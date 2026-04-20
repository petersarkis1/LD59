extends Node2D

signal finished

var phone_position: Vector2
var phone_size: Vector2

const ITEM_COUNT    = 18
const STRIP_ITEMS   = 120
const ITEM_SIZE     = 280.0
const CELL_GAP      = 0.0
const STRIP_H       = 280.0
const SCROLL_DURATION = 9.0
const RESULT_PAUSE    = 0.6
const RESULT_DISPLAY_TIME = 1.2
const EDGE_PAD      = 20.0

# ── Exact CS:GO Scaleform rarity palette ──────────────────────────────────────
const RARITY_COLORS: Dictionary = {
	"Consumer":   Color("#b0c3d9"),
	"Industrial": Color("#5e98d9"),
	"Mil-Spec":   Color("#4b69ff"),
	"Restricted": Color("#8847ff"),
	"Classified": Color("#d32ce6"),
	"Covert":     Color("#eb4b4b"),
	"Contraband": Color("#e4ae39"),
}

const QUALITIES: Array = [
	"Factory New", "Minimal Wear", "Field-Tested", "Well-Worn", "Battle-Scarred"
]

const ITEM_NAMES: Dictionary = {
	1: "Hamster | Common",         2: "Cage | Common",
	3: "Wheel | Field-Tested",     4: "Tube | Battle-Scarred",
	5: "Nest | Blue Steel",        6: "Pellet | Cobalt",
	7: "Treat | Royal Blue",       8: "Blanket | Fade",
	9: "Bedding | Doppler",        10: "Bottle | Slaughter",
	11: "Seed | Tiger Tooth",      12: "Leash | Marble Fade",
	13: "Vest | Ultraviolet",      14: "Ball | Case Hardened",
	15: "Hut | Neon Revolution",   16: "Condo | Crimson Web",
	17: "Mansion | Autotronic",    18: "Palace | Gold",
}

# ── Steam palette ─────────────────────────────────────────────────────────────
const C_BG     := Color("#1b2838")
const C_HEADER := Color("#171d25")
const C_PANEL  := Color("#16202d")
const C_BORDER := Color("#2a475e")
const C_TEXT   := Color("#8f98a0")
const C_WHITE  := Color("#ffffff")
const C_GOLD   := Color("#f5a623")
const C_BTN    := Color("#4d7a9e")
const C_BTN_LT := Color("#66a0c9")
const C_GAP    := Color("#080c10")

var _phase: String = "idle"
var _textures: Dictionary = {}
var _valid_items: Array[int] = []
var _item_strip: Array[int] = []
var _strip_containers: Array[Node2D] = []
var _scroll_offset: float = 0.0
var _scroll_elapsed: float = 0.0
var _won_item: int = 0
var _won_quality: String = ""
var _target_offset: float = 0.0
var _landing_index: int = STRIP_ITEMS - 10


func setup(pos: Vector2, size: Vector2) -> void:
	phone_position = pos
	phone_size = size
	for i in range(1, ITEM_COUNT + 1):
		var tex := load("res://Assets/Phone/case-opening/%d.png" % i) as Texture2D
		if tex != null:
			_textures[i] = tex
			_valid_items.append(i)
	_show_idle()


# ── Rarity helpers ────────────────────────────────────────────────────────────

func _rarity_of(item: int) -> String:
	if item <= 2:    return "Consumer"
	elif item <= 4:  return "Industrial"
	elif item <= 7:  return "Mil-Spec"
	elif item <= 10: return "Restricted"
	elif item <= 13: return "Classified"
	elif item <= 17: return "Covert"
	else:            return "Contraband"

func _rarity_color(item: int) -> Color:
	return RARITY_COLORS[_rarity_of(item)]

func _random_quality() -> String:
	var r := randf()
	if r < 0.03:    return "Factory New"
	elif r < 0.15:  return "Minimal Wear"
	elif r < 0.50:  return "Field-Tested"
	elif r < 0.75:  return "Well-Worn"
	else:           return "Battle-Scarred"


# ── Node factories ────────────────────────────────────────────────────────────

func _rect(parent: Node, col: Color, pos: Vector2, sz: Vector2) -> ColorRect:
	var r := ColorRect.new()
	r.color    = col
	r.position = pos
	r.size     = sz
	parent.add_child(r)
	return r

func _label(parent: Node, txt: String, sz: int, col: Color,
		pos: Vector2, size: Vector2,
		h := HORIZONTAL_ALIGNMENT_CENTER,
		v := VERTICAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = h
	l.vertical_alignment   = v
	l.position = pos
	l.size     = size
	parent.add_child(l)
	return l

func _steam_button(parent: Node, txt: String, pos: Vector2, sz: Vector2) -> void:
	_rect(parent, C_BTN,    pos,                                       sz)
	_rect(parent, C_BTN_LT, pos,                                       Vector2(sz.x, sz.y * 0.5))
	_rect(parent, C_BORDER.darkened(0.3), pos + Vector2(0, sz.y - 1), Vector2(sz.x, 1))
	_label(parent, txt, 20, C_WHITE, pos, sz)

func _gradient_fade(parent: Node, pos: Vector2, sz: Vector2, left_opaque: bool) -> void:
	var grad := Gradient.new()
	var dark  := Color(0.05, 0.07, 0.10, 0.85)
	var clear := Color(0.05, 0.07, 0.10, 0.0)
	if left_opaque:
		grad.set_color(0, dark)
		grad.set_color(1, clear)
	else:
		grad.set_color(0, clear)
		grad.set_color(1, dark)
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	tex.width    = 32
	var fade_rect := TextureRect.new()
	fade_rect.texture      = tex
	fade_rect.position     = pos
	fade_rect.size         = sz
	fade_rect.stretch_mode = TextureRect.STRETCH_SCALE
	parent.add_child(fade_rect)


# ── IDLE SCREEN ───────────────────────────────────────────────────────────────

func _show_idle() -> void:
	_phase = "idle"
	var W: float = phone_size.x
	var H: float = phone_size.y
	var P: float = EDGE_PAD

	_rect(self, C_BG, phone_position, phone_size)

	var header_h := P * 2 + 50.0
	_rect(self, C_HEADER, phone_position, Vector2(W, header_h))
	_label(self, "CASE OPENING", 19, C_WHITE,
		phone_position + Vector2(0, P * 2), Vector2(W, 50))
	_rect(self, C_BORDER, phone_position + Vector2(0, header_h), Vector2(W, 1))

	_label(self, "YOU ARE ABOUT TO OPEN", 13, C_TEXT,
		phone_position + Vector2(P, header_h + 8), Vector2(W - P * 2, 22))
	_label(self, "Operation Dinner Date", 18, C_WHITE,
		phone_position + Vector2(P, header_h + 28), Vector2(W - P * 2, 26),
		HORIZONTAL_ALIGNMENT_LEFT)

	var img_y := phone_position.y + header_h + 62.0
	var img_h := H * 0.55
	_rect(self, C_BORDER, Vector2(phone_position.x + P - 1, img_y - 1),
		Vector2(W - P * 2 + 2, img_h + 2))
	_rect(self, C_PANEL, Vector2(phone_position.x + P, img_y),
		Vector2(W - P * 2, img_h))

	var case_tex := load("res://Assets/Phone/case-opening/case.png") as Texture2D
	if case_tex:
		var cs := Sprite2D.new()
		cs.texture  = case_tex
		cs.centered = true
		cs.position = Vector2(phone_position.x + W * 0.5, img_y + img_h * 0.5)
		var avail: float = min(W - P * 2 - 20, img_h - 16)
		cs.scale = Vector2.ONE * (avail / max(case_tex.get_width(), case_tex.get_height()))
		add_child(cs)

	var swatch_y := img_y + img_h + 10.0
	var sw_size  := 14.0
	var sw_gap   := 3.0
	var total_w  := ITEM_COUNT * (sw_size + sw_gap) - sw_gap
	var sw_x     := phone_position.x + (W - total_w) * 0.5
	for i in range(1, ITEM_COUNT + 1):
		_rect(self, _rarity_color(i),
			Vector2(sw_x + (i - 1) * (sw_size + sw_gap), swatch_y),
			Vector2(sw_size, sw_size))
	_label(self, "Contains %d items" % ITEM_COUNT, 13, C_TEXT,
		Vector2(phone_position.x + P, swatch_y + sw_size + 4), Vector2(W - P * 2, 20))

	var div_y := swatch_y + sw_size + 30.0
	_rect(self, C_BORDER, Vector2(phone_position.x + P, div_y), Vector2(W - P * 2, 1))

	var btn_y := div_y + 16.0
	var btn_h := 52.0
	_steam_button(self, "OPEN CASE",
		Vector2(phone_position.x + P, btn_y), Vector2(W - P * 2, btn_h))


# ── STRIP helpers ─────────────────────────────────────────────────────────────

func _pick_item() -> int:
	return _valid_items[randi() % _valid_items.size()]

func _pick_item_avoiding(recent: Array) -> int:
	var candidates: Array[int] = []
	var weights: Array[float]  = []
	var total := 0.0
	for item in _valid_items:
		if item in recent:
			continue
		var w: float = 1.0 / (item * item)
		candidates.append(item)
		weights.append(w)
		total += w
	if candidates.is_empty():
		return _pick_item()
	var r := randf() * total
	var acc := 0.0
	for i in range(candidates.size()):
		acc += weights[i]
		if r <= acc:
			return candidates[i]
	return candidates[0]

func _build_strip(target_item: int) -> void:
	_item_strip.clear()
	for i in range(STRIP_ITEMS):
		if i == _landing_index:
			_item_strip.append(target_item)
		else:
			_item_strip.append(_pick_item_avoiding(
				_item_strip.slice(max(0, i - 10), i)))


# ── SPIN SCREEN ───────────────────────────────────────────────────────────────

func _start_spin() -> void:
	_phase = "spinning"
	_won_item    = _pick_item()
	_won_quality = _random_quality()
	_build_strip(_won_item)

	for child in get_children():
		child.queue_free()
	_strip_containers.clear()

	var audio := AudioStreamPlayer.new()
	audio.stream = load("res://Assets/Phone/case-opening/spin.wav")
	add_child(audio)
	audio.play()

	var W: float = phone_size.x
	var H: float = phone_size.y
	var P: float = EDGE_PAD

	_rect(self, C_BG, phone_position, phone_size)

	var spin_header_h := P * 2 + 52.0
	_rect(self, C_HEADER, phone_position, Vector2(W, spin_header_h))
	_rect(self, C_BORDER, phone_position + Vector2(0, spin_header_h), Vector2(W, 1))

	var case_tex := load("res://Assets/Phone/case-opening/case.png") as Texture2D
	if case_tex:
		var thumb := Sprite2D.new()
		thumb.texture  = case_tex
		thumb.centered = true
		var thumb_size := 40.0
		thumb.position = Vector2(phone_position.x + P + 20, phone_position.y + P * 2 + 26)
		thumb.scale    = Vector2.ONE * (thumb_size / max(case_tex.get_width(), case_tex.get_height()))
		add_child(thumb)

	_label(self, "CASE OPENING", 17, C_WHITE,
		phone_position + Vector2(P + 48, P * 2), Vector2(W - P - 56, 28),
		HORIZONTAL_ALIGNMENT_LEFT)
	_label(self, "Operation Dinner Date", 13, C_TEXT,
		phone_position + Vector2(P + 48, P * 2 + 26), Vector2(W - P - 56, 24),
		HORIZONTAL_ALIGNMENT_LEFT)

	var usable_top: float = phone_position.y + spin_header_h + 1.0
	var usable_h: float   = H - spin_header_h
	var strip_y: float    = usable_top + (usable_h - STRIP_H) * 0.42
	var tri_h             := 16.0
	var frame_pad         := 3.0

	_rect(self, C_GAP,
		Vector2(phone_position.x, strip_y - frame_pad - tri_h),
		Vector2(W, STRIP_H + frame_pad * 2 + tri_h * 2))
	_rect(self, Color("#0d1117"),
		Vector2(phone_position.x, strip_y - frame_pad),
		Vector2(W, STRIP_H + frame_pad * 2))

	var clip := Control.new()
	clip.position      = phone_position
	clip.size          = phone_size
	clip.clip_contents = true
	add_child(clip)

	var ly: float = strip_y - phone_position.y

	for i in range(_item_strip.size()):
		var item_num: int  = _item_strip[i]
		var cx_cell: float = i * (ITEM_SIZE + CELL_GAP)

		var container := Node2D.new()
		container.position = Vector2(cx_cell, ly)
		clip.add_child(container)
		_strip_containers.append(container)

		var tex: Texture2D = _textures[item_num]
		var ts: Vector2    = tex.get_size()
		var s: float       = min(ITEM_SIZE / ts.x, STRIP_H / ts.y)
		var sw: float      = ts.x * s
		var sh: float      = ts.y * s
		var spr := Sprite2D.new()
		spr.texture  = tex
		spr.centered = false
		spr.scale    = Vector2.ONE * s
		spr.position = Vector2((ITEM_SIZE - sw) * 0.5, (STRIP_H - sh) * 0.5)
		container.add_child(spr)

	var cx: float = W * 0.5
	var tw: float = tri_h * 1.1

	var tri_top := Polygon2D.new()
	tri_top.color   = C_GOLD
	tri_top.polygon = PackedVector2Array([
		Vector2(cx - tw, ly - tri_h),
		Vector2(cx + tw, ly - tri_h),
		Vector2(cx,      ly),
	])
	clip.add_child(tri_top)

	var tri_bot := Polygon2D.new()
	tri_bot.color   = C_GOLD
	tri_bot.polygon = PackedVector2Array([
		Vector2(cx - tw, ly + STRIP_H + tri_h),
		Vector2(cx + tw, ly + STRIP_H + tri_h),
		Vector2(cx,      ly + STRIP_H),
	])
	clip.add_child(tri_bot)

	var fade_w: float = W * 0.22
	_gradient_fade(clip, Vector2(0,          ly), Vector2(fade_w, STRIP_H), true)
	_gradient_fade(clip, Vector2(W - fade_w, ly), Vector2(fade_w, STRIP_H), false)

	_label(self, "Good luck!", 15, C_TEXT,
		Vector2(phone_position.x + P, strip_y + STRIP_H + tri_h + frame_pad + 12),
		Vector2(W - P * 2, 26))

	var target_cx: float = _landing_index * (ITEM_SIZE + CELL_GAP) + ITEM_SIZE * 0.5
	_target_offset  = target_cx - W * 0.5
	_scroll_offset  = 0.0
	_scroll_elapsed = 0.0
	_update_strip_positions()


func _update_strip_positions() -> void:
	for i in range(_strip_containers.size()):
		_strip_containers[i].position.x = i * (ITEM_SIZE + CELL_GAP) - _scroll_offset


func _process(delta: float) -> void:
	if _phase != "spinning":
		return
	_scroll_elapsed += delta
	var t: float      = clamp(_scroll_elapsed / SCROLL_DURATION, 0.0, 1.0)
	var ease_t: float = 1.0 - pow(1.0 - t, 3.0)
	_scroll_offset = _target_offset * ease_t
	_update_strip_positions()
	if t >= 1.0:
		_phase = "result"
		_show_result_delayed()


# ── RESULT SCREEN ─────────────────────────────────────────────────────────────

func _show_result_delayed() -> void:
	await get_tree().create_timer(RESULT_PAUSE).timeout
	_show_result()

func _show_result() -> void:
	var W: float       = phone_size.x
	var H: float       = phone_size.y
	var P: float       = EDGE_PAD
	var rarity: String = _rarity_of(_won_item)
	var rc: Color      = RARITY_COLORS[rarity]

	var result_root := Node2D.new()
	result_root.modulate.a = 0.0
	add_child(result_root)

	_rect(result_root, Color(0.04, 0.06, 0.10, 0.90), phone_position, phone_size)

	var card_w  := W - P * 2
	var card_h  := H * 0.56
	var card_x  := phone_position.x + P
	var card_y  := phone_position.y + (H - card_h) * 0.5 - 10.0

	_label(result_root, "YOU RECEIVED:", 14, C_TEXT,
		Vector2(phone_position.x + P, card_y - 26), Vector2(W - P * 2, 22))

	_rect(result_root, C_PANEL,            Vector2(card_x, card_y),           Vector2(card_w, card_h))
	_rect(result_root, rc,                 Vector2(card_x, card_y),           Vector2(card_w, 3))
	_rect(result_root, rc.darkened(0.60),  Vector2(card_x, card_y + 3),       Vector2(card_w, 28))
	_rect(result_root, rc.darkened(0.30),  Vector2(card_x, card_y + card_h - 1), Vector2(card_w, 1))
	_label(result_root, rarity.to_upper(), 16, rc,
		Vector2(card_x, card_y + 3), Vector2(card_w, 28))

	var img_area_y := card_y + 34.0
	var img_area_h := card_h * 0.72
	_rect(result_root, rc.darkened(0.78),
		Vector2(card_x + 1, img_area_y), Vector2(card_w - 2, img_area_h))

	var tex: Texture2D = _textures[_won_item]
	var ts: Vector2    = tex.get_size()
	var avail: float   = min(card_w - 28, img_area_h - 12)
	var s: float       = avail / max(ts.x, ts.y)
	var spr            := Sprite2D.new()
	spr.texture  = tex
	spr.centered = true
	spr.scale    = Vector2.ONE * s
	spr.position = Vector2(card_x + card_w * 0.5, img_area_y + img_area_h * 0.5)
	result_root.add_child(spr)

	var div_y := img_area_y + img_area_h + 6.0
	_rect(result_root, C_BORDER, Vector2(card_x + 8, div_y), Vector2(card_w - 16, 1))

	var full_name: String = ITEM_NAMES.get(_won_item, "Item %d" % _won_item)
	_label(result_root, full_name, 15, C_WHITE,
		Vector2(card_x + 6, div_y + 8), Vector2(card_w - 12, 26))

	_label(result_root, _won_quality, 13, C_TEXT,
		Vector2(card_x + 8, div_y + 34), Vector2(card_w * 0.55, 22),
		HORIZONTAL_ALIGNMENT_LEFT)
	_label(result_root, rarity, 13, rc,
		Vector2(card_x, div_y + 34), Vector2(card_w - 8, 22),
		HORIZONTAL_ALIGNMENT_RIGHT)

	var tween := create_tween()
	tween.tween_property(result_root, "modulate:a", 1.0, 0.35)

	await get_tree().create_timer(RESULT_DISPLAY_TIME).timeout
	finished.emit()


# ── INPUT ─────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if _phase != "idle":
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local: Vector2 = event.position - phone_position
		if Rect2(Vector2.ZERO, phone_size).has_point(local):
			_start_spin()
