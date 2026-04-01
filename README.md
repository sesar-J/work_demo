# Hands-on 实践中心（MVP）

技术栈：
- 前端：Vue3 + Vite + TinyVue
- 后端：FastAPI + SQLModel + SQLite
- 内容：`ipynb` 为源，后端自动转换为 HTML 渲染

## 目录结构

```text
demo/
  backend/
    app/
      api/
      services/
    content/cases/
  frontend/
```

## 启动方式（mac + Windows）

### A. 使用脚本（推荐）

根目录只保留两个入口：
- macOS/Linux: `run.sh`
- Windows: `run.bat`

#### macOS/Linux

```bash
# 已有 Python + Node.js
./run.sh start

# 没有环境时自动安装后再启动
./run.sh install

# 停止前后端
./run.sh stop
```

#### Windows（PowerShell 或 CMD）

```bat
REM 已有 Python + Node.js
run.bat start

REM 没有环境时自动安装后再启动
run.bat install

REM 停止前后端
run.bat stop
```

说明：
- 在 PowerShell 中请用 `.\run.bat start|install|stop` 调用。
- 不要把 `cmd` 语法（如 `cd /d`、`&&`）直接粘贴到 PowerShell 里执行。

Windows 日志文件（排错用）：
- `.run\backend.log` / `.run\backend.err.log`
- `.run\frontend.log` / `.run\frontend.err.log`
- `.run\backend.port` / `.run\frontend.port`（本次实际启动端口）

Windows 端口说明：
- 默认后端 `8000`、前端 `5173`。
- 若默认端口被占用，`run.bat start` 会自动向后扫描可用端口并继续启动。
- 前端会自动读取本次后端端口（通过 `VITE_API_BASE_URL` 注入），无需手动改代码。
- 如需指定起始端口，可在命令前设置：
  - `set BACKEND_PORT=8001 && set FRONTEND_PORT=5174 && run.bat start`

Windows 换行说明：
- 仓库已通过 `.gitattributes` 强制 `*.bat` 使用 `CRLF`（避免批处理异常）。
- 如果你是旧仓库直接 `pull` 后仍是 `LF`，可重新检出该文件：
  - `git checkout -- run.bat`

脚本模式说明：
- `start`：机器已有 Python/Node.js 时直接启动
- `install`：缺少环境时自动安装后再启动
- `stop`：停止 `8000/5173` 端口上的前后端进程

### B. 不使用脚本（手动）

#### macOS/Linux 手动启动

```bash
# 终端 1：后端
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m uvicorn app.main:app --reload --port 8000
```

```bash
# 终端 2：前端
cd frontend
npm install
npm run dev -- --host 127.0.0.1 --port 5173
```

#### Windows 手动启动

```bat
REM 终端 1：后端
cd backend
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements.txt
.venv\Scripts\python.exe -m uvicorn app.main:app --reload --port 8000
```

```bat
REM 终端 2：前端
cd frontend
npm install
npm run dev -- --host 127.0.0.1 --port 5173
```

访问地址：
- 前端：`http://127.0.0.1:5173/`
- 后端：`http://127.0.0.1:8000`
- 健康检查：`http://127.0.0.1:8000/api/health`

## 当前已实现能力（MVP）

1. 首页案例列表
2. 案例详情页（来源于 `detail.ipynb` 自动转换 HTML）
3. 操作页左右布局（左文档，右 iframe notebook）
4. 后端案例管理（SQLModel + SQLite）
5. Git 事件同步接口（`POST /api/sync/git-event`），收到事件后触发 content 仓库 `git pull`
6. 同步后自动执行 `ipynb -> HTML` 重建（更新左侧文档内容）
7. 同步审计日志表 `SyncEventLog`（记录来源、状态、消息、时间）
8. webhook 分支过滤（默认仅 `main/master`，可通过 `SYNC_BRANCHES` 配置）
9. 增量重建（根据提交文件路径，仅重建受影响案例）
10. 操作页按“用户 + 案例”启动独立 Notebook 会话（刷新不保留历史状态）
11. 所有案例统一 Terraform 模板接口：`GET /api/lab/terraform-template`

## 内容组织规范（已落地）

每个案例目录建议如下：

```text
backend/content/cases/<case-slug>/
  case.json
  detail.ipynb
  operation.ipynb
```

`case.json` 示例字段：
- `slug` / `title` / `summary` / `cover_image`
- `detail_notebook` / `operation_notebook`
- `notebook_iframe_url`

## Git 同步设计说明（第一版）

- 内容仓库（`backend/content`）由 DTSE 团队维护；
- 当内容仓库有提交时，通过 webhook 调用后端同步接口；
- 后端拉取最新内容后，前端重新请求详情，即可看到新内容；
- webhook 兼容：
  - `X-CodeArts-Signature`（CodeArts）
  - `X-Gitcode-Token`（GitCode token）
  - `X-Hub-Signature-256`（兼容标准签名头）
- 同步接口：
  - `POST /api/sync/git-event`：接收 webhook 并增量同步
  - `POST /api/sync/rebuild`：手动重建所有案例
  - `GET /api/sync/status`：查询最新同步状态
- Lab 接口：
  - `POST /api/lab/session`：按用户+案例创建独立会话 URL
  - `GET /api/lab/terraform-template`：获取统一 Terraform 模板
- 后续可扩展：
  - 增量同步与版本号
  - `ipynb` 转换异步队列
  - 缓存失效策略

## 环境变量

- `GIT_WEBHOOK_SECRET`：webhook 校验密钥（推荐必填）
- `SYNC_BRANCHES`：允许触发同步的分支列表，逗号分隔，默认 `main,master`
- `DTSE_REPO`：允许同步的 DTSE 仓库名（例如 `dtse/case-content`）
- `NOTEBOOK_BASE_URL`：Notebook 基础地址（默认 `https://jupyter.org/try-jupyter/lab/`）

## Python 版本建议

- 推荐 Python 3.11+（更好的类型语法支持和性能）
- 当前代码已兼容 Python 3.9，可先运行；升级后再切到 3.11 虚拟环境即可
