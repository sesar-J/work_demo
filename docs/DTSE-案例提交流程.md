# DTSE 案例提交流程（实践中心）

本文用于约束 DTSE 案例内容仓的提交规范，确保案例内容能够被本系统稳定同步、正确渲染并展示到前端页面。

## 1. 目标

- 统一 DTSE 案例目录结构，减少同步失败与渲染异常。
- 明确每个文件在前端的最终展示位置。
- 给出可执行的提交流程与验收清单，降低沟通成本。

## 2. 仓库目录规范（必须遵守）

DTSE 内容仓应采用如下目录结构：

```text
仓库根目录
└── cases/
    ├── <case-folder-a>/
    │   ├── case.json
    │   ├── detail.ipynb
    │   ├── operation.ipynb
    │   └── lab-files/
    │       ├── versions.tf
    │       ├── provider.tf
    │       ├── variables.tf
    │       ├── main.tf
    │       └── terraform.tfvars
    ├── <case-folder-b>/
    │   ├── case.json
    │   ├── detail.ipynb
    │   ├── operation.ipynb
    │   └── lab-files/
    │       └── ...
    └── ...
```

约束说明：

- `cases/` 为固定根目录，不可改名。
- 每个案例必须是 `cases/` 下的一个独立子目录。
- 每个案例目录必须至少包含：
  - `case.json`
  - 详情 notebook（默认 `detail.ipynb`）
  - 操作 notebook（默认 `operation.ipynb`）
- 每个案例目录建议包含：
  - `lab-files/`（右侧 JupyterLab 会话中的真实实操文件来源）

## 3. case.json 字段规范

每个案例目录下必须有 `case.json`，建议模板如下：

```json
{
  "slug": "huawei-vpc-terraform",
  "title": "华为云 VPC Terraform 部署指南",
  "summary": "通过 Terraform 在华为云创建 VPC、子网与安全组的实践案例。",
  "cover_image": "https://example.com/cover.png",
  "detail_notebook": "detail.ipynb",
  "operation_notebook": "operation.ipynb",
  "notebook_iframe_url": "https://jupyter.org/try-jupyter/lab/"
}
```

字段要求：

- `slug`：全局唯一、稳定，不可频繁改动。
- `title`：案例标题（展示在首页卡片和详情页）。
- `summary`：案例简介（展示在首页卡片和详情页摘要）。
- `cover_image`：封面图 URL（建议可公开访问）。
- `detail_notebook`：详情页对应的 ipynb 文件名。
- `operation_notebook`：操作页左侧文档对应的 ipynb 文件名。
- `notebook_iframe_url`：操作页右侧 iframe 地址。

## 4. 路径与页面展示映射

| DTSE 路径 | 用途 | 前端展示位置 |
|---|---|---|
| `cases/<case-folder>/case.json` | 案例元数据 | 首页卡片（标题/摘要/封面）、详情页标题摘要、右侧 iframe 地址 |
| `cases/<case-folder>/detail.ipynb` | 详情正文源 | 详情页正文（后端转换为 HTML） |
| `cases/<case-folder>/operation.ipynb` | 操作说明源 | 操作页左侧文档区（后端转换为 HTML） |
| `cases/<case-folder>/lab-files/*.tf` | 真实实操文件源 | 操作页右侧 JupyterLab 会话工作目录中的 `.tf` 文件 |

补充说明：

- 系统会将 ipynb 转换为 HTML 后再返回前端。
- 右侧 Notebook iframe 内容由 `notebook_iframe_url` 决定。
- 未来右侧若升级为云开发 JupyterLab，会话启动时将 `lab-files/` 注入该会话目录。

## 5. 右侧 TF 文件来源与未来会话模型（关键）

为避免“左侧文档与右侧实操文件不一致”，平台采用以下口径：

- **单一内容源**：右侧 `.tf` 文件来自 DTSE 仓 `cases/<case-folder>/lab-files/`。
- **会话注入机制**：用户进入操作页时，平台拉起独立云开发会话，并把该案例 `lab-files/` 复制到会话工作目录。
- **环境与内容分离**：
  - 云开发镜像提供工具链（Terraform、Python、Git）。
  - 案例业务文件仅来自 DTSE 仓，不在镜像内固化。

建议 DTSE 在 `lab-files/` 中至少提供：

- `versions.tf`
- `provider.tf`
- `variables.tf`
- `main.tf`
- `terraform.tfvars`

可选增强文件：

- `README.md`（该案例右侧执行提示）
- `scripts/`（初始化脚本）

会话行为约定：

- 每次进入操作页为新会话，不保留上一次用户改动。
- AK/SK 为会话运行参数，不作为案例文件内容来源。

## 6. 提交流程（DTSE）

1. 在 `cases/` 下新建案例目录，补齐 `case.json`、`detail.ipynb`、`operation.ipynb`。
2. 本地自检：
   - JSON 语法合法。
   - ipynb 可正常打开。
   - `case.json` 的 notebook 文件名与真实文件一致。
3. 提交到受监控分支（默认 `main` 或 `master`）。
4. 触发 webhook 后，平台自动执行：
   - `git pull`
   - 识别变更路径
   - 增量重建受影响案例
5. 在平台首页确认：
   - 案例是否出现/更新
   - 详情页、操作页内容是否符合预期

## 7. 分支与仓库监听约束

- 平台只处理 DTSE 指定仓库事件（由服务端 `DTSE_REPO` 控制）。
- 平台只处理允许分支（由服务端 `SYNC_BRANCHES` 控制，默认 `main,master`）。
- 非 DTSE 仓或非允许分支事件会被忽略。

## 8. 内容编写建议（提升展示质量）

- 标题层级清晰：`#`、`##`、`###` 分层。
- 代码块完整可复制，尽量使用连续命令块。
- 图片尽量使用公网可访问 URL。
- 避免把超长日志直接贴入正文，建议截取关键片段。

## 9. 常见问题

### Q1：为什么案例没更新到前端？

优先检查：

- 是否提交到了受监控分支。
- webhook 是否成功投递。
- 路径是否在 `cases/<case-folder>/...` 下。
- `case.json` 与 notebook 文件名是否匹配。

### Q2：`slug` 可以改吗？

不建议。`slug` 变化会被系统视为新案例，可能导致历史链接失效或出现重复条目。

### Q3：是否支持只改一个 notebook？

支持。只要路径在该案例目录下，系统会按变更路径做增量重建。

### Q4：右侧 `.tf` 文件是来自模板还是 DTSE 仓？

目标口径是 **DTSE 仓为主**：来自 `lab-files/`。平台统一模板只作为兜底，不应替代案例真实文件。

### Q5：为什么还需要 `operation.ipynb`，不能只放 `.tf` 吗？

`operation.ipynb` 负责左侧步骤说明与教学引导，`lab-files/` 负责右侧真实实操文件。两者分工不同，建议同时维护。

## 10. 提交前检查清单（可直接勾选）

- [ ] 路径在 `cases/<case-folder>/` 下
- [ ] `case.json` 字段完整且 JSON 合法
- [ ] `detail_notebook`、`operation_notebook` 文件存在
- [ ] `lab-files/` 已提供并含核心 `.tf` 文件
- [ ] `slug` 唯一且稳定
- [ ] notebook 能正常打开，代码块可读
- [ ] 提交分支在允许范围（`main/master`）

