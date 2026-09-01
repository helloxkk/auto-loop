# state.tpl.md —— 复制到 ~/.<项目名>-loop/state.md

round: 0
kind: idle
task_id: （无）
theme: （无）
started: —
status: idle
history: []
pending_feedback: （空）
pm_proposals: （负责人自提需求池——每轮收官后以产品视角增补，与用户反馈同级编排）
chain_state: 初始（首轮主题：{FILL 用户需求}）

# 使用约定（保持文件格式，追加不重写）
# - 每轮收官：history 追加一行"轮次|主题|结果|调度侧备注"
# - 用户反馈即时进 pending_feedback，被消化后清空并注明去向
# - 负责人提案进 pm_proposals（P 编号），完成销账
# - chain_state 记录特殊态：awaiting_user / awaiting_device / paused 等
