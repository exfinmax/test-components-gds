class_name IllustrationModule
extends BalloonModule
## ════════════════════════════════════════════════════════════════
## IllustrationModule — 立绘模块
## ════════════════════════════════════════════════════════════════
##
## 持有 IllustrationManager 引用，管理立绘显示与焦点。
## 解析对话行中的 expression:{key} 和 position:{left|right|center} 标签。
## ════════════════════════════════════════════════════════════════

@export_group("立绘设置")
## 淡入淡出时长（秒）
@export var fade_duration: float = 0.3

## IllustrationManager 节点引用（由场景配置）
var illustration_manager: IllustrationManager

# ════════════════════════════════════════════════════════════════
# BalloonModule 接口
# ════════════════════════════════════════════════════════════════

func get_module_name() -> String:
	return "illustration"

func on_dialogue_line_changed(line: DialogueLine) -> void:
	if not is_instance_valid(illustration_manager):
		return
	
	# 更新说话角色焦点
	if not line.character.is_empty():
		illustration_manager.set_focus_by_name(line.character)
	
	# 解析标签
	var expression := ""
	var position := IllustrationManager.IllustrationPosition.LEFT
	var has_position := false
	
	for tag in line.tags:
		var normalized := tag.strip_edges().lstrip("#")
		if normalized.begins_with("expression:"):
			var parts := normalized.split(":")
			if parts.size() >= 2:
				expression = parts[1]
		elif normalized.begins_with("position:"):
			var parts := normalized.split(":")
			if parts.size() >= 2:
				has_position = true
				match parts[1].to_lower():
					"right":  position = IllustrationManager.IllustrationPosition.RIGHT
					"center": position = IllustrationManager.IllustrationPosition.CENTER
					_:        position = IllustrationManager.IllustrationPosition.LEFT
	
	# 切换表情
	if not expression.is_empty():
		illustration_manager.switch_expression(position, expression)

func on_dialogue_ended() -> void:
	if not is_instance_valid(illustration_manager):
		return
	illustration_manager.reset_all()

# ════════════════════════════════════════════════════════════════
# 公共 API
# ════════════════════════════════════════════════════════════════

## 切换指定位置的立绘资源
func switch_illustration(position: int, resource: LiHui, default_key: String = "ax") -> void:
	if not is_instance_valid(illustration_manager):
		return
	illustration_manager.switch_illustration(position, resource, default_key)

## 显示立绘（带动画）
func show_illustration(position: int, animate: bool = true) -> void:
	if not is_instance_valid(illustration_manager):
		return
	illustration_manager.show_illustration(position, animate)

## 隐藏立绘（带动画）
func hide_illustration(position: int, animate: bool = true) -> void:
	if not is_instance_valid(illustration_manager):
		return
	illustration_manager.hide_illustration(position, animate)
