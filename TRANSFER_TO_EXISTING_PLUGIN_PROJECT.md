# Transfer To Existing Plugin Project

This transfer package is intended for a target Godot project that already has these plugins installed and enabled:

- `addons/dialogue_manager`
- `addons/enhance_save_system`
- `addons/simple-gui-transitions`

## Copy Into The Target Project

Copy these folders from the package into the target project root and keep the same relative paths:

- `StarterPacks/`
- `ComponentLibrary/Core/`
- `ComponentLibrary/Systems/MetaFlow/`
- `ComponentLibrary/Systems/SceneFlow2D/`
- `ComponentLibrary/Systems/Interaction2D/`
- `ComponentLibrary/Systems/Camera2D/`
- `ComponentLibrary/Systems/ObjectiveFlag/`
- `ComponentLibrary/Modules/UI/`
- `ComponentLibrary/Modules/Movement/`
- `ComponentLibrary/Modules/Combat/`
- `ComponentLibrary/Modules/GameLogic/Action/`

## Required Autoloads

The target project should already expose these autoloads:

- `DialogueManager`
- `SaveSystem`
- `GuiTransitions`

Add these project autoloads if they do not already exist:

- `EventBus` -> `res://ComponentLibrary/Core/events/event_bus.gd`
- `ObjectPool` -> `res://ComponentLibrary/Core/pools/object_pool.gd`

## Required Input Actions

Make sure the target project has these actions:

- `ui_accept`
- `ui_cancel`
- `ui_page_down`
- `ui_page_up`
- `ui_text_submit`
- `left`
- `right`
- `up`
- `down`
- `jump`
- `dash`
- `interact`

## Important Plugin-Side Dependency

`StarterPacks/NarrativeUI` currently depends on:

- `res://addons/dialogue_manager/modify_test/modular_balloon.tscn`
- `res://addons/dialogue_manager/modify_test/dialogue_save_module.gd`

So the target project's installed `dialogue_manager` plugin must already include your `modify_test` additions, not only the upstream base plugin.

## Recommended Entry Points

- `res://StarterPacks/Meta2DHost/Main.tscn`
- `res://StarterPacks/NarrativeUI/Main.tscn`
- `res://StarterPacks/PlatformerAction/Main.tscn`
- `res://StarterPacks/TopDownAction/Main.tscn`
- `res://StarterPacks/UIPuzzle/Main.tscn`
