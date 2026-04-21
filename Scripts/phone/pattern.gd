extends Node2D

signal finished

# Size of the grid (3 = 3x3, so 9 nodes total)
const GRID = 3
const NODE_RADIUS = 18
const LINE_WIDTH = 5

# Passed in by phone.gd via setup() - defines where and how large to draw
var phone_position: Vector2
var phone_size: Vector2

# Each grid has its own origin and cell size so the ref can be displayed smaller
var cell_size: float
var ref_cell_size: float
var ref_origin: Vector2
var input_origin: Vector2

# The set of nodes the player must visit (order doesn't matter)
var target_pattern: Array[int] = []
# The pattern the player is currently drawing
var current_pattern: Array[int] = []
var is_dragging := false


func setup(pos: Vector2, size: Vector2) -> void:
	phone_position = pos
	phone_size = size

	# Reference grid is small and centered at the top
	var ref_span = min(size.x * 0.4, size.y * 0.18)
	ref_cell_size = ref_span / GRID
	var ref_x = pos.x + (size.x - ref_span) / 2.0
	ref_origin = Vector2(ref_x, pos.y + size.y * 0.03 + 40.0)

	# Input grid fills the remaining height below the reference grid
	var ref_bottom = ref_origin.y + ref_span + 20.0
	var remaining = (pos.y + size.y) - ref_bottom - 20.0
	var input_span = min(size.x * 0.85, remaining)
	cell_size = input_span / GRID
	var input_x = pos.x + (size.x - input_span) / 2.0
	var input_bottom_y = pos.y + size.y - 100.0
	var input_y = max(ref_bottom, input_bottom_y - input_span)
	input_origin = Vector2(input_x, input_y)

	_generate_pattern()


# Returns true if nodes a and b are neighbors on the grid (including diagonals)
func _adjacent(a: int, b: int) -> bool:
	@warning_ignore("integer_division")
	var ar: int = a / GRID; var ac: int = a % GRID
	@warning_ignore("integer_division")
	var br: int = b / GRID; var bc: int = b % GRID
	return abs(ar - br) <= 1 and abs(ac - bc) <= 1 and a != b


# Builds target_pattern as a random walk of adjacent unvisited nodes
func _generate_pattern() -> void:
	var length = randi_range(4, 6)
	target_pattern.clear()
	var start = randi() % (GRID * GRID)
	target_pattern.append(start)
	while target_pattern.size() < length:
		var last = target_pattern.back()
		# Collect unvisited neighbors of the current tail node
		var neighbors: Array[int] = []
		for n in GRID * GRID:
			if _adjacent(last, n) and not target_pattern.has(n):
				neighbors.append(n)
		# Dead end - accept a shorter pattern rather than backtrack
		if neighbors.is_empty():
			break
		target_pattern.append(neighbors[randi() % neighbors.size()])


# Converts a flat node index to pixel coords within a grid at `origin`
func _node_world_pos(index: int, origin: Vector2, cs: float) -> Vector2:
	var col: int = index % GRID
	@warning_ignore("integer_division")
	var row: int = index / GRID
	return origin + Vector2(col * cs + cs / 2.0, row * cs + cs / 2.0)


# Draws one grid: connecting lines, node circles
func _draw_grid(origin: Vector2, cs: float, pattern: Array[int], is_ref: bool) -> void:
	var inactive_fill = Color(0.25, 0.25, 0.3)
	# Reference grid uses blue; input grid uses green
	var active_fill = Color(0.3, 0.6, 1.0) if is_ref else Color(0.2, 0.8, 0.5)
	var line_col = Color(0.3, 0.6, 1.0, 0.85) if is_ref else Color(0.2, 0.8, 0.5, 0.85)
	var node_r = cs * 0.35 # scale node radius with cell size

	# Draw connecting lines between consecutive pattern nodes
	for i in range(pattern.size() - 1):
		draw_line(
			_node_world_pos(pattern[i], origin, cs),
			_node_world_pos(pattern[i + 1], origin, cs),
			line_col, max(2.0, LINE_WIDTH * cs / cell_size), true
		)

	# Draw each node, then overlay a dark inner circle for a ring appearance
	for i in GRID * GRID:
		var p = _node_world_pos(i, origin, cs)
		var active = i in pattern
		draw_circle(p, node_r, active_fill if active else inactive_fill)
		draw_circle(p, node_r - 3.0, Color(0.08, 0.08, 0.12))


func _draw() -> void:
	var ref_label := "MATCH THIS"
	var ref_label_size := ThemeDB.fallback_font.get_string_size(ref_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	draw_string(ThemeDB.fallback_font, ref_origin + Vector2((ref_cell_size * GRID - ref_label_size.x) / 2.0, -8), ref_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	var draw_label := "DRAW THE PATTERN"
	var draw_lsz := ThemeDB.fallback_font.get_string_size(draw_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
	draw_string(ThemeDB.fallback_font, input_origin + Vector2((cell_size * GRID - draw_lsz.x) * 0.5, -14), draw_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)

	_draw_grid(ref_origin, ref_cell_size, target_pattern, true)
	_draw_grid(input_origin, cell_size, current_pattern, false)

	# Draw a faint line from the last visited node to the cursor while dragging
	if is_dragging and not current_pattern.is_empty():
		draw_line(
			_node_world_pos(current_pattern.back(), input_origin, cell_size),
			get_local_mouse_position(),
			Color(0.2, 0.8, 0.5, 0.5), LINE_WIDTH, true
		)


# Returns the index of the node under `pos`, or -1 if none is close enough
func _node_at(pos: Vector2, origin: Vector2, cs: float) -> int:
	for i in GRID * GRID:
		if pos.distance_to(_node_world_pos(i, origin, cs)) <= cs * 0.35 * 1.6:
			return i
	return -1


func _input(event: InputEvent) -> void:
	var local_pos = make_input_local(event).position
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Start a new drag only if the player clicks on a node
			var node = _node_at(local_pos, input_origin, cell_size)
			if node != -1:
				is_dragging = true
				current_pattern.clear()
				current_pattern.append(node)
				queue_redraw()
		else:
			# Mouse released - evaluate the drawn pattern
			if is_dragging:
				is_dragging = false
				queue_redraw()
				_check_pattern()

	elif event is InputEventMouseMotion and is_dragging:
		var node = _node_at(local_pos, input_origin, cell_size)
		# Append the node only if it hasn't been visited yet
		if node != -1 and not current_pattern.has(node):
			current_pattern.append(node)
		queue_redraw()


func _get_edges(pattern: Array[int]) -> Array:
	var edges = []
	for i in range(pattern.size() - 1):
		var a = pattern[i]; var b = pattern[i + 1]
		edges.append([min(a, b), max(a, b)])
	edges.sort()
	return edges


func _check_pattern() -> void:
	# Check same set of nodes
	var target_set = target_pattern.duplicate()
	var current_set = current_pattern.duplicate()
	target_set.sort()
	current_set.sort()
	if current_set != target_set:
		current_pattern.clear()
		queue_redraw()
		return

	# Normalize both edge sets (sorted [min,max] pairs) so direction of drawing doesn't matter
	if _get_edges(current_pattern) != _get_edges(target_pattern):
		current_pattern.clear()
		queue_redraw()
		return

	finished.emit()
