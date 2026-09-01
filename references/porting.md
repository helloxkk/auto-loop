# porting.md —— 宿主移植表

auto-loop 的循环设计宿主无关；差异只在"能力原语"的名字。移植 = 把下表右列换成目标宿主的等价物。

## 能力 → ZCode 映射（本技能默认）

| 能力原语 | ZCode 实现 | 说明 |
|---|---|---|
| 派后台子代理 | `Agent(subagent_type=general-purpose, run_in_background=true)` | 任务书即 prompt，自包含 |
| 查子代理状态 | `TaskOutput(task_id, block=false)` | 注意：查无≠已死（假阴性实录） |
| 停子代理 | `TaskStop(task_id)` | |
| 与子代理通信 | `SendMessage(to=agent_id)` | 中途反馈/指令下发 |
| 定时巡逻 | `CronCreate/CronUpdate/CronDelete`（cron `*/30 * * * *`） | 自毁式暂停用 Delete+重建 |
| 读其他会话 | `ReadSessionContext(sessionId)` | 用户自有会话的收官判定/经验提取 |
| 不打扰纪律 | 禁 `AskUserQuestion` | 无人值守期一切决策记账不提问 |

## → Claude Code 映射

| 能力 | Claude Code 等价 |
|---|---|
| 派后台子代理 | `Task` 工具（subagent_type: general）后台任务 |
| 查状态/停止 | TaskOutput/TaskStop 同名能力 |
| 与子代理通信 | 无直接等价——把中途反馈写进 loop 目录 `pending_feedback`，由巡逻会话转发；或用 `claude -p "<任务书>"` 独立进程 + 文件通信 |
| 定时巡逻 | 系统 crontab 调 `claude -p "执行 ~/.<proj>-loop/protocol.md 的巡逻步骤"`；暂停=注释 crontab 行 |
| 读其他会话 | 无等价——用户自有会话改为"收官时把总结写入 morning.md"约定 |

## → Codex / 通用 CLI agent 映射

- 子代理 = 独立 CLI 进程（`codex exec "<任务书>" &`），产出以 git commit + 报告文件为地面真源（本来就是本循环的判定标准，天然兼容）
- 巡逻 = 系统 crontab 调一次 CLI 跑巡逻 prompt；判定全靠 patrol-scan.sh 证据 + git
- 通信 = 全走 loop 目录文件（state.md pending_feedback / log.md），无实时通道时以"文件+下班次生效"降级

## 通用降级原则

实时通道（SendMessage/ReadSessionContext）缺失时，一切改为**文件协议**：反馈进 state.md、子代理收官报告写 reports/、巡逻按文件判定。本循环的判定本就以 git+账本为准，文件降级几乎无损。
