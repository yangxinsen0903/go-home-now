from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from models.dog import Dog
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/api/dogs", tags=["dogs"])


class DogOut(BaseModel):
    id: int
    name: str
    age: int
    breed: str
    size: str
    energy_level: str
    temperament: str
    shelter: str
    city: str
    home_type_required: str
    monthly_cost: int
    first_vet_days: int
    training_plan: str
    risk_flags: list
    behavior_notes: str
    image_url: Optional[str]

    model_config = {"from_attributes": True}


@router.get("/", response_model=list[DogOut])
def list_dogs(city: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(Dog)
    if city:
        query = query.filter(Dog.city == city)
    return query.all()


@router.get("/{dog_id}", response_model=DogOut)
def get_dog(dog_id: int, db: Session = Depends(get_db)):
    return db.query(Dog).filter(Dog.id == dog_id).first()
