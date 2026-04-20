extends Node2D

signal hand_signaled

@onready var left_hand: Sprite2D = $Left/LeftHand
@onready var right_hand: Sprite2D = $Right/RightHand
@onready var left_hand_phone: Sprite2D = $Left/LeftHand_Phone
@onready var right_hand_phone: Sprite2D = $Right/RightHand_Phone
@onready var left_sleeve: Sprite2D = $Left/LeftSleeve
@onready var right_sleeve: Sprite2D = $Right/RightSleeve


const HAND_DOWN = preload("res://Assets/Player/RestingHands/HAND_DOWN_A.png")
const HAND_DOWN_B = preload("res://Assets/Player/RestingHands/HAND_DOWN_B.png")
const HAND_UP = preload("res://Assets/Player/RaisedHands/HAND_UP_A.png")
const HAND_UP_B = preload("res://Assets/Player/RaisedHands/HAND_UP_B.png")
const POINTER_OFFSET = Vector2(115, 102)
var hand_change_y_threshold: int = 500
var is_on_phone: bool = false

var left_hand_original_pos: Vector2
var right_hand_original_pos: Vector2
var left_hand_phone_original_pos: Vector2
var right_hand_phone_original_pos: Vector2
var right_hand_phone_original_rotation: float
var left_sleeve_offset: Vector2
var right_sleeve_offset: Vector2
var last_controlled_side: String = ""
var left_hand_returning: bool = false
var right_hand_returning: bool = false
var left_hand_taking_control: bool = false
var right_hand_taking_control: bool = false
var left_hand_control_start_time: float = 0.0
var right_hand_control_start_time: float = 0.0
var return_animation_speed: float = 0.2
var control_animation_delay: float = 0.15
var control_lerp_weight: float = 0.15
var phone_transition_duration: float = 0.3
var is_transitioning: bool = false
var active_transition_tweens: Array[Tween] = []
var active_hand: String = "Left"
var is_shaking: bool = false
var phone_tilt_tween: Tween = null
var is_phone_tilted: bool = false
var flicker_timer: float = 0.0
var flicker_interval: float = 0.1
var use_b_variant: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	left_hand_original_pos = left_hand.position
	right_hand_original_pos = right_hand.position
	left_hand_phone_original_pos = left_hand_phone.position
	right_hand_phone_original_pos = right_hand_phone.position
	right_hand_phone_original_rotation = right_hand_phone.rotation
	
	# Store the original offset between sleeves and hands
	left_sleeve_offset = left_sleeve.position - left_hand.position
	right_sleeve_offset = right_sleeve.position - right_hand.position
	
	# Start with phone hands hidden below viewport
	var viewport_height = get_viewport_rect().size.y
	left_hand_phone.position.y = viewport_height + 200
	right_hand_phone.position.y = viewport_height + 200
	left_hand_phone.visible = false
	right_hand_phone.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Update flicker timer
	flicker_timer += delta
	if flicker_timer >= flicker_interval:
		flicker_timer = 0.0
		use_b_variant = not use_b_variant
	
	# Skip mouse control during phone transitions
	if is_transitioning:
		return
	
	var mouse_pos = get_local_mouse_position()
	
	# Handle phone mode controls
	if is_on_phone:
		left_hand_phone.position = left_hand_phone_original_pos
		right_hand_phone.position = mouse_pos + POINTER_OFFSET
		left_sleeve.visible = false
		right_sleeve.visible = false
		return
	
	# Regular hand controls
	var screen_width = get_viewport_rect().size.x
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Determine which side of the screen the mouse is on
	if mouse_pos.x < screen_width / 2:
		active_hand = "Left"
		# Left side - control left hand
		if last_controlled_side == "right" and not right_hand_returning:
			# Transition: animate right hand back to original position
			right_hand_returning = true
			right_hand.texture = HAND_DOWN_B if use_b_variant else HAND_DOWN
			var return_tween = create_tween()
			return_tween.set_trans(Tween.TRANS_SINE)
			return_tween.set_ease(Tween.EASE_IN_OUT)
			return_tween.tween_property(right_hand, "position", right_hand_original_pos, return_animation_speed)
			return_tween.finished.connect(func(): right_hand_returning = false)
			
			# Start left hand control transition
			left_hand_taking_control = true
			left_hand_control_start_time = current_time
		
		last_controlled_side = "left"
		left_hand_returning = false
		
		# Handle left hand control
		if left_hand_taking_control:
			var time_since_start = current_time - left_hand_control_start_time
			if time_since_start >= control_animation_delay:
				# Smoothly lerp toward current mouse position
				left_hand.position = left_hand.position.lerp(mouse_pos, control_lerp_weight)
				
				# Stop taking control when close enough to mouse
				if left_hand.position.distance_to(mouse_pos) < 5.0:
					left_hand_taking_control = false
		else:
			# Direct control
			left_hand.position = mouse_pos
		
		# Check if hand is lifted above threshold and apply flicker
		if mouse_pos.y < hand_change_y_threshold:
			left_hand.texture = HAND_UP_B if use_b_variant else HAND_UP
		else:
			left_hand.texture = HAND_DOWN_B if use_b_variant else HAND_DOWN
	else:
		# Right side - control right hand
		active_hand = "Right"
		if last_controlled_side == "left" and not left_hand_returning:
			# Transition: animate left hand back to original position
			left_hand_returning = true
			left_hand.texture = HAND_DOWN_B if use_b_variant else HAND_DOWN
			var return_tween = create_tween()
			return_tween.set_trans(Tween.TRANS_SINE)
			return_tween.set_ease(Tween.EASE_IN_OUT)
			return_tween.tween_property(left_hand, "position", left_hand_original_pos, return_animation_speed)
			return_tween.finished.connect(func(): left_hand_returning = false)
			
			# Start right hand control transition
			right_hand_taking_control = true
			right_hand_control_start_time = current_time
		
		last_controlled_side = "right"
		right_hand_returning = false
		
		# Handle right hand control
		if right_hand_taking_control:
			var time_since_start = current_time - right_hand_control_start_time
			if time_since_start >= control_animation_delay:
				# Smoothly lerp toward current mouse position
				right_hand.position = right_hand.position.lerp(mouse_pos, control_lerp_weight)
				
				# Stop taking control when close enough to mouse
				if right_hand.position.distance_to(mouse_pos) < 5.0:
					right_hand_taking_control = false
		else:
			# Direct control
			right_hand.position = mouse_pos
		
		# Check if hand is lifted above threshold and apply flicker
		if mouse_pos.y < hand_change_y_threshold:
			right_hand.texture = HAND_UP_B if use_b_variant else HAND_UP
		else:
			right_hand.texture = HAND_DOWN_B if use_b_variant else HAND_DOWN
	
	# Update sleeve positions to maintain constant distance to hands
	left_sleeve.visible = true
	right_sleeve.visible = true
	left_sleeve.position = left_hand.position + left_sleeve_offset
	right_sleeve.position = right_hand.position + right_sleeve_offset

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				emit_signal("hand_signaled", active_hand)
				shake_active_hand()
			else:
				# Handle mouse button release
				if is_on_phone and is_phone_tilted:
					tween_phone_back()

func shake_active_hand() -> void:
	
	if is_shaking:
		return
	
	var hand_to_shake: Sprite2D = null
	
	# Determine which hand is active
	if is_on_phone:
		hand_to_shake = right_hand_phone
		# Special behavior for phone: tween to 2 degrees while held
		if phone_tilt_tween and phone_tilt_tween.is_valid():
			phone_tilt_tween.kill()
		
		phone_tilt_tween = create_tween()
		phone_tilt_tween.set_trans(Tween.TRANS_SINE)
		phone_tilt_tween.set_ease(Tween.EASE_IN_OUT)
		
		var target_angle = right_hand_phone_original_rotation - deg_to_rad(2.0)
		phone_tilt_tween.tween_property(hand_to_shake, "rotation", target_angle, 0.2)
		is_phone_tilted = true
		return
	elif last_controlled_side == "left":
		hand_to_shake = left_hand
	elif last_controlled_side == "right":
		hand_to_shake = right_hand
	else:
		return
	
	is_shaking = true
	
	# Create shake animation
	var shake_tween = create_tween()
	shake_tween.set_trans(Tween.TRANS_SINE)
	shake_tween.set_ease(Tween.EASE_IN_OUT)
	
	var shake_angle = deg_to_rad(10.0)
	var shake_duration = 0.08
	var original_rotation = hand_to_shake.rotation
	
	# Rotate left and right 3 times
	shake_tween.tween_property(hand_to_shake, "rotation", original_rotation - shake_angle, shake_duration)
	shake_tween.tween_property(hand_to_shake, "rotation", original_rotation + shake_angle, shake_duration)
	shake_tween.tween_property(hand_to_shake, "rotation", original_rotation - shake_angle, shake_duration)
	shake_tween.tween_property(hand_to_shake, "rotation", original_rotation + shake_angle, shake_duration)
	shake_tween.tween_property(hand_to_shake, "rotation", original_rotation - shake_angle, shake_duration)
	shake_tween.tween_property(hand_to_shake, "rotation", original_rotation + shake_angle, shake_duration)
	shake_tween.tween_property(hand_to_shake, "rotation", original_rotation, shake_duration)
	
	shake_tween.finished.connect(func(): is_shaking = false)

func tween_phone_back() -> void:
	if phone_tilt_tween and phone_tilt_tween.is_valid():
		phone_tilt_tween.kill()
	
	phone_tilt_tween = create_tween()
	phone_tilt_tween.set_trans(Tween.TRANS_SINE)
	phone_tilt_tween.set_ease(Tween.EASE_IN_OUT)
	
	phone_tilt_tween.tween_property(right_hand_phone, "rotation", right_hand_phone_original_rotation, 0.2)
	is_phone_tilted = false

func _on_restaurant_camera_view_changed(view_name: String) -> void:
	if view_name == "down":
		animate_to_phone_hands()
	else:
		animate_to_regular_hands()

func animate_to_phone_hands() -> void:
	if is_on_phone and not is_transitioning:
		return
	
	# Cancel any active transition
	for tween in active_transition_tweens:
		if tween and tween.is_valid():
			tween.kill()
	active_transition_tweens.clear()
	
	is_transitioning = true
	is_on_phone = true
	var viewport_height = get_viewport_rect().size.y
	
	# Animate regular hands down below viewport
	var hands_down_tween = create_tween()
	hands_down_tween.set_parallel(true)
	hands_down_tween.set_trans(Tween.TRANS_CUBIC)
	hands_down_tween.set_ease(Tween.EASE_IN)
	hands_down_tween.tween_property(left_hand, "position:y", viewport_height + 200, phone_transition_duration)
	hands_down_tween.tween_property(right_hand, "position:y", viewport_height + 200, phone_transition_duration)
	active_transition_tweens.append(hands_down_tween)
	
	await hands_down_tween.finished
	
	# Hide regular hands and sleeves, show phone hands
	left_hand.visible = false
	right_hand.visible = false
	left_sleeve.visible = false
	right_sleeve.visible = false
	left_hand_phone.visible = true
	right_hand_phone.visible = true
	
	# Animate phone hands up into view
	var mouse_pos = get_local_mouse_position()
	var phone_hands_up_tween = create_tween()
	phone_hands_up_tween.set_parallel(true)
	phone_hands_up_tween.set_trans(Tween.TRANS_CUBIC)
	phone_hands_up_tween.set_ease(Tween.EASE_OUT)
	phone_hands_up_tween.tween_property(left_hand_phone, "position", left_hand_phone_original_pos, phone_transition_duration)
	phone_hands_up_tween.tween_property(right_hand_phone, "position", mouse_pos + POINTER_OFFSET, phone_transition_duration)
	active_transition_tweens.append(phone_hands_up_tween)
	
	await phone_hands_up_tween.finished
	active_transition_tweens.clear()
	is_transitioning = false

func animate_to_regular_hands() -> void:
	if not is_on_phone and not is_transitioning:
		return
	
	# Cancel any active transition
	for tween in active_transition_tweens:
		if tween and tween.is_valid():
			tween.kill()
	active_transition_tweens.clear()
	
	is_transitioning = true
	is_on_phone = false
	var viewport_height = get_viewport_rect().size.y
	
	# Animate phone hands down below viewport
	var phone_hands_down_tween = create_tween()
	phone_hands_down_tween.set_parallel(true)
	phone_hands_down_tween.set_trans(Tween.TRANS_CUBIC)
	phone_hands_down_tween.set_ease(Tween.EASE_IN)
	phone_hands_down_tween.tween_property(left_hand_phone, "position:y", viewport_height + 200, phone_transition_duration)
	phone_hands_down_tween.tween_property(right_hand_phone, "position:y", viewport_height + 200, phone_transition_duration)
	active_transition_tweens.append(phone_hands_down_tween)
	
	await phone_hands_down_tween.finished
	
	# Hide phone hands and show regular hands and sleeves
	left_hand_phone.visible = false
	right_hand_phone.visible = false
	left_hand.visible = true
	right_hand.visible = true
	left_sleeve.visible = true
	right_sleeve.visible = true
	
	# Animate regular hands up into view
	var hands_up_tween = create_tween()
	hands_up_tween.set_parallel(true)
	hands_up_tween.set_trans(Tween.TRANS_CUBIC)
	hands_up_tween.set_ease(Tween.EASE_OUT)
	hands_up_tween.tween_property(left_hand, "position", left_hand_original_pos, phone_transition_duration)
	hands_up_tween.tween_property(right_hand, "position", right_hand_original_pos, phone_transition_duration)
	active_transition_tweens.append(hands_up_tween)
	
	await hands_up_tween.finished
	active_transition_tweens.clear()
	is_transitioning = false
