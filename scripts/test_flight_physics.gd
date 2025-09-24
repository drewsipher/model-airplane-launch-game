extends Node

## Simple test script to verify FlightPhysics functionality
## This can be run to test the physics calculations

func _ready():
	test_flight_physics()

func test_flight_physics():
	print("=== FlightPhysics Test ===")
	
	# Create a mock airplane (RigidBody3D)
	var mock_airplane = RigidBody3D.new()
	mock_airplane.mass = 0.05  # 50g airplane
	
	# Create FlightPhysics instance
	var flight_physics = FlightPhysics.new()
	
	# Test lift calculation
	var test_velocity = Vector3(0, 0, 10)  # 10 m/s forward
	var lift_coefficient = 0.1
	var lift_force = flight_physics.calculate_lift(mock_airplane, test_velocity, lift_coefficient)
	
	print("Test Velocity: ", test_velocity)
	print("Calculated Lift Force: ", lift_force)
	print("Lift Magnitude: ", lift_force.length())
	
	# Test drag calculation
	var drag_coefficient = 0.02
	var drag_force = flight_physics.calculate_drag(mock_airplane, test_velocity, drag_coefficient)
	
	print("Calculated Drag Force: ", drag_force)
	print("Drag Magnitude: ", drag_force.length())
	
	# Test stall detection
	var is_stalled = flight_physics.check_stall_conditions(mock_airplane, test_velocity)
	print("Is Stalled at 10 m/s: ", is_stalled)
	
	# Test with low speed (should stall)
	var low_velocity = Vector3(0, 0, 1)  # 1 m/s forward
	var is_stalled_low = flight_physics.check_stall_conditions(mock_airplane, low_velocity)
	print("Is Stalled at 1 m/s: ", is_stalled_low)
	
	# Test aerodynamic info
	var aero_info = flight_physics.get_aerodynamic_info(mock_airplane, test_velocity, lift_coefficient, drag_coefficient)
	print("Aerodynamic Info: ", aero_info)
	
	print("=== Test Complete ===")
	
	# Clean up
	mock_airplane.queue_free()
	flight_physics.queue_free()