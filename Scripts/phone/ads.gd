extends Node2D

signal finished

var phone_position: Vector2
var phone_size: Vector2
var _raw_size: Vector2

var ads: Array[Sprite2D] = []
var velocities: Array[Vector2] = []
var ad_sizes: Array[Vector2] = []
var texture: Texture2D

const SPEED = 40.0

# ── Win98 chrome constants (mirrors tos.gd) ──────────────────────────
const FONT_SIZE_SMALL := 12
const TITLEBAR_H      := 18.0
const MENUBAR_H       := 15.0
const TOOLBAR_H       := 22.0
const SAFE_BOTTOM     := 0.09

const C_WIN_BG   := Color(0.753, 0.753, 0.753)
const C_LIGHT    := Color(1, 1, 1)
const C_DARK     := Color(0.376, 0.376, 0.376)
const C_SHADOW   := Color(0.125, 0.125, 0.125)
const C_TEXT     := Color(0, 0, 0)
const C_LINK     := Color(0, 0, 0.8)
const C_BTN_FACE := Color(0.753, 0.753, 0.753)
const C_MENUBAR  := Color(0.753, 0.753, 0.753)

const AB_H        := 18.0
const CONTENT_TOP := 2.0 + TITLEBAR_H + MENUBAR_H + TOOLBAR_H + AB_H + 2.0


func setup(pos: Vector2, size: Vector2) -> void:
	_raw_size      = size
	phone_position = pos
	phone_size     = Vector2(size.x, size.y * (1.0 - SAFE_BOTTOM))
	var ad_files := [
		"res://Assets/Phone/ads/ad.png",
		"res://Assets/Phone/ads/ad_virus.png",
		"res://Assets/Phone/ads/ad_winner.png",
		"res://Assets/Phone/ads/ad_iq.png",
		"res://Assets/Phone/ads/ad_dating.png",
		"res://Assets/Phone/ads/ad_weight.png",
		"res://Assets/Phone/ads/ad_iphone.png",
		"res://Assets/Phone/ads/ad_download.png",
	]

	var area_top   := phone_position.y + CONTENT_TOP
	var area_bot   := phone_position.y + phone_size.y
	var area_left  := phone_position.x + 4.0
	var area_w     := phone_size.x - 8.0

	for i in randi_range(15, 30):
		var sprite  := Sprite2D.new()
		var tex: Texture2D = load(ad_files[randi() % ad_files.size()])
		sprite.texture  = tex
		sprite.centered = false
		var tex_size: Vector2 = tex.get_size()
		var divisor := randf_range(1.5, 3.5)
		var max_size := phone_size / divisor
		var scale_f: float = min(max_size.x / tex_size.x, max_size.y / tex_size.y)
		sprite.scale = Vector2(scale_f, scale_f)
		var ad_size: Vector2 = tex_size * scale_f
		sprite.position = Vector2(
			randf_range(area_left, area_left + area_w - ad_size.x),
			randf_range(area_top,  area_bot  - ad_size.y)
		)
		add_child(sprite)
		ads.append(sprite)
		velocities.append(Vector2.from_angle(randf_range(0.0, TAU)) * SPEED)
		ad_sizes.append(ad_size)


func _process(delta: float) -> void:
	var area_top   := phone_position.y + CONTENT_TOP
	var area_bot   := phone_position.y + phone_size.y
	var area_left  := phone_position.x + 4.0
	var area_right := phone_position.x + phone_size.x - 4.0

	for i in ads.size():
		var sprite  := ads[i]
		var ad_size := ad_sizes[i]
		sprite.position += velocities[i] * delta
		var p := sprite.position
		if p.x < area_left:
			p.x = area_left;                velocities[i].x =  abs(velocities[i].x)
		elif p.x > area_right - ad_size.x:
			p.x = area_right - ad_size.x;   velocities[i].x = -abs(velocities[i].x)
		if p.y < area_top:
			p.y = area_top;                 velocities[i].y =  abs(velocities[i].y)
		elif p.y > area_bot - ad_size.y:
			p.y = area_bot - ad_size.y;     velocities[i].y = -abs(velocities[i].y)
		sprite.position = p
	queue_redraw()


func _draw_win98_bevel(r: Rect2, raised: bool) -> void:
	var tl  := C_LIGHT  if raised else C_SHADOW
	var br  := C_SHADOW if raised else C_LIGHT
	var tl2 := C_WIN_BG.lightened(0.3) if raised else C_DARK
	var br2 := C_DARK if raised else C_WIN_BG.lightened(0.3)
	draw_line(r.position, Vector2(r.end.x, r.position.y), tl, 1)
	draw_line(r.position, Vector2(r.position.x, r.end.y), tl, 1)
	draw_line(Vector2(r.end.x, r.position.y), r.end, br, 1)
	draw_line(Vector2(r.position.x, r.end.y), r.end, br, 1)
	var ii := Rect2(r.position + Vector2(1, 1), r.size - Vector2(2, 2))
	draw_line(ii.position, Vector2(ii.end.x, ii.position.y), tl2, 1)
	draw_line(ii.position, Vector2(ii.position.x, ii.end.y), tl2, 1)
	draw_line(Vector2(ii.end.x, ii.position.y), ii.end, br2, 1)
	draw_line(Vector2(ii.position.x, ii.end.y), ii.end, br2, 1)


func _draw_chrome(font: Font, wp: Vector2, ws: Vector2) -> void:
	# ── Title bar ────────────────────────────────────────────────────────
	var tb := Rect2(wp.x + 2, wp.y + 2, ws.x - 4, TITLEBAR_H)
	for i in int(tb.size.x):
		var t   := float(i) / tb.size.x
		var col := Color(0.0, 0.07, 0.56).lerp(Color(0.45, 0.62, 0.87), 1.0 - t)
		draw_line(Vector2(tb.position.x + i, tb.position.y),
				  Vector2(tb.position.x + i, tb.end.y), col, 1)
	var icon_r := Rect2(tb.position.x + 2, tb.position.y + 2, 14, 14)
	draw_rect(icon_r, Color(0.2, 0.4, 0.9), true)
	draw_string(font, Vector2(icon_r.position.x + 3, icon_r.position.y + 11),
		"e", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL, Color.WHITE)
	draw_string(font, Vector2(tb.position.x + 20, tb.position.y + TITLEBAR_H - 4),
		"New Page 1 - Microsoft Internet Explorer",
		HORIZONTAL_ALIGNMENT_LEFT, tb.size.x - 70, FONT_SIZE_SMALL, Color.WHITE)

	var cb_h    := TITLEBAR_H - 4.0
	var cb_y    := tb.position.y + 2.0
	var close_w := cb_h + 2.0
	var norm_w  := cb_h - 2.0
	var cb_x    := tb.end.x - close_w - 2.0
	var cb_r    := Rect2(cb_x, cb_y, close_w, cb_h)
	draw_rect(cb_r, C_BTN_FACE, true); _draw_win98_bevel(cb_r, true)
	var cx := cb_r.position.x + close_w * 0.5
	var cy := cb_r.position.y + cb_h * 0.5
	var cs := cb_h * 0.28
	draw_line(Vector2(cx - cs, cy - cs), Vector2(cx + cs, cy + cs), C_TEXT, 1.5)
	draw_line(Vector2(cx + cs, cy - cs), Vector2(cx - cs, cy + cs), C_TEXT, 1.5)
	var mx_x := cb_x - norm_w - 2.0
	var mx_r  := Rect2(mx_x, cb_y, norm_w, cb_h)
	draw_rect(mx_r, C_BTN_FACE, true); _draw_win98_bevel(mx_r, true)
	var mp  := 3.0
	var inn := Rect2(mx_r.position.x + mp, mx_r.position.y + mp, mx_r.size.x - mp * 2, mx_r.size.y - mp * 2)
	draw_rect(inn, C_TEXT, false, 1.0)
	draw_line(inn.position, Vector2(inn.end.x, inn.position.y), C_TEXT, 2.0)
	var mn_r := Rect2(mx_x - norm_w - 2.0, cb_y, norm_w, cb_h)
	draw_rect(mn_r, C_BTN_FACE, true); _draw_win98_bevel(mn_r, true)
	draw_line(Vector2(mn_r.position.x + 3, mn_r.end.y - 4),
			  Vector2(mn_r.end.x - 3,      mn_r.end.y - 4), C_TEXT, 2.0)

	# ── Menu bar ─────────────────────────────────────────────────────────
	var mb_y := wp.y + 2 + TITLEBAR_H
	var mb   := Rect2(wp.x + 2, mb_y, ws.x - 4, MENUBAR_H)
	draw_rect(mb, C_MENUBAR, true)
	draw_line(Vector2(mb.position.x, mb.end.y - 1), Vector2(mb.end.x, mb.end.y - 1), C_DARK, 1)
	var menu_items := ["File", "Edit", "View", "Favorites", "Tools", "Help"]
	var menu_x     := mb.position.x + 6.0
	for item in menu_items:
		var isz := font.get_string_size(item, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL)
		draw_string(font, Vector2(menu_x, mb.position.y + MENUBAR_H - 4),
			item, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL, C_TEXT)
		var lsz := font.get_string_size(item.left(1), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL)
		draw_line(Vector2(menu_x, mb.position.y + MENUBAR_H - 3),
			Vector2(menu_x + lsz.x, mb.position.y + MENUBAR_H - 3), C_TEXT, 1)
		menu_x += isz.x + 10.0

	# ── Toolbar ──────────────────────────────────────────────────────────
	var tb2_y := mb_y + MENUBAR_H
	var tb2   := Rect2(wp.x + 2, tb2_y, ws.x - 4, TOOLBAR_H)
	draw_rect(tb2, C_WIN_BG, true)
	draw_line(Vector2(tb2.position.x, tb2.end.y - 1), Vector2(tb2.end.x, tb2.end.y - 1), C_DARK, 1)
	var toolbar_btns := [["◄", "Back"], ["►", "Forward"], ["■", "Stop"], ["↺", "Refresh"], ["⌂", "Home"]]
	var tbx   := tb2.position.x + 2.0
	var tb_bh := TOOLBAR_H - 4.0
	var tb_by := tb2_y + 2.0
	for tbi in toolbar_btns.size():
		var lbl : String = toolbar_btns[tbi][1]
		var lsz := font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL)
		var tbw := lsz.x + 6.0
		var tb_r := Rect2(tbx, tb_by, tbw, tb_bh)
		draw_rect(tb_r, C_WIN_BG, true); _draw_win98_bevel(tb_r, true)
		draw_string(font, Vector2(tb_r.position.x + (tbw - lsz.x) * 0.5,
			tb_r.position.y + (tb_bh + lsz.y) * 0.5 - 2),
			lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL, C_TEXT)
		tbx += tbw + 2.0
		if tbi == 2:
			draw_line(Vector2(tbx + 1, tb_by + 2), Vector2(tbx + 1, tb_by + tb_bh - 2), C_DARK, 1)
			tbx += 4.0

	# ── Address bar ──────────────────────────────────────────────────────
	var ab_y := tb2_y + TOOLBAR_H
	draw_rect(Rect2(wp.x + 2, ab_y, ws.x - 4, AB_H), C_WIN_BG, true)
	var addr_lbl := "Address"
	var alsz     := font.get_string_size(addr_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL)
	draw_string(font, Vector2(wp.x + 5, ab_y + 13), addr_lbl,
		HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL, C_TEXT)
	var a1sz := font.get_string_size("A", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE_SMALL)
	draw_line(Vector2(wp.x + 5, ab_y + 14), Vector2(wp.x + 5 + a1sz.x, ab_y + 14), C_TEXT, 1)
	var addr_rect := Rect2(wp.x + alsz.x + 8, ab_y + 2, ws.x - alsz.x - 14, AB_H - 4)
	draw_rect(addr_rect, C_LIGHT, true); _draw_win98_bevel(addr_rect, false)
	draw_string(font, Vector2(addr_rect.position.x + 3, addr_rect.position.y + 11),
		"http://www.free-prizes.com/you-won.htm", HORIZONTAL_ALIGNMENT_LEFT,
		int(addr_rect.size.x) - 4, FONT_SIZE_SMALL, C_LINK)
	draw_line(Vector2(wp.x + 2, ab_y + AB_H), Vector2(wp.x + ws.x - 2, ab_y + AB_H), C_DARK, 1)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var wp   := phone_position
	var ws   := phone_size
	draw_rect(Rect2(Vector2.ZERO, _raw_size), C_WIN_BG, true)
	draw_rect(Rect2(wp, ws), C_WIN_BG, true)
	_draw_win98_bevel(Rect2(wp, ws), true)
	# Chrome drawn last so it always sits on top of ads
	_draw_chrome(font, wp, ws)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = event.position
		for i in range(ads.size() - 1, -1, -1):
			var sprite   := ads[i]
			var ad_size  := ad_sizes[i]
			# Large generous zone around the X (top-right corner)
			var close_zone := Rect2(
				sprite.position + Vector2(ad_size.x - 140.0, -40.0),
				Vector2(180.0, 180.0)
			)
			if close_zone.has_point(pos):
				sprite.queue_free()
				ads.remove_at(i)
				ad_sizes.remove_at(i)
				velocities.remove_at(i)
				if ads.is_empty():
					finished.emit()
				break
