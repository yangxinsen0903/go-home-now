from sqlalchemy import Column, Integer, String, JSON
from database import Base


class Dog(Base):
    __tablename__ = "dogs"

    id = Column(Integer, primary_key=True, index=True)
    external_id = Column(String, nullable=True, unique=True, index=True)  # e.g. "rg_12345"
    name = Column(String, nullable=False)
    age = Column(Integer)  # years
    breed = Column(String)
    size = Column(String)  # small, medium, large
    energy_level = Column(String)  # low, moderate, high
    temperament = Column(String)
    shelter = Column(String)
    city = Column(String)  # dc, nyc
    home_type_required = Column(String)  # apartment, house, any
    monthly_cost = Column(Integer)
    first_vet_days = Column(Integer)
    training_plan = Column(String)
    risk_flags = Column(JSON, default=list)
    behavior_notes = Column(String)
    image_url = Column(String, nullable=True)
    photos = Column(JSON, default=list)  # up to 6 photo URLs
    sex = Column(String, nullable=True)           # Male / Female
    weight_lbs = Column(Integer, nullable=True)  # extracted from description
    good_with = Column(String, nullable=True)    # e.g. "dogs, kids"
    neutered = Column(String, nullable=True)     # Yes / No / Unknown
    vaccinated = Column(String, nullable=True)   # Yes / No / Unknown
    house_trained = Column(String, nullable=True) # Yes / No / Unknown
