# UI 与 VFX 模板包说明（中文）

## 目标

模板层追求“低耦合可复用”：
- UI 模板偏展示，不耦合具体玩法状态机。
- VFX 模板偏反馈，不绑定具体角色逻辑。
- 通过公开方法进行最小接入。

## UI 模板

1. `Templates/UI/time_ability_hud.tscn`
- 脚本：`time_ability_hud.gd`
- 用途：显示能量、回溯储能、提示文本。
- 接口：`set_energy`、`set_rewind_charge`、`show_hint`。

2. `Templates/UI/toast_feed.tscn`
- 脚本：`toast_feed.gd`
- 用途：消息流提示。
- 接口：`push_toast`。

3. `Templates/UI/cooldown_chip.tscn`
- 脚本：`cooldown_chip.gd`
- 用途：单技能冷却展示。
- 接口：`set_ready`、`set_cooldown`。

4. `Templates/UI/save_slot_panel.tscn`
- 脚本：`save_slot_panel.gd`
- 用途：多槽位存档管理面板。
- 接口：`refresh_slots`、`save_slot`、`load_slot`、`delete_slot`。

5. `Templates/UI/ability_wheel_hud.tscn`
- 脚本：`ability_wheel_hud.gd`
- 用途：能力轮盘 HUD（选中态 + 冷却展示）。
- 接口：`set_selected`、`set_cooldown`、`set_hint`。

## VFX 模板

1. `Templates/VFX/time_echo_visual.tscn`
- 脚本：`time_echo_visual.gd`
- 用途：回声残影反馈。
- 接口：`set_active`。

2. `Templates/VFX/telegraph_ring.tscn`
- 脚本：`telegraph_ring.gd`
- 用途：机关预警圈。
- 接口：`play`。

3. `Templates/VFX/freeze_frame_effect.gd`
- 用途：冻结帧反馈。
- 接口：`play`。

4. `Templates/VFX/camera_shake_template.gd`
- 用途：相机震动反馈。
- 接口：`shake`。

5. `Templates/VFX/screen_flash_overlay.tscn`
- 脚本：`screen_flash_overlay.gd`
- 用途：全屏闪白/闪色反馈。
- 接口：`flash`。

## 建议用法

1. 常驻 `HUD + Toast + AbilityWheel` 作为统一信息层。
2. 把命中、机关、能力释放等事件统一转发到 VFX 模板层。
3. 通过 `Gameplay` 层组件发信号，不在表现层反向驱动玩法逻辑。
