# 组件库架构说明（中文）

## 目标

本仓库定位为“复制即用”的通用组件库：

- 不保留重复实现
- 分类清晰、可按包迁移
- 每个包至少有模板和 Demo 可验证

## 当前分层

### 1) Global Services（项目级单例）

位于 `Core/` 与 `Systems/`：

- `EventBus`
- `ObjectPool`
- `TimeController`
- `LocalTimeDomain`

### 2) ComponentLibrary/Dependencies（可复制依赖）

位于 `ComponentLibrary/Dependencies/`：

- `event_bus.gd`
- `object_pool.gd`
- `time_controller.gd`
- `local_time_domain.gd`
- `component_base.gd`
- `character_component_base.gd`

### 3) ComponentLibrary/Packs（分类组件包）

按功能与品类划分：

- 基础与系统：`Foundation` / `Action` / `Platformer` / `Time` / `UI` / `VFX`
- 品类扩展：`Shooter` / `RPG` / `Strategy` / `Survival` / `Card` / `Puzzle` / `Roguelike` / `Racing` / `Builder`

### 4) ComponentLibrary/Demos（最小演示）

每个包都有最小可运行演示场景，可直接运行验证行为日志。

## 关键规则

- 不在多个目录重复放同一组件；优先移动原组件并统一归档。
- 组件跨包通信优先信号；强耦合对象允许直接引用。
- 若需要局部时间，组件实现 `_local_time_process` / `_local_time_physics_process` 并挂在 `LocalTimeDomain` 子树。
- 每个 Pack 至少包含：
  - `Components/*.gd`
  - `Templates/*.tscn`
  - `README.md`
  - 对应 `Demos/<Pack>/*_demo.tscn`

## ADR 关联

- `Docs/adr/0002-global-and-local-time-flow.md`
- `Docs/adr/0003-portable-component-pack-and-dependency-hub.md`
- `Docs/adr/0004-plugin-distribution-and-demo-baseline.md`
