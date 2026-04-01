# Windows PowerShell 停止脚本

$ErrorActionPreference = "Stop"

$ROOT_DIR = Split-Path -Parent $PSScriptRoot
$RUN_DIR = Join-Path $ROOT_DIR ".run"
$BACKEND_PID_FILE = Join-Path $RUN_DIR "backend.pid"
$FRONTEND_PID_FILE = Join-Path $RUN_DIR "frontend.pid"

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Stop-ProcessByPid {
    param(
        [string]$PidFile,
        [string]$Name
    )
    
    if (-not (Test-Path $PidFile)) {
        Write-Warning "$Name 未运行"
        return
    }
    
    $pid = Get-Content $PidFile
    
    try {
        Stop-Process -Id $pid -Force
        Write-Success "$Name 已停止 (PID: $pid)"
    }
    catch {
        Write-Warning "$Name 进程不存在 (PID: $pid)"
    }
    finally {
        Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ""
Write-Host "停止所有服务..." -ForegroundColor Yellow
Write-Host ""

Stop-ProcessByPid -PidFile $BACKEND_PID_FILE -Name "后端服务"
Stop-ProcessByPid -PidFile $FRONTEND_PID_FILE -Name "前端服务"

Write-Success "所有服务已停止"
