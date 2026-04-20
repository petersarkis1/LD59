extends Node2D

const GAME_SCENE = preload("res://Scenes/game.tscn")

@onready var start_btn: Sprite2D = $startBtn

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if start_btn.get_rect().has_point(start_btn.to_local(get_global_mouse_position())):
			get_tree().change_scene_to_packed(GAME_SCENE)
