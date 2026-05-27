"""Endpoints REST para clips."""

import os
from typing import List
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel

from backend.services.database_service import Clip, init_db, ensure_images_dir

router = APIRouter(prefix="/clips", tags=["clips"])

# Base URL pública do servidor de imagens. Como o backend escuta em 127.0.0.1:8001
# e o frontend Electron também roda local, esta constante é suficiente.
IMAGE_BASE_URL = "http://127.0.0.1:8001/api/images"


class ClipCreate(BaseModel):
    content: str
    mime: str = "text/plain"


class ClipOut(BaseModel):
    id: int
    content: str
    mime: str
    created_at: str
    file_path: str | None = None


def get_session():
    SessionLocal = init_db()
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


def _serialize(clip: Clip) -> ClipOut:
    """Converte um Clip do DB para a forma pública.

    Para imagens, o DB guarda apenas o filename. Aqui transformamos em URL
    servida pelo StaticFiles e expomos o path absoluto separadamente em
    `file_path` para o Electron poder usar `nativeImage.createFromPath`.
    """
    if clip.mime and clip.mime.startswith("image"):
        # Compatibilidade retroativa: se algum registro antigo tem path absoluto,
        # extrai o basename. Novos registros já vêm só com o filename.
        filename = os.path.basename(clip.content)
        return ClipOut(
            id=clip.id,
            content=f"{IMAGE_BASE_URL}/{filename}",
            mime=clip.mime,
            created_at=str(clip.created_at),
            file_path=os.path.join(ensure_images_dir(), filename),
        )
    return ClipOut(
        id=clip.id,
        content=clip.content,
        mime=clip.mime,
        created_at=str(clip.created_at),
        file_path=None,
    )


@router.post("/", response_model=ClipOut)
def create_clip(payload: ClipCreate, session=Depends(get_session)):
    clip = Clip(content=payload.content, mime=payload.mime)
    session.add(clip)
    session.commit()
    session.refresh(clip)
    return _serialize(clip)


@router.get("/", response_model=List[ClipOut])
def list_clips(limit: int = 50, session=Depends(get_session)):
    rows = session.query(Clip).order_by(Clip.created_at.desc()).limit(limit).all()
    return [_serialize(r) for r in rows]


@router.get("/{clip_id}", response_model=ClipOut)
def get_clip(clip_id: int, session=Depends(get_session)):
    clip = session.query(Clip).filter(Clip.id == clip_id).first()
    if not clip:
        raise HTTPException(status_code=404, detail="Clip not found")
    return _serialize(clip)


@router.delete("/{clip_id}")
def delete_clip(clip_id: int, session=Depends(get_session)):
    clip = session.query(Clip).filter(Clip.id == clip_id).first()
    if not clip:
        raise HTTPException(status_code=404, detail="Clip not found")
    session.delete(clip)
    session.commit()
    return {"status": "deleted"}
