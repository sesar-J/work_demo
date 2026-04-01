#!/bin/bash

echo ""
echo "============================================================"
echo "  Hands-on 实践中心 - macOS/Linux 启动脚本"
echo "============================================================"
echo ""
echo "正在启动，请稍候..."
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 调用 Bash 脚本
bash "${SCRIPT_DIR}/scripts/dev.sh"
