# Survival Pack

## 组件

- `StatusEffectComponent`

## 依赖

- 无硬依赖
- 可选接入 `LocalTimeDomain`（实现 `_local_time_process`）

## 使用

- 添加状态：`add_effect("poison", 5.0, {"damage_per_tick": 2}, 1.0)`
- 每次 tick 监听 `effect_ticked` 执行真实伤害/回复
