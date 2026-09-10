from typing import Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database import get_db
from models.account import Account
from models.user import UserProfile
from routes.auth import get_current_account

router = APIRouter(prefix="/api/profile", tags=["profile"])


class ProfileIn(BaseModel):
    home_type: str
    monthly_budget: int
    activity_level: str
    experience: str
    location: Optional[str] = None
    preferred_sizes: Optional[list[str]] = None
    preferred_age: Optional[str] = None


class ProfileOut(ProfileIn):
    pass


def _to_out(profile: UserProfile) -> ProfileOut:
    return ProfileOut(
        home_type=profile.home_type,
        monthly_budget=profile.monthly_budget,
        activity_level=profile.activity_level,
        experience=profile.experience,
        location=profile.location,
        preferred_sizes=profile.preferred_sizes.split(",") if profile.preferred_sizes else [],
        preferred_age=profile.preferred_age,
    )


@router.get("/", response_model=Optional[ProfileOut])
def get_profile(account: Account = Depends(get_current_account), db: Session = Depends(get_db)):
    profile = db.query(UserProfile).filter(UserProfile.account_id == account.id).first()
    return _to_out(profile) if profile else None


@router.put("/", response_model=ProfileOut)
def upsert_profile(
    req: ProfileIn,
    account: Account = Depends(get_current_account),
    db: Session = Depends(get_db),
):
    profile = db.query(UserProfile).filter(UserProfile.account_id == account.id).first()
    if not profile:
        profile = UserProfile(account_id=account.id)
        db.add(profile)
    profile.home_type = req.home_type
    profile.monthly_budget = req.monthly_budget
    profile.activity_level = req.activity_level
    profile.experience = req.experience
    profile.location = req.location
    profile.preferred_sizes = ",".join(req.preferred_sizes or [])
    profile.preferred_age = req.preferred_age
    db.commit()
    db.refresh(profile)
    return _to_out(profile)
