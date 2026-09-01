#!/bin/bash
# init.sh —— auto-loop 初始化脚手架：建运行目录+落四件套
# 用法: init.sh <项目名> [仓库绝对路径]
set -u
NAME="${1:?用法: init.sh <项目名> [仓库绝对路径]}"
REPO="${2:-$PWD}"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$HOME/.${NAME}-loop"

if [ -d "$DIR" ]; then echo "已存在: $DIR（如需重来先手动删）"; exit 1; fi
mkdir -p "$DIR"
for f in protocol state leadbook; do
  cp "$SKILL_DIR/templates/$f.tpl.md" "$DIR/$f.md"
done
cat > "$DIR/morning.md" << EOF
# ${NAME} 迭代晨报

（每次轮次收官由负责人追加；用户验收入口）
EOF
touch "$DIR/log.md"
# 项目名与仓库路径回填（模板内 {REPO} 占位）
sed -i '' "s|{REPO}|${REPO}|g" "$DIR/protocol.md" 2>/dev/null || sed -i "s|{REPO}|${REPO}|g" "$DIR/protocol.md"

cat << EOF

初始化完成: $DIR
  protocol.md / state.md / leadbook.md / morning.md / log.md
  仓库: $REPO

负责人接下来说明（按 SKILL.md 执行）:
  1. 在 protocol.md 填 {FILL} 项: 验收命令/红线/环境守卫/方向池（问用户一次）
  2. state.md 填 chain_state 与首轮主题
  3. 建 30 分钟巡逻 cron（prompt 见 protocol.md 末尾模板）
  4. 写首轮任务书（templates/goal-prompt.tpl.md）并 spawn
  若项目没有可判定验收命令——首轮主题改为"先造一个"
EOF
