extends Node2D

var level_length: float = 60.0
var current_level_time: float = 0.0
@onready var world: SubViewport = $"CRT-Container/CRT/World-Container/World"
@onready var guide: Node2D = $"CRT-Container/CRT/guide"
@onready var curtains: Sprite2D = $"CRT-Container/CRT/curtains"

const RESTAURANT = preload("res://Scenes/restaurant.tscn")
const RESTAURANT_2 = preload("res://Scenes/restaurant2.tscn")
var levels = [RESTAURANT, RESTAURANT_2]
var local_cur_level

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	guide.visible = true
	var level = levels[0].instantiate()
	world.add_child(level)
	local_cur_level = level


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if Globals.player_health >= Globals.player_health_max:
		get_tree().change_scene_to_file("res://Scenes/lose.tscn")
	
	if Globals.cur_level == levels.size()-1:
		guide.visible = false
	if Globals.tutorial_complete:
		current_level_time += delta
	if current_level_time >= level_length:
		Globals.cur_level += 1
		current_level_time = 0.0
		if Globals.cur_level >= levels.size():
			get_tree().change_scene_to_file("res://Scenes/win.tscn")
		else:
			lower_curtains()
			await get_tree().create_timer(3).timeout
			local_cur_level.queue_free()
			local_cur_level = levels[Globals.cur_level].instantiate()
			world.add_child(local_cur_level)
			raise_curtains()
			
func lower_curtains() -> void:
	var tween = create_tween()
	tween.tween_property(curtains, "position:y", 265, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
func raise_curtains() -> void:
	var tween = create_tween()
	tween.tween_property(curtains, "position:y", -639.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
