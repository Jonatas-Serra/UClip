"""UClip backend - FastAPI scaffold

Roda um servidor FastAPI mínimo com um endpoint de saúde.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.api.clip import router as clip_router
from backend.services.database_service import init_db
from fastapi.staticfiles import StaticFiles
from backend.services.database_service import ensure_images_dir

app = FastAPI(title="UClip Backend", version="0.1.0")

# Add CORS middleware to allow Electron frontend to access the API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup():
    # initialize DB (creates tables)
    init_db()


@app.get("/")
async def root():
    return {"status": "ok", "message": "UClip backend running"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


app.include_router(clip_router, prefix="/api")

# Serve images saved by the listener
images_dir = ensure_images_dir()
app.mount("/api/images", StaticFiles(directory=images_dir), name="images")
