# 需求文档：模块化对话气球系统（Modular Dialogue Balloon System）

## 简介

本系统旨在将现有的 `ModifyBalloon`、`EnhancedBalloon`、`IllustratedBalloon` 三个气球实现整合为一个统一的 `BaseBalloon` 模板气球，并将各功能拆分为高内聚、低耦合的独立模块（BalloonModule）。每个模块可按需挂载到 `BaseBalloon` 下，开发者可自由组合所需功能，无需修改核心气球逻辑。

系统基于 Godot 4 和 `dialogue_manager` 插件构建，复用并优化现有的 `BalloonAnimator`、`CharacterManager`、`DialogueFlowController`、`BalloonUIRenderer`、`IllustrationManager`、`DialogueHistoryLog`、`HumanTexture`、`LiHui` 等组件。

---

## 词汇表

- **BaseBalloon**：核心气球节点（CanvasLayer），负责对话生命周期管理和模块调度，不包含任何具体功能逻辑
- **BalloonModule**：可挂载到 BaseBalloon 下的功能模块基类（Node），通过标准接口与 BaseBalloon 通信
- **DialogueLine**：dialogue_manager 插件提供的对话行数据对象
- **DialogueResource**：dialogue_manager 插件提供的对话资源文件
- **HumanTexture**：立绘节点，继承 TextureRect，支持移动/跳跃/抖动/缩放/翻转/焦点动画
- **LiHui**：立绘资源（Resource），包含角色名和表情字典（sprites: Dictionary[String, Texture2D]）
- **IllustrationManager**：立绘管理节点，负责多位置立绘的显示、切换和焦点管理
- **CharacterManager**：角色配置管理器（RefCounted），统一管理角色音调、颜色、纹理、方向等属性
- **BalloonAnimator**：气球动画控制器（RefCounted），支持 scale/fade/slide/pop 等动画类型
- **DialogueFlowController**：对话流程控制器（RefCounted），负责对话推进、跳转、结束等逻辑
- **DialogueHistoryLog**：历史记录面板（Control），记录对话内容并支持滚动查看
- **BalloonUIRenderer**：UI 渲染管理器（RefCounted），负责气球布局和方向切换
- **IllustrationPosition**：立绘位置枚举（LEFT=0, RIGHT=1, CENTER=2）
- **AnimType**：动画类型枚举（SCALE, FADE, SLIDE_UP, SLIDE_DOWN, SLIDE_LEFT, SLIDE_RIGHT, POP, NONE）
- **打字音效**：对话文本逐字显示时播放的音效，音调因角色而异
- **自动推进**：打字完成后无需玩家输入、自动进入下一行对话的功能
- **快进/慢放**：按住特定按键动态加速或减速打字动画的功能
- **焦点状态**：当前说话角色的立绘放大高亮、非说话角色立绘缩小变暗的视觉状态

---

## 需求

### 需求 1：BaseBalloon 核心气球

**用户故事：** 作为开发者，我希望有一个轻量的核心气球节点，使其只负责对话生命周期和模块调度，以便我可以按需组合功能模块而无需修改核心代码。

#### 验收标准

1. THE BaseBalloon SHALL 继承 CanvasLayer，并持有一个 DialogueFlowController 实例用于管理对话流程
2. THE BaseBalloon SHALL 提供 `start(resource: DialogueResource, title: String, extra_states: Array)` 方法以启动对话
3. THE BaseBalloon SHALL 提供 `next(next_id: String)` 方法以推进到下一行对话
4. WHEN 对话行发生变化时，THE BaseBalloon SHALL 依次调用所有已注册 BalloonModule 的 `on_dialogue_line_changed(line: DialogueLine)` 方法
5. WHEN 对话结束时，THE BaseBalloon SHALL 依次调用所有已注册 BalloonModule 的 `on_dialogue_ended()` 方法
6. WHEN 对话开始时，THE BaseBalloon SHALL 依次调用所有已注册 BalloonModule 的 `on_dialogue_started(resource, title)` 方法
7. THE BaseBalloon SHALL 提供 `register_module(module: BalloonModule)` 和 `unregister_module(module: BalloonModule)` 方法以动态管理模块
8. WHEN dialogue_manager 的 `mutated` 信号触发时，THE BaseBalloon SHALL 通知所有模块并在冷却后隐藏气球
9. THE BaseBalloon SHALL 发出 `dialogue_started`、`dialogue_line_changed`、`dialogue_ended` 三个信号
10. IF 对话资源为空时调用 start，THEN THE BaseBalloon SHALL 输出错误日志并中止启动

---

### 需求 2：BalloonModule 模块基类

**用户故事：** 作为开发者，我希望有一个标准的模块基类，使所有功能模块遵循统一接口，以便 BaseBalloon 可以统一调度而无需了解模块内部实现。

#### 验收标准

1. THE BalloonModule SHALL 继承 Node，并声明以下虚方法供子类重写：`on_dialogue_started`、`on_dialogue_line_changed`、`on_dialogue_ended`、`on_input`
2. THE BalloonModule SHALL 持有对宿主 BaseBalloon 的弱引用，通过 `setup(balloon: BaseBalloon)` 方法注入
3. WHEN BalloonModule 作为 BaseBalloon 的子节点加入场景树时，THE BalloonModule SHALL 自动调用 `setup` 完成注册
4. THE BalloonModule SHALL 提供 `is_enabled: bool` 属性，WHEN `is_enabled` 为 false 时，THE BalloonModule SHALL 跳过所有回调执行
5. THE BalloonModule SHALL 提供 `get_module_name() -> String` 方法返回模块唯一标识名称

---

### 需求 3：FlowControlModule（对话流程模块）

**用户故事：** 作为开发者，我希望将对话推进、自动推进、快进/慢放等流程控制逻辑封装为独立模块，以便在不同气球中复用相同的流程控制行为。

#### 验收标准

1. THE FlowControlModule SHALL 封装 DialogueFlowController，负责对话的启动、推进和结束
2. WHEN 打字动画完成且 `auto_advance` 为 true 时，THE FlowControlModule SHALL 在 `auto_advance_delay` 秒后自动调用 `BaseBalloon.next()`
3. WHERE `auto_advance_mode` 为 `text_length` 时，THE FlowControlModule SHALL 根据文本长度乘以 `auto_advance_text_multiplier` 计算延迟，且延迟不低于 `auto_advance_delay`
4. WHILE 玩家持续按住 `fast_forward_action` 时，THE FlowControlModule SHALL 将打字速度乘以 `fast_forward_speed` 倍率
5. WHILE 玩家持续按住 `slow_motion_action` 时，THE FlowControlModule SHALL 将打字速度乘以 `slow_motion_speed` 倍率
6. WHEN 对话行包含 `time` 字段时，THE FlowControlModule SHALL 等待指定时间后自动推进，无需玩家输入
7. WHEN 对话行包含 `voice` 标签时，THE FlowControlModule SHALL 播放指定音频文件，并在播放完成后自动推进
8. WHEN 对话行包含响应选项时，THE FlowControlModule SHALL 等待玩家选择，不自动推进
9. IF 对话行既无响应选项、又无 time 字段、又无 voice 标签、且 `auto_advance` 为 false 时，THEN THE FlowControlModule SHALL 等待玩家输入后推进
10. THE FlowControlModule SHALL 提供 `toggle_auto_advance()` 方法切换自动推进状态

---

### 需求 4：TypingSoundModule（打字音效模块）

**用户故事：** 作为开发者，我希望将角色打字音效逻辑封装为独立模块，以便不同角色拥有不同音调的打字音效，且可以独立启用或禁用。

#### 验收标准

1. THE TypingSoundModule SHALL 监听 DialogueLabel 的 `spoke` 信号，并在满足条件时播放打字音效
2. WHEN 当前字符为空格、标点符号（`.`、`,`、`!`、`?`、`\n`）时，THE TypingSoundModule SHALL 跳过音效播放
3. WHEN 字符索引不是 `sound_interval` 的整数倍时，THE TypingSoundModule SHALL 跳过音效播放
4. WHEN 当前速度倍率小于 1.0 时，THE TypingSoundModule SHALL 将 `sound_interval` 设为 1 以保证音效密度
5. THE TypingSoundModule SHALL 从 CharacterManager 读取当前角色的音调配置，并叠加 `pitch_variance` 范围内的随机偏移
6. WHEN 对话行变化时，THE TypingSoundModule SHALL 从 CharacterManager 更新当前角色音调
7. THE TypingSoundModule SHALL 支持通过 `typing_sound_enabled` 属性全局开关音效

---

### 需求 5：HistoryModule（历史记录模块）

**用户故事：** 作为开发者，我希望将对话历史记录功能封装为独立模块，以便玩家可以随时查看已发生的对话内容。

#### 验收标准

1. THE HistoryModule SHALL 持有 DialogueHistoryLog 节点引用，并在每次对话行变化时调用 `add_dialogue_line`
2. WHEN 玩家选择响应选项时，THE HistoryModule SHALL 调用 `add_player_response` 记录玩家选择
3. WHEN 对话开始且 `chapter_name` 不为空时，THE HistoryModule SHALL 调用 `add_chapter_divider` 添加章节分隔
4. WHEN 对话开始时，THE HistoryModule SHALL 调用 `clear_history` 清空上一次对话的历史记录
5. WHEN 玩家按下 `history_action` 输入动作时，THE HistoryModule SHALL 切换 DialogueHistoryLog 的显示状态
6. THE HistoryModule SHALL 从 CharacterManager 读取角色颜色并传递给 DialogueHistoryLog
7. WHERE `max_history_entries` 大于 0 时，THE HistoryModule SHALL 限制 DialogueHistoryLog 的最大条目数

---

### 需求 6：SaveModule（存档模块）

**用户故事：** 作为开发者，我希望将对话进度存档功能封装为独立模块，以便玩家的对话进度可以自动保存，且存档逻辑与气球核心解耦。

#### 验收标准

1. WHEN 每次对话行变化且 `auto_save_progress` 为 true 时，THE SaveModule SHALL 尝试通过 SaveSystem 单例保存当前对话进度
2. IF SaveSystem 单例不存在时，THEN THE SaveModule SHALL 静默跳过存档操作，不产生错误
3. THE SaveModule SHALL 将 `dialogue_resource`、`dialogue_line.id`、`chapter_name`、`character`、`text` 传递给存档系统
4. THE SaveModule SHALL 提供 `chapter_name: String` 属性用于标识当前对话章节

---

### 需求 7：AnimationModule（动画模块）

**用户故事：** 作为开发者，我希望将气球入场/出场动画和响应选项动画封装为独立模块，以便不同气球可以配置不同的动画风格。

#### 验收标准

1. THE AnimationModule SHALL 持有 BalloonAnimator 实例，并在对话开始时播放入场动画
2. WHEN 对话结束时，THE AnimationModule SHALL 播放出场动画，并在动画完成后隐藏气球
3. WHEN 响应选项显示时，THE AnimationModule SHALL 对每个选项按 `response_animation_delay` 间隔依次播放淡入动画
4. THE AnimationModule SHALL 支持通过 `enter_animation_type` 和 `exit_animation_type` 属性配置动画类型，可选值为 `scale`、`fade`、`pop`、`slide_up`、`slide_down`、`none`
5. THE AnimationModule SHALL 支持通过 `enable_enter_animation` 和 `enable_exit_animation` 属性独立开关入场和出场动画
6. WHEN `enable_enter_animation` 为 false 时，THE AnimationModule SHALL 直接显示气球，不播放任何动画

---

### 需求 8：IllustrationModule（立绘模块）

**用户故事：** 作为开发者，我希望将立绘显示、焦点切换、表情切换等功能封装为独立模块，以便立绘逻辑与气球 UI 逻辑完全解耦。

#### 验收标准

1. THE IllustrationModule SHALL 持有 IllustrationManager 节点引用，并在对话行变化时调用 `update_from_dialogue_line`
2. WHEN 对话行的 `character` 字段变化时，THE IllustrationModule SHALL 调用 IllustrationManager 更新焦点状态，使当前说话角色的立绘放大高亮
3. WHEN 对话行的 tags 包含 `expression:{key}` 时，THE IllustrationModule SHALL 解析表情键名并调用 `IllustrationManager.switch_expression`
4. WHEN 对话行的 tags 包含 `position:{left|right|center}` 时，THE IllustrationModule SHALL 解析位置并传递给 IllustrationManager
5. THE IllustrationModule SHALL 提供 `switch_illustration(position: int, resource: LiHui, default_key: String)` 方法供外部代码切换立绘资源
6. WHEN 对话结束时，THE IllustrationModule SHALL 调用 `IllustrationManager.reset_all` 重置所有立绘状态
7. THE IllustrationModule SHALL 支持通过 `fade_duration` 属性配置立绘淡入淡出时长

---

### 需求 9：CharacterUIModule（角色 UI 模块）

**用户故事：** 作为开发者，我希望将角色名称标签、头像、背景纹理等 UI 元素的更新逻辑封装为独立模块，以便角色视觉呈现与对话流程解耦。

#### 验收标准

1. THE CharacterUIModule SHALL 持有 CharacterManager 实例，并在对话行变化时更新角色名称标签的文本和颜色
2. WHEN 对话行的 `character` 字段为空时，THE CharacterUIModule SHALL 隐藏角色名称标签
3. THE CharacterUIModule SHALL 从 CharacterManager 读取角色的头像纹理、背景纹理、头像偏移、名称缩放等配置并应用到对应 UI 节点
4. WHEN `balloon_direction` 为 `auto` 时，THE CharacterUIModule SHALL 从 CharacterManager 读取角色默认方向并调用 BalloonUIRenderer 切换布局
5. THE CharacterUIModule SHALL 提供 `register_character(name: String, config: Dictionary)` 方法，代理到 CharacterManager 的同名方法
6. THE CharacterUIModule SHALL 提供 `set_expression(expression: String)` 方法，更新当前表情并刷新头像显示

---

### 需求 10：ResponseModule（响应选项模块）

**用户故事：** 作为开发者，我希望将响应选项的显示、焦点管理和选择处理封装为独立模块，以便响应逻辑与气球核心解耦。

#### 验收标准

1. THE ResponseModule SHALL 持有 DialogueResponsesMenu 节点引用，并在对话行包含响应选项时显示菜单
2. WHEN 对话行不包含响应选项时，THE ResponseModule SHALL 隐藏响应菜单
3. WHEN 玩家选择响应选项时，THE ResponseModule SHALL 调用 `BaseBalloon.next(response.next_id)` 推进对话
4. WHEN 玩家选择响应选项时，THE ResponseModule SHALL 通知 HistoryModule 记录玩家选择（若 HistoryModule 已注册）
5. WHEN 响应菜单显示时，THE ResponseModule SHALL 调用 `configure_focus` 设置键盘焦点到第一个选项
6. THE ResponseModule SHALL 发出 `response_selected(response: DialogueResponse)` 信号

---

### 需求 11：IndicatorModule（状态指示器模块）

**用户故事：** 作为开发者，我希望将自动推进指示器、速度指示器等 HUD 元素的更新逻辑封装为独立模块，以便 UI 反馈与功能逻辑解耦。

#### 验收标准

1. THE IndicatorModule SHALL 监听 FlowControlModule 的状态变化，并更新自动推进指示器标签的文本和可见性
2. WHEN 速度倍率大于 1.5 时，THE IndicatorModule SHALL 显示快进指示器并展示当前倍率
3. WHEN 速度倍率小于 0.7 时，THE IndicatorModule SHALL 显示慢放指示器并展示当前倍率
4. WHEN 速度倍率在 0.7 到 1.5 之间时，THE IndicatorModule SHALL 隐藏速度指示器
5. WHEN 自动推进启用时，THE IndicatorModule SHALL 显示自动推进指示器；WHEN 自动推进禁用时，THE IndicatorModule SHALL 隐藏自动推进指示器

---

### 需求 12：HumanTexture 立绘节点扩展

**用户故事：** 作为开发者，我希望扩展 HumanTexture 的功能，使其能够自动响应对话行变化并支持更丰富的动作组合，以便立绘表现更加生动。

#### 验收标准

1. THE HumanTexture SHALL 提供 `set_focus(is_speaking: bool)` 方法，根据参数应用焦点或非焦点的缩放和透明度动画
2. WHEN `set_focus` 被调用时，THE HumanTexture SHALL 使用 Tween 并行动画同时更新 `scale` 和 `modulate:a`，动画时长由 `focus_duration` 决定
3. THE HumanTexture SHALL 提供 `play_action_sequence(actions: Array[Dictionary])` 方法，按顺序依次执行多个动作，每个动作字典包含 `type`、`args` 字段
4. WHEN `switch_lihui_resource` 被调用时，THE HumanTexture SHALL 先淡出当前立绘，替换纹理资源，再淡入新立绘，淡出淡入时长由 `lihui_fade_duration` 决定
5. THE HumanTexture SHALL 提供 `reset_all()` 方法，将位置、缩放、透明度全部重置为初始值
6. WHEN `lihui_resource` 不包含请求的表情键名时，THE HumanTexture SHALL 静默跳过切换，不产生错误

---

### 需求 13：LiHui 立绘资源扩展

**用户故事：** 作为开发者，我希望扩展 LiHui 资源，使其支持更丰富的元数据，以便立绘系统可以自动读取角色配置而无需手动注册。

#### 验收标准

1. THE LiHui SHALL 提供 `default_expression: String` 属性，指定角色的默认表情键名，默认值为 `"ax"`
2. THE LiHui SHALL 提供 `default_direction: String` 属性，指定角色的默认站位方向（`"left"` 或 `"right"`），默认值为 `"left"`
3. THE LiHui SHALL 提供 `character_color: Color` 属性，指定角色名称标签的显示颜色
4. THE LiHui SHALL 提供 `has_expression(key: String) -> bool` 方法，返回 `sprites` 字典中是否包含指定键名
5. THE LiHui SHALL 提供 `get_expression_keys() -> Array[String]` 方法，返回所有可用表情键名列表

---

### 需求 14：IllustrationManager 扩展

**用户故事：** 作为开发者，我希望扩展 IllustrationManager，使其支持中央立绘位置和更精细的焦点控制，以便支持更多样的场景布局。

#### 验收标准

1. THE IllustrationManager SHALL 支持 `IllustrationPosition.CENTER` 位置的立绘节点，通过 `center_illustration` 导出变量配置
2. WHEN `update_from_dialogue_line` 被调用时，THE IllustrationManager SHALL 正确解析 `position:center` 标签并更新中央立绘
3. THE IllustrationManager SHALL 提供 `set_focus_by_name(character_name: String)` 方法，根据角色名自动查找对应立绘并应用焦点状态
4. WHEN 没有任何立绘的 `character_name` 匹配当前说话角色时，THE IllustrationManager SHALL 将所有立绘设为非焦点状态
5. THE IllustrationManager SHALL 提供 `swap_illustrations(pos_a: int, pos_b: int)` 方法，交换两个位置的立绘资源
6. WHEN `hide_illustration` 或 `show_illustration` 被调用且 `animate` 为 true 时，THE IllustrationManager SHALL 使用 Tween 完成淡出/淡入动画，时长由 `fade_duration` 决定

---

### 需求 15：模块间通信与事件总线

**用户故事：** 作为开发者，我希望模块之间通过标准化的事件接口通信，而不是直接持有彼此的引用，以便模块可以独立替换而不影响其他模块。

#### 验收标准

1. THE BaseBalloon SHALL 提供 `emit_module_event(event_name: String, data: Dictionary)` 方法，向所有已注册模块广播自定义事件
2. THE BalloonModule SHALL 提供 `on_module_event(event_name: String, data: Dictionary)` 虚方法，供子类重写以响应自定义事件
3. WHEN HistoryModule 需要记录玩家选择时，THE ResponseModule SHALL 通过 `emit_module_event("response_selected", {...})` 广播事件，而不直接调用 HistoryModule
4. THE BaseBalloon SHALL 保证模块回调的调用顺序与模块注册顺序一致
5. IF 某个模块的回调抛出异常时，THEN THE BaseBalloon SHALL 捕获异常、输出错误日志，并继续调用后续模块的回调

---

### 需求 16：输入处理标准化

**用户故事：** 作为开发者，我希望气球的输入处理逻辑标准化，使各模块可以声明自己关心的输入动作，以便输入冲突可以被统一管理。

#### 验收标准

1. THE BaseBalloon SHALL 在 `_unhandled_input` 中将输入事件传递给所有模块的 `on_input(event: InputEvent)` 方法
2. WHEN 某个模块的 `on_input` 返回 `true` 时，THE BaseBalloon SHALL 调用 `get_viewport().set_input_as_handled()` 并停止向后续模块传递该事件
3. WHEN `will_block_other_input` 为 true 时，THE BaseBalloon SHALL 在每帧 `_unhandled_input` 中调用 `set_input_as_handled` 阻断其他节点的输入
4. THE FlowControlModule SHALL 在 `on_input` 中处理推进对话（`next_action`）、跳过打字（`skip_action`）的输入
5. THE HistoryModule SHALL 在 `on_input` 中处理切换历史面板（`history_action`）的输入

