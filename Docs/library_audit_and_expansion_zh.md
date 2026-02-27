# 组件库扩充与代码审查报告（中文）

## 一、本轮已完成的关键工程改造

### 1) 存档系统升级（Resource 主存储 + 多槽位）

改造文件：
- `Systems/Save/save_manager.gd`
- `Systems/Save/save_game.gd`

新增能力：
1. 多槽位（`1..max_slots`）
2. 切换槽位：`set_current_slot(slot)`
3. 槽位保存/加载：`save_game_to_slot` / `load_game_from_slot`
4. 槽位列表：`list_slots()`（含时间戳和条目数）
5. 删除槽位：`delete_slot(slot)`
6. 导出导入 Resource：`export_slot_resource` / `import_slot_resource`
7. 导出导入 JSON：`export_slot_json` / `import_slot_json`

设计说明：
- 主存档仍然是 `SaveGame Resource`，保留你说的“自定义资源保存”优势。
- JSON 只作为交换格式，不强制替代 Resource。

### 2) 角色组件驱动优化

改造文件：
- `CharacterComponents/Character/character.gd`

优化点：
- 把每帧 `get_children()` + 新数组分配，改成缓存列表。
- 通过 `child_entered_tree/child_exiting_tree` 自动标记 dirty 并刷新。
- 高频 tick 场景下减少分配与遍历开销。

---

## 二、组件库继续扩充（新增）

### Foundation
- `TagComponent`：运行时标签系统（低耦合过滤）。

### Gameplay/Common
- `SequenceSwitchComponent`：顺序开关谜题组件。

### Gameplay/Time
- `RewindEchoBridgeComponent`：把“回溯结束”桥接为“回声释放请求”，用于你想要的核心循环。

---

## 三、前面已补的模板与组件（可直接复用）

### UI 模板
- `Templates/UI/time_ability_hud.*`
- `Templates/UI/toast_feed.*`
- `Templates/UI/cooldown_chip.*`

### VFX 模板
- `Templates/VFX/time_echo_visual.*`
- `Templates/VFX/telegraph_ring.*`
- `Templates/VFX/freeze_frame_effect.gd`
- `Templates/VFX/camera_shake_template.gd`

### 演示场景
- `Test/template_showcase.tscn`
- `Test/template_showcase.gd`

---

## 四、对“存档方案”的结论

你的判断是正确的：
- 纯 JSON 并不总是更好。
- 对 Godot 项目，使用 Resource 作为主存储在“自定义资源、编辑器友好、结构扩展”方面更稳。

最佳实践建议：
1. 运行时存档：Resource（主）
2. 对外交换/备份：JSON（辅）
3. 大量记录型日志（如回放轨迹）：二进制或压缩 JSON（按需）

---

## 五、下一轮建议（高优先）

1. 给 `SaveManager` 增加“槽位封面截图”与关卡名元信息。
2. 给 `RewindEchoBridgeComponent` 接入你实际 `TimeRewind/GhostReplay`，做真桥接而不是信号模板。
3. 把 `time-runner` 的 L2/L3 做成可玩灰盒场景并接入埋点统计。
