from datetime import datetime
from typing import Optional

from sqlmodel import Field, SQLModel


class Case(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    slug: str = Field(index=True, unique=True)
    title: str
    summary: str
    cover_image: Optional[str] = None
    detail_html_path: str
    operation_html_path: str
    notebook_iframe_url: str = "https://jupyter.org/try-jupyter/lab/"


class SyncEventLog(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    source: str
    status: str
    message: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
