extends Node

## MobileInputManager singleton for handling touch input and gestures
## Provides mobile-optimized input handling for the game

signal touch_started(position: Vector2, index: int)
signal touch_ended(position: Vector2, index: int)
signal touch_dragged(position: Vector2, relative: Vector2, index: int)
signal pinch_gesture(distance: float, center: Vector2)

var active_touches: Dictionary = {}
var camera: Camera3D

func _ready():
	print("MobileInputManager initialized")

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		handle_touch_input(event)
	elif event is InputEventScreenDrag:
		handle_drag_input(event)

func handle_touch_input(event: InputEventScreenTouch) -> void:
	if event.pressed:
		active_touches[event.index] = event.position
		touch_started.emit(event.position, event.index)
	else:
		if event.index in active_touches:
			active_touches.erase(event.index)
		touch_ended.emit(event.position, event.index)
	
	# Handle pinch gesture for two touches
	if active_touches.size() == 2:
		var positions = active_touches.values()
		var distance = positions[0].distance_to(positions[1])
		var center = (positions[0] + positions[1]) / 2.0
		pinch_gesture.emit(distance, center)

func handle_drag_input(event: InputEventScreenDrag) -> void:
	if event.index in active_touches:
		active_touches[event.index] = event.position
		touch_dragged.emit(event.position, event.relative, event.index)

func convert_touch_to_3d_position(screen_pos: Vector2, camera_3d: Camera3D = null) -> Vector3:
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
	var result = space_state.intersect_ray(query)
	
	if result:
		return result.position
	else:
		# Return position on a plane at distance 10 from camera
		return from + camera_3d.project_ray_normal(screen_pos) * 10.0

func set_camera(new_camera: Camera3D) -> void:
	camera = new_camera

func get_touch_count() -> int:
	return active_touches.size()

func is_touching() -> bool:
	return active_touches.size() > 0