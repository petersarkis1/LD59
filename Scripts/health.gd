extends Node2D

signal health_maxed

@export var bar_size: Vector2 = Vector2(278, 510)
@export var bubble_count: int = 18

var _prev_health: int = -1
var _time: float = 0.0
var _bubbles: Array = []
var _display_ratio: float = 1.0

func _ready() -> void:
	for i in bubble_count:
		_bubbles.append(_make_bubble(randf_range(0.0, 1.0)))

func _make_bubble(y_ratio: float) -> Dictionary:
	return {
		"x": randf_range(5.0, bar_size.x - 5.0),
		"y": bar_size.y * y_ratio,
		"r": randf_range(2.5, 6.0),
		"speed": randf_range(25.0, 70.0),
	}

func _process(delta: float) -> void:
	var h := Globals.player_health
	if h != _prev_health:
		_prev_health = h
		if h >= Globals.player_health_max:
			health_maxed.emit()

	_time += delta

	var ratio := clampf(float(Globals.player_health) / float(Globals.player_health_max), 0.0, 1.0)
	var fill_top := bar_size.y * (1.0 - ratio)

	for b in _bubbles:
		b["y"] -= b["speed"] * delta
		if b["y"] < fill_top - b["r"]:
			b["y"] = bar_size.y
			b["x"] = randf_range(5.0, bar_size.x - 5.0)
			b["r"] = randf_range(2.5, 6.0)
			b["speed"] = randf_range(25.0, 70.0)

	queue_redraw()

func _draw() -> void:
	var ratio := clampf(float(Globals.player_health) / float(Globals.player_health_max), 0.0, 1.0)
	if ratio <= 0.0:
		return

	var fill_top := bar_size.y * (1.0 - ratio)
	var wave_amp := 5.0
	var wave_steps := 40

	# Build polygon with animated wavy top edge
	var points := PackedVector2Array()
	points.append(Vector2(0.0, bar_size.y))
	points.append(Vector2(bar_size.x, bar_size.y))
	for i in range(wave_steps + 1):
		var t := float(i) / wave_steps
		var x := bar_size.x * (1.0 - t)
		var y := fill_top + sin(t * TAU * 2.5 + _time * 3.5) * wave_amp
		points.append(Vector2(x, y))

	draw_colored_polygon(points, Color.RED)

	# Bubbles — slightly lighter red, only within the fluid
	var bubble_col := Color(1.0, 0.45, 0.45, 0.75)
	for b in _bubbles:
		if b["y"] > fill_top and b["y"] < bar_size.y:
			draw_circle(Vector2(b["x"], b["y"]), b["r"], bubble_col)
