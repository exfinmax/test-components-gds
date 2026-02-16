extends Resource
class_name BuffEffect
## Buff 效果定义资源 - 描述一个 Buff/Debuff 的完整行为
##
## 什么是 Buff？
##   Buff 就是"临时效果"。比如：
##     - 吃了蘑菇 → 速度 x1.5，持续 5 秒（加速 Buff）
##     - 被冰冻 → 速度 x0，持续 2 秒（减速 Debuff）
##     - 进入时间慢放区 → 时间缩放 x0.3（时间 Debuff）
##     - 无敌星星 → 免疫伤害 3 秒（无敌 Buff）
##
## 使用方式：
##   在编辑器中创建 BuffEffect 资源 (.tres 文件)
##   或代码中 BuffEffect.new() 然后设置属性

## Buff 的唯一标识名
@export var id: StringName = &""

## 显示名称（UI 用）
@export var display_name: String = ""

## Buff 类型
enum BuffType { 
	SPEED_MULTIPLY,       ## 速度倍率
	SPEED_ADD,            ## 速度加值
	GRAVITY_MULTIPLY,     ## 重力倍率
	JUMP_MULTIPLY,        ## 跳跃力倍率
	DAMAGE_MULTIPLY,      ## 伤害倍率
	INVINCIBLE,           ## 无敌（免疫伤害）
	FREEZE,               ## 冻结（无法行动）
	TIME_SCALE,           ## 个体时间缩放
	CUSTOM,               ## 自定义（通过 custom_key 指定）
}
@export var type: BuffType = BuffType.SPEED_MULTIPLY

## 效果值（含义取决于 type）
## MULTIPLY 类型：1.0 = 无变化，1.5 = 增加 50%，0.5 = 减少 50%
## ADD 类型：直接加减
## INVINCIBLE/FREEZE：无视此值
@export var value: float = 1.0

## 持续时间（秒），-1 = 永久直到手动移除
@export var duration: float = 5.0

## 最大叠加层数（1 = 不可叠加）
@export var max_stacks: int = 1

## 叠加时是否刷新持续时间
@export var refresh_on_stack: bool = true

## 自定义键名（type = CUSTOM 时使用）
@export var custom_key: StringName = &""

## 图标（UI 显示用）
@export var icon: Texture2D

## 是否是负面效果
@export var is_debuff: bool = false


## 快速创建 Buff 的工厂方法
static func create(buff_id: StringName, buff_type: BuffType, val: float, dur: float, stacks: int = 1) -> BuffEffect:
	var buff := BuffEffect.new()
	buff.id = buff_id
	buff.type = buff_type
	buff.value = val
	buff.duration = dur
	buff.max_stacks = stacks
	return buff
