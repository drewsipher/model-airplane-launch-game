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

signal camera_mode_changed(new_mode: CameraMode)
signal distance_updated(distance: float, max_distance: float)

func _ready() -> void:
	# Set initial launch view
	set_launch_view()
	print("FlightCamera initialized in launch view")

func _process(delta: float) -> void:
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
	
	# Position camera behind and above airplane
	var camera_offset = -airplane_forward * distance_behind + Vector3.UP * height_offset
	target_position = airplane_pos + camera_offset
	
	# Look ahead of the airplane
	var look_ahead_pos = airplane_pos + airplane_forward * look_ahead_distance
	target_look_at = look_ahead_pos

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
		"max_distance": max_distance_from_launch
	}