class_name FlightCamera
extends Camera3D

## Flight camera that smoothly follows airplane during flight
## Handles camera switching between launch view and flight tracking
## Implements distance measurement from launch point

@export_group("Camera Settings")
@export var follow_speed: float = 2.0  # Speed of camera following
@export var look_ahead_distance: float = 3.0  # How far ahead to look
@export var height_offset: float = 2.0  # Height above airplane
@export var distance_behind: float = 5.0  # Distance behind airplane
@export var smooth_rotation: bool = true  # Smooth camera rotation
@export var rotation_speed: float = 1.5  # Speed of camera rotation

@export_group("Launch View Settings")
@export var launch_position: Vector3 = Vector3(0, 3, 8)  # Launch camera position
@export var launch_target: Vector3 = Vector3.ZERO  # Launch camera target
@export var transition_speed: float = 3.0  # Speed of view transitions

@export_group("Touch Controls")
@export var touch_pan_sensitivity: float = 0.002  # Sensitivity for touch panning
@export var pinch_zoom_sensitivity: float = 0.01  # Sensitivity for pinch zoom
@export var min_zoom_distance: float = 2.0  # Minimum camera distance
@export var max_zoom_distance: float = 20.0  # Maximum camera distance
@export var pan_bounds_size: float = 10.0  # Maximum pan distance from target
@export var smooth_touch_response: bool = true  # Smooth touch input response
@export var touch_response_speed: float = 5.0  # Speed of touch response smoothing

# Camera modes
enum CameraMode {
	LAUNCH_VIEW,    # Static view for launching
	FLIGHT_TRACKING, # Following airplane during flight
	TRANSITIONING   # Transitioning between modes
}

# Internal state
var current_mode: CameraMode = CameraMode.LAUNCH_VIEW
var target_airplane: BasicAirplane = null
var launch_point: Vector3 = Vector3.ZERO
var flight_start_position: Vector3 = Vector3.ZERO

# Smooth following variables
var target_position: Vector3
var target_look_at: Vector3
var velocity: Vector3 = Vector3.ZERO

# Distance tracking
var max_distance_from_launch: float = 0.0
var current_distance_from_launch: float = 0.0

# Touch control state
var touch_enabled: bool = true
var is_panning: bool = false
var is_zooming: bool = false
var pan_offset: Vector3 = Vector3.ZERO
var target_pan_offset: Vector3 = Vector3.ZERO
var current_zoom_distance: float = 5.0
var target_zoom_distance: float = 5.0
var base_camera_position: Vector3
var last_pinch_distance: float = 0.0

signal camera_mode_changed(new_mode: CameraMode)
signal distance_updated(distance: float, max_distance: float)

func _ready() -> void:
	# Set initial launch view
	set_launch_view()
	
	# Initialize touch controls
	current_zoom_distance = distance_behind
	target_zoom_distance = distance_behind
	
	# Connect to MobileInputManager
	_connect_mobile_input()
	
	print("FlightCamera initialized in launch view with touch controls")

func _process(delta: float) -> void:
	# Update touch control smoothing
	if touch_enabled:
		_update_touch_controls(delta)
	
	match current_mode:
		CameraMode.LAUNCH_VIEW:
			_update_launch_view(delta)
		CameraMode.FLIGHT_TRACKING:
			_update_flight_tracking(delta)
		CameraMode.TRANSITIONING:
			_update_transition(delta)
	
	# Update distance measurement if airplane is available
	if target_airplane:
		_update_distance_measurement()

func set_target_airplane(airplane: BasicAirplane) -> void:
	"""Set the airplane to track"""
	target_airplane = airplane
	if airplane:
		launch_point = airplane.global_position
		flight_start_position = airplane.global_position
		max_distance_from_launch = 0.0
		print("FlightCamera target set to airplane at: ", launch_point)

func set_launch_view() -> void:
	"""Switch to launch view mode"""
	if current_mode == CameraMode.LAUNCH_VIEW:
		return
	
	current_mode = CameraMode.LAUNCH_VIEW
	
	# Set camera to launch position
	global_position = launch_position
	look_at(launch_target, Vector3.UP)
	
	camera_mode_changed.emit(current_mode)
	print("Camera switched to launch view")

func start_flight_tracking() -> void:
	"""Switch to flight tracking mode"""
	if not target_airplane:
		print("Cannot start flight tracking: no target airplane")
		return
	
	if current_mode == CameraMode.FLIGHT_TRACKING:
		return
	
	current_mode = CameraMode.TRANSITIONING
	
	# Calculate initial flight tracking position
	_calculate_flight_tracking_position()
	
	print("Camera starting flight tracking transition")

func stop_flight_tracking() -> void:
	"""Stop flight tracking and return to launch view"""
	if current_mode == CameraMode.LAUNCH_VIEW:
		return
	
	current_mode = CameraMode.TRANSITIONING
	target_position = launch_position
	target_look_at = launch_target
	
	print("Camera returning to launch view")

func _update_launch_view(delta: float) -> void:
	"""Update camera in launch view mode"""
	# Keep camera in launch position
	# Could add slight movement or breathing effect here if desired
	pass

func _update_flight_tracking(delta: float) -> void:
	"""Update camera during flight tracking"""
	if not target_airplane:
		return
	
	# Calculate desired camera position
	_calculate_flight_tracking_position()
	
	# Smooth camera movement
	global_position = global_position.lerp(target_position, follow_speed * delta)
	
	# Smooth camera rotation
	if smooth_rotation:
		var current_transform = global_transform
		var target_transform = current_transform.looking_at(target_look_at, Vector3.UP)
		global_transform = current_transform.interpolate_with(target_transform, rotation_speed * delta)
	else:
		look_at(target_look_at, Vector3.UP)

func _update_transition(delta: float) -> void:
	"""Update camera during mode transitions"""
	# Smooth transition to target position
	global_position = global_position.lerp(target_position, transition_speed * delta)
	
	# Smooth rotation transition
	var current_transform = global_transform
	var target_transform = current_transform.looking_at(target_look_at, Vector3.UP)
	global_transform = current_transform.interpolate_with(target_transform, transition_speed * delta)
	
	# Check if transition is complete
	var position_distance = global_position.distance_to(target_position)
	if position_distance < 0.1:
		# Transition complete
		if target_position.is_equal_approx(launch_position):
			current_mode = CameraMode.LAUNCH_VIEW
		else:
			current_mode = CameraMode.FLIGHT_TRACKING
		
		camera_mode_changed.emit(current_mode)
		print("Camera transition complete to mode: ", current_mode)

func _calculate_flight_tracking_position() -> void:
	"""Calculate the desired camera position for flight tracking"""
	if not target_airplane:
		return
	
	var airplane_pos = target_airplane.global_position
	var airplane_velocity = target_airplane.linear_velocity
	
	# Calculate position behind and above the airplane
	var airplane_forward = -target_airplane.global_transform.basis.z
	if airplane_velocity.length() > 1.0:
		# Use velocity direction if airplane is moving fast enough
		airplane_forward = airplane_velocity.normalized()
	
	# Use touch-controlled zoom distance instead of fixed distance
	var effective_distance = current_zoom_distance if touch_enabled else distance_behind
	
	# Position camera behind and above airplane
	var camera_offset = -airplane_forward * effective_distance + Vector3.UP * height_offset
	base_camera_position = airplane_pos + camera_offset
	
	# Apply touch pan offset
	target_position = base_camera_position + pan_offset
	
	# Look ahead of the airplane (also affected by pan offset for more natural feel)
	var look_ahead_pos = airplane_pos + airplane_forward * look_ahead_distance
	target_look_at = look_ahead_pos + pan_offset * 0.3  # Reduced pan effect on look target

func _update_distance_measurement() -> void:
	"""Update distance measurement from launch point"""
	if not target_airplane:
		return
	
	# Calculate current distance from launch point
	current_distance_from_launch = target_airplane.global_position.distance_to(launch_point)
	
	# Update maximum distance
	if current_distance_from_launch > max_distance_from_launch:
		max_distance_from_launch = current_distance_from_launch
	
	# Emit distance update signal
	distance_updated.emit(current_distance_from_launch, max_distance_from_launch)

func get_flight_distance_data() -> Dictionary:
	"""Get current flight distance information"""
	return {
		"current_distance": current_distance_from_launch,
		"max_distance": max_distance_from_launch,
		"launch_point": launch_point,
		"airplane_position": target_airplane.global_position if target_airplane else Vector3.ZERO
	}

func reset_distance_tracking() -> void:
	"""Reset distance tracking for new flight"""
	max_distance_from_launch = 0.0
	current_distance_from_launch = 0.0
	if target_airplane:
		launch_point = target_airplane.global_position
		flight_start_position = target_airplane.global_position

# Camera control methods for external use
func set_follow_speed(speed: float) -> void:
	"""Set camera follow speed"""
	follow_speed = max(0.1, speed)

func set_camera_distance(distance: float) -> void:
	"""Set camera distance behind airplane"""
	distance_behind = max(1.0, distance)

func set_camera_height(height: float) -> void:
	"""Set camera height above airplane"""
	height_offset = max(0.5, height)

# Touch control methods
func _connect_mobile_input() -> void:
	"""Connect to MobileInputManager for touch controls"""
	if MobileInputManager:
		MobileInputManager.pan_gesture.connect(_on_pan_gesture)
		MobileInputManager.pinch_gesture.connect(_on_pinch_gesture)
		MobileInputManager.touch_started.connect(_on_touch_started)
		MobileInputManager.touch_ended.connect(_on_touch_ended)
		
		# Set this camera as the reference for 3D conversions
		MobileInputManager.set_camera(self)
		print("FlightCamera connected to MobileInputManager")

func _update_touch_controls(delta: float) -> void:
	"""Update smooth touch control responses"""
	if smooth_touch_response:
		# Smooth pan offset
		pan_offset = pan_offset.lerp(target_pan_offset, touch_response_speed * delta)
		
		# Smooth zoom distance
		current_zoom_distance = lerp(current_zoom_distance, target_zoom_distance, touch_response_speed * delta)
	else:
		pan_offset = target_pan_offset
		current_zoom_distance = target_zoom_distance

func _on_pan_gesture(delta: Vector2, center: Vector2) -> void:
	"""Handle pan gesture for camera movement"""
	if not touch_enabled or current_mode == CameraMode.TRANSITIONING:
		return
	
	# Don't pan during launcher interaction
	if MobileInputManager.is_launcher_interaction_active():
		return
	
	# Convert screen delta to world space movement
	var camera_right = global_transform.basis.x
	var camera_up = global_transform.basis.y
	
	# Apply pan sensitivity
	var pan_delta = (-camera_right * delta.x + camera_up * delta.y) * touch_pan_sensitivity
	
	# Add to target pan offset with bounds checking
	target_pan_offset += pan_delta
	target_pan_offset = _clamp_pan_offset(target_pan_offset)

func _on_pinch_gesture(distance: float, center: Vector2, delta_distance: float) -> void:
	"""Handle pinch gesture for camera zoom"""
	if not touch_enabled or current_mode == CameraMode.TRANSITIONING:
		return
	
	# Don't zoom during launcher interaction
	if MobileInputManager.is_launcher_interaction_active():
		return
	
	# Calculate zoom change based on pinch
	var zoom_delta = -delta_distance * pinch_zoom_sensitivity
	target_zoom_distance += zoom_delta
	
	# Clamp zoom distance
	target_zoom_distance = clamp(target_zoom_distance, min_zoom_distance, max_zoom_distance)

func _on_touch_started(position: Vector2, index: int) -> void:
	"""Handle touch start for camera controls"""
	if not touch_enabled:
		return
	
	# Reset pan state when new touch starts
	if index == 0:
		is_panning = false
		is_zooming = false

func _on_touch_ended(position: Vector2, index: int) -> void:
	"""Handle touch end for camera controls"""
	if not touch_enabled:
		return
	
	# Reset interaction states when touches end
	if MobileInputManager.get_touch_count() == 0:
		is_panning = false
		is_zooming = false

func _clamp_pan_offset(offset: Vector3) -> Vector3:
	"""Clamp pan offset to bounds"""
	var max_offset = pan_bounds_size
	return Vector3(
		clamp(offset.x, -max_offset, max_offset),
		clamp(offset.y, -max_offset, max_offset),
		clamp(offset.z, -max_offset, max_offset)
	)

func reset_camera_position() -> void:
	"""Reset camera to default position (remove pan/zoom)"""
	target_pan_offset = Vector3.ZERO
	target_zoom_distance = distance_behind
	
	if not smooth_touch_response:
		pan_offset = Vector3.ZERO
		current_zoom_distance = distance_behind

func set_touch_enabled(enabled: bool) -> void:
	"""Enable or disable touch controls"""
	touch_enabled = enabled
	if not enabled:
		reset_camera_position()

func is_touch_enabled() -> bool:
	"""Check if touch controls are enabled"""
	return touch_enabled

# Enhanced camera control methods
func set_zoom_bounds(min_distance: float, max_distance: float) -> void:
	"""Set zoom distance bounds"""
	min_zoom_distance = max(0.5, min_distance)
	max_zoom_distance = max(min_zoom_distance + 1.0, max_distance)
	
	# Clamp current zoom to new bounds
	target_zoom_distance = clamp(target_zoom_distance, min_zoom_distance, max_zoom_distance)

func set_pan_bounds(bounds_size: float) -> void:
	"""Set pan bounds size"""
	pan_bounds_size = max(1.0, bounds_size)
	target_pan_offset = _clamp_pan_offset(target_pan_offset)

func get_touch_control_info() -> Dictionary:
	"""Get touch control information for debugging"""
	return {
		"touch_enabled": touch_enabled,
		"is_panning": is_panning,
		"is_zooming": is_zooming,
		"pan_offset": pan_offset,
		"target_pan_offset": target_pan_offset,
		"current_zoom_distance": current_zoom_distance,
		"target_zoom_distance": target_zoom_distance,
		"zoom_bounds": [min_zoom_distance, max_zoom_distance],
		"pan_bounds": pan_bounds_size
	}

# Debug information
func get_camera_info() -> Dictionary:
	"""Get camera information for debugging"""
	return {
		"mode": current_mode,
		"position": global_position,
		"target_position": target_position,
		"target_look_at": target_look_at,
		"has_airplane": target_airplane != null,
		"distance_from_launch": current_distance_from_launch,
		"max_distance": max_distance_from_launch,
		"touch_controls": get_touch_control_info()
	}