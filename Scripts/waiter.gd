extends Node2D

signal waiter_despawned(lane: String)

@onready var waiter: AnimatedSprite2D = $Waiter
@onready var epoint: Sprite2D = $Epoint
@onready var table_pose: Sprite2D = $TablePose
@onready var bad: AudioStreamPlayer = $bad
@onready var footsteps: AudioStreamPlayer = $footsteps
@onready var food_pos: Node2D = $FoodPos
const WINE = preload("res://Scenes/wine.tscn")
const BURGER = preload("res://Scenes/burger.tscn")
var foods = [WINE, BURGER]
var selectedFood
var initial_scale: float = 0.25
var final_scale: float = 3.0
var min_y: float = -250.0
var max_y: float = 250.0
var target_y: float = 250.0
var look_y: float = -200.0
var is_looking: bool = false
var is_flipped: bool = false
var is_at_table: bool = false
var is_signaled: bool = false:
	set(value):
		is_signaled = value
		if epoint and not is_at_table:
			epoint.visible = is_signaled
			
var despawn_timer_started: bool = false
var lane: String = ""
var move_speed: float = 10.0

func _ready() -> void:
	selectedFood = foods.pick_random().instantiate()
	food_pos.add_child(selectedFood)
	var x_scale = -initial_scale if is_flipped else initial_scale
	scale = Vector2(x_scale, initial_scale)
	
	waiter.play()
	
	if epoint:
		epoint.visible = false

func _physics_process(delta: float) -> void:
	var progress = clamp((position.y - min_y) / (max_y - min_y), 0.0, 1.0)
	
	var current_scale = lerp(initial_scale, final_scale, progress)
	scale = Vector2(current_scale * (-1 if is_flipped else 1), current_scale)
	
	z_index = int(position.y)
	
	var spd = move_speed
	if is_signaled:
		spd = move_speed * 5
	
	if position.y >= look_y and not is_signaled and not is_looking:
		footsteps.stop()
		pause_and_look_left_and_right_waiting_for_signal()
		
	if not is_looking:
		waiter.play()
		if position.y < target_y:
			if not footsteps.playing:
				footsteps.play()
			position.y += spd * delta
		elif position.y >= target_y and not despawn_timer_started:
			footsteps.stop()
			despawn_timer_started = true
			position.y = target_y
			epoint.visible = false
			is_at_table = true
			waiter.visible = false
			food_pos.position = Vector2(120, -136)
			table_pose.visible = true
			var timer = get_tree().create_timer(3.0)
			timer.timeout.connect(_on_despawn_timer_timeout)

func pause_and_look_left_and_right_waiting_for_signal() -> void:
	var original_flip = is_flipped
	is_looking = true
	waiter.pause()
	for i in range(5):
		is_flipped = !is_flipped
		await get_tree().create_timer(0.5).timeout
		if is_signaled:
			is_flipped = original_flip
			is_looking = false
			return
	
	if not is_signaled:
		_on_despawn_timer_timeout()

	# Finished all 3 looks without being signaled — walk away and despawn
	var dir: float = sign(position.x) if position.x != 0.0 else 1.0
	position.x += dir * 100.0
	queue_free()

func _on_despawn_timer_timeout() -> void:
	waiter_despawned.emit(lane)
	queue_free()
