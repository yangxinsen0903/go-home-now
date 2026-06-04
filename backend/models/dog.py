from sqlalchemy import Column, Integer, String, JSON
from database import Base


class Dog(Base):
    __tablename__ = "dogs"

    id = Column(Integer, primary_key=True, index=True)
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
