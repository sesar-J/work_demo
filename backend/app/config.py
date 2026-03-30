from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent.parent
CONTENT_DIR = BASE_DIR / "content" / "cases"
SQLITE_URL = f"sqlite:///{BASE_DIR / 'app.db'}"
