---
summary: "组件库新增 Platformer/Racing/Builder 三包，建立 Demo 基线与可选插件分发，并修复 TransitionScene 失效资源路径。"
created: 2026-02-28
updated: 2026-02-28
status: resolved
tags: [architecture, component-library, demos, plugin, godot]
related:
  - ComponentLibrary/Packs/README.md
  - ComponentLibrary/Demos/README.md
  - addons/component_library_share/plugin.gd
  - Docs/adr/0004-plugin-distribution-and-demo-baseline.md
  - UI/Transition/TransitionScene.tscn
---

# 本轮结论

1. 组件库按品类继续扩展：新增 `Platformer`、`Racing`、`Builder`。
2. 建立 Demo 验收基线：每个品类都提供 `*_demo.tscn + *_demo.gd`，并统一入口 `demo_hub.tscn`。
3. 新增可选插件 `component_library_share`：仅提供编辑器 Custom Type 注册，不接管运行时。
4. 修复历史问题：`UI/Transition/TransitionScene.tscn` 的资源路径指向旧目录，现已改为 `res://UI/Transition/*`。

# 交付物

- 新增三类组件：
  - `CoyoteJumpComponent`
  - `LapCheckpointComponent`
  - `GridPlacementComponent`
- 新增 10 个品类 Demo（Shooter/RPG/Strategy/Survival/Card/Puzzle/Roguelike/Platformer/Racing/Builder）
- 新增 ADR-0004 记录插件化分发与 Demo 验收标准
- 生成 `Docs/component_library_catalog_zh.docx`

# 环境限制

- `npm install docx` 在当前环境被网络权限拦截（EACCES），无法使用 docx-js 安装路径。
- 采用 `python-docx` 作为替代生成 docx 文件，保证文档交付连续性。

