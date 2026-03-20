# Component Library Architecture

## 目标

当前仓库以“2D 元游戏底座 + 可插拔玩法包”作为主线。底层不是单一游戏模板，而是围绕平台插件、共享组件和玩法包宿主建立统一运行协议。

## 当前结构

```text
Root/
├── addons/                  # 平台插件层（SaveSystem / Dialogue 扩展）
├── ComponentLibrary/
│   ├── Core/                # 基础设施与统一组件约定
│   ├── Modules/             # Movement / Combat / UI / VFX / GameLogic
│   └── Systems/
│       ├── MetaFlow/        # pack manifest / meta progress / registry
│       ├── SceneFlow2D/     # 统一场景与玩法包装载
│       ├── Interaction2D/   # 2D 通用交互热点
│       ├── Camera2D/        # 房间相机与跟随相机
│       └── ObjectiveFlag/   # 标记、任务、章节门控
├── StarterPacks/            # Meta2DHost + 各玩法包
├── Shader/ / shaders/       # 特效与展示
└── Test/                    # 验证入口与保留测试
```

## 主线约束

- 主线组件统一遵循 `enabled`、`enabled_changed`、`get_component_data()` 契约。
- `enhance_save_system` 作为正式 `SaveSystem` autoload，负责 global/slot、settings、keybindings、stats、dialogue、meta progress 等持久化。
- `dialogue_manager/modify_test` 作为正式对话扩展包，不再按测试目录处理。
- 每个玩法包都必须支持：
  - `pack_finished(result: Dictionary)` 信号
  - `start_pack(context: Dictionary)`
  - `export_pack_state() -> Dictionary`
  - `import_pack_state(state: Dictionary)`
- 任何 pack 状态都必须通过宿主和 `SaveSystem` 收口，不允许各自写本地文件。

## 当前 Starter Packs

- `StarterPacks/Meta2DHost`
  元游戏宿主，负责装载和切换 pack，并回写 `MetaProgressModule`。
- `StarterPacks/NarrativeUI`
  叙事 pack，围绕 `dialogue_manager/modify_test + DialogueSaveModule` 运行。
- `StarterPacks/PlatformerAction`
  横板动作 pack，围绕 `Movement + Combat + Action + UI` 运行。
- `StarterPacks/TopDownAction`
  俯视动作 pack，围绕 `HotspotComponent + RoomCameraComponent + pack state` 运行。
- `StarterPacks/UIPuzzle`
  UI 解密 pack，作为元游戏中的插入式界面玩法集合。
