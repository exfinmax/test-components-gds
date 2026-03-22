extends Control

signal pack_finished(result: Dictionary)

const SAVE_MODULE_SCRIPT := preload("res://StarterPacks/UIPuzzle/UI/ui_puzzle_save_module.gd")
const PACK_ID := "ui_puzzle"
const EXPECTED_PATTERN :PackedInt32Array= ([0, 4, 8])
const EXPECTED_SEQUENCE :PackedStringArray= (["A", "C", "B"])

@onready var _status: Label = $Margin/Root/Header/StatusLabel
@onready var _tabs: TabContainer = $Margin/Root/Tabs
@onready var _code_input: LineEdit = $Margin/Root/Tabs/CodePad/VBox/CodeLine
@onready var _terminal_input: LineEdit = $Margin/Root/Tabs/Terminal/VBox/CommandLine
@onready var _document_preview: Label = $Margin/Root/Tabs/DocumentInspect/VBox/PreviewLabel
@onready var _pattern_grid: GridContainer = $Margin/Root/Tabs/PatternGrid/VBox/Grid
@onready var _circuit_label: Label = $Margin/Root/Tabs/CircuitLink/VBox/SequenceLabel
@onready var _summary: Label = $Margin/Root/Footer/SummaryLabel
@onready var _save_system: Node = get_node_or_null("/root/SaveSystem")

var _running_under_host: bool = false
var _save_module: ISaveModule = null
var _pending_import_state: Dictionary = {}
var _selected_document: String = ""
var _circuit_sequence: PackedStringArray = PackedStringArray()
var _solved := {
	"codepad": false,
	"pattern": false,
	"circuit": false,
	"terminal": false,
	"document": false,
}

func _ready() -> void:
	($Margin/Root/Header/Buttons/SaveButton as Button).pressed.connect(_save_slot)
	($Margin/Root/Header/Buttons/LoadButton as Button).pressed.connect(_load_slot)
	($Margin/Root/Header/Buttons/SuccessButton as Button).pressed.connect(_finish_success)
	($Margin/Root/Header/Buttons/FailButton as Button).pressed.connect(_finish_fail)
	($Margin/Root/Header/Buttons/BackButton as Button).pressed.connect(_finish_return)
	($Margin/Root/Tabs/CodePad/VBox/SubmitButton as Button).pressed.connect(_solve_codepad)
	($Margin/Root/Tabs/Terminal/VBox/RunButton as Button).pressed.connect(_solve_terminal)
	for index in range(_pattern_grid.get_child_count()):
		var button := _pattern_grid.get_child(index) as Button
		button.pressed.connect(_toggle_pattern.bind(index))
	($Margin/Root/Tabs/CircuitLink/VBox/Buttons/AButton as Button).pressed.connect(_append_circuit.bind("A"))
	($Margin/Root/Tabs/CircuitLink/VBox/Buttons/BButton as Button).pressed.connect(_append_circuit.bind("B"))
	($Margin/Root/Tabs/CircuitLink/VBox/Buttons/CButton as Button).pressed.connect(_append_circuit.bind("C"))
	($Margin/Root/Tabs/DocumentInspect/VBox/Choices/ArchivePhotoButton as Button).pressed.connect(_select_document.bind("archive_photo"))
	($Margin/Root/Tabs/DocumentInspect/VBox/Choices/SecurityMemoButton as Button).pressed.connect(_select_document.bind("security_memo"))
	($Margin/Root/Tabs/DocumentInspect/VBox/Choices/VisitorBadgeButton as Button).pressed.connect(_select_document.bind("visitor_badge"))
	_register_save_module()
	_update_summary()
	_apply_pending_import_state()

func start_pack(context: Dictionary) -> void:
	_running_under_host = true
	if not context.is_empty():
		import_pack_state(context.get("resume_state", context))

func export_pack_state() -> Dictionary:
	var state := _collect_puzzle_state()
	state["pack_id"] = PACK_ID
	state["status_text"] = _status.text
	return state

func import_pack_state(state: Dictionary) -> void:
	_pending_import_state = state.duplicate(true)
	_apply_pending_import_state()

func _register_save_module() -> void:
	if _save_system == null or not _save_system.has_method("register_module"):
		return
	_save_module = _save_system.get_module(PACK_ID)
	if _save_module == null:
		_save_module = SAVE_MODULE_SCRIPT.new(self)
		_save_system.register_module(_save_module)

func _save_slot() -> void:
	if _save_system == null or not _save_system.has_method("save_slot"):
		_status.text = "SaveSystem 不可用"
		return
	var ok := bool(_save_system.save_slot(1))
	_status.text = "UIPuzzle 保存槽位1 %s" % ("成功" if ok else "失败")

func _load_slot() -> void:
	if _save_system == null or not _save_system.has_method("load_slot"):
		_status.text = "SaveSystem 不可用"
		return
	var ok := bool(_save_system.load_slot(1))
	_status.text = "UIPuzzle 读取槽位1 %s" % ("成功" if ok else "失败")
	if ok:
		_update_summary()

func _solve_codepad() -> void:
	if _code_input.text.strip_edges() == "3142":
		_mark_solved("codepad", "CodePad 已解开。")
	else:
		_status.text = "CodePad 密码错误。"

func _toggle_pattern(index: int) -> void:
	var button := _pattern_grid.get_child(index) as Button
	button.text = "●" if button.button_pressed else "○"
	var active := PackedInt32Array()
	for i in range(_pattern_grid.get_child_count()):
		var child := _pattern_grid.get_child(i) as Button
		child.text = "●" if child.button_pressed else "○"
		if child.button_pressed:
			active.append(i)
	if active == EXPECTED_PATTERN:
		_mark_solved("pattern", "PatternGrid 已完成。")

func _append_circuit(node_id: String) -> void:
	_circuit_sequence.append(node_id)
	_circuit_label.text = "当前连接：%s" % ", ".join(_circuit_sequence)
	for i in range(_circuit_sequence.size()):
		if _circuit_sequence[i] != EXPECTED_SEQUENCE[i]:
			_circuit_sequence.clear()
			_circuit_label.text = "顺序错误，已重置。"
			_status.text = "CircuitLink 顺序错误。"
			return
	if _circuit_sequence.size() == EXPECTED_SEQUENCE.size():
		_mark_solved("circuit", "CircuitLink 已联通。")

func _solve_terminal() -> void:
	if _terminal_input.text.strip_edges().to_lower() == "unlock meta_portal":
		_mark_solved("terminal", "Terminal 指令已执行。")
	else:
		_status.text = "Terminal 指令不正确。"

func _select_document(document_id: String) -> void:
	_selected_document = document_id
	_document_preview.text = "当前证据：%s" % document_id
	if document_id == "archive_photo":
		_mark_solved("document", "DocumentInspect 找到了正确证据。")

func _mark_solved(key: String, message: String) -> void:
	_solved[key] = true
	_status.text = message
	_update_summary()

func _finish_success() -> void:
	if not _all_solved():
		_status.text = "还有未完成的解密模块。"
		return
	_finish_pack({
		"pack_id": PACK_ID,
		"outcome": "success",
		"state": export_pack_state(),
		"summary": "all_ui_puzzles_solved",
	})

func _finish_fail() -> void:
	_finish_pack({
		"pack_id": PACK_ID,
		"outcome": "fail",
		"state": export_pack_state(),
	})

func _finish_return() -> void:
	_finish_pack({
		"pack_id": PACK_ID,
		"outcome": "return",
		"state": export_pack_state(),
	})

func _finish_pack(result: Dictionary) -> void:
	if _running_under_host:
		pack_finished.emit(result)
		return
	SceneChangeBridge.change_scene("res://Test/test_main.tscn")

func _collect_puzzle_state() -> Dictionary:
	return {
		"current_tab": _tabs.current_tab,
		"solved": _solved.duplicate(true),
		"code_entry": _code_input.text,
		"terminal_text": _terminal_input.text,
		"selected_document": _selected_document,
	}

func _apply_puzzle_state(data: Dictionary) -> void:
	_tabs.current_tab = int(data.get("current_tab", 0))
	_solved = (data.get("solved", _solved) as Dictionary).duplicate(true)
	_code_input.text = str(data.get("code_entry", ""))
	_terminal_input.text = str(data.get("terminal_text", ""))
	_selected_document = str(data.get("selected_document", ""))
	_document_preview.text = "当前证据：%s" % (_selected_document if _selected_document != "" else "未选择")
	for index in range(_pattern_grid.get_child_count()):
		var button := _pattern_grid.get_child(index) as Button
		button.button_pressed = EXPECTED_PATTERN.has(index) and bool(_solved.get("pattern", false))
		button.text = "●" if button.button_pressed else "○"
	if bool(_solved.get("circuit", false)):
		_circuit_sequence = EXPECTED_SEQUENCE.duplicate()
		_circuit_label.text = "当前连接：%s" % ", ".join(_circuit_sequence)
	else:
		_circuit_sequence.clear()
		_circuit_label.text = "当前连接："
	_update_summary()

func _apply_pending_import_state() -> void:
	if _pending_import_state.is_empty():
		return
	_apply_puzzle_state(_pending_import_state)
	var status_text := str(_pending_import_state.get("status_text", ""))
	if status_text != "":
		_status.text = status_text
	_pending_import_state.clear()

func _update_summary() -> void:
	var solved_count := 0
	for value in _solved.values():
		if bool(value):
			solved_count += 1
	_summary.text = "已完成：%d / 5" % solved_count
	if _all_solved():
		_status.text = "全部 UI 解密已完成，可以提交成功结果。"

func _all_solved() -> bool:
	for value in _solved.values():
		if not bool(value):
			return false
	return true
