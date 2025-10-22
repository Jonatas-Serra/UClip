"""Serviço de banco de dados — esqueleto usando SQLAlchemy.

Define um modelo simples `Clip` e funções básicas de inicialização.
"""

from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, create_engine
from sqlalchemy.orm import declarative_base, sessionmaker, scoped_session

Base = declarative_base()


class Clip(Base):
    __tablename__ = "clips"

    id = Column(Integer, primary_key=True)
    content = Column(String, nullable=False)
    mime = Column(String, default="text/plain")
    created_at = Column(DateTime, default=datetime.utcnow)


def ensure_images_dir(path: str | None = None) -> str:
    """Ensure images directory exists and return its path.

    Default: ~/.local/share/uclip/images/
    """
    import os

    if path is None:
        home = os.path.expanduser("~")
        path = os.path.join(home, ".local", "share", "uclip", "images")
    os.makedirs(path, exist_ok=True)
    return path


def get_engine(sqlite_path: str = "sqlite:///./uclip.db"):
    return create_engine(sqlite_path, connect_args={"check_same_thread": False})


def init_db(engine=None):
    """Cria as tabelas e retorna uma Session factory (scoped_session).

    Uso:
        SessionLocal = init_db()
        with SessionLocal() as session:
            ...
    """
    if engine is None:
        engine = get_engine()
    Base.metadata.create_all(bind=engine)
    session_factory = sessionmaker(bind=engine, autoflush=False, autocommit=False)
    return scoped_session(session_factory)

