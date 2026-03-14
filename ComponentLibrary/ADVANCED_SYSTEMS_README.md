# 高级系统组件库 - Advanced Systems Component Library

本组件库包含8个现代游戏开发所需的高级系统组件，基于业界标准的设计模式（如UE5的GAS系统）。

## 📦 包含的系统

### 1. **属性系统 (Attribute System)** - Combat模块
文件: `ComponentLibrary/Modules/Combat/Components/attribute_system.gd`

**功能**: 支持动态属性修改的完整属性管理系统

**特性**:
- 基础值 + 修饰符 = 最终值
- 4种修饰符类型:
  - `ADDITIVE`: 加成 (+20)
  - `PERCENTAGE`: 百分比 (×1.2)  
  - `MULTIPLY`: 乘数 (×2)
  - `CLAMP`: 夹紧 (min/max)
- 临时修饰符自动过期清理
- 属性变化信号通知

**快速开始**:
```gdscript
var attr = AttributeSystem.new()
attr.set_base_value("health", 100)

var bonus = AttributeSystem.ModifierData.new(20, AttributeSystem.ModifierData.Type.ADDITIVE, "装备")
attr.add_modifier("health", bonus)

print(attr.get_value("health"))  # 120
```

**Template**: `basic_fighter_template.gd`  
**Demo**: `attribute_system_tutorial.gd`

---

### 2. **能力系统 (Ability Component)** - Combat模块
文件: `ComponentLibrary/Modules/Combat/Components/ability_component.gd`

**功能**: GAS风格的能力框架，管理能力的激活、冷却和消耗

**特性**:
- 能力激活流程: `can_activate()` → `activate()` → `_on_ability_activate()`
- 冷却时间管理
- 资源消耗（可集成AttributeSystem）
- 虚拟方法供子类覆盖
- 能力标签系统

**快速开始**:
```gdscript
var ability = AbilityComponent.new()
ability.set_cooldown_duration(5.0)
ability.set_ability_name("Fireball")

if ability.can_activate():
	ability.activate(target_position)
```

**Template**: `basic_fighter_template.gd`  
**Demo**: `combat_advanced_demo.gd`

---

### 3. **冷却系统 (Cooldown Component)** - Combat模块
文件: `ComponentLibrary/Modules/Combat/Components/cooldown_component.gd`

**功能**: 独立的冷却计时管理器，支持多个独立冷却

**特性**:
- 支持多个冷却ID同时运行
- 冷却进度查询 (0.0 - 1.0)
- 剩余时间查询
- 自动清理过期冷却

**快速开始**:
```gdscript
var cd = CooldownComponent.new()
cd.start_cooldown("attack", 2.0)

if not cd.is_on_cooldown("attack"):
	# 可以攻击
	cd.start_cooldown("attack", 2.0)
```

**集成**: AbilityComponent会自动使用此系统

---

### 4. **效果管理器 (Effect Manager)** - Combat模块
文件: `ComponentLibrary/Modules/Combat/Components/effect_manager.gd`

**功能**: Buff/Debuff管理系统，支持临时效果和周期性触发

**特性**:
- 效果堆叠或替换策略
- 周期性效果（每0.5秒触发一次伤害等）
- 效果自动过期清理
- 自定义效果回调

**快速开始**:
```gdscript
var effects = EffectManager.new()

var burn = EffectManager.EffectData.new()
burn.effect_name = "Burn"
burn.duration = 3.0
burn.tick_interval = 0.5
burn.on_tick = func(delta): take_damage(5)

effects.apply_effect(burn)
```

**Demo**: `combat_advanced_demo.gd`

---

### 5. **状态机 (State Machine)** - Movement模块
文件: `ComponentLibrary/Modules/Movement/Components/state_machine.gd`

**功能**: 通用有限状态机，支持自动状态转移条件检查

**特性**:
- 状态转移条件自动检查
- 进入/退出回调
- `_process`、`_physics_process`、`_input` 自动路由到当前状态
- 灵活的状态处理器设计

**快速开始**:
```gdscript
var fsm = StateMachine.new()
fsm.add_state("idle")
fsm.add_state("run")

fsm.add_transition("idle", "run", func():
	return Input.is_action_pressed("ui_right")
)

fsm.set_state("idle")
# 在_process中调用fsm.process(delta)
```

**Template**: `basic_player_template.gd`  
**Demo**: `movement_state_demo.gd`

---

### 6. **库存系统 (Inventory Component)** - GameLogic/RPG模块
文件: `ComponentLibrary/Modules/GameLogic/RPG/Components/inventory_component.gd`

**功能**: 物品库存管理系统，支持堆叠和移动

**特性**:
- 物品堆叠管理
- 物品搜索和排序
- 槽位限制
- 物品移动

**快速开始**:
```gdscript
var inventory = InventoryComponent.new()
inventory.set_slot_count(20)

var sword = InventoryComponent.ItemData.new("sword_001", "铁剑", 1)
sword.max_stack = 1
inventory.add_item(sword)

var potion = InventoryComponent.ItemData.new("potion", "药水", 5)
potion.max_stack = 10
inventory.add_item(potion)
```

**Template**: `basic_npc_template.gd`  
**Demo**: `rpg_systems_demo.gd`

---

### 7. **对话系统 (Dialogue System)** - UI模块
文件: `ComponentLibrary/Modules/UI/Components/dialogue_system.gd`

**功能**: 分支对话树系统，支持对话历史和条件判断

**特性**:
- 对话节点树结构
- 选项条件判断
- 对话历史记录
- 动态对话选项

**快速开始**:
```gdscript
var dialogue = DialogueSystem.new()

var scene1 = DialogueSystem.DialogueNode.new("start")
scene1.speaker = "NPC"
scene1.text = "你好！"
scene1.add_option("你好", "scene2")

dialogue.add_node(scene1)
dialogue.start_dialogue("start")
```

**Template**: `basic_npc_template.gd`  
**Demo**: `rpg_systems_demo.gd`

---

### 8. **任务系统 (Quest System)** - GameLogic/RPG模块
文件: `ComponentLibrary/Modules/GameLogic/RPG/Components/quest_system.gd`

**功能**: 任务管理系统，支持多目标和奖励

**特性**:
- 任务目标进度跟踪
- 任务状态管理 (AVAILABLE → ACCEPTED → COMPLETED)
- 任务奖励系统 (金币、经验、物品)
- 重复性任务控制

**快速开始**:
```gdscript
var quests = QuestSystem.new()

var quest = QuestSystem.QuestData.new("quest_001", "打败敌人", "击败5个哥布林")
quest.add_objective("击败哥布林", 5)
quest.reward.gold = 100
quest.reward.experience = 200

quests.add_available_quest(quest)
if quests.accept_quest("quest_001"):
	print("任务已接受！")
```

**Template**: `basic_npc_template.gd`  
**Demo**: `rpg_systems_demo.gd`

---

## 🎮 集成Template

### BasicFighterTemplate
完整集成了: 属性 + 能力 + 效果

```gdscript
var fighter = BasicFighterTemplate.new()
fighter.position = Vector2(100, 100)
add_child(fighter)

# 直接使用
fighter.take_damage(10)
fighter.apply_buff("Strength", 5.0, func(): pass)
print(fighter.debug_stats())
```

### BasicPlayerTemplate
完整集成了: 运动 + 属性 + 库存

```gdscript
var player = BasicPlayerTemplate.new()
add_child(player)
# 自动处理运动、属性、库存
```

### BasicNPCTemplate
完整集成了: 库存 + 任务 + 对话

```gdscript
var npc = BasicNPCTemplate.new()
npc.npc_name = "村长"
add_child(npc)
npc.start_dialogue()
```

---

## 🎯 Demo演示

### 1. AttributeSystemTutorial
展示属性系统和修饰符的完整用法

### 2. CombatAdvancedDemo
展示战斗系统的完整流程:
- 属性计算
- 伤害计算
- 效果应用

### 3. MovementStateDemo
展示状态机在运动系统中的应用:
- Idle → Run → Jump → Fall 状态转移

### 4. RPGSystemsDemo
展示RPG系统的完整集成:
- 库存管理
- 任务系统
- 对话交互

---

## 🚀 快速开始

### 步骤1: 选择你需要的系统
```gdscript
# 只需属性系统
var attr = AttributeSystem.new()
add_child(attr)

# 只需状态机
var fsm = StateMachine.new()
add_child(fsm)

# 完整集成（推荐）
var fighter = BasicFighterTemplate.new()
add_child(fighter)
```

### 步骤2: 创建你的系统子类
```gdscript
extends BasicFighterTemplate

func _populate_ability() -> void:
	# 自定义你的能力
	pass
```

### 步骤3: 集成到你的游戏
```gdscript
var player = YourCustomPlayer.new()
add_child(player)
```

---

## 💡 设计模式

### 1. 信号驱动
所有系统都使用信号进行通信，保持解耦:
```gdscript
attr_system.attribute_changed.connect(_on_attribute_changed)
ability.ability_activated.connect(_on_ability_activated)
```

### 2. 组件化
每个系统是独立的可选组件，可单独使用或组合

### 3. 虚拟方法
提供虚拟方法供子类覆盖自定义逻辑:
```gdscript
func _on_ability_activate() -> void:
	# 子类覆盖此方法
	pass
```

### 4. 数据驱动
使用数据类（如ModifierData、EffectData）分离数据和逻辑

---

## 📊 系统关系图

```
BasicFighterTemplate
├── AttributeSystem (属性)
├── AbilityComponent (能力)
│   └── CooldownComponent (冷却)
└── EffectManager (效果)

BasicPlayerTemplate
├── StateMachine (运动状态)
└── BasicFighterTemplate (战斗部分)

BasicNPCTemplate
├── InventoryComponent (库存)
├── QuestSystem (任务)
└── DialogueSystem (对话)
```

---

## 🔧 常见用法

### 创建可升级的属性
```gdscript
var strength = AttributeSystem.new()
strength.set_base_value("power", 10)

# 装备加成
var equipment = AttributeSystem.ModifierData.new(
	5, AttributeSystem.ModifierData.Type.ADDITIVE, "装备"
)
strength.add_modifier("power", equipment)

# 天赋加强
var talent = AttributeSystem.ModifierData.new(
	0.3, AttributeSystem.ModifierData.Type.PERCENTAGE, "天赋"
)
strength.add_modifier("power", talent)
```

### 创建复杂的状态转移
```gdscript
fsm.add_transition("idle", "attack", func():
	return Input.is_action_just_pressed("ui_attack") and can_attack()
)

fsm.add_transition("attack", "idle", func():
	return not is_attacking()
)
```

### 追踪多个冷却
```gdscript
var cd = CooldownComponent.new()
cd.start_cooldown("attack", 1.0)
cd.start_cooldown("spell", 3.0)
cd.start_cooldown("ultimate", 10.0)

print(cd.get_progress("attack"))   # 0.0 - 1.0
print(cd.get_remaining("spell"))   # 剩余秒数
```

---

## ⚠️ 注意事项

1. **性能**: 大量效果/修饰符会影响性能，建议使用对象池
2. **数据持久化**: 需要手动实现保存/加载功能
3. **网络同步**: 多人游戏时需要同步这些系统的状态
4. **调试**: 每个系统都有 `debug_*()` 方法用于调试

---

## 📝 文件结构

```
ComponentLibrary/
├── Core/
│   └── component_base.gd
├── Modules/
│   ├── Combat/
│   │   ├── Components/
│   │   │   ├── attribute_system.gd
│   │   │   ├── ability_component.gd
│   │   │   ├── cooldown_component.gd
│   │   │   └── effect_manager.gd
│   │   ├── Templates/
│   │   │   └── basic_fighter_template.gd
│   │   └── Demo/
│   │       ├── combat_advanced_demo.gd
│   │       └── attribute_system_tutorial.gd
│   ├── Movement/
│   │   ├── Components/
│   │   │   └── state_machine.gd
│   │   ├── Templates/
│   │   │   └── basic_player_template.gd
│   │   └── Demo/
│   │       └── movement_state_demo.gd
│   └── GameLogic/
│       └── RPG/
│           ├── Components/
│           │   ├── inventory_component.gd
│           │   ├── dialogue_system.gd
│           │   └── quest_system.gd
│           ├── Templates/
│           │   └── basic_npc_template.gd
│           └── Demo/
│               └── rpg_systems_demo.gd
└── Systems/
```

---

## 🎓 学习路径

1. 📖 阅读本 README
2. 📝 查看 Demo 代码
3. 🧪 运行 Demo 场景
4. 🔧 修改 Template 实现自己的系统
5. 🚀 集成到你的项目中

---

## 📞 支持

如有问题或建议，请查阅各组件文件中的详细注释和虚拟方法说明。

**版本**: 1.0  
**更新时间**: 2024年  
**推荐Godot版本**: 4.6+
