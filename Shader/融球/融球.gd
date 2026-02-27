@tool
extends ColorRect

# 将最大点数限制为20，必须与Shader中的常量一致
const MAX_SHADER_POINTS = 20

# 动态查找点，不再需要手动拖拽赋值
var points_node: Array[Point] = []
# 用于传给Shader的数据
@export var points: PackedVector2Array
@export var radius: PackedFloat32Array
@export var colors: PackedColorArray

var now_size: int

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	# 统一在编辑器和运行时执行刷新每帧刷新
	# 如果觉得太耗性能，可以只在编辑器模式下每帧运行
	_refresh_data()
	_update_shader()

func _refresh_data() -> void:
	# 1. 清空旧列表，重新构建
	points_node.clear()
	
	# 2. 递归查找当前节点下的所有 Point 节点
	_find_points(self)
	
	# 3. 限制数量，防止越界
	now_size = min(points_node.size(), MAX_SHADER_POINTS)
	
	if points.size() != now_size:
		points.resize(now_size)
		radius.resize(now_size)
		colors.resize(now_size)
	
	# 4. 更新坐标和半径
	for i in range(now_size):
		var p = points_node[i]
		# 计算相对坐标：将点的全局位置转换为相对于 ColorRect 的 UV 坐标 (0.0 - 1.0)
		var local_pos = p.position
		points[i] = local_pos / size 
		
		# 直接传递相对半径 (0.0 - 0.5)
		radius[i] = p.radius
		
		# 传递颜色
		colors[i] = p.color

# 递归查找 Point 节点
func _find_points(node: Node) -> void:
	for child in node.get_children():
		if child is Point:
			points_node.append(child)
		elif child is Control: # 继续递归查找容器里的点
			_find_points(child)

func _update_shader() -> void:
	var mat = self.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("points", points)
		mat.set_shader_parameter("radius", radius)
		mat.set_shader_parameter("colors", colors)
		mat.set_shader_parameter("now_size", now_size)
