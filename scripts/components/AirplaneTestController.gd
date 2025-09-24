extends Node3D

## Test controller for BasicAirplane functionality
## Press SPACE to launch the airplane for testing

@onready var airplane: BasicAirplane = $BasicAirplane

func _ready() -> void:
	print("Airplane Test Controller ready")
	print("Press SPACE to launch balanced airplane")
	print("Press ENTER to launch unbalanced airplane (tumbling test)")
	print("Airplane details: ", airplane)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # SPACE key
		launch_test_airplane()
	elif event.is_action_pressed("ui_select"):  # Enter key
		launch_unbalanced_test()

func launch_test_airplane() -> void:
	"""Launch airplane with test velocity"""
	var launch_velocity = Vector3(0, 5, 15)  # Forward and upward velocity
	airplane.is_unbalanced = false  # Reset to balanced
	airplane.launch_airplane(launch_velocity)
	print("Test launch executed with velocity: ", launch_velocity)

func launch_unbalanced_test() -> void:
	"""Launch airplane with unbalanced configuration for testing"""
	var launch_velocity = Vector3(0, 5, 15)  # Forward and upward velocity
	airplane.is_unbalanced = true  # Set to unbalanced for testing
	airplane.launch_airplane(launch_velocity)
	print("Unbalanced test launch executed with velocity: ", launch_velocity)

func _process(_delta: float) -> void:
	# Display flight data in real-time
	if airplane.is_flying:
		var flight_data = airplane.get_flight_data()
		var status_text = "Speed: %.1f m/s, Altitude: %.1f m" % [flight_data.speed, flight_data.altitude]
		
		# Add stall and balance information
		if flight_data.has("is_stalled") and flight_data.is_stalled:
			status_text += " [STALLED]"
		if flight_data.has("is_unbalanced") and flight_data.is_unbalanced:
			status_text += " [UNBALANCED]"
		
		print(status_text)
		
		# Print detailed aerodynamic info every 2 seconds for debugging
		if int(Time.get_time_dict_from_system().second) % 2 == 0:
			var aero_info = airplane.get_detailed_aerodynamic_info()
			if not aero_info.is_empty():
				print("Aerodynamics - AoA: %.1f°, Lift: %.2f N, Drag: %.2f N" % [
					aero_info.get("angle_of_attack_deg", 0),
					aero_info.get("lift_magnitude", 0),
					aero_info.get("drag_magnitude", 0)
				])