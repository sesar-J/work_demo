# 启动指南

## 🚀 快速启动（推荐）

### Windows 用户

**方式 1：双击启动（最简单）**
- 在项目根目录找到 `start.bat` 文件
- 双击运行即可

**方式 2：命令行启动**
```powershell
# 进入项目目录
cd D:\work\demo

# 运行启动脚本
start.bat
```

### macOS / Linux 用户

```bash
# 进入项目目录
cd /你的路径/demo

# 运行启动脚本
./start.sh
```

## ✨ 自动化功能

启动脚本会自动完成以下操作：

1. ✅ **检测并安装 Python**（如果缺失）
   - Windows: 使用 winget 或 Chocolatey
   - macOS: 使用 Homebrew
   - Linux: 使用 apt/yum/dnf

2. ✅ **检测并安装 Node.js**（如果缺失）
   - Windows: 使用 winget 或 Chocolatey
   - macOS: 使用 Homebrew
   - Linux: 使用 apt/yum/dnf

3. ✅ **自动设置项目环境**
   - 创建 Python 虚拟环境
   - 安装 Python 依赖
   - 安装 Node.js 依赖

4. ✅ **启动前后端服务**
   - 后端服务：http://127.0.0.1:8000
   - 前端服务：http://127.0.0.1:5173

## 🛑 停止服务

### Windows
```powershell
.\scripts\stop.ps1
```

### macOS / Linux
```bash
./scripts/stop.sh
```

或者直接关闭弹出的服务窗口。

## 📍 访问应用

启动成功后，在浏览器中访问：

- **前端应用**：http://127.0.0.1:5173/
- **后端 API**：http://127.0.0.1:8000
- **健康检查**：http://127.0.0.1:8000/api/health
- **API 文档**：http://127.0.0.1:8000/docs

## 📋 查看日志

### Windows
```powershell
# 后端日志
Get-Content .run\backend.log -Tail 20 -Wait

# 前端日志
Get-Content .run\frontend.log -Tail 20 -Wait

# 或用记事本打开
notepad .run\backend.log
notepad .run\frontend.log
```

### macOS / Linux
```bash
# 后端日志
tail -f .run/backend.log

# 前端日志
tail -f .run/frontend.log
```

---

## 📚 高级使用

### 手动启动方式

如果你想手动控制启动过程，可以使用以下方式：

#### Windows
```powershell
# 方式 1: PowerShell 脚本（推荐）
.\scripts\dev.ps1

# 方式 2: 批处理脚本
.\scripts\dev.bat

# 方式 3: Python 脚本（需要已安装 Python）
python scripts\dev.py
```

#### macOS / Linux
```bash
# 方式 1: Bash 脚本（推荐）
bash scripts/dev.sh

# 方式 2: Python 脚本（需要已安装 Python）
python3 scripts/dev.py
```

### 脚本说明

| 脚本文件 | 适用系统 | 说明 |
|---------|---------|------|
| `start.bat` | Windows | 统一启动入口（推荐） |
| `start.sh` | macOS/Linux | 统一启动入口（推荐） |
| `scripts/dev.ps1` | Windows | PowerShell 详细脚本 |
| `scripts/dev.bat` | Windows | 批处理详细脚本 |
| `scripts/dev.sh` | macOS/Linux | Bash 详细脚本 |
| `scripts/dev.py` | 全平台 | Python 跨平台脚本 |

---

## ❓ 常见问题

### 1. Windows 提示"禁止运行脚本"

**问题**：PowerShell 提示"无法加载文件，因为在此系统上禁止运行脚本"

**解决**：
```powershell
# 临时允许运行脚本（仅当前会话）
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# 然后重新运行
start.bat
```

### 2. Python 版本过低

**问题**：提示 "Python 版本过低: 3.7 < 3.8"

**解决**：
- 脚本会自动安装最新版 Python
- 或手动下载：https://www.python.org/downloads/

### 3. Node.js 未安装

**问题**：提示 "未找到 Node.js"

**解决**：
- 脚本会自动安装 Node.js
- 或手动下载：https://nodejs.org/

### 4. 端口被占用

**问题**：端口 8000 或 5173 被占用

**解决**：

**Windows**：
```powershell
# 查找占用端口的进程
netstat -ano | findstr :8000
netstat -ano | findstr :5173

# 终止进程
taskkill /F /PID <PID>
```

**macOS/Linux**：
```bash
# 查找占用端口的进程
lsof -i :8000
lsof -i :5173

# 终止进程
kill -9 <PID>
```

### 5. 安装环境后仍然提示未找到

**问题**：安装 Python/Node.js 后仍然提示未找到

**解决**：

**Windows**：
- 关闭当前 PowerShell 窗口
- 重新打开 PowerShell
- 再次运行 `start.bat`

**macOS/Linux**：
```bash
# 刷新 shell 配置
source ~/.bashrc  # 或 source ~/.zshrc

# 再次运行
./start.sh
```

---

## 🔧 环境要求

### 最低要求

- **Python**: 3.8 或更高版本
- **Node.js**: 16.0 或更高版本

### 推荐版本

- **Python**: 3.11+
- **Node.js**: 20.x LTS

---

## 💡 提示

1. **首次启动较慢**：需要下载和安装依赖，请耐心等待
2. **网络问题**：如果下载依赖失败，可以配置国内镜像源
3. **权限问题**：macOS/Linux 可能需要 `chmod +x start.sh` 赋予执行权限
4. **日志排查**：遇到问题时，先查看日志文件 `.run/backend.log` 和 `.run/frontend.log`

---

## 📞 获取帮助

如有问题，请：

1. 查看日志文件：`.run/backend.log` 和 `.run/frontend.log`
2. 检查健康状态：http://127.0.0.1:8000/api/health
3. 查看项目文档：项目根目录的 `README.md`
