@echo off
setlocal enabledelayedexpansion

set "MODE=%~1"
if "%MODE%"=="" set "MODE=ready"
if /I not "%MODE%"=="ready" if /I not "%MODE%"=="install" (
    echo 用法: start.bat [ready^|install]
    echo   ready   已有 Python/Node 环境时启动（默认）
    echo   install 自动安装缺失环境后再启动
    exit /b 1
)

set "ROOT_DIR=%~dp0"
set "BACKEND_DIR=%ROOT_DIR%backend"
set "FRONTEND_DIR=%ROOT_DIR%frontend"
set "RUN_DIR=%ROOT_DIR%.run"
set "BACKEND_LOG=%RUN_DIR%\backend.log"
set "FRONTEND_LOG=%RUN_DIR%\frontend.log"
set "BACKEND_PID_FILE=%RUN_DIR%\backend.pid"
set "FRONTEND_PID_FILE=%RUN_DIR%\frontend.pid"

echo ============================================================
echo Hands-on 启动脚本 (Windows^) - 模式: %MODE%
echo ============================================================

if not exist "%BACKEND_DIR%" (
    echo [ERR] backend 目录不存在: %BACKEND_DIR%
    exit /b 1
)
if not exist "%FRONTEND_DIR%" (
    echo [ERR] frontend 目录不存在: %FRONTEND_DIR%
    exit /b 1
)

where python >nul 2>&1
if %errorlevel% neq 0 (
    if /I "%MODE%"=="install" (
        call :install_python
    ) else (
        echo [ERR] 未检测到 Python。请执行: start.bat install
        exit /b 1
    )
)
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PY_VER=%%i
echo [OK] 检测到 Python: %PY_VER%

where node >nul 2>&1
if %errorlevel% neq 0 (
    if /I "%MODE%"=="install" (
        call :install_node
    ) else (
        echo [ERR] 未检测到 Node.js。请执行: start.bat install
        exit /b 1
    )
)
for /f %%i in ('node --version') do set NODE_VER=%%i
echo [OK] 检测到 Node.js: %NODE_VER%

if not exist "%RUN_DIR%" mkdir "%RUN_DIR%"

echo [INFO] 准备后端环境...
cd /d "%BACKEND_DIR%"
if not exist ".venv" (
    python -m venv .venv
    if %errorlevel% neq 0 (
        echo [ERR] 创建后端虚拟环境失败
        exit /b 1
    )
)
call ".venv\Scripts\python.exe" -m pip install --upgrade pip >nul 2>&1
call ".venv\Scripts\python.exe" -m pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo [ERR] 安装后端依赖失败
    exit /b 1
)
echo [OK] 后端依赖安装完成

echo [INFO] 准备前端环境...
cd /d "%FRONTEND_DIR%"
call npm install
if %errorlevel% neq 0 (
    echo [ERR] 安装前端依赖失败
    exit /b 1
)
echo [OK] 前端依赖安装完成

echo [INFO] 启动后端服务...
cd /d "%BACKEND_DIR%"
start "Backend" cmd /c ".venv\Scripts\uvicorn.exe app.main:app --reload --port 8000 > ""%BACKEND_LOG%"" 2>&1"
timeout /t 2 /nobreak >nul
for /f "tokens=2" %%i in ('tasklist /FI "WINDOWTITLE eq Backend" /FO LIST ^| findstr "PID:"') do set BACKEND_PID=%%i
if not "%BACKEND_PID%"=="" echo %BACKEND_PID%>"%BACKEND_PID_FILE%"

echo [INFO] 启动前端服务...
cd /d "%FRONTEND_DIR%"
start "Frontend" cmd /c "npm run dev -- --host 127.0.0.1 --port 5173 > ""%FRONTEND_LOG%"" 2>&1"
timeout /t 2 /nobreak >nul
for /f "tokens=2" %%i in ('tasklist /FI "WINDOWTITLE eq Frontend" /FO LIST ^| findstr "PID:"') do set FRONTEND_PID=%%i
if not "%FRONTEND_PID%"=="" echo %FRONTEND_PID%>"%FRONTEND_PID_FILE%"

echo.
echo [OK] 启动完成
echo 前端: http://127.0.0.1:5173/
echo 后端: http://127.0.0.1:8000
echo 后端健康检查: http://127.0.0.1:8000/api/health
echo.
echo 日志:
echo   %BACKEND_LOG%
echo   %FRONTEND_LOG%
echo.
echo 停止服务: scripts\stop.bat
echo.
exit /b 0

:install_python
where winget >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] 使用 winget 安装 Python 3.11...
    winget install Python.Python.3.11 --accept-source-agreements --accept-package-agreements
) else (
    where choco >nul 2>&1
    if %errorlevel% equ 0 (
        echo [INFO] 使用 Chocolatey 安装 Python...
        choco install python -y
    ) else (
        echo [ERR] 自动安装 Python 失败：未找到 winget/choco
        echo       请手动安装后重试: https://www.python.org/downloads/
        exit /b 1
    )
)
set "PATH=%PATH%;%LocalAppData%\Programs\Python\Python311;%LocalAppData%\Programs\Python\Python311\Scripts%"
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERR] Python 已安装但当前窗口未生效，请重新打开终端后执行 start.bat install
    exit /b 1
)
exit /b 0

:install_node
where winget >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] 使用 winget 安装 Node.js LTS...
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
) else (
    where choco >nul 2>&1
    if %errorlevel% equ 0 (
        echo [INFO] 使用 Chocolatey 安装 Node.js...
        choco install nodejs -y
    ) else (
        echo [ERR] 自动安装 Node.js 失败：未找到 winget/choco
        echo       请手动安装后重试: https://nodejs.org/
        exit /b 1
    )
)
set "PATH=%PATH%;%ProgramFiles%\nodejs;%ProgramFiles(x86)%\nodejs"
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERR] Node.js 已安装但当前窗口未生效，请重新打开终端后执行 start.bat install
    exit /b 1
)
exit /b 0
