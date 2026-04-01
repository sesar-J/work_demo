#!/usr/bin/env bash

set -euo pipefail

MODE="${1:-ready}"
if [[ "${MODE}" != "ready" && "${MODE}" != "install" ]]; then
  echo "用法: ./start.sh [ready|install]"
  echo "  ready   已有 Python/Node 环境时启动（默认）"
  echo "  install 自动安装缺失环境后再启动"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="${ROOT_DIR}/backend"
FRONTEND_DIR="${ROOT_DIR}/frontend"
RUN_DIR="${ROOT_DIR}/.run"
BACKEND_LOG="${RUN_DIR}/backend.log"
FRONTEND_LOG="${RUN_DIR}/frontend.log"
BACKEND_PID_FILE="${RUN_DIR}/backend.pid"
FRONTEND_PID_FILE="${RUN_DIR}/frontend.pid"

print_info() { echo "[INFO] $1"; }
print_ok() { echo "[OK]   $1"; }
print_err() { echo "[ERR]  $1"; }

require_dir() {
  local path="$1"
  local name="$2"
  if [[ ! -d "${path}" ]]; then
    print_err "${name} 目录不存在: ${path}"
    exit 1
  fi
}

ensure_brew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  print_err "未找到 Homebrew，无法自动安装。请先安装 Homebrew 后重试。"
  print_info "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  exit 1
}

ensure_python() {
  if command -v python3 >/dev/null 2>&1; then
    print_ok "检测到 python3: $(python3 --version 2>&1)"
    return 0
  fi
  if [[ "${MODE}" != "install" ]]; then
    print_err "未检测到 python3。请执行: ./start.sh install"
    exit 1
  fi
  ensure_brew
  print_info "安装 Python..."
  brew install python@3.11
  print_ok "Python 安装完成: $(python3 --version 2>&1)"
}

ensure_node() {
  if command -v node >/dev/null 2>&1; then
    print_ok "检测到 Node.js: $(node --version)"
    return 0
  fi
  if [[ "${MODE}" != "install" ]]; then
    print_err "未检测到 Node.js。请执行: ./start.sh install"
    exit 1
  fi
  ensure_brew
  print_info "安装 Node.js..."
  brew install node
  print_ok "Node.js 安装完成: $(node --version)"
}

setup_backend() {
  print_info "准备后端环境..."
  cd "${BACKEND_DIR}"
  if [[ ! -d ".venv" ]]; then
    python3 -m venv .venv
  fi
  .venv/bin/python -m pip install --upgrade pip >/dev/null 2>&1 || true
  .venv/bin/python -m pip install -r requirements.txt
  print_ok "后端依赖安装完成"
}

setup_frontend() {
  print_info "准备前端环境..."
  cd "${FRONTEND_DIR}"
  npm install
  print_ok "前端依赖安装完成"
}

start_services() {
  mkdir -p "${RUN_DIR}"
  cd "${BACKEND_DIR}"
  nohup .venv/bin/uvicorn app.main:app --reload --port 8000 >"${BACKEND_LOG}" 2>&1 &
  echo $! >"${BACKEND_PID_FILE}"
  cd "${FRONTEND_DIR}"
  nohup npm run dev -- --host 127.0.0.1 --port 5173 >"${FRONTEND_LOG}" 2>&1 &
  echo $! >"${FRONTEND_PID_FILE}"
}

echo "============================================================"
echo "Hands-on 启动脚本 (macOS/Linux) - 模式: ${MODE}"
echo "============================================================"

require_dir "${BACKEND_DIR}" "backend"
require_dir "${FRONTEND_DIR}" "frontend"
ensure_python
ensure_node
setup_backend
setup_frontend
start_services

echo
print_ok "启动完成"
echo "前端: http://127.0.0.1:5173/"
echo "后端: http://127.0.0.1:8000"
echo "后端健康检查: http://127.0.0.1:8000/api/health"
echo
echo "日志:"
echo "  ${BACKEND_LOG}"
echo "  ${FRONTEND_LOG}"
echo
echo "停止服务: ./scripts/stop.sh"
