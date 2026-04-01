@echo off
setlocal enabledelayedexpansion

echo.
echo ============================================================
echo   Hands-on 实践中心 - Windows 一键启动脚本
echo ============================================================
echo.

set "ROOT_DIR=%~dp0.."
set "RUN_DIR=%ROOT_DIR%\.run"
set "BACKEND_DIR=%ROOT_DIR%\backend"
set "FRONTEND_DIR=%ROOT_DIR%\frontend"

cd /d "%ROOT_DIR%"

REM 检查 Python
echo [1/6] 检查 Python 环境...
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] 未找到 Python，开始自动安装...
    
    REM 检查 winget
    where winget >nul 2>&1
    if %errorlevel% equ 0 (
        echo [*] 使用 winget 安装 Python 3.11...
        winget install Python.Python.3.11 --accept-source-agreements --accept-package-agreements
        
        echo.
        echo [!] Python 已安装，但需要刷新环境变量
        echo [*] 请关闭当前窗口，重新打开 PowerShell 后再次运行此脚本
        echo.
        pause
        exit /b 0
    )
    
    REM 检查 chocolatey
    where choco >nul 2>&1
    if %errorlevel% equ 0 (
        echo [*] 使用 Chocolatey 安装 Python...
        choco install python -y
        
        echo.
        echo [!] Python 已安装，但需要刷新环境变量
        echo [*] 请关闭当前窗口，重新打开 PowerShell 后再次运行此脚本
        echo.
        pause
        exit /b 0
    )
    
    echo [✗] 未找到包管理器，请手动安装 Python:
    echo     https://www.python.org/downloads/
    echo     安装时请勾选 "Add Python to PATH"
    echo.
    pause
    exit /b 1
)

for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo [✓] 找到 Python: %PYTHON_VERSION%

REM 检查 Node.js
echo.
echo [2/6] 检查 Node.js 环境...
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] 未找到 Node.js，开始自动安装...
    
    REM 检查 winget
    where winget >nul 2>&1
    if %errorlevel% equ 0 (
        echo [*] 使用 winget 安装 Node.js LTS...
        winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
        
        echo.
        echo [!] Node.js 已安装，但需要刷新环境变量
        echo [*] 请关闭当前窗口，重新打开 PowerShell 后再次运行此脚本
        echo.
        pause
        exit /b 0
    )
    
    REM 检查 chocolatey
    where choco >nul 2>&1
    if %errorlevel% equ 0 (
        echo [*] 使用 Chocolatey 安装 Node.js...
        choco install nodejs -y
        
        echo.
        echo [!] Node.js 已安装，但需要刷新环境变量
        echo [*] 请关闭当前窗口，重新打开 PowerShell 后再次运行此脚本
        echo.
        pause
        exit /b 0
    )
    
    echo [✗] 未找到包管理器，请手动安装 Node.js:
    echo     https://nodejs.org/
    echo.
    pause
    exit /b 1
)

for /f %%i in ('node --version') do set NODE_VERSION=%%i
echo [✓] 找到 Node.js: %NODE_VERSION%

REM 创建运行目录
if not exist "%RUN_DIR%" mkdir "%RUN_DIR%"

REM 设置后端环境
echo.
echo [3/6] 设置后端环境...
cd /d "%BACKEND_DIR%"

if not exist ".venv" (
    echo [*] 创建 Python 虚拟环境...
    python -m venv .venv
    if %errorlevel% neq 0 (
        echo [✗] 创建虚拟环境失败
        pause
        exit /b 1
    )
    echo [✓] 虚拟环境创建成功
)

echo [*] 安装 Python 依赖...
call .venv\Scripts\activate.bat
python -m pip install --upgrade pip >nul 2>&1
python -m pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo [✗] 安装依赖失败
    pause
    exit /b 1
)
echo [✓] 后端环境设置完成

REM 设置前端环境
echo.
echo [4/6] 设置前端环境...
cd /d "%FRONTEND_DIR%"

echo [*] 安装 Node.js 依赖...
call npm install
if %errorlevel% neq 0 (
    echo [✗] 安装依赖失败
    pause
    exit /b 1
)
echo [✓] 前端环境设置完成

REM 启动后端服务
echo.
echo [5/6] 启动后端服务...
cd /d "%BACKEND_DIR%"
start "Backend" cmd /c ".venv\Scripts\uvicorn.exe app.main:app --reload --port 8000 > %RUN_DIR%\backend.log 2>&1"
timeout /t 2 /nobreak >nul
echo [✓] 后端服务已启动 (端口: 8000)

REM 启动前端服务
echo.
echo [6/6] 启动前端服务...
cd /d "%FRONTEND_DIR%"
start "Frontend" cmd /c "npm run dev -- --host 127.0.0.1 --port 5173 > %RUN_DIR%\frontend.log 2>&1"
timeout /t 2 /nobreak >nul
echo [✓] 前端服务已启动 (端口: 5173)

REM 显示成功信息
echo.
echo ============================================================
echo   启动成功！
echo ============================================================
echo.
echo 前端地址: http://127.0.0.1:5173/
echo 后端地址: http://127.0.0.1:8000
echo 健康检查: http://127.0.0.1:8000/api/health
echo.
echo 查看日志:
echo   后端: notepad %RUN_DIR%\backend.log
echo   前端: notepad %RUN_DIR%\frontend.log
echo.
echo 停止服务:
echo   关闭 "Backend" 和 "Frontend" 窗口
echo   或运行: scripts\stop.bat
echo.
echo 按任意键退出此窗口（服务将继续运行）...
pause >nul
