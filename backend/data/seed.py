from database import engine, SessionLocal
from models import Dog
import models  # ensure tables are created

def seed():
    from database import Base
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    if db.query(Dog).count() > 0:
        db.close()
        return

    dogs = [
        Dog(
            name="Luna",
            age=3,
            breed="Mixed Breed",
            size="medium",
            energy_level="low",
            temperament="Calm, affectionate",
            shelter="Humane Rescue Alliance",
            city="dc",
            home_type_required="any",
            monthly_cost=185,
            first_vet_days=7,
            training_plan="4-week leash plan",
            risk_flags=["Mild anxiety"],
            behavior_notes="Calm and affectionate, needs leash practice. Good with calm households.",
            image_url=None,
        ),
        Dog(
            name="Milo",
            age=6,
            breed="Labrador Mix",
            size="large",
            energy_level="low",
            temperament="Gentle, easy-going",
            shelter="Foster Network DC",
            city="dc",
            home_type_required="any",
            monthly_cost=210,
            first_vet_days=5,
            training_plan="Basic manners refresher",
            risk_flags=[],
            behavior_notes="Gentle senior dog, great for first-time owners. Foster-tested with kids.",
            image_url=None,
        ),
        Dog(
            name="Toby",
            age=1,
            breed="Border Collie Mix",
            size="medium",
            energy_level="high",
            temperament="Active, playful",
            shelter="NYC Animal Care Centers",
            city="nyc",
            home_type_required="house",
            monthly_cost=230,
            first_vet_days=3,
            training_plan="8-week obedience + enrichment plan",
            risk_flags=["High energy", "Needs yard"],
            behavior_notes="Young, energetic dog. Needs daily exercise and mental stimulation.",
            image_url=None,
        ),
        Dog(
            name="Bella",
            age=4,
            breed="Beagle Mix",
            size="small",
            energy_level="moderate",
            temperament="Curious, friendly",
            shelter="NYC Animal Care Centers",
            city="nyc",
            home_type_required="any",
            monthly_cost=170,
            first_vet_days=7,
            training_plan="3-week recall training",
            risk_flags=["Scent-driven, needs leash"],
            behavior_notes="Friendly and curious. Loves sniffing. Great apartment dog if exercised.",
            image_url=None,
        ),
    ]

    db.add_all(dogs)
    db.commit()
    db.close()
    print("Seeded database with sample dogs.")


if __name__ == "__main__":
    seed()
