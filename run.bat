@echo off
setlocal enabledelayedexpansion

set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=start"
if /I not "%ACTION%"=="start" if /I not "%ACTION%"=="install" if /I not "%ACTION%"=="stop" (
    echo 用法: run.bat [start^|install^|stop]
    echo   start   已有环境时一键启动（默认）
    echo   install 自动安装缺失环境后启动
    echo   stop    停止前后端
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

if /I "%ACTION%"=="stop" (
    call :stop_all
    exit /b 0
)

if not exist "%BACKEND_DIR%" (
    echo [ERR] backend 目录不存在: %BACKEND_DIR%
    exit /b 1
)
if not exist "%FRONTEND_DIR%" (
    echo [ERR] frontend 目录不存在: %FRONTEND_DIR%
    exit /b 1
)

call :ensure_python || exit /b 1
call :ensure_node || exit /b 1

if not exist "%RUN_DIR%" mkdir "%RUN_DIR%"

echo [INFO] 安装后端依赖...
cd /d "%BACKEND_DIR%"
if not exist ".venv" (
    python -m venv .venv
    if errorlevel 1 (
        echo [ERR] 创建虚拟环境失败
        exit /b 1
    )
)
".venv\Scripts\python.exe" -m pip install --upgrade pip >nul 2>&1
".venv\Scripts\python.exe" -m pip install -r requirements.txt
if errorlevel 1 (
    echo [ERR] 安装后端依赖失败
    exit /b 1
)

echo [INFO] 安装前端依赖...
cd /d "%FRONTEND_DIR%"
call npm install
if errorlevel 1 (
    echo [ERR] 安装前端依赖失败
    exit /b 1
)

call :stop_all >nul 2>&1

echo [INFO] 启动后端...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Start-Process -FilePath '%BACKEND_DIR%\.venv\Scripts\python.exe' -ArgumentList '-m','uvicorn','app.main:app','--reload','--port','8000' -WorkingDirectory '%BACKEND_DIR%' -RedirectStandardOutput '%BACKEND_LOG%' -RedirectStandardError '%BACKEND_LOG%' -PassThru; $p.Id" > "%BACKEND_PID_FILE%"

echo [INFO] 启动前端...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=Start-Process -FilePath 'npm.cmd' -ArgumentList 'run','dev','--','--host','127.0.0.1','--port','5173' -WorkingDirectory '%FRONTEND_DIR%' -RedirectStandardOutput '%FRONTEND_LOG%' -RedirectStandardError '%FRONTEND_LOG%' -PassThru; $p.Id" > "%FRONTEND_PID_FILE%"

echo.
echo [OK] 启动完成
echo 前端: http://127.0.0.1:5173/
echo 后端: http://127.0.0.1:8000
echo 日志: %BACKEND_LOG%  ^|  %FRONTEND_LOG%
echo 停止: run.bat stop
exit /b 0

:ensure_python
where python >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do echo [OK] Python: %%i
    exit /b 0
)
if /I not "%ACTION%"=="install" (
    echo [ERR] 未检测到 Python，请执行 run.bat install
    exit /b 1
)
where winget >nul 2>&1
if not errorlevel 1 (
    echo [INFO] 使用 winget 安装 Python 3.11...
    winget install Python.Python.3.11 --accept-source-agreements --accept-package-agreements
) else (
    where choco >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] 使用 choco 安装 Python...
        choco install python -y
    ) else (
        echo [ERR] 未找到 winget/choco，无法自动安装 Python
        exit /b 1
    )
)
set "PATH=%PATH%;%LocalAppData%\Programs\Python\Python311;%LocalAppData%\Programs\Python\Python311\Scripts%"
where python >nul 2>&1
if errorlevel 1 (
    echo [ERR] Python 已安装但当前窗口未生效，请重开终端后再执行 run.bat install
    exit /b 1
)
exit /b 0

:ensure_node
where node >nul 2>&1
if not errorlevel 1 (
    for /f %%i in ('node --version') do echo [OK] Node: %%i
    exit /b 0
)
if /I not "%ACTION%"=="install" (
    echo [ERR] 未检测到 Node.js，请执行 run.bat install
    exit /b 1
)
where winget >nul 2>&1
if not errorlevel 1 (
    echo [INFO] 使用 winget 安装 Node.js LTS...
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
) else (
    where choco >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] 使用 choco 安装 Node.js...
        choco install nodejs -y
    ) else (
        echo [ERR] 未找到 winget/choco，无法自动安装 Node.js
        exit /b 1
    )
)
set "PATH=%PATH%;%ProgramFiles%\nodejs;%ProgramFiles(x86)%\nodejs"
where node >nul 2>&1
if errorlevel 1 (
    echo [ERR] Node.js 已安装但当前窗口未生效，请重开终端后再执行 run.bat install
    exit /b 1
)
exit /b 0

:stop_all
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":8000 .*LISTENING"') do taskkill /F /PID %%p >nul 2>&1
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":5173 .*LISTENING"') do taskkill /F /PID %%p >nul 2>&1
if exist "%BACKEND_PID_FILE%" del /q "%BACKEND_PID_FILE%" >nul 2>&1
if exist "%FRONTEND_PID_FILE%" del /q "%FRONTEND_PID_FILE%" >nul 2>&1
echo [OK] 已停止前后端
exit /b 0
