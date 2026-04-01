# 启动脚本使用指南

本项目提供了跨平台的启动脚本，支持 **macOS**、**Linux** 和 **Windows** 系统。

## 快速开始

### macOS / Linux

```bash
# 方式 1: 使用 Bash 脚本（推荐）
bash scripts/dev.sh

# 方式 2: 使用 Python 脚本
python3 scripts/dev.py
```

### Windows

```powershell
# 方式 1: 使用批处理脚本（推荐，完全自动化）
.\scripts\dev.bat

# 方式 2: 使用 PowerShell 脚本
.\scripts\dev.ps1

# 方式 3: 使用 Python 脚本（需要已安装 Python）
python scripts\dev.py
```

## 功能特性

### ✅ 自动环境检测与安装

启动脚本会自动检测以下环境，如果缺失会提示安装：

- **Python 3.8+**：后端运行环境
- **Node.js 16+**：前端运行环境

支持的安装方式：

#### macOS
- Homebrew (`brew install python` / `brew install node`)

#### Linux
- apt (`apt-get install python3 nodejs`)
- yum (`yum install python3 nodejs`)
- dnf (`dnf install python3 nodejs`)

#### Windows
- winget (`winget install Python.Python.3.11`)
- Chocolatey (`choco install python nodejs`)

### ✅ 自动依赖安装

- 自动创建 Python 虚拟环境
- 自动安装 Python 依赖（`requirements.txt`）
- 自动安装 Node.js 依赖（`npm install`）

### ✅ 后台运行与日志管理

- 服务在后台运行，不占用终端
- 日志输出到文件，便于排查问题
- PID 文件管理，防止重复启动

## 脚本说明

### 启动脚本

| 脚本 | 适用系统 | 说明 |
|------|---------|------|
| `scripts/dev.bat` | Windows | 批处理脚本，完全自动化，无需 Python |
| `scripts/dev.sh` | macOS / Linux | Bash 脚本，功能完整 |
| `scripts/dev.ps1` | Windows | PowerShell 脚本，功能完整 |
| `scripts/dev.py` | 全平台 | Python 脚本，跨平台通用 |

### 停止脚本

| 脚本 | 适用系统 | 说明 |
|------|---------|------|
| `scripts/stop.bat` | Windows | 停止所有服务 |
| `scripts/stop.sh` | macOS / Linux | 停止所有服务 |
| `scripts/stop.ps1` | Windows | 停止所有服务 |
| `scripts/stop.py` | 全平台 | 停止所有服务 |

## 使用示例

### 首次启动

```bash
# macOS / Linux
bash scripts/dev.sh
```

脚本会依次执行：

```
1. 检查 Python 环境
   ✓ 找到 python3: 3.11.5
   ✓ Python 版本满足要求 (>= 3.8)

2. 检查 Node.js 环境
   ✓ 找到 node: v18.17.0
   ✓ Node.js 版本满足要求 (>= 16)

3. 设置后端环境
   ✓ 虚拟环境创建成功
   ✓ 后端环境设置完成

4. 设置前端环境
   ✓ 前端环境设置完成

5. 启动服务
   ✓ 后端服务已启动 (PID: 12345)
   ✓ 前端服务已启动 (PID: 12346)
```

### 环境缺失时的处理

如果系统缺少 Python 或 Node.js，脚本会提示安装：

```bash
⚠ 未找到合适的 Python 环境

是否自动安装 Python? (y/n): y

▶ 在 macOS 上安装 Python
ℹ 使用 Homebrew 安装 Python...
# 自动执行安装命令
```

### 查看日志

```bash
# 后端日志
tail -f .run/backend.log

# 前端日志
tail -f .run/frontend.log

# Windows PowerShell
Get-Content .run\backend.log -Tail 20 -Wait
Get-Content .run\frontend.log -Tail 20 -Wait
```

### 停止服务

```bash
# macOS / Linux
bash scripts/stop.sh

# Windows
.\scripts\stop.ps1

# 全平台
python scripts/stop.py
```

## 服务地址

启动成功后，可以访问：

- **前端应用**：http://127.0.0.1:5173/
- **后端 API**：http://127.0.0.1:8000
- **健康检查**：http://127.0.0.1:8000/api/health
- **API 文档**：http://127.0.0.1:8000/docs

## 目录结构

```
demo/
├── scripts/
│   ├── dev.sh          # macOS/Linux 启动脚本
│   ├── dev.ps1         # Windows 启动脚本
│   ├── dev.py          # 跨平台启动脚本
│   ├── stop.sh         # macOS/Linux 停止脚本
│   ├── stop.ps1        # Windows 停止脚本
│   └── stop.py         # 跨平台停止脚本
├── .run/               # 运行时文件（自动创建）
│   ├── backend.pid     # 后端进程 ID
│   ├── frontend.pid    # 前端进程 ID
│   ├── backend.log     # 后端日志
│   └── frontend.log    # 前端日志
├── backend/            # 后端代码
└── frontend/           # 前端代码
```

## 常见问题

### 1. Python 版本过低

**问题**：提示 "Python 版本过低: 3.7 < 3.8"

**解决**：
```bash
# macOS
brew install python@3.11

# Linux (Ubuntu/Debian)
sudo apt-get install python3.11

# Windows
# 下载安装最新版 Python: https://www.python.org/downloads/
```

### 2. Node.js 未安装

**问题**：提示 "未找到合适的 Node.js 环境"

**解决**：
```bash
# macOS
brew install node

# Linux (Ubuntu/Debian)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Windows
# 下载安装 Node.js: https://nodejs.org/
```

### 3. 端口被占用

**问题**：提示端口 8000 或 5173 被占用

**解决**：
```bash
# 查找占用端口的进程
# macOS / Linux
lsof -i :8000
lsof -i :5173

# Windows
netstat -ano | findstr :8000
netstat -ano | findstr :5173

# 终止进程
kill -9 <PID>  # macOS / Linux
taskkill /F /PID <PID>  # Windows
```

### 4. 权限不足

**问题**：提示 "Permission denied"

**解决**：
```bash
# 添加执行权限
chmod +x scripts/dev.sh
chmod +x scripts/stop.sh
```

### 5. Windows 执行策略限制

**问题**：PowerShell 提示 "无法加载文件，因为在此系统上禁止运行脚本"

**解决**：
```powershell
# 临时允许运行脚本（仅当前会话）
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 或者使用 Python 脚本
python scripts\dev.py
```

## 高级配置

### 环境变量

可以通过环境变量自定义配置：

```bash
# 自定义后端端口
export BACKEND_PORT=8001

# 自定义前端端口
export FRONTEND_PORT=3000

# 自定义同步分支
export SYNC_BRANCHES="main,master,develop"
```

### 使用本地 Jupyter

修改案例配置文件 `backend/content/cases/*/case.json`：

```json
{
  "notebook_iframe_url": "http://localhost:8888/lab?token=YOUR_TOKEN"
}
```

## 技术支持

如有问题，请查看：

1. 日志文件：`.run/backend.log` 和 `.run/frontend.log`
2. 健康检查：http://127.0.0.1:8000/api/health
3. 项目文档：[README.md](../README.md)
