# test-components-gds

Godot 4.6 组件库仓库，当前主线已经升级为“2D 元游戏底座 + 可插拔玩法包”。

## 当前结构

- `addons/`
  平台插件层。`enhance_save_system` 是正式存档平台，`dialogue_manager/modify_test` 是正式叙事扩展层。
- `ComponentLibrary/`
  共享稳定组件层，包含 `Core`、`Movement`、`Combat`、`UI`、`VFX`、`GameLogic/*` 以及新的 `Systems/MetaFlow`、`SceneFlow2D`、`Interaction2D`、`Camera2D`、`ObjectiveFlag`。
- `StarterPacks/`
  产品模板层。当前包括 `Meta2DHost`、`NarrativeUI`、`PlatformerAction`、`TopDownAction`、`UIPuzzle`。
- `Shader/`、`shaders/`、`Test/`
  保留的实验、验证和展示层。

## 平台核心

- `addons/enhance_save_system/core/save_system.gd`
  作为正式 `SaveSystem` autoload，承载 global/slot、模块注册、自动存档、迁移、加密/压缩、导入导出等能力。
- `addons/dialogue_manager/modify_test`
  作为正式对话扩展包，负责增强 balloon、历史、插画、响应以及对话进度恢复。

## Starter Packs

- `StarterPacks/Meta2DHost`
  2D 元游戏宿主。负责玩法包装载、继续游戏、结果回写、统一存档入口。
- `StarterPacks/NarrativeUI`
  叙事 UI 标准玩法包，支持对话开始、继续、存档、恢复。
- `StarterPacks/PlatformerAction`
  横板动作标准玩法包，保留移动、受击、HUD、暂停和玩家状态存档。
- `StarterPacks/TopDownAction`
  2D 俯视动作标准玩法包，覆盖 8 向移动、冲刺、近战/投射物、交互点、拾取物、房间出口。
- `StarterPacks/UIPuzzle`
  聚合式 UI 解密玩法包，内置 CodePad、PatternGrid、CircuitLink、Terminal、DocumentInspect 五类玩法。

## 入口

- 项目主入口：`Test/test_main.tscn`
- launcher 提供 Meta2DHost、各 starter pack、主线 demo、Shader 展示、插件自测入口。

## 打包

`package_library.ps1` 继续打包：

- `ComponentLibrary`
- `StarterPacks`
- `addons/dialogue_manager`
- `addons/enhance_save_system`
- `README.md`
