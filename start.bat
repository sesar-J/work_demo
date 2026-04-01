@echo off
echo.
echo ============================================================
echo   Hands-on 实践中心 - Windows 启动脚本
echo ============================================================
echo.
echo 正在启动，请稍候...
echo.

REM 调用 PowerShell 脚本
powershell.exe -ExecutionPolicy Bypass -File "%~dp0dev.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [!] 如果遇到问题，请手动运行：
    echo     powershell -ExecutionPolicy Bypass -File scripts\dev.ps1
    echo.
    pause
)
