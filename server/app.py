"""Halaa development API. No production authentication or payment processing."""
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Literal
from uuid import uuid4

app = FastAPI(title="Halaa API", version="0.1.0")

THEMES = {
    "royal": {"id": "royal", "name": "البنفسجي الملكي", "primary": "#6632A2", "background": "#170A29", "accent": "#FFD57A"},
    "black-gold": {"id": "black-gold", "name": "الأسود الذهبي", "primary": "#282020", "background": "#090909", "accent": "#FFD57A"},
    "diamond-blue": {"id": "diamond-blue", "name": "الأزرق الألماسي", "primary": "#2255B8", "background": "#091831", "accent": "#92E5FF"},
}
ROOMS = [
    {"id": "1001", "name": "المجلس الملكي", "country": "SA", "listeners": 256},
    {"id": "1002", "name": "لمة الأصدقاء", "country": "SD", "listeners": 189},
    {"id": "1003", "name": "نجوم هلاا", "country": "IQ", "listeners": 412},
]
@app.get("/health")
def health():
    return {"status": "ok", "service": "halaa-development"}

@app.get("/v1/themes")
def themes():
    return list(THEMES.values())

@app.get("/v1/rooms")
def rooms(country: str | None = None):
    return [r for r in ROOMS if not country or r["country"] == country.upper()]

@app.get("/v1/games")
def games():
    return [{"id": key, "name": name, "status": "planned"} for key, name in [
        ("ludo", "ليدو"), ("billiards", "بلياردو"), ("chess", "شطرنج"),
        ("domino", "دومينو"), ("tarneeb", "طرنيب")]]

# Never expose write/admin endpoints without server-side authentication and authorization.
