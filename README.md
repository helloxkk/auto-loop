# auto-loop · 自主闭环迭代开发技能 / Autonomous Dev-Loop Skill

> 你当老板：提需求、验收。AI 负责人管其余一切：派发子代理开发、测试、巡逻、接续、复盘——循环到你说停。
> You're the boss: state requirements and do acceptance. An AI foreman runs everything else — dispatching subagents for dev & test, patrol, chaining, retrospectives — looping until you say stop.

在一个真实项目上验证：**25 轮自主迭代 / 2 天**（架构重构、预研支线、新引擎接入、多轮长跑压测），全程用户只做验收与拍板。
Validated on a real project: **25 autonomous rounds in 2 days** (architecture refactor, research spike, new engine integration, multi-round soak tests) with the user only accepting deliverables.

## 为什么需要它 / Why

一次性的 agent 会话在人离开后就停了；把"继续"反复喂给一个长会话，它会越跑越漂。auto-loop 用**外部节奏 + 地面真值**解决这个问题：
One-shot agent sessions stop when you look away; a single long session fed with "continue" drifts. auto-loop fixes this with an external heartbeat and ground truth:

- **可判定的验收命令是地基**——每轮好坏由 `make test` 这类命令客观判定，不由 agent 自称
- **巡逻班次**（默认 30 分钟）从外部检查循环健康：收官判定、失败保护、孤儿进程清查
- **治理纪律**：欠债显式结转、PM 自审、事故固化进协议、每 3 轮复盘——每条纪律都来自真实事故的结晶（见 `references/lessons.md`）

## 它是怎么工作的 / How it works

```
用户(需求/验收/拍板)                        用户拍板节(不阻塞循环)
   │ 只在边界介入                              ▲
   ▼                                          │
┌─────────────── 负责人 Agent(Foreman) ──────────────────┐
│  派轮 ──► 轮次 Agent 子代理: 实现+客观验证+增量commit     │
│   ▲      (主线串行[独占资源] / 支线并行[文件域不相交])     │
│  接续 ◄── 收官判定(从严: git+账本+任务状态三方一致)        │
│   │                                                     │
│  巡逻 cron(默认30min): 证据采集脚本 → 判定 → 失败保护      │
│  治理: 欠债结转/PM自审≥3条/事故固化/每3轮复盘(leadbook)    │
└─────────────────────────────────────────────────────────┘
```

三个状态文件是循环的"操作系统"，运行目录放在**项目外**（`~/.<项目名>-loop/`），不污染项目 git：

| 文件 | 角色 / Role |
|---|---|
| `protocol.md` | 项目协议：验收命令、红线、环境守卫、主题决策规则 |
| `state.md` | 实时状态：当前轮次、用户反馈池、负责人提案池 |
| `leadbook.md` | 负责人复盘手册：每 3 轮台账 + 系统级经验 |
| `morning.md` / `log.md` | 你的验收入口（晨报）/ 巡逻流水 |

## 安装 / Install

```sh
git clone https://github.com/helloxkk/auto-loop.git ~/.agents/skills/auto-loop
```

- ZCode 自动发现；也可放 `<project>/.agents/skills/` 仅单项目启用
- 其他宿主（Claude Code / Codex / 通用 CLI agent）的能力映射与降级方案见 `references/porting.md`

## 快速开始 / Quickstart

1. 在你的项目里说："**用 auto-loop 跑 <需求>，我只管验收**"（英文: "use auto-loop to run <goal>, I'll only do acceptance"）
2. 负责人检查四个前提并初始化（缺啥先让首轮补啥）：
   - 可判定的验收命令（`make test` / `npm test` …没有就先造，`example/` 有实例）
   - backlog 真源文件 · 红线清单（不许 agent 做的事）· 环境守卫项（如有）
3. 循环开始：写任务书派轮 → 子代理实现+客观验证+增量 commit → 巡逻收官判定 → 接续下一轮
4. 之后你只需要：随时插反馈（即时下发不阻塞）/ 说"继续"恢复 / 说"R{n} 做完就停"暂停 / 回来看 `~/.<项目>-loop/morning.md` 验收

## 适用边界 / When to use

- ✅ 适合：有可判定验收手段的长期项目；无人值守时段（过夜/周末）；多支线并行的打磨维护期
- ⚠️ 不适合：一次性问答；完全没有客观验收手段且不愿先造验收命令的项目——那循环必然漂移，验收命令是地基不是可选项

## 安全须知 / Safety (必读)

- **红线清单是硬前提**：部署生产、删数据、push 远端、花钱>阈值……初始化时写进 protocol，agent 一律"记录待拍板"而非执行
- **成本控制**：子代理消耗 LLM 额度；给耗 API 的项目在协议里写"每环节测试调用上限"（实战用 mock E2E 做到零额度验证协议）
- **验收命令是地基**：没有客观验收命令的循环会漂——宁可第一轮不写功能先造测试
- **渐进信任**：新项目建议先跑 1-2 轮观察任务书与收官质量，再放手无人值守
- 完整事故经验库见 `references/lessons.md`（24 条真实教训）

## 实战经验节选 / Lessons

`references/lessons.md` 只收经完整轮次实战验证的教训，三条样例：

- **自证硬门 > 口头声称**：agent 自称"已过/形态关"不可信，每类工作长出自动化检查脚本，收官必须附自检数据
- **收官判定只信地面真值**：git + backlog 账本 + 任务状态三方一致才算收官；"任务查无+零产出"≠已死，按存活疑犯处置
- **spawn 后必验活**：30 分钟内 commit/产物/任务输出三选一，否则视为静默失败重派

## 移植到其他 agent 宿主 / Porting

本技能按 ZCode 能力编写（后台子代理 / 定时任务 / 会话间读取）；核心流程宿主无关。映射表与文件协议降级方案见 `references/porting.md`（Claude Code / Codex / 通用 crontab 方案）。

## 结构 / Layout

```
SKILL.md                    总纲(触发+循环+纪律)
scripts/init.sh             一键初始化运行目录
scripts/patrol-scan.sh      巡逻证据采集(git/孤儿进程/环境守卫/state)
templates/                  protocol/state/leadbook/goal-prompt 四模板
references/lessons.md       24 条实战经验(25 轮验证)
references/porting.md       宿主移植表
example/                    一个填好的 mini protocol 示例
```

## FAQ

**Q: 中途能插手吗？** 能。直接说，负责人即时下发在跑 agent 并记入反馈池，不阻塞循环。

**Q: 成本怎么控制？** 子代理消耗 LLM 额度：协议里写"每环节测试调用上限"；mock E2E（生产代码+本机 mock 服务）可零额度验证协议正确性（lessons #24）。

**Q: 和"一个超长 prompt 让它自己跑"有何不同？** 后者没有外部节奏、地面真值与失败保护，典型结局是目标漂移和静默失败。本技能的巡逻班次、三方一致收官判定、spawn 验活重派就是针对这两类失败模式。

**Q: 支持哪些宿主？** 默认 ZCode；Claude Code / Codex / 通用 CLI agent 的等价映射与降级方案见 `references/porting.md`。

## License

MIT
