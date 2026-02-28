# ADR-0004: 组件库插件化分发与 Demo 验收基线

## Status

Accepted

## Context

组件库已采用“统一依赖 + 品类包”模式，但仍有两个落地问题：

- 外部项目接入时，编辑器内缺少统一创建入口；
- 新增品类时容易只加脚本，不加可运行演示，导致可验证性不足。

仓库目标是“复制即用 + 可分享”，因此需要在不增加运行时耦合的前提下，补齐分发与验收约束。

## Decision Drivers

- 保持运行时架构简洁，不再引入额外包装层
- 让组件在编辑器和文件复制两种路径都可快速接入
- 保证每个品类新增后可直接演示、可快速验收

## Considered Options

### Option 1: 仅保留文件复制，不提供插件

- Pros: 结构最简单
- Cons: 编辑器可发现性差，新用户上手慢

### Option 2: 仅提供插件，不强调目录可复制

- Pros: 编辑器体验较好
- Cons: 与“组件仓库可搬运”目标冲突，跨项目迁移成本更高

### Option 3: 复制优先 + 插件可选 + Demo 基线（本次采用）

- Pros: 同时满足可搬运性与可发现性；验收标准清晰
- Cons: 需要维护 demo 和插件注册表

## Decision

采用 **Option 3**：

1. 运行时仍以 `ComponentLibrary/Dependencies` + `ComponentLibrary/Packs` 为主；
2. 新增可选插件 `addons/component_library_share`，只负责 Custom Type 注册，不接管运行时；
3. 建立 Demo 验收基线：每个 `Packs/<Genre>/` 必须同时提供：
   - `Components/*.gd`
   - `Templates/*.tscn`
   - `Demos/<Genre>/*_demo.tscn` + `*_demo.gd`
   - `README.md`
4. 统一入口 `ComponentLibrary/Demos/demo_hub.tscn` 用于快速浏览全部演示。

## Consequences

### Positive

- 组件可通过“复制目录”或“启用插件”两种方式接入
- 新品类具备最低可运行验证，减少无演示代码堆积
- 架构保持三层清晰：全局依赖、品类组件、可选插件

### Negative

- 新增组件时需要同步补 demo，工作量上升
- 插件注册列表需要随组件演进维护

### Risks

- 若维护不及时，插件注册与实际脚本可能漂移
- Demo 可能覆盖不足真实业务边界

## Implementation Notes

- 新增 `addons/component_library_share/plugin.gd` 与 `plugin.cfg`
- 扩展品类：`Platformer`、`Racing`、`Builder`
- 补齐 `ComponentLibrary/Demos`（含 10 个品类 demo + hub）

## Related Decisions

- ADR-0002: 全局时间与局部时间域模型
- ADR-0003: 去除多余适配层并引入可复制组件包规范
