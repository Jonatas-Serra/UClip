"""UClip backend — FastAPI app entrypoint."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from backend.api.clip import router as clip_router
from backend.services.database_service import init_db, ensure_images_dir

app = FastAPI(title="UClip Backend", version="0.2.1")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup():
    init_db()


@app.get("/")
async def root():
    return {"status": "ok", "service": "uclip-backend"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


app.include_router(clip_router, prefix="/api")

# Static mount p/ imagens — usa o mesmo diretório que o listener usa.
# ensure_images_dir() respeita UCLIP_DATA_DIR para casos especiais.
app.mount("/api/images", StaticFiles(directory=ensure_images_dir()), name="images")
