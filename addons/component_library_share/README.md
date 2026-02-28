# component_library_share 插件

## 目的

把 `ComponentLibrary` 的常用脚本注册为 Godot Custom Type，方便在编辑器里快速创建节点。

## 特性

- 不接管运行时逻辑
- 仅提供编辑器创建入口
- 兼容“复制脚本/场景直接用”的仓库目标

## 启用

1. 确保项目内存在 `ComponentLibrary/` 目录。
2. 在 Godot `Project -> Project Settings -> Plugins` 启用 `ComponentLibraryShare`。
3. 在新建节点列表中搜索组件名即可创建。

## 已注册类型

- `GlobalEventBus`
- `GlobalObjectPool`
- `GlobalTimeController`
- `LocalTimeDomainDependency`
- `ProjectileEmitterComponent`
- `CooldownComponent`
- `TriggerRouterComponent`
- `TimelineSwitchComponent`
- `UIPageStateComponent`
- `ImpactVFXComponent`
- `AttributeSetComponent`
- `ProductionQueueComponent`
- `StatusEffectComponent`
- `DeckDrawComponent`
- `SequenceSwitchComponent`
- `WeightedSpawnTableComponent`
- `CoyoteJumpComponent`
- `LapCheckpointComponent`
- `GridPlacementComponent`
