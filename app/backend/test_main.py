"""Contract tests for the FastAPI backend (the tiny `/` + `/healthz` surface)."""

from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_healthz_returns_ok():
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_root_returns_message():
    resp = client.get("/")
    assert resp.status_code == 200
    body = resp.json()
    assert "message" in body
    assert isinstance(body["message"], str) and body["message"]
