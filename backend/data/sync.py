from database import SessionLocal
from models.dog import Dog
from services.rescuegroups import fetch_dogs

SEARCH_TARGETS = [
    {"state": "DC", "city": "dc"},
    {"state": "NY", "city": "nyc"},
]


def sync_from_rescuegroups(limit_per_city: int = 50) -> dict:
    """Pull dogs from RescueGroups and upsert into the local DB. Returns a summary."""
    db = SessionLocal()
    added = updated = 0
    errors = []

    try:
        for target in SEARCH_TARGETS:
            try:
                dogs = fetch_dogs(target["state"], target["city"], limit=limit_per_city)
            except Exception as e:
                errors.append(f"{target['city']}: {e}")
                continue

            for dog_data in dogs:
                external_id = dog_data.get("external_id")
                existing = db.query(Dog).filter(Dog.external_id == external_id).first()
                if existing:
                    for k, v in dog_data.items():
                        setattr(existing, k, v)
                    updated += 1
                else:
                    db.add(Dog(**dog_data))
                    added += 1

        db.commit()
    except Exception as e:
        db.rollback()
        errors.append(str(e))
    finally:
        db.close()

    return {"added": added, "updated": updated, "errors": errors}
