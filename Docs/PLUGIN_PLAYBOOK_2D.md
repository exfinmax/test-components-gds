# 2D Plugin Playbook

This project now treats a small set of third-party plugins as the default 2D toolchain.

## Core stack

### enhance_save_system + input display module
- Use this for settings pages, rebinding, save/load, and input prompt text.
- Keep all input persistence inside `enhance_save_system`.
- Do not save bindings separately in gameplay scenes.
- Preferred use cases: pause menu, settings menu, accessibility options, platform-specific prompt display.

### scene_manager
- Use this for full scene changes, loading screens, and scene-level transitions.
- Preferred use cases: room changes, chapter jumps, returning from packs to launcher, loading next meta-game segment.
- Keep `SceneFlow2D` as the host protocol layer for pack mount/resume; let the plugin handle whole-scene changes.

### sound_manager
- Use this for global BGM/SFX playback and bus volume control.
- Preferred use cases: menu click sounds, layered BGM, combat music changes, ambient loops.
- Keep game settings synced through `SettingsModule`; do not build a second audio settings store.

### godot_state_charts
- Use this for complex, inspectable gameplay state graphs.
- Preferred use cases: boss phases, dialogue flow with conditions, puzzle progression, multi-step interaction logic.
- Do not replace every lightweight state check with charts. Keep simple movement/UI state code lightweight.

### phantom_camera
- Use this for Camera2D follow, tweening, limits, and shake.
- Preferred use cases: top-down action rooms, platformer follow cameras, cutscene framing, boss intro pans.
- This repo uses a local 2D-only fork. Avoid reintroducing 3D classes into it.

### gdfxr
- Use this for rapid prototype sound effects and placeholder UI/feedback sounds.
- Preferred use cases: button clicks, pickups, hit confirms, puzzle success/fail blips.
- Replace with authored audio later if the game needs a stronger audio identity.

### godotsize
- Use this before builds and content drops.
- Preferred use cases: tracking export growth, spotting oversized assets, checking plugin impact on package size.

### todo_manager_godot4
- Use this to keep local code TODOs visible in-editor.
- Preferred use cases: short-horizon cleanup, follow-up implementation notes, migration tasks.
- Do not use it as a substitute for long-term production planning.

## Genre recommendations

### Platformer action
- `enhance_save_system`
- `sound_manager`
- `phantom_camera`
- `godot_state_charts`
- `scene_manager`

### Top-down action
- `enhance_save_system`
- `phantom_camera`
- `sound_manager`
- `godot_state_charts`
- `scene_manager`

### Narrative exploration
- `dialogue_manager`
- `enhance_save_system`
- `scene_manager`
- `sound_manager`
- `godot_state_charts`

### UI puzzle / meta UI game
- `enhance_save_system`
- `scene_manager`
- `sound_manager`
- `godot_state_charts`
- `gdfxr`

### Meta-game host
- `enhance_save_system`
- `scene_manager`
- `sound_manager`
- `godot_state_charts`
- `godotsize`

## Practical defaults
- Prefer plugins for cross-scene systems, editor tooling, and mature runtime infrastructure.
- Prefer local thin facades when starter packs need stable project-level APIs.
- Keep 2D-first decisions unless a specific game segment needs 3D presentation.
