# Architecture Decision Records

本目录用于记录本项目的重要架构决策，避免后续重构时反复争论同一问题。

## 状态说明

- `Proposed`：提案中
- `Accepted`：已采纳并执行
- `Deprecated`：已过时
- `Superseded`：被新 ADR 替代
- `Rejected`：已否决

## 索引

| ADR | 标题 | 状态 | 日期 |
|---|---|---|---|
| [0001](0001-global-services-boundary.md) | 全局服务边界与单一事实来源 | Superseded | 2026-02-28 |
| [0002](0002-global-and-local-time-flow.md) | 全局时间与局部时间域模型 | Accepted | 2026-02-28 |
| [0003](0003-portable-component-pack-and-dependency-hub.md) | 去除多余适配层并引入可复制组件包规范 | Accepted | 2026-02-28 |
| [0004](0004-plugin-distribution-and-demo-baseline.md) | 组件库插件化分发与 Demo 验收基线 | Accepted | 2026-02-28 |
| [0005](0005-consolidate-modules-into-component-library.md) | 合并 Modules 到 ComponentLibrary 并执行移动式去重 | Accepted | 2026-02-28 |
