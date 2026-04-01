# Windows PowerShell 启动脚本
# 支持 Windows 10/11

$ErrorActionPreference = "Stop"

$ROOT_DIR = Split-Path -Parent $PSScriptRoot
$RUN_DIR = Join-Path $ROOT_DIR ".run"
$BACKEND_PID_FILE = Join-Path $RUN_DIR "backend.pid"
$FRONTEND_PID_FILE = Join-Path $RUN_DIR "frontend.pid"
$BACKEND_LOG_FILE = Join-Path $RUN_DIR "backend.log"
$FRONTEND_LOG_FILE = Join-Path $RUN_DIR "frontend.log"

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Test-Python {
    $pythonCommands = @("python", "python3")
    
    foreach ($cmd in $pythonCommands) {
        try {
            $version = & $cmd --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Info "找到 $cmd`: $version"
                $versionParts = $version.ToString().Split()[1].Split(".")
                $major = [int]$versionParts[0]
                $minor = [int]$versionParts[1]
                
                if ($major -ge 3 -and $minor -ge 8) {
                    Write-Success "Python 版本满足要求 (>= 3.8)"
                    return $cmd
                }
                else {
                    Write-Warning "Python 版本过低: $major.$minor < 3.8"
                }
            }
        }
        catch {
            continue
        }
    }
    
    return $null
}

function Install-Python {
    Write-Info "检查 Python 安装方式..."
    
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Info "使用 winget 安装 Python..."
        $response = Read-Host "是否使用 winget 安装 Python 3.11? (y/n)"
        if ($response -eq "y") {
            winget install Python.Python.3.11
            Write-Success "Python 安装成功，请重新打开 PowerShell"
            exit 0
        }
    }
    
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Info "使用 Chocolatey 安装 Python..."
        $response = Read-Host "是否使用 Chocolatey 安装 Python? (y/n)"
        if ($response -eq "y") {
            choco install python -y
            Write-Success "Python 安装成功，请重新打开 PowerShell"
            exit 0
        }
    }
    
    Write-Warning "未找到包管理器，请手动下载安装 Python:"
    Write-Host "  https://www.python.org/downloads/" -ForegroundColor Cyan
    Write-Host "安装时请勾选 'Add Python to PATH'" -ForegroundColor Yellow
    exit 1
}

function Test-Node {
    try {
        $version = node --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Info "找到 Node.js: $version"
            $versionParts = $version.ToString().TrimStart("v").Split(".")
            $major = [int]$versionParts[0]
            $minor = [int]$versionParts[1]
            
            if ($major -ge 16) {
                Write-Success "Node.js 版本满足要求 (>= 16)"
                return $true
            }
            else {
                Write-Warning "Node.js 版本过低: $major.$minor < 16"
                return $false
            }
        }
    }
    catch {
        return $false
    }
    
    return $false
}

function Install-Node {
    Write-Info "检查 Node.js 安装方式..."
    
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Info "使用 winget 安装 Node.js..."
        $response = Read-Host "是否使用 winget 安装 Node.js LTS? (y/n)"
        if ($response -eq "y") {
            winget install OpenJS.NodeJS.LTS
            Write-Success "Node.js 安装成功，请重新打开 PowerShell"
            exit 0
        }
    }
    
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Info "使用 Chocolatey 安装 Node.js..."
        $response = Read-Host "是否使用 Chocolatey 安装 Node.js? (y/n)"
        if ($response -eq "y") {
            choco install nodejs -y
            Write-Success "Node.js 安装成功，请重新打开 PowerShell"
            exit 0
        }
    }
    
    Write-Warning "未找到包管理器，请手动下载安装 Node.js:"
    Write-Host "  https://nodejs.org/" -ForegroundColor Cyan
    exit 1
}

function Setup-Backend {
    param([string]$PythonCmd)
    
    $backendDir = Join-Path $ROOT_DIR "backend"
    $venvDir = Join-Path $backendDir ".venv"
    $requirementsFile = Join-Path $backendDir "requirements.txt"
    
    if (-not (Test-Path $backendDir)) {
        Write-Error "后端目录不存在: $backendDir"
        exit 1
    }
    
    if (-not (Test-Path $requirementsFile)) {
        Write-Error "requirements.txt 不存在: $requirementsFile"
        exit 1
    }
    
    if (-not (Test-Path $venvDir)) {
        Write-Info "创建 Python 虚拟环境..."
        & $PythonCmd -m venv $venvDir
        if ($LASTEXITCODE -ne 0) {
            Write-Error "创建虚拟环境失败"
            exit 1
        }
        Write-Success "虚拟环境创建成功"
    }
    
    $venvPython = Join-Path $venvDir "Scripts\python.exe"
    $venvPip = Join-Path $venvDir "Scripts\pip.exe"
    
    Write-Info "安装 Python 依赖..."
    & $venvPython -m pip install --upgrade pip | Out-Null
    & $venvPython -m pip install -r $requirementsFile
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "安装依赖失败"
        exit 1
    }
    
    Write-Success "后端环境设置完成"
}

function Setup-Frontend {
    $frontendDir = Join-Path $ROOT_DIR "frontend"
    $packageJson = Join-Path $frontendDir "package.json"
    
    if (-not (Test-Path $frontendDir)) {
        Write-Error "前端目录不存在: $frontendDir"
        exit 1
    }
    
    if (-not (Test-Path $packageJson)) {
        Write-Error "package.json 不存在: $packageJson"
        exit 1
    }
    
    Write-Info "安装 Node.js 依赖..."
    Push-Location $frontendDir
    npm install
    Pop-Location
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "安装依赖失败"
        exit 1
    }
    
    Write-Success "前端环境设置完成"
}

function Start-Backend {
    param([string]$PythonCmd)
    
    $backendDir = Join-Path $ROOT_DIR "backend"
    $venvDir = Join-Path $backendDir ".venv"
    $venvUvicorn = Join-Path $venvDir "Scripts\uvicorn.exe"
    
    New-Item -ItemType Directory -Force -Path $RUN_DIR | Out-Null
    
    Write-Info "启动 FastAPI 服务..."
    
    $process = Start-Process -FilePath $venvUvicorn `
        -ArgumentList "app.main:app", "--reload", "--port", "8000" `
        -WorkingDirectory $backendDir `
        -RedirectStandardOutput $BACKEND_LOG_FILE `
        -RedirectStandardError $BACKEND_LOG_FILE `
        -PassThru
    
    $process.Id | Out-File -FilePath $BACKEND_PID_FILE
    Write-Success "后端服务已启动 (PID: $($process.Id))"
    Write-Info "日志文件: $BACKEND_LOG_FILE"
}

function Start-Frontend {
    $frontendDir = Join-Path $ROOT_DIR "frontend"
    
    New-Item -ItemType Directory -Force -Path $RUN_DIR | Out-Null
    
    Write-Info "启动 Vite 开发服务器..."
    
    $process = Start-Process -FilePath "npm" `
        -ArgumentList "run", "dev", "--", "--host", "127.0.0.1", "--port", "5173" `
        -WorkingDirectory $frontendDir `
        -RedirectStandardOutput $FRONTEND_LOG_FILE `
        -RedirectStandardError $FRONTEND_LOG_FILE `
        -PassThru
    
    $process.Id | Out-File -FilePath $FRONTEND_PID_FILE
    Write-Success "前端服务已启动 (PID: $($process.Id))"
    Write-Info "日志文件: $FRONTEND_LOG_FILE"
}

# 主程序
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Hands-on 实践中心 - Windows 启动脚本" -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""

Write-Info "操作系统: Windows"
Write-Info "项目目录: $ROOT_DIR"

# 检查 Python
$pythonCmd = Test-Python
if (-not $pythonCmd) {
    Write-Warning "未找到合适的 Python 环境"
    Install-Python
}

# 检查 Node.js
if (-not (Test-Node)) {
    Write-Warning "未找到合适的 Node.js 环境"
    Install-Node
}

# 设置环境
Setup-Backend -PythonCmd $pythonCmd
Setup-Frontend

# 启动服务
Start-Backend -PythonCmd $pythonCmd
Start-Frontend

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  启动成功！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

Write-Host "前端地址: " -NoNewline -ForegroundColor Cyan
Write-Host "http://127.0.0.1:5173/"
Write-Host "后端地址: " -NoNewline -ForegroundColor Cyan
Write-Host "http://127.0.0.1:8000"
Write-Host "健康检查: " -NoNewline -ForegroundColor Cyan
Write-Host "http://127.0.0.1:8000/api/health"

Write-Host ""
Write-Host "查看日志:" -ForegroundColor Yellow
Write-Host "  后端: Get-Content $BACKEND_LOG_FILE -Tail 20 -Wait"
Write-Host "  前端: Get-Content $FRONTEND_LOG_FILE -Tail 20 -Wait"

Write-Host ""
Write-Host "停止服务:" -ForegroundColor Yellow
Write-Host "  .\scripts\stop.ps1"

Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
