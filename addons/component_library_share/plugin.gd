@tool
extends EditorPlugin

const TYPE_CONFIGS := [
	{
		"name": "GlobalEventBus",
		"base": "Node",
		"path": "res://ComponentLibrary/Dependencies/event_bus.gd",
	},
	{
		"name": "GlobalObjectPool",
		"base": "Node",
		"path": "res://ComponentLibrary/Dependencies/object_pool.gd",
	},
	{
		"name": "GlobalTimeController",
		"base": "Node",
		"path": "res://ComponentLibrary/Dependencies/time_controller.gd",
	},
	{
		"name": "LocalTimeDomainDependency",
		"base": "Node",
		"path": "res://ComponentLibrary/Dependencies/local_time_domain.gd",
	},
	{
		"name": "ProjectileEmitterComponent",
		"base": "Node2D",
		"path": "res://ComponentLibrary/Packs/Shooter/Components/projectile_emitter_component.gd",
	},
	{
		"name": "CooldownComponent",
		"base": "Node",
		"path": "res://ComponentLibrary/Packs/Foundation/Components/cooldown_component.gd",
	},
	{
		"name": "TriggerRouterComponent",
		"base": "Node",
		"path": "res://ComponentLibrary/Packs/Action/Components/trigger_router_component.gd",
	},
	{
		"name": "TimelineSwitchComponent",
		"base": "Node2D",
		"path": "res://ComponentLibrary/Packs/Time/Components/timeline_switch_component.gd",
	},
	{
		"name": "UIPageStateComponent",
		"base": "Node",
		"path": "res://ComponentLibrary/Packs/UI/Components/ui_page_state_component.gd",
	},
	{
		"name": "ImpactVFXComponent",
		"base": "Node2D",
		"path": "res://ComponentLibrary/Packs/VFX/Components/impact_vfx_component.gd",
	},
	{
		"name": "AttributeSetComponent",
		"base": "Node",
		"path": "res://ComponentLibrary/Packs/RPG/Components/attribute_set_component.gd",
	},
	{
		"name": "ProductionQueueComponent",
		"base": "Node",
		"path": "res://ComponentLibrary/Packs/Strategy/Components/production_queue_component.gd",
	},
	{
		"name": "StatusEffectComponent",
		"base": "Node",
		"path": "res://ComponentLibrary/Packs/Survival/Components/status_effect_component.gd",
	},
	{
		"name": "DeckDrawComponent",
		"base": "Node",
		"path": "res://ComponentLibrary/Packs/Card/Components/deck_draw_component.gd",
	},
	{
		"name": "SequenceSwitchComponent",
		"base": "Node",
		"path": "res://ComponentLibrary/Packs/Puzzle/Components/sequence_switch_component.gd",
	},
	{
		"name": "WeightedSpawnTableComponent",
		"base": "Node",
		"path": "res://ComponentLibrary/Packs/Roguelike/Components/weighted_spawn_table_component.gd",
	},
	{
		"name": "CoyoteJumpComponent",
		"base": "Node",
		"path": "res://ComponentLibrary/Packs/Platformer/Components/coyote_jump_component.gd",
	},
	{
		"name": "LapCheckpointComponent",
		"base": "Node",
		"path": "res://ComponentLibrary/Packs/Racing/Components/lap_checkpoint_component.gd",
	},
	{
		"name": "GridPlacementComponent",
		"base": "Node",
		"path": "res://ComponentLibrary/Packs/Builder/Components/grid_placement_component.gd",
	},
]

var _registered_types: Array[String] = []

func _enter_tree() -> void:
	var icon := _load_icon()
	for config in TYPE_CONFIGS:
		var type_name: String = config["name"]
		var base_name: String = config["base"]
		var script_path: String = config["path"]
		var script := load(script_path)
		if script == null:
			push_warning("[component_library_share] script missing: %s" % script_path)
			continue
		add_custom_type(type_name, base_name, script, icon)
		_registered_types.append(type_name)

func _exit_tree() -> void:
	for type_name in _registered_types:
		remove_custom_type(type_name)
	_registered_types.clear()

func _load_icon() -> Texture2D:
	var maybe_icon := load("res://icon.svg")
	if maybe_icon is Texture2D:
		return maybe_icon
	return null
