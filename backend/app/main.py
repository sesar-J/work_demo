from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session

from app.api.routes_cases import router as cases_router
from app.api.routes_sync import router as sync_router
from app.db import engine, init_db
from app.services.content_service import seed_cases_if_empty


app = FastAPI(title="Hands-on Practice Center API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup():
    init_db()
    with Session(engine) as session:
        seed_cases_if_empty(session)


@app.get("/api/health")
def health():
    return {"status": "ok"}


app.include_router(cases_router)
app.include_router(sync_router)
