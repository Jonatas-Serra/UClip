import os
import tempfile

import pytest
from fastapi.testclient import TestClient


@pytest.fixture()
def client(monkeypatch, tmp_path):
    # Isolar dados de teste em diretório temporário
    monkeypatch.setenv("UCLIP_DATA_DIR", str(tmp_path))
    monkeypatch.setenv("UCLIP_DB_URL", f"sqlite:///{tmp_path}/test.db")

    # Re-import só após setar env vars (módulo lê env na hora de criar engine)
    from importlib import reload
    from backend.services import database_service
    reload(database_service)
    from backend import app as app_module
    reload(app_module)

    return TestClient(app_module.app)


def test_create_and_get_text_clip(client):
    resp = client.post("/api/clips/", json={"content": "from test", "mime": "text/plain"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["content"] == "from test"
    assert body["mime"] == "text/plain"
    assert body["file_path"] is None
    clip_id = body["id"]

    r2 = client.get("/api/clips/")
    assert r2.status_code == 200
    arr = r2.json()
    assert any(c["id"] == clip_id for c in arr)


def test_image_clip_url_uses_filename_only(client):
    # Simula um clip de imagem onde o content vem como filename puro
    resp = client.post(
        "/api/clips/",
        json={"content": "img_deadbeef.png", "mime": "image/png"},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["content"].endswith("/api/images/img_deadbeef.png")
    assert body["file_path"] is not None
    assert body["file_path"].endswith("img_deadbeef.png")


def test_image_clip_with_legacy_absolute_path(client):
    # Compatibilidade: clips antigos podem ter path absoluto em content
    resp = client.post(
        "/api/clips/",
        json={"content": "/some/legacy/path/img_xyz.png", "mime": "image/png"},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["content"].endswith("/api/images/img_xyz.png")
