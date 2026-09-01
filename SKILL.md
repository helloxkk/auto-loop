---
name: auto-loop
description: Autonomous dev-loop: the user only states requirements and does acceptance; an AI foreman runs everything else — dispatching subagents for dev/test, cron patrol, chaining, failure recovery, retrospectives. Use whenever the user says "自动迭代/持续开发/无人值守/闭环开发/我只管验收/自动跑下去/接着迭代不用问我/自动驾驶" or English "autonomous loop / self-iterating development / unattended development / I only do acceptance / keep iterating without me / auto-pilot this project" or asks for subagent-driven dev+test closed loop that keeps running overnight. Works for any project (code, embedded, web, CLI).
---

# auto-loop · 自动闭环迭代开发

用户当老板只做两件事：**提需求、验收**。你（当前会话的 agent）当负责人，管理轮次 agent 子代理完成开发-测试-巡逻-接续的自动循环。本 skill 在真实项目上验证过 25 轮/2 天的连续自主迭代。

## 一、适用前提（开工前逐项确认，缺了先补）

1. **可判定的验收命令**：项目必须有一条命令能客观判定"本轮改完没坏"（如 `make test` / `make selftest` / `npm test`）。没有就先让第一轮 agent 造一个——这是整个循环的地基。
2. **backlog 真源文件**：一个记录需求/状态/欠债的文件（如 `docs/TODO.md`），轮次 agent 与负责人共读写。
3. **红线清单**：不可越权的事项（部署生产/删数据/push 远端/重启独占资源/花费超阈值等），写进协议，agent 一律"记录待拍板"而不是执行。
4. **环境守卫项**（可选）：需要在轮次间保持恒定的外部状态（如外设状态/服务运行态/资源单例锁），初始化时问用户一次写死。

## 二、初始化（首次调用时执行一次）

运行 `scripts/init.sh <项目名> [仓库绝对路径]`——自动在**项目外**建运行目录 `~/.<项目名>-loop/`（放项目外避免污染 git status，每轮 agent 开局要求 git 干净）：

```
~/.<项目名>-loop/
├── protocol.md    # 从 protocol.tpl.md 复制，填入：验收命令/红线/环境守卫/主题决策规则
├── state.md       # 从 state.tpl.md 复制，round/kind/task_id/theme/status
├── leadbook.md    # 从 leadbook.tpl.md 复制（负责人复盘手册，每 3 轮更新）
└── log.md         # 巡逻流水（一行一事）
```

再建巡逻定时任务：`CronCreate` 每 30 分钟一班（cron `*/30 * * * *`，intervalUnit=minute, interval=30），prompt 要点：读 protocol+state → 判定当前轮收官（见下）→ 未收官记一行日志结束 / 已收官做接续 → 失败保护 → 红线。prompt 全文参考 `templates/protocol.tpl.md` 末尾。

## 三、核心循环（负责人职责）

### 派轮
1. 定主题：`pending_feedback(用户反馈) > pm_proposals(负责人自提池) > 上一轮记录的候选 > 未竟大项 > 默认稳定轮`。
2. 用 `templates/goal-prompt.tpl.md` 骨架写任务书：一句话目标 + 开局自检 + 功能目标(F1..Fn 含验收标准) + 退出条件 + 硬约束。**每项验收必须可判定**（命令/像素/日志锚点），禁"优化一下"这类模糊任务。
3. `Agent(subagent_type=general-purpose, run_in_background=true)` 启动，把 task_id 写回 state.md。
4. **spawn 验活**：30 分钟内确认 commit/产物/TaskOutput 三选一，否则视为静默失败重派（一次），再失败停链记录——不要相信"启动成功"回执。

### 巡逻（每班次）
1. 先跑 `scripts/patrol-scan.sh <仓库> <loop目录>`（ORPHAN_PAT/GUARD_CMD 环境变量按协议配置）——一份命令拿到 git 快照/孤儿进程/环境守卫/state 字段的全部证据，再基于它做判断。
2. **收官判定从严**：只信 git log + backlog 账本 + TaskOutput 三方一致的地面真值；"任务查无+零产出"只能判"疑似死"（注册表假阴性实录存在），30 分钟无产出按存活疑犯处置。
3. 未收官 → log.md 记一行"时间|轮次|简记"结束，**不做其他动作**（干预是例外不是常规）。
4. agent 完成通知到达 → 立即接续（不等下个整点）。
5. 环境守卫执行（守卫值核对、孤儿进程清查：agent 异常死亡时其长任务子进程可能残留抢资源）。
6. 用户中途反馈 → 即时 SendMessage 下发该轮 agent（含根因方向），同时记入 state.md pending_feedback 防丢。

### 收官接续
1. 提取经验入 state.md history；晨报（morning.md）追加摘要——用户回来只看这一个文件。
2. 需用户拍板的事项累积到 backlog"用户在场"节，**不阻塞循环**。
3. 立即派下一轮（或按用户指令暂停/等待设备）。

### 分工铁律
- **轮次 agent**：实现 + 客观验证（测试/像素/日志）+ 增量 commit + 立册 backlog。
- **负责人（你）**：派发/巡逻/主观判定（视觉审美/产品决策）/产品提案（pm_proposals 池，每轮收官后增补——需求思考是负责人的本职，不许全部依赖用户报障）/复盘。
- **用户**：需求 + 验收 + 拍板节。视觉类验收若项目有 vision 子代理则负责人调用后把结论下发（agent 自称"通过/过形态关"不可信，两轮实战证伪）。

## 四、治理纪律（违反=返工或事故，完整版见 references/lessons.md）

1. **自证硬门 > 口头声称**：每类工作长出自动化检查脚本（自检清单模式：一张可执行检查表跑出 PASS/FAIL），agent 收官必须附自检数据。
2. **欠债显式结转**：退出条件未满足就收官的项写进 backlog 顶部，下轮第 0 项还清；"本轮无需沉淀"是合法答案。
3. **PM 自审**：每轮收官报告必须含"产品视角找茬 ≥3 条"，防做完功能就走。
4. **事故固化**：每次事故（挂死/误判/抢资源）后立即把对策写进 protocol 骨架——模板是事故的结晶，不靠记忆。
5. **独占资源守恒**（设备/共享环境/生产/工作树皆适用）：长任务启动前查残留实例+登记 pid+重启必杀旧；agent 异常终结时巡逻清孤儿。
6. **命令带硬超时**：远程命令/长轮询一律超时保护；证据取不到降级日志级并注明，禁无限重试。
7. **主线串行支线并行**：碰独占资源（设备/生产环境）的轮严格串行；纯本地 Mac/写码类可开支线并行（spawn 时声明不相交文件域，commit 冲突主线优先）。
8. **大轮预拆**：F 项 >6 或先例 >90min 的拆两段派发；时间盒轮（用户给窗口时）到点增量 commit+显式结转，不为赶工跳过验证。
9. **离线先行**：目标设备/环境不可达时代码+构建+mock E2E 先行，真机验收显式结转成清单（含顺序敏感步骤）。

## 五、用户接口（告诉用户的用法）

- 启动："用 auto-loop 跑 XX 需求" / 日常："继续" / 暂停："R{n} 做完就停"（巡逻在收官处置后 CronDelete 自毁，说"继续"时重建）。
- 随时插反馈：直接说，负责人即时下发不阻塞。
- 睡眠/离开：告知即可（负责人切换值守模式：零提问、需拍板事项全记账、有环境守卫则执行之）。
- 验收：看 `~/.<项目名>-loop/morning.md` 或直接问负责人要战报。

## 六、何时读哪个文件

- 首次初始化 → `templates/` 全读
- 派轮写任务书 → `templates/goal-prompt.tpl.md`
- 每轮收官后 → 自己增补 pm_proposals；每 3 轮更新 leadbook.md（读 `references/lessons.md` 对齐已验证经验，避免重复踩坑）
- 遇到事故/异常判定 → 读 `references/lessons.md` 找同类先例
