---
summary: "为了让 ComponentLibrary 场景在 Godot 中都能打开，给所有继承 ComponentBase/CharacterComponentBase 的脚本显式 preload 了基础脚本。"
created: 2026-02-28
updated: 2026-02-28
status: resolved
tags: [bugfix, component-library, godot]
related:
  - ComponentLibrary/Dependencies/component_base.gd
  - ComponentLibrary/Dependencies/character_component_base.gd
  - ComponentLibrary/Packs/Foundation/Components/condition_gate_component.gd
  - ComponentLibrary/Packs/Action/Components/action_gate_component.gd
  - ComponentLibrary/Packs/Time/Components/time_energy_component.gd
---

# 修复目的

Godot 报错“找不到 ComponentBase/CharacterComponentBase”时会让整个场景加载失败。由于基础脚本搬到 `ComponentLibrary/Dependencies` 后没有被自动预加载，所有依赖的组件都无法编译，从而 Demo 场景在 Godot 中打不开。

# 本次处理

- 重新从 `Modules/*` 里恢复涉及 ComponentBase/CharacterComponentBase 的脚本，保留原逻辑。
- 在每个继承 ComponentBase 的脚本开头 `preload("res://ComponentLibrary/Dependencies/component_base.gd")` 并升级 extends，防止基类未被加载。
- 在每个继承 CharacterComponentBase 的脚本额外 `preload("res://ComponentLibrary/Dependencies/character_component_base.gd")`。
- `character_component_base.gd` 也预加载了 `component_base.gd`，保持自包含。
- 这样只要复制 `Dependencies/` 和 `Packs/`，Godot 就能加载 Demo，之前 “场景打不开” 的问题应当消失。
