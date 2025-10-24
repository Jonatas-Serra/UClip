from typing import List
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel

from backend.services.database_service import Clip, init_db

router = APIRouter(prefix="/clips", tags=["clips"])


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
    try:
        session = SessionLocal()
        yield session
    finally:
        session.close()


@router.post("/", response_model=ClipOut)
def create_clip(payload: ClipCreate, session=Depends(get_session)):
    clip = Clip(content=payload.content, mime=payload.mime)
    session.add(clip)
    session.commit()
    session.refresh(clip)
    content = clip.content
    file_path = None
    if clip.mime and clip.mime.startswith("image"):
        # convert local path to API URL (absolute URL for Electron frontend)
        import os
        filename = os.path.basename(content)
        content = f"http://127.0.0.1:8001/api/images/{filename}"
        file_path = clip.content
    return ClipOut(
        id=clip.id,
        content=content,
        mime=clip.mime,
        created_at=str(clip.created_at),
        file_path=file_path,
    )


@router.get("/", response_model=List[ClipOut])
def list_clips(limit: int = 50, session=Depends(get_session)):
    rows = session.query(Clip).order_by(Clip.created_at.desc()).limit(limit).all()
    out = []
    import os
    for r in rows:
        content = r.content
        file_path = None
        if r.mime and r.mime.startswith("image"):
            filename = os.path.basename(r.content)
            content = f"http://127.0.0.1:8001/api/images/{filename}"
            file_path = r.content
        out.append(
            ClipOut(
                id=r.id,
                content=content,
                mime=r.mime,
                created_at=str(r.created_at),
                file_path=file_path,
            )
        )
    return out


@router.get("/{clip_id}", response_model=ClipOut)
def get_clip(clip_id: int, session=Depends(get_session)):
    clip = session.query(Clip).filter(Clip.id == clip_id).first()
    if not clip:
        raise HTTPException(status_code=404, detail="Clip not found")
    content = clip.content
    file_path = None
    if clip.mime and clip.mime.startswith("image"):
        import os
        filename = os.path.basename(content)
        content = f"http://127.0.0.1:8001/api/images/{filename}"
        file_path = clip.content
    return ClipOut(
        id=clip.id,
        content=content,
        mime=clip.mime,
        created_at=str(clip.created_at),
        file_path=file_path,
    )


@router.delete("/{clip_id}")
def delete_clip(clip_id: int, session=Depends(get_session)):
    clip = session.query(Clip).filter(Clip.id == clip_id).first()
    if not clip:
        raise HTTPException(status_code=404, detail="Clip not found")
    session.delete(clip)
    session.commit()
    return {"status": "deleted"}
