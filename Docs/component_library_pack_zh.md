# 通用组件库打包说明（中文）

## 定位

本仓库作为组件仓库使用，目标是：

- 可按目录复制到其他项目
- 依赖集中、路径清晰
- 不绑定单一玩法

## 推荐复制顺序

1. 复制 `ComponentLibrary/Dependencies/`
2. 复制目标品类包 `ComponentLibrary/Packs/<Genre>/`
3. 可选复制 `ComponentLibrary/Demos/` 用于验证行为
4. 在目标项目注册需要的 Autoload：
   - `EventBus`
   - `ObjectPool`
   - `TimeController`
5. 可选启用 `addons/component_library_share` 插件，获得编辑器 Custom Type 快速创建入口

## 目录结构

```text
project_root/
  ComponentLibrary/
	Dependencies/
	  event_bus.gd
	  object_pool.gd
	  time_controller.gd
	  local_time_domain.gd
	Packs/
	  Foundation/
	  Action/
	  Platformer/
	  Time/
	  UI/
	  VFX/
	  Shooter/
	  RPG/
	  Strategy/
	  Survival/
	  Card/
	  Puzzle/
	  Roguelike/
	  Racing/
	  Builder/
	Demos/
  addons/
	component_library_share/
```

## 当前组件包

- Foundation: `CooldownComponent` 等基础组件
- Action: `DamageReceiverComponent` 等通用玩法组件
- Time: `TimeAbilityComponent` 等时间玩法组件
- UI: `UIPageStateComponent`
- VFX: `ImpactVFXComponent`
- Shooter: `ProjectileEmitterComponent`
- RPG: `AttributeSetComponent`
- Strategy: `ProductionQueueComponent`
- Survival: `StatusEffectComponent`
- Card: `DeckDrawComponent`
- Puzzle: `SequenceSwitchComponent`
- Roguelike: `WeightedSpawnTableComponent`
- Platformer: `CoyoteJumpComponent`
- Racing: `LapCheckpointComponent`
- Builder: `GridPlacementComponent`

## 架构约束

- 全局服务只保留一套，不做局部重复实现。
- 组件优先信号通信；强耦合对象可直接引用。
- 需要局部时间时使用 `LocalTimeDomain` 显式适配。
- 每个品类包必须提供模板和最小可运行 Demo。
