# Windows PowerShell 一键启动脚本 - 支持自动刷新环境变量

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[$Message]" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[✓] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[✗] $Message" -ForegroundColor Red
}

function Update-PathEnvironment {
    <#
    .SYNOPSIS
    刷新当前 PowerShell 会话的 PATH 环境变量
    #>
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $systemPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $env:Path = "$userPath;$systemPath"
}

function Test-Python {
    try {
        $version = & python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "找到 Python: $version"
            return $true
        }
    }
    catch {
        return $false
    }
    return $false
}

function Test-Node {
    try {
        $version = & node --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "找到 Node.js: $version"
            return $true
        }
    }
    catch {
        return $false
    }
    return $false
}

function Install-Python {
    Write-Warning "未找到 Python，开始自动安装..."
    
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Step "使用 winget 安装 Python 3.11..."
        winget install Python.Python.3.11 --accept-source-agreements --accept-package-agreements
        
        Write-Step "刷新环境变量..."
        Update-PathEnvironment
        
        if (Test-Python) {
            Write-Success "Python 安装成功"
            return $true
        }
    }
    
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Step "使用 Chocolatey 安装 Python..."
        choco install python -y
        
        Write-Step "刷新环境变量..."
        Update-PathEnvironment
        
        if (Test-Python) {
            Write-Success "Python 安装成功"
            return $true
        }
    }
    
    Write-Error "自动安装失败，请手动安装 Python:"
    Write-Host "  https://www.python.org/downloads/" -ForegroundColor Cyan
    Write-Host "  安装时请勾选 'Add Python to PATH'" -ForegroundColor Yellow
    return $false
}

function Install-Node {
    Write-Warning "未找到 Node.js，开始自动安装..."
    
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Step "使用 winget 安装 Node.js LTS..."
        winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
        
        Write-Step "刷新环境变量..."
        Update-PathEnvironment
        
        if (Test-Node) {
            Write-Success "Node.js 安装成功"
            return $true
        }
    }
    
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Step "使用 Chocolatey 安装 Node.js..."
        choco install nodejs -y
        
        Write-Step "刷新环境变量..."
        Update-PathEnvironment
        
        if (Test-Node) {
            Write-Success "Node.js 安装成功"
            return $true
        }
    }
    
    Write-Error "自动安装失败，请手动安装 Node.js:"
    Write-Host "  https://nodejs.org/" -ForegroundColor Cyan
    return $false
}

# 主程序
Write-Host ""
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host "  Hands-on 实践中心 - Windows 一键启动脚本" -ForegroundColor Magenta
Write-Host "============================================================" -ForegroundColor Magenta
Write-Host ""

$ROOT_DIR = Split-Path -Parent $PSScriptRoot
$RUN_DIR = Join-Path $ROOT_DIR ".run"
$BACKEND_DIR = Join-Path $ROOT_DIR "backend"
$FRONTEND_DIR = Join-Path $ROOT_DIR "frontend"

Write-Host "项目目录: $ROOT_DIR" -ForegroundColor Gray

# 检查 Python
Write-Host ""
Write-Step "1/6 检查 Python 环境..."
if (-not (Test-Python)) {
    if (-not (Install-Python)) {
        Read-Host "按回车键退出"
        exit 1
    }
}

# 检查 Node.js
Write-Host ""
Write-Step "2/6 检查 Node.js 环境..."
if (-not (Test-Node)) {
    if (-not (Install-Node)) {
        Read-Host "按回车键退出"
        exit 1
    }
}

# 创建运行目录
New-Item -ItemType Directory -Force -Path $RUN_DIR | Out-Null

# 设置后端环境
Write-Host ""
Write-Step "3/6 设置后端环境..."

$venvDir = Join-Path $BACKEND_DIR ".venv"
if (-not (Test-Path $venvDir)) {
    Write-Host "创建 Python 虚拟环境..." -ForegroundColor Gray
    & python -m venv $venvDir
    if ($LASTEXITCODE -ne 0) {
        Write-Error "创建虚拟环境失败"
        Read-Host "按回车键退出"
        exit 1
    }
    Write-Success "虚拟环境创建成功"
}

$venvPython = Join-Path $venvDir "Scripts\python.exe"
$requirementsFile = Join-Path $BACKEND_DIR "requirements.txt"

Write-Host "安装 Python 依赖..." -ForegroundColor Gray
& $venvPython -m pip install --upgrade pip | Out-Null
& $venvPython -m pip install -r $requirementsFile
if ($LASTEXITCODE -ne 0) {
    Write-Error "安装依赖失败"
    Read-Host "按回车键退出"
    exit 1
}
Write-Success "后端环境设置完成"

# 设置前端环境
Write-Host ""
Write-Step "4/6 设置前端环境..."

Write-Host "安装 Node.js 依赖..." -ForegroundColor Gray
Push-Location $FRONTEND_DIR
npm install
Pop-Location
if ($LASTEXITCODE -ne 0) {
    Write-Error "安装依赖失败"
    Read-Host "按回车键退出"
    exit 1
}
Write-Success "前端环境设置完成"

# 启动后端服务
Write-Host ""
Write-Step "5/6 启动后端服务..."

$venvUvicorn = Join-Path $venvDir "Scripts\uvicorn.exe"
$backendLog = Join-Path $RUN_DIR "backend.log"

Start-Process -FilePath $venvUvicorn `
    -ArgumentList "app.main:app", "--reload", "--port", "8000" `
    -WorkingDirectory $BACKEND_DIR `
    -RedirectStandardOutput $backendLog `
    -RedirectStandardError $backendLog `
    -WindowStyle Normal

Start-Sleep -Seconds 2
Write-Success "后端服务已启动 (端口: 8000)"

# 启动前端服务
Write-Host ""
Write-Step "6/6 启动前端服务..."

$frontendLog = Join-Path $RUN_DIR "frontend.log"

Start-Process -FilePath "npm" `
    -ArgumentList "run", "dev", "--", "--host", "127.0.0.1", "--port", "5173" `
    -WorkingDirectory $FRONTEND_DIR `
    -RedirectStandardOutput $frontendLog `
    -RedirectStandardError $frontendLog `
    -WindowStyle Normal

Start-Sleep -Seconds 2
Write-Success "前端服务已启动 (端口: 5173)"

# 显示成功信息
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
Write-Host "  后端: Get-Content $backendLog -Tail 20 -Wait"
Write-Host "  前端: Get-Content $frontendLog -Tail 20 -Wait"

Write-Host ""
Write-Host "停止服务:" -ForegroundColor Yellow
Write-Host "  .\scripts\stop.ps1"

Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
