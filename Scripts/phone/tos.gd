extends Node2D

signal finished

var phone_position: Vector2
var phone_size: Vector2
var _raw_size: Vector2   # full viewport size, used to fill the bezel gap

# ── Scroll state ─────────────────────────────────────────────────────
var _scroll_y: float = 0.0
var _max_scroll: float = 0.0
var _velocity: float = 0.0
const FRICTION := 0.98
const FLICK_MULTIPLIER := 4.0

var _dragging := false
var _last_mouse_y: float = 0.0
var _last_delta_y: float = 0.0
var _blink: float = 0.0

# ── Layout ───────────────────────────────────────────────────────────
var _content_height: float = 0.0
var _agree_rect: Rect2
var _scroll_rect: Rect2   # valid drag area (content region only)
var _at_bottom := false

const FONT_SIZE_TITLE := 22
const FONT_SIZE_BODY  := 16
const FONT_SIZE_BTN   := 18
const FONT_SIZE_SMALL := 12
const LINE_SPACING    := 24.0
const PAD             := 12.0

const TITLEBAR_H      := 18.0
const MENUBAR_H       := 15.0
const TOOLBAR_H       := 22.0
const STATUSBAR_H     := 13.0
const CHROME_TOP      := TITLEBAR_H + MENUBAR_H + TOOLBAR_H + 6.0
const BTN_AREA_H      := 80.0
const CHROME_BOT      := STATUSBAR_H + BTN_AREA_H
const HEADER_H        := 52.0   # giant "agree to TOS" banner at top of content

# Bottom bezel covers ~17% of screen height; no side inset needed
const SAFE_BOTTOM     := 0.09

# Win98 palette
const C_DESKTOP    := Color(0.004, 0.294, 0.518)   # classic teal desktop
const C_WIN_BG     := Color(0.753, 0.753, 0.753)   # #C0C0C0
const C_TITLEBAR   := Color(0.008, 0.008, 0.502)   # navy
const C_TITLE_TEXT := Color.WHITE
const C_LIGHT      := Color(1, 1, 1)
const C_DARK       := Color(0.376, 0.376, 0.376)   # #606060
const C_SHADOW     := Color(0.125, 0.125, 0.125)
const C_TEXT       := Color(0, 0, 0)
const C_LINK       := Color(0, 0, 0.8)
const C_SCROLL_BG  := Color(0.878, 0.878, 0.878)
const C_SCROLL_TH  := Color(0.753, 0.753, 0.753)
const C_BTN_FACE   := Color(0.753, 0.753, 0.753)
const C_MENUBAR    := Color(0.753, 0.753, 0.753)

const TOS_FILES := [
	"res://Assets/Phone/tos/axolotl.txt",
	"res://Assets/Phone/tos/montypyt.txt", 
	"res://Assets/Phone/tos/beemovie.txt"
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

	_raw_size      = size
	phone_position = pos
	phone_size     = Vector2(size.x, size.y * (1.0 - SAFE_BOTTOM))
	_content_height = TOS_LINES.size() * LINE_SPACING + PAD * 4 + 60.0
	# Actual scrollable viewport: subtract title/menu/address bars, header, status bar, button area
	var address_bar_h := 18.0
	var chrome_top_px := 2.0 + TITLEBAR_H + MENUBAR_H + TOOLBAR_H + address_bar_h + 2.0
	var visible_h: float = phone_size.y - chrome_top_px - BTN_AREA_H - HEADER_H
	_max_scroll     = max(0.0, _content_height - visible_h)


func _process(delta: float) -> void:
	if not _dragging:
		_scroll_y += _velocity
		_velocity *= FRICTION
		if abs(_velocity) < 0.1:
			_velocity = 0.0
	_scroll_y = clamp(_scroll_y, 0.0, _max_scroll)
	_at_bottom = _scroll_y >= _max_scroll - 2.0
	if _at_bottom:
		_scroll_y = _max_scroll
		_velocity = 0.0
		_dragging = false
	_blink = fmod(_blink + delta * 2.5, TAU)
	queue_redraw()


func _draw_win98_bevel(r: Rect2, raised: bool) -> void:
	var tl := C_LIGHT if raised else C_SHADOW
	var br := C_SHADOW if raised else C_LIGHT
	var tl2 := C_WIN_BG.lightened(0.3) if raised else C_DARK
	var br2 := C_DARK if raised else C_WIN_BG.lightened(0.3)
	# outer
	draw_line(r.position, Vector2(r.end.x, r.position.y), tl, 1)
	draw_line(r.position, Vector2(r.position.x, r.end.y), tl, 1)
	draw_line(Vector2(r.end.x, r.position.y), r.end, br, 1)
	draw_line(Vector2(r.position.x, r.end.y), r.end, br, 1)
	# inner
	var i := Rect2(r.position + Vector2(1,1), r.size - Vector2(2,2))
	draw_line(i.position, Vector2(i.end.x, i.position.y), tl2, 1)
	draw_line(i.position, Vector2(i.position.x, i.end.y), tl2, 1)
	draw_line(Vector2(i.end.x, i.position.y), i.end, br2, 1)
	draw_line(Vector2(i.position.x, i.end.y), i.end, br2, 1)


func _draw_win98_button(r: Rect2, label: String, font: Font, enabled: bool, face: Color = C_BTN_FACE) -> void:
	draw_rect(r, face, true)
	_draw_win98_bevel(r, enabled)
	var sz := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_BTN)
	var col := C_LIGHT if face != C_BTN_FACE else (C_TEXT if enabled else C_DARK)
	draw_string(font, Vector2(
		r.position.x + (r.size.x - sz.x) * 0.5,
		r.position.y + (r.size.y + sz.y) * 0.5 - 3),
		label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_BTN, col)


func _draw_chrome(font: Font, wp: Vector2, ws: Vector2) -> void:
	# ── Title bar ────────────────────────────────────────────────────────
	var tb := Rect2(wp.x + 2, wp.y + 2, ws.x - 4, TITLEBAR_H)
	# Win98 blue gradient: left bright → right dark
	for i in int(tb.size.x):
		var t   := float(i) / tb.size.x
		var col := Color(0.0, 0.07, 0.56).lerp(Color(0.45, 0.62, 0.87), 1.0 - t)
		draw_line(Vector2(tb.position.x + i, tb.position.y),
				  Vector2(tb.position.x + i, tb.end.y), col, 1)

	# Small app icon (IE-style blue square with e)
	var icon_r := Rect2(tb.position.x + 2, tb.position.y + 2, 14, 14)
	draw_rect(icon_r, Color(0.2, 0.4, 0.9), true)
	draw_string(font, Vector2(icon_r.position.x + 3, icon_r.position.y + 11),
		"e", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL, Color.WHITE)

	# Title text (next to icon)
	var title := "Terms of Service - Microsoft Internet Explorer"
	draw_string(font, Vector2(tb.position.x + 20, tb.position.y + TITLEBAR_H - 4),
		title, HORIZONTAL_ALIGNMENT_LEFT, tb.size.x - 70, FONT_SIZE_SMALL, C_TITLE_TEXT)

	# Window control buttons: _ □ × (right to left, close is wider and red)
	var cb_h   := TITLEBAR_H - 4.0
	var cb_y   := tb.position.y + 2.0
	var close_w := cb_h + 2.0
	var norm_w  := cb_h - 2.0

	# Close button (×) — slightly wider, red face
	var cb_x := tb.end.x - close_w - 2.0
	var cb_r := Rect2(cb_x, cb_y, close_w, cb_h)
	draw_rect(cb_r, Color(0.75, 0.75, 0.75), true)
	_draw_win98_bevel(cb_r, true)
	var cx := cb_r.position.x + close_w * 0.5
	var cy := cb_r.position.y + cb_h * 0.5
	var cs := cb_h * 0.28
	draw_line(Vector2(cx - cs, cy - cs), Vector2(cx + cs, cy + cs), C_TEXT, 1.5)
	draw_line(Vector2(cx + cs, cy - cs), Vector2(cx - cs, cy + cs), C_TEXT, 1.5)

	# Maximize button (□)
	var mx_x := cb_x - norm_w - 2.0
	var mx_r := Rect2(mx_x, cb_y, norm_w, cb_h)
	draw_rect(mx_r, C_BTN_FACE, true)
	_draw_win98_bevel(mx_r, true)
	var mx_pad := 3.0
	var inner := Rect2(mx_r.position.x + mx_pad, mx_r.position.y + mx_pad,
		mx_r.size.x - mx_pad * 2, mx_r.size.y - mx_pad * 2)
	draw_rect(inner, C_TEXT, false, 1.0)
	draw_line(inner.position, Vector2(inner.end.x, inner.position.y), C_TEXT, 2.0)

	# Minimize button (_)
	var mn_x := mx_x - norm_w - 2.0
	var mn_r := Rect2(mn_x, cb_y, norm_w, cb_h)
	draw_rect(mn_r, C_BTN_FACE, true)
	_draw_win98_bevel(mn_r, true)
	var bar_y := mn_r.end.y - 4.0
	draw_line(Vector2(mn_r.position.x + 3, bar_y), Vector2(mn_r.end.x - 3, bar_y), C_TEXT, 2.0)

	# ── Menu bar ─────────────────────────────────────────────────────────
	var mb_y := wp.y + 2 + TITLEBAR_H
	var mb   := Rect2(wp.x + 2, mb_y, ws.x - 4, MENUBAR_H)
	draw_rect(mb, C_MENUBAR, true)
	# bottom separator
	draw_line(Vector2(mb.position.x, mb.end.y - 1), Vector2(mb.end.x, mb.end.y - 1), C_DARK, 1)
	var menu_items  := ["File", "Edit", "View", "Favorites", "Tools", "Help"]
	var menu_x      := mb.position.x + 6.0
	for item in menu_items:
		var isz := font.get_string_size(item, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL)
		draw_string(font, Vector2(menu_x, mb.position.y + MENUBAR_H - 4),
			item, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL, C_TEXT)
		# underline first letter (mnemonic)
		var lsz := font.get_string_size(item.left(1), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL)
		draw_line(Vector2(menu_x, mb.position.y + MENUBAR_H - 3),
			Vector2(menu_x + lsz.x, mb.position.y + MENUBAR_H - 3), C_TEXT, 1)
		menu_x += isz.x + 10.0

	# ── Toolbar (Back, Forward, Stop, Refresh, Home, Search, Favorites) ──
	var tb2_y := mb_y + MENUBAR_H
	var tb2   := Rect2(wp.x + 2, tb2_y, ws.x - 4, TOOLBAR_H)
	draw_rect(tb2, C_WIN_BG, true)
	draw_line(Vector2(tb2.position.x, tb2.end.y - 1), Vector2(tb2.end.x, tb2.end.y - 1), C_DARK, 1)
	var toolbar_btns := [["◄", "Back"], ["►", "Forward"], ["■", "Stop"], ["↺", "Refresh"], ["⌂", "Home"]]
	var tbx := tb2.position.x + 2.0
	var tb_bh := TOOLBAR_H - 4.0
	var tb_by := tb2_y + 2.0
	for tbi in toolbar_btns.size():
		var ico  : String = toolbar_btns[tbi][0]
		var lbl  : String = toolbar_btns[tbi][1]
		var lsz  := font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL)
		var isz  := font.get_string_size(ico, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL)
		var tbw  := maxf(lsz.x, isz.x) + 6.0
		var tb_r := Rect2(tbx, tb_by, tbw, tb_bh)
		draw_rect(tb_r, C_WIN_BG, true)
		_draw_win98_bevel(tb_r, true)
		# icon on top, label below — just show label for space
		draw_string(font, Vector2(tb_r.position.x + (tbw - lsz.x) * 0.5,
			tb_r.position.y + (tb_bh + lsz.y) * 0.5 - 2),
			lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL, C_TEXT)
		tbx += tbw + 2.0
		# separator after Stop
		if tbi == 2:
			draw_line(Vector2(tbx + 1, tb_by + 2), Vector2(tbx + 1, tb_by + tb_bh - 2), C_DARK, 1)
			tbx += 4.0

	# ── Address bar ──────────────────────────────────────────────────────
	var ab_y  := tb2_y + TOOLBAR_H
	var ab_h  := 18.0
	draw_rect(Rect2(wp.x + 2, ab_y, ws.x - 4, ab_h), C_WIN_BG, true)
	var addr_lbl := "Address"
	var alsz     := font.get_string_size(addr_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL)
	draw_string(font, Vector2(wp.x + 5, ab_y + 13), addr_lbl,
		HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL, C_TEXT)
	# underline A
	var a1sz := font.get_string_size("A", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL)
	draw_line(Vector2(wp.x + 5, ab_y + 14), Vector2(wp.x + 5 + a1sz.x, ab_y + 14), C_TEXT, 1)
	var addr_rect := Rect2(wp.x + alsz.x + 8, ab_y + 2, ws.x - alsz.x - 14, ab_h - 4)
	draw_rect(addr_rect, C_LIGHT, true)
	_draw_win98_bevel(addr_rect, false)
	draw_string(font, Vector2(addr_rect.position.x + 3, addr_rect.position.y + 11),
		"http://www.termsofservice.com/tos.htm", HORIZONTAL_ALIGNMENT_LEFT,
		int(addr_rect.size.x) - 4, FONT_SIZE_SMALL, C_LINK)

	# Separator line under address bar
	var sep_y := ab_y + ab_h
	draw_line(Vector2(wp.x + 2, sep_y), Vector2(wp.x + ws.x - 2, sep_y), C_DARK, 1)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var wp   := phone_position
	var ws   := phone_size

	# Fill the full viewport (covers bezel gap below window)
	draw_rect(Rect2(Vector2.ZERO, _raw_size), C_WIN_BG, true)

	# ── Outer window frame ───────────────────────────────────────────────
	draw_rect(Rect2(wp, ws), C_WIN_BG, true)
	_draw_win98_bevel(Rect2(wp, ws), true)

	# ── Compute layout (must match _draw_chrome geometry) ────────────────
	var ab_h      := 18.0
	var ab_y      := wp.y + 2.0 + TITLEBAR_H + MENUBAR_H + TOOLBAR_H
	var sep_y     := ab_y + ab_h

	var SCROLL_W  := 18.0
	var content_x := wp.x + 4
	var content_w := ws.x - 8 - SCROLL_W
	var text_top  := sep_y + 2.0
	var text_bot  := wp.y + ws.y - CHROME_BOT + STATUSBAR_H

	# Store scroll region for input gating
	_scroll_rect = Rect2(content_x, text_top, content_w + SCROLL_W, text_bot - text_top)

	# Content area background (white, like a webpage)
	draw_rect(_scroll_rect, C_LIGHT, true)

	# ── Giant fixed header banner ─────────────────────────────────────────
	var hdr := Rect2(content_x, text_top, content_w + SCROLL_W, HEADER_H)
	draw_rect(hdr, Color(0.008, 0.008, 0.502), true)   # navy
	var hdr1 := "TERMS OF SERVICE"
	var hdr2 := "You must read and agree to continue"
	var h1sz  := font.get_string_size(hdr1, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_TITLE)
	var h2sz  := font.get_string_size(hdr2, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL)
	draw_string(font, Vector2(content_x + (content_w - h1sz.x) * 0.5, text_top + 20),
		hdr1, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_TITLE, Color.WHITE)
	draw_string(font, Vector2(content_x + (content_w - h2sz.x) * 0.5, text_top + 40),
		hdr2, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL, Color(0.8, 0.8, 1.0))

	# ── Website-style TOS content ─────────────────────────────────────────
	var text_x := content_x + PAD
	# offset scroll start below header
	var y      := text_top + HEADER_H + LINE_SPACING - _scroll_y

	for i in TOS_LINES.size():
		if y + LINE_SPACING >= text_top and y <= text_bot:
			var line     := TOS_LINES[i]
			var is_title := i == 0
			var is_section: bool = line.length() > 0 and line[0].is_valid_int() and line.contains(".")
			var col      := C_TEXT
			var fsize    := FONT_SIZE_BODY
			if is_title:
				col   = Color(0.1, 0.1, 0.5)
				fsize = FONT_SIZE_TITLE
			elif is_section:
				col   = Color(0.0, 0.0, 0.6)
				fsize = FONT_SIZE_BODY + 1
			draw_string(font, Vector2(text_x, y), line,
				HORIZONTAL_ALIGNMENT_LEFT, content_w - PAD, fsize, col)
		y += LINE_SPACING

	# Clip text bleeding below content area
	draw_rect(Rect2(content_x, text_bot, content_w + SCROLL_W, wp.y + ws.y - text_bot), C_WIN_BG, true)
	# Redraw header over any scrolled text that crept into it
	draw_rect(hdr, Color(0.008, 0.008, 0.502), true)
	draw_string(font, Vector2(content_x + (content_w - h1sz.x) * 0.5, text_top + 20),
		hdr1, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_TITLE, Color.WHITE)
	draw_string(font, Vector2(content_x + (content_w - h2sz.x) * 0.5, text_top + 40),
		hdr2, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL, Color(0.8, 0.8, 1.0))

	# ── Win98 scrollbar ───────────────────────────────────────────────────
	var sb_x := content_x + content_w
	draw_rect(Rect2(sb_x, text_top, SCROLL_W, text_bot - text_top), C_SCROLL_BG, true)
	# thumb
	var track_h := text_bot - text_top - SCROLL_W * 2
	var thumb_h: float = maxf(16.0, track_h * (text_bot - text_top) / maxf(_content_height, 1.0))
	var thumb_y: float = text_top + SCROLL_W + ((_scroll_y / _max_scroll) * (track_h - thumb_h) if _max_scroll > 0 else 0.0)
	var thumb_r := Rect2(sb_x, thumb_y, SCROLL_W, thumb_h)
	draw_rect(thumb_r, C_SCROLL_TH, true)
	_draw_win98_bevel(thumb_r, true)
	# arrow buttons
	for arrow in 2:
		var ar_y := (text_top if arrow == 0 else text_bot - SCROLL_W)
		var ar   := Rect2(sb_x, ar_y, SCROLL_W, SCROLL_W)
		draw_rect(ar, C_BTN_FACE, true)
		_draw_win98_bevel(ar, true)
		var glyph := "▲" if arrow == 0 else "▼"
		var gsz   := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
		draw_string(font, Vector2(ar.position.x + (SCROLL_W - gsz.x) * 0.5,
								  ar.position.y + (SCROLL_W + gsz.y) * 0.5 - 1),
			glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, C_TEXT)

	# ── Bottom button area ────────────────────────────────────────────────
	var btn_area_h := BTN_AREA_H
	var btn_area_y := wp.y + ws.y - btn_area_h
	draw_rect(Rect2(wp.x + 2, btn_area_y, ws.x - 4, btn_area_h), C_WIN_BG, true)
	draw_line(Vector2(wp.x + 2, btn_area_y), Vector2(wp.x + ws.x - 2, btn_area_y), C_DARK, 1)

	var btn_margin := 6.0
	_agree_rect = Rect2(wp.x + btn_margin, btn_area_y + btn_margin,
		ws.x - btn_margin * 2.0, btn_area_h - btn_margin * 2.0)

	if _at_bottom:
		_draw_win98_button(_agree_rect, "I Accept", font, true, Color(0.15, 0.55, 0.15))
	else:
		_draw_win98_button(_agree_rect, "SCROLL", font, true, Color(0.75, 0.1, 0.1))

	# ── Chrome drawn last so it always sits on top of content ────────────
	_draw_chrome(font, wp, ws)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = event.position
		if event.pressed:
			if _scroll_rect.has_point(pos):
				_dragging     = true
				_last_mouse_y = event.position.y
				_last_delta_y = 0.0
				_velocity     = 0.0
		else:
			_dragging = false
			_velocity = -_last_delta_y * FLICK_MULTIPLIER
			if _at_bottom and pos.y >= phone_size.y * 0.5:
				finished.emit()

	elif event is InputEventMouseMotion and _dragging:
		var dy: float  = event.position.y - _last_mouse_y
		_last_delta_y  = dy
		_scroll_y     -= dy
		_scroll_y      = clamp(_scroll_y, 0.0, _max_scroll)
		_last_mouse_y  = event.position.y
