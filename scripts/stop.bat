@echo off
chcp 65001 >nul
echo.
echo 停止所有服务...
echo.

REM 关闭后端服务
tasklist /FI "WINDOWTITLE eq Backend*" 2>nul | find /I "cmd.exe" >nul
if %errorlevel% equ 0 (
    taskkill /FI "WINDOWTITLE eq Backend*" /F >nul 2>&1
    echo [✓] 后端服务已停止
) else (
    echo [!] 后端服务未运行
)

REM 关闭前端服务
tasklist /FI "WINDOWTITLE eq Frontend*" 2>nul | find /I "cmd.exe" >nul
if %errorlevel% equ 0 (
    taskkill /FI "WINDOWTITLE eq Frontend*" /F >nul 2>&1
    echo [✓] 前端服务已停止
) else (
    echo [!] 前端服务未运行
)

echo.
echo [✓] 所有服务已停止
echo.
pause
