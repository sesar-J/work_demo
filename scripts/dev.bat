@echo off
chcp 65001 >nul
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

REM 刷新环境变量函数
:refresh_env
echo [*] 刷新环境变量...

REM 从注册表重新读取用户 PATH
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USER_PATH=%%b"

REM 从注册表重新读取系统 PATH
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYSTEM_PATH=%%b"

REM 合并 PATH
set "PATH=%USER_PATH%;%SYSTEM_PATH%"

echo [✓] 环境变量已刷新
goto :eof

REM 检查 Python
:check_python
python --version >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
    echo [✓] 找到 Python: !PYTHON_VERSION!
    set "PYTHON_FOUND=1"
) else (
    set "PYTHON_FOUND=0"
)
goto :eof

REM 检查 Node.js
:check_node
node --version >nul 2>&1
if %errorlevel% equ 0 (
    for /f %%i in ('node --version') do set NODE_VERSION=%%i
    echo [✓] 找到 Node.js: !NODE_VERSION!
    set "NODE_FOUND=1"
) else (
    set "NODE_FOUND=0"
)
goto :eof

REM 安装 Python
:install_python
echo [!] 未找到 Python，开始自动安装...

REM 检查 winget
winget --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [*] 使用 winget 安装 Python 3.11...
    winget install Python.Python.3.11 --accept-source-agreements --accept-package-agreements --silent
    
    REM 等待安装完成
    timeout /t 5 /nobreak >nul
    
    REM 刷新环境变量
    call :refresh_env
    
    REM 再次检查
    call :check_python
    if "!PYTHON_FOUND!"=="1" (
        echo [✓] Python 安装成功
        goto :eof
    )
)

REM 检查 chocolatey
choco --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [*] 使用 Chocolatey 安装 Python...
    choco install python -y
    
    REM 刷新环境变量
    call :refresh_env
    
    REM 再次检查
    call :check_python
    if "!PYTHON_FOUND!"=="1" (
        echo [✓] Python 安装成功
        goto :eof
    )
)

echo [✗] 自动安装失败，请手动安装 Python:
echo     https://www.python.org/downloads/
echo     安装时请勾选 "Add Python to PATH"
echo     安装完成后，重新运行此脚本
echo.
pause
exit /b 1

REM 安装 Node.js
:install_node
echo [!] 未找到 Node.js，开始自动安装...

REM 检查 winget
winget --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [*] 使用 winget 安装 Node.js LTS...
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements --silent
    
    REM 等待安装完成
    timeout /t 5 /nobreak >nul
    
    REM 刷新环境变量
    call :refresh_env
    
    REM 再次检查
    call :check_node
    if "!NODE_FOUND!"=="1" (
        echo [✓] Node.js 安装成功
        goto :eof
    )
)

REM 检查 chocolatey
choco --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [*] 使用 Chocolatey 安装 Node.js...
    choco install nodejs -y
    
    REM 刷新环境变量
    call :refresh_env
    
    REM 再次检查
    call :check_node
    if "!NODE_FOUND!"=="1" (
        echo [✓] Node.js 安装成功
        goto :eof
    )
)

echo [✗] 自动安装失败，请手动安装 Node.js:
echo     https://nodejs.org/
echo     安装完成后，重新运行此脚本
echo.
pause
exit /b 1

REM 主流程
echo [1/6] 检查 Python 环境...
call :check_python
if "%PYTHON_FOUND%"=="0" (
    call :install_python
    if %errorlevel% neq 0 exit /b 1
)

echo.
echo [2/6] 检查 Node.js 环境...
call :check_node
if "%NODE_FOUND%"=="0" (
    call :install_node
    if %errorlevel% neq 0 exit /b 1
)

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
