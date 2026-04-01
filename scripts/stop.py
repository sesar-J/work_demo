#!/usr/bin/env python3
"""
跨平台停止脚本 - 支持 macOS、Linux、Windows
"""

import os
import sys
import subprocess
import signal
from pathlib import Path


class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
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


def stop_process_by_pid(pid_file: Path, name: str) -> bool:
    """通过 PID 文件停止进程"""
    if not pid_file.exists():
        print_info(f"{name} 未运行")
        return True
    
    try:
        pid = int(pid_file.read_text().strip())
    except ValueError:
        print_warning(f"{name} PID 文件格式错误")
        pid_file.unlink()
        return True
    
    try:
        if sys.platform == 'win32':
            subprocess.run(['taskkill', '/F', '/PID', str(pid)], capture_output=True)
        else:
            os.kill(pid, signal.SIGTERM)
        print_success(f"{name} 已停止 (PID: {pid})")
    except ProcessLookupError:
        print_warning(f"{name} 进程不存在 (PID: {pid})")
    except Exception as e:
        print_error(f"停止 {name} 失败: {e}")
        return False
    finally:
        pid_file.unlink()
    
    return True


def main():
    print(f"\n{Colors.BOLD}{Colors.YELLOW}停止所有服务...{Colors.RESET}\n")
    
    root_dir = Path(__file__).parent.parent.resolve()
    run_dir = root_dir / '.run'
    
    backend_pid = run_dir / 'backend.pid'
    frontend_pid = run_dir / 'frontend.pid'
    
    stop_process_by_pid(backend_pid, "后端服务")
    stop_process_by_pid(frontend_pid, "前端服务")
    
    print_success("所有服务已停止")


if __name__ == '__main__':
    main()
