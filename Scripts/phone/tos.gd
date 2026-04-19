extends Node2D

signal finished

var phone_position: Vector2
var phone_size: Vector2

# ── Scroll state ─────────────────────────────────────────────────────
var _scroll_y: float = 0.0
var _max_scroll: float = 0.0
var _velocity: float = 0.0
const FRICTION := 0.98
const FLICK_MULTIPLIER := 4.0

var _dragging := false
var _last_mouse_y: float = 0.0
var _last_delta_y: float = 0.0

# ── Layout ───────────────────────────────────────────────────────────
var _content_height: float = 0.0
var _agree_rect: Rect2
var _at_bottom := false

const FONT_SIZE_TITLE := 16
const FONT_SIZE_BODY  := 12
const FONT_SIZE_BTN   := 15
const LINE_SPACING    := 18.0
const PAD             := 16.0

const TOS_FILES := [
	"res://Assets/Phone/tos/axolotl.txt",
	"res://Assets/Phone/tos/montypyt.txt"
]

var TOS_LINES: Array[String] = []


func setup(pos: Vector2, size: Vector2) -> void:
	var path: String = TOS_FILES[randi() % TOS_FILES.size()]
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open file: " + path)
		return
	TOS_LINES.clear()
	while not file.eof_reached():
		TOS_LINES.append(file.get_line())
	file.close()

	phone_position = pos
	phone_size     = size
	_content_height = TOS_LINES.size() * LINE_SPACING + PAD * 4 + 60.0
	var visible_h: float = phone_size.y - PAD * 2
	_max_scroll     = max(0.0, _content_height - visible_h)
	_agree_rect     = Rect2(
		phone_position.x + phone_size.x * 0.1,
		phone_position.y + phone_size.y - 54.0,
		phone_size.x * 0.8, 38.0)


func _process(_delta: float) -> void:
	if not _dragging:
		_scroll_y += _velocity
		_velocity *= FRICTION
		if abs(_velocity) < 0.1:
			_velocity = 0.0
	_scroll_y = clamp(_scroll_y, 0.0, _max_scroll)
	_at_bottom = _scroll_y >= _max_scroll - 2.0
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font

	# Background
	draw_rect(Rect2(phone_position, phone_size), Color(0.95, 0.93, 0.88), true)
	draw_rect(Rect2(phone_position, phone_size), Color(0.25, 0.25, 0.35), false, 1.5)

	var text_x   := phone_position.x + PAD
	var text_top := phone_position.y + PAD
	var text_bot := phone_position.y + phone_size.y - 60.0

	var y := text_top - _scroll_y + LINE_SPACING

	for i in TOS_LINES.size():
		if y + LINE_SPACING >= text_top and y <= text_bot:
			var line: String = TOS_LINES[i]
			var is_title: bool = i == 0
			# Detect numbered section headings like "1. Introduction" by checking first char is a digit
			var is_section: bool = line.length() > 0 and line[0].is_valid_int() and line.contains(".")
			var col   := Color(0.1, 0.1, 0.15)
			var line_fsize := FONT_SIZE_TITLE if is_title else FONT_SIZE_BODY
			if is_title:
				col = Color(0.1, 0.1, 0.5)
			elif is_section:
				col = Color(0.2, 0.2, 0.2)
			draw_string(font, Vector2(text_x, y), line,
				HORIZONTAL_ALIGNMENT_LEFT, phone_size.x - PAD * 2, line_fsize, col)
		y += LINE_SPACING

	# Gradient fade hinting there's more content below — drawn as stacked semi-transparent lines
	if not _at_bottom:
		for i in 32:
			var alpha: float = float(i) / 32.0 * 0.85
			var fy: float    = text_bot - 32 + i
			draw_line(
				Vector2(phone_position.x, fy),
				Vector2(phone_position.x + phone_size.x, fy),
				Color(0.95, 0.93, 0.88, alpha), 1.0)

	# Scrollbar
	var sb_w: float = 3.0
	var sb_x: float = phone_position.x + phone_size.x - sb_w - 2.0
	var sb_h: float = (phone_size.y - 60.0) * ((phone_size.y - 60.0) / _content_height)
	var sb_y: float = phone_position.y + (_scroll_y / _max_scroll) * ((phone_size.y - 60.0) - sb_h) if _max_scroll > 0 else phone_position.y
	draw_rect(Rect2(sb_x, sb_y, sb_w, sb_h), Color(0.5, 0.5, 0.6, 0.6), true)

	# Agree button
	var btn_col := Color(0.2, 0.6, 0.3) if _at_bottom else Color(0.5, 0.5, 0.5)
	var btn_r   := _agree_rect
	draw_rect(btn_r, btn_col, true)
	draw_rect(btn_r, btn_col.darkened(0.3), false, 1.5)
	var lbl: String  = "I Agree" if _at_bottom else "Read to the bottom first"
	var fsize: int   = FONT_SIZE_BTN if _at_bottom else 11
	var lsz: Vector2 = font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	draw_string(font,
		Vector2(btn_r.position.x + (btn_r.size.x - lsz.x) * 0.5,
				btn_r.position.y + (btn_r.size.y + lsz.y) * 0.5 - 4),
		lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color.WHITE)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var pos: Vector2 = make_input_local(event).position
			if Rect2(Vector2.ZERO, phone_size).has_point(pos):
				_dragging     = true
				_last_mouse_y = event.position.y
				_last_delta_y = 0.0
				_velocity     = 0.0
		else:
			_dragging = false
			# Convert the last frame's drag delta into momentum for inertia scrolling
			_velocity = -_last_delta_y * FLICK_MULTIPLIER
			if _at_bottom:
				# Agree button is in phone-local coords, but make_input_local gives SubViewport coords
				var pos: Vector2 = make_input_local(event).position
				if _agree_rect.has_point(pos + phone_position):
					finished.emit()

	elif event is InputEventMouseMotion and _dragging:
		var dy: float  = event.position.y - _last_mouse_y
		_last_delta_y  = dy
		_scroll_y     -= dy
		_scroll_y      = clamp(_scroll_y, 0.0, _max_scroll)
		_last_mouse_y  = event.position.y
