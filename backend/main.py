from dotenv import load_dotenv
load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from database import engine
from models import Dog, UserProfile
import models
from database import Base
from routes import dogs, matches
from routes.admin import router as admin_router
from data.seed import seed

Base.metadata.create_all(bind=engine)

# Migrate: add external_id column if it doesn't exist yet (SQLite-safe)
with engine.connect() as conn:
    for col_def in ["external_id TEXT", "photos TEXT", "sex TEXT", "weight_lbs INTEGER", "good_with TEXT"]:
        try:
            conn.execute(text(f"ALTER TABLE dogs ADD COLUMN {col_def}"))
            conn.commit()
        except Exception:
            pass  # Column already present

seed()

app = FastAPI(title="GoHomeNow API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(dogs.router)
app.include_router(matches.router)
app.include_router(admin_router)


@app.get("/")
def root():
    return {"status": "ok", "service": "GoHomeNow API"}
