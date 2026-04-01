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
set "BACKEND_ERR=%RUN_DIR%\backend.err.log"
set "FRONTEND_LOG=%RUN_DIR%\frontend.log"
set "FRONTEND_ERR=%RUN_DIR%\frontend.err.log"
set "BACKEND_PORT_FILE=%RUN_DIR%\backend.port"
set "FRONTEND_PORT_FILE=%RUN_DIR%\frontend.port"
if "%BACKEND_PORT%"=="" set "BACKEND_PORT=8000"
if "%FRONTEND_PORT%"=="" set "FRONTEND_PORT=5173"

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

call :release_port %BACKEND_PORT% backend >nul 2>&1
if errorlevel 1 (
    call :find_available_port %BACKEND_PORT% BACKEND_PORT
    if errorlevel 1 (
        echo [ERR] 未找到可用后端端口（从 %BACKEND_PORT% 开始扫描）
        exit /b 1
    )
    echo [WARN] 后端默认端口被占用，改用端口 %BACKEND_PORT%
)
call :release_port %FRONTEND_PORT% frontend >nul 2>&1
if errorlevel 1 (
    call :find_available_port %FRONTEND_PORT% FRONTEND_PORT
    if errorlevel 1 (
        echo [ERR] 未找到可用前端端口（从 %FRONTEND_PORT% 开始扫描）
        exit /b 1
    )
    echo [WARN] 前端默认端口被占用，改用端口 %FRONTEND_PORT%
)

> "%BACKEND_PORT_FILE%" echo %BACKEND_PORT%
> "%FRONTEND_PORT_FILE%" echo %FRONTEND_PORT%

echo [INFO] 启动后端...
start "backend-%BACKEND_PORT%" /min cmd /c "cd /d \"%BACKEND_DIR%\" && .venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port %BACKEND_PORT% 1> \"%BACKEND_LOG%\" 2> \"%BACKEND_ERR%\""

echo [INFO] 启动前端...
start "frontend-%FRONTEND_PORT%" /min cmd /c "cd /d \"%FRONTEND_DIR%\" && set VITE_API_BASE_URL=http://127.0.0.1:%BACKEND_PORT%/api && npx vite --host 127.0.0.1 --port %FRONTEND_PORT% 1> \"%FRONTEND_LOG%\" 2> \"%FRONTEND_ERR%\""

timeout /t 2 /nobreak >nul
call :check_port %FRONTEND_PORT%
if errorlevel 1 (
    echo [ERR] 前端未能成功监听 %FRONTEND_PORT%，请查看 %FRONTEND_ERR%
    exit /b 1
)
call :check_port %BACKEND_PORT%
if errorlevel 1 (
    echo [ERR] 后端未能成功监听 %BACKEND_PORT%，请查看 %BACKEND_ERR%
    exit /b 1
)

echo.
echo [OK] 启动完成
echo 前端: http://127.0.0.1:%FRONTEND_PORT%/
echo 后端: http://127.0.0.1:%BACKEND_PORT%
echo 日志: %BACKEND_LOG%  ^|  %FRONTEND_LOG%
echo 错误日志: %BACKEND_ERR%  ^|  %FRONTEND_ERR%
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
if exist "%BACKEND_PORT_FILE%" (
    for /f "usebackq delims=" %%p in ("%BACKEND_PORT_FILE%") do set "BACKEND_PORT=%%p"
)
if exist "%FRONTEND_PORT_FILE%" (
    for /f "usebackq delims=" %%p in ("%FRONTEND_PORT_FILE%") do set "FRONTEND_PORT=%%p"
)
call :release_port %BACKEND_PORT% backend >nul 2>&1
call :release_port %FRONTEND_PORT% frontend >nul 2>&1
if exist "%BACKEND_PORT_FILE%" del /q "%BACKEND_PORT_FILE%" >nul 2>&1
if exist "%FRONTEND_PORT_FILE%" del /q "%FRONTEND_PORT_FILE%" >nul 2>&1
echo [OK] 已停止前后端
exit /b 0

:check_port
for /f "tokens=1,2,3,4,5" %%a in ('netstat -ano -p tcp ^| findstr /I "LISTENING" ^| findstr /R /C:":%1 " ') do (
    echo [OK] 端口 %1 已监听（PID: %%e）
    exit /b 0
)
exit /b 1

:release_port
set "TARGET_PORT=%~1"
set "TARGET_NAME=%~2"
set "FOUND="
for /L %%n in (1,1,10) do (
    set "FOUND="
    for /f "tokens=1,2,3,4,5" %%a in ('netstat -ano -p tcp ^| findstr /R /C:":!TARGET_PORT! " ') do (
        echo %%b| findstr /R /C:".*:!TARGET_PORT!$" >nul
        if not errorlevel 1 (
            set "FOUND=1"
            taskkill /F /PID %%e >nul 2>&1
        )
    )
    if not defined FOUND (
        echo [OK] %TARGET_NAME% 端口 !TARGET_PORT! 已释放
        exit /b 0
    )
    timeout /t 1 /nobreak >nul
)
echo [ERR] %TARGET_NAME% 端口 !TARGET_PORT! 仍被占用，请手动检查
exit /b 1

:find_available_port
setlocal enabledelayedexpansion
set /a "PORT_BASE=%~1"
for /L %%n in (0,1,200) do (
    set /a "CANDIDATE=PORT_BASE+%%n"
    call :check_port !CANDIDATE! >nul 2>&1
    if errorlevel 1 (
        endlocal & set "%~2=!CANDIDATE!" & exit /b 0
    )
)
endlocal
exit /b 1
