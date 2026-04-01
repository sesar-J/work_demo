import os
from datetime import datetime, timedelta
from typing import Dict, Optional
from urllib.parse import urlencode
from uuid import uuid4


# 内存会话：用于 demo 展示“用户+案例独立环境”，不做持久化。
LAB_SESSIONS: Dict[str, Dict[str, str]] = {}


def build_notebook_url(base_url: str, params: Dict[str, str]) -> str:
    separator = "&" if "?" in base_url else "?"
    return f"{base_url}{separator}{urlencode(params)}"


def create_lab_session(
    case_slug: str,
    user_id: Optional[str] = None,
    ak: str = "",
    sk: str = "",
    notebook_base_url: Optional[str] = None,
) -> Dict[str, str]:
    session_id = str(uuid4())
    expires_at = (datetime.utcnow() + timedelta(hours=2)).isoformat() + "Z"
    normalized_user = user_id.strip() if user_id else f"guest-{session_id[:8]}"

    base_url = notebook_base_url or os.getenv("NOTEBOOK_BASE_URL", "https://jupyter.org/try-jupyter/lab/")
    notebook_url = build_notebook_url(
        base_url,
        {
            "session_id": session_id,
            "case_slug": case_slug,
            "user_id": normalized_user,
        },
    )

    LAB_SESSIONS[session_id] = {
        "session_id": session_id,
        "case_slug": case_slug,
        "user_id": normalized_user,
        "ak_masked": f"{ak[:4]}****{ak[-2:]}" if len(ak) >= 6 else "",
        "sk_masked": "********" if sk else "",
        "notebook_url": notebook_url,
        "expires_at": expires_at,
    }
    return LAB_SESSIONS[session_id]


def terraform_template() -> Dict[str, str]:
    return {
        "versions.tf": """terraform {
  required_version = ">= 1.5.0"
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.50.0"
    }
  }
}
""",
        "provider.tf": """provider "huaweicloud" {
  region = var.region
}
""",
        "variables.tf": """variable "region" {
  type    = string
  default = "cn-north-4"
}
""",
        "main.tf": """# 这里根据具体案例补资源，例如 VPC/ECS/RDS/OBS
output "case_name" {
  value = "hands-on-unified-template"
}
""",
        "terraform.tfvars": """region = "cn-north-4"
""",
        "commands": """export HW_ACCESS_KEY="<输入你的AK>"
export HW_SECRET_KEY="<输入你的SK>"
terraform init
terraform plan
terraform apply -auto-approve
""",
    }
