# example/protocol.example.md —— 一个 Web 项目的填充示例（展示 {FILL} 如何落地）

> 场景：单体 Next.js SaaS，用户目标"把测试覆盖率提上去并修掉积压 bug，我只管验收"。

## {FILL} 落地示例

- 验收命令：`npm test -- --coverage`（覆盖率 ≥70% 且全绿）＋ `npm run build` 零错误
- 红线：不部署生产 / 不 push / 不改 schema 迁移文件 / 不动 .env*
- 独占资源（主线串行依据）：无共享设备——主线=主分支工作树本身（避免两个 agent 同时改同一工作树），部署演练一律支线后手动
- 环境守卫：无（纯软件项目典型情况；涉及外设/系统状态/共享资源的项目才会有守卫项）
- 方向池：测试线（覆盖率）→ bug 积压（按 severity）→ 重构线（契约测试先行）
- 并行工作绕开：`src/legacy/**` 用户在手工重构中，任何轮次不碰

## 巡逻 cron prompt（填充后节选）

"…7) 红线：不部署生产/不 push/不改迁移/不动 .env；结束仓库干净（npm test 全绿为证）…"

## 首轮主题示例（前提补齐）

/goal 目标（第 1 轮，主题「验收地基」）：项目无可判定验收门——先把 `npm test` 修到全绿可用（当前 3 个失败），加 coverage 报告，selftest 断言脚本入库。验收：npm test 全绿 + coverage 输出 + 断言脚本 commit。
