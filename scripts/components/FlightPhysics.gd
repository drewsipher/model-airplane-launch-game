class_name FlightPhysics
extends Node

## Flight physics system for calculating aerodynamic forces
## Handles lift, drag, and gravity calculations for airplane flight simulation

# Physics constants
const AIR_DENSITY: float = 1.225  # kg/m³ at sea level
const GRAVITY_ACCELERATION: float = 9.81  # m/s²

# Aerodynamic calculation data
class AerodynamicData:
	var lift_force: Vector3 = Vector3.ZERO
	var drag_force: Vector3 = Vector3.ZERO
	var total_force: Vector3 = Vector3.ZERO
	var angle_of_attack: float = 0.0
	var airspeed: float = 0.0

func calculate_lift(airplane: RigidBody3D, velocity: Vector3, lift_coefficient: float) -> Vector3:
	"""Calculate lift force based on airplane orientation and velocity"""
	
	# Only calculate lift if airplane is moving with reasonable speed
	if velocity.length() < 1.0:
		return Vector3.ZERO
	
	# Get airplane's orientation vectors
	var forward_direction = -airplane.global_transform.basis.z  # Forward (negative Z)
	var up_direction = airplane.global_transform.basis.y        # Up (Y axis)
	var right_direction = airplane.global_transform.basis.x     # Right (X axis)
	
	# Calculate forward velocity component (airspeed)
	var forward_velocity = velocity.dot(forward_direction)
	
	# Only generate lift when moving forward
	if forward_velocity <= 0:
		return Vector3.ZERO
	
	# Calculate angle of attack (simplified)
	var velocity_normalized = velocity.normalized()
	var angle_of_attack = acos(velocity_normalized.dot(forward_direction))
	
	# Adjust lift based on angle of attack (basic stall model)
	var lift_efficiency = 1.0
	if angle_of_attack > deg_to_rad(15):  # Stall angle
		lift_efficiency = max(0.1, 1.0 - (angle_of_attack - deg_to_rad(15)) / deg_to_rad(30))
	
	# Calculate lift magnitude: F = 0.5 * ρ * v² * Cl * A
	var velocity_squared = forward_velocity * forward_velocity
	var lift_magnitude = 0.5 * AIR_DENSITY * velocity_squared * lift_coefficient * lift_efficiency
	
	# Apply lift perpendicular to velocity and in the airplane's up direction
	var lift_direction = up_direction
	
	# Adjust lift direction based on bank angle for realistic turning
	var bank_angle = asin(clamp(right_direction.dot(Vector3.UP), -1.0, 1.0))
	if abs(bank_angle) > deg_to_rad(5):  # Only apply banking effects for significant bank angles
		var bank_factor = sin(bank_angle)
		lift_direction = lift_direction.rotated(forward_direction, bank_angle * 0.5)
	
	return lift_direction * lift_magnitude

func calculate_drag(airplane: RigidBody3D, velocity: Vector3, drag_coefficient: float) -> Vector3:
	"""Calculate drag force opposing airplane motion"""
	
	if velocity.length() < 0.1:
		return Vector3.ZERO
	
	# Calculate drag magnitude: F = 0.5 * ρ * v² * Cd * A
	var velocity_squared = velocity.length_squared()
	var drag_magnitude = 0.5 * AIR_DENSITY * velocity_squared * drag_coefficient
	
	# Apply drag opposite to velocity direction
	var drag_force = -velocity.normalized() * drag_magnitude
	
	return drag_force

func apply_aerodynamic_forces(airplane: RigidBody3D, state: PhysicsDirectBodyState3D, 
							 lift_coefficient: float, drag_coefficient: float) -> AerodynamicData:
	"""Apply all aerodynamic forces to the airplane and return calculation data"""
	
	var velocity = state.linear_velocity
	var aerodynamic_data = AerodynamicData.new()
	
	# Calculate individual forces
	aerodynamic_data.lift_force = calculate_lift(airplane, velocity, lift_coefficient)
	aerodynamic_data.drag_force = calculate_drag(airplane, velocity, drag_coefficient)
	
	# Store flight data
	aerodynamic_data.airspeed = velocity.length()
	aerodynamic_data.angle_of_attack = _calculate_angle_of_attack(airplane, velocity)
	
	# Apply forces to the physics body
	if aerodynamic_data.lift_force.length() > 0:
		state.apply_central_force(aerodynamic_data.lift_force)
	
	if aerodynamic_data.drag_force.length() > 0:
		state.apply_central_force(aerodynamic_data.drag_force)
	
	# Calculate total aerodynamic force
	aerodynamic_data.total_force = aerodynamic_data.lift_force + aerodynamic_data.drag_force
	
	return aerodynamic_data

func check_stall_conditions(airplane: RigidBody3D, velocity: Vector3) -> bool:
	"""Check if the airplane is in a stall condition"""
	
	# Check airspeed stall
	var min_flying_speed = 3.0  # Minimum speed to maintain flight
	if velocity.length() < min_flying_speed:
		return true
	
	# Check angle of attack stall
	var angle_of_attack = _calculate_angle_of_attack(airplane, velocity)
	var stall_angle = deg_to_rad(20)  # Critical angle of attack
	
	if angle_of_attack > stall_angle:
		return true
	
	return false

func apply_gravity_force(state: PhysicsDirectBodyState3D, mass: float) -> Vector3:
	"""Apply gravity force to the airplane"""
	var gravity_force = Vector3(0, -GRAVITY_ACCELERATION * mass, 0)
	state.apply_central_force(gravity_force)
	return gravity_force

func simulate_tumbling_behavior(airplane: RigidBody3D, state: PhysicsDirectBodyState3D, 
							   is_unbalanced: bool = false) -> void:
	"""Simulate tumbling behavior for unbalanced or stalled airplanes"""
	
	if not is_unbalanced and not check_stall_conditions(airplane, state.linear_velocity):
		return
	
	# Apply random torque to simulate tumbling
	var tumble_strength = 2.0
	if is_unbalanced:
		tumble_strength *= 1.5
	
	var random_torque = Vector3(
		randf_range(-tumble_strength, tumble_strength),
		randf_range(-tumble_strength, tumble_strength),
		randf_range(-tumble_strength, tumble_strength)
	)
	
	state.apply_torque(random_torque)

func _calculate_angle_of_attack(airplane: RigidBody3D, velocity: Vector3) -> float:
	"""Calculate the angle of attack between airplane forward direction and velocity"""
	
	if velocity.length() < 0.1:
		return 0.0
	
	var forward_direction = -airplane.global_transform.basis.z
	var velocity_normalized = velocity.normalized()
	
	# Calculate angle between forward direction and velocity
	var dot_product = clamp(forward_direction.dot(velocity_normalized), -1.0, 1.0)
	return acos(dot_product)

# Debug and utility functions
func get_aerodynamic_info(airplane: RigidBody3D, velocity: Vector3, 
						 lift_coefficient: float, drag_coefficient: float) -> Dictionary:
	"""Get detailed aerodynamic information for debugging"""
	
	var lift_force = calculate_lift(airplane, velocity, lift_coefficient)
	var drag_force = calculate_drag(airplane, velocity, drag_coefficient)
	var angle_of_attack = _calculate_angle_of_attack(airplane, velocity)
	var is_stalled = check_stall_conditions(airplane, velocity)
	
	return {
		"airspeed": velocity.length(),
		"angle_of_attack_deg": rad_to_deg(angle_of_attack),
		"lift_force": lift_force,
		"drag_force": drag_force,
		"lift_magnitude": lift_force.length(),
		"drag_magnitude": drag_force.length(),
		"is_stalled": is_stalled,
		"forward_velocity": velocity.dot(-airplane.global_transform.basis.z)
	}