# 组件库结构与使用说明（中文）

## 目标

本仓库定位为“可复制复用”的组件库，不绑定单一游戏项目。

核心原则：

- 全局能力只保留一套，不做并行封装。
- 组件尽量自包含，依赖统一收敛。
- 每个组件包可按目录复制到新项目直接使用。

## 三层架构

### 1) Global Services（全局服务层）

放在 `Core/` 与 `Systems/`，作为唯一事实来源：

- 事件总线：`Core/event_bus.gd`（Autoload: `EventBus`）
- 对象池：`Core/object_pool.gd`（Autoload: `ObjectPool`）
- 全局时间：`Systems/Time/TimeController.gd`（Autoload: `TimeController`）
- 局部时间域：`Systems/Time/local_time_domain.gd`

### 2) Modules（通用能力层）

放在 `Modules/`，按玩法域拆分：

- `Foundation`：基础逻辑（冷却、标签、黑板、调度等）
- `Gameplay/Common`：受击、交互、资源、机关等
- `Gameplay/Platformer`：平台跳跃相关
- `Gameplay/Time`：时间玩法相关
- `UI/Common`、`VFX/Common`：通用表现层

说明：该层不再重复实现全局事件总线与对象池。

### 3) ComponentLibrary（可复制组件包）

放在 `ComponentLibrary/`：

- `Dependencies/`：复制时需要的统一依赖
- `Packs/<Genre>/`：按游戏品类组织的组件包

## 依赖规则

- 若组件需要全局服务，直接使用 `EventBus` / `ObjectPool` / `TimeController`。
- 若组件需要局部时间，显式实现：
  - `_local_time_process(delta)`
  - `_local_time_physics_process(delta)`
  并挂在 `LocalTimeDomain` 子树下。

## 当前重点组件（Modules）

### Foundation

- `CooldownComponent`
- `LifetimeComponent`
- `StateFlagComponent`
- `ConditionGateComponent`
- `TagComponent`
- `DataBlackboardComponent`
- `TickSchedulerComponent`（已支持接入 `LocalTimeDomain`）

### Gameplay/Common

- `ResourcePoolComponent`
- `InvincibilityComponent`
- `ActionGateComponent`
- `DamageReceiverComponent`
- `InteractableComponent`
- `PeriodicSpawnerComponent`
- `CheckpointMemoryComponent`
- `KnockbackReceiverComponent`
- `TelegraphComponent`
- `TimedDoorComponent`
- `StateStackComponent`
- `TriggerRouterComponent`

### UI/Common / VFX/Common

- `UIPageStateComponent`
- `ImpactVFXComponent`（直接接入全局 `ObjectPool`）

## ADR 关联

- `Docs/adr/0002-global-and-local-time-flow.md`
- `Docs/adr/0003-portable-component-pack-and-dependency-hub.md`
