extends Node2D

signal finished

var phone_position: Vector2
var phone_size: Vector2

const ITEM_COUNT = 18
const STRIP_ITEMS = 120
const ITEM_SIZE = 140.0
const SCROLL_DURATION = 9.0
const INITIAL_SPEED = 4000.0
const RESULT_DISPLAY_TIME = 2.5

var _phase: String = "idle" # idle, spinning, result
var _textures: Dictionary = {} # item_number -> Texture2D
var _valid_items: Array[int] = [] # item numbers that have textures
var _item_strip: Array[int] = [] # item numbers in the strip
var _strip_sprites: Array[Sprite2D] = []
var _scroll_offset: float = 0.0
var _scroll_speed: float = 0.0
var _scroll_elapsed: float = 0.0
var _won_item: int = 0
var _case_sprite: Sprite2D = null
var _center_bar: ColorRect = null


func setup(pos: Vector2, size: Vector2) -> void:
	phone_position = pos
	phone_size = size

	for i in range(1, ITEM_COUNT + 1):
		var tex = load("res://Assets/Phone/case-opening/%d.png" % i) as Texture2D
		if tex != null:
			_textures[i] = tex
			_valid_items.append(i)

	_show_case()


func _show_case() -> void:
	_phase = "idle"
	var case_tex = load("res://Assets/Phone/case-opening/case.png") as Texture2D
	_case_sprite = Sprite2D.new()
	_case_sprite.texture = case_tex
	_case_sprite.centered = true
	_case_sprite.position = phone_position + phone_size * 0.5
	var scale_fit = min(phone_size.x * 0.6 / case_tex.get_width(), phone_size.y * 0.4 / case_tex.get_height())
	_case_sprite.scale = Vector2.ONE * scale_fit
	add_child(_case_sprite)

	var hint = Label.new()
	hint.text = "Tap to open"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = phone_position
	hint.set_deferred("size", phone_size)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 24)
	# push hint below the case
	hint.position.y += phone_size.y * 0.25
	add_child(hint)


func _pick_item() -> int:
	return _valid_items[randi() % _valid_items.size()]


func _pick_item_avoiding(recent: Array) -> int:
	var weights: Array[float] = []
	var candidates: Array[int] = []
	var total := 0.0
	for item in _valid_items:
		if item in recent:
			continue
		# Lower-numbered items get higher weight (1/i²), making them appear more often in filler slots
		var w = 1.0 / (item * item)
		candidates.append(item)
		weights.append(w)
		total += w
	if candidates.is_empty():
		return _pick_item()
	# Weighted random selection via linear scan of cumulative probability
	var r = randf() * total
	var acc := 0.0
	for i in range(candidates.size()):
		acc += weights[i]
		if r <= acc:
			return candidates[i]
	return candidates[0]


func _build_strip(target_item: int) -> void:
	_item_strip.clear()
	# Place the winning item near the end so it lines up under the center bar when scrolling stops
	var landing_index = STRIP_ITEMS - 10
	for i in range(STRIP_ITEMS):
		if i == landing_index:
			_item_strip.append(target_item)
		else:
			# Avoid repeating an item that appeared in the last 10 slots (prevents visual clustering)
			var recent = _item_strip.slice(max(0, i - 10), i)
			_item_strip.append(_pick_item_avoiding(recent))


func _start_spin() -> void:
	_phase = "spinning"
	_won_item = _pick_item()
	_build_strip(_won_item)

	# remove case/hint
	for child in get_children():
		child.queue_free()
	_strip_sprites.clear()

	var spin_audio = AudioStreamPlayer.new()
	spin_audio.stream = load("res://Assets/Phone/case-opening/spin.wav")
	add_child(spin_audio)
	spin_audio.play()

	var clip = Control.new()
	clip.position = phone_position
	clip.size = phone_size
	clip.clip_contents = true
	add_child(clip)

	var strip_y = phone_size.y * 0.5 - ITEM_SIZE * 0.5

	for i in range(_item_strip.size()):
		var item_num = _item_strip[i]
		var sprite = Sprite2D.new()
		sprite.texture = _textures[item_num]
		sprite.centered = false
		var tex_size = _textures[item_num].get_size()
		var s = ITEM_SIZE / max(tex_size.x, tex_size.y)
		sprite.scale = Vector2.ONE * s
		sprite.position = Vector2(i * ITEM_SIZE, strip_y)
		clip.add_child(sprite)
		_strip_sprites.append(sprite)

	# white center bar
	_center_bar = ColorRect.new()
	_center_bar.color = Color(1, 1, 1, 0.8)
	_center_bar.size = Vector2(4, ITEM_SIZE)
	_center_bar.position = Vector2(phone_size.x * 0.5 - 2, strip_y)
	clip.add_child(_center_bar)

	# Calculate how far the strip must scroll so the landing item's center aligns with the center bar
	var landing_index = STRIP_ITEMS - 10
	var landing_center_x = phone_position.x + landing_index * ITEM_SIZE + ITEM_SIZE * 0.5
	var center_x = phone_position.x + phone_size.x * 0.5
	var total_distance = landing_center_x - center_x
	_scroll_offset = 0.0
	_scroll_speed = INITIAL_SPEED
	_scroll_elapsed = 0.0

	# store target offset
	_target_offset = total_distance

	_update_strip_positions()


var _target_offset: float = 0.0


func _update_strip_positions() -> void:
	var strip_y = phone_size.y * 0.5 - ITEM_SIZE * 0.5
	for i in range(_strip_sprites.size()):
		var sprite = _strip_sprites[i]
		sprite.position.x = i * ITEM_SIZE - _scroll_offset
		sprite.position.y = strip_y


func _process(delta: float) -> void:
	if _phase != "spinning":
		return

	_scroll_elapsed += delta
	var t = clamp(_scroll_elapsed / SCROLL_DURATION, 0.0, 1.0)
	# ease out cubic
	# Ease-out cubic: fast start, decelerates to a stop — mimics real case-opening momentum
	var ease_t = 1.0 - pow(1.0 - t, 3.0)
	_scroll_offset = _target_offset * ease_t
	_update_strip_positions()

	if t >= 1.0:
		_phase = "result"
		_show_result()


func _show_result() -> void:
	var label = Label.new()
	var rarity_text = _rarity_label(_won_item)
	label.text = rarity_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.position = phone_position + Vector2(0, phone_size.y * 0.3)
	label.set_deferred("size", phone_size)
	add_child(label)

	await get_tree().create_timer(RESULT_DISPLAY_TIME).timeout
	finished.emit()


func _rarity_label(item: int) -> String:
	if item < 3:
		return "Common"
	elif item < 8:
		return "Uncommon"
	elif item < 12:
		return "Rare"
	elif item < 16:
		return "Epic"
	elif item < 18:
		return "Legendary"
	else:
		return "Contraband"


func _input(event: InputEvent) -> void:
	if _phase != "idle":
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _case_sprite and _case_sprite.get_rect().grow(20).has_point(_case_sprite.to_local(event.position)):
			_start_spin()
