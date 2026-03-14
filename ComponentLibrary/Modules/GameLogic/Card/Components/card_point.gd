class_name CardPoint
extends Control
## 手牌槽位锚点
## 由 Hand 生成并管理，Card 追踪此节点的 global_position 平滑移动到正确位置。
## CardPoint 本身无视觉，仅作为位置 + 旋转目标存储器。

## Hand 在 _update_points() 中写入期望的旋转角度
var target_rotation_degrees: float = 0.0
