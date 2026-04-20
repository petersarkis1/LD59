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

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, phone_size), Color.BLACK, true)

func _ready() -> void:
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
	match next:
		State.IDLE:
			_show_idle_screen()
		State.PLAYING:
			_start_game()
		State.FINISHED:
			_show_finish_screen()


func _show_idle_screen() -> void:
	var label = Label.new()
	label.text = "Idle"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sub_viewport.add_child(label)


func _start_game() -> void:

	# var game_name = GAMES[randi() % GAMES.size()]
	var game_name = GAMES[2]

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
	label.text = "Done!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sub_viewport.add_child(label)
	await get_tree().create_timer(2.0).timeout
	_transition(State.IDLE)
