from fastapi import APIRouter
from data.sync import sync_from_rescuegroups

router = APIRouter(prefix="/api/admin", tags=["admin"])


@router.post("/sync")
def trigger_sync():
    """Pull fresh dog listings from RescueGroups and upsert into the DB."""
    result = sync_from_rescuegroups()
    return {"status": "ok", **result}
