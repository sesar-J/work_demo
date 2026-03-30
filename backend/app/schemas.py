from typing import Optional

from pydantic import BaseModel


class CaseListItem(BaseModel):
    slug: str
    title: str
    summary: str
    cover_image: Optional[str] = None


class CaseDetail(BaseModel):
    slug: str
    title: str
    summary: str
    cover_image: Optional[str] = None
    detail_html: str
    operation_html: str
    notebook_iframe_url: str
