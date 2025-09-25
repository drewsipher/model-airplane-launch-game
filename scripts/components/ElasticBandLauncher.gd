class_name ElasticBandLauncher
extends Node3D

## Elastic band launcher for model airplanes
## Provides visual feedback and physics-based launching

@export_group("Launcher Properties")
@export var max_pull_distance: float = 3.0  # Maximum pull-back distance
@export var launch_force_multiplier: float = 5.0  # Force multiplier for launch velocity
@export var band_tension_curve: Curve  # Curve for non-linear tension

@export_group("Visual Components")
@export var launcher_base: MeshInstance3D
@export var elastic_band: MeshInstance3D
@export var airplane_attachment_point: Node3D

# Auto-found child nodes (fallback if exports not set)
@onready var _launcher_base: MeshInstance3D = $LauncherBase
@onready var _elastic_band: MeshInstance3D = $ElasticBand  
@onready var _airplane_attachment_point: Node3D = $AirplaneAttachmentPoint

# Internal state
var is_pulling: bool = false
var current_pull_distance: float = 0.0
var airplane = null
var launch_position: Vector3
var pull_direction: Vector3 = Vector3.BACK  # Default pull direction

# Visual feedback
var original_band_scale: Vector3
var original_band_position: Vector3
var original_airplane_position: Vector3
var is_band_snapping: bool = false

signal airplane_launched(velocity: Vector3)
signal pull_started()
signal pull_updated(distance: float, force: float)
signal pull_released()

func _ready() -> void:
	# Set up launcher position and orientation
	launch_position = global_position
	
	# Use auto-found nodes if export variables aren't set
	if not launcher_base and _launcher_base:
		launcher_base = _launcher_base
	if not elastic_band and _elastic_band:
		elastic_band = _elastic_band
	if not airplane_attachment_point and _airplane_attachment_point:
		airplane_attachment_point = _airplane_attachment_point
	
	print("ElasticBandLauncher: Found nodes:")
	print("  launcher_base: ", launcher_base != null)
	print("  elastic_band: ", elastic_band != null)
	print("  airplane_attachment_point: ", airplane_attachment_point != null)
	
	# Store original visual states
	if elastic_band:
		original_band_scale = elastic_band.scale
		original_band_position = elastic_band.position
		print("ElasticBandLauncher: Stored original band scale: ", original_band_scale)
		print("ElasticBandLauncher: Stored original band position: ", original_band_position)
	else:
		print("ElasticBandLauncher: ERROR - No elastic band found!")
	
	# Create default tension curve if not set
	if not band_tension_curve:
		band_tension_curve = Curve.new()
		band_tension_curve.add_point(Vector2(0.0, 0.0))  # No tension at start
		band_tension_curve.add_point(Vector2(0.5, 0.7))  # Moderate tension at half pull
		band_tension_curve.add_point(Vector2(1.0, 1.0))  # Maximum tension at full pull
	
	# Connect to MobileInputManager signals for touch-based controls
	_connect_mobile_input()
	
	print("ElasticBandLauncher ready at position: ", launch_position)

func _connect_mobile_input() -> void:
	"""Connect to MobileInputManager for touch-based launcher controls"""
	if MobileInputManager:
		MobileInputManager.launcher_pull_started.connect(_on_touch_pull_started)
		MobileInputManager.launcher_pull_updated.connect(_on_touch_pull_updated)
		MobileInputManager.launcher_pull_released.connect(_on_touch_pull_released)
		print("Connected to MobileInputManager for touch controls")

func attach_airplane(airplane_node) -> void:
	"""Attach an airplane to the launcher"""
	if airplane:
		detach_airplane()
	
	airplane = airplane_node
	if airplane and airplane_attachment_point:
		# Position airplane at attachment point
		airplane.global_position = airplane_attachment_point.global_position
		airplane.freeze = true  # Prevent physics while attached
		original_airplane_position = airplane.global_position
		
		print("Airplane attached to launcher")

func detach_airplane() -> void:
	"""Detach airplane from launcher"""
	if airplane:
		airplane.freeze = false
		airplane = null
		print("Airplane detached from launcher")

func start_pull(pull_input_position: Vector3 = Vector3.ZERO) -> void:
	"""Start pulling the elastic band - bow/ballista style"""
	if not airplane:
		print("No airplane attached to launcher")
		return
	
	is_pulling = true
	current_pull_distance = 0.0
	
	# Store initial airplane position for reference
	if airplane_attachment_point:
		original_airplane_position = airplane_attachment_point.global_position
	
	pull_started.emit()
	print("Started bow-style pull - grab airplane and pull back!")

func update_pull(pull_input_position: Vector3) -> void:
	"""Update pull distance based on input position - bow/ballista style"""
	if not is_pulling or not airplane:
		return
	
	# Calculate pull vector from launch position to input position
	var pull_vector = pull_input_position - launch_position
	
	# Use a consistent backwards direction - use the launcher base's orientation if available
	var launch_backwards: Vector3
	if launcher_base:
		# Use the launcher base's backwards direction (it's angled upward)
		launch_backwards = launcher_base.global_transform.basis.z
	else:
		# Fallback to launcher's backwards direction
		launch_backwards = global_transform.basis.z
	
	# Calculate how far back we're pulling along the launcher's backwards direction
	var pull_distance_raw = pull_vector.dot(launch_backwards)
	
	# Clamp between 0 and max_pull_distance - no pulling forward, no going over 100%
	current_pull_distance = clamp(pull_distance_raw, 0.0, max_pull_distance)
	
	# Calculate normalized pull (0.0 to 1.0)
	var pull_normalized = current_pull_distance / max_pull_distance
	
	# Calculate tension using curve
	var tension = band_tension_curve.sample(pull_normalized) if band_tension_curve else pull_normalized
	
	# Update visual feedback
	_update_visual_feedback(pull_normalized, tension, launch_backwards)
	
	# Calculate launch force for feedback
	var launch_force = tension * launch_force_multiplier
	
	# Emit update signal
	pull_updated.emit(current_pull_distance, launch_force)
	
	# Debug output
	if pull_normalized > 0.1:
		print("Pulling back: %.1f%% (%.2fm)" % [pull_normalized * 100.0, current_pull_distance])
	

func release_pull() -> void:
	"""Release the elastic band and launch the airplane"""
	if not is_pulling or not airplane:
		return
	
	is_pulling = false
	
	# Calculate launch velocity based on pull distance
	var pull_normalized = current_pull_distance / max_pull_distance
	var tension = band_tension_curve.sample(pull_normalized) if band_tension_curve else pull_normalized
	var launch_speed = tension * launch_force_multiplier
	
	# Launch direction - use launcher base's forward direction (matches the ramp angle)
	var launch_direction: Vector3
	if launcher_base:
		# Use the launcher base's forward direction (angled upward like a ramp)
		launch_direction = -launcher_base.global_transform.basis.z
	else:
		# Fallback to launcher's forward direction
		launch_direction = -global_transform.basis.z
	
	var launch_velocity = launch_direction * launch_speed
	
	# Start elastic band snap animation
	_animate_band_snap()
	
	# Launch the airplane
	if airplane:
		var airplane_to_launch = airplane  # Store reference before detaching
		detach_airplane()
		airplane_to_launch.launch_airplane(launch_velocity)
		airplane_launched.emit(launch_velocity)
	
	pull_released.emit()
	print("Airplane launched with velocity: ", launch_velocity)

func cancel_pull() -> void:
	"""Cancel the current pull without launching"""
	if not is_pulling:
		return
	
	is_pulling = false
	current_pull_distance = 0.0
	
	# Reset visual feedback
	_reset_visual_feedback()
	
	print("Pull cancelled")

func _update_visual_feedback(pull_normalized: float, tension: float, pull_direction: Vector3 = Vector3.BACK) -> void:
	"""Update visual elements to show pull state - ballista style"""
	
	if is_band_snapping:
		return  # Don't update during snap animation
	
	# Move elastic band backwards with the pull (like a ballista string)
	if elastic_band and original_band_position != Vector3.ZERO:
		# Use the passed pull_direction (which is now the launcher base's direction)
		var band_pull_offset = pull_direction * current_pull_distance * 0.8  # Band moves 80% of pull distance
		elastic_band.position = original_band_position + band_pull_offset
		
		# Stretch the band to show tension, more stretch near the limit
		var stretch_factor = 1.0 + (pull_normalized * 0.5)  # Stretch up to 50% more
		
		# Add extra stretch and visual stress near the limit
		if pull_normalized > 0.8:
			stretch_factor += (pull_normalized - 0.8) * 0.5  # Extra stretch when near limit
		
		elastic_band.scale = original_band_scale * Vector3(stretch_factor, 1.0, 1.0)
		
		# Change band color based on tension
		_update_band_tension_color(pull_normalized)
	
	# Move airplane back based on pull (like drawing an arrow)
	if airplane and airplane_attachment_point:
		# Use the passed pull_direction (which matches the launcher's angle)
		var pull_offset = pull_direction * current_pull_distance
		airplane.global_position = original_airplane_position + pull_offset
		
		# Rotate airplane slightly to show tension
		if pull_normalized > 0.2:
			var tilt_angle = pull_normalized * 5.0  # Up to 5 degrees tilt
			airplane.rotation_degrees.x = tilt_angle

func _reset_visual_feedback() -> void:
	"""Reset all visual feedback to default state"""
	
	if is_band_snapping:
		return  # Don't reset during snap animation
	
	# Reset elastic band position and scale
	if elastic_band:
		if original_band_scale != Vector3.ZERO:
			elastic_band.scale = original_band_scale
		if original_band_position != Vector3.ZERO:
			elastic_band.position = original_band_position
	
	# Reset airplane rotation
	if airplane:
		airplane.rotation_degrees.x = 0.0
	
	current_pull_distance = 0.0

func get_launch_info() -> Dictionary:
	"""Get current launch information for UI display"""
	var pull_normalized = current_pull_distance / max_pull_distance if max_pull_distance > 0 else 0.0
	var tension = band_tension_curve.sample(pull_normalized) if band_tension_curve else pull_normalized
	var estimated_launch_speed = tension * launch_force_multiplier
	
	return {
		"is_pulling": is_pulling,
		"pull_distance": current_pull_distance,
		"max_pull_distance": max_pull_distance,
		"pull_percentage": pull_normalized * 100.0,
		"tension": tension,
		"estimated_launch_speed": estimated_launch_speed,
		"has_airplane": airplane != null
	}

# Touch input handlers
func _on_touch_pull_started(position: Vector2) -> void:
	"""Handle touch-based pull start - bow/ballista style"""
	if not airplane:
		print("No airplane attached - cannot start pull")
		return
	
	# Check if touch is near airplane (not launcher base)
	var airplane_screen_pos = _get_airplane_screen_position()
	var touch_distance = position.distance_to(airplane_screen_pos)
	
	# Only start pull if touch is on or near the airplane
	if touch_distance < 100.0:  # 100 pixels threshold for airplane
		print("ElasticBandLauncher: Starting bow-style pull on airplane")
		start_pull()
	else:
		print("ElasticBandLauncher: Touch not near airplane - distance: %.1f pixels" % touch_distance)

func _on_touch_pull_updated(position: Vector2, pull_distance_screen: float) -> void:
	"""Handle touch-based pull update - bow/ballista style"""
	if not is_pulling:
		return
	
	# Convert screen position to 3D world position
	var world_pos = MobileInputManager.convert_touch_to_3d_position(position)
	
	# Calculate pull direction from launcher base to touch position
	var pull_vector = world_pos - launch_position
	var pull_direction_normalized = pull_vector.normalized()
	
	# Only allow pulling backwards (away from launch direction)
	var launch_forward = -global_transform.basis.z
	var dot_product = pull_direction_normalized.dot(-launch_forward)
	
	if dot_product > 0.1:  # Allow some angle tolerance
		update_pull(world_pos)
	else:
		# Constrain to valid pull direction
		var constrained_direction = -launch_forward
		var constrained_pos = launch_position + constrained_direction * pull_vector.length()
		update_pull(constrained_pos)

func _on_touch_pull_released(position: Vector2, pull_distance_screen: float) -> void:
	"""Handle touch-based pull release"""
	if not is_pulling:
		return
	
	release_pull()

func _get_launcher_screen_position() -> Vector2:
	"""Get launcher position in screen coordinates"""
	var camera = get_viewport().get_camera_3d()
	if camera:
		return camera.unproject_position(global_position)
	return Vector2.ZERO

func _get_airplane_screen_position() -> Vector2:
	"""Get airplane position in screen coordinates"""
	var camera = get_viewport().get_camera_3d()
	if camera and airplane:
		return camera.unproject_position(airplane.global_position)
	return Vector2.ZERO

func is_touch_near_launcher(touch_position: Vector2, threshold: float = 100.0) -> bool:
	"""Check if touch position is near the launcher"""
	var launcher_screen_pos = _get_launcher_screen_position()
	return touch_position.distance_to(launcher_screen_pos) < threshold

func is_touch_near_airplane(touch_position: Vector2, threshold: float = 80.0) -> bool:
	"""Check if touch position is near the airplane"""
	var airplane_screen_pos = _get_airplane_screen_position()
	return touch_position.distance_to(airplane_screen_pos) < threshold

func _animate_band_snap() -> void:
	"""Animate the elastic band snapping forward after release"""
	if not elastic_band:
		return
	
	is_band_snapping = true
	
	# Store current pulled-back position
	var start_position = elastic_band.position
	var start_scale = elastic_band.scale
	
	# Create a tween for smooth animation
	var tween = create_tween()
	tween.set_parallel(true)  # Allow multiple properties to animate simultaneously
	
	# Animate band snapping forward (overshoot then settle)
	var overshoot_position = original_band_position + (original_band_position - start_position) * 0.2
	
	# First phase: snap forward with overshoot (fast)
	tween.tween_property(elastic_band, "position", overshoot_position, 0.1)
	tween.tween_property(elastic_band, "scale", original_band_scale * Vector3(0.8, 1.0, 1.0), 0.1)
	
	# Second phase: settle back to original position (slower)
	tween.tween_property(elastic_band, "position", original_band_position, 0.15).set_delay(0.1)
	tween.tween_property(elastic_band, "scale", original_band_scale, 0.15).set_delay(0.1)
	
	# Reset snapping flag when animation completes
	tween.tween_callback(_on_band_snap_complete).set_delay(0.25)

func _on_band_snap_complete() -> void:
	"""Called when the band snap animation completes"""
	is_band_snapping = false
	current_pull_distance = 0.0
	
	# Reset band color
	_update_band_tension_color(0.0)
	
	print("Band snap animation complete")

func _update_band_tension_color(tension_normalized: float) -> void:
	"""Update the elastic band color based on tension"""
	if not elastic_band:
		return
	
	# Get or create material
	var material = elastic_band.material_override
	if not material:
		material = StandardMaterial3D.new()
		elastic_band.material_override = material
	
	# Color progression: Gray -> Yellow -> Orange -> Red
	var base_color = Color.GRAY
	if tension_normalized < 0.3:
		# Gray to yellow
		base_color = Color.GRAY.lerp(Color.YELLOW, tension_normalized / 0.3)
	elif tension_normalized < 0.7:
		# Yellow to orange
		base_color = Color.YELLOW.lerp(Color.ORANGE, (tension_normalized - 0.3) / 0.4)
	else:
		# Orange to red
		base_color = Color.ORANGE.lerp(Color.RED, (tension_normalized - 0.7) / 0.3)
	
	# Add slight emission for dramatic effect at high tension
	var emission_strength = max(0.0, tension_normalized - 0.5) * 0.3
	
	material.albedo_color = base_color
	material.emission = base_color * emission_strength

# Debug visualization
func _draw_debug_info() -> void:
	"""Draw debug information (for development)"""
	if not is_pulling:
		return
	
	# This would be implemented with debug drawing if needed
	pass
