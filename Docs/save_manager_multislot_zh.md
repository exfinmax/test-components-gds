# SaveManager 多槽位 API（中文）

## 兼容旧接口
- `save_game()`：保存到当前槽位
- `load_game()`：读取当前槽位
- `delete_save()`：删除当前槽位
- `has_save()`：当前槽位是否有存档

## 新接口
- `set_current_slot(slot:int) -> bool`
- `save_game_to_slot(slot:int) -> bool`
- `load_game_from_slot(slot:int) -> bool`
- `delete_slot(slot:int) -> bool`
- `slot_exists(slot:int) -> bool`
- `list_slots() -> Array[Dictionary]`

## 导入导出
- `export_slot_resource(slot, out_path)`：导出 `.tres` 原生资源
- `import_slot_resource(slot, in_path)`：导入 `.tres` 到槽位
- `export_slot_json(slot, out_path)`：导出 JSON
- `import_slot_json(slot, in_path)`：导入 JSON

## 信号
- 兼容旧信号：
  - `save_started`
  - `save_completed(err)`
  - `load_started`
  - `load_completed`
- 新增槽位信号：
  - `slot_save_started(slot)`
  - `slot_save_completed(slot, err)`
  - `slot_load_started(slot)`
  - `slot_load_completed(slot, success)`
  - `slot_changed(slot)`

## 存储路径
- 槽位目录：`user://saves`
- 槽位文件：`slot_01.tres` ~ `slot_08.tres`
- 元数据：`user://saves/manifest.data`
