extends Node2D

@onready var happy: AnimatedSprite2D = $Happy
@onready var angry: AnimatedSprite2D = $Angry
@onready var confused: AnimatedSprite2D = $Confused
var is_talking: bool = false
var active_date: AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	active_date = happy

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_talking:
		active_date.play()
	else:
		active_date.stop()


func _on_player_health_change(health: int) -> void:
	happy.visible = false
	angry.visible = false
	confused.visible = false
	if health <= 1:
		confused.visible = true
		active_date = confused
	elif health <= 3:
		angry.visible = true
		active_date = angry
	else:
		happy.visible = true
		active_date = happy
