# UI 与 VFX 模板包说明（中文）

## 目标

这套模板不是“继承旧组件体系”，而是以 **可独立拼装** 为目标：
- UI：直接拖进场景即可用；
- VFX：脚本驱动，尽量少依赖你的游戏结构；
- Demo：`Test/template_showcase.tscn` 提供一键体验。

## UI 模板

1. `Templates/UI/time_ability_hud.tscn`
- 脚本：`time_ability_hud.gd`
- 能力：显示能量、回溯储能、提示文本。
- 常用接口：
  - `set_energy(current, max)`
  - `set_rewind_charge(ratio)`
  - `show_hint(text)`

2. `Templates/UI/toast_feed.tscn`
- 脚本：`toast_feed.gd`
- 能力：屏幕消息流提示。
- 常用接口：
  - `push_toast(text)`

3. `Templates/UI/cooldown_chip.tscn`
- 脚本：`cooldown_chip.gd`
- 能力：单个技能冷却状态条。
- 常用接口：
  - `set_ready()`
  - `set_cooldown(remaining, duration)`

## VFX 模板

1. `Templates/VFX/time_echo_visual.tscn`
- 脚本：`time_echo_visual.gd`
- 能力：残影拖尾（回声/回溯反馈）。
- 常用接口：
  - `set_active(true/false)`

2. `Templates/VFX/telegraph_ring.tscn`
- 脚本：`telegraph_ring.gd`
- 能力：机关预警环动画。
- 常用接口：
  - `play(duration)`

3. `Templates/VFX/freeze_frame_effect.gd`
- 能力：冻结帧（短暂停顿反馈）。
- 常用接口：
  - `play(duration)`

4. `Templates/VFX/camera_shake_template.gd`
- 能力：轻量相机震动。
- 常用接口：
  - `shake(intensity, duration)`

## 演示场景

- 文件：`Test/template_showcase.tscn`
- 脚本：`Test/template_showcase.gd`
- 按键：
  - `R` 按住：模拟回溯 + 回声拖影
  - `Q`：释放回声（带冷却）
  - `T`：预警环
  - `F`：冻结帧 + 震动
  - `E`：消息提示

## 接入建议

1. 先把 HUD + Toast 接入主场景，统一反馈层。
2. 回溯开始/结束时切换 `TimeEchoVisual`。
3. 陷阱触发前统一调用 `TelegraphRing.play()`。
4. 关键事件（回声释放、受击、开关成功）统一走 `FreezeFrameEffect + CameraShake`。
\n\n## 存档模板\n\n- Templates/UI/save_slot_panel.tscn\n  - 脚本：save_slot_panel.gd\n  - 能力：列出多槽位、保存/读取/删除/刷新。\n  - 依赖：SaveManager 新增多槽位 API。\n
