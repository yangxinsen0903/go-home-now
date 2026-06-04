# GoHomeNow

Dog adoption-success platform — smart matching + transparent care planning.

## Structure

```
backend/   FastAPI + SQLite API server (runs on Hostinger VPS)
ios/       SwiftUI iOS app (local Xcode project)
```

## Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

## Deployment

Backend auto-deploys to VPS on push to main via deploy script.
