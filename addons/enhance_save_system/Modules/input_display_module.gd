class_name InputDisplayModule
extends Node

signal device_changed(device: String, device_index: int)

const DEVICE_KEYBOARD := "keyboard"
const DEVICE_XBOX := "xbox"
const DEVICE_SWITCH := "switch"
const DEVICE_PLAYSTATION := "playstation"
const DEVICE_STEAMDECK := "steamdeck"
const DEVICE_GENERIC := "generic"

const XBOX_BUTTON_LABELS := ["A", "B", "X", "Y", "Back", "Guide", "Start", "Left Stick", "Right Stick", "LB", "RB", "Up", "Down", "Left", "Right", "Share", "Paddle 1", "Paddle 2", "Paddle 3", "Paddle 4"]
const SWITCH_BUTTON_LABELS := ["B", "A", "Y", "X", "Minus", "", "Plus", "Left Stick", "Right Stick", "L", "R", "Up", "Down", "Left", "Right", "Capture"]
const PLAYSTATION_BUTTON_LABELS := ["Cross", "Circle", "Square", "Triangle", "Create", "PS", "Options", "L3", "R3", "L1", "R1", "Up", "Down", "Left", "Right", "Microphone", "", "", "", "", "Touchpad"]
const STEAMDECK_BUTTON_LABELS := ["A", "B", "X", "Y", "View", "?", "Options", "Left Stick", "Right Stick", "L1", "R1", "Up", "Down", "Left", "Right", "", "", "", "", ""]

static var instance: InputDisplayModule

var deadzone: float = 0.5
var mouse_motion_threshold: int = 100
var device: String = DEVICE_KEYBOARD
var device_index: int = -1
var last_known_joypad_device: String = DEVICE_GENERIC

func _ready() -> void:
	instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	device = _guess_device_name()
	device_index = 0 if Input.get_connected_joypads().size() > 0 else -1

func _input(event: InputEvent) -> void:
	var next_device := device
	var next_index := device_index
	if event is InputEventKey or event is InputEventMouseButton or (event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length_squared() > mouse_motion_threshold):
		next_device = DEVICE_KEYBOARD
		next_index = -1
	elif event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > deadzone):
		next_device = _get_simplified_device_name(Input.get_joy_name(event.device))
		next_index = event.device
		last_known_joypad_device = next_device
	if next_device != device or next_index != device_index:
		device = next_device
		device_index = next_index
		device_changed.emit(device, device_index)

func get_current_input_device() -> String:
	var settings := _get_settings_module()
	if settings != null:
		var override_value := str(settings.get_value("input_device_override", "auto"))
		if override_value != "" and override_value != "auto":
			return override_value
	return device

func get_action_prompt_text(action: String, prefer_current_device: bool = true) -> String:
	var prompt := get_action_prompt(action, prefer_current_device)
	return str(prompt.get("text", ""))

func get_action_prompt(action: String, prefer_current_device: bool = true) -> Dictionary:
	var target_device := get_current_input_device() if prefer_current_device else device
	var events := _get_action_events(action)
	if events.is_empty():
		return {"device": target_device, "text": "", "icon_key": ""}
	var chosen := _pick_event_for_device(events, target_device)
	if chosen == null:
		chosen = events[0]
	return {
		"device": target_device,
		"text": get_label_for_input(chosen),
		"icon_key": _make_icon_key(chosen, target_device),
	}

func get_input_display_preferences() -> Dictionary:
	var settings := _get_settings_module()
	if settings == null:
		return {
			"input_device_override": "auto",
			"input_prompt_style": "label",
			"show_input_icons": false,
		}
	return {
		"input_device_override": str(settings.get_value("input_device_override", "auto")),
		"input_prompt_style": str(settings.get_value("input_prompt_style", "label")),
		"show_input_icons": bool(settings.get_value("show_input_icons", false)),
	}

func set_input_display_preference(key: String, value: Variant) -> void:
	var settings := _get_settings_module()
	if settings == null:
		return
	settings.set_value(key, value)

func get_label_for_input(input_event: InputEvent) -> String:
	if input_event == null:
		return ""
	if input_event is InputEventKey:
		var key_event := input_event as InputEventKey
		if key_event.physical_keycode > 0:
			var keycode := DisplayServer.keyboard_get_keycode_from_physical(key_event.physical_keycode) if DisplayServer.keyboard_get_current_layout() > -1 else key_event.physical_keycode
			return OS.get_keycode_string(keycode)
		if key_event.keycode > 0:
			return OS.get_keycode_string(key_event.keycode)
		return key_event.as_text()
	if input_event is InputEventMouseButton:
		match (input_event as InputEventMouseButton).button_index:
			MOUSE_BUTTON_LEFT:
				return "Mouse Left"
			MOUSE_BUTTON_MIDDLE:
				return "Mouse Middle"
			MOUSE_BUTTON_RIGHT:
				return "Mouse Right"
		return "Mouse Button %d" % (input_event as InputEventMouseButton).button_index
	if input_event is InputEventJoypadButton:
		var button_event := input_event as InputEventJoypadButton
		var labels := _get_joypad_labels(last_known_joypad_device if last_known_joypad_device != "" else get_current_input_device())
		if button_event.button_index >= 0 and button_event.button_index < labels.size():
			return labels[button_event.button_index]
		return "Button %d" % button_event.button_index
	if input_event is InputEventJoypadMotion:
		var motion := input_event as InputEventJoypadMotion
		match motion.axis:
			JOY_AXIS_LEFT_X:
				return "Left Stick %s" % ("Left" if motion.axis_value < 0 else "Right")
			JOY_AXIS_LEFT_Y:
				return "Left Stick %s" % ("Up" if motion.axis_value < 0 else "Down")
			JOY_AXIS_RIGHT_X:
				return "Right Stick %s" % ("Left" if motion.axis_value < 0 else "Right")
			JOY_AXIS_RIGHT_Y:
				return "Right Stick %s" % ("Up" if motion.axis_value < 0 else "Down")
			JOY_AXIS_TRIGGER_LEFT:
				return "Left Trigger"
			JOY_AXIS_TRIGGER_RIGHT:
				return "Right Trigger"
	return input_event.as_text()

func _get_action_events(action: String) -> Array[InputEvent]:
	if KeybindingModule.instance != null:
		return KeybindingModule.instance.get_action_events(action)
	if InputMap.has_action(action):
		return InputMap.action_get_events(action)
	return []

func _pick_event_for_device(events: Array[InputEvent], target_device: String) -> InputEvent:
	for input_event in events:
		if target_device == DEVICE_KEYBOARD and (input_event is InputEventKey or input_event is InputEventMouseButton):
			return input_event
		if target_device != DEVICE_KEYBOARD and (input_event is InputEventJoypadButton or input_event is InputEventJoypadMotion):
			return input_event
	for input_event in events:
		if input_event is InputEventKey or input_event is InputEventMouseButton:
			return input_event
	for input_event in events:
		if input_event is InputEventJoypadButton or input_event is InputEventJoypadMotion:
			return input_event
	return null

func _get_settings_module() -> SettingsModule:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var save_system := tree.root.get_node_or_null("SaveSystem")
	if save_system != null and save_system.has_method("get_module"):
		return save_system.get_module("settings") as SettingsModule
	return null

func _guess_device_name() -> String:
	if Input.get_connected_joypads().is_empty():
		return DEVICE_KEYBOARD
	return _get_simplified_device_name(Input.get_joy_name(Input.get_connected_joypads()[0]))

func _get_simplified_device_name(raw_name: String) -> String:
	var lower := raw_name.to_lower()
	if "xbox" in lower or "xinput" in lower:
		return DEVICE_XBOX
	if "sony" in lower or "dualshock" in lower or "dualsense" in lower or "ps4" in lower or "ps5" in lower:
		return DEVICE_PLAYSTATION
	if "switch" in lower or "joy-con" in lower:
		return DEVICE_SWITCH
	if "steam" in lower:
		return DEVICE_STEAMDECK
	return DEVICE_GENERIC

func _get_joypad_labels(target_device: String) -> Array:
	match target_device:
		DEVICE_SWITCH:
			return SWITCH_BUTTON_LABELS
		DEVICE_PLAYSTATION:
			return PLAYSTATION_BUTTON_LABELS
		DEVICE_STEAMDECK:
			return STEAMDECK_BUTTON_LABELS
		_:
			return XBOX_BUTTON_LABELS

func _make_icon_key(input_event: InputEvent, target_device: String) -> String:
	if input_event is InputEventJoypadButton:
		return "%s_button_%d" % [target_device, (input_event as InputEventJoypadButton).button_index]
	if input_event is InputEventJoypadMotion:
		return "%s_axis_%d" % [target_device, (input_event as InputEventJoypadMotion).axis]
	if input_event is InputEventMouseButton:
		return "mouse_%d" % (input_event as InputEventMouseButton).button_index
	if input_event is InputEventKey:
		var key_event := input_event as InputEventKey
		return "key_%s" % OS.get_keycode_string(key_event.keycode if key_event.keycode > 0 else key_event.physical_keycode).to_lower()
	return ""
