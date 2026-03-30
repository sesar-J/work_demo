import json
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Set

from nbconvert import HTMLExporter
from nbformat import read as nb_read
from sqlmodel import Session, select

from app.config import BASE_DIR, CONTENT_DIR
from app.models import Case


def read_html_file(path: str) -> str:
    file_path = Path(path)
    if not file_path.exists():
        return "<p>内容暂未生成。</p>"
    return file_path.read_text(encoding="utf-8")


def convert_ipynb_to_html(source_path: Path, target_path: Path) -> None:
    with source_path.open("r", encoding="utf-8") as fp:
        notebook = nb_read(fp, as_version=4)
    exporter = HTMLExporter()
    body, _ = exporter.from_notebook_node(notebook)
    target_path.parent.mkdir(parents=True, exist_ok=True)
    target_path.write_text(body, encoding="utf-8")


def load_case_manifest(case_dir: Path) -> Dict[str, str]:
    manifest_file = case_dir / "case.json"
    if not manifest_file.exists():
        raise ValueError(f"Missing case.json in {case_dir}")
    with manifest_file.open("r", encoding="utf-8") as fp:
        return json.load(fp)


def _extract_candidate_slugs_from_paths(paths: Iterable[str]) -> Set[str]:
    # path 形态示例: "cases/sample-vpc/detail.ipynb" 或 "sample-vpc/detail.ipynb"
    slugs: Set[str] = set()
    for path in paths:
        clean = path.strip("/")
        parts = clean.split("/")
        if len(parts) >= 3 and parts[0] == "cases":
            slugs.add(parts[1])
        elif len(parts) >= 2:
            slugs.add(parts[0])
    return slugs


def rebuild_cases_from_ipynb(session: Session, changed_paths: Optional[List[str]] = None) -> int:
    generated_root = BASE_DIR / "content" / "generated"
    case_dirs = [p for p in CONTENT_DIR.iterdir() if p.is_dir() and (p / "case.json").exists()]
    allowed_slugs: Optional[Set[str]] = None
    if changed_paths:
        allowed_slugs = _extract_candidate_slugs_from_paths(changed_paths)

    processed = 0
    for case_dir in case_dirs:
        manifest = load_case_manifest(case_dir)
        slug = manifest["slug"]
        if allowed_slugs is not None and slug not in allowed_slugs:
            continue

        detail_nb = case_dir / manifest["detail_notebook"]
        operation_nb = case_dir / manifest["operation_notebook"]
        detail_html = generated_root / slug / "detail.html"
        operation_html = generated_root / slug / "operation.html"
        convert_ipynb_to_html(detail_nb, detail_html)
        convert_ipynb_to_html(operation_nb, operation_html)

        existing = session.exec(select(Case).where(Case.slug == slug)).first()
        if existing:
            existing.title = manifest["title"]
            existing.summary = manifest["summary"]
            existing.cover_image = manifest.get("cover_image")
            existing.detail_html_path = str(detail_html)
            existing.operation_html_path = str(operation_html)
            existing.notebook_iframe_url = manifest.get(
                "notebook_iframe_url", "https://jupyter.org/try-jupyter/lab/"
            )
        else:
            session.add(
                Case(
                    slug=slug,
                    title=manifest["title"],
                    summary=manifest["summary"],
                    cover_image=manifest.get("cover_image"),
                    detail_html_path=str(detail_html),
                    operation_html_path=str(operation_html),
                    notebook_iframe_url=manifest.get(
                        "notebook_iframe_url", "https://jupyter.org/try-jupyter/lab/"
                    ),
                )
            )
        processed += 1
    session.commit()
    return processed


def seed_cases_if_empty(session: Session) -> None:
    rebuild_cases_from_ipynb(session)
