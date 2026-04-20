extends Node2D

signal finished

var phone_position: Vector2
var phone_size: Vector2

# ── Card images ──────────────────────────────────────────────────────
const HAMPTERS_DIR := "res://Assets/Phone/cards/hampters/"
const PACK_TEXTURE := "res://Assets/Phone/cards/card_pack/pack.png"
const CARD_COUNT := 10

# ── State ────────────────────────────────────────────────────────────
enum Phase { RIPPING, SWIPING }
var _phase: Phase = Phase.RIPPING

# Common → Rare → Ultra Rare → Secret Rare (YGO/Pokemon ladder)
enum Rarity { COMMON, RARE, ULTRA_RARE, SECRET_RARE }

var _cards: Array[Texture2D] = []
var _card_rarities: Array[int] = []
var _pack_tex: Texture2D

# Rip phase
var _rip_progress: float = 0.0   # 0 to 1
var _rip_direction: float = 1.0  # +1 right, -1 left
var _rip_dragging: bool = false
var _rip_start_x: float = 0.0
var _rip_current_x: float = 0.0
const RIP_DISTANCE := 120.0       # pixels to drag to complete rip

# Swipe phase
var _current_card: int = 0
var _swipe_offset: float = 0.0
var _swipe_dragging: bool = false
var _swipe_start_x: float = 0.0
var _swipe_velocity: float = 0.0
var _swipe_animating: bool = false
var _flying_card: int = -1        # index of card currently animating off-screen
var _flying_offset: float = 0.0
var _flying_target: float = 0.0
var _waiting_to_finish: bool = false
const SWIPE_THRESHOLD := 60.0
const SWIPE_ANIM_SPEED := 18.0
const FLY_SPEED := 1600.0


func setup(pos: Vector2, size: Vector2) -> void:
	phone_position = pos
	phone_size     = size

	# Pick 5 random cards from the hampters folder
	var dir := DirAccess.open(HAMPTERS_DIR)
	var pool: Array[String] = []
	if dir:
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if fname.ends_with(".png"):
				pool.append(HAMPTERS_DIR + fname)
			fname = dir.get_next()
		dir.list_dir_end()
	_pack_tex = load(PACK_TEXTURE)
	pool.shuffle()
	for i in CARD_COUNT:
		_cards.append(load(pool[i]) as Texture2D)

	# 10-card pack: 6 Common → 2 Uncommon (silver) → 1 Rare (gold) → 1 Secret Rare
	for i in 6:
		_card_rarities.append(Rarity.COMMON)
	for i in 2:
		_card_rarities.append(Rarity.RARE)
	_card_rarities.append(Rarity.ULTRA_RARE)
	_card_rarities.append(Rarity.SECRET_RARE)


func _process(delta: float) -> void:
	if _phase == Phase.SWIPING:
		# Animate flying card off-screen at constant speed
		if _flying_card >= 0:
			_flying_offset = move_toward(_flying_offset, _flying_target, FLY_SPEED * delta)
			if _flying_offset == _flying_target:
				_flying_card = -1
				if _waiting_to_finish:
					finished.emit()
		# Spring current card back to center
		if _swipe_animating:
			_swipe_offset = lerp(_swipe_offset, 0.0, SWIPE_ANIM_SPEED * delta)
			if abs(_swipe_offset) < 1.0:
				_swipe_offset = 0.0
				_swipe_animating = false
	queue_redraw()


func _draw() -> void:
	# Background
	draw_rect(Rect2(phone_position, phone_size), Color(0.08, 0.06, 0.12), true)
	draw_rect(Rect2(phone_position, phone_size), Color(0.3, 0.2, 0.5), false, 2.0)

	var center := phone_position + phone_size * 0.5

	if _phase == Phase.RIPPING:
		_draw_rip_phase(center)
	elif _phase == Phase.SWIPING:
		_draw_swipe_phase(center)


func _draw_rip_phase(center: Vector2) -> void:
	# Pack rectangle
	var pack_w := phone_size.x * 0.72
	var pack_h := phone_size.y * 0.62
	var pack_x := center.x - pack_w * 0.5
	var pack_y := center.y - pack_h * 0.5 - 20.0

	# Rip tear offset — top half shifts right as you rip
	var tear_offset := _rip_direction * _rip_progress * pack_w * 0.6

	const TEAR_FRAC := 0.11
	var tex_w: float = _pack_tex.get_width()
	var tex_h: float = _pack_tex.get_height()
	var split_src := tex_h * TEAR_FRAC

	# Body — bottom portion stays fixed
	draw_texture_rect_region(_pack_tex,
		Rect2(pack_x, pack_y + pack_h * TEAR_FRAC, pack_w, pack_h * (1.0 - TEAR_FRAC)),
		Rect2(0, split_src, tex_w, tex_h - split_src))

	# Lip — top portion shifts with rip direction
	draw_texture_rect_region(_pack_tex,
		Rect2(pack_x + tear_offset, pack_y, pack_w, pack_h * TEAR_FRAC),
		Rect2(0, 0, tex_w, split_src))

	# Shiny foil overlay — body and lip separately so it follows the tear
	_draw_pack_sheen(pack_x, pack_y + pack_h * TEAR_FRAC, pack_w, pack_h * (1.0 - TEAR_FRAC))
	_draw_pack_sheen(pack_x + tear_offset, pack_y, pack_w, pack_h * TEAR_FRAC)

	# Tear-here indicators (fade out as rip progresses)
	var tear_alpha := 1.0 - _rip_progress
	if tear_alpha > 0.0:
		var tear_y := pack_y + pack_h * TEAR_FRAC
		var font := ThemeDB.fallback_font
		# Dotted line across the tear seam
		var dot_gap := 8.0
		var x := pack_x
		while x < pack_x + pack_w:
			draw_line(Vector2(x, tear_y), Vector2(minf(x + dot_gap * 0.5, pack_x + pack_w), tear_y),
				Color(1, 1, 1, tear_alpha * 0.9), 2.0)
			x += dot_gap
		# "✂ TEAR HERE" label above the pack
		var t := Time.get_ticks_msec() * 0.001
		var label := "✂  TEAR HERE"
		var lsz := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
		var lx := center.x - lsz.x * 0.5
		var above_y := pack_y - 14.0
		draw_string(font, Vector2(lx, above_y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, tear_alpha))
		# Animated ◄► arrow pulsing below label
		var pulse := 0.6 + 0.4 * sin(t * 4.0)
		var asz := font.get_string_size("◄  ►", HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
		draw_string(font, Vector2(center.x - asz.x * 0.5, above_y + 26), "◄  ►", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, tear_alpha * pulse))


func _draw_pack_sheen(x: float, y: float, w: float, h: float) -> void:
	var t := Time.get_ticks_msec() * 0.001

	# Subtle iridescent base — thin diagonal stripes cycling through cool hues
	for i in 6:
		var hue := fmod(t * 0.08 + float(i) / 6.0 * 0.25 + 0.55, 1.0)
		var col := Color.from_hsv(hue, 0.35, 1.0, 0.06)
		var slope := h
		var span := w + slope
		var stripe_w := span / 6.0
		var base := x + float(i) * stripe_w - slope
		var pts := PackedVector2Array()
		pts.append(Vector2(base, y))
		pts.append(Vector2(base + stripe_w, y))
		pts.append(Vector2(base + stripe_w + slope, y + h))
		pts.append(Vector2(base + slope, y + h))
		var clipped := _clip_poly_x(pts, x, x + w)
		if clipped.size() >= 3:
			draw_colored_polygon(clipped, col)

	# Bright specular streak sweeping left to right every 3.5s
	var progress := fmod(t / 3.5, 1.0)
	var streak_x := x - w * 0.3 + progress * (w * 1.6)
	var streak_w := w * 0.18
	var slope2 := h * 0.7
	var pts2 := PackedVector2Array()
	pts2.append(Vector2(streak_x, y))
	pts2.append(Vector2(streak_x + streak_w, y))
	pts2.append(Vector2(streak_x + streak_w + slope2, y + h))
	pts2.append(Vector2(streak_x + slope2, y + h))
	var clipped2 := _clip_poly_x(pts2, x, x + w)
	if clipped2.size() >= 3:
		# Fade in/out at edges of sweep
		var fade := sin(progress * PI)
		var streak_col := Color(1.0, 0.98, 0.92, 0.38 * fade)
		draw_colored_polygon(clipped2, streak_col)


func _draw_swipe_phase(center: Vector2) -> void:
	var font := ThemeDB.fallback_font

	var card_w := phone_size.x * 0.72
	var card_h := phone_size.y * 0.62
	var card_y := center.y - card_h * 0.5 - 20.0

	var cx := center.x - card_w * 0.5

	# Draw next card underneath — only when there is one
	if _current_card + 1 < CARD_COUNT:
		_draw_card(Rect2(cx, card_y, card_w, card_h), _current_card + 1)

	# Draw current card on top with drag offset
	if _current_card < CARD_COUNT:
		_draw_card(Rect2(cx + _swipe_offset, card_y, card_w, card_h), _current_card)

	# Draw flying card animating off-screen on top of everything
	if _flying_card >= 0 and _flying_card < _cards.size():
		_draw_card(Rect2(cx + _flying_offset, card_y, card_w, card_h), _flying_card)

	# Card counter
	var display_card: int = mini(_current_card + 1, CARD_COUNT)
	var counter := "%d / %d" % [display_card, CARD_COUNT]
	var csz     := font.get_string_size(counter, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	draw_string(font,
		Vector2(center.x - csz.x * 0.5, card_y + card_h + 28),
		counter, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)

	var t2 := Time.get_ticks_msec() * 0.001
	var pulse2 := 0.6 + 0.4 * sin(t2 * 4.0)
	var hint := "◄  SWIPE  ►"
	var hsz  := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
	draw_string(font,
		Vector2(center.x - hsz.x * 0.5, card_y + card_h + 56),
		hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, pulse2))


func _draw_card(rect: Rect2, idx: int) -> void:
	draw_rect(rect, Color(1.0, 0.97, 0.9), true)
	draw_texture_rect(_cards[idx], rect, false)
	if _card_rarities[idx] != Rarity.COMMON:
		_draw_rarity_filter(rect, _card_rarities[idx])
	draw_rect(rect, _rarity_border_color(_card_rarities[idx]), false, 4.0)


func _rarity_border_color(rarity: int) -> Color:
	var t := Time.get_ticks_msec() * 0.001
	match rarity:
		Rarity.RARE:        return Color(0.75, 0.85, 0.95)
		Rarity.ULTRA_RARE:  return Color(0.95, 0.72, 0.05)
		Rarity.SECRET_RARE: return Color.from_hsv(fmod(t * 0.4, 1.0), 1.0, 1.0)
		_:                  return Color(0.7, 0.6, 0.4)


func _draw_rarity_filter(rect: Rect2, rarity: int) -> void:
	match rarity:
		Rarity.RARE:        _draw_wavy_shimmer(rect, 0.58, 0.10, 0.15, 0.08, 0.0)
		Rarity.ULTRA_RARE:  _draw_wavy_shimmer(rect, 0.08, 0.06, 0.95, 0.09, 0.0)
		Rarity.SECRET_RARE: _draw_wavy_shimmer(rect, 0.0,  1.0,  0.9,  0.09, 0.12)


# Shared wavy stripe engine used by all rarity filters
# hue_speed: how fast hue shifts over time (0 = locked colour, 0.12 = full rainbow cycle)
func _draw_wavy_shimmer(rect: Rect2, hue_base: float, hue_range: float, saturation: float, alpha: float, hue_speed: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	var n := 48
	var slope := rect.size.y
	var span := rect.size.x + slope
	var stripe_w := span / 10.0
	var steps := 24
	for i in n:
		var hue := fmod(t * hue_speed + hue_base + float(i) / n * hue_range, 1.0)
		var col := Color.from_hsv(hue, saturation, 1.0, alpha)
		var base := rect.position.x + i * (span / n) - slope
		var phase := float(i) / n * TAU
		var pts := PackedVector2Array()
		for s in steps + 1:
			var frac: float = float(s) / steps
			var y: float = rect.position.y + frac * rect.size.y
			var wave: float = sin(frac * TAU * 2.5 + t * 0.9 + phase) * 8.0 \
							+ sin(frac * TAU * 1.0 + t * 0.5 + phase * 0.5) * 4.0
			pts.append(Vector2(base + frac * slope + wave, y))
		for s in range(steps, -1, -1):
			var frac: float = float(s) / steps
			var y: float = rect.position.y + frac * rect.size.y
			var wave: float = sin(frac * TAU * 2.5 + t * 0.9 + phase) * 8.0 \
							+ sin(frac * TAU * 1.0 + t * 0.5 + phase * 0.5) * 4.0
			pts.append(Vector2(base + stripe_w + frac * slope + wave, y))
		var clipped := _clip_poly_x(pts, rect.position.x, rect.position.x + rect.size.x)
		if clipped.size() >= 3:
			draw_colored_polygon(clipped, col)


func _clip_poly_x(pts: PackedVector2Array, x_min: float, x_max: float) -> PackedVector2Array:
	var tmp := _clip_poly_half(pts, x_min, true)
	return _clip_poly_half(tmp, x_max, false)


func _clip_poly_half(pts: PackedVector2Array, x_edge: float, keep_right: bool) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n: int = pts.size()
	for i in n:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		var a_in: bool = (a.x >= x_edge) == keep_right
		var b_in: bool = (b.x >= x_edge) == keep_right
		if a_in:
			out.append(a)
		if a_in != b_in:
			var tt: float = (x_edge - a.x) / (b.x - a.x)
			out.append(Vector2(x_edge, a.y + tt * (b.y - a.y)))
	return out


# ── Input ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _phase == Phase.RIPPING:
		_input_rip(event)
	elif _phase == Phase.SWIPING:
		_input_swipe(event)


func _input_rip(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var pos: Vector2 = make_input_local(event).position
			if Rect2(Vector2.ZERO, phone_size).has_point(pos):
				_rip_dragging = true
				_rip_start_x  = event.position.x
				_rip_current_x = event.position.x
		else:
			_rip_dragging = false

	elif event is InputEventMouseMotion and _rip_dragging:
		_rip_current_x = event.position.x
		var raw_dx: float = _rip_current_x - _rip_start_x
		if abs(raw_dx) > 4.0:
			_rip_direction = sign(raw_dx)
		_rip_progress = clamp(abs(raw_dx) / RIP_DISTANCE, 0.0, 1.0)
		if _rip_progress >= 1.0:
			_rip_dragging = false
			_phase = Phase.SWIPING
		queue_redraw()


func _input_swipe(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var pos: Vector2 = make_input_local(event).position
			if Rect2(Vector2.ZERO, phone_size).has_point(pos):
				_swipe_dragging = true
				_swipe_start_x  = event.position.x
				_swipe_velocity = 0.0
				_swipe_animating = false
		else:
			_swipe_dragging = false
			var flick: bool = abs(_swipe_velocity) >= 10.0
			var commit_dir: float = sign(_swipe_offset) if abs(_swipe_offset) > 0.1 else sign(_swipe_velocity)
			if (abs(_swipe_offset) >= SWIPE_THRESHOLD or flick) and commit_dir != 0 and _current_card < CARD_COUNT:
				# Launch current card off-screen, immediately advance
				_flying_card   = _current_card
				_flying_offset = _swipe_offset
				_flying_target = commit_dir * phone_size.x * 1.5
				_current_card += 1
				_swipe_offset  = 0.0
				if _current_card >= CARD_COUNT:
					_waiting_to_finish = true
			else:
				# Not far enough — spring back
				_swipe_animating = true

	elif event is InputEventMouseMotion and _swipe_dragging:
		var dx: float   = event.position.x - _swipe_start_x
		_swipe_velocity = dx - _swipe_offset
		_swipe_offset   = dx
		queue_redraw()
