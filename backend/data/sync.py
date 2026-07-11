from database import SessionLocal
from models.dog import Dog
from services.rescuegroups import fetch_all_dogs

# Each entry maps one or more US state codes to a city label.
# Multi-state entries (e.g. DMV = DC + MD + VA) are fetched together so
# that the stale-deletion pass sees the full combined live set.
SEARCH_TARGETS = [
    {"states": ["DC", "MD", "VA"], "city": "dc"},   # DMV metro area
    {"states": ["NY"],             "city": "nyc"},
]


def sync_from_rescuegroups() -> dict:
    """
    Full reconciliation sync:
    - Fetch all currently-available dogs from RescueGroups for each city
    - Upsert (add new, update existing)
    - Delete dogs no longer returned (adopted / delisted)
    Returns a summary dict.
    """
    db = SessionLocal()
    added = updated = deleted = 0
    errors = []

    try:
        for target in SEARCH_TARGETS:
            city = target["city"]
            # Aggregate dogs from all states for this city
            all_live_dogs: list[dict] = []
            for state in target["states"]:
                try:
                    all_live_dogs.extend(fetch_all_dogs(state, city))
                except Exception as e:
                    errors.append(f"{city}/{state}: {e}")

            live_dogs = all_live_dogs
            live_ids = {d["external_id"] for d in live_dogs if d.get("external_id")}

            # Upsert
            for dog_data in live_dogs:
                external_id = dog_data.get("external_id")
                if not external_id:
                    continue
                existing = db.query(Dog).filter(Dog.external_id == external_id).first()
                if existing:
                    for k, v in dog_data.items():
                        setattr(existing, k, v)
                    updated += 1
                else:
                    db.add(Dog(**dog_data))
                    added += 1

            # Delete dogs from this city no longer available on RescueGroups
            # (only touch RescueGroups-sourced dogs, i.e. external_id starts with "rg_")
            stale = (
                db.query(Dog)
                .filter(Dog.city == city)
                .filter(Dog.external_id.like("rg_%"))
                .filter(Dog.external_id.notin_(live_ids))
                .all()
            )
            for dog in stale:
                db.delete(dog)
                deleted += 1

        db.commit()
    except Exception as e:
        db.rollback()
        errors.append(str(e))
    finally:
        db.close()

    return {"added": added, "updated": updated, "deleted": deleted, "errors": errors}
