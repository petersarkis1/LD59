extends Node2D

signal finished

const CLOSE_SIZE = Vector2(40, 40)  # top-right hit area in pixels

var phone_position: Vector2
var phone_size: Vector2
var ads: Array[Sprite2D] = []
var velocities: Array[Vector2] = []
var ad_sizes: Array[Vector2] = []
var texture: Texture2D

const SPEED = 40.0


func setup(pos: Vector2, size: Vector2) -> void:
	phone_position = pos
	phone_size = size
	texture = load("res://Assets/Phone/ads/ad.png")
	var tex_size = texture.get_size()
	for i in 10:
		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		var divisor = randf_range(1.5, 3.5)
		var max_size = phone_size / divisor
		# Fit the texture inside max_size while preserving aspect ratio
		var uniform_scale = min(max_size.x / tex_size.x, max_size.y / tex_size.y)
		sprite.scale = Vector2(uniform_scale, uniform_scale)
		var ad_size = tex_size * uniform_scale
		sprite.position = Vector2(
			randf_range(phone_position.x, phone_position.x + phone_size.x - ad_size.x),
			randf_range(phone_position.y, phone_position.y + phone_size.y - ad_size.y)
		)
		add_child(sprite)
		ads.append(sprite)
		# Random direction at fixed speed — ads bounce around like DVD screensavers
		velocities.append(Vector2.from_angle(randf_range(0.0, TAU)) * SPEED)
		ad_sizes.append(ad_size)


func _process(delta: float) -> void:
	for i in ads.size():
		var sprite = ads[i]
		var ad_size = ad_sizes[i]
		sprite.position += velocities[i] * delta
		var pos = sprite.position
		if pos.x < phone_position.x:
			pos.x = phone_position.x
			velocities[i].x = abs(velocities[i].x)
		elif pos.x > phone_position.x + phone_size.x - ad_size.x:
			pos.x = phone_position.x + phone_size.x - ad_size.x
			velocities[i].x = -abs(velocities[i].x)
		if pos.y < phone_position.y:
			pos.y = phone_position.y
			velocities[i].y = abs(velocities[i].y)
		elif pos.y > phone_position.y + phone_size.y - ad_size.y:
			pos.y = phone_position.y + phone_size.y - ad_size.y
			velocities[i].y = -abs(velocities[i].y)
		sprite.position = pos


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos = make_input_local(event).position
		# Iterate back-to-front so the topmost (last drawn) ad is hit first
		for i in range(ads.size() - 1, -1, -1):
			var sprite = ads[i]
			var ad_size = ad_sizes[i]
			# Close button lives in the top-right corner of the ad
			var top_right = Rect2(
				sprite.position + Vector2(ad_size.x - CLOSE_SIZE.x, 0),
				CLOSE_SIZE
			)
			if top_right.has_point(local_pos):
				sprite.queue_free()
				ads.remove_at(i)
				ad_sizes.remove_at(i)
				velocities.remove_at(i)
				if ads.is_empty():
					finished.emit()
				break
