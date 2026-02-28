# Shooter Pack

## 组件

- `ProjectileEmitterComponent`

## 依赖

- 无硬依赖
- 可选全局依赖：`ObjectPool`（若存在可复用子弹实例）

## 使用

1. 挂载 `projectile_emitter_component.gd` 到任意 `Node2D`
2. 配置 `projectile_scene`
3. 调用 `fire(direction)` 触发发射
