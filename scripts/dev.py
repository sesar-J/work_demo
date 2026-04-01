#!/usr/bin/env python3
"""
跨平台启动脚本 - 支持 macOS、Linux、Windows
自动检测和安装 Python、Node.js 环境
"""

import os
import sys
import subprocess
import platform
import shutil
import urllib.request
import json
from pathlib import Path
from typing import Optional, Tuple


class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    RESET = '\033[0m'
    BOLD = '\033[1m'


def print_info(msg: str):
    print(f"{Colors.BLUE}ℹ {msg}{Colors.RESET}")


def print_success(msg: str):
    print(f"{Colors.GREEN}✓ {msg}{Colors.RESET}")


def print_warning(msg: str):
    print(f"{Colors.YELLOW}⚠ {msg}{Colors.RESET}")


def print_error(msg: str):
    print(f"{Colors.RED}✗ {msg}{Colors.RESET}")


def print_step(step: str):
    print(f"\n{Colors.CYAN}{Colors.BOLD}▶ {step}{Colors.RESET}")


def run_command(cmd: list, cwd: Optional[Path] = None, check: bool = True) -> Tuple[int, str, str]:
    """运行命令并返回结果"""
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            check=False
        )
        return result.returncode, result.stdout, result.stderr
    except Exception as e:
        return 1, "", str(e)


def get_system_info() -> dict:
    """获取系统信息"""
    return {
        'system': platform.system(),
        'machine': platform.machine(),
        'python_version': platform.python_version(),
        'is_windows': platform.system() == 'Windows',
        'is_mac': platform.system() == 'Darwin',
        'is_linux': platform.system() == 'Linux',
    }


def check_python_version(min_version: Tuple[int, int] = (3, 8)) -> Optional[str]:
    """检查 Python 版本"""
    print_step("检查 Python 环境")
    
    python_commands = ['python3', 'python']
    
    for cmd in python_commands:
        try:
            result = subprocess.run(
                [cmd, '--version'],
                capture_output=True,
                text=True,
                check=False
            )
            
            if result.returncode == 0:
                version_str = result.stdout.strip() or result.stderr.strip()
                print_info(f"找到 {cmd}: {version_str}")
                
                version_parts = version_str.split()[1].split('.')
                major, minor = int(version_parts[0]), int(version_parts[1])
                
                if (major, minor) >= min_version:
                    print_success(f"Python 版本满足要求 (>= {min_version[0]}.{min_version[1]})")
                    return cmd
                else:
                    print_warning(f"Python 版本过低: {major}.{minor} < {min_version[0]}.{min_version[1]}")
        except Exception:
            continue
    
    return None


def install_python_mac() -> bool:
    """在 macOS 上安装 Python"""
    print_step("在 macOS 上安装 Python")
    
    if shutil.which('brew'):
        print_info("使用 Homebrew 安装 Python...")
        code, _, err = run_command(['brew', 'install', 'python@3.11'])
        if code == 0:
            print_success("Python 安装成功")
            return True
        else:
            print_error(f"安装失败: {err}")
            return False
    else:
        print_warning("未找到 Homebrew，请先安装 Homebrew:")
        print("  /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"")
        print("\n或手动下载安装 Python: https://www.python.org/downloads/")
        return False


def install_python_windows() -> bool:
    """在 Windows 上安装 Python"""
    print_step("在 Windows 上安装 Python")
    
    if shutil.which('winget'):
        print_info("使用 winget 安装 Python...")
        code, _, err = run_command(['winget', 'install', 'Python.Python.3.11'])
        if code == 0:
            print_success("Python 安装成功，请重新打开终端")
            return True
        else:
            print_error(f"安装失败: {err}")
    
    if shutil.which('choco'):
        print_info("使用 Chocolatey 安装 Python...")
        code, _, err = run_command(['choco', 'install', 'python', '-y'])
        if code == 0:
            print_success("Python 安装成功，请重新打开终端")
            return True
        else:
            print_error(f"安装失败: {err}")
    
    print_warning("未找到包管理器，请手动下载安装 Python:")
    print("  https://www.python.org/downloads/")
    print("\n安装时请勾选 'Add Python to PATH'")
    return False


def install_python_linux() -> bool:
    """在 Linux 上安装 Python"""
    print_step("在 Linux 上安装 Python")
    
    if shutil.which('apt-get'):
        print_info("使用 apt 安装 Python...")
        code, _, err = run_command(['sudo', 'apt-get', 'update'])
        code, _, err = run_command(['sudo', 'apt-get', 'install', '-y', 'python3', 'python3-pip', 'python3-venv'])
        if code == 0:
            print_success("Python 安装成功")
            return True
    elif shutil.which('yum'):
        print_info("使用 yum 安装 Python...")
        code, _, err = run_command(['sudo', 'yum', 'install', '-y', 'python3', 'python3-pip'])
        if code == 0:
            print_success("Python 安装成功")
            return True
    elif shutil.which('dnf'):
        print_info("使用 dnf 安装 Python...")
        code, _, err = run_command(['sudo', 'dnf', 'install', '-y', 'python3', 'python3-pip'])
        if code == 0:
            print_success("Python 安装成功")
            return True
    
    print_warning("请手动安装 Python 3.8+")
    return False


def ensure_python() -> Optional[str]:
    """确保 Python 环境可用"""
    python_cmd = check_python_version()
    
    if python_cmd:
        return python_cmd
    
    sys_info = get_system_info()
    
    print_warning("未找到合适的 Python 环境")
    
    response = input(f"\n{Colors.YELLOW}是否自动安装 Python? (y/n): {Colors.RESET}")
    
    if response.lower() != 'y':
        print_error("需要 Python 3.8+ 才能继续")
        return None
    
    if sys_info['is_mac']:
        success = install_python_mac()
    elif sys_info['is_windows']:
        success = install_python_windows()
    elif sys_info['is_linux']:
        success = install_python_linux()
    else:
        print_error(f"不支持的操作系统: {sys_info['system']}")
        return None
    
    if success:
        return check_python_version()
    
    return None


def check_node_version(min_version: Tuple[int, int] = (16, 0)) -> Optional[str]:
    """检查 Node.js 版本"""
    print_step("检查 Node.js 环境")
    
    node_commands = ['node', 'nodejs']
    
    for cmd in node_commands:
        if shutil.which(cmd):
            try:
                result = subprocess.run(
                    [cmd, '--version'],
                    capture_output=True,
                    text=True,
                    check=False
                )
                
                if result.returncode == 0:
                    version_str = result.stdout.strip()
                    print_info(f"找到 {cmd}: {version_str}")
                    
                    version_parts = version_str.lstrip('v').split('.')
                    major, minor = int(version_parts[0]), int(version_parts[1])
                    
                    if (major, minor) >= min_version:
                        print_success(f"Node.js 版本满足要求 (>= {min_version[0]}.{min_version[1]})")
                        return cmd
                    else:
                        print_warning(f"Node.js 版本过低: {major}.{minor} < {min_version[0]}.{min_version[1]}")
            except Exception:
                continue
    
    return None


def install_node_mac() -> bool:
    """在 macOS 上安装 Node.js"""
    print_step("在 macOS 上安装 Node.js")
    
    if shutil.which('brew'):
        print_info("使用 Homebrew 安装 Node.js...")
        code, _, err = run_command(['brew', 'install', 'node'])
        if code == 0:
            print_success("Node.js 安装成功")
            return True
        else:
            print_error(f"安装失败: {err}")
            return False
    else:
        print_warning("未找到 Homebrew，请手动下载安装 Node.js:")
        print("  https://nodejs.org/")
        return False


def install_node_windows() -> bool:
    """在 Windows 上安装 Node.js"""
    print_step("在 Windows 上安装 Node.js")
    
    if shutil.which('winget'):
        print_info("使用 winget 安装 Node.js...")
        code, _, err = run_command(['winget', 'install', 'OpenJS.NodeJS.LTS'])
        if code == 0:
            print_success("Node.js 安装成功，请重新打开终端")
            return True
        else:
            print_error(f"安装失败: {err}")
    
    if shutil.which('choco'):
        print_info("使用 Chocolatey 安装 Node.js...")
        code, _, err = run_command(['choco', 'install', 'nodejs', '-y'])
        if code == 0:
            print_success("Node.js 安装成功，请重新打开终端")
            return True
        else:
            print_error(f"安装失败: {err}")
    
    print_warning("未找到包管理器，请手动下载安装 Node.js:")
    print("  https://nodejs.org/")
    return False


def install_node_linux() -> bool:
    """在 Linux 上安装 Node.js"""
    print_step("在 Linux 上安装 Node.js")
    
    if shutil.which('apt-get'):
        print_info("使用 apt 安装 Node.js...")
        code, _, err = run_command(['curl', '-fsSL', 'https://deb.nodesource.com/setup_lts.x', '-o', '/tmp/nodesource_setup.sh'])
        if code == 0:
            code, _, err = run_command(['sudo', 'bash', '/tmp/nodesource_setup.sh'])
            code, _, err = run_command(['sudo', 'apt-get', 'install', '-y', 'nodejs'])
            if code == 0:
                print_success("Node.js 安装成功")
                return True
    elif shutil.which('yum') or shutil.which('dnf'):
        print_info("使用 yum/dnf 安装 Node.js...")
        code, _, err = run_command(['curl', '-fsSL', 'https://rpm.nodesource.com/setup_lts.x', '-o', '/tmp/nodesource_setup.sh'])
        if code == 0:
            code, _, err = run_command(['sudo', 'bash', '/tmp/nodesource_setup.sh'])
            pkg_manager = 'dnf' if shutil.which('dnf') else 'yum'
            code, _, err = run_command(['sudo', pkg_manager, 'install', '-y', 'nodejs'])
            if code == 0:
                print_success("Node.js 安装成功")
                return True
    
    print_warning("请手动安装 Node.js 16+")
    print("  https://nodejs.org/")
    return False


def ensure_node() -> bool:
    """确保 Node.js 环境可用"""
    if check_node_version():
        return True
    
    sys_info = get_system_info()
    
    print_warning("未找到合适的 Node.js 环境")
    
    response = input(f"\n{Colors.YELLOW}是否自动安装 Node.js? (y/n): {Colors.RESET}")
    
    if response.lower() != 'y':
        print_error("需要 Node.js 16+ 才能继续")
        return False
    
    if sys_info['is_mac']:
        return install_node_mac()
    elif sys_info['is_windows']:
        return install_node_windows()
    elif sys_info['is_linux']:
        return install_node_linux()
    else:
        print_error(f"不支持的操作系统: {sys_info['system']}")
        return False


def setup_backend(root_dir: Path, python_cmd: str) -> bool:
    """设置后端环境"""
    print_step("设置后端环境")
    
    backend_dir = root_dir / 'backend'
    venv_dir = backend_dir / '.venv'
    requirements_file = backend_dir / 'requirements.txt'
    
    if not backend_dir.exists():
        print_error(f"后端目录不存在: {backend_dir}")
        return False
    
    if not requirements_file.exists():
        print_error(f"requirements.txt 不存在: {requirements_file}")
        return False
    
    sys_info = get_system_info()
    
    if not venv_dir.exists():
        print_info("创建 Python 虚拟环境...")
        code, _, err = run_command([python_cmd, '-m', 'venv', str(venv_dir)])
        if code != 0:
            print_error(f"创建虚拟环境失败: {err}")
            return False
        print_success("虚拟环境创建成功")
    
    venv_python = venv_dir / ('Scripts' if sys_info['is_windows'] else 'bin') / ('python.exe' if sys_info['is_windows'] else 'python')
    
    if not venv_python.exists():
        print_error(f"虚拟环境 Python 不存在: {venv_python}")
        return False
    
    print_info("安装 Python 依赖...")
    code, _, err = run_command([str(venv_python), '-m', 'pip', 'install', '--upgrade', 'pip'])
    code, out, err = run_command([str(venv_python), '-m', 'pip', 'install', '-r', str(requirements_file)])
    
    if code != 0:
        print_error(f"安装依赖失败: {err}")
        return False
    
    print_success("后端环境设置完成")
    return True


def setup_frontend(root_dir: Path) -> bool:
    """设置前端环境"""
    print_step("设置前端环境")
    
    frontend_dir = root_dir / 'frontend'
    package_json = frontend_dir / 'package.json'
    
    if not frontend_dir.exists():
        print_error(f"前端目录不存在: {frontend_dir}")
        return False
    
    if not package_json.exists():
        print_error(f"package.json 不存在: {package_json}")
        return False
    
    print_info("安装 Node.js 依赖...")
    code, out, err = run_command(['npm', 'install'], cwd=frontend_dir)
    
    if code != 0:
        print_error(f"安装依赖失败: {err}")
        return False
    
    print_success("前端环境设置完成")
    return True


def start_backend(root_dir: Path, python_cmd: str) -> Optional[subprocess.Popen]:
    """启动后端服务"""
    print_step("启动后端服务")
    
    backend_dir = root_dir / 'backend'
    venv_dir = backend_dir / '.venv'
    sys_info = get_system_info()
    
    venv_python = venv_dir / ('Scripts' if sys_info['is_windows'] else 'bin') / ('python.exe' if sys_info['is_windows'] else 'python')
    venv_uvicorn = venv_dir / ('Scripts' if sys_info['is_windows'] else 'bin') / ('uvicorn.exe' if sys_info['is_windows'] else 'uvicorn')
    
    log_file = root_dir / '.run' / 'backend.log'
    log_file.parent.mkdir(parents=True, exist_ok=True)
    
    print_info("启动 FastAPI 服务...")
    
    with open(log_file, 'w') as log:
        process = subprocess.Popen(
            [str(venv_uvicorn), 'app.main:app', '--reload', '--port', '8000'],
            cwd=backend_dir,
            stdout=log,
            stderr=subprocess.STDOUT
        )
    
    print_success(f"后端服务已启动 (PID: {process.pid})")
    print_info(f"日志文件: {log_file}")
    
    return process


def start_frontend(root_dir: Path) -> Optional[subprocess.Popen]:
    """启动前端服务"""
    print_step("启动前端服务")
    
    frontend_dir = root_dir / 'frontend'
    log_file = root_dir / '.run' / 'frontend.log'
    log_file.parent.mkdir(parents=True, exist_ok=True)
    
    print_info("启动 Vite 开发服务器...")
    
    with open(log_file, 'w') as log:
        process = subprocess.Popen(
            ['npm', 'run', 'dev', '--', '--host', '127.0.0.1', '--port', '5173'],
            cwd=frontend_dir,
            stdout=log,
            stderr=subprocess.STDOUT,
            shell=True if sys.platform == 'win32' else False
        )
    
    print_success(f"前端服务已启动 (PID: {process.pid})")
    print_info(f"日志文件: {log_file}")
    
    return process


def save_pid(root_dir: Path, backend_pid: int, frontend_pid: int):
    """保存进程 ID"""
    pid_dir = root_dir / '.run'
    pid_dir.mkdir(parents=True, exist_ok=True)
    
    (pid_dir / 'backend.pid').write_text(str(backend_pid))
    (pid_dir / 'frontend.pid').write_text(str(frontend_pid))


def main():
    print(f"\n{Colors.BOLD}{Colors.MAGENTA}{'='*60}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.MAGENTA}  Hands-on 实践中心 - 跨平台启动脚本{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.MAGENTA}{'='*60}{Colors.RESET}\n")
    
    sys_info = get_system_info()
    print_info(f"操作系统: {sys_info['system']} {sys_info['machine']}")
    
    root_dir = Path(__file__).parent.parent.resolve()
    print_info(f"项目目录: {root_dir}")
    
    python_cmd = ensure_python()
    if not python_cmd:
        sys.exit(1)
    
    if not ensure_node():
        sys.exit(1)
    
    if not setup_backend(root_dir, python_cmd):
        sys.exit(1)
    
    if not setup_frontend(root_dir):
        sys.exit(1)
    
    backend_process = start_backend(root_dir, python_cmd)
    if not backend_process:
        sys.exit(1)
    
    frontend_process = start_frontend(root_dir)
    if not frontend_process:
        backend_process.terminate()
        sys.exit(1)
    
    save_pid(root_dir, backend_process.pid, frontend_process.pid)
    
    print(f"\n{Colors.GREEN}{Colors.BOLD}{'='*60}{Colors.RESET}")
    print(f"{Colors.GREEN}{Colors.BOLD}  启动成功！{Colors.RESET}")
    print(f"{Colors.GREEN}{Colors.BOLD}{'='*60}{Colors.RESET}\n")
    
    print(f"{Colors.CYAN}前端地址:{Colors.RESET} http://127.0.0.1:5173/")
    print(f"{Colors.CYAN}后端地址:{Colors.RESET} http://127.0.0.1:8000")
    print(f"{Colors.CYAN}健康检查:{Colors.RESET} http://127.0.0.1:8000/api/health")
    
    print(f"\n{Colors.YELLOW}查看日志:{Colors.RESET}")
    print(f"  后端: tail -f {root_dir / '.run' / 'backend.log'}")
    print(f"  前端: tail -f {root_dir / '.run' / 'frontend.log'}")
    
    print(f"\n{Colors.YELLOW}停止服务:{Colors.RESET}")
    print(f"  Python: python scripts/stop.py")
    print(f"  Bash:   bash scripts/stop.sh")
    print(f"  PowerShell: .\\scripts\\stop.ps1")
    
    print(f"\n{Colors.CYAN}按 Ctrl+C 停止所有服务...{Colors.RESET}\n")
    
    try:
        backend_process.wait()
        frontend_process.wait()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}正在停止服务...{Colors.RESET}")
        backend_process.terminate()
        frontend_process.terminate()
        backend_process.wait()
        frontend_process.wait()
        print_success("服务已停止")


if __name__ == '__main__':
    main()
