#!/usr/bin/env bash

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# 项目路径
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="${ROOT_DIR}/.run"
BACKEND_PID_FILE="${RUN_DIR}/backend.pid"
FRONTEND_PID_FILE="${RUN_DIR}/frontend.pid"
BACKEND_LOG_FILE="${RUN_DIR}/backend.log"
FRONTEND_LOG_FILE="${RUN_DIR}/frontend.log"

# 打印函数
print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_step() {
    echo -e "\n${CYAN}${BOLD}▶ $1${NC}"
}

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "mac"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# 检查 Python 版本
check_python() {
    print_step "检查 Python 环境"
    
    local python_commands=("python3.11" "python3.10" "python3.9" "python3.8" "python3" "python")
    local min_major=3
    local min_minor=8
    
    for cmd in "${python_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            local version
            version=$("$cmd" --version 2>&1 | awk '{print $2}')
            print_info "找到 $cmd: $version"
            
            local major minor
            major=$(echo "$version" | cut -d. -f1)
            minor=$(echo "$version" | cut -d. -f2)
            
            if [[ $major -gt $min_major ]] || ([[ $major -eq $min_major ]] && [[ $minor -ge $min_minor ]]); then
                print_success "Python 版本满足要求 (>= $min_major.$min_minor)"
                echo "$cmd"
                return 0
            else
                print_warning "Python 版本过低: $major.$minor < $min_major.$min_minor"
            fi
        fi
    done
    
    return 1
}

# 安装 Python - macOS
install_python_mac() {
    print_step "在 macOS 上安装 Python"
    
    if command -v brew >/dev/null 2>&1; then
        print_info "使用 Homebrew 安装 Python..."
        read -p "$(echo -e ${YELLOW}是否使用 Homebrew 安装 Python 3.11? \(y/n\): ${NC})" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            brew install python@3.11
            if [[ $? -eq 0 ]]; then
                print_success "Python 安装成功"
                return 0
            else
                print_error "安装失败"
                return 1
            fi
        fi
    else
        print_warning "未找到 Homebrew，请先安装 Homebrew:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    fi
    
    print_warning "或手动下载安装 Python: https://www.python.org/downloads/"
    return 1
}

# 安装 Python - Linux
install_python_linux() {
    print_step "在 Linux 上安装 Python"
    
    if command -v apt-get >/dev/null 2>&1; then
        print_info "使用 apt 安装 Python..."
        read -p "$(echo -e ${YELLOW}是否使用 apt 安装 Python? \(y/n\): ${NC})" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip python3-venv
            if [[ $? -eq 0 ]]; then
                print_success "Python 安装成功"
                return 0
            fi
        fi
    elif command -v yum >/dev/null 2>&1; then
        print_info "使用 yum 安装 Python..."
        read -p "$(echo -e ${YELLOW}是否使用 yum 安装 Python? \(y/n\): ${NC})" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo yum install -y python3 python3-pip
            if [[ $? -eq 0 ]]; then
                print_success "Python 安装成功"
                return 0
            fi
        fi
    elif command -v dnf >/dev/null 2>&1; then
        print_info "使用 dnf 安装 Python..."
        read -p "$(echo -e ${YELLOW}是否使用 dnf 安装 Python? \(y/n\): ${NC})" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo dnf install -y python3 python3-pip
            if [[ $? -eq 0 ]]; then
                print_success "Python 安装成功"
                return 0
            fi
        fi
    fi
    
    print_warning "请手动安装 Python 3.8+"
    return 1
}

# 确保 Python 可用
ensure_python() {
    local python_cmd
    python_cmd=$(check_python)
    
    if [[ -n "$python_cmd" ]]; then
        echo "$python_cmd"
        return 0
    fi
    
    print_warning "未找到合适的 Python 环境"
    
    local os
    os=$(detect_os)
    
    case "$os" in
        mac)
            install_python_mac
            ;;
        linux)
            install_python_linux
            ;;
        *)
            print_error "不支持的操作系统: $OSTYPE"
            return 1
            ;;
    esac
    
    check_python
}

# 检查 Node.js 版本
check_node() {
    print_step "检查 Node.js 环境"
    
    local node_commands=("node" "nodejs")
    local min_major=16
    
    for cmd in "${node_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            local version
            version=$("$cmd" --version 2>&1)
            print_info "找到 $cmd: $version"
            
            local major
            major=$(echo "$version" | sed 's/v//' | cut -d. -f1)
            
            if [[ $major -ge $min_major ]]; then
                print_success "Node.js 版本满足要求 (>= $min_major)"
                return 0
            else
                print_warning "Node.js 版本过低: $major < $min_major"
            fi
        fi
    done
    
    return 1
}

# 安装 Node.js - macOS
install_node_mac() {
    print_step "在 macOS 上安装 Node.js"
    
    if command -v brew >/dev/null 2>&1; then
        print_info "使用 Homebrew 安装 Node.js..."
        read -p "$(echo -e ${YELLOW}是否使用 Homebrew 安装 Node.js? \(y/n\): ${NC})" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            brew install node
            if [[ $? -eq 0 ]]; then
                print_success "Node.js 安装成功"
                return 0
            fi
        fi
    fi
    
    print_warning "请手动下载安装 Node.js: https://nodejs.org/"
    return 1
}

# 安装 Node.js - Linux
install_node_linux() {
    print_step "在 Linux 上安装 Node.js"
    
    if command -v apt-get >/dev/null 2>&1; then
        print_info "使用 apt 安装 Node.js..."
        read -p "$(echo -e ${YELLOW}是否使用 apt 安装 Node.js? \(y/n\): ${NC})" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
            if [[ $? -eq 0 ]]; then
                print_success "Node.js 安装成功"
                return 0
            fi
        fi
    elif command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
        print_info "使用 yum/dnf 安装 Node.js..."
        read -p "$(echo -e ${YELLOW}是否使用 yum/dnf 安装 Node.js? \(y/n\): ${NC})" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            local pkg_manager="yum"
            command -v dnf >/dev/null 2>&1 && pkg_manager="dnf"
            sudo "$pkg_manager" install -y nodejs
            if [[ $? -eq 0 ]]; then
                print_success "Node.js 安装成功"
                return 0
            fi
        fi
    fi
    
    print_warning "请手动安装 Node.js 16+"
    echo "  https://nodejs.org/"
    return 1
}

# 确保 Node.js 可用
ensure_node() {
    if check_node; then
        return 0
    fi
    
    print_warning "未找到合适的 Node.js 环境"
    
    local os
    os=$(detect_os)
    
    case "$os" in
        mac)
            install_node_mac
            ;;
        linux)
            install_node_linux
            ;;
        *)
            print_error "不支持的操作系统: $OSTYPE"
            return 1
            ;;
    esac
}

# 设置后端环境
setup_backend() {
    local python_cmd="$1"
    print_step "设置后端环境"
    
    local backend_dir="${ROOT_DIR}/backend"
    local venv_dir="${backend_dir}/.venv"
    local requirements_file="${backend_dir}/requirements.txt"
    
    if [[ ! -d "$backend_dir" ]]; then
        print_error "后端目录不存在: $backend_dir"
        return 1
    fi
    
    if [[ ! -f "$requirements_file" ]]; then
        print_error "requirements.txt 不存在: $requirements_file"
        return 1
    fi
    
    if [[ ! -d "$venv_dir" ]]; then
        print_info "创建 Python 虚拟环境..."
        "$python_cmd" -m venv "$venv_dir"
        if [[ $? -ne 0 ]]; then
            print_error "创建虚拟环境失败"
            return 1
        fi
        print_success "虚拟环境创建成功"
    fi
    
    local venv_python="${venv_dir}/bin/python"
    
    print_info "安装 Python 依赖..."
    "$venv_python" -m pip install --upgrade pip >/dev/null 2>&1
    "$venv_python" -m pip install -r "$requirements_file"
    
    if [[ $? -ne 0 ]]; then
        print_error "安装依赖失败"
        return 1
    fi
    
    print_success "后端环境设置完成"
}

# 设置前端环境
setup_frontend() {
    print_step "设置前端环境"
    
    local frontend_dir="${ROOT_DIR}/frontend"
    local package_json="${frontend_dir}/package.json"
    
    if [[ ! -d "$frontend_dir" ]]; then
        print_error "前端目录不存在: $frontend_dir"
        return 1
    fi
    
    if [[ ! -f "$package_json" ]]; then
        print_error "package.json 不存在: $package_json"
        return 1
    fi
    
    print_info "安装 Node.js 依赖..."
    (cd "$frontend_dir" && npm install)
    
    if [[ $? -ne 0 ]]; then
        print_error "安装依赖失败"
        return 1
    fi
    
    print_success "前端环境设置完成"
}

# 启动后端服务
start_backend() {
    local python_cmd="$1"
    print_step "启动后端服务"
    
    local backend_dir="${ROOT_DIR}/backend"
    local venv_dir="${backend_dir}/.venv"
    local venv_uvicorn="${venv_dir}/bin/uvicorn"
    
    mkdir -p "${RUN_DIR}"
    
    if [[ -f "${BACKEND_PID_FILE}" ]] && kill -0 "$(cat "${BACKEND_PID_FILE}")" 2>/dev/null; then
        print_warning "后端服务已在运行 (PID=$(cat "${BACKEND_PID_FILE}"))"
        return 0
    fi
    
    print_info "启动 FastAPI 服务..."
    
    (
        cd "${backend_dir}"
        source .venv/bin/activate
        uvicorn app.main:app --reload --port 8000
    ) >"${BACKEND_LOG_FILE}" 2>&1 &
    
    echo $! >"${BACKEND_PID_FILE}"
    print_success "后端服务已启动 (PID=$(cat "${BACKEND_PID_FILE}"))"
    print_info "日志文件: ${BACKEND_LOG_FILE}"
}

# 启动前端服务
start_frontend() {
    print_step "启动前端服务"
    
    local frontend_dir="${ROOT_DIR}/frontend"
    
    mkdir -p "${RUN_DIR}"
    
    if [[ -f "${FRONTEND_PID_FILE}" ]] && kill -0 "$(cat "${FRONTEND_PID_FILE}")" 2>/dev/null; then
        print_warning "前端服务已在运行 (PID=$(cat "${FRONTEND_PID_FILE}"))"
        return 0
    fi
    
    print_info "启动 Vite 开发服务器..."
    
    (
        cd "${frontend_dir}"
        npm run dev -- --host 127.0.0.1 --port 5173
    ) >"${FRONTEND_LOG_FILE}" 2>&1 &
    
    echo $! >"${FRONTEND_PID_FILE}"
    print_success "前端服务已启动 (PID=$(cat "${FRONTEND_PID_FILE}"))"
    print_info "日志文件: ${FRONTEND_LOG_FILE}"
}

# 主程序
main() {
    echo -e "\n${MAGENTA}${BOLD}============================================================${NC}"
    echo -e "${MAGENTA}${BOLD}  Hands-on 实践中心 - macOS/Linux 启动脚本${NC}"
    echo -e "${MAGENTA}${BOLD}============================================================${NC}\n"
    
    local os
    os=$(detect_os)
    print_info "操作系统: $os"
    print_info "项目目录: ${ROOT_DIR}"
    
    # 检查环境
    local python_cmd
    python_cmd=$(ensure_python)
    if [[ -z "$python_cmd" ]]; then
        exit 1
    fi
    
    if ! ensure_node; then
        exit 1
    fi
    
    # 设置环境
    if ! setup_backend "$python_cmd"; then
        exit 1
    fi
    
    if ! setup_frontend; then
        exit 1
    fi
    
    # 启动服务
    if ! start_backend "$python_cmd"; then
        exit 1
    fi
    
    if ! start_frontend; then
        # 如果前端启动失败，停止后端
        if [[ -f "${BACKEND_PID_FILE}" ]]; then
            kill "$(cat "${BACKEND_PID_FILE}")" 2>/dev/null || true
            rm -f "${BACKEND_PID_FILE}"
        fi
        exit 1
    fi
    
    # 打印成功信息
    echo -e "\n${GREEN}${BOLD}============================================================${NC}"
    echo -e "${GREEN}${BOLD}  启动成功！${NC}"
    echo -e "${GREEN}${BOLD}============================================================${NC}\n"
    
    echo -e "${CYAN}前端地址:${NC} http://127.0.0.1:5173/"
    echo -e "${CYAN}后端地址:${NC} http://127.0.0.1:8000"
    echo -e "${CYAN}健康检查:${NC} http://127.0.0.1:8000/api/health"
    
    echo -e "\n${YELLOW}查看日志:${NC}"
    echo "  后端: tail -f ${BACKEND_LOG_FILE}"
    echo "  前端: tail -f ${FRONTEND_LOG_FILE}"
    
    echo -e "\n${YELLOW}停止服务:${NC}"
    echo "  Bash:   bash scripts/stop.sh"
    echo "  Python: python scripts/stop.py"
    
    echo -e "\n${CYAN}按 Ctrl+C 停止所有服务...${NC}\n"
    
    # 等待进程
    wait
}

# 运行主程序
main "$@"
