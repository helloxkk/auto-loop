#!/bin/bash
# patrol-scan.sh —— 巡逻证据采集：把每班次重复的机械快照合成一份摘要，供负责人判定
# 用法: patrol-scan.sh <仓库路径> [状态目录]
#   环境变量: ORPHAN_PAT="soak|regression|voice-test"  独占资源长任务进程模式（孤儿清查）
#             GUARD_CMD="date +%s"  环境守卫探测命令（任意探测命令，输出原样呈报）
set -u
REPO="${1:?用法: patrol-scan.sh <仓库路径> [状态目录]}"
LOOP_DIR="${2:-}"
ORPHAN_PAT="${ORPHAN_PAT:-}"
GUARD_CMD="${GUARD_CMD:-}"
# 配置外置：~/.<proj>-loop/scan.env 可固化 ORPHAN_PAT/GUARD_CMD（环境变量优先于文件）
if [ -n "${2:-}" ] && [ -f "$2/scan.env" ]; then . "$2/scan.env"; fi

echo "===== patrol-scan $(date '+%m-%d %H:%M:%S') ====="

echo "--- git (HEAD 3 / status 摘要) ---"
git -C "$REPO" log --oneline -3 2>&1
git -C "$REPO" status --short 2>&1 | head -8

if [ -n "$ORPHAN_PAT" ]; then
  echo "--- 孤儿长任务进程 ($ORPHAN_PAT) ---"
  ps aux | grep -E "$ORPHAN_PAT" | grep -v grep | grep -v "shell-snapshot" | awk '{print $2, $9, substr($0, index($0,$11), 70)}'
  echo "(空=无残留)"
fi

if [ -n "$GUARD_CMD" ]; then
  echo "--- 环境守卫探测 ---"
  eval "$GUARD_CMD" 2>&1
fi

if [ -n "$LOOP_DIR" ] && [ -f "$LOOP_DIR/state.md" ]; then
  echo "--- state 摘要 (round/status 首行字段) ---"
  grep -E "^round:|^kind:|^task_id:|^status:|^chain_state:" "$LOOP_DIR/state.md" | tail -5
fi

echo "--- 磁盘/负载 ---"
df -h / | tail -1
uptime
echo "===== 采集结束；判定/接续/环境纠正由负责人执行 ====="
