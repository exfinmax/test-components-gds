# test-components 项目

## 项目定位

Godot 4.6 可复用组件库（GDScript + C# 双版本）

每个文件夹都是一个**独立组件**，复制到任何项目即可使用，无需修改即可单独测试。
目标游戏类型：时间操控横板跑酷。

> 文档来源自 `CONTEXT.md`，已于 2026-03-03 更新为 README。

## 设计原则

1. **单一职责** — 每个组件只做一件事
2. **独立可测** — 组件挂到最小场景（如空的 CharacterBody2D）即可运行，不依赖外部
3. **信号驱动** — 组件之间通过信号通信，避免直接引用
4. **自省能力** — 每个组件都有 `get_component_data() -> Dictionary`，返回当前状态的键值对
5. **零配置可用** — 组件有合理的默认值，拖入场景即工作
6. **双语版本** — 核心组件同时提供 GDScript 和 C# 实现

## 目录结构（截选）

```
test-components/
│
├── Core/                       ⭐ 框架基础
│   ├── component_base.gd      # ComponentBase（enabled, find_sibling, get_component_data）
│   ├── event_bus.gd           # EventBus 全局事件总线（Autoload）
│   ├── state_coordinator.gd   # StateCoordinator 状态协调器
│   ├── StateCoordinatorCS.cs  # C# 版
│   ├── object_pool.gd        # ObjectPool 对象池
│   └── ObjectPoolCS.cs        # C# 版
│
├── CharacterComponents/        ⭐ 角色能力组件系统（组合式）
│   ├── Components/
│   │   ├── character_component_base.gd  # CharacterComponentBase → extends ComponentBase
│   │   ├── input_component.gd      # 输入抽象（玩家/AI/回放）
│   │   ├── gravity_component.gd    # 重力（正常/低/无重力）
│   │   ├── move_component.gd       # 水平移动（加速度、速度倍率）
│   │   ├── jump_component.gd       # 跳跃（可变高度、土狼时间、预输入）
│   │   ├── dash_component.gd       # 冲刺（方向、次数、冷却）
│   │   ├── wall_climb_component.gd # 滑墙 + 蹬墙跳
│   │   ├── animation_component.gd  # 动画管理（优先级系统）
│   │   └── animation_config.gd     # 动画名映射资源
│   └── Character/
│       ├── character.gd            # 角色基类（统一驱动、朝向管理）
│       ├── Player/                 # 组件版玩家
│       └── ReplayEnemy/            # 组件版敌人（录制回放）
│
├── Combat/                     ⭐ 战斗/生存组件
│   ├── health_component.gd     # 生命值（扣血/治疗/死亡/飘字）
│   ├── hitbox_component.gd     # 攻击箱
│   ├── hurtbox_component.gd    # 受击箱
│   ├── attack_component.gd     # 攻击组件（连击、冷却、命中窗口）
│   ├── AttackComponentCS.cs    # C# 版
│   ├── knockback_component.gd  # 击退组件（方向力 + 衰减曲线）
│   ├── KnockbackComponentCS.cs # C# 版
│   ├── buff_effect.gd          # Buff 效果定义 Resource
│   ├── buff_component.gd       # Buff 管理器（叠加、过期、缓存聚合）
│   ├── BuffComponentCS.cs      # C# 版
│   ├── respawn_component.gd    # 重生组件（死亡→检查点→复活流程）
│   └── RespawnComponentCS.cs   # C# 版
│
... (省略其余结构)
```

## Autoload（全局单例）

- `SaveManager` (`utils/SaveSystem/gds版本/save_manager.gd`)
- `DebugHelper` (`utils/DebugConsole/debug_helper.gd`)
- `MusicPlayer` (`utils/AudioSystem/music_player.tscn`)
- `TimeController` (`utils/TimeController/TimeController.gd`)
- `SettingsManager` (`utils/SaveSystem/gds版本/settings_manager.gd`, 需手动注册)

## 组件基类体系

> 详见项目内部 Context 文档，包含 ComponentBase 及衍生分类、统一 `enabled` 模式。

## 使用指南

- CharacterComponents 驱动、自免疫时间缩放、组件间信号通信等详述
- AnimationComponent 自动播放优先级
- TimeController 缩放及排除逻辑
- 战斗组件互相连接流程
- 回放与存档系统示例

> 本 README 仅为摘要，开发者可参考原始 `CONTEXT.md` 获取完整细节。

---

```
// 将 README 与其它代码一并提交至 GitHub：
// git add README.md
// git commit -m "Add/update project README from CONTEXT" 
// git push origin main
```