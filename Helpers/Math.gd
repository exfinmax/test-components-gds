class_name Mathf


static var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

static func create_randf_offset(offset: float) -> float:
	return randf_range(deg_to_rad(-offset), deg_to_rad(offset))

static func create_randf_vector2_offset(offset: float) -> Vector2:
	return Vector2(randf_range(deg_to_rad(-offset), deg_to_rad(offset)),randf_range(deg_to_rad(-offset), deg_to_rad(offset)))


	

static func calculate_circular_velocity(speed: float, center_position: Vector2, radius: float, self_position: Vector2) -> Vector2:
	"""
	改进的环形轨迹计算，卡牌围绕创建者稳定旋转
	"""
	var to_center = center_position - self_position
	var distance_to_center = to_center.length()
	
	# 计算径向方向（指向中心）
	var radial_direction = to_center.normalized()
	
	# 计算切线方向（垂直于径向，用于旋转）
	var tangent_direction = Vector2(-radial_direction.y, radial_direction.x)
	
	# 计算径向速度分量（用于调整到正确半径）
	var radial_speed = 0.0
	var distance_error = distance_to_center - radius
	
	if abs(distance_error) > 5.0:  # 如果距离误差较大
		radial_speed = distance_error * 2.0  # 向中心或远离中心移动
		radial_speed = clamp(radial_speed, -speed * 0.3, speed * 0.3)  # 限制径向速度
	
	# 组合切线速度和径向速度
	var velocity = tangent_direction * speed + radial_direction * radial_speed
	
	return velocity




	

static func calculate_tracking_trajectory(
	current_velocity: Vector2, 
	current_pos: Vector2, 
	target_pos: Vector2, 
	speed: float, 
	tracking_strength: float, 
	delta: float
) -> Vector2:
	var target_direction = (target_pos - current_pos).normalized()
	var current_direction = current_velocity.normalized()
	
	#使用自然底数平滑移动
	var blend_factor = 1.0 - exp(-tracking_strength * delta * 3.0)
	var new_direction = current_direction.lerp(target_direction, blend_factor)
	
	return new_direction * speed

static func calculate_sine_wave_trajectory(
	initial_direction: Vector2,
	speed: float,
	time: float,
	wave_amplitude: float,
	wave_frequency: float,
	offset: float = 1
) -> Vector2:
	# 创建sin波动轨迹
	var forward = initial_direction.normalized()
	var perpendicular = Vector2(-forward.y, forward.x)
	
	# 计算波动偏移
	var wave_offset = sin(time * wave_frequency * 2.0 * PI) * wave_amplitude
	var direction = forward + perpendicular * wave_offset * 0.1  # 减小波动幅度
	
	# 只在初始化时应用随机偏移
	if offset > 0:
		return direction.normalized().rotated(create_randf_offset(offset)) * speed
	else:
		return direction.normalized() * speed

static func calculate_bounce_trajectory(
	current_velocity: Vector2,
	collision_normal: Vector2,
	bounce_damping: float = 0.8
) -> Vector2:
	#计算带有阻力的反弹
	var reflected = current_velocity.bounce(collision_normal)
	return reflected * bounce_damping
