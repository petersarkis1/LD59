extends Node2D

signal finished

# ── Config ──────────────────────────────────────────────────────────
const PASSWORDS := ["bing bong", "peenar snipper guy", "teezy", "charlie", "radio", 
					"blue rose", "log lady", "damn good coffee", "doppelganger", "glorp", 
					"bingus", "fire walk", "he he he he he", "yellow king", "blue velvet", 
					"outer heaven", "diamond dog", "cathode ray tube", "psycho mantis", "solid snake",
					"liquid snake", "big boss"]
var TARGET_PASSWORD: String = ""
const FLASH_TIME      := 0.6
const FONT_SIZE_KEY   := 15
const FONT_SIZE_INPUT := 24
const FONT_SIZE_HINT  := 12
const CORNER_RADIUS   := 5.0

# iPhone QWERTY rows
const ROW0 := ["1","2","3","4","5","6","7","8","9","0"]
const ROW1 := ["q","w","e","r","t","y","u","i","o","p"]
const ROW2 := ["a","s","d","f","g","h","j","k","l"]
const ROW3 := ["z","x","c","v","b","n","m"]
const ROW4 := [" "]

# ── State ────────────────────────────────────────────────────────────
var phone_position: Vector2
var phone_size:     Vector2

var _current_input: String = ""
var _flash_wrong:   bool   = false
var _flash_timer:   float  = 0.0

var _key_rects:  Array[Rect2]  = []
var _key_labels: Array[String] = []
var _backspace_rect: Rect2
var _go_rect:        Rect2
var _input_rect:     Rect2


func setup(pos: Vector2, size: Vector2) -> void:
	TARGET_PASSWORD = PASSWORDS[randi() % PASSWORDS.size()]
	phone_position = pos
	phone_size     = size
	_build_layout()


func _build_layout() -> void:
	_key_rects.clear()
	_key_labels.clear()

	var pad   : float = phone_size.x * 0.03
	var left  : float = phone_position.x + pad
	var width : float = phone_size.x - pad * 2.0

	# Input field near the top
	_input_rect = Rect2(left, phone_position.y + phone_size.y * 0.25, width, 44.0)

	# Keyboard anchored to the bottom of the phone
	var key_h     : float = phone_size.y * 0.085
	var gap       : float = phone_size.x * 0.012
	var action_h  : float = key_h
	var kb_bottom : float = phone_position.y + phone_size.y - pad
	# 5 standard rows + 1 action row (backspace/go), anchored from the bottom up
	var kb_top    : float = kb_bottom - 5.0 * (key_h + gap) - (action_h + gap)

	var row_y : float = kb_top

	# Row 0 — numbers
	_layout_row(ROW0, row_y, key_h, left, width, gap)
	row_y += key_h + gap

	# Row 1 — qwerty
	_layout_row(ROW1, row_y, key_h, left, width, gap)
	row_y += key_h + gap

	# Row 2 — asdfghjkl (slightly indented)
	_layout_row(ROW2, row_y, key_h, left + width * 0.055, width * 0.89, gap)
	row_y += key_h + gap

	# Row 3 — [backspace] [zxcvbnm] [go]
	var action_w : float = width * 0.165
	_backspace_rect = Rect2(left, row_y, action_w, action_h)
	_layout_row(ROW3, row_y, action_h,
				left + action_w + gap,
				width - 2.0 * (action_w + gap), gap)
	_go_rect = Rect2(left + width - action_w, row_y, action_w, action_h)
	row_y += action_h + gap

	# Row 4 — spacebar
	_layout_row(ROW4, row_y, action_h, left + width * 0.1, width * 0.8, gap)


func _layout_row(keys: Array, y: float, h: float,
				 row_left: float, row_width: float, gap: float) -> void:
	var n     : int   = keys.size()
	var key_w : float = (row_width - gap * (n - 1)) / float(n)
	for i in n:
		var x : float = row_left + i * (key_w + gap)
		_key_rects.append(Rect2(x, y, key_w, h))
		_key_labels.append(keys[i])


# ── Draw ─────────────────────────────────────────────────────────────
func _draw() -> void:
	var font : Font = ThemeDB.fallback_font

	var phone_bg  := Color(0.07, 0.07, 0.09)
	var kb_bg     := Color(0.13, 0.13, 0.16)
	var key_col   := Color(0.32, 0.32, 0.38)
	var key_dark  := Color(0.18, 0.18, 0.22)
	var key_hov   := Color(0.50, 0.50, 0.58)
	var go_col    := Color(0.25, 0.52, 1.00)
	var go_hov    := Color(0.40, 0.65, 1.00)
	var white     := Color.WHITE
	var hint_col  := Color(0.55, 0.65, 1.00)
	var wrong_col := Color(1.00, 0.30, 0.30)

	# Phone body
	draw_rect(Rect2(phone_position, phone_size), phone_bg, true)
	draw_rect(Rect2(phone_position, phone_size), Color(0.25, 0.25, 0.35), false, 1.5)

	# Hint
	var hint    : String  = "Password: %s" % TARGET_PASSWORD
	var hint_sz : Vector2 = font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_HINT)
	draw_string(font,
		Vector2(phone_position.x + (phone_size.x - hint_sz.x) * 0.5,
				_input_rect.position.y - 10),
		hint, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_HINT, hint_col)

	# Input field
	var field_bg  : Color = wrong_col.darkened(0.55) if _flash_wrong else Color(0.16, 0.16, 0.22)
	var field_bdr : Color = wrong_col if _flash_wrong else Color(0.38, 0.38, 0.55)
	_draw_rounded_rect(_input_rect, field_bg, CORNER_RADIUS)
	_draw_rounded_rect_outline(_input_rect, field_bdr, CORNER_RADIUS, 1.5)

	var display : String  = _current_input if not _current_input.is_empty() else "▮"
	var txt_col : Color   = wrong_col if _flash_wrong else white
	var txt_sz  : Vector2 = font.get_string_size(display, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_INPUT)
	draw_string(font,
		Vector2(_input_rect.position.x + (_input_rect.size.x - txt_sz.x) * 0.5,
				_input_rect.position.y + (_input_rect.size.y + txt_sz.y) * 0.5 - 10),
		display, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_INPUT, txt_col)
	# Keyboard backing
	var kb_rect : Rect2 = Rect2(
		phone_position.x,
		_key_rects[0].position.y - 6.0,
		phone_size.x,
		phone_position.y + phone_size.y - (_key_rects[0].position.y - 6.0)
	)
	draw_rect(kb_rect, kb_bg, true)

	# Regular keys
	var mouse : Vector2 = get_local_mouse_position()
	for i in _key_rects.size():
		var r   : Rect2  = _key_rects[i]
		var hov : bool   = r.has_point(mouse)
		# First 10 keys are the number row (ROW0), which uses a darker shade
		var bg  : Color  = key_hov if hov else (key_dark if i < 10 else key_col)
		_draw_rounded_rect(r, bg, CORNER_RADIUS)
		var lbl : String  = _key_labels[i]
		var ls  : Vector2 = font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_KEY)
		draw_string(font,
			Vector2(r.position.x + (r.size.x - ls.x) * 0.5,
					r.position.y + (r.size.y + ls.y) * 0.5 - 4),
			lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_KEY, white)

	# Backspace
	var bs_hov : bool = _backspace_rect.has_point(mouse)
	_draw_rounded_rect(_backspace_rect, key_hov if bs_hov else key_dark, CORNER_RADIUS)
	var bs_lbl : String  = "⌫"
	var bs_sz  : Vector2 = font.get_string_size(bs_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_KEY + 2)
	draw_string(font,
	Vector2(_backspace_rect.position.x + (_backspace_rect.size.x - bs_sz.x) * 0.5,
			_backspace_rect.position.y + (_backspace_rect.size.y + bs_sz.y) * 0.5 - 4),
	bs_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_KEY + 2, white)

	# Go
	var go_hov_b : bool = _go_rect.has_point(mouse)
	_draw_rounded_rect(_go_rect, go_hov if go_hov_b else go_col, CORNER_RADIUS)
	var go_lbl : String  = "Go"
	var go_sz  : Vector2 = font.get_string_size(go_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_KEY)
	draw_string(font,
		Vector2(_go_rect.position.x + (_go_rect.size.x - go_sz.x) * 0.5,
				_go_rect.position.y + (_go_rect.size.y + go_sz.y) * 0.5 - 4),
		go_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_KEY, white)


func _draw_rounded_rect(r: Rect2, color: Color, radius: float) -> void:
	draw_colored_polygon(_rounded_rect_points(r, radius), color)


func _draw_rounded_rect_outline(r: Rect2, color: Color, radius: float, width: float) -> void:
	var pts : PackedVector2Array = _rounded_rect_points(r, radius)
	pts.append(pts[0])
	draw_polyline(pts, color, width, true)


func _rounded_rect_points(r: Rect2, radius: float) -> PackedVector2Array:
	var pts     : PackedVector2Array = PackedVector2Array()
	var corners : Array = [
		Vector2(r.position.x + radius,            r.position.y + radius),
		Vector2(r.position.x + r.size.x - radius, r.position.y + radius),
		Vector2(r.position.x + r.size.x - radius, r.position.y + r.size.y - radius),
		Vector2(r.position.x + radius,            r.position.y + r.size.y - radius),
	]
		# Corners go: top-left, top-right, bottom-right, bottom-left — angles sweep clockwise
	var start_angles : Array = [PI, 1.5 * PI, 0.0, 0.5 * PI]
	var steps : int = 6
	for c in 4:
		for s in steps:
			var angle : float = start_angles[c] + (0.5 * PI / steps) * s
			pts.append(corners[c] + Vector2(cos(angle), sin(angle)) * radius)
	return pts


# ── Input ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _flash_wrong:
		return
	if not (event is InputEventMouseButton and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		return

	var pos: Vector2 = make_input_local(event).position

	if _backspace_rect.has_point(pos):
		if not _current_input.is_empty():
			_current_input = _current_input.left(_current_input.length() - 1)
		queue_redraw()
		return

	if _go_rect.has_point(pos):
		_check_password()
		return

	for i in _key_rects.size():
		if _key_rects[i].has_point(pos):
			_current_input += _key_labels[i]
			queue_redraw()
			return


func _check_password() -> void:
	if _current_input == TARGET_PASSWORD:
		finished.emit()
	elif _current_input.length() > 0:
		_flash_wrong = true
		_flash_timer = FLASH_TIME
		queue_redraw()


# ── Process ───────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if _flash_wrong:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_flash_wrong   = false
			_current_input = ""
			queue_redraw()
