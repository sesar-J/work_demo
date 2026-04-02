import os
import re
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Header, Request
from pydantic import BaseModel
from sqlmodel import Session, select

from app.db import engine
from app.models import SyncEventLog
from app.services.content_service import rebuild_cases_from_ipynb
from app.services.git_sync_service import pull_latest_content, verify_webhook_signature


router = APIRouter(prefix="/api/sync", tags=["sync"])


class SyncResponse(BaseModel):
    message: str
    git_output: str
    source: str


class SyncStatusResponse(BaseModel):
    source: str
    status: str
    message: str
    created_at: str


def _extract_branch(payload: Dict[str, Any]) -> Optional[str]:
    ref = payload.get("ref")
    if isinstance(ref, str):
        if ref.startswith("refs/heads/"):
            return ref.replace("refs/heads/", "", 1)
        return ref

    for key in ("target_branch", "targetBranch", "branch"):
        value = payload.get(key)
        if isinstance(value, str):
            return value

    push_data = payload.get("push_data")
    if isinstance(push_data, dict):
        push_ref = push_data.get("ref")
        if isinstance(push_ref, str):
            return push_ref.replace("refs/heads/", "", 1)

    return None


def _extract_changed_paths(payload: Dict[str, Any]) -> List[str]:
    paths: List[str] = []

    commits = payload.get("commits")
    if isinstance(commits, list):
        for commit in commits:
            if not isinstance(commit, dict):
                continue
            for key in ("added", "modified", "removed"):
                files = commit.get(key, [])
                if isinstance(files, list):
                    paths.extend([f for f in files if isinstance(f, str)])

    head_commit = payload.get("head_commit")
    if isinstance(head_commit, dict):
        for key in ("added", "modified", "removed"):
            files = head_commit.get(key, [])
            if isinstance(files, list):
                paths.extend([f for f in files if isinstance(f, str)])

    push_data = payload.get("push_data")
    if isinstance(push_data, dict) and isinstance(push_data.get("commits"), list):
        for commit in push_data["commits"]:
            if not isinstance(commit, dict):
                continue
            for key in ("added", "modified", "removed"):
                files = commit.get(key, [])
                if isinstance(files, list):
                    paths.extend([f for f in files if isinstance(f, str)])

    # 去重并保持顺序
    return list(dict.fromkeys(paths))


def _allowed_branches() -> List[str]:
    raw = os.getenv("SYNC_BRANCHES", "main,master")
    return [item.strip() for item in raw.split(",") if item.strip()]


def _repo_name(payload: Dict[str, Any]) -> str:
    repo = payload.get("repository")
    if isinstance(repo, dict):
        full_name = repo.get("full_name")
        if isinstance(full_name, str):
            return full_name
        name = repo.get("name")
        if isinstance(name, str):
            return name
        path_with_namespace = repo.get("path_with_namespace")
        if isinstance(path_with_namespace, str):
            return path_with_namespace
    project = payload.get("project")
    if isinstance(project, dict):
        name = project.get("name")
        if isinstance(name, str):
            return name
        path_with_namespace = project.get("path_with_namespace")
        if isinstance(path_with_namespace, str):
            return path_with_namespace
    return ""


def _is_dtse_repo(payload: Dict[str, Any]) -> bool:
    current = _repo_name(payload).lower()
    expected = os.getenv("DTSE_REPO", "").strip().lower()
    if expected:
        return current == expected or current.endswith("/" + expected)
    return "dtse" in current


def _friendly_sync_message(source: str, status: str, raw_message: str) -> str:
    if status == "skipped":
        if "non-dtse repo" in raw_message:
            return "已忽略非 DTSE 案例仓的推送事件。"
        if raw_message.startswith("skip branch:"):
            branch = raw_message.split(":", 1)[-1].strip()
            return f"已忽略分支 {branch} 的推送事件。"
        return "本次同步事件已按规则忽略。"

    if status != "success":
        return "同步状态异常，请稍后重试。"

    manual_match = re.search(r"cases=(\d+)", raw_message)
    if manual_match:
        return f"已完成案例内容重建，共 {manual_match.group(1)} 个案例。"

    webhook_match = re.search(r"rebuilt_cases=(\d+)", raw_message)
    if webhook_match:
        return f"已完成案例内容同步，本次更新 {webhook_match.group(1)} 个案例。"

    if source == "manual":
        return "已完成手动重建。"
    return "已完成案例内容同步。"


@router.post("/git-event", response_model=SyncResponse)
async def sync_from_git_event(
    request: Request,
    x_hub_signature_256: Optional[str] = Header(default=None),
    x_gitcode_token: Optional[str] = Header(default=None),
    x_codearts_signature: Optional[str] = Header(default=None),
):
    body = await request.body()
    payload: Dict[str, Any] = await request.json()
    signature = x_hub_signature_256 or x_codearts_signature
    verify_webhook_signature(body, signature, os.getenv("GIT_WEBHOOK_SECRET"), x_gitcode_token)

    if not _is_dtse_repo(payload):
        with Session(engine) as session:
            session.add(SyncEventLog(source="codearts-or-gitcode", status="skipped", message="skip non-dtse repo"))
            session.commit()
        return SyncResponse(message="跳过非 DTSE 案例仓", git_output="skipped", source="codearts-or-gitcode")

    branch = _extract_branch(payload)
    allowed = _allowed_branches()
    if branch and branch not in allowed:
        with Session(engine) as session:
            session.add(
                SyncEventLog(source="codearts-or-gitcode", status="skipped", message=f"skip branch: {branch}")
            )
            session.commit()
        return SyncResponse(message=f"跳过分支 {branch}", git_output="skipped", source="codearts-or-gitcode")

    changed_paths = _extract_changed_paths(payload)
    output = pull_latest_content()
    with Session(engine) as session:
        changed_count = rebuild_cases_from_ipynb(session, changed_paths=changed_paths or None)
        session.add(
            SyncEventLog(
                source="codearts-or-gitcode",
                status="success",
                message=f"{output or 'No updates'}; rebuilt_cases={changed_count}",
            )
        )
        session.commit()
    return SyncResponse(message="同步成功", git_output=output, source="codearts-or-gitcode")


@router.post("/rebuild", response_model=SyncResponse)
def rebuild_now():
    with Session(engine) as session:
        changed_count = rebuild_cases_from_ipynb(session)
        session.add(SyncEventLog(source="manual", status="success", message=f"manual rebuild; cases={changed_count}"))
        session.commit()
    return SyncResponse(
        message=f"已完成案例内容重建，共 {changed_count} 个案例。",
        git_output="manual rebuild",
        source="manual",
    )


@router.get("/status", response_model=SyncStatusResponse)
def sync_status():
    with Session(engine) as session:
        latest = session.exec(select(SyncEventLog).order_by(SyncEventLog.id.desc())).first()
        if not latest:
            return SyncStatusResponse(source="none", status="idle", message="暂无同步记录", created_at="")
        friendly_message = _friendly_sync_message(
            source=latest.source,
            status=latest.status,
            raw_message=latest.message,
        )
        return SyncStatusResponse(
            source=latest.source,
            status=latest.status,
            message=friendly_message,
            created_at=latest.created_at.isoformat(),
        )
