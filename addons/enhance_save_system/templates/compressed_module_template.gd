## 压缩模块模板
##
## 演示如何在存档模块中配合 Compressor 使用，
## 适用于需要存储大量数据（如地图数据、物品列表）的模块。
##
## 注意：SaveSystem 的全局压缩（compression_enabled=true）会自动压缩整个存档文件。
## 此模板演示的是在模块内部手动压缩特定大型字段的方案，
## 适合只有部分字段需要压缩的场景。
##
## 使用步骤：
##   1. 复制此文件到你的项目中
##   2. 修改 class_name 和 get_module_key()
##   3. 在 collect_data() 中压缩大型数据
##   4. 在 apply_data() 中解压数据

class_name CompressedModuleTemplate
extends ISaveModule

# ──────────────────────────────────────────────
# ISaveModule 必须实现的方法
# ──────────────────────────────────────────────


func get_module_key() -> String:
	return "world_data"  # ← 修改为你的模块键名

func is_global() -> bool:
	return false

func collect_data() -> Dictionary:
	# 假设这是一个大型地图数据
	var large_data := _get_large_map_data()

	# 将大型数据序列化为 JSON 字符串
	var json_str := JSON.stringify(large_data)
	var raw_bytes := json_str.to_utf8_buffer()

	# 使用 gzip 压缩
	var compressed := Compressor.compress(raw_bytes, Compressor.Mode.GZIP)

	# 将压缩后的字节数组转为 base64 字符串（JSON 可序列化）
	var compressed_b64 := Marshalls.raw_to_base64(compressed)

	return {
		# 普通小字段直接存储
		"world_name":    "My World",
		"seed":          12345,
		"player_count":  1,
		# 大型数据压缩存储
		"map_data_compressed": compressed_b64,
		"map_data_compression": "gzip",  # 记录压缩算法，便于解压
	}

func apply_data(data: Dictionary) -> void:
	var world_name:   String = data.get("world_name", "")
	var seed:         int    = data.get("seed", 0)
	var player_count: int    = data.get("player_count", 1)

	# 解压大型数据
	var map_data: Dictionary = {}
	var compressed_b64: String = data.get("map_data_compressed", "")
	if not compressed_b64.is_empty():
		var compressed := Marshalls.base64_to_raw(compressed_b64)
		var compression_str: String = data.get("map_data_compression", "gzip")
		var cmode := Compressor.mode_from_string(compression_str)
		var raw_bytes := Compressor.decompress(compressed, cmode)
		if not raw_bytes.is_empty():
			var json := JSON.new()
			if json.parse(raw_bytes.get_string_from_utf8()) == OK:
				map_data = json.data as Dictionary

	# 应用到游戏状态...
	print("加载世界：name=%s, seed=%d, players=%d, map_tiles=%d" % [
		world_name, seed, player_count, map_data.size()
	])

# ──────────────────────────────────────────────
# 示例：生成大型地图数据
# ──────────────────────────────────────────────

func _get_large_map_data() -> Dictionary:
	# 模拟一个 100x100 的地图数据
	var tiles: Array = []
	for i in range(100):
		var row: Array = []
		for j in range(100):
			row.append(randi() % 5)  # 0-4 的地形类型
		tiles.append(row)
	return { "tiles": tiles, "width": 100, "height": 100 }

# ──────────────────────────────────────────────
# 提示：全局压缩 vs 模块内压缩
# ──────────────────────────────────────────────
##
## 方案 A（推荐）：启用 SaveSystem 全局压缩
##   SaveSystem.compression_enabled = true
##   SaveSystem.compression_mode = "gzip"
##   → 整个存档文件自动压缩，无需修改模块代码
##
## 方案 B（本模板）：模块内手动压缩特定字段
##   → 适合只有部分字段需要压缩的场景
##   → 其他字段仍保持可读的 JSON 格式
##   → 压缩/解压逻辑由模块自己管理
