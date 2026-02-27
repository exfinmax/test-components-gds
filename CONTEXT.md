# test-components 项目上下文

> **项目定位**：Godot 4.6 可复用组件库（GDScript + C# 双版本）  
> 每个文件夹都是一个**独立组件**，复制到任何项目即可使用，无需修改即可单独测试。  
> **目标游戏类型**：时间操控横板跑酷

---

## 📐 设计原则

1. **单一职责** — 每个组件只做一件事
2. **独立可测** — 组件挂到最小场景（如空的 CharacterBody2D）即可运行，不依赖外部
3. **信号驱动** — 组件之间通过信号通信，避免直接引用
4. **自省能力** — 每个组件都有 `get_component_data() -> Dictionary`，返回当前状态的键值对
5. **零配置可用** — 组件有合理的默认值，拖入场景即工作
6. **双语版本** — 核心组件同时提供 GDScript 和 C# 实现

---

## 📁 目录结构

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
├── Systems/                    ⭐ 全局系统/服务
│   ├── Audio/                  # 全局音频（BGM/SFX，淡入淡出）
│   ├── Camera/                 # 摄像机（跟随、震动、前瞻、限制）
│   │   ├── camera_component.gd
│   │   └── CameraComponentCS.cs
│   ├── Checkpoint/             # 检查点（关卡内即时重生标记）
│   │   ├── checkpoint_component.gd
│   │   └── CheckpointComponentCS.cs
│   ├── Debug/                  # 调试控制台 + 日志
│   ├── GhostReplay/            # 幽灵回放（最佳路径影子 T3）
│   │   ├── ghost_replay_component.gd
│   │   └── GhostReplayComponentCS.cs
│   ├── LevelTimer/             # 关卡计时器（Speedrun 分段计时 T4）
│   │   ├── level_timer_component.gd
│   │   └── LevelTimerComponentCS.cs
│   ├── Platform/               # 移动平台（路径点、缓动、时间影响 T2）
│   │   ├── moving_platform_component.gd
│   │   └── MovingPlatformComponentCS.cs
│   ├── Save/                   # 存档系统（GDS Resource + C# JSON）
│   ├── Score/                  # 连击计分（Combo 链、多样性加成 T2）
│   │   ├── combo_timer_component.gd
│   │   └── ComboTimerComponentCS.cs
│   ├── Time/                   # 全局时间控制器（缩放 + 排除列表）
│   ├── TimeRewind/             # 时间倒流（环形缓冲区录制/回放 T3）
│   │   ├── time_rewind_component.gd
│   │   └── TimeRewindComponentCS.cs
│   ├── TimeZone/               # 时间区域（区域内改变时间流速 T2）
│   │   ├── time_zone_component.gd
│   │   └── TimeZoneComponentCS.cs
│   └── Trigger/                # 通用触发区域（关卡事件开关 T4）
│       ├── trigger_zone_component.gd
│       └── TriggerZoneComponentCS.cs
│
├── VFX/                        ⭐ 视觉特效
│   ├── CanYing/                # 残影/拖影
│   ├── DeathAnimated/          # 死亡动画
│   ├── FloatingText/           # 浮动伤害数字
│   ├── HitFlash/               # 受击闪白
│   ├── ScreenEffect/           # 全屏后处理（时间操控视觉反馈 T3）
│   │   └── screen_effect_component.gd
│   ├── Trail/                  # 拖尾渲染（运动轨迹线 T4）
│   │   └── trail_renderer_component.gd
│   ├── parallax_background.tscn
│   └── time_stop_particles.tscn
│
├── Helpers/                    ⭐ 静态工具
│   ├── Math.gd                 # GDS 数学工具
│   ├── MathHelper.cs           # C# 数学工具（内联优化）
│   ├── ReplayFrame.cs          # 回放帧 struct + 环形缓冲区
│   └── TimeControllerCS.cs     # C# 时间控制器
│
├── Shader/                     ⭐ Shader 实验
│   ├── shaders/                # 着色器文件集合
│   └── ...                     # 控制脚本 + 测试场景
│
├── UI/                         ⭐ UI 组件
│   ├── Transition/             # 场景转场（Shader 溶解式）
│   ├── ShaderButton/           # Shader 按钮
│   └── ButtonEffectModule/     # 按钮效果模块
│
├── AI/                         ⭐ AI 组件
│   └── ReplayEnemy(状态机版)/   # 录制回放式敌人 AI（旧版）
│
├── 2dCharacterStateMachine/    📦 旧版状态机（已被 CharacterComponents 替代）
│
└── Test/                       🧪 测试场景
```

---

## 🔌 Autoload（全局单例）

| 名称 | 路径 | 说明 |
|------|------|------|
| `SaveManager` | `utils/SaveSystem/gds版本/save_manager.gd` | 存档管理器（GDS） |
| `DebugHelper` | `utils/DebugConsole/debug_helper.gd` | 调试日志 `DebugHelper.log()` |
| `MusicPlayer` | `utils/AudioSystem/music_player.tscn` | 音频系统 |
| `TimeController` | `utils/TimeController/TimeController.gd` | 时间缩放 + 排除列表 |
| `SettingsManager`* | `utils/SaveSystem/gds版本/settings_manager.gd` | 设置管理（需手动注册） |

> *SettingsManager 需要手动在 project.godot 中注册 Autoload

---

## ⭐ 组件基类体系

### 继承关系

```
ComponentBase (Node)                    ← Core/component_base.gd
│  enabled + enabled_changed 信号
│  _on_enable() / _on_disable() 虚回调
│  _component_ready() 初始化钩子
│  get_component_data() 自省
│  find_sibling() / find_siblings() 同级查找
│
├── CharacterComponentBase              ← CharacterComponents/Components/component_base.gd
│   │  character: CharacterBody2D 自动绑定
│   │  self_driven + physics_tick/tick 双驱动
│   │  find_component() 角色子节点查找
│   │
│   ├── GravityComponent
│   ├── MoveComponent
│   ├── JumpComponent
│   ├── DashComponent
│   ├── WallClimbComponent
│   ├── InputComponent
│   └── AnimationComponent
│
├── RecordComponent                     ← 录制组件
├── ReplayComponent                     ← 回放组件
└── HitFlashComponent                   ← 受击闪白

Area2D / Node2D 组件（无法继承 ComponentBase，手动实现同一模式）：
├── HealthComponent (Node2D)    — enabled 阻止 damage/heal
├── HitBoxComponent (Area2D)    — enabled → monitoring/monitorable
├── HurtBoxComponent (Area2D)   — enabled → monitoring
├── CanyingComponent (Node2D)   — enabled 替代旧 is_enable
└── DeathAnimatedComponent (Node2D) — enabled 阻止死亡特效
```

### 统一 enabled 模式

所有组件（无论是否继承 ComponentBase）现在都遵循相同的模式：

```gdscript
# 所有组件都有：
signal enabled_changed(is_enabled: bool)

var enabled: bool = true:
	set(v):
		if enabled == v: return
		enabled = v
		enabled_changed.emit(enabled)
		# ComponentBase 子类自动调用 _on_enable/_on_disable
		# Area2D 子类额外同步 monitoring/monitorable

# 禁用组件：
health_component.enabled = false   # 不再受伤
hitbox_component.enabled = false   # 攻击箱关闭碰撞
hurtbox_component.enabled = false  # 受击箱关闭检测
dash_component.enabled = false     # 中断冲刺并恢复依赖组件
```

---

## ⭐ CharacterComponents 使用指南

### 驱动模式（self_driven）

| 模式 | 说明 | 适用场景 |
|------|------|----------|
| `self_driven = true` | 组件自行 `_process`/`_physics_process` | 独立测试、简单场景 |
| `self_driven = false` | Character 统一调用 `tick(delta)`/`physics_tick(delta)` | 时间免疫、统一 delta 控制 |

```gdscript
# 玩家免疫时间缩放的原理：
# 1. 所有组件 self_driven=false
# 2. Character._physics_process 统一调用 comp.physics_tick(delta)
# 3. PlayerComponent 重写 _get_physics_delta 返回补偿 delta

# Character 基类逻辑：
func _physics_process(delta: float) -> void:
	var drive_delta := _get_physics_delta(delta)  # 子类可重写
	for comp in get_all_components():
		if not comp.self_driven:
			comp.physics_tick(drive_delta)
	move_and_slide()

# PlayerComponent 重写：
func _get_physics_delta(delta: float) -> float:
	if time_immune:
		return TimeController.get_real_delta(delta)  # 补偿后的真实 delta
	return delta
```

### 效果对比

```
Engine.time_scale = 0.5 时：

敌人（不免疫）                  玩家（免疫）
├─ delta = 0.033 (1/60*0.5)       ├─ raw delta = 0.033
├─ physics_tick(0.033)            ├─ get_real_delta(0.033) = 0.066
├─ 移动速度减半                   ├─ physics_tick(0.066)
└─ 动画慢放                       └─ 移动速度正常，动画正常
```

### 最小场景搭建

```
CharacterBody2D (character.gd)
  ├── CollisionShape2D
  ├── Body (Node2D, unique name %)      # 用于翻转朝向
  │   └── Sprite2D
  ├── InputComponent                    # 输入
  ├── GravityComponent                  # 重力
  └── MoveComponent                     # 移动
```

### 添加跳跃 + 冲刺 + 爬墙

```
CharacterBody2D
  ├── ...基础组件...
  ├── JumpComponent       # @export 连接 InputComponent, GravityComponent
  ├── DashComponent       # @export 连接 InputComponent, MoveComponent, GravityComponent
  └── WallClimbComponent  # @export 连接 InputComponent, GravityComponent, MoveComponent
```

### 组件间通信（信号）

```gdscript
# 外部脚本监听组件信号
var jump_comp := character.get_component(JumpComponent) as JumpComponent
jump_comp.jumped.connect(func(): play_sfx("jump"))
jump_comp.landed.connect(func(): spawn_dust_particles())

var dash_comp := character.get_component(DashComponent) as DashComponent
dash_comp.dash_started.connect(func(dir): enable_ghost_trail())
dash_comp.dash_ended.connect(func(): disable_ghost_trail())
```

### AI/回放驱动

```gdscript
# 切换到 AI 输入源
var input_comp := character.get_component(InputComponent) as InputComponent
input_comp.input_source = InputComponent.InputSource.AI

# AI 脚本中调用
input_comp.simulate_move(Vector2.RIGHT)
input_comp.simulate_jump(true)
```

### 获取组件自省数据

```gdscript
# 单个组件
var data = jump_comp.get_component_data()
# {"enabled": true, "is_jumping": false, "coyote_timer": 0.2, ...}

# 所有组件
var all_data = character.get_all_component_data()
# {"InputComponent": {...}, "GravityComponent": {...}, ...}
```

---

## 🎬 AnimationComponent 使用指南

### 场景结构

```
CharacterBody2D (character.gd)
  ├── CollisionShape2D
  ├── Body (Node2D, unique name %)
  │   ├── Sprite2D
  │   └── AnimationPlayer          ← 动画播放器
  ├── InputComponent
  ├── GravityComponent
  ├── MoveComponent
  ├── JumpComponent
  ├── DashComponent
  └── AnimationComponent            ← 自动发现上面所有组件 + AnimationPlayer
	  └── config: AnimationConfig   ← 拖入 .tres 资源
```

### 优先级系统

```
DEATH=100  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  死亡（最高）
HIT=50     ▓▓▓▓▓▓▓▓▓▓             受击
DASH=40    ▓▓▓▓▓▓▓▓               冲刺
WALL=35    ▓▓▓▓▓▓▓                滑墙/蹬墙跳
JUMP=30    ▓▓▓▓▓▓                 跳跃
LAND=25    ▓▓▓▓▓                  落地（一次性）
FALL=20    ▓▓▓▓                   下落
MOVE=10    ▓▓                     跑步
IDLE=0     ▓                      待机（最低）
```

### 自动动画流

```gdscript
# 不需要任何代码！AnimationComponent 自动监听信号：
# MoveComponent.started_moving  → 播放 "run"
# MoveComponent.stopped_moving  → 播放 "idle"
# JumpComponent.jumped          → 播放 "jump_start" → "jump_rise"
# GravityComponent.started_falling → 播放 "fall"
# JumpComponent.landed          → 播放 "land"（一次性）
# DashComponent.dash_started    → 播放 "dash_begin" → "dash"
# DashComponent.dash_ended      → 播放 "dash_end"
# WallClimbComponent.wall_slide_started → 播放 "wall_slide"
```

### AnimationConfig 映射

```gdscript
# 不同角色使用不同 AnimationConfig 资源
# 例如同一套逻辑，boss 的动画名可能不同：
var config = AnimationConfig.new()
config.idle = &"boss_idle"
config.dash = &"boss_charge"
config.dash_up = &"boss_uppercut"  # 向上冲刺使用不同动画
```

### 手动触发（受击/死亡等）

```gdscript
var anim_comp = character.get_component(AnimationComponent) as AnimationComponent
anim_comp.play_hit()     # 优先级 50，打断除 DEATH 外的一切
anim_comp.play_death()   # 优先级 100，打断一切
anim_comp.play_custom(&"special_attack", AnimationComponent.Priority.HIT)
```

---

## 🕐 TimeController 使用指南

```gdscript
# 引擎慢放（物理+渲染）
TimeController.engine_time_scale = 0.5

# 音频独立控制
TimeController.audio_time_scale = 0.8

# 同时设置（旧行为）
TimeController.set_all_time_scale(0.5)

# 排除玩家（不受慢放影响）
TimeController.exclude(player)

# 被排除节点中使用补偿 delta
func _process(delta: float) -> void:
	var real_delta = TimeController.get_real_delta(delta)

# 恢复受影响
TimeController.include(player)
```

---

## ⚔️ 战斗组件使用指南

```
角色A                          角色B
├── HitBoxComponent            ├── HurtBoxComponent
│   damage = 10                │   @export health_component
│   hit_target 信号 ──────────→│   hurt 信号 → 击退/特效
│                              ├── HealthComponent
│                              │   health_changed 信号 → 血条UI
│                              │   died 信号 → 死亡逻辑
```

---

## 📋 组件清单与 get_component_data

| 组件 | class_name | get_component_data 返回字段 |
|------|------------|---------------------------|
| ComponentBase | `ComponentBase` | `enabled` |
| GravityComponent | `GravityComponent` | `enabled, gravity_force, gravity_mode, is_on_floor` |
| InputComponent | `InputComponent` | `enabled, input_source, direction, is_jump_held, buffered_inputs` |
| MoveComponent | `MoveComponent` | `enabled, speed, acceleration, is_moving, current_velocity_x` |
| JumpComponent | `JumpComponent` | `enabled, is_jumping, coyote_timer, pre_jump_timer` |
| DashComponent | `DashComponent` | `enabled, is_dashing, can_dash, current_dash_count, cooldown_remaining` |
| WallClimbComponent | `WallClimbComponent` | `enabled, is_wall_sliding, wall_normal` |
| HealthComponent | `HealthComponent` | `max_health, current_health, health_percent, is_alive` |
| HitBoxComponent | `HitBoxComponent` | `damage, collision_layer, collision_mask` |
| HurtBoxComponent | `HurtBoxComponent` | `has_health_component, collision_layer, collision_mask` |
| TimeController | (Autoload) | `global_time_scale, excluded_count, excluded_nodes` |

---

## 🔁 回放组件使用指南

### 两种回放模式

| 模式 | 说明 | 精度 | 性能 |
|------|------|------|------|
| **INPUT** | 录制输入，回放时注入 InputComponent | 较低（物理模拟可能偏移） | 高 |
| **PATH** | 录制位置，回放时直接设置坐标 | 精确 | 中 |

### 录制

```gdscript
# 将 RecordComponent 挂到目标（玩家）角色上
# 设置 target 为自身 CharacterBody2D
# record_mode = RecordMode.BOTH (同时录制输入和位置)

# 开始/停止录制
record_comp.start_recording()
record_comp.stop_recording()

# 获取录制的帧数据
var frames: Array[ReplayFrame] = record_comp.get_all_frames()
```

### 回放

```gdscript
# 将 ReplayComponent 挂到回放体（敌人）角色上
# 手动设置 recorded_frames 或通过 Inspector

replay_comp.recorded_frames = frames
replay_comp.replay_mode = ReplayComponent.ReplayMode.PATH
replay_comp.start_replay()
```

---

## 💾 存档系统使用指南

### GDS 版本（继承模式）

```gdscript
# 1. 继承 SaveableComponent 并重写
class_name PlayerSaveable extends SaveableComponent

func get_save_data() -> Dictionary:
	return {"hp": owner.hp, "position": owner.global_position}

func apply_save_data(data: Dictionary) -> void:
	owner.hp = data.get("hp", 100)
	owner.global_position = data.get("position", Vector2.ZERO)

# 2. 存档/读档
SaveManager.save_game()
SaveManager.load_game()
```

### C# 版本（接口模式）

```csharp
// 1. 实现 ISaveable 接口（无需继承特定基类）
public partial class PlayerData : Node, ISaveable
{
	public string NodeUuid { get; set; } = "player_main";
	public bool IsStatic => false;

	public Dictionary<string, Variant> GetSaveData() => new()
	{
		["hp"] = GetParent<Player>().Hp,
		["pos_x"] = GetParent<Player>().GlobalPosition.X,
	};

	public void ApplySaveData(Dictionary<string, Variant> data) { ... }
}

// 2. 注册后存档
saveManager.Register(this);
saveManager.SaveGame();
```

### GDS vs C# 存档对比

| 特性 | GDS 版 | C# 版 |
|------|--------|-------|
| 多态方式 | 继承 SaveableComponent | 实现 ISaveable 接口 |
| 序列化格式 | Godot Resource (.tres) | JSON (.json) |
| UUID 查找 | Dictionary O(1) | Dictionary O(1) |
| 设置管理 | SettingsManager（独立） | 不含（按需自行实现） |
| 适用场景 | 纯 GDS 项目 | 混合项目/需要跨平台 JSON |

---

## 🚀 GDS vs C# 组件分类

### 适合用 C# 实现的组件

| 组件 | 原因 |
|------|------|
| **MathHelper** | `in` 参数避免 Vector2 拷贝、`[AggressiveInlining]` 内联、`MathF` float 精度、`SmoothDamp` 等高级插值 |
| **ReplayFrame** | struct 值类型零 GC（对比 GDS RefCounted 每帧堆分配）、环形缓冲区连续内存、18000 帧从 ~3.6MB 降至 ~1.1MB |
| **TimeControllerCS** | `HashSet<Node>` O(1) 排除查找（对比 GDS `Array.has()` O(n)）、回调模式避免临时列表分配 |
| **SaveManagerCS** | 接口替代继承、JSON 序列化跨平台友好、强类型泛型集合 |

### 适合保留 GDS 的组件

| 组件 | 原因 |
|------|------|
| **CharacterComponents 全系** | 与 Godot 物理引擎深度集成（CharacterBody2D）、信号驱动天然 GDS 友好、`@export` 编辑器交互好 |
| **战斗组件（Health/HitBox/HurtBox）** | 逻辑简单、信号驱动、无性能瓶颈 |
| **UI 组件** | 与 Godot UI 系统紧密集成、Shader 控制代码简单 |
| **音频/视觉组件** | 逻辑轻量、主要是 Godot 节点配置 |

### 混合使用建议

```
GDS 组件（游戏逻辑层）         C# 组件（性能关键层）
├── InputComponent              ├── MathHelper（静态调用）
├── MoveComponent               ├── ReplayFrame（数据结构）
├── JumpComponent               ├── TimeControllerCS（替换 GDS 版）
├── HealthComponent             └── SaveManagerCS（替换 GDS 版）
└── HurtBoxComponent
```

> 可以从 GDScript 直接调用 C# 类，无需额外桥接。

---

## 📋 组件完整清单

| 组件 | 语言 | class_name | get_component_data 返回字段 |
|------|------|------------|---------------------------|
| ComponentBase | GDS | `ComponentBase` | `enabled` |
| GravityComponent | GDS | `GravityComponent` | `enabled, gravity_force, gravity_mode, is_on_floor` |
| InputComponent | GDS | `InputComponent` | `enabled, input_source, direction, is_jump_held, buffered_inputs` |
| MoveComponent | GDS | `MoveComponent` | `enabled, speed, acceleration, is_moving, current_velocity_x` |
| JumpComponent | GDS | `JumpComponent` | `enabled, is_jumping, coyote_timer, pre_jump_timer` |
| DashComponent | GDS | `DashComponent` | `enabled, is_dashing, can_dash, current_dash_count, cooldown_remaining` |
| WallClimbComponent | GDS | `WallClimbComponent` | `enabled, is_wall_sliding, wall_normal` |
| AnimationComponent | GDS | `AnimationComponent` | `enabled, current_animation, current_priority, is_playing, queue_size, connected_components` |
| AnimationConfig | GDS | `AnimationConfig` | N/A (Resource) |
| HealthComponent | GDS | `HealthComponent` | `max_health, current_health, health_percent, is_alive` |
| HitBoxComponent | GDS | `HitBoxComponent` | `damage, collision_layer, collision_mask` |
| HurtBoxComponent | GDS | `HurtBoxComponent` | `has_health_component, collision_layer, collision_mask` |
| RecordComponent | GDS | `RecordComponent` | `is_recording, record_mode, frame_count, buffer_seconds` |
| ReplayComponent | GDS | `ReplayComponent` | `is_replaying, replay_mode, progress, current_frame_index` |
| TimeController | GDS | (Autoload) | `engine_time_scale, audio_time_scale, excluded_count, excluded_nodes` |
| PlayerComponent | GDS | `PlayerComponent` | `is_dead, time_immune, heading, velocity` + 所有子组件 |
| EnemyComponent | GDS | `EnemyComponent` | `is_dead, has_appeared, delay_seconds` + 所有子组件 |
| SaveManager | GDS | (Autoload) | `current_slot, registered_count, loaded_data_count` |
| SettingsManager | GDS | `SettingsManager` | `setting_count, keys` |
| MathHelper | C# | (static) | N/A |
| ReplayFrame | C# | (struct) | N/A |
| ReplayBuffer | C# | (class) | N/A |
| TimeControllerCS | C# | `TimeControllerCS` | `type, global_time_scale, excluded_count, excluded_nodes` |
| SaveManagerCS | C# | `SaveManagerCS` | `type, current_slot, registered_count, loaded_data_count` |
