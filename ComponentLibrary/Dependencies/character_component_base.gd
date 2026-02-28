@abstract
extends ComponentBase
class_name CharacterComponentBase
## 角色组件基类 - 所有角色能力组件的抽象基类
##
## 继承自 ComponentBase，额外提供：
##   - character: CharacterBody2D 自动绑定
##   - self_driven 双驱动模式（自驱 / 外部 tick）
##   - physics_tick / tick 外部驱动接口
##
## 使用方式：
##   1. 继承此类创建具体组件
##   2. 将组件作为 CharacterBody2D 的子节点
##   3. 组件自动获取 character 引用
##   4. 通过 enabled 控制启用/禁用（继承自 ComponentBase）
##   5. 通过 get_component_data() 获取组件自省信息
##
## 驱动模式：
##   self_driven = true  → 组件内部自行 _process/_physics_process（默认，适合独立测试）
##   self_driven = false → 组件关闭内部 process，由 Character 统一调用 tick/physics_tick
##                         Character 可以传入补偿后的 delta（如时间免疫的玩家）
##
## 可单独测试：将组件挂在任意 CharacterBody2D 下即可运行

## 组件所属的角色（自动从 owner 获取）
var character: CharacterBody2D

## 是否自驱动（true = 内部 _process/_physics_process；false = 由外部调用 tick/physics_tick）
@export var self_driven: bool = true

func _ready() -> void:
	_auto_bind_character()
	if not self_driven:
		set_process(false)
		set_physics_process(false)
	_component_ready()

## 自动绑定角色引用
func _auto_bind_character() -> void:
	if owner is CharacterBody2D:
		character = owner as CharacterBody2D
	elif get_parent() is CharacterBody2D:
		character = get_parent() as CharacterBody2D
	else:
		push_warning("[%s] 未找到 CharacterBody2D，组件可能无法正常工作" % name)

#region 外部驱动接口

## 物理帧驱动 - 子类重写此方法（替代在 _physics_process 中写逻辑）
## Character 统一调用，可传入补偿后的 delta
func physics_tick(delta: float) -> void:
	pass

## 帧驱动 - 子类重写此方法（替代在 _process 中写逻辑）
func tick(delta: float) -> void:
	pass

#endregion

## 获取组件自省数据 - 子类必须重写
@abstract func get_component_data() -> Dictionary


## 按类型查找同级组件（角色专用别名，搜索 character 的子节点）
func find_component(type: GDScript) -> CharacterComponentBase:
	if not character: return null
	for child in get_parent().get_children():
		if is_instance_of(child, type):
			return child as CharacterComponentBase
	return null
