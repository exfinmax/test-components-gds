# PlatformerAction

2D 横板动作标准玩法包，聚合 `Movement`、基础 `Combat`、`Action` 交互、`UI` 和玩家状态存档。

- 入口场景：`Main.tscn`
- 默认输入：`A/D` 左右，`Space` 跳跃，`Shift` 冲刺，`E` 交互，`Esc` 暂停
- 存档：优先使用 `/root/SaveSystem`，默认示例保存到槽位 `1`
- 宿主协议：支持 `start_pack`、`export_pack_state`、`import_pack_state`、`pack_finished`
- 可替换点：玩家预制体、HUD、交互区、危险区、存档模块
