## 任务系统 - 任务管理和跟踪
##
## 特性：
## - 任务的创建、接受、完成
## - 任务阶段系统
## - 任务奖励
## - 任务进度跟踪
##
## 使用示例：
##   var quest = QuestSystem.new()
##   var new_quest = QuestData.new("Rescue", "Rescue the villagers")
##   new_quest.add_objective("Find 5 survivors")
##   quest.accept_quest(new_quest)
##
extends Node
class_name QuestSystem

## 任务目标
class QuestObjective:
	var description: String = ""
	var target_count: int = 1
	var current_count: int = 0
	var completed: bool = false
	
	func _init(p_description: String = "", p_target: int = 1) -> void:
		description = p_description
		target_count = p_target
	
	func is_completed() -> bool:
		return current_count >= target_count
	
	func progress() -> void:
		current_count += 1
		if current_count >= target_count:
			completed = true

## 任务奖励
class QuestReward:
	var gold: int = 0
	var experience: int = 0
	var items: Dictionary = {}  # item_id -> quantity
	
	func _init(p_gold: int = 0, p_xp: int = 0) -> void:
		gold = p_gold
		experience = p_xp

## 任务数据
class QuestData:
	enum QuestState { AVAILABLE, ACCEPTED, IN_PROGRESS, COMPLETED, FAILED }
	
	var quest_id: String = ""
	var quest_name: String = ""
	var description: String = ""
	var state: QuestState = QuestState.AVAILABLE
	var objectives: Array[QuestObjective] = []
	var reward: QuestReward = QuestReward.new()
	var level_requirement: int = 1
	var is_repeatable: bool = false
	var is_main_quest: bool = false
	
	func _init(p_id: String = "", p_name: String = "", p_desc: String = "") -> void:
		quest_id = p_id
		quest_name = p_name
		description = p_desc
	
	func add_objective(description: String, target: int = 1) -> QuestObjective:
		var objective = QuestObjective.new(description, target)
		objectives.append(objective)
		return objective
	
	func is_completed() -> bool:
		if objectives.is_empty():
			return true
		for objective in objectives:
			if not objective.is_completed():
				return false
		return true
	
	func get_progress() -> float:
		if objectives.is_empty():
			return 1.0
		var completed_count = 0
		for objective in objectives:
			if objective.is_completed():
				completed_count += 1
		return float(completed_count) / float(objectives.size())

## 活跃任务列表
var active_quests: Dictionary[String, QuestData] = {}

## 已完成任务列表
var completed_quests: Array[String] = []

## 可用任务列表
var available_quests: Dictionary[String, QuestData] = {}

## 任务信号
signal quest_added(quest: QuestData)
signal quest_accepted(quest: QuestData)
signal quest_progress(quest: QuestData)
signal quest_completed(quest: QuestData)
signal quest_failed(quest: QuestData)
signal objective_completed(quest: QuestData, objective: QuestObjective)

func _ready() -> void:
	pass

## 添加可用任务
func add_available_quest(quest: QuestData) -> void:
	available_quests[quest.quest_id] = quest
	quest_added.emit(quest)

## 接受任务
func accept_quest(quest_id: String) -> bool:
	if not quest_id in available_quests:
		push_error("Quest '%s' not available" % quest_id)
		return false
	
	var quest = available_quests[quest_id]
	quest.state = QuestData.QuestState.ACCEPTED
	
	active_quests[quest_id] = quest
	quest_accepted.emit(quest)
	
	return true

## 推进目标
func progress_objective(quest_id: String, objective_index: int) -> bool:
	if not quest_id in active_quests:
		return false
	
	var quest = active_quests[quest_id]
	if objective_index < 0 or objective_index >= quest.objectives.size():
		return false
	
	var objective = quest.objectives[objective_index]
	objective.progress()
	quest_progress.emit(quest)
	
	if objective.is_completed():
		objective_completed.emit(quest, objective)
	
	# 检查任务是否完成
	if quest.is_completed():
		complete_quest(quest_id)
	
	return true

## 完成任务
func complete_quest(quest_id: String) -> bool:
	if not quest_id in active_quests:
		return false
	
	var quest = active_quests[quest_id]
	quest.state = QuestData.QuestState.COMPLETED
	
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	
	quest_completed.emit(quest)
	
	return true

## 失败任务
func fail_quest(quest_id: String) -> bool:
	if not quest_id in active_quests:
		return false
	
	var quest = active_quests[quest_id]
	quest.state = QuestData.QuestState.FAILED
	
	active_quests.erase(quest_id)
	quest_failed.emit(quest)
	
	return true

## 获取活跃任务
func get_active_quests() -> Dictionary:
	return active_quests.duplicate()

## 检查任务是否活跃
func is_quest_active(quest_id: String) -> bool:
	return quest_id in active_quests

## 检查任务是否已完成
func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quests

## 获取任务进度
func get_quest_progress(quest_id: String) -> float:
	if not quest_id in active_quests:
		return 0.0
	return active_quests[quest_id].get_progress()

## 获取已完成的任务数
func get_completed_quest_count() -> int:
	return completed_quests.size()

## 获取活跃任务数
func get_active_quest_count() -> int:
	return active_quests.size()

## 调试：输出任务信息
func debug_quests() -> String:
	var output = "=== Quests ===\n"
	output += "Active: %d\n" % active_quests.size()
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		output += "  [%s] %s (%.0f%%)\n" % [quest_id, quest.quest_name, quest.get_progress() * 100]
	output += "Completed: %d\n" % completed_quests.size()
	return output
