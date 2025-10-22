import os
import tempfile

from backend.services.database_service import get_engine, init_db, Clip


def test_init_db_and_insert():
    # create a temporary sqlite file
    fd, path = tempfile.mkstemp(suffix=".db")
    os.close(fd)
    try:
        engine = get_engine(f"sqlite:///{path}")
        SessionLocal = init_db(engine=engine)
        session = SessionLocal()
        clip = Clip(content="hello world", mime="text/plain")
        session.add(clip)
        session.commit()
        assert clip.id is not None
        fetched = session.query(Clip).filter(Clip.id == clip.id).first()
        assert fetched.content == "hello world"
    finally:
        try:
            os.remove(path)
        except Exception:
            pass
