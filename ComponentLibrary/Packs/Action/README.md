# Action Pack

## 组件

- `ActionGateComponent`
- `CheckpointMemoryComponent`
- `DamageReceiverComponent`
- `InteractableComponent`
- `InvincibilityComponent`
- `KnockbackReceiverComponent`
- `PeriodicSpawnerComponent`
- `ResourcePoolComponent`
- `StateStackComponent`
- `TelegraphComponent`
- `TimedDoorComponent`
- `TriggerRouterComponent`

## 依赖

- 需要 `ComponentBase`，其中角色相关组件还需要 `CharacterComponentBase`
- 部分组件可选使用全局 `EventBus` / `ObjectPool`

## 使用

- 适合动作/ARPG/横版等实时玩法的交互与战斗流程。
