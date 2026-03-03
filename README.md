# test-components 项目

## 项目定位

Godot 4.6 可复用组件库（GDScript + C# 双版本）  
每个文件夹都是一个**独立组件**，可以复制到任何项目直接使用并单独测试。  
目标游戏类型：时间操控横板跑酷。

> 本文档摘要自 `CONTEXT.md`，后者包含详细说明。

## 设计原则

1. 单一职责：每个组件只做一件事
2. 独立可测：组件挂到最小场景即可运行
3. 信号驱动：组件之间通过信号通信
4. 自省能力：`get_component_data() -> Dictionary`
5. 零配置可用：合理的默认值
6. 双语版本：核心组件同时提供 GDScript 和 C# 实现

## 仓库总体结构

```
test-components-gds/             # 仓库根
├── .venv/                       # Python 虚拟环境（文档工具）
├── addons/                      # Godot 插件
├── AI/                          # 旧版 AI/回放代码
├── ComponentLibrary/            # 实际组件源（见下文）
├── Docs/                        # 文档生成脚本 & 原稿
├── Resources/                   # 通用资源
├── Shader/                      # 着色器实验场景
├── shaders/                     # 整体 shader 支持文件
├── Test/                        # 测试场景与脚本
├── CONTEXT.md                   # 项目上下文细节
├── README.md                    # 本文件
├── project.godot                # Godot 工程文件
└── …                            # 其它配置、脚本、图标等
```

### ComponentLibrary 目录（主干结构）

```
ComponentLibrary/
├── Core/                       # 框架基础 (ComponentBase, EventBus, ObjectPool ...)
├── CharacterComponents/        # 角色能力组件系统
│   ├── Components/             # 各类能力（输入、重力、移动、跳跃、冲刺、滑墙、动画等）
│   └── Character/              # 统一驱动的角色模板与 Player/ReplayEnemy 演示
├── Combat/                     # 战斗/生存组件（血量、攻击/防御、击退、Buff、重生等）
├── Systems/                    # 全局子系统
│   ├── Audio/Camera/Checkpoint/Debug/…
│   ├── GhostReplay/LevelTimer/
│   ├── Platform/Save/Score/
│   ├── Time/TimeRewind/TimeZone/Trigger/
│   └── …                       # 各种可插拔服务
├── VFX/                        # 视觉特效组件（残影、死亡动画、浮动文本、拖尾、后处理等）
├── Helpers/                    # 静态工具类（Math, ReplayFrame, 时间控制 C# 等）
├── Shader/                     # shader 示例
├── UI/                         # UI 类组件、按钮、转场、模板
├── Modules/                    # 按游戏机制划分的扩展模块（RPG/Shooter/Strategy/…）
│   ├── GameLogic/              # 例如 RPG、Shooter、Strategy、Survival
│   ├── Input/Movement/Time/…
│   └── …                       # 每个模块包含 Components/Demo/Templates 结构
└── …                           # 其它逐步添加的目录
```

> 上述树形是简化版本；实际目录极为丰富，请查看 `CONTEXT.md` 的“目录结构”节获取完整清单。

## Autoload（全局单例）

| 名称           | 路径                                            | 说明                    |
|----------------|-------------------------------------------------|-------------------------|
| `SaveManager`  | `utils/SaveSystem/gds版本/save_manager.gd`      | 存档管理器（GDS）       |
| `DebugHelper`  | `utils/DebugConsole/debug_helper.gd`            | 调试日志 `DebugHelper.log()` |
| `MusicPlayer`  | `utils/AudioSystem/music_player.tscn`           | BGM/SFX 播放器          |
| `TimeController` | `utils/TimeController/TimeController.gd`      | 全局时间缩放与排除列表  |
| `SettingsManager`* | `utils/SaveSystem/gds版本/settings_manager.gd` | 设置管理（需手动注册） |

> *需要手动在 `project.godot` 中注册。

## 组件基类体系

所有组件遵循统一的 `enabled` 模式；核心类位于 `ComponentLibrary/Core`。  
继承结构和使用指南见 `CONTEXT.md`。

## 使用指南（摘要）

- CharacterComponents：统一驱动、自免疫时间缩放、信号通信等；
- AnimationComponent：优先级系统、自动/手动动画流；
- TimeController：时间缩放、排除列表；
- 战斗组件：血量、攻击/受击、Buff、击退等互联；
- 回放与存档示例。

> 本 README 为简洁版，深入说明请查阅仓库根的 `CONTEXT.md`。

---

### 提交与推送

```bash
git add README.md
git commit -m "Refresh README to reflect current project structure"
git push origin main
```