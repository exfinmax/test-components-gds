# Platformer Pack

## 组件

- `CoyoteJumpComponent`
- `AirJumpComponent`
- `FallDamageComponent`
- `OneWayDropComponent`
- `PlatformAttachComponent`

## 依赖

- `AirJump/FallDamage/OneWayDrop/PlatformAttach` 需要 `CharacterComponentBase`
- 可选接入 `LocalTimeDomain`（实现 `_local_time_process`）

## 使用

- 在角色离地时调用 `notify_grounded(false)`
- 在角色接地时调用 `notify_grounded(true)`
- 输入跳跃时调用 `queue_jump()` + `consume_jump()`
