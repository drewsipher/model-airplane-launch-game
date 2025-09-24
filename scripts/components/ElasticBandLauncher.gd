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

# Internal state
var is_pulling: bool = false
var current_pull_distance: float = 0.0
var airplane = null
var launch_position: Vector3
var pull_direction: Vector3 = Vector3.BACK  # Default pull direction

# Visual feedback
var original_band_scale: Vector3
var original_airplane_position: Vector3

signal airplane_launched(velocity: Vector3)
signal pull_started()
signal pull_updated(distance: float, force: float)
signal pull_released()

func _ready() -> void:
	# Set up launcher position and orientation
	launch_position = global_position
	
	# Store original visual states
	if elastic_band:
		original_band_scale = elastic_band.scale
	
	# Create default tension curve if not set
	if not band_tension_curve:
		band_tension_curve = Curve.new()
		band_tension_curve.add_point(Vector2(0.0, 0.0))  # No tension at start
		band_tension_curve.add_point(Vector2(0.5, 0.7))  # Moderate tension at half pull
		band_tension_curve.add_point(Vector2(1.0, 1.0))  # Maximum tension at full pull
	
	print("ElasticBandLauncher ready at position: ", launch_position)

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
	"""Start pulling the elastic band"""
	if not airplane:
		print("No airplane attached to launcher")
		return
	
	is_pulling = true
	pull_started.emit()
	print("Started pulling launcher")

func update_pull(pull_input_position: Vector3) -> void:
	"""Update pull distance based on input position"""
	if not is_pulling or not airplane:
		return
	
	# Calculate pull distance from launch position
	var pull_vector = pull_input_position - launch_position
	var pull_distance_raw = pull_vector.length()
	
	# Clamp to maximum pull distance
	current_pull_distance = min(pull_distance_raw, max_pull_distance)
	
	# Calculate normalized pull (0.0 to 1.0)
	var pull_normalized = current_pull_distance / max_pull_distance
	
	# Calculate tension using curve
	var tension = band_tension_curve.sample(pull_normalized) if band_tension_curve else pull_normalized
	
	# Update visual feedback
	_update_visual_feedback(pull_normalized, tension)
	
	# Calculate launch force for feedback
	var launch_force = tension * launch_force_multiplier
	
	# Emit update signal
	pull_updated.emit(current_pull_distance, launch_force)

func release_pull() -> void:
	"""Release the elastic band and launch the airplane"""
	if not is_pulling or not airplane:
		return
	
	is_pulling = false
	
	# Calculate launch velocity based on pull distance
	var pull_normalized = current_pull_distance / max_pull_distance
	var tension = band_tension_curve.sample(pull_normalized) if band_tension_curve else pull_normalized
	var launch_speed = tension * launch_force_multiplier
	
	# Launch direction (forward from launcher)
	var launch_direction = -global_transform.basis.z  # Forward direction
	var launch_velocity = launch_direction * launch_speed
	
	# Add some upward component for realistic launch
	launch_velocity.y += launch_speed * 0.3
	
	# Launch the airplane
	if airplane:
		detach_airplane()
		airplane.launch_airplane(launch_velocity)
		airplane_launched.emit(launch_velocity)
	
	# Reset visual feedback
	_reset_visual_feedback()
	
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

func _update_visual_feedback(pull_normalized: float, tension: float) -> void:
	"""Update visual elements to show pull state"""
	
	# Stretch elastic band visual
	if elastic_band and original_band_scale != Vector3.ZERO:
		var stretch_factor = 1.0 + (pull_normalized * 0.5)  # Stretch up to 50% more
		elastic_band.scale = original_band_scale * Vector3(stretch_factor, 1.0, 1.0)
	
	# Move airplane back based on pull
	if airplane and airplane_attachment_point:
		var pull_offset = pull_direction * current_pull_distance
		airplane.global_position = airplane_attachment_point.global_position + pull_offset

func _reset_visual_feedback() -> void:
	"""Reset all visual feedback to default state"""
	
	# Reset elastic band
	if elastic_band and original_band_scale != Vector3.ZERO:
		elastic_band.scale = original_band_scale
	
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

# Debug visualization
func _draw_debug_info() -> void:
	"""Draw debug information (for development)"""
	if not is_pulling:
		return
	
	# This would be implemented with debug drawing if needed
	pass