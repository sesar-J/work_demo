from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.db import get_session
from app.models import Case
from app.schemas import CaseDetail, CaseListItem
from app.services.content_service import read_html_file


router = APIRouter(prefix="/api/cases", tags=["cases"])


@router.get("", response_model=list[CaseListItem])
def list_cases(session: Session = Depends(get_session)):
    rows = session.exec(select(Case)).all()
    return [
        CaseListItem(
            slug=row.slug,
            title=row.title,
            summary=row.summary,
            cover_image=row.cover_image,
        )
        for row in rows
    ]


@router.get("/{slug}", response_model=CaseDetail)
def get_case(slug: str, session: Session = Depends(get_session)):
    row = session.exec(select(Case).where(Case.slug == slug)).first()
    if not row:
        raise HTTPException(status_code=404, detail="Case not found")

    return CaseDetail(
        slug=row.slug,
        title=row.title,
        summary=row.summary,
        cover_image=row.cover_image,
        detail_html=read_html_file(row.detail_html_path),
        operation_html=read_html_file(row.operation_html_path),
        notebook_iframe_url=row.notebook_iframe_url,
    )
