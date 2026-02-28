---
summary: "组件仓库完成移动式整合：Modules 组件并入 ComponentLibrary/Packs，按 Foundation/Action/Time/UI/VFX 等分类归档，并移除重复 Puzzle 实现。"
created: 2026-02-28
updated: 2026-02-28
status: in-progress
tags: [architecture, refactor, component-library, dedup, godot]
related:
  - Docs/adr/0005-consolidate-modules-into-component-library.md
  - ComponentLibrary/Packs/README.md
  - ComponentLibrary/Demos/README.md
  - Docs/component_architecture_zh.md
  - Docs/component_library_catalog_zh.docx
---

# 本轮重点

1. 将原 `Modules/*/Components` 组件迁入 `ComponentLibrary/Packs/*/Components`，移除并行目录。
2. 新增功能分类包：`Foundation`、`Action`、`Time`、`UI`、`VFX`。
3. 合并并去重 Puzzle：删除 `SequenceLockComponent`，统一使用历史 `SequenceSwitchComponent`。
4. 将组件基类依赖移动到 `ComponentLibrary/Dependencies`：
   - `component_base.gd`
   - `character_component_base.gd`
5. 扩展 Demo：新增 Foundation/Action/Time/UI/VFX 演示并更新 Demo Hub。
6. Demo 脚本统一改为弱类型节点引用，降低 class 注册异常导致场景无法打开的风险。

# 校验结果

- 全仓 `.tscn` 的 `ext_resource` 路径检查通过：未发现缺失资源。
- plugin 注册路径检查通过：无失效脚本路径。
- `class_name` 重名检查通过：无重复类名。

# 后续建议

1. 在具备 Godot CLI 的环境下跑一轮 headless 场景加载验证（当前环境缺少 Godot 命令）。
2. 如需进一步瘦身，可把 `CharacterComponents/` 下可复用能力继续分批移动到 `Packs`。
