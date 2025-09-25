extends Node

## MobileInputManager singleton for handling touch input and gestures
## Provides mobile-optimized input handling for the game

# Touch event signals
signal touch_started(position: Vector2, index: int)
signal touch_ended(position: Vector2, index: int)
signal touch_dragged(position: Vector2, relative: Vector2, index: int)

# Gesture signals
signal pinch_gesture(distance: float, center: Vector2, delta_distance: float)
signal pan_gesture(delta: Vector2, center: Vector2)
signal tap_gesture(position: Vector2)
signal long_press_gesture(position: Vector2)

# Launcher-specific signals
signal launcher_pull_started(position: Vector2)
signal launcher_pull_updated(position: Vector2, pull_distance: float)
signal launcher_pull_released(position: Vector2, pull_distance: float)

# Touch tracking
var active_touches: Dictionary = {}
var touch_start_times: Dictionary = {}
var initial_pinch_distance: float = 0.0
var current_pinch_distance: float = 0.0

# Camera reference
var camera: Camera3D

# Touch settings
@export var tap_threshold_time: float = 0.3  # Maximum time for tap
@export var long_press_threshold_time: float = 0.8  # Minimum time for long press
@export var drag_threshold_distance: float = 10.0  # Minimum distance to start drag
@export var pinch_threshold_distance: float = 20.0  # Minimum distance change for pinch

# Launcher interaction state
var launcher_touch_index: int = -1
var launcher_start_position: Vector2
var is_launcher_active: bool = false

func _ready():
	print("MobileInputManager initialized")
	# Set process mode to always to handle input even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		handle_touch_input(event)
	elif event is InputEventScreenDrag:
		handle_drag_input(event)
	elif event is InputEventMouseButton:
		handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		handle_mouse_motion(event)

func handle_touch_input(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Start touch
		active_touches[event.index] = event.position
		touch_start_times[event.index] = Time.get_ticks_msec()
		touch_started.emit(event.position, event.index)
		
		# Check if this could be a launcher interaction (single touch)
		if active_touches.size() == 1 and not is_launcher_active:
			_check_launcher_interaction_start(event.position, event.index)
		
		# Initialize pinch gesture for two touches
		if active_touches.size() == 2:
			var positions = active_touches.values()
			initial_pinch_distance = positions[0].distance_to(positions[1])
			current_pinch_distance = initial_pinch_distance
	else:
		# End touch
		if event.index in active_touches:
			var touch_duration = _get_touch_duration(event.index)
			var start_pos = active_touches[event.index]
			var distance_moved = start_pos.distance_to(event.position)
			
			# Detect tap vs drag
			if touch_duration <= tap_threshold_time and distance_moved < drag_threshold_distance:
				tap_gesture.emit(event.position)
			elif touch_duration >= long_press_threshold_time and distance_moved < drag_threshold_distance:
				long_press_gesture.emit(event.position)
			
			# Handle launcher release
			if event.index == launcher_touch_index and is_launcher_active:
				_handle_launcher_release(event.position)
			
			# Clean up touch tracking
			active_touches.erase(event.index)
			touch_start_times.erase(event.index)
		
		touch_ended.emit(event.position, event.index)
		
		# Reset pinch if we go below 2 touches
		if active_touches.size() < 2:
			initial_pinch_distance = 0.0
			current_pinch_distance = 0.0

func handle_drag_input(event: InputEventScreenDrag) -> void:
	if event.index in active_touches:
		active_touches[event.index] = event.position
		touch_dragged.emit(event.position, event.relative, event.index)
		
		# Handle launcher drag
		if event.index == launcher_touch_index and is_launcher_active:
			_handle_launcher_drag(event.position)
		
		# Handle pinch gesture
		if active_touches.size() == 2:
			_handle_pinch_gesture()
		
		# Handle pan gesture (single finger drag)
		elif active_touches.size() == 1:
			_handle_pan_gesture(event.relative, event.position)

func convert_touch_to_3d_position(screen_pos: Vector2, camera_3d: Camera3D = null) -> Vector3:
	"""Convert screen touch position to 3D world position"""
	if camera_3d == null:
		camera_3d = camera
	
	if camera_3d == null:
		push_warning("No camera available for 3D conversion")
		return Vector3.ZERO
	
	# Project screen position to 3D world space
	var from = camera_3d.project_ray_origin(screen_pos)
	var to = from + camera_3d.project_ray_normal(screen_pos) * 1000.0
	
	# Cast ray to find intersection with world
	var space_state = camera_3d.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1  # Only check world layer
	var result = space_state.intersect_ray(query)
	
	if result:
		return result.position
	else:
		# Return position on a plane at distance 10 from camera
		return from + camera_3d.project_ray_normal(screen_pos) * 10.0

func convert_touch_to_3d_direction(screen_pos: Vector2, camera_3d: Camera3D = null) -> Vector3:
	"""Convert screen touch position to 3D ray direction"""
	if camera_3d == null:
		camera_3d = camera
	
	if camera_3d == null:
		push_warning("No camera available for 3D conversion")
		return Vector3.FORWARD
	
	return camera_3d.project_ray_normal(screen_pos)

func project_3d_to_screen(world_pos: Vector3, camera_3d: Camera3D = null) -> Vector2:
	"""Project 3D world position to screen coordinates"""
	if camera_3d == null:
		camera_3d = camera
	
	if camera_3d == null:
		push_warning("No camera available for screen projection")
		return Vector2.ZERO
	
	return camera_3d.unproject_position(world_pos)

# Launcher interaction methods
func _check_launcher_interaction_start(position: Vector2, index: int) -> void:
	"""Check if touch started on launcher area"""
	# For now, we'll assume any single touch could be launcher interaction
	launcher_touch_index = index
	launcher_start_position = position
	is_launcher_active = true
	launcher_pull_started.emit(position)

func _handle_launcher_drag(position: Vector2) -> void:
	"""Handle launcher pull drag"""
	if not is_launcher_active:
		return
	
	var pull_distance = launcher_start_position.distance_to(position)
	launcher_pull_updated.emit(position, pull_distance)

func _handle_launcher_release(position: Vector2) -> void:
	"""Handle launcher release"""
	if not is_launcher_active:
		return
	
	var pull_distance = launcher_start_position.distance_to(position)
	launcher_pull_released.emit(position, pull_distance)
	
	# Reset launcher state
	launcher_touch_index = -1
	is_launcher_active = false

# Gesture handling methods
func _handle_pinch_gesture() -> void:
	"""Handle pinch zoom gesture"""
	if active_touches.size() != 2:
		return
	
	var positions = active_touches.values()
	var new_distance = positions[0].distance_to(positions[1])
	var center = (positions[0] + positions[1]) / 2.0
	var delta_distance = new_distance - current_pinch_distance
	
	if abs(delta_distance) > pinch_threshold_distance:
		pinch_gesture.emit(new_distance, center, delta_distance)
		current_pinch_distance = new_distance

func _handle_pan_gesture(relative: Vector2, position: Vector2) -> void:
	"""Handle single finger pan gesture"""
	if is_launcher_active:
		return  # Don't pan while launcher is active
	
	pan_gesture.emit(relative, position)

func _get_touch_duration(index: int) -> float:
	"""Get duration of touch in seconds"""
	if index not in touch_start_times:
		return 0.0
	
	var start_time_ms = touch_start_times[index]
	var current_time_ms = Time.get_ticks_msec()
	
	var duration_ms = current_time_ms - start_time_ms
	return duration_ms / 1000.0  # Convert to seconds

# Public interface methods
func set_camera(new_camera: Camera3D) -> void:
	"""Set the camera for 3D conversions"""
	camera = new_camera

func get_touch_count() -> int:
	"""Get number of active touches"""
	return active_touches.size()

func is_touching() -> bool:
	"""Check if any touches are active"""
	return active_touches.size() > 0

func get_touch_position(index: int) -> Vector2:
	"""Get position of specific touch"""
	return active_touches.get(index, Vector2.ZERO)

func get_touch_positions() -> Array[Vector2]:
	"""Get all active touch positions"""
	var positions: Array[Vector2] = []
	for pos in active_touches.values():
		positions.append(pos)
	return positions

func enable_launcher_mode() -> void:
	"""Enable launcher interaction mode"""
	# This could be used to restrict input to launcher only
	pass

func disable_launcher_mode() -> void:
	"""Disable launcher interaction mode"""
	if is_launcher_active:
		_handle_launcher_release(launcher_start_position)

func is_launcher_interaction_active() -> bool:
	"""Check if launcher interaction is currently active"""
	return is_launcher_active

# Mouse input handlers (for desktop testing)
func handle_mouse_button(event: InputEventMouseButton) -> void:
	"""Handle mouse button events as touch events"""
	if event.button_index == MOUSE_BUTTON_LEFT:
		# Convert mouse button to touch event
		var touch_event = InputEventScreenTouch.new()
		touch_event.index = 0
		touch_event.position = event.position
		touch_event.pressed = event.pressed
		handle_touch_input(touch_event)

func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	"""Handle mouse motion as touch drag when button is pressed"""
	if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		# Convert mouse motion to touch drag
		var drag_event = InputEventScreenDrag.new()
		drag_event.index = 0
		drag_event.position = event.position
		drag_event.relative = event.relative
		handle_drag_input(drag_event)