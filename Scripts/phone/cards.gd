extends Node2D

signal finished

var phone_position: Vector2
var phone_size: Vector2

# ── Card images ──────────────────────────────────────────────────────
const CARD_IMAGES := [
	"res://Assets/Phone/cards/witch.png",
	"res://Assets/Phone/cards/candy.png",
	"res://Assets/Phone/cards/frankenstein.png",
	"res://Assets/Phone/cards/dracula.png",
	"res://Assets/Phone/cards/jason.png",
	"res://Assets/Phone/cards/ghostface.png",
	"res://Assets/Phone/cards/blob.png",
	"res://Assets/Phone/cards/ghost.png",
	"res://Assets/Phone/cards/devil.png",
	"res://Assets/Phone/cards/shrek.png",
	"res://Assets/Phone/cards/pumpkin.png",
]
const CARD_COUNT := 5

# ── State ────────────────────────────────────────────────────────────
enum Phase { RIPPING, SWIPING, DONE }
var _phase: Phase = Phase.RIPPING

var _cards: Array[Texture2D] = []

# Rip phase
var _rip_progress: float = 0.0   # 0 to 1
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
var _swipe_target: float = 0.0
const SWIPE_THRESHOLD := 80.0
const SWIPE_ANIM_SPEED := 12.0


func setup(pos: Vector2, size: Vector2) -> void:
	phone_position = pos
	phone_size     = size

	# Pick 5 random cards
	var pool := CARD_IMAGES.duplicate()
	pool.shuffle()
	for i in CARD_COUNT:
		var tex: Texture2D = load(pool[i])
		_cards.append(tex)


func _process(delta: float) -> void:
	if _phase == Phase.SWIPING and _swipe_animating:
		_swipe_offset = lerp(_swipe_offset, _swipe_target, SWIPE_ANIM_SPEED * delta)
		if abs(_swipe_offset - _swipe_target) < 1.0:
			# Snap-complete: reset offset so the next card draws from center
			_swipe_offset = 0.0
			_swipe_animating = false
			_swipe_target = 0.0
			if _current_card >= CARD_COUNT:
				_phase = Phase.DONE
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
	elif _phase == Phase.DONE:
		_draw_done(center)


func _draw_rip_phase(center: Vector2) -> void:
	var font := ThemeDB.fallback_font

	# Pack rectangle
	var pack_w := phone_size.x * 0.72
	var pack_h := phone_size.y * 0.62
	var pack_x := center.x - pack_w * 0.5
	var pack_y := center.y - pack_h * 0.5 - 20.0

	# Rip tear offset — top half shifts right as you rip
	var tear_offset := _rip_progress * pack_w * 0.6

	# Body of pack (almost all of it)
	draw_rect(Rect2(pack_x, pack_y + pack_h * 0.1, pack_w, pack_h * 0.9),
		Color(0.85, 0.2, 0.2), true)

	# Just the lip at the top shifts with rip
	draw_rect(Rect2(pack_x + tear_offset, pack_y, pack_w, pack_h * 0.12),
		Color(0.95, 0.25, 0.25), true)

	# Pack sheen line
	draw_line(
		Vector2(pack_x + tear_offset + pack_w * 0.15, pack_y + 8),
		Vector2(pack_x + tear_offset + pack_w * 0.2,  pack_y + pack_h * 0.1),
		Color(1.0, 1.0, 1.0, 0.25), 6.0, true)

	# Tear line near top
	var tear_y := pack_y + pack_h * 0.11

	# Pack label (stays fixed on the body)
	var lbl := "HAMPTER PACK"
	var lsz := font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	draw_string(font,
		Vector2(pack_x + (pack_w - lsz.x) * 0.5, pack_y + pack_h * 0.25),
		lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

func _draw_swipe_phase(center: Vector2) -> void:
	var font := ThemeDB.fallback_font

	var card_w := phone_size.x * 0.72
	var card_h := phone_size.y * 0.62
	var card_y := center.y - card_h * 0.5 - 20.0

	# Draw next card underneath
	if _current_card + 1 < CARD_COUNT:
		draw_rect(Rect2(center.x - card_w * 0.5, card_y, card_w, card_h),
			Color(1.0, 0.97, 0.9), true)
		draw_rect(Rect2(center.x - card_w * 0.5, card_y, card_w, card_h),
			Color(0.7, 0.6, 0.4), false, 2.5)

	# Draw current card on top with swipe offset
	var card_x := center.x - card_w * 0.5 + _swipe_offset
	draw_rect(Rect2(card_x, card_y, card_w, card_h), Color(1.0, 0.97, 0.9), true)
	draw_rect(Rect2(card_x, card_y, card_w, card_h), Color(0.7, 0.6, 0.4), false, 2.5)

	# Card counter
	var counter := "%d / %d" % [min(_current_card + 1, CARD_COUNT), CARD_COUNT]
	var csz     := font.get_string_size(counter, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	draw_string(font,
		Vector2(center.x - csz.x * 0.5, card_y + card_h + 18),
		counter, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.6, 0.7))

	var hint := "swipe to view next"
	var hsz  := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	draw_string(font,
		Vector2(center.x - hsz.x * 0.5, card_y + card_h + 36),
		hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.45, 0.45, 0.55))


func _draw_done(center: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var msg  := "Pack Opened!"
	var msz  := font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 24)
	draw_string(font,
		Vector2(center.x - msz.x * 0.5, center.y - 20),
		msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1.0, 0.85, 0.2))

	var sub  := "tap to finish"
	var ssz  := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	draw_string(font,
		Vector2(center.x - ssz.x * 0.5, center.y + 16),
		sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.6, 0.7))


# ── Input ─────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _phase == Phase.RIPPING:
		_input_rip(event)
	elif _phase == Phase.SWIPING:
		_input_swipe(event)
	elif _phase == Phase.DONE:
		if event is InputEventMouseButton and event.pressed:
			finished.emit()


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
		var delta_x: float = abs(_rip_current_x - _rip_start_x)
		_rip_progress = clamp(delta_x / RIP_DISTANCE, 0.0, 1.0)
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
		else:
			_swipe_dragging = false
			if abs(_swipe_offset) >= SWIPE_THRESHOLD:
				# Commit the swipe: fly the card off-screen in the direction dragged
				_swipe_target    = sign(_swipe_offset) * phone_size.x * 1.2
				_swipe_animating = true
				_current_card   += 1
			else:
				# Not far enough — spring back to center
				_swipe_target    = 0.0
				_swipe_animating = true

	elif event is InputEventMouseMotion and _swipe_dragging:
		var dx: float  = event.position.x - _swipe_start_x
		_swipe_velocity = dx - _swipe_offset
		_swipe_offset   = dx
		queue_redraw()
