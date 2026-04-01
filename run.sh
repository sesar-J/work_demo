#!/usr/bin/env bash

set -euo pipefail

ACTION="${1:-start}"
if [[ "${ACTION}" != "start" && "${ACTION}" != "install" && "${ACTION}" != "stop" ]]; then
  echo "用法: ./run.sh [start|install|stop]"
  echo "  start   已有环境时一键启动（默认）"
  echo "  install 自动安装缺失环境后启动"
  echo "  stop    停止前后端"
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

stop_port() {
  local port="$1"
  local name="$2"
  local pids
  pids="$(lsof -t -iTCP:${port} -sTCP:LISTEN 2>/dev/null || true)"
  if [[ -z "${pids}" ]]; then
    print_info "${name} 未运行 (port ${port})"
    return
  fi
  for pid in ${pids}; do
    kill "${pid}" 2>/dev/null || true
    print_ok "已停止 ${name} (port ${port}, pid=${pid})"
  done
}

stop_all() {
  stop_port 8000 "backend"
  stop_port 5173 "frontend"
  rm -f "${BACKEND_PID_FILE}" "${FRONTEND_PID_FILE}"
  print_ok "停止完成"
}

ensure_brew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  print_err "未找到 Homebrew，无法自动安装环境。"
  print_info "先执行: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  exit 1
}

ensure_python() {
  if command -v python3 >/dev/null 2>&1; then
    print_ok "Python: $(python3 --version 2>&1)"
    return 0
  fi
  if [[ "${ACTION}" != "install" ]]; then
    print_err "未检测到 Python，请执行 ./run.sh install"
    exit 1
  fi
  ensure_brew
  print_info "安装 Python..."
  brew install python@3.11
  print_ok "Python: $(python3 --version 2>&1)"
}

ensure_node() {
  if command -v node >/dev/null 2>&1; then
    print_ok "Node: $(node --version)"
    return 0
  fi
  if [[ "${ACTION}" != "install" ]]; then
    print_err "未检测到 Node.js，请执行 ./run.sh install"
    exit 1
  fi
  ensure_brew
  print_info "安装 Node.js..."
  brew install node
  print_ok "Node: $(node --version)"
}

setup_backend() {
  cd "${BACKEND_DIR}"
  if [[ ! -d ".venv" ]]; then
    python3 -m venv .venv
  fi
  .venv/bin/python -m pip install --upgrade pip >/dev/null 2>&1 || true
  .venv/bin/python -m pip install -r requirements.txt
  print_ok "后端依赖已就绪"
}

setup_frontend() {
  cd "${FRONTEND_DIR}"
  npm install
  print_ok "前端依赖已就绪"
}

start_services() {
  mkdir -p "${RUN_DIR}"

  stop_port 8000 "backend"
  stop_port 5173 "frontend"

  cd "${BACKEND_DIR}"
  nohup .venv/bin/python -m uvicorn app.main:app --reload --port 8000 >"${BACKEND_LOG}" 2>&1 &
  echo $! >"${BACKEND_PID_FILE}"

  cd "${FRONTEND_DIR}"
  nohup npm run dev -- --host 127.0.0.1 --port 5173 >"${FRONTEND_LOG}" 2>&1 &
  echo $! >"${FRONTEND_PID_FILE}"

  print_ok "启动完成"
  echo "前端: http://127.0.0.1:5173/"
  echo "后端: http://127.0.0.1:8000"
  echo "日志: ${BACKEND_LOG} / ${FRONTEND_LOG}"
}

if [[ "${ACTION}" == "stop" ]]; then
  stop_all
  exit 0
fi

if [[ ! -d "${BACKEND_DIR}" || ! -d "${FRONTEND_DIR}" ]]; then
  print_err "缺少 backend/frontend 目录，请在项目根目录执行。"
  exit 1
fi

ensure_python
ensure_node
setup_backend
setup_frontend
start_services
