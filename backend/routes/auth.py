import re
import secrets
from typing import Optional

import bcrypt
from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel, field_validator
from sqlalchemy.orm import Session

from database import get_db
from models.account import Account

router = APIRouter(prefix="/api/auth", tags=["auth"])

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class SignupRequest(BaseModel):
    email: str
    password: str
    name: Optional[str] = None

    @field_validator("email")
    @classmethod
    def valid_email(cls, v):
        if not EMAIL_RE.match(v):
            raise ValueError("Invalid email address")
        return v.lower()

    @field_validator("password")
    @classmethod
    def valid_password(cls, v):
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters")
        return v


class LoginRequest(BaseModel):
    email: str
    password: str


class AuthOut(BaseModel):
    token: str
    email: str
    name: Optional[str] = None


class MeOut(BaseModel):
    email: str
    name: Optional[str] = None


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, password_hash: str) -> bool:
    return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("utf-8"))


@router.post("/signup", response_model=AuthOut)
def signup(req: SignupRequest, db: Session = Depends(get_db)):
    existing = db.query(Account).filter(Account.email == req.email).first()
    if existing:
        raise HTTPException(status_code=409, detail="An account with this email already exists")
    account = Account(
        email=req.email,
        password_hash=hash_password(req.password),
        name=req.name,
        token=secrets.token_urlsafe(32),
    )
    db.add(account)
    db.commit()
    db.refresh(account)
    return AuthOut(token=account.token, email=account.email, name=account.name)


@router.post("/login", response_model=AuthOut)
def login(req: LoginRequest, db: Session = Depends(get_db)):
    account = db.query(Account).filter(Account.email == req.email.lower()).first()
    if not account or not verify_password(req.password, account.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    account.token = secrets.token_urlsafe(32)
    db.commit()
    return AuthOut(token=account.token, email=account.email, name=account.name)


def get_current_account(
    authorization: Optional[str] = Header(None), db: Session = Depends(get_db)
) -> Account:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.removeprefix("Bearer ").strip()
    account = db.query(Account).filter(Account.token == token).first()
    if not account:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    return account


@router.get("/me", response_model=MeOut)
def me(account: Account = Depends(get_current_account)):
    return MeOut(email=account.email, name=account.name)
