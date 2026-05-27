"""Serviço de banco de dados — modelo Clip + helpers de path.

Diretório de dados unificado em ~/.local/share/uclip, podendo ser
sobrescrito via env vars (útil para systemd services e testes).
"""

import os
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, create_engine
from sqlalchemy.orm import declarative_base, sessionmaker, scoped_session

Base = declarative_base()


class Clip(Base):
    __tablename__ = "clips"

    id = Column(Integer, primary_key=True)
    content = Column(String, nullable=False)  # texto OU filename da imagem (sem path)
    mime = Column(String, default="text/plain")
    created_at = Column(DateTime, default=datetime.utcnow)


def _data_root() -> str:
    """Raiz dos dados do UClip. Env UCLIP_DATA_DIR sobrescreve, senão ~/.local/share/uclip."""
    root = os.environ.get("UCLIP_DATA_DIR")
    if not root:
        root = os.path.join(os.path.expanduser("~"), ".local", "share", "uclip")
    os.makedirs(root, exist_ok=True)
    return root


def ensure_images_dir(path: str | None = None) -> str:
    """Garante que o diretório de imagens existe e retorna o path absoluto."""
    if path is None:
        path = os.path.join(_data_root(), "images")
    os.makedirs(path, exist_ok=True)
    return path


def _default_db_url() -> str:
    """URL padrão do SQLite com path absoluto user-scoped."""
    db_path = os.path.join(_data_root(), "uclip.db")
    return f"sqlite:///{db_path}"


def get_engine(sqlite_path: str | None = None):
    """Retorna engine SQLAlchemy. Aceita override via arg ou env UCLIP_DB_URL."""
    if sqlite_path is None:
        sqlite_path = os.environ.get("UCLIP_DB_URL") or _default_db_url()
    return create_engine(sqlite_path, connect_args={"check_same_thread": False})


def init_db(engine=None):
    """Cria as tabelas e retorna uma Session factory (scoped_session)."""
    if engine is None:
        engine = get_engine()
    Base.metadata.create_all(bind=engine)
    session_factory = sessionmaker(bind=engine, autoflush=False, autocommit=False)
    return scoped_session(session_factory)
