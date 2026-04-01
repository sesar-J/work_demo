# 启动指南（精简版）

项目启动入口已统一为根目录两个脚本：

- macOS/Linux: `./start.sh`
- Windows: `start.bat`

## 两种一键模式

### 1) 已有环境（默认）

- macOS/Linux: `./start.sh`
- Windows: `start.bat`

要求：机器上已安装 Python 与 Node.js。

### 2) 无环境自动安装后启动

- macOS/Linux: `./start.sh install`
- Windows: `start.bat install`

说明：
- macOS 通过 Homebrew 安装缺失环境
- Windows 通过 winget/choco 安装缺失环境

## 启动后地址

- 前端: `http://127.0.0.1:5173/`
- 后端: `http://127.0.0.1:8000`
- 健康检查: `http://127.0.0.1:8000/api/health`

## 日志与停止

- 日志文件：`.run/backend.log`、`.run/frontend.log`
- 停止（macOS/Linux）：`./scripts/stop.sh`
- 停止（Windows）：`scripts\stop.bat`
