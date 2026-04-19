extends Node2D

signal camera_view_changed(view_name: String)

@onready var background: Sprite2D = $background
@onready var camera: Camera2D = $Camera
@onready var spawn_timer: Timer = Timer.new()
var camera_pos: String = "center"
const WAITER = preload("res://Scenes/waiter.tscn")

var waiterSpawnPositions = {
	"left": Vector2(-720, -250),
	"right": Vector2(720, -250)
}

var spawn_interval: float = 5.0
var waiter_rise_distance: float = 300.0
var waiter_rise_duration: float = 1.5
var waiter_initial_scale: float = 0.1
var waiter_final_scale: float = 1.0

var is_left_lane_occupied: bool = false
var is_right_lane_occupied: bool = false
var current_left_waiter: Node2D = null
var current_right_waiter: Node2D = null
var waiter_move_speed: float = 10.0


var camera_positions = {
	"center": Vector2(0, 0),
	"left": Vector2(-384, 0),
	"right": Vector2(384, 0),
	"down": Vector2(-100, 384)
}

var camera_zooms = {
	"center": Vector2(1.0, 1.0),
	"left": Vector2(1.0, 1.0),
	"right": Vector2(1.0, 1.0),
	"down": Vector2(2, 2)
}

var camera_tween: Tween
var background_tween: Tween
var animation_duration: float = 0.5
var is_nodding: bool = false

func _ready() -> void:
	camera.position = camera_positions["center"]
	camera.zoom = camera_zooms["center"]
	
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _process(delta: float) -> void:
	handle_camera_input()

func handle_camera_input() -> void:
	if Input.is_action_just_pressed("ui_left"):
		move_camera("left")
	elif Input.is_action_just_pressed("ui_right"):
		move_camera("right")
	elif Input.is_action_just_pressed("ui_up"):
		move_camera("center")
	elif Input.is_action_just_pressed("ui_down"):
		move_camera("down")
	elif Input.is_action_just_pressed("ui_accept") and camera_pos == "center" and not is_nodding:
		play_nodding_animation()

func move_camera(target_pos: String) -> void:

	if is_nodding:
		return

	if not camera_positions.has(target_pos):
		return
	
	if camera_pos == target_pos:
		return
		
	if ((camera_pos == "left" and target_pos == "right") or (camera_pos == "right" and target_pos == "left")):
		target_pos = "center"
	
	camera_pos = target_pos
	camera_view_changed.emit(camera_pos)
	
	if camera_tween:
		camera_tween.kill()
	
	camera_tween = create_tween()
	camera_tween.set_ease(Tween.EASE_IN_OUT)
	camera_tween.set_trans(Tween.TRANS_CUBIC)
	camera_tween.set_parallel(true)
	camera_tween.tween_property(camera, "position", camera_positions[target_pos], animation_duration)
	camera_tween.tween_property(camera, "zoom", camera_zooms[target_pos], animation_duration)

func play_nodding_animation() -> void:
	is_nodding = true
	
	if background_tween:
		background_tween.kill()
	
	var original_position = background.position
	var nod_distance = 20.0
	var nod_duration = 0.2
	
	background_tween = create_tween()
	background_tween.set_ease(Tween.EASE_IN_OUT)
	background_tween.set_trans(Tween.TRANS_SINE)
	
	for i in range(3):
		background_tween.tween_property(background, "position:y", original_position.y - nod_distance, nod_duration)
		background_tween.tween_property(background, "position:y", original_position.y + nod_distance, nod_duration)
	
	background_tween.tween_property(background, "position", original_position, nod_duration)
	background_tween.finished.connect(func(): is_nodding = false)

func _on_spawn_timer_timeout() -> void:
	spawn_waiter()

func spawn_waiter() -> void:
	var available_lanes = []
	
	if not is_left_lane_occupied:
		available_lanes.append("left")
	if not is_right_lane_occupied:
		available_lanes.append("right")
	
	if available_lanes.is_empty():
		return
	
	var random_lane = available_lanes[randi() % available_lanes.size()]
	var spawn_pos = waiterSpawnPositions[random_lane]
	
	var waiter = WAITER.instantiate()
	waiter.position = spawn_pos
	waiter.move_speed = waiter_move_speed
	waiter.waiter_despawned.connect(_on_waiter_despawned)
	
	if random_lane == "left":
		waiter.is_flipped = false
		waiter.lane = "left"
		is_left_lane_occupied = true
		current_left_waiter = waiter
	else:
		waiter.is_flipped = true
		waiter.lane = "right"
		is_right_lane_occupied = true
		current_right_waiter = waiter
	
	add_child(waiter)

func _on_waiter_despawned(lane: String) -> void:
	if lane == "left":
		is_left_lane_occupied = false
		current_left_waiter = null
	elif lane == "right":
		is_right_lane_occupied = false
		current_right_waiter = null

func _on_player_hand_signaled(side: String) -> void:
	if side == "Left" and is_instance_valid(current_left_waiter):
		current_left_waiter.is_signaled = true
	elif side == "Right" and is_instance_valid(current_right_waiter):
		current_right_waiter.is_signaled = true
