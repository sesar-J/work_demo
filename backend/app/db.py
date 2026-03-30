from sqlmodel import Session, SQLModel, create_engine

from .config import SQLITE_URL


engine = create_engine(SQLITE_URL, echo=False)


def init_db() -> None:
    SQLModel.metadata.create_all(engine)


def get_session():
    with Session(engine) as session:
        yield session
