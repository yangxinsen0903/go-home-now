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
    image_url = None
    if isinstance(pics, list) and pics:
        image_url = pics[0].get("urlSecureFullsize") or pics[0].get("urlSecureThumbnail")

    raw_desc = record.get("animalDescription") or ""
    description = _strip_html(raw_desc)[:800] or f"{breed} available for adoption."

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
        "behavior_notes": description,
        "image_url": image_url,
    }


def fetch_dogs(state: str, city: str, limit: int = 50) -> list[dict]:
    """Fetch available dogs in a US state and return mapped dog dicts."""
    payload = {
        "apikey": API_KEY,
        "objectType": "animals",
        "objectAction": "publicSearch",
        "search": {
            "resultStart": "0",
            "resultLimit": str(limit),
            "resultSort": "animalID",
            "resultOrder": "asc",
            "calcFoundRows": "No",
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
    if isinstance(records, list):
        return []

    org_ids = {str(v.get("animalOrgID")) for v in records.values() if v.get("animalOrgID")}
    org_names = _fetch_org_names(org_ids)

    results = []
    for record in records.values():
        mapped = _map_animal(record, org_names, city)
        if mapped:
            results.append(mapped)
    return results
