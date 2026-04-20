@tool
extends Node2D

signal finished

const GAMES = ["ads", "pattern", "password", "case-opening", "tos", "cards"]

enum State {IDLE, PLAYING, FINISHED}
var _state: State = State.IDLE
var _current_game: Node2D = null

@export var phone_size: Vector2 = Vector2(338, 600):
	set(v):
		phone_size = v
		queue_redraw()
		if _sub_viewport:
			_sub_viewport.size = Vector2i(v)


var _tap_player: AudioStreamPlayer
var _sub_viewport: SubViewport

var _reflection_texture: Texture2D

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, phone_size), Color.BLACK, true)
	if _state == State.IDLE and _reflection_texture:
		draw_texture_rect(_reflection_texture, Rect2(Vector2.ZERO, phone_size), false, Color(1, 1, 1, 0.15))
	if _state == State.FINISHED:
		_draw_silenced_bell()


func _draw_silenced_bell() -> void:
	var cx := phone_size.x / 2.0
	var cy := phone_size.y / 2.0 - 30.0
	var color := Color.WHITE
	var lw := 5.0

	var dome_r := 50.0
	var dome_cy := cy - 10.0

	# Handle
	draw_rect(Rect2(cx - 8, dome_cy - dome_r - 18, 16, 20), color, true)

	# Dome (top semicircle: PI → 2*PI draws through top in Godot's Y-down space)
	draw_arc(Vector2(cx, dome_cy), dome_r, PI, 2.0 * PI, 48, color, lw)

	# Flared sides
	var flare := 14.0
	var body_bottom := dome_cy + 52.0
	draw_line(Vector2(cx - dome_r, dome_cy), Vector2(cx - dome_r - flare, body_bottom), color, lw)
	draw_line(Vector2(cx + dome_r, dome_cy), Vector2(cx + dome_r + flare, body_bottom), color, lw)

	# Rim
	draw_line(Vector2(cx - dome_r - flare - 10, body_bottom), Vector2(cx + dome_r + flare + 10, body_bottom), color, lw + 2.0)

	# Clapper
	draw_circle(Vector2(cx, body_bottom + 14.0), 7.0, color)

	# Slash
	var s := 78.0
	draw_line(Vector2(cx - s, cy + s), Vector2(cx + s, cy - s), Color.RED, lw + 1.0)

func _ready() -> void:
	_reflection_texture = load("res://Assets/Phone/reflection.png")
	_tap_player = AudioStreamPlayer.new()
	_tap_player.stream = load("res://Assets/Phone/phone-tap.wav")
	add_child(_tap_player)

	_sub_viewport = SubViewport.new()
	_sub_viewport.size = Vector2i(phone_size)
	_sub_viewport.transparent_bg = true
	_sub_viewport.disable_3d = true
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sub_viewport)

	var vp_sprite = Sprite2D.new()
	vp_sprite.texture = _sub_viewport.get_texture()
	vp_sprite.centered = false
	vp_sprite.position = Vector2.ZERO
	add_child(vp_sprite)

	_show_idle_screen()

func _input(event: InputEvent) -> void:
	var local_pos = get_local_mouse_position()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not Rect2(Vector2.ZERO, phone_size).has_point(local_pos):
			return
		if event.pressed:
			_tap_player.play()
		var sub_event = event.duplicate()
		sub_event.position = local_pos
		_sub_viewport.push_input(sub_event, true)
	elif event is InputEventMouseMotion:
		var sub_event = event.duplicate()
		sub_event.position = local_pos
		_sub_viewport.push_input(sub_event, true)

func start() -> void:
	if _state == State.PLAYING:
		return
	_transition(State.PLAYING)


func _clear_screen() -> void:
	for child in _sub_viewport.get_children():
		child.queue_free()
	_current_game = null


func _transition(next: State) -> void:
	_clear_screen()
	_state = next
	queue_redraw()
	match next:
		State.IDLE:
			_show_idle_screen()
		State.PLAYING:
			_start_game()
		State.FINISHED:
			_show_finish_screen()


func _show_idle_screen() -> void:
	pass


func _start_game() -> void:

	# comment out random game selection for testing specific games
	var game_name = GAMES[randi() % GAMES.size()]

	# 0:ads, 1:pattern, 2:password, 3:case-opening, 4:tos, 5:cards
	# uncomment to test specific games:
	#var game_name = GAMES[5]

	var script = load("res://Scripts/phone/%s.gd" % game_name)
	_current_game = Node2D.new()
	_current_game.set_script(script)
	_sub_viewport.add_child(_current_game)
	_current_game.setup(Vector2.ZERO, phone_size)
	_current_game.finished.connect(_on_game_finished)


func _on_game_finished() -> void:
	finished.emit()
	_transition(State.FINISHED)


func _show_finish_screen() -> void:
	var label = Label.new()
	label.text = "Phone silenced"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.position = Vector2(0, phone_size.y / 2.0 + 50.0)
	label.size = Vector2(phone_size.x, 50)
	_sub_viewport.add_child(label)
	await get_tree().create_timer(2.0).timeout
	_transition(State.IDLE)
