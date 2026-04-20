extends Node2D

var _speech_bubble: Control = null
var _waiting_for_click := false
var _is_typing := false
var _full_text := ""
var _current_label: Label = null
var _char_index := 0
var _typing_speed := 0.05

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var talking: AudioStreamPlayer = $talking

var messages: Array[String] = [
	"WAKE UP *Left click to proceed*",
	"You see that lovely lady over there? Shes your date so dont mess this up",
	"Use WASD to move around and get a good look of your environment",
	"During service waiters will be coming by on both the left and right. Be sure to flag them down because we aint got time to wait.",
	"Of course make sure you are playing attention to the lady of the hour! Oh how I wish I were in her shoes. If she pauses to get your reaction make sure you always nod in agreement *space bar*",
	"And if that horrendous phone alarm goes off again make sure you silence that quickly before your date notices",
	"When youre ready to kickstart the night give her a wave"
]
var message_index: int = 0


func _ready() -> void:
	animated_sprite_2d.play()
	show_speech_bubble(messages[message_index])


func _input(event: InputEvent) -> void:
	if not _waiting_for_click:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		
		if _is_typing:
			_complete_typing()
		else:
			message_index += 1
			if message_index < messages.size():
				show_speech_bubble(messages[message_index])
			else:
				_waiting_for_click = false
				if is_instance_valid(_speech_bubble):
					_speech_bubble.queue_free()
					_speech_bubble = null


func show_speech_bubble(text: String, duration: float = 0.0) -> void:
	if is_instance_valid(_speech_bubble):
		_speech_bubble.queue_free()

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.93)
	style.border_color = Color(0.2, 0.2, 0.2)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(200, 60)

	var label := Label.new()
	label.text = ""
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(180, 0)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	panel.add_child(label)

	panel.position = animated_sprite_2d.position + Vector2(60, -120)
	add_child(panel)
	_speech_bubble = panel
	_waiting_for_click = true
	_current_label = label
	_full_text = text
	_char_index = 0
	_is_typing = true
	
	talking.play()
	_type_next_character()

	if duration > 0.0:
		get_tree().create_timer(duration).timeout.connect(func() -> void:
			if is_instance_valid(_speech_bubble):
				_speech_bubble.queue_free()
				_speech_bubble = null
			_waiting_for_click = false
		)


func _type_next_character() -> void:
	if not _is_typing or not is_instance_valid(_current_label):
		return
	
	if _char_index < _full_text.length():
		_current_label.text = _full_text.substr(0, _char_index + 1)
		_char_index += 1
		get_tree().create_timer(_typing_speed).timeout.connect(_type_next_character)
	else:
		_finish_typing()


func _complete_typing() -> void:
	if not is_instance_valid(_current_label):
		return
	_current_label.text = _full_text
	_finish_typing()


func _finish_typing() -> void:
	_is_typing = false
	talking.stop()
