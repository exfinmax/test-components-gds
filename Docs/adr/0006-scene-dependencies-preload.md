# 0006 - Scene dependency preload for ComponentLibrary demos

## Context
Scenes in `ComponentLibrary/Demos` reference scripts that in turn extend
`ComponentBase` or `CharacterComponentBase`. When the editor opens a scene,
those base classes must be loaded first or the script can't be parsed and the
scene fails to open.

The project structure places the base classes under
`ComponentLibrary/Dependencies`, but they are not automatically imported when a
single demo scene is loaded standalone. Previous attempts to fix the issue by
adding `tool` keywords or editing only the child scripts did not solve the
problem because the editor still needed a direct dependency entry in the scene
file.

## Decision
Add explicit `ext_resource` entries for the base class scripts in every demo
scene (and in the template scenes). This ensures Godot will load those
resources before it tries to instantiate any node relying on them.

The entries do not need to be used by any node; their presence is solely to
force the editor to preload the scripts.

Example patch applied across all demos:

```diff
[ext_resource type="Script" path="res://ComponentLibrary/Demos/Action/action_demo.gd" id="1"]
+ [ext_resource type="Script" path="res://ComponentLibrary/Dependencies/component_base.gd" id="99"]
+ [ext_resource type="Script" path="res://ComponentLibrary/Dependencies/character_component_base.gd" id="100"]
```

## Consequences
- Scenes become self‑sufficient; they can be opened individually without
  loading the entire library.
- Slight increase in scene file size; negligible.
- Future demos must follow the same pattern when they add new base-class
  dependencies.

If the base classes move, the patch will need updating; the ADR documents this
manual step.
