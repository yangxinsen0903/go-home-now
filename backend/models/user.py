from sqlalchemy import Column, Integer, String
from database import Base


class UserProfile(Base):
    __tablename__ = "user_profiles"

    id = Column(Integer, primary_key=True, index=True)
    home_type = Column(String)  # apartment, house
    schedule = Column(String)  # hybrid, office, remote
    monthly_budget = Column(Integer)
    activity_level = Column(String)  # low, moderate, high
    experience = Column(String)  # first-time, some, experienced
    has_kids = Column(String)  # yes, no
    has_other_pets = Column(String)  # yes, no
    location = Column(String)  # dc, nyc
