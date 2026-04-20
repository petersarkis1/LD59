extends Node2D

var level_length: float = 3.0
var current_level_time: float = 0.0
@onready var world: SubViewport = $"CRT-Container/CRT/World-Container/World"
@onready var guide: Node2D = $"CRT-Container/CRT/guide"

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
			print('going to new level')
			print(Globals.cur_level)
			local_cur_level.queue_free()
			local_cur_level = levels[Globals.cur_level].instantiate()
			world.add_child(local_cur_level)
