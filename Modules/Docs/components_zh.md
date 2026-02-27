# 组件分层与组件清单（中文）

本文档对应 `Modules/` 新架构，目标是把“可跨项目复用能力”和“时间横版解谜特化能力”分层。

## 一、分层理由

### Foundation（基础层）
- 放置跨项目都用得上的基础能力。
- 不绑定具体玩法语义。
- 例如：冷却、生命周期、状态标记、条件门。

### Gameplay/Common（通用玩法层）
- 放置大多数游戏都可能用到的玩法组件。
- 有玩法语义，但不依赖“平台跳跃/时间能力”等特定类型。
- 例如：资源池、无敌、受击、交互、预警触发。

### Gameplay/Platformer（平台特化层）
- 强依赖横版/平台跳跃角色控制语义。
- 例如：空中跳、跌落伤害、单向平台下落、移动平台附着。

### Gameplay/Time（时间特化层）
- 专门服务时间能力与时间谜题玩法。
- 例如：时间能量、时间能力调度、时间线开关、时间碎片拾取。

---

## 二、组件清单

## 1) Foundation
- `CooldownComponent`
  - 文件：`Modules/Foundation/Components/cooldown_component.gd`
  - 作用：按标签管理冷却。
- `LifetimeComponent`
  - 文件：`Modules/Foundation/Components/lifetime_component.gd`
  - 作用：对象生命周期控制。
- `StateFlagComponent`
  - 文件：`Modules/Foundation/Components/state_flag_component.gd`
  - 作用：统一状态位管理。
- `ConditionGateComponent`
  - 文件：`Modules/Foundation/Components/condition_gate_component.gd`
  - 作用：按状态位组合判断门禁。

## 2) Gameplay/Common
- `ResourcePoolComponent`
  - 文件：`Modules/Gameplay/Common/Components/resource_pool_component.gd`
  - 作用：体力/法力/能量等通用资源模型。
- `InvincibilityComponent`
  - 文件：`Modules/Gameplay/Common/Components/invincibility_component.gd`
  - 作用：无敌窗口管理。
- `ActionGateComponent`
  - 文件：`Modules/Gameplay/Common/Components/action_gate_component.gd`
  - 作用：资源消耗 + 冷却门控。
- `DamageReceiverComponent`
  - 文件：`Modules/Gameplay/Common/Components/damage_receiver_component.gd`
  - 作用：统一受伤入口。
- `InteractableComponent`
  - 文件：`Modules/Gameplay/Common/Components/interactable_component.gd`
  - 作用：可交互对象标准化。
- `PeriodicSpawnerComponent`
  - 文件：`Modules/Gameplay/Common/Components/periodic_spawner_component.gd`
  - 作用：周期生成对象。
- `CheckpointMemoryComponent`
  - 文件：`Modules/Gameplay/Common/Components/checkpoint_memory_component.gd`
  - 作用：记录/恢复检查点状态。
- `KnockbackReceiverComponent`
  - 文件：`Modules/Gameplay/Common/Components/knockback_receiver_component.gd`
  - 作用：统一击退注入与衰减。
- `TelegraphComponent`
  - 文件：`Modules/Gameplay/Common/Components/telegraph_component.gd`
  - 作用：机关预警 -> 延迟触发。

## 3) Gameplay/Platformer
- `AirJumpComponent`
  - 文件：`Modules/Gameplay/Platformer/Components/air_jump_component.gd`
  - 作用：双跳/多段跳。
- `FallDamageComponent`
  - 文件：`Modules/Gameplay/Platformer/Components/fall_damage_component.gd`
  - 作用：按下落速度结算落地伤害。
- `OneWayDropComponent`
  - 文件：`Modules/Gameplay/Platformer/Components/one_way_drop_component.gd`
  - 作用：单向平台下落穿透。
- `PlatformAttachComponent`
  - 文件：`Modules/Gameplay/Platformer/Components/platform_attach_component.gd`
  - 作用：站立移动平台时继承平台位移。

## 4) Gameplay/Time
- `TimeEnergyComponent`
  - 文件：`Modules/Gameplay/Time/Components/time_energy_component.gd`
  - 作用：时间能力能量池。
- `TimeAbilityComponent`
  - 文件：`Modules/Gameplay/Time/Components/time_ability_component.gd`
  - 作用：时缓/时间冲刺能力触发流程。
- `TimelineSwitchComponent`
  - 文件：`Modules/Gameplay/Time/Components/timeline_switch_component.gd`
  - 作用：时间状态驱动机关开关。
- `TimeFragmentPickupComponent`
  - 文件：`Modules/Gameplay/Time/Components/time_fragment_pickup_component.gd`
  - 作用：拾取恢复时间能量。

---

## 三、你这个项目的推荐接入顺序

1. 先接入 Foundation：`Cooldown`、`StateFlag`、`ConditionGate`。
2. 再接入 Common：`ActionGate`、`DamageReceiver`、`ResourcePool`。
3. 平台玩法补齐：`AirJump`、`FallDamage`、`OneWayDrop`、`PlatformAttach`。
4. 最后接时间玩法：`TimeEnergy`、`TimeAbility`、`TimelineSwitch`、`TimeFragmentPickup`。

---

## 四、与 `time-runner` 的对齐方向

参考了你 `D:\Hopes_and_Dream\Godotprojects\time-runner` 的 C# 组件方向，已先在 GDS 侧补齐：
- 时间资源与能力拆分（Energy + Ability）
- 平台玩法增强（空中跳、落伤、单向下落、平台附着）
- 机关逻辑增强（预警、交互、状态门）

下一步可做“接口对齐版”：按你 C# 新版的字段和信号，生成一套同名 GDS/C# 双实现模板。

## 5) 本轮新增（机关向）

- `EchoTriggerPlateComponent`
  - 文件：`Modules/Gameplay/Time/Components/echo_trigger_plate_component.gd`
  - 作用：回声/玩家可选触发压板，输出激活状态。

- `TimedDoorComponent`
  - 文件：`Modules/Gameplay/Common/Components/timed_door_component.gd`
  - 作用：输入持续激活达到阈值后开门，可自动关闭。
