class_name BasicAirplane
extends RigidBody3D

## Basic airplane physics body with weight and drag properties
## Uses FlightPhysics system for realistic aerodynamic simulation

@export_group("Physics Properties")
@export var airplane_weight: float = 50.0  # Weight in grams
@export var drag_coefficient: float = 0.02  # Basic drag coefficient
@export var lift_coefficient: float = 0.1   # Basic lift coefficient
@export var is_unbalanced: bool = false     # For testing unbalanced flight behavior

@export_group("Visual Components")
@export var fuselage_mesh: MeshInstance3D
@export var wing_left_mesh: MeshInstance3D
@export var wing_right_mesh: MeshInstance3D

# Internal references to scene components
@onready var fuselage_mesh_node: MeshInstance3D = $FuselageMesh
@onready var wing_left_mesh_node: MeshInstance3D = $WingLeftMesh
@onready var wing_right_mesh_node: MeshInstance3D = $WingRightMesh

# Flight physics system
var flight_physics: FlightPhysics

# Flight state tracking
var flight_velocity: Vector3 = Vector3.ZERO
var is_flying: bool = false
var is_stalled: bool = false
var current_aerodynamic_data: FlightPhysics.AerodynamicData

func _ready() -> void:
	# Initialize flight physics system
	flight_physics = FlightPhysics.new()
	add_child(flight_physics)
	
	# Set up physics properties
	mass = airplane_weight / 1000.0  # Convert grams to kg
	gravity_scale = 0.0  # We'll handle gravity through FlightPhysics
	
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
	# Always apply gravity
	flight_physics.apply_gravity_force(state, mass)
	
	if not is_flying:
		return
	
	# Get current velocity
	flight_velocity = state.linear_velocity
	
	# Apply aerodynamic forces using FlightPhysics system
	current_aerodynamic_data = flight_physics.apply_aerodynamic_forces(
		self, state, lift_coefficient, drag_coefficient
	)
	
	# Check for stall conditions
	is_stalled = flight_physics.check_stall_conditions(self, flight_velocity)
	
	# Apply tumbling behavior if airplane is unbalanced or stalled
	if is_unbalanced or is_stalled:
		flight_physics.simulate_tumbling_behavior(self, state, is_unbalanced)
	
	# Update flight state
	_update_flight_state()

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

func _update_flight_state() -> void:
	"""Update flight state based on current conditions"""
	
	# Check if airplane has landed (low altitude and low speed)
	if global_position.y < 1.0 and flight_velocity.length() < 2.0:
		if is_flying:
			stop_flight()

func get_flight_data() -> Dictionary:
	"""Return current flight data for tracking"""
	var base_data = {
		"velocity": flight_velocity,
		"speed": flight_velocity.length(),
		"altitude": global_position.y,
		"is_flying": is_flying,
		"is_stalled": is_stalled,
		"is_unbalanced": is_unbalanced,
		"weight": airplane_weight,
		"drag_coefficient": drag_coefficient,
		"lift_coefficient": lift_coefficient
	}
	
	# Add aerodynamic data if available
	if current_aerodynamic_data:
		base_data.merge({
			"lift_force": current_aerodynamic_data.lift_force,
			"drag_force": current_aerodynamic_data.drag_force,
			"total_aerodynamic_force": current_aerodynamic_data.total_force,
			"angle_of_attack": current_aerodynamic_data.angle_of_attack,
			"airspeed": current_aerodynamic_data.airspeed
		})
	
	return base_data

func get_detailed_aerodynamic_info() -> Dictionary:
	"""Get detailed aerodynamic information for debugging"""
	if not flight_physics:
		return {}
	
	return flight_physics.get_aerodynamic_info(
		self, flight_velocity, lift_coefficient, drag_coefficient
	)

# Debug information
func _to_string() -> String:
	return "BasicAirplane(weight=%s, drag=%s, lift=%s, flying=%s)" % [
		airplane_weight, drag_coefficient, lift_coefficient, is_flying
	]