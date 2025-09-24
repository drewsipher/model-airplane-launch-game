class_name BasicAirplane
extends RigidBody3D

## Basic airplane physics body with weight and drag properties
## Implements simple flight physics for initial testing

@export_group("Physics Properties")
@export var airplane_weight: float = 50.0  # Weight in grams
@export var drag_coefficient: float = 0.02  # Basic drag coefficient
@export var lift_coefficient: float = 0.1   # Basic lift coefficient

@export_group("Visual Components")
@export var fuselage_mesh: MeshInstance3D
@export var wing_left_mesh: MeshInstance3D
@export var wing_right_mesh: MeshInstance3D

# Internal references to scene components
@onready var fuselage_mesh_node: MeshInstance3D = $FuselageMesh
@onready var wing_left_mesh_node: MeshInstance3D = $WingLeftMesh
@onready var wing_right_mesh_node: MeshInstance3D = $WingRightMesh

# Physics constants
const GRAVITY_SCALE: float = 1.0
const AIR_DENSITY: float = 1.225  # kg/m³ at sea level

# Flight state tracking
var flight_velocity: Vector3 = Vector3.ZERO
var is_flying: bool = false

func _ready() -> void:
	# Set up physics properties
	mass = airplane_weight / 1000.0  # Convert grams to kg
	gravity_scale = GRAVITY_SCALE
	
	# Enable physics processing
	set_gravity_scale(GRAVITY_SCALE)
	
	# Set up mesh references if not assigned in editor
	if not fuselage_mesh and has_node("FuselageMesh"):
		fuselage_mesh = fuselage_mesh_node
	if not wing_left_mesh and has_node("WingLeftMesh"):
		wing_left_mesh = wing_left_mesh_node
	if not wing_right_mesh and has_node("WingRightMesh"):
		wing_right_mesh = wing_right_mesh_node
	
	# Connect signals for flight tracking
	body_entered.connect(_on_collision_detected)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not is_flying:
		return
	
	# Get current velocity
	flight_velocity = state.linear_velocity
	
	# Apply aerodynamic forces
	_apply_drag_force(state)
	_apply_basic_lift_force(state)

func _apply_drag_force(state: PhysicsDirectBodyState3D) -> void:
	"""Apply drag force opposing motion"""
	if flight_velocity.length() < 0.1:
		return
	
	# Calculate drag force: F = 0.5 * ρ * v² * Cd * A
	var velocity_squared = flight_velocity.length_squared()
	var drag_magnitude = 0.5 * AIR_DENSITY * velocity_squared * drag_coefficient
	
	# Apply drag opposite to velocity direction
	var drag_force = -flight_velocity.normalized() * drag_magnitude
	state.apply_central_force(drag_force)

func _apply_basic_lift_force(state: PhysicsDirectBodyState3D) -> void:
	"""Apply basic lift force based on forward velocity and orientation"""
	# Only apply lift if moving forward with reasonable speed
	if flight_velocity.length() < 2.0:
		return
	
	# Get airplane's forward direction (negative Z in Godot)
	var forward_direction = -global_transform.basis.z
	
	# Calculate forward velocity component
	var forward_velocity = flight_velocity.dot(forward_direction)
	
	if forward_velocity > 0:
		# Calculate lift force: simplified version based on forward speed
		var lift_magnitude = 0.5 * AIR_DENSITY * forward_velocity * forward_velocity * lift_coefficient
		
		# Apply lift in the up direction relative to the airplane
		var up_direction = global_transform.basis.y
		var lift_force = up_direction * lift_magnitude
		
		state.apply_central_force(lift_force)

func launch_airplane(initial_velocity: Vector3) -> void:
	"""Launch the airplane with given initial velocity"""
	is_flying = true
	linear_velocity = initial_velocity
	
	# Enable physics simulation
	freeze = false
	
	print("Airplane launched with velocity: ", initial_velocity)

func stop_flight() -> void:
	"""Stop flight simulation (for landing/crashing)"""
	is_flying = false
	print("Flight stopped")

func _on_collision_detected(body: Node) -> void:
	"""Handle collision with ground or obstacles"""
	if body.is_in_group("ground") or body.is_in_group("obstacles"):
		stop_flight()

func get_flight_data() -> Dictionary:
	"""Return current flight data for tracking"""
	return {
		"velocity": flight_velocity,
		"speed": flight_velocity.length(),
		"altitude": global_position.y,
		"is_flying": is_flying,
		"weight": airplane_weight,
		"drag_coefficient": drag_coefficient,
		"lift_coefficient": lift_coefficient
	}

# Debug information
func _to_string() -> String:
	return "BasicAirplane(weight=%s, drag=%s, lift=%s, flying=%s)" % [
		airplane_weight, drag_coefficient, lift_coefficient, is_flying
	]