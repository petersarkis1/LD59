extends Node2D

var _speech_bubble: Control = null
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	animated_sprite_2d.play()
	show_speech_bubble("Welcome to this abomination of a game")
	await get_tree().create_timer(3.0).timeout
	show_speech_bubble("You see that lovely lady over there? Shes your date so dont fuck this up")
	await get_tree().create_timer(3.0).timeout
	show_speech_bubble("Use WASD to move around and when your ready left click to wave are your date to kickoff the night")

func _process(_delta: float) -> void:
	pass


func show_speech_bubble(text: String, duration: float = 3.0) -> void:
	if is_instance_valid(_speech_bubble):
		_speech_bubble.queue_free()

	var sprite: AnimatedSprite2D = $AnimatedSprite2D

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
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(180, 0)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	panel.add_child(label)

	# Place the bubble up and to the right, barely overlapping the sprite
	panel.position = sprite.position + Vector2(60, -120)
	add_child(panel)
	_speech_bubble = panel

	if duration > 0.0:
		get_tree().create_timer(duration).timeout.connect(func() -> void:
			if is_instance_valid(_speech_bubble):
				_speech_bubble.queue_free()
				_speech_bubble = null
		)
