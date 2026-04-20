extends Node2D

@onready var rich_text_label: RichTextLabel = $Control/RichTextLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rich_text_label.text = str(Globals.player_health)
