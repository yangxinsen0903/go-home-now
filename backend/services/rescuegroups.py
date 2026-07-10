import os
import re
import httpx
from typing import Optional

API_KEY = os.getenv("RESCUEGROUPS_API_KEY", "FumIB33p")
HTTP_API_URL = "https://api.rescuegroups.org/http/v2.json"

# animalGeneralAge → approximate age in years
_AGE_MAP = {"Baby": 0, "Young": 1, "Adult": 4, "Senior": 9}

_SMALL_BREED_KEYWORDS = {
    "chihuahua", "pomeranian", "maltese", "yorkshire", "dachshund",
    "bichon", "shih tzu", "miniature", "toy poodle", "papillon", "pug",
    "boston terrier", "jack russell", "fox terrier",
}
_LARGE_BREED_KEYWORDS = {
    "labrador", "golden retriever", "german shepherd", "husky", "malinois",
    "rottweiler", "mastiff", "great dane", "saint bernard", "newfoundland",
    "weimaraner", "vizsla", "collie", "cattle dog", "heeler", "boxer",
    "doberman", "cane corso", "great pyrenees", "bernese", "bloodhound",
    "akita", "alaskan",
}
_HIGH_ENERGY_KEYWORDS = {
    "husky", "cattle", "heeler", "collie", "malinois", "retriever",
    "spaniel", "pointer", "vizsla", "weimaraner", "terrier", "shepherd",
    "border", "australian",
}
_LOW_ENERGY_KEYWORDS = {
    "bulldog", "basset", "mastiff", "great dane", "saint", "newfoundland",
    "shih tzu", "pug",
}

_MONTHLY_COST = {"small": 130, "medium": 175, "large": 215}

_ANIMAL_FIELDS = [
    "animalID", "animalName", "animalBreed", "animalBirthdate",
    "animalGeneralAge", "animalDescription", "animalLocation",
    "animalLocationState", "animalOrgID", "animalPictures",
    "animalSex", "animalSpecialneeds",
]


def _strip_html(html: str) -> str:
    text = re.sub(r"<[^>]+>", " ", html or "")
    for entity, char in [("&nbsp;", " "), ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">")]:
        text = text.replace(entity, char)
    text = re.sub(r"&[a-z]+;", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def _extract_rg_description(html: str) -> str:
    """Pull only the rgDescription div, stripping rgFoster (contact) and rgSummary (promo)."""
    m = re.search(r'class=["\']rgDescription["\'][^>]*>(.*?)</div>', html or "", re.DOTALL | re.IGNORECASE)
    if m:
        return _strip_html(m.group(1))
    return _strip_html(html)


_JUNK_PREFIXES = re.compile(
    r"^\s*(?:name\s*:|best guess for|sex\s*:|approximate weight|gets along with"
    r"|currently living|foster|please contact|http|www\.)",
    re.IGNORECASE,
)

def _clean_behavior_notes(raw_text: str) -> str:
    """Remove structured-data preamble and marketing lines; keep narrative text."""
    sentences = re.split(r"(?<=[.!?])\s+", raw_text)
    kept = []
    for s in sentences:
        s = s.strip()
        if not s:
            continue
        if _JUNK_PREFIXES.match(s):
            continue
        if re.search(r"@\w+\.\w+", s):  # email address
            continue
        if re.search(r"NEEDS? A FOREVER HOME", s, re.IGNORECASE):
            continue
        kept.append(s)
    return " ".join(kept)[:600].strip()


def _extract_weight(text: str) -> Optional[int]:
    m = re.search(r"(?:approximate\s+)?weight[:\s]+(\d+)\s*lbs?", text, re.IGNORECASE)
    return int(m.group(1)) if m else None


def _extract_good_with(text: str) -> Optional[str]:
    m = re.search(
        r"gets?\s+along\s+with\s*[:\-]?\s*(.+?)(?:\.|We haven|We have not|$)",
        text, re.IGNORECASE | re.DOTALL,
    )
    if m:
        result = re.sub(r"\s+", " ", m.group(1)).strip().rstrip("!")
        return result[:150] if result else None
    return None


def _extract_yes_no(text: str, *positive_patterns: str) -> Optional[str]:
    """Return 'Yes', 'No', or None by scanning text for keyword signals."""
    t = text.lower()
    for pat in positive_patterns:
        not_pat = rf"not\s+{pat}|un{pat}"
        if re.search(not_pat, t):
            return "No"
        if re.search(pat, t):
            return "Yes"
    return None


def _extract_neutered(text: str) -> Optional[str]:
    return _extract_yes_no(text, r"spay(?:ed)?", r"neuter(?:ed)?")


def _extract_vaccinated(text: str) -> Optional[str]:
    return _extract_yes_no(text, r"vaccin(?:ated|ations?)", r"up[\s\-]to[\s\-]date on (?:his|her|all)?\s*(?:shots|vaccines?|vaccinations?)")


def _extract_house_trained(text: str) -> Optional[str]:
    return _extract_yes_no(text, r"house[\s\-]train(?:ed)?", r"potty[\s\-]train(?:ed)?")


def _estimate_size(breed: str) -> str:
    b = (breed or "").lower()
    if any(k in b for k in _SMALL_BREED_KEYWORDS):
        return "small"
    if any(k in b for k in _LARGE_BREED_KEYWORDS):
        return "large"
    return "medium"


def _estimate_energy(breed: str, general_age: str) -> str:
    age = (general_age or "").lower()
    if age in ("baby", "young"):
        return "high"
    if age == "senior":
        return "low"
    b = (breed or "").lower()
    if any(k in b for k in _HIGH_ENERGY_KEYWORDS):
        return "high"
    if any(k in b for k in _LOW_ENERGY_KEYWORDS):
        return "low"
    return "moderate"


def _default_training_plan(energy: str, general_age: str) -> str:
    age = (general_age or "").lower()
    if age == "baby":
        return "8-week puppy basics + socialization"
    if energy == "high":
        return "6-week obedience + daily enrichment plan"
    if energy == "low":
        return "2-week settle-in + basic manners"
    return "4-week basic manners plan"


def _post(payload: dict) -> dict:
    with httpx.Client(timeout=30) as c:
        r = c.post(HTTP_API_URL, json=payload)
        r.raise_for_status()
        return r.json()


def _fetch_org_names(org_ids: set[str]) -> dict[str, str]:
    result = {}
    for org_id in org_ids:
        try:
            payload = {
                "apikey": API_KEY,
                "objectType": "orgs",
                "objectAction": "publicSearch",
                "search": {
                    "resultStart": "0",
                    "resultLimit": "1",
                    "calcFoundRows": "No",
                    "filters": [{"fieldName": "orgID", "operation": "equals", "criteria": org_id}],
                    "fields": ["orgID", "orgName"],
                },
            }
            data = _post(payload)
            orgs = data.get("data") or {}
            if isinstance(orgs, dict) and org_id in orgs:
                result[org_id] = orgs[org_id].get("orgName", "Local Rescue")
        except Exception:
            pass
    return result


def _map_animal(record: dict, org_names: dict, city: str) -> Optional[dict]:
    name = (record.get("animalName") or "").strip()
    if not name:
        return None

    breed = (record.get("animalBreed") or "Mixed Breed").strip()
    general_age = record.get("animalGeneralAge") or "Adult"
    age = _AGE_MAP.get(general_age, 4)
    size = _estimate_size(breed)
    energy = _estimate_energy(breed, general_age)

    org_id = str(record.get("animalOrgID") or "")
    shelter = org_names.get(org_id, "Local Rescue")

    pics = record.get("animalPictures") or []
    photo_urls = []
    if isinstance(pics, list):
        for p in pics[:6]:
            url = p.get("urlSecureFullsize") or p.get("urlSecureThumbnail")
            if url:
                photo_urls.append(url)
    image_url = photo_urls[0] if photo_urls else None

    raw_html = record.get("animalDescription") or ""
    raw_text = _extract_rg_description(raw_html) or _strip_html(raw_html)
    behavior_notes = _clean_behavior_notes(raw_text) or f"{breed} available for adoption."

    weight_lbs = _extract_weight(raw_text)
    good_with = _extract_good_with(raw_text)
    neutered = _extract_neutered(raw_text)
    vaccinated = _extract_vaccinated(raw_text)
    house_trained = _extract_house_trained(raw_text)

    sex_raw = (record.get("animalSex") or "").strip()
    sex = sex_raw if sex_raw in ("Male", "Female") else None

    risk_flags = []
    if (record.get("animalSpecialneeds") or "").lower() in ("yes", "true", "1"):
        risk_flags.append("Special needs")

    return {
        "external_id": f"rg_{record['animalID']}",
        "name": name,
        "age": age,
        "breed": breed,
        "size": size,
        "energy_level": energy,
        "temperament": general_age,
        "shelter": shelter,
        "city": city,
        "home_type_required": "any",
        "monthly_cost": _MONTHLY_COST[size],
        "first_vet_days": 7,
        "training_plan": _default_training_plan(energy, general_age),
        "risk_flags": risk_flags,
        "behavior_notes": behavior_notes,
        "image_url": image_url,
        "photos": photo_urls,
        "sex": sex,
        "weight_lbs": weight_lbs,
        "good_with": good_with,
        "neutered": neutered,
        "vaccinated": vaccinated,
        "house_trained": house_trained,
    }


def fetch_all_dogs(state: str, city: str, page_size: int = 100) -> list[dict]:
    """Fetch ALL currently-available dogs in a US state, paginating as needed."""
    all_records: dict = {}
    start = 0

    while True:
        payload = {
            "apikey": API_KEY,
            "objectType": "animals",
            "objectAction": "publicSearch",
            "search": {
                "resultStart": str(start),
                "resultLimit": str(page_size),
                "resultSort": "animalID",
                "resultOrder": "asc",
                "calcFoundRows": "Yes",
                "filters": [
                    {"fieldName": "animalStatus", "operation": "equals", "criteria": "Available"},
                    {"fieldName": "animalSpecies", "operation": "equals", "criteria": "Dog"},
                    {"fieldName": "animalLocationState", "operation": "equals", "criteria": state},
                ],
                "fields": _ANIMAL_FIELDS,
            },
        }
        data = _post(payload)
        records = data.get("data") or {}
        if isinstance(records, list) or not records:
            break
        all_records.update(records)

        total = int(data.get("foundRows") or 0)
        start += page_size
        if start >= total:
            break

    org_ids = {str(v.get("animalOrgID")) for v in all_records.values() if v.get("animalOrgID")}
    org_names = _fetch_org_names(org_ids)

    results = []
    for record in all_records.values():
        mapped = _map_animal(record, org_names, city)
        if mapped:
            results.append(mapped)
    return results
