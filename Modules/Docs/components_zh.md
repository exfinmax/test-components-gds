# 组件分层与清单（中文）

本文档对应 `Modules/` 的分层设计，核心目标是把“跨项目可复用能力”和“特定玩法能力”拆开，避免组件仓越长越臃肿。

## 分层原则

- `Foundation`：项目无关、玩法无关的基础能力。只处理通用技术问题，不带具体游戏语义。
- `UI/Common` 与 `VFX/Common`：跨品类可复用的表现层组件，负责反馈与展示，不直接承载关卡规则。
- `Gameplay/Common`：通用玩法语义（受伤、交互、资源池、机关门控等），适用于多数动作/解谜项目。
- `Gameplay/Platformer`：平台跳跃强相关组件。
- `Gameplay/Time`：时间能力强相关组件。

这套分层把“核心组件”和“特化组件”隔离开：
- 先在 `Foundation + UI/VFX/Common + Gameplay/Common` 建稳定底座。
- 再按项目类型引入 `Platformer` 或 `Time`。

## 当前组件清单

### Foundation

- `CooldownComponent`：标签化冷却计时。
- `LifetimeComponent`：对象生命周期与自动回收。
- `StateFlagComponent`：轻量状态位管理。
- `ConditionGateComponent`：状态条件门。
- `TagComponent`：标签查询与筛选。
- `ObjectPoolComponent`：通用对象池，减少频繁实例化。
- `EventChannelComponent`：轻量事件通道，解耦模块依赖。

### UI/Common

- `UIPageStateComponent`：统一页面状态切换（主菜单/暂停/背包等）。

### VFX/Common

- `ImpactVFXComponent`：命中特效统一入口，支持对象池。

### Gameplay/Common

- `ResourcePoolComponent`：生命/能量等资源池。
- `InvincibilityComponent`：无敌窗口。
- `ActionGateComponent`：资源 + 冷却门控。
- `DamageReceiverComponent`：统一受击入口。
- `InteractableComponent`：标准化交互对象。
- `PeriodicSpawnerComponent`：周期生成。
- `CheckpointMemoryComponent`：检查点数据恢复。
- `KnockbackReceiverComponent`：击退处理。
- `TelegraphComponent`：预警后触发。
- `TimedDoorComponent`：持续激活开门逻辑。

### Gameplay/Platformer

- `AirJumpComponent`：空中跳。
- `FallDamageComponent`：落地伤害。
- `OneWayDropComponent`：单向平台下落。
- `PlatformAttachComponent`：移动平台附着。

### Gameplay/Time

- `TimeEnergyComponent`：时间能量池。
- `TimeAbilityComponent`：时间能力调度。
- `TimelineSwitchComponent`：时间线开关。
- `TimeFragmentPickupComponent`：时间碎片拾取。
- `RewindEchoBridgeComponent`：回溯与回声桥接。
- `EchoTriggerPlateComponent`：回声触发压板。

## 接入顺序建议

1. 先接 `Foundation` 与 `UI/VFX/Common`。
2. 再接 `Gameplay/Common`。
3. 项目是平台跳跃时再引入 `Gameplay/Platformer`。
4. 项目有时间能力时再引入 `Gameplay/Time`。

## 本轮新增（核心/通用补强）

### Foundation
- `DataBlackboardComponent`
  - 文件：`Modules/Foundation/Components/data_blackboard_component.gd`
  - 作用：提供跨组件共享上下文，降低硬引用。
- `TickSchedulerComponent`
  - 文件：`Modules/Foundation/Components/tick_scheduler_component.gd`
  - 作用：任务分频调度，减少全局逐帧负载。

### Gameplay/Common
- `StateStackComponent`
  - 文件：`Modules/Gameplay/Common/Components/state_stack_component.gd`
  - 作用：可嵌套状态流管理（交互/过场/暂停等）。
- `TriggerRouterComponent`
  - 文件：`Modules/Gameplay/Common/Components/trigger_router_component.gd`
  - 作用：统一触发事件路由，减少场景连线复杂度。
