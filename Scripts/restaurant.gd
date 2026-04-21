extends Node2D

signal camera_view_changed(view_name: String)
signal health_change(health: int)

@onready var background: Sprite2D = $background
@onready var camera: Camera2D = $Camera
@onready var spawn_timer: Timer = Timer.new()
var camera_pos: String = "center"
const WAITER = preload("res://Scenes/waiter.tscn")

var waiterSpawnPositions = {
	"left": Vector2(-750, 100),
	"right": Vector2(750, 100)
}

@onready var good: AudioStreamPlayer = $good
@onready var bad: AudioStreamPlayer = $bad
@onready var ambiance: AudioStreamPlayer = $ambiance

@onready var date: Node2D = $Date
@onready var phone_timer: Timer = $PhoneTimer
@onready var phone_ring: AudioStreamPlayer = $PhoneRing
@onready var phone_buzz: AudioStreamPlayer = $PhoneBuzz
@onready var date_cough: AudioStreamPlayer = $dateCough
@onready var door: AudioStreamPlayer = $door

@onready var date_timer: Timer = $DateTimer
@onready var date_dialog: AudioStreamPlayer = $dateDialog
var date_cooldown_timeout: int = randi_range(10,20)
var inital_phone_timeout: int = randi_range(15,25)
var phone_cooldown_timeout: int = randi_range(8,12)

var spawn_interval: float = 8.0
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
	"down": Vector2(2.5, 2.5)
}

var camera_tween: Tween
var background_tween: Tween
var animation_duration: float = 0.5
var is_nodding: bool = false

var is_round_started: bool = false
var is_date_waiting: bool = false
var date_waiting_duration: float = 0.0
var date_warning_time: float = 2.0
var date_warned: bool = false
var date_damage_time: float = 6.0
var is_phone_waiting: bool = false
var phone_waiting_duration: float = 0.0
var phone_warning_time: float = 6.0
var phone_warned: bool = false
var phone_damage_time: float = 15.0

func _ready() -> void:
	date_dialog.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	camera.position = camera_positions["center"]
	camera.zoom = camera_zooms["center"]

func _process(delta: float) -> void:
	handle_camera_input()
	handle_date_event(delta)
	handle_phone_event(delta)
	
func startRound() -> void:
	Globals.tutorial_complete = true
	date_dialog.play()
	ambiance.play()
	date.is_talking = true
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	
	#date timer
	date_timer.start(date_cooldown_timeout)
	#phone timer
	phone_timer.start(inital_phone_timeout)

func handle_date_event(delta) -> void:
	if is_date_waiting:
		date_waiting_duration += delta
		if is_nodding:
			is_date_waiting = false
			date_warned = false
			good.play()
			await get_tree().create_timer(1.0).timeout
			date_dialog.play()
			date.is_talking = true
			date_timer.start(date_cooldown_timeout)
		else:
			if date_waiting_duration > date_warning_time and not date_warned:
				date_cough.play()
				date_warned = true
			if date_waiting_duration > date_damage_time:
				lose_health()
				is_date_waiting = false
				date_warned = false
				await get_tree().create_timer(1.0).timeout
				date_dialog.play()
				date.is_talking = true
				date_timer.start(date_cooldown_timeout)
	
func handle_phone_event(delta) -> void:
	if is_phone_waiting:
		phone_waiting_duration += delta
		if phone_waiting_duration > phone_warning_time and not phone_warned:
			phone_ring.volume_db += 2.0
			phone_buzz.volume_db += 5.0
			phone_warned = true
		if phone_waiting_duration > phone_damage_time:
			lose_health()
			phone_waiting_duration = 0

func lose_health() -> void:
	bad.play()
	Globals.player_health += 10
	health_change.emit(Globals.player_health)
	if Globals.player_health <= 0:
		pass
		

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
	
	var original_position = camera.position
	var nod_distance = 20.0
	var nod_duration = 0.2
	
	background_tween = create_tween()
	background_tween.set_ease(Tween.EASE_IN_OUT)
	background_tween.set_trans(Tween.TRANS_SINE)
	
	for i in range(3):
		background_tween.tween_property(camera, "position:y", original_position.y - nod_distance, nod_duration)
		background_tween.tween_property(camera, "position:y", original_position.y + nod_distance, nod_duration)
	
	background_tween.tween_property(camera, "position", original_position, nod_duration)
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
	door.play()

func _on_waiter_despawned(lane: String, missed: bool) -> void:
	if missed:
		lose_health()
	else:
		good.play()
	if lane == "left":
		is_left_lane_occupied = false
		current_left_waiter = null
	elif lane == "right":
		is_right_lane_occupied = false
		current_right_waiter = null

func _on_player_hand_signaled(side: String) -> void:
	if camera_pos == "center" and not is_round_started:
		is_round_started = true
		startRound()
	if camera_pos == "left" and side == "Left" and is_instance_valid(current_left_waiter):
		current_left_waiter.is_signaled = true
	elif camera_pos == "right" and side == "Right" and is_instance_valid(current_right_waiter):
		current_right_waiter.is_signaled = true


func _on_phone_start_timer_timeout() -> void:
	var phone = find_child("Phone", true, false)
	if not phone.finished.is_connected(_on_phone_finished):
		phone.finished.connect(_on_phone_finished)
	phone.start()
	
	phone_ring.play()
	phone_ring.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	phone_buzz.play()
	phone_buzz.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	is_phone_waiting = true
	phone_waiting_duration = 0

func _on_phone_finished() -> void:
	is_phone_waiting = false
	if phone_warned:
		phone_ring.volume_db -= 2.0
		phone_buzz.volume_db -= 5.0
	phone_warned = false
	phone_waiting_duration = 0
	phone_timer.start(phone_cooldown_timeout)
	phone_ring.stop()
	phone_buzz.stop()
	good.play()


func _on_date_start_timer_timeout() -> void:
	date_dialog.stop()
	date.is_talking = false
	is_date_waiting = true
	date_waiting_duration = 0
