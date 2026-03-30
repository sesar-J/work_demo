import hashlib
import hmac
import subprocess
from typing import Optional

from fastapi import HTTPException

from app.config import BASE_DIR


def verify_webhook_signature(
    body: bytes,
    signature: Optional[str],
    secret: Optional[str],
    gitcode_token: Optional[str] = None,
) -> None:
    if not secret:
        return
    if gitcode_token and gitcode_token == secret:
        return
    if not signature:
        raise HTTPException(status_code=401, detail="Missing signature or token")

    expected = "sha256=" + hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, signature):
        raise HTTPException(status_code=401, detail="Invalid signature")


def pull_latest_content() -> str:
    # 这里假设案例内容仓库已经在 backend/content 中通过 git clone 初始化
    content_repo = BASE_DIR / "content"
    result = subprocess.run(
        ["git", "-C", str(content_repo), "pull"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise HTTPException(status_code=500, detail=f"Git pull failed: {result.stderr.strip()}")
    return result.stdout.strip() or "No updates"
