from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine
from models import Dog, UserProfile
import models  # register all models with Base
from database import Base
from routes import dogs, matches
from data.seed import seed

Base.metadata.create_all(bind=engine)
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


@app.get("/")
def root():
    return {"status": "ok", "service": "GoHomeNow API"}
