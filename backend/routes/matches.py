from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from models.dog import Dog
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/api/matches", tags=["matches"])

ENERGY_LEVELS = ["low", "moderate", "high"]
EXPERIENCE_MAX_ENERGY = {"first-time": "moderate", "some": "high", "experienced": "high"}


def compute_fit_score(dog: Dog, home_type: str, monthly_budget: int,
                      activity_level: str, experience: str) -> int:
    score = 0

    # Budget (30 pts)
    if dog.monthly_cost <= monthly_budget:
        score += 30
    elif dog.monthly_cost <= monthly_budget * 1.15:
        score += 15

    # Home type (25 pts)
    if dog.home_type_required == "any" or dog.home_type_required == home_type:
        score += 25

    # Energy / activity match (25 pts)
    user_idx = ENERGY_LEVELS.index(activity_level) if activity_level in ENERGY_LEVELS else 1
    dog_idx = ENERGY_LEVELS.index(dog.energy_level) if dog.energy_level in ENERGY_LEVELS else 1
    diff = abs(user_idx - dog_idx)
    if diff == 0:
        score += 25
    elif diff == 1:
        score += 12

    # Experience vs dog energy (20 pts)
    max_ok = EXPERIENCE_MAX_ENERGY.get(experience, "high")
    max_ok_idx = ENERGY_LEVELS.index(max_ok)
    if dog_idx <= max_ok_idx:
        score += 20

    return min(score, 100)


class MatchRequest(BaseModel):
    home_type: str
    monthly_budget: int
    activity_level: str
    experience: str
    location: Optional[str] = None


class MatchOut(BaseModel):
    id: int
    name: str
    age: int
    breed: str
    size: str
    energy_level: str
    temperament: str
    shelter: str
    city: str
    monthly_cost: int
    training_plan: str
    risk_flags: list
    behavior_notes: str
    image_url: Optional[str]
    fit_score: int

    model_config = {"from_attributes": True}


@router.post("/", response_model=list[MatchOut])
def get_matches(req: MatchRequest, db: Session = Depends(get_db)):
    query = db.query(Dog)
    if req.location:
        query = query.filter(Dog.city == req.location)
    dogs = query.all()

    results = []
    for dog in dogs:
        score = compute_fit_score(
            dog, req.home_type, req.monthly_budget,
            req.activity_level, req.experience
        )
        results.append({
            **{c.name: getattr(dog, c.name) for c in dog.__table__.columns},
            "fit_score": score,
        })

    results.sort(key=lambda x: x["fit_score"], reverse=True)
    return results
