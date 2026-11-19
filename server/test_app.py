"""Basic smoke tests for the public development API."""
from fastapi.testclient import TestClient
from app import app

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

def test_rooms():
    response = client.get("/v1/rooms?country=SA")
    assert response.status_code == 200
    assert all(room["country"] == "SA" for room in response.json())

def test_themes():
    response = client.get("/v1/themes")
    assert response.status_code == 200
    assert any(theme["id"] == "royal" for theme in response.json())

def test_games():
    response = client.get("/v1/games")
    assert response.status_code == 200
    assert len(response.json()) == 5
