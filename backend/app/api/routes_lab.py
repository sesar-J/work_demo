from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field, model_validator
from sqlmodel import Session, select

from app.db import engine
from app.models import Case
from app.services.lab_service import create_lab_session, terraform_template


router = APIRouter(prefix="/api/lab", tags=["lab"])


class LabSessionCreateRequest(BaseModel):
    case_slug: str
    user_id: str | None = Field(default=None, min_length=2, max_length=64)
    ak: str = Field(default="", max_length=128)
    sk: str = Field(default="", max_length=128)

    @model_validator(mode="after")
    def validate_ak_sk_pair(self):
        if bool(self.ak) != bool(self.sk):
            raise ValueError("AK 和 SK 需要同时填写或同时留空")
        return self


class LabSessionCreateResponse(BaseModel):
    session_id: str
    case_slug: str
    user_id: str
    notebook_url: str
    expires_at: str


@router.post("/session", response_model=LabSessionCreateResponse)
def create_session(payload: LabSessionCreateRequest):
    with Session(engine) as session:
        case = session.exec(select(Case).where(Case.slug == payload.case_slug)).first()
        if not case:
            raise HTTPException(status_code=404, detail="Case not found")

    data = create_lab_session(
        case_slug=payload.case_slug,
        user_id=payload.user_id,
        ak=payload.ak,
        sk=payload.sk,
        notebook_base_url=case.notebook_iframe_url,
    )
    return LabSessionCreateResponse(
        session_id=data["session_id"],
        case_slug=data["case_slug"],
        user_id=data["user_id"],
        notebook_url=data["notebook_url"],
        expires_at=data["expires_at"],
    )


@router.get("/terraform-template")
def get_terraform_template():
    return terraform_template()
