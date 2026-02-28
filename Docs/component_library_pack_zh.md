# 通用组件库打包说明（中文）

## 定位

本仓库作为组件仓库使用，目标是：

- 可按目录复制到其他项目
- 依赖集中、路径清晰
- 不绑定单一玩法

## 推荐复制顺序

1. 复制 `ComponentLibrary/Dependencies/`
2. 复制目标品类包 `ComponentLibrary/Packs/<Genre>/`
3. 在目标项目注册需要的 Autoload：
   - `EventBus`
   - `ObjectPool`
   - `TimeController`

## 目录结构

```text
ComponentLibrary/
  Dependencies/
    event_bus.gd
    object_pool.gd
    time_controller.gd
    local_time_domain.gd
  Packs/
    Shooter/
    RPG/
    Strategy/
    Survival/
    Card/
```

## 当前组件包

- Shooter: `ProjectileEmitterComponent`
- RPG: `AttributeSetComponent`
- Strategy: `ProductionQueueComponent`
- Survival: `StatusEffectComponent`
- Card: `DeckDrawComponent`

## 架构约束

- 全局服务只保留一套，不做局部重复实现。
- 组件优先信号通信；强耦合对象可直接引用。
- 需要局部时间时使用 `LocalTimeDomain` 显式适配。
