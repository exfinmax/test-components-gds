# Component Library 架构设计

## 🎯 设计目标

打造一个**模块化、可扩展、易于使用**的Godot 4组件库系统，支持：
- 清晰的分类体系
- 快速组件查找和集成
- 自动化测试和演示
- 文档和示例完整

## 📦 新分类系统

### 三层分类架构

```
ComponentLibrary/
├── Core/                    # 核心层：基础设施
├── Modules/                 # 模块层：功能组件
└── Systems/                 # 系统层：全局服务
```

### 1. Core（核心层） - 基础设施

**职责**：提供所有组件的基础类和工具

```
Core/
├── base/
│   ├── component_base.gd            # 组件基类
│   ├── character_component_base.gd  # 角色组件基类
│   └── system_base.gd               # 系统基类（新）
├── events/
│   ├── event_bus.gd                 # 全局事件总线
│   └── event_types.gd               # 事件类型定义
├── pools/
│   ├── object_pool.gd               # 对象池
│   └── particle_pool.gd             # 粒子池（新）
├── time/
│   ├── time_controller.gd           # 时间控制器
│   └── local_time_domain.gd         # 局部时间域
└── utils/
	├── math_utils.gd                # 数学工具
	├── vector_utils.gd              # 向量工具
	└── curve_utils.gd               # 曲线工具
```

### 2. Modules（模块层） - 按功能分类

**职责**：可复用的独立功能组件

#### 2.1 Combat（战斗模块）
```
Modules/Combat/
├── Components/
│   ├── health_component.gd          # 生命值
│   ├── hitbox_component.gd          # 攻击箱
│   ├── hurtbox_component.gd         # 受击箱
│   ├── attack_component.gd          # 攻击
│   ├── knockback_component.gd       # 击退
│   ├── buff_component.gd            # Buff系统
│   └── respawn_component.gd         # 重生
├── Demo/
│   ├── combat_demo.tscn
│   ├── combat_demo.gd
│   └── preview.png
└── README.md
```

#### 2.2 Movement（移动模块）
```
Modules/Movement/
├── Components/
│   ├── gravity_component.gd         # 重力
│   ├── move_component.gd            # 水平移动
│   ├── jump_component.gd            # 跳跃
│   ├── dash_component.gd            # 冲刺
│   ├── wall_climb_component.gd      # 爬墙
│   ├── coyote_jump_component.gd     # 土狼时间
│   ├── one_way_drop_component.gd    # 单向平台
│   └── fall_damage_component.gd     # 坠落伤害
├── Demo/
└── README.md
```

#### 2.3 Input（输入模块）
```
Modules/Input/
├── Components/
│   ├── player_input_component.gd    # 玩家输入
│   ├── ai_input_component.gd        # AI输入
│   └── replay_input_component.gd    # 回放输入
├── Demo/
└── README.md
```

#### 2.4 Animation（动画模块）
```
Modules/Animation/
├── Components/
│   ├── animation_component.gd       # 动画管理
│   ├── animation_config.gd          # 动画配置
│   └── sprite_flipper_component.gd  # 精灵翻转
├── Demo/
└── README.md
```

#### 2.5 Time（时间模块）
```
Modules/Time/
├── Components/
│   ├── time_energy_component.gd     # 时间能量
│   ├── time_ability_component.gd    # 时间能力
│   ├── timeline_switch_component.gd # 时间线切换
│   ├── rewind_echo_bridge_component.gd
│   └── echo_trigger_plate_component.gd
├── Demo/
└── README.md
```

#### 2.6 VFX（特效模块）
```
Modules/VFX/
├── Components/
│   ├── impact_vfx_component.gd      # 冲击特效
│   ├── trail_component.gd           # 拖尾
│   ├── hit_flash_component.gd       # 受击闪白
│   ├── death_animation_component.gd # 死亡动画
│   └── afterimage_component.gd      # 残影
├── Templates/                        # 特效预制体
└── Demo/
```

#### 2.7 UI（界面模块）
```
Modules/UI/
├── Components/
│   ├── ui_page_state_component.gd   # 页面状态
│   ├── health_bar_component.gd      # 血条（新）
│   ├── cooldown_indicator_component.gd # 冷却指示（新）
│   └── floating_text_component.gd   # 浮动文字（新）
├── Templates/
│   └── Transition/
└── Demo/
```

#### 2.8 GameLogic（游戏逻辑模块）
```
Modules/GameLogic/
├── Foundation/                       # 基础逻辑
│   ├── cooldown_component.gd        # 冷却
│   ├── state_flag_component.gd      # 状态标记
│   └── timer_component.gd           # 计时器
├── Card/                            # 卡牌游戏
│   ├── deck_draw_component.gd
│   └── card_hand_component.gd
├── RPG/                             # RPG元素
│   ├── attribute_set_component.gd
│   ├── inventory_component.gd       # 背包（新）
│   └── quest_tracker_component.gd   # 任务追踪（新）
├── Roguelike/                       # Roguelike元素
│   ├── weighted_spawn_table_component.gd
│   └── procedural_gen_component.gd  # 程序生成（新）
├── Strategy/                        # 策略游戏
│   └── production_queue_component.gd
├── Puzzle/                          # 解谜元素
│   └── sequence_switch_component.gd
└── README.md
```

### 3. Systems（系统层） - 全局服务

**职责**：跨场景的全局管理系统

```
Systems/
├── Camera/
│   ├── camera_follow_system.gd      # 摄像机跟随
│   ├── camera_shake_system.gd       # 摄像机震动
│   └── camera_zone_system.gd        # 摄像机区域
├── Audio/
│   ├── audio_manager.gd             # 音频管理器
│   ├── bgm_player.gd                # 背景音乐
│   └── sfx_pool.gd                  # 音效池
├── Save/
│   ├── save_manager.gd              # 存档管理
│   └── checkpoint_system.gd         # 检查点系统
├── Level/
│   ├── level_loader.gd              # 关卡加载
│   ├── scene_transition.gd          # 场景转换
│   └── level_timer.gd               # 关卡计时
├── Replay/
│   ├── ghost_replay_system.gd       # 幽灵回放
│   └── time_rewind_system.gd        # 时间倒流
├── Score/
│   ├── score_manager.gd             # 分数管理
│   └── combo_tracker.gd             # 连击追踪
├── Debug/
│   ├── debug_overlay.gd             # 调试覆盖层
│   └── performance_monitor.gd       # 性能监控
└── Platform/
	└── moving_platform_system.gd    # 移动平台
```

## 🗂️ 迁移计划

### 阶段1：清理和重组（立即）

**删除/移动：**
- `Packs/111/` → 删除
- `Packs/SamplePackage/` → 删除
- `Packs/Character/` → 合并到 `Modules/Movement/`
- `Packs/Helpers/` → 移动到 `Core/utils/`

**重组：**
```bash
# 战斗相关
Packs/Combat/ → Modules/Combat/

# 移动相关
Packs/Platformer/ → Modules/Movement/
Packs/Racing/ (部分) → Modules/Movement/

# 游戏逻辑
Packs/Foundation/ → Modules/GameLogic/Foundation/
Packs/Card/ → Modules/GameLogic/Card/
Packs/RPG/ → Modules/GameLogic/RPG/
Packs/Roguelike/ → Modules/GameLogic/Roguelike/
Packs/Strategy/ → Modules/GameLogic/Strategy/
Packs/Puzzle/ → Modules/GameLogic/Puzzle/
Packs/Builder/ → Modules/GameLogic/Builder/

# 其他模块
Packs/Time/ → Modules/Time/
Packs/VFX/ → Modules/VFX/
Packs/UI/ → Modules/UI/
Packs/Action/ → Modules/Combat/ (合并)
Packs/Shooter/ → Modules/Combat/ (部分)
Packs/Survival/ → Modules/Combat/ (buff系统)

# 系统层
Packs/Systems/* → Systems/* (展开所有子系统)
```

### 阶段2：插件增强（优先）

**新功能：**
1. **分类浏览**：按Core/Modules/Systems三层浏览
2. **搜索过滤**：组件名称、标签搜索
3. **依赖检查**：显示组件依赖关系
4. **一键导入**：拷贝组件到项目
5. **文档预览**：内置README查看器
6. **示例场景**：快速测试组件

### 阶段3：文档完善（持续）

每个模块必须包含：
- `README.md`：功能说明、使用方法
- `Demo/`：可运行的演示场景
- 组件内注释：`## Component Name\n## Description\n## Properties`

## 🔧 插件架构改进

### 新的插件结构

```gdscript
# plugin.gd
class_name ComponentLibraryPlugin
extends EditorPlugin

var _dock: ComponentLibraryDock  # 独立Dock面板
var _categories := {
	"Core": [],
	"Modules": {},     # 子分类
	"Systems": []
}

func _get_category_for_path(path: String) -> String:
	if path.begins_with("Core/"): return "Core"
	elif path.begins_with("Modules/"): return "Modules"
	elif path.begins_with("Systems/"): return "Systems"
	return "Unknown"

func _load_component_metadata(path: String) -> Dictionary:
	# 从README.md或组件注释读取元数据
	# 返回: { name, description, dependencies, tags, author }
	pass
```

### 新UI设计

```
+------------------------------------------+
| Component Library                        |
+------------------------------------------+
| [Search...] [Filter▼]           [Close] |
+------------------------------------------+
| ├─ Core                                  |
| │  ├─ base/                              |
| │  ├─ events/                            |
| │  └─ pools/                             |
| ├─ Modules                               |
| │  ├─ Combat            [12 components]  |
| │  ├─ Movement          [8 components]   |
| │  ├─ Time              [6 components]   |
| │  ├─ VFX               [5 components]   |
| │  └─ GameLogic/                         |
| │     ├─ Foundation     [3 components]   |
| │     ├─ Card           [2 components]   |
| │     └─ RPG            [1 component]    |
| └─ Systems                               |
|    ├─ Camera            [3 systems]      |
|    ├─ Audio             [3 systems]      |
|    └─ Save              [2 systems]      |
+------------------------------------------+
| Selected: health_component.gd            |
| 📦 Combat Module                         |
| ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  |
| Manages entity health, damage, healing   |
| 📚 View Demo | 📄 View Code | ➕ Import  |
+------------------------------------------+
```

## 📊 文件组织规范

### 命名规范
- 组件：`功能_component.gd` (小写snake_case)
- 系统：`功能_system.gd` 或 `功能_manager.gd`
- Demo：`模块名_demo.gd`
- 资源：`功能_config.gd` 或 `功能_data.tres`

### 必需文件
```
ModuleName/
├── Components/          # 必需
│   └── *.gd
├── Demo/               # 必需
│   ├── demo.tscn
│   ├── demo.gd
│   └── preview.png
├── Templates/          # 可选：预制场景
├── Resources/          # 可选：配置资源
└── README.md          # 必需
```

### README.md 模板
````markdown
# Module Name

## Overview
Brief description (1-2 sentences)

## Components

### component_name.gd
- **Purpose**: What it does
- **Dependencies**: Required components/systems
- **Signals**: 
  - `signal_name(params)` - Description
- **Properties**:
  - `property: Type` - Description

## Usage Example
```gdscript
# Quick start code
var comp = ComponentName.new()
add_child(comp)
comp.do_something()
```

## Demo
Run `demo.tscn` to see it in action.
````

## 🎯 优先级任务

### P0 - 立即处理
1. ✅ 修复time_controller依赖缺失
2. ✅ 删除测试文件夹（111, SamplePackage）
3. 重组Core层（整合Dependencies）
4. 创建新的Modules目录结构

### P1 - 本周完成
1. 展开Systems子系统
2. 迁移Combat模块
3. 迁移Movement模块
4. 更新插件分类逻辑
5. 添加搜索功能

### P2 - 本月完成
1. 完成所有模块迁移
2. 为每个模块编写README
3. 改进Demo质量
4. 添加依赖检查

### P3 - 长期计划
1. 组件单元测试
2. 性能基准测试
3. C#双版本支持
4. 在线文档站点

## 📝 下一步行动

1. **备份当前项目** `git commit -am "Backup before restructure"`
2. **执行阶段1重组** 按迁移计划移动文件
3. **修复插件** 更新扫描逻辑适配新结构
4. **测试验证** 确保所有组件正常加载
5. **文档编写** 为迁移的模块添加README
