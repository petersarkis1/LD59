extends Node2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var wine: Node2D = $"."
@onready var drink: AudioStreamPlayer = $Drink

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if sprite_2d.get_rect().has_point(sprite_2d.to_local(get_global_mouse_position())):
			if wine.get_parent().get_parent().is_at_table:
				var waiter = wine.get_parent().get_parent()
				if waiter.is_at_table:
					sprite_2d.visible = false
					drink.play()
					Globals.player_health -= 2
					await get_tree().create_timer(3).timeout
					queue_free()
