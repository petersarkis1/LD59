extends Node2D

signal finished

# ── Config ──────────────────────────────────────────────────────────
# Classic MP3 transport symbols — drawn as vectors in each button
enum Sym { PLAY, BACK, STOP, REC, FF, REW }
const SYMBOL_COUNT := 6

const PASSWORDS: Array = [
	[Sym.PLAY, Sym.BACK, Sym.PLAY, Sym.BACK],
	[Sym.STOP, Sym.REC,  Sym.STOP, Sym.REC],
	[Sym.PLAY, Sym.STOP, Sym.REC,  Sym.FF],
	[Sym.BACK, Sym.FF,   Sym.PLAY, Sym.STOP],
	[Sym.REC,  Sym.REC,  Sym.FF,   Sym.PLAY],
	[Sym.REW,  Sym.PLAY, Sym.STOP, Sym.REC,  Sym.FF],
	[Sym.FF,   Sym.BACK, Sym.REC,  Sym.STOP],
	[Sym.PLAY, Sym.FF,   Sym.REW,  Sym.BACK],
	[Sym.REC,  Sym.STOP, Sym.FF,   Sym.PLAY, Sym.BACK],
	[Sym.BACK, Sym.REC,  Sym.PLAY, Sym.REW],
]

# Display glyphs for each symbol (for LCD readout)
const SYM_GLYPH: Array[String] = ["▶", "◀", "■", "●", "▶▶", "◀◀"]
const SYM_LABEL: Array[String] = ["PLAY", "BACK", "STOP", "REC", "FF", "REW"]

const MAX_INPUT  := 8
const FLASH_TIME := 0.6

# Winamp classic palette
const COL_WIN_BG    := Color(0.098, 0.098, 0.110)
const COL_TITLE_BG  := Color(0.000, 0.255, 0.255)
const COL_TITLE_ACT := Color(0.000, 0.420, 0.420)
const COL_DISPLAY   := Color(0.000, 0.000, 0.000)
const COL_LCD_GREEN := Color(0.090, 0.820, 0.310)
const COL_LCD_DIM   := Color(0.025, 0.220, 0.085)
const COL_BTN       := Color(0.188, 0.188, 0.208)
const COL_BTN_HOV   := Color(0.260, 0.260, 0.290)
const COL_BTN_TXT   := Color(0.780, 0.780, 0.820)
const COL_GOLD      := Color(0.820, 0.700, 0.000)
const COL_RED       := Color(0.850, 0.200, 0.200)

var TARGET_PASSWORD: Array = []

# ── State ────────────────────────────────────────────────────────────
var phone_position: Vector2
var phone_size:     Vector2

var _current_input: Array  = []
var _flash_wrong:   bool   = false
var _flash_timer:   float  = 0.0
var _blink_timer:   float  = 0.0
var _blink_on:      bool   = true
var _scroll_t:      float  = 0.0

# Layout
var _win_rect:     Rect2
var _title_rect:   Rect2
var _display_rect: Rect2
var _eq_rect:      Rect2
var _seek_rect:    Rect2
var _btn_rects:    Array = []
var _del_rect:     Rect2
var _enter_rect:   Rect2


func setup(pos: Vector2, size: Vector2) -> void:
	TARGET_PASSWORD = PASSWORDS[randi() % PASSWORDS.size()]
	phone_position  = pos
	phone_size      = size
	_build_layout()


func _build_layout() -> void:
	_btn_rects.clear()

	var pw: float = phone_size.x
	var ph: float = phone_size.y

	_win_rect = Rect2(phone_position.x + pw * 0.04, phone_position.y + ph * 0.05,
		pw * 0.92, ph * 0.90)

	var wx: float = _win_rect.position.x
	var wy: float = _win_rect.position.y
	var ww: float = _win_rect.size.x

	_title_rect   = Rect2(wx, wy, ww, 16.0)

	# Tall display — takes ~38% of window height
	_display_rect = Rect2(wx + 2.0, wy + 18.0, ww - 4.0, _win_rect.size.y * 0.38)

	# EQ only occupies a top strip inside display
	_eq_rect = Rect2(
		_display_rect.position.x + _display_rect.size.x * 0.60,
		_display_rect.position.y + 4.0,
		_display_rect.size.x * 0.36,
		24.0)

	_seek_rect = Rect2(wx + 2.0,
		_display_rect.position.y + _display_rect.size.y + 4.0,
		ww - 4.0, 8.0)

	# Button grid: 3×2, fills space between seek and action row
	var action_h: float = 60.0
	var btn_top:  float = _seek_rect.position.y + _seek_rect.size.y + 6.0
	var btn_bot:  float = _win_rect.position.y + _win_rect.size.y - action_h - 6.0
	var gap:      float = 5.0
	var btn_w:    float = (ww - 4.0 - gap * 2.0) / 3.0
	var btn_h:    float = (btn_bot - btn_top - gap) / 2.0
	for i in 6:
		var col: int   = i % 3
		var row: int   = int(i / 3.0)
		_btn_rects.append(Rect2(
			wx + 2.0 + col * (btn_w + gap),
			btn_top + row * (btn_h + gap),
			btn_w, btn_h))

	var action_y: float = _win_rect.position.y + _win_rect.size.y - action_h
	var half_w:   float = (ww - 4.0 - gap) * 0.5
	_del_rect   = Rect2(wx + 2.0,              action_y, half_w, action_h)
	_enter_rect = Rect2(wx + 2.0 + half_w + gap, action_y, half_w, action_h)


func _process(delta: float) -> void:
	_blink_timer += delta
	if _blink_timer >= 0.5:
		_blink_timer = 0.0
		_blink_on = not _blink_on
	_scroll_t += delta
	queue_redraw()

	if _flash_wrong:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_flash_wrong   = false
			_current_input.clear()


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font

	draw_rect(Rect2(phone_position, phone_size), Color(0.05, 0.05, 0.06), true)
	draw_rect(Rect2(_win_rect.position + Vector2(3, 3), _win_rect.size), Color(0, 0, 0, 0.6), true)
	draw_rect(_win_rect, COL_WIN_BG, true)
	draw_rect(_win_rect, Color(0.35, 0.35, 0.40), false, 1.0)

	# ── Title bar ─────────────────────────────────────────────────────
	draw_rect(_title_rect, COL_TITLE_BG, true)
	for sx in range(0, int(_title_rect.size.x), 4):
		draw_line(
			Vector2(_title_rect.position.x + sx, _title_rect.position.y),
			Vector2(_title_rect.position.x + sx, _title_rect.position.y + _title_rect.size.y),
			COL_TITLE_ACT, 2.0)
	draw_string(font, Vector2(_title_rect.position.x + 4.0, _title_rect.position.y + 11.0),
		"WINAMP", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.9, 0.9, 1.0))
	for i in 3:
		var dot_col: Color = [Color(0.9,0.3,0.3), Color(0.9,0.7,0.1), Color(0.2,0.7,0.2)][i]
		draw_circle(Vector2(_title_rect.position.x + _title_rect.size.x - 8.0 - i * 10.0,
			_title_rect.position.y + 8.0), 3.5, dot_col)

	# ── Main display ──────────────────────────────────────────────────
	draw_rect(_display_rect, COL_DISPLAY, true)
	draw_rect(_display_rect, Color(0.08, 0.18, 0.10), false, 1.0)

	var dx: float = _display_rect.position.x
	var dy: float = _display_rect.position.y
	var dw: float = _display_rect.size.x
	var dh: float = _display_rect.size.y

	# Top strip: time + scrolling title + EQ
	var t_secs: int = int(_scroll_t) % 60
	var t_mins: int = int(_scroll_t / 60.0) % 60
	draw_string(font, Vector2(dx + 6.0, dy + 13.0),
		"%02d:%02d" % [t_mins, t_secs], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COL_LCD_GREEN)

	var title_str: String = "  LOCKED TRACK  //  ENTER ACCESS CODE  //  "
	var scroll_x: float = fmod(_scroll_t * 30.0, float(title_str.length()) * 6.5)
	draw_string(font,
		Vector2(dx + 46.0 - scroll_x, dy + 13.0),
		title_str + title_str, HORIZONTAL_ALIGNMENT_LEFT, int(dw - 52.0), 9, COL_LCD_DIM)

	# EQ bars
	var eq_bar_w: float = (_eq_rect.size.x - 2.0) / 8.0
	for b in 8:
		var bh: float = _eq_rect.size.y * (0.25 + 0.75 * abs(sin(_scroll_t * 2.2 + b * 0.7)))
		draw_rect(Rect2(
			_eq_rect.position.x + b * eq_bar_w,
			_eq_rect.position.y + _eq_rect.size.y - bh,
			eq_bar_w - 1.0, bh),
			COL_LCD_GREEN.darkened(0.2 + 0.5 * (1.0 - bh / _eq_rect.size.y)), true)

	# Divider after top strip
	draw_line(Vector2(dx + 4.0, dy + 20.0), Vector2(dx + dw - 4.0, dy + 20.0), COL_LCD_DIM, 1.0)

	# ── CODE section ──────────────────────────────────────────────────
	draw_string(font, Vector2(dx + 6.0, dy + 32.0),
		"CODE:", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COL_LCD_DIM)

	var code_cy: float = dy + 62.0
	_draw_lcd_symbol_row(TARGET_PASSWORD, dx + dw * 0.5, code_cy, 30, COL_LCD_GREEN, false)

	# Divider
	draw_line(Vector2(dx + 4.0, dy + dh * 0.54), Vector2(dx + dw - 4.0, dy + dh * 0.54),
		COL_LCD_DIM, 1.0)

	# ── INPUT section ─────────────────────────────────────────────────
	draw_string(font, Vector2(dx + 6.0, dy + dh * 0.58 + 10.0),
		"INPUT:", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COL_LCD_DIM)

	var inp_cy: float = dy + dh * 0.58 + 44.0
	var inp_col: Color = COL_RED if _flash_wrong else COL_LCD_GREEN
	if _current_input.is_empty():
		if _blink_on and not _flash_wrong:
			var cs := font.get_string_size("▮", HORIZONTAL_ALIGNMENT_LEFT, -1, 28)
			draw_string(font, Vector2(dx + dw * 0.5 - cs.x * 0.5, inp_cy),
				"▮", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, COL_LCD_DIM)
	else:
		_draw_lcd_symbol_row(_current_input, dx + dw * 0.5, inp_cy, 30, inp_col,
			_blink_on and not _flash_wrong)

	# Bitrate strip
	draw_string(font, Vector2(dx + 6.0, dy + dh - 6.0),
		"128KBPS  44KHZ  STEREO", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, COL_LCD_DIM)

	# ── Seek bar ──────────────────────────────────────────────────────
	draw_rect(_seek_rect, Color(0.06, 0.06, 0.08), true)
	draw_rect(_seek_rect, Color(0.20, 0.20, 0.24), false, 1.0)
	var ph_frac: float = fmod(_scroll_t * 0.03, 1.0)
	draw_rect(Rect2(_seek_rect.position.x + ph_frac * (_seek_rect.size.x - 8.0),
		_seek_rect.position.y, 8.0, _seek_rect.size.y), COL_GOLD, true)

	# ── Symbol buttons ────────────────────────────────────────────────
	var mouse := get_local_mouse_position()
	for i in _btn_rects.size():
		var r:   Rect2   = _btn_rects[i]
		var hov: bool    = r.has_point(mouse)
		var ofs: Vector2 = Vector2(1, 1) if hov else Vector2.ZERO
		var fr:  Rect2   = Rect2(r.position + ofs, r.size)
		_draw_winamp_btn(fr, COL_BTN_HOV if hov else COL_BTN, hov)
		_draw_transport_symbol(i, fr, COL_BTN_TXT)
		# Label under icon
		var lbl: String = SYM_LABEL[i]
		var ls := font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 9)
		draw_string(font,
			Vector2(fr.position.x + (fr.size.x - ls.x) * 0.5, fr.position.y + fr.size.y - 6.0),
			lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.55, 0.55, 0.62))

	# ── DEL + ENTER ───────────────────────────────────────────────────
	var del_hov: bool    = _del_rect.has_point(mouse)
	var del_ofs: Vector2 = Vector2(1, 1) if del_hov else Vector2.ZERO
	_draw_winamp_btn(Rect2(_del_rect.position + del_ofs, _del_rect.size),
		Color(0.26, 0.16, 0.16) if del_hov else Color(0.20, 0.13, 0.13), del_hov)
	var del_sz := font.get_string_size("⌫  DEL", HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	draw_string(font,
		Vector2(_del_rect.position.x + del_ofs.x + (_del_rect.size.x - del_sz.x) * 0.5,
				_del_rect.position.y + del_ofs.y + (_del_rect.size.y + del_sz.y) * 0.5 - 4.0),
		"⌫  DEL", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.90, 0.55, 0.55))

	var en_hov: bool    = _enter_rect.has_point(mouse)
	var en_ofs: Vector2 = Vector2(1, 1) if en_hov else Vector2.ZERO
	_draw_winamp_btn(Rect2(_enter_rect.position + en_ofs, _enter_rect.size),
		Color(0.12, 0.24, 0.12) if en_hov else Color(0.10, 0.18, 0.10), en_hov)
	var en_sz := font.get_string_size("▶  PLAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	draw_string(font,
		Vector2(_enter_rect.position.x + en_ofs.x + (_enter_rect.size.x - en_sz.x) * 0.5,
				_enter_rect.position.y + en_ofs.y + (_enter_rect.size.y + en_sz.y) * 0.5 - 4.0),
		"▶  PLAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.45, 0.92, 0.45))


# Draw a row of transport symbol glyphs centered on (cx, cy)
func _draw_lcd_symbol_row(seq: Array, cx: float, cy: float,
		font_sz: int, col: Color, blink_cursor: bool) -> void:
	var font: Font  = ThemeDB.fallback_font
	var spacing:    float = float(font_sz) * 1.8
	var total_w:    float = spacing * (seq.size() - 1)
	var start_x:    float = cx - total_w * 0.5
	for i in seq.size():
		var glyph: String = SYM_GLYPH[seq[i] as int]
		var gs := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz)
		draw_string(font, Vector2(start_x + i * spacing - gs.x * 0.5, cy),
			glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz, col)
	if blink_cursor:
		var cursor_x: float = cx + total_w * 0.5 + spacing
		draw_string(font, Vector2(cursor_x, cy), "▮",
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz, col.darkened(0.3))


# Draw classic MP3 transport icons as vector shapes
func _draw_transport_symbol(sym: int, r: Rect2, col: Color) -> void:
	var cx: float = r.position.x + r.size.x * 0.5
	var cy: float = r.position.y + r.size.y * 0.5 - 6.0
	var s:  float = minf(r.size.x, r.size.y) * 0.28

	match sym:
		Sym.PLAY:  # Right triangle
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - s, cy - s), Vector2(cx + s * 1.2, cy), Vector2(cx - s, cy + s)]), col)
		Sym.BACK:  # Left triangle
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx + s, cy - s), Vector2(cx - s * 1.2, cy), Vector2(cx + s, cy + s)]), col)
		Sym.STOP:  # Square
			draw_rect(Rect2(cx - s, cy - s, s * 2.0, s * 2.0), col, true)
		Sym.REC:   # Circle
			draw_circle(Vector2(cx, cy), s, Color(0.9, 0.2, 0.2))
			draw_circle(Vector2(cx, cy), s * 0.55, Color(1.0, 0.5, 0.5))
		Sym.FF:    # Double right triangle
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - s * 1.3, cy - s), Vector2(cx, cy), Vector2(cx - s * 1.3, cy + s)]), col)
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx, cy - s), Vector2(cx + s * 1.3, cy), Vector2(cx, cy + s)]), col)
		Sym.REW:   # Double left triangle
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx + s * 1.3, cy - s), Vector2(cx, cy), Vector2(cx + s * 1.3, cy + s)]), col)
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx, cy - s), Vector2(cx - s * 1.3, cy), Vector2(cx, cy + s)]), col)


func _draw_winamp_btn(r: Rect2, fill: Color, pressed: bool) -> void:
	if not pressed:
		draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.5), true)
	draw_rect(r, fill, true)
	var hi: Color = fill.lightened(0.30) if not pressed else fill.darkened(0.20)
	var sh: Color = fill.darkened(0.30)  if not pressed else fill.lightened(0.20)
	draw_line(r.position, Vector2(r.position.x + r.size.x, r.position.y), hi, 1.0)
	draw_line(r.position, Vector2(r.position.x, r.position.y + r.size.y), hi, 1.0)
	draw_line(Vector2(r.position.x, r.position.y + r.size.y), r.position + r.size, sh, 1.0)
	draw_line(Vector2(r.position.x + r.size.x, r.position.y), r.position + r.size, sh, 1.0)


# ── Input ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _flash_wrong:
		return
	if not (event is InputEventMouseButton and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		return

	var pos: Vector2 = make_input_local(event).position

	if _del_rect.has_point(pos):
		if not _current_input.is_empty():
			_current_input.pop_back()
		queue_redraw()
		return

	if _enter_rect.has_point(pos):
		_check_password()
		return

	for i in _btn_rects.size():
		if (_btn_rects[i] as Rect2).has_point(pos):
			if _current_input.size() < MAX_INPUT:
				_current_input.append(i)
			queue_redraw()
			return


func _check_password() -> void:
	if _current_input == TARGET_PASSWORD:
		finished.emit()
	elif not _current_input.is_empty():
		_flash_wrong = true
		_flash_timer = FLASH_TIME
		queue_redraw()
