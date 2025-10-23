from fastapi.testclient import TestClient

from backend.app import app


client = TestClient(app)


def test_create_and_get_clip():
    # create a clip
    resp = client.post("/api/clips/", json={"content": "from test", "mime": "text/plain"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["content"] == "from test"
    clip_id = body["id"]

    # get list
    r2 = client.get("/api/clips/")
    assert r2.status_code == 200
    arr = r2.json()
    assert any(c["id"] == clip_id for c in arr)
