import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Read allowed origins from env: "http://site.local,https://example.com"
raw = os.getenv("CORS_ORIGINS", "http://site.local")
allow_origins = [o.strip() for o in raw.split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allow_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"message": "Hello from backend (api.site.local)!"}

@app.get("/healthz")
def healthz():
    return {"status": "ok"}
