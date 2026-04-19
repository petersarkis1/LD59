extends Node2D

signal waiter_despawned(lane: String)

@onready var waiter: AnimatedSprite2D = $Waiter
@onready var epoint: Sprite2D = $Epoint

var initial_scale: float = 0.25
var final_scale: float = 3.0
var min_y: float = -250.0
var max_y: float = 250.0
var target_y: float = 250.0
var is_flipped: bool = false
var is_signaled: bool = false:
	set(value):
		is_signaled = value
		if epoint:
			epoint.visible = is_signaled
			
var despawn_timer_started: bool = false
var lane: String = ""
var move_speed: float = 10.0

func _ready() -> void:
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
	
	if position.y < target_y:
		position.y += spd * delta
	elif position.y >= target_y and not despawn_timer_started:
		despawn_timer_started = true
		position.y = target_y
		epoint.visible = false
		var timer = get_tree().create_timer(1.0)
		timer.timeout.connect(_on_despawn_timer_timeout)

func _on_despawn_timer_timeout() -> void:
	waiter_despawned.emit(lane)
	queue_free()
