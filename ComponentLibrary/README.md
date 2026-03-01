# ComponentLibrary - 2D通用组件库

> **Godot 4.x** 的模块化、可复制、开箱即用的2D游戏组件集合

## 🎯 设计理念

ComponentLibrary 是一个**按需复制**的组件库，而非传统的依赖包：
- 🔌 **零耦合**：所有组件可独立运行，无强制依赖
- 📦 **按需使用**：只复制需要的模块到项目
- 🎨 **清晰分层**：Core基础 → Modules功能 → Systems服务
- 🚀 **直接可用**：每个组件都有完整的Demo和Template

---

## 📂 标准目录结构

每个模块都遵循统一的**三层结构**：

```
ModuleName/
├── Components/        # 📜 组件实现（脚本 + 场景）
│   ├── xxx_component.gd      # 组件脚本
│   ├── xxx_component.tscn    # 组件场景（可选）
│   └── ...
│
├── Templates/         # 🎨 使用模板（预配置的节点组合）
│   ├── basic_template.tscn   # 基础模板：展示最简单的用法
│   ├── advanced_template.tscn # 高级模板：展示复杂组合
│   └── ...
│
└── Demo/             # 🎮 完整演示（可运行的游戏示例）
    ├── demo_scene.tscn       # 演示场景
    ├── demo_scene.gd         # 演示逻辑
    └── ...
```

### 📋 目录职责说明

| 目录 | 职责 | 内容示例 |
|------|------|----------|
| **Components** | 纯粹的组件实现，每个组件只做一件事 | `health_component.gd`、`jump_component.gd` |
| **Templates** | 展示如何组合多个组件，提供预配置的节点树 | `basic_player.tscn`包含移动+跳跃+动画组件 |
| **Demo** | 完整的可玩示例，展示模块在实际游戏中的应用 | 完整的平台跳跃关卡，带UI和音效 |

---

## 🏗️ 完整架构

### Core - 核心基础设施

**用途**：所有组件的基础依赖，通常整体复制到项目

```
Core/
├── base/              # 基类
│   ├── component_base.gd           # 所有组件的基类
│   ├── character_component_base.gd # 角色组件基类
│   └── pack_demo.gd                # Demo场景基类
│
├── events/            # 事件系统
│   └── event_bus.gd                # 全局事件总线（解耦模块通信）
│
├── pools/             # 对象池
│   └── object_pool.gd              # 对象复用管理（性能优化）
│
├── time/              # 时间控制
│   ├── time_controller.gd          # 全局时间控制器（子弹时间）
│   └── local_time_domain.gd        # 局部时间域
│
└── utils/             # 工具库
    ├── Math.gd                     # 数学工具函数
    ├── Complex.gd                  # 复数运算
    └── FFT.gd                      # 快速傅里叶变换
```

---

### Modules - 功能模块

**用途**：按需复制，每个模块提供特定领域的功能

#### 🗡️ Combat - 战斗系统

**Components**：
- `health_component` - 生命值管理
- `hitbox_component` - 攻击判定区
- `hurtbox_component` - 受击判定区
- `attack_component` - 攻击行为
- `buff_component` - Buff/Debuff系统
- `knockback_component` - 击退效果
- `respawn_component` - 重生逻辑

**Templates**：
- `basic_fighter.tscn` - 基础战斗单位（health + hitbox + hurtbox）
- `advanced_enemy.tscn` - 高级敌人（添加buff和击退）

**Demo**：
- `combat_demo.tscn` - 完整战斗演示场景

---

#### 🏃 Movement - 角色移动

**Components**：
- `move_component` - 基础移动
- `jump_component` - 跳跃控制
- `dash_component` - 冲刺
- `gravity_component` - 重力
- `wall_climb_component` - 爬墙
- `input_component` - 输入处理
- `animation_component` - 动画控制
- `state_coordinator` - 状态协调器

**Templates**：
- `character.gd` - 角色基类（组合所有移动组件）

**Demo**：
- `Player/` - 玩家控制演示
- `ReplayEnemy/` - AI/回放演示

---

#### 🎬 Animation - 动画系统
#### ⌨️ Input - 输入处理
#### ⏱️ Time - 时间特效
#### ✨ VFX - 视觉特效
#### 🖼️ UI - UI组件

---

#### 🎮 GameLogic - 游戏类型专属

按游戏类型组织的专属逻辑：

- **Platformer** - 平台跳跃（平台、弹簧、活板门）
- **Roguelike** - Roguelike（随机生成、房间系统）
- **RPG** - RPG系统（任务、对话、物品）
- **Shooter** - 射击游戏（枪械、弹道、掩体）
- **Strategy** - 策略游戏（单位选择、建筑、资源）
- **Survival** - 生存游戏（饥饿、耐力、采集）
- **Card** - 卡牌游戏（卡组、手牌、回合）
- **Puzzle** - 解谜游戏（机关、推箱子）
- **Racing** - 竞速游戏（赛道、漂移、计时）
- **Builder** - 建造游戏（网格、建筑物）
- **Action** - 动作游戏（连招、格挡、处决）
- **Foundation** - 基础游戏逻辑

---

### Systems - 全局服务

**用途**：单例模式的系统级服务，通常作为Autoload

#### 📷 Camera - 相机系统
- 平滑跟随、震动效果、区域限制、多目标跟踪

#### 🔊 Audio - 音频管理
- 音乐播放、音效管理、音量控制、淡入淡出

#### 💾 Save - 存档系统
- 数据持久化、自动保存、多存档槽

#### 📹 Replay - 回放系统
- 录制回放、幽灵数据、时间倒流

#### 🗺️ Level - 关卡管理
- 场景切换、关卡计时、进度跟踪

#### 🏆 Score - 计分系统
- 分数计算、排行榜、成就

#### 🐛 Debug - 调试工具
- 性能监控、可视化调试、作弊工具

#### 🎯 Platform - 平台相关
- 平台特定功能、权限管理

#### 🚩 Checkpoint - 检查点
- 存档点、快速传送

#### ⚡ Trigger - 触发器
- 区域触发、事件触发

---

## 🚀 快速开始

### 1️⃣ 复制Core层（必需）

```bash
# 复制整个Core目录到你的项目
cp -r ComponentLibrary/Core/* <你的项目>/Core/
```

### 2️⃣ 注册Autoload（推荐）

打开 **Project → Project Settings → Autoload**，添加：

| Name | Path | 说明 |
|------|------|------|
| `EventBus` | `res://Core/events/event_bus.gd` | 全局事件总线 |
| `TimeController` | `res://Core/time/time_controller.gd` | 时间控制器 |
| `ObjectPool` | `res://Core/pools/object_pool.gd` | 对象池 |

### 3️⃣ 复制需要的模块

```bash
# 例如：需要战斗系统和移动系统
cp -r ComponentLibrary/Modules/Combat <你的项目>/Modules/Combat
cp -r ComponentLibrary/Modules/Movement <你的项目>/Modules/Movement
```

### 4️⃣ 使用模板快速开始

1. 打开 `Modules/Combat/Templates/basic_fighter.tscn`
2. 右键 → **Save Branch as Scene** 保存为你的角色场景
3. 在场景中调整组件参数
4. 运行场景测试

### 5️⃣ 或者手动组装组件

```gdscript
# 在你的角色脚本中
extends CharacterBody2D

@onready var health = $HealthComponent
@onready var jump = $JumpComponent
@onready var move = $MoveComponent

func _ready():
	health.max_health = 100
	jump.jump_force = 500
	move.speed = 300

func _physics_process(delta):
	jump.process_jump(self, delta)
	move.process_move(self, delta)
```

---

## 📖 使用示例

### 示例1：创建基础战斗角色

1. **复制模块**：
   ```bash
   cp -r ComponentLibrary/Modules/Combat MyProject/Combat
   ```

2. **使用模板**：
   - 打开 `Combat/Templates/basic_fighter.tscn`
   - 修改Sprite2D的纹理
   - 调整collision形状
   - 保存为 `player.tscn`

3. **配置参数**：
   ```gdscript
   # 在Inspector中调整
   HealthComponent:
       max_health: 100
       regeneration_rate: 5
   
   HurtboxComponent:
       damage_multiplier: 1.0
   ```

### 示例2：添加移动能力

1. **打开角色场景** `player.tscn`

2. **添加移动组件**：
   - 右键场景根节点
   - Add Child Node
   - 搜索组件类名（如 `MoveComponent`、`JumpComponent`）
   - 或者直接拖入 `Movement/Components/*.tscn` 场景

3. **在脚本中使用**：
   ```gdscript
   extends CharacterBody2D
   
   @onready var move = $MoveComponent
   @onready var jump = $JumpComponent
   @onready var dash = $DashComponent
   
   func _physics_process(delta):
       var input = Vector2(
           Input.get_axis("ui_left", "ui_right"),
           0
       )
       
       move.process_move(self, input, delta)
       
       if Input.is_action_just_pressed("ui_accept"):
           jump.try_jump(self)
       
       if Input.is_action_just_pressed("dash"):
           dash.perform_dash(self, input)
   ```

### 示例3：查看完整Demo

1. 运行 `Modules/Movement/Demo/Player/player_demo.tscn`
2. 查看场景树结构和组件配置
3. 阅读 `player.gd` 了解组件调用方式
4. 复制需要的部分到你的项目

---

## 🔌 插件支持

启用编辑器插件可获得：
- 📚 **组件浏览器**：Dock面板中浏览所有组件
- 🔍 **快速搜索**：实时搜索组件
- 📖 **详情查看**：查看组件说明和依赖
- ⚡ **快速打开**：一键打开脚本或Demo

**启用方法**：
1. 打开 **Project → Project Settings → Plugins**
2. 启用 `ComponentLibrary Share`
3. 查看右下角 **ComponentLibrary** 面板

---

## 📝 设计约束

### 1. 无依赖降级

所有组件在缺少依赖时仍能工作（功能可能受限）

```gdscript
# 示例：检查EventBus是否存在
if has_node("/root/EventBus"):
    EventBus.emit_signal("player_damaged", damage)
else:
    # 降级处理：直接调用
    _on_damaged(damage)
```

### 2. 单一职责

每个组件只做一件事，通过组合实现复杂功能

```gdscript
# ❌ 不要这样：一个组件做所有事
class_name PlayerController  # 混杂了移动、战斗、UI

# ✅ 应该这样：拆分为多个组件
# - MoveComponent: 只负责移动
# - JumpComponent: 只负责跳跃
# - HealthComponent: 只负责生命值
```

### 3. 信号优先

跨模块通信优先使用信号，避免直接引用

```gdscript
# ✅ 推荐：通过信号通信
signal health_changed(new_health)
health_changed.emit(health)

# ⚠️ 避免：直接引用其他模块
ui_manager.update_health(health)  # 创建了耦合
```

### 4. 场景优先

提供 `.tscn` 模板，开箱即用

```
✅ 提供：health_component.tscn（配置好的Area2D + CollisionShape2D）
✅ 文档：说明如何在代码中动态创建
```

### 5. 完整文档

每个模块都应包含：
- `README.md` - 模块说明和使用指南
- `Components/` - 组件实现
- `Templates/` - 使用模板
- `Demo/` - 可运行的演示

---

## 🛠️ 开发规范

### 创建新组件

1. **选择合适的分类**：
   - 通用功能 → `Modules/`
   - 游戏类型专属 → `Modules/GameLogic/`
   - 单例服务 → `Systems/`

2. **创建标准结构**：
   ```bash
   mkdir -p Modules/MyModule/{Components,Templates,Demo}
   ```

3. **编写组件脚本**：
   ```gdscript
   extends ComponentBase  # 或 CharacterComponentBase
   class_name MyComponent
   
   ## 组件说明：这个组件做什么
   ## 
   ## 使用方法：
   ## 1. 添加到角色节点
   ## 2. 配置参数
   ## 3. 调用process_xxx()方法
   
   @export var strength: float = 1.0
   
   func _ready():
       super._ready()
   
   func process_component(delta: float) -> void:
       # 组件逻辑
       pass
   ```

4. **创建组件场景**（可选）：
   - 新建场景，根节点类型根据功能选择（Node、Area2D等）
   - 附加组件脚本
   - 添加必要的子节点（如CollisionShape2D）
   - 保存为 `.tscn`

5. **创建模板**：
   - 展示组件的典型用法
   - 预配置常用参数
   - 添加必要的子节点

6. **创建Demo**：
   - 完整的可运行场景
   - 展示模块在实际游戏中的应用
   - 添加UI提示和说明文字

7. **编写README**：
   ```markdown
   # ModuleName
   
   ## 功能说明
   
   ## 组件列表
   
   ## 使用示例
   
   ## 注意事项
   ```

---

## 📚 相关文档

- [ARCHITECTURE.md](ARCHITECTURE.md) - 详细架构设计和迁移指南
- [PROJECT_PLAN.md](PROJECT_PLAN.md) - 项目规划和路线图
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - 快速参考和常见问题

---

## 🤝 贡献指南

1. 遵循现有代码风格
2. 遵守三层目录结构（Components/Templates/Demo）
3. 添加完整的注释和类型提示
4. 提供可运行的Demo
5. 更新相关文档
6. 确保向后兼容

---

## 📄 许可证

本项目使用 MIT 许可证，可自由使用、修改和分发。

---

## 🏷️ 标签

`#Godot` `#GDScript` `#ComponentSystem` `#GameDev` `#2D` `#Modular` `#Reusable` `#Template`
