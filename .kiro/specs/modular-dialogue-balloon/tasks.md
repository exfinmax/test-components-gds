# 实现计划：模块化对话气球系统（Modular Dialogue Balloon System）

## 概述

按照设计文档，将现有气球实现重构为 `BaseBalloon` 核心节点 + 可插拔 `BalloonModule` 子节点的架构。实现顺序：核心基础设施 → 各功能模块 → 资源/组件扩展 → 集成连线。

---

## 任务

- [x] 1. 搭建核心基础设施（BaseBalloon + BalloonModule 基类）
  - [x] 1.1 实现 `BalloonModule` 基类
    - 新建 `balloon_module.gd`，继承 `Node`
    - 声明 `is_enabled: bool` 导出属性
    - 声明 `_balloon: BaseBalloon` 弱引用字段
    - 实现 `setup(balloon: BaseBalloon)`、`get_module_name() -> String` 方法
    - 声明虚方法：`on_dialogue_started`、`on_dialogue_line_changed`、`on_dialogue_ended`、`on_input`、`on_module_event`
    - 在 `_enter_tree()` 中检查父节点是否为 `BaseBalloon`，若是则自动调用 `setup` 并注册
    - _需求：2.1、2.2、2.3、2.4、2.5_

  - [ ]* 1.2 为 BalloonModule 编写属性测试（属性 3、属性 4）
    - **属性 3：is_enabled=false 时跳过所有回调**
    - **验证：需求 2.4**
    - **属性 4：子节点自动注册**
    - **验证：需求 2.3**

  - [x] 1.3 实现 `BaseBalloon` 核心节点
    - 新建 `base_balloon.gd`，继承 `CanvasLayer`
    - 声明三个信号：`dialogue_started`、`dialogue_line_changed`、`dialogue_ended`
    - 实现 `start(resource, title, extra_states)`，空资源时 `push_error` 并返回
    - 实现 `next(next_id)`、`register_module`、`unregister_module`、`emit_module_event`
    - 在生命周期事件中按注册顺序调用所有模块回调，用异常捕获隔离单个模块错误
    - 在 `_unhandled_input` 中依次调用模块 `on_input`，返回 `true` 时消费事件并停止传播
    - 处理 `dialogue_manager.mutated` 信号：0.1 秒冷却后通知模块并隐藏气球
    - _需求：1.1–1.10、15.1–15.5、16.1–16.3_

  - [ ]* 1.4 为 BaseBalloon 编写属性测试（属性 1、属性 2、属性 16、属性 17、属性 18）
    - **属性 1：生命周期回调全覆盖**
    - **验证：需求 1.4、1.5、1.6**
    - **属性 2：模块注册/注销 Round-Trip**
    - **验证：需求 1.7**
    - **属性 16：模块事件按注册顺序广播**
    - **验证：需求 15.1、15.4**
    - **属性 17：单模块异常不影响后续模块**
    - **验证：需求 15.5**
    - **属性 18：输入事件消费后停止传播**
    - **验证：需求 16.2**

  - [ ]* 1.5 为 BaseBalloon 编写单元测试
    - 测试 `start()` 传入 null 资源不崩溃（需求 1.10）
    - 测试 `BalloonModule.setup()` 正确注入宿主引用（需求 2.2）
    - 测试 `get_module_name()` 返回非空字符串（需求 2.5）

- [ ] 2. 检查点——确保基础设施测试全部通过
  - 确保所有测试通过，如有疑问请向用户确认。

- [x] 3. 实现 FlowControlModule（对话流程模块）
  - [x] 3.1 实现 `FlowControlModule`
    - 新建 `flow_control_module.gd`，继承 `BalloonModule`
    - 声明所有导出属性：`auto_advance`、`auto_advance_delay`、`auto_advance_mode`、`auto_advance_text_multiplier`、`fast_forward_speed`、`slow_motion_speed`、`base_typing_speed`、`next_action`、`skip_action`
    - 实现 `toggle_auto_advance()` 方法
    - 在 `on_input` 中处理推进（`next_action`）和跳过打字（`skip_action`）
    - 在 `on_dialogue_line_changed` 中处理 `time` 字段自动推进、`voice` 标签播放并推进
    - 实现快进/慢放速度倍率逻辑，通过 `emit_module_event("speed_changed", ...)` 广播
    - 打字完成后根据 `auto_advance` 和 `auto_advance_mode` 计算延迟并自动推进
    - 通过 `emit_module_event("auto_advance_changed", ...)` 广播自动推进状态变化
    - _需求：3.1–3.10、16.4_

  - [ ]* 3.2 为 FlowControlModule 编写属性测试（属性 5）
    - **属性 5：自动推进延迟计算正确性**
    - **验证：需求 3.3**

  - [ ]* 3.3 为 FlowControlModule 编写单元测试
    - 测试 `auto_advance` 延迟计算边界值（L=0）（需求 3.3）
    - 测试 `fast_forward` 按键时速度倍率正确（需求 3.4）

- [x] 4. 实现 TypingSoundModule（打字音效模块）
  - [x] 4.1 实现 `TypingSoundModule`
    - 新建 `typing_sound_module.gd`，继承 `BalloonModule`
    - 声明导出属性：`typing_sound_enabled`、`default_pitch`、`pitch_variance`、`sound_interval`、`typing_sound`
    - 在 `on_dialogue_line_changed` 中从 `CharacterManager` 更新当前角色音调
    - 监听 `DialogueLabel.spoke` 信号，实现 `should_play_sound(c, i, speed_multiplier) -> bool` 纯函数
    - 跳过空格和标点（`.`、`,`、`!`、`?`、`\n`）；速度倍率 < 1.0 时 `effective_interval = 1`
    - 播放时叠加 `pitch_variance` 范围内的随机偏移
    - _需求：4.1–4.7_

  - [ ]* 4.2 为 TypingSoundModule 编写属性测试（属性 6、属性 7）
    - **属性 6：音效播放条件正确性**
    - **验证：需求 4.2、4.3、4.4**
    - **属性 7：角色音调范围约束**
    - **验证：需求 4.5**

  - [ ]* 4.3 为 TypingSoundModule 编写单元测试
    - 测试 `sound_interval` 在慢速时强制为 1（需求 4.4）

- [x] 5. 实现 HistoryModule（历史记录模块）
  - [x] 5.1 实现 `HistoryModule`
    - 新建 `history_module.gd`，继承 `BalloonModule`
    - 声明导出属性：`history_enabled`、`chapter_name`、`max_history_entries`、`history_action`
    - 声明 `history_log: DialogueHistoryLog` 节点引用（由场景树配置）
    - 在 `on_dialogue_started` 中清空历史记录，若 `chapter_name` 不为空则添加章节分隔
    - 在 `on_dialogue_line_changed` 中调用 `add_dialogue_line`，从 `CharacterManager` 读取角色颜色
    - 在 `on_module_event("response_selected", ...)` 中调用 `add_player_response`
    - 在 `on_input` 中处理 `history_action` 切换历史面板显示，返回 `true` 消费事件
    - 若 `max_history_entries > 0` 则限制最大条目数
    - _需求：5.1–5.7、15.3、16.5_

  - [ ]* 5.2 为 HistoryModule 编写属性测试（属性 8、属性 9）
    - **属性 8：历史记录随对话行增长**
    - **验证：需求 5.1**
    - **属性 9：新对话开始时历史清空**
    - **验证：需求 5.4**

  - [ ]* 5.3 为 HistoryModule 编写单元测试
    - 测试对话开始时历史记录清空（需求 5.4）

- [x] 6. 实现 SaveModule（存档模块）
  - [x] 6.1 实现 `SaveModule`
    - 新建 `save_module.gd`，继承 `BalloonModule`
    - 声明导出属性：`auto_save_progress`、`chapter_name`
    - 在 `on_dialogue_line_changed` 中检查 `Engine.has_singleton("SaveSystem")`，存在时传递存档数据，不存在时静默跳过
    - _需求：6.1–6.4_

  - [ ]* 6.2 为 SaveModule 编写单元测试
    - 测试 `SaveSystem` 不存在时静默跳过，不产生错误（需求 6.2）

- [x] 7. 实现 AnimationModule（动画模块）
  - [x] 7.1 实现 `AnimationModule`
    - 新建 `animation_module.gd`，继承 `BalloonModule`
    - 声明导出属性：`enable_enter_animation`、`enable_exit_animation`、`enter_animation_type`、`exit_animation_type`、`animation_duration`、`response_animation_delay`
    - 声明 `balloon_control: Control` 和 `responses_menu: DialogueResponsesMenu` 节点引用
    - 在 `on_dialogue_started` 中播放入场动画（`enable_enter_animation=false` 时直接显示）
    - 在 `on_dialogue_ended` 中播放出场动画，动画完成后隐藏气球
    - 在 `on_dialogue_line_changed` 中检测响应选项，按 `response_animation_delay` 间隔依次淡入各选项
    - _需求：7.1–7.6_

  - [ ]* 7.2 为 AnimationModule 编写单元测试
    - 测试 `enable_enter_animation=false` 时气球立即显示（需求 7.6）

- [x] 8. 扩展 LiHui 资源和 HumanTexture 节点
  - [x] 8.1 扩展 `LiHui` 资源
    - 在 `lihui.gd` 中新增导出属性：`default_expression`（默认 `"ax"`）、`default_direction`（默认 `"left"`）、`character_color`（默认 `Color.WHITE`）
    - 实现 `has_expression(key: String) -> bool` 和 `get_expression_keys() -> Array[String]`
    - _需求：13.1–13.5_

  - [ ]* 8.2 为 LiHui 编写属性测试（属性 12）
    - **属性 12：LiHui 表情键名 Round-Trip**
    - **验证：需求 13.4、13.5**

  - [x] 8.3 扩展 `HumanTexture` 节点
    - 在 `human_texture.gd` 中实现 `set_focus(is_speaking: bool)`：用 Tween 并行动画更新 `scale` 和 `modulate:a`，时长由 `focus_duration` 决定
    - 实现 `play_action_sequence(actions: Array[Dictionary])`：按顺序执行 `type`/`args` 动作字典
    - 扩展 `switch_lihui_resource`：淡出 → 替换纹理 → 淡入，时长由 `lihui_fade_duration` 决定；切换前用 `has_expression` 检查，不存在时静默返回
    - 实现 `reset_all()`：重置位置、缩放、透明度为初始值
    - _需求：12.1–12.6_

  - [ ]* 8.4 为 HumanTexture 编写属性测试（属性 13）
    - **属性 13：缺失表情键名静默跳过**
    - **验证：需求 12.6**

  - [ ]* 8.5 为 HumanTexture 编写单元测试
    - 测试 `switch_lihui_resource` 完成后透明度恢复 1.0（需求 12.4）

- [x] 9. 扩展 IllustrationManager
  - [x] 9.1 扩展 `IllustrationManager`
    - 新增 `center_illustration: HumanTexture` 导出变量，支持 `IllustrationPosition.CENTER`
    - 在 `update_from_dialogue_line` 中解析 `position:center` 标签
    - 实现 `set_focus_by_name(character_name: String)`：匹配角色名应用焦点，无匹配时全部设为非焦点
    - 实现 `swap_illustrations(pos_a: int, pos_b: int)`：交换两个位置的立绘资源
    - 扩展 `hide_illustration`/`show_illustration`：`animate=true` 时用 Tween 完成淡出/淡入，时长由 `fade_duration` 决定
    - _需求：14.1–14.6_

  - [ ]* 9.2 为 IllustrationManager 编写属性测试（属性 14、属性 15）
    - **属性 14：IllustrationManager 无匹配时全部非焦点**
    - **验证：需求 14.4**
    - **属性 15：立绘交换 Round-Trip**
    - **验证：需求 14.5**

  - [ ]* 9.3 为 IllustrationManager 编写单元测试
    - 测试 `set_focus_by_name` 正确立绘获得焦点（需求 14.3）

- [x] 10. 实现 IllustrationModule（立绘模块）
  - [x] 10.1 实现 `IllustrationModule`
    - 新建 `illustration_module.gd`，继承 `BalloonModule`
    - 声明 `fade_duration: float` 导出属性和 `illustration_manager: IllustrationManager` 节点引用
    - 在 `on_dialogue_line_changed` 中调用 `illustration_manager.update_from_dialogue_line`
    - 解析 `character` 字段变化时调用 `set_focus_by_name` 更新焦点
    - 解析 tags 中的 `expression:{key}` 和 `position:{left|right|center}` 并传递给 IllustrationManager
    - 在 `on_dialogue_ended` 中调用 `illustration_manager.reset_all`
    - 实现 `switch_illustration(position, resource, default_key)` 公共方法
    - 所有方法在使用前用 `is_instance_valid()` 检查节点引用
    - _需求：8.1–8.7_

- [x] 11. 实现 CharacterUIModule（角色 UI 模块）
  - [x] 11.1 实现 `CharacterUIModule`
    - 新建 `character_ui_module.gd`，继承 `BalloonModule`
    - 声明 `balloon_direction` 导出枚举属性（`"left"`/`"right"`/`"auto"`）
    - 声明 `character_manager: CharacterManager` 和 `ui_renderer: BalloonUIRenderer` 节点引用
    - 在 `on_dialogue_line_changed` 中更新角色名称标签文本和颜色；`character` 为空时隐藏标签
    - 从 `CharacterManager` 读取头像纹理、背景纹理、头像偏移、名称缩放并应用到 UI 节点
    - `balloon_direction` 为 `"auto"` 时从 `CharacterManager` 读取角色默认方向并调用 `BalloonUIRenderer` 切换布局
    - 实现 `register_character(name, config)` 和 `set_expression(expression)` 代理方法
    - _需求：9.1–9.6_

- [x] 12. 实现 ResponseModule（响应选项模块）
  - [x] 12.1 实现 `ResponseModule`
    - 新建 `response_module.gd`，继承 `BalloonModule`
    - 声明 `response_selected(response: DialogueResponse)` 信号
    - 声明 `responses_menu: DialogueResponsesMenu` 节点引用
    - 在 `on_dialogue_line_changed` 中根据是否包含响应选项显示/隐藏菜单
    - 响应菜单显示时调用 `configure_focus` 设置键盘焦点到第一个选项
    - 玩家选择后调用 `_balloon.next(response.next_id)`，发出 `response_selected` 信号，并通过 `emit_module_event("response_selected", {response: ...})` 广播
    - _需求：10.1–10.6、15.3_

  - [ ]* 12.2 为 ResponseModule 编写属性测试（属性 10）
    - **属性 10：响应菜单可见性与对话行一致**
    - **验证：需求 10.1、10.2**

  - [ ]* 12.3 为 ResponseModule 编写单元测试
    - 测试响应选择后 `response_selected` 信号发出（需求 10.3）

- [x] 13. 实现 IndicatorModule（状态指示器模块）
  - [x] 13.1 实现 `IndicatorModule`
    - 新建 `indicator_module.gd`，继承 `BalloonModule`
    - 声明 `auto_advance_indicator: Label` 和 `speed_indicator: Label` 节点引用
    - 在 `on_module_event` 中处理 `"speed_changed"` 事件：`m > 1.5` 显示快进，`m < 0.7` 显示慢放，否则隐藏
    - 在 `on_module_event` 中处理 `"auto_advance_changed"` 事件：更新自动推进指示器可见性
    - 在 `on_dialogue_started` 中从宿主查找 `FlowControlModule` 并缓存引用
    - _需求：11.1–11.5_

  - [ ]* 13.2 为 IndicatorModule 编写属性测试（属性 11）
    - **属性 11：速度指示器显示状态正确性**
    - **验证：需求 11.2、11.3、11.4**

- [ ] 14. 检查点——确保所有模块单元测试通过
  - 确保所有测试通过，如有疑问请向用户确认。

- [-] 15. 集成连线：创建 BaseBalloon 场景并挂载所有模块
  - [x] 15.1 创建 `base_balloon.tscn` 场景
    - 根节点为 `BaseBalloon`（CanvasLayer）
    - 添加气球 UI 子节点（Panel/Control、DialogueLabel、角色名标签等）
    - 将所有 BalloonModule 子节点挂载到场景树，配置各模块的节点引用导出变量
    - _需求：1.1–1.9、2.3_

  - [ ] 15.2 将现有 EnhancedBalloon / IllustratedBalloon 的功能迁移到对应模块
    - 确认旧气球场景中的逻辑已全部由对应模块覆盖
    - 更新 `demo_scene.gd` 或演示场景，改用 `BaseBalloon` 启动对话
    - _需求：全部_

- [ ] 16. 最终检查点——确保所有测试通过
  - 确保所有测试通过，如有疑问请向用户确认。

---

## 备注

- 标有 `*` 的子任务为可选测试任务，可在快速迭代时跳过
- 每个任务均引用具体需求条款以保证可追溯性
- 属性测试使用 gdUnit4 框架，每个属性最少运行 100 次迭代
- 测试文件放置于 `tests/unit/` 和 `tests/property/` 目录下
- 所有模块在使用节点引用前须调用 `is_instance_valid()` 检查
