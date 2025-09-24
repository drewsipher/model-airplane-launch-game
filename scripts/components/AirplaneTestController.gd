extends Node3D

## Test controller for BasicAirplane functionality
## Press SPACE to launch the airplane for testing

@onready var airplane: BasicAirplane = $BasicAirplane

func _ready() -> void:
	print("Airplane Test Controller ready")
	print("Press SPACE to launch airplane")
	print("Airplane details: ", airplane)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # SPACE key
		launch_test_airplane()

func launch_test_airplane() -> void:
	"""Launch airplane with test velocity"""
	var launch_velocity = Vector3(0, 5, 15)  # Forward and upward velocity
	airplane.launch_airplane(launch_velocity)
	print("Test launch executed with velocity: ", launch_velocity)

func _process(_delta: float) -> void:
	# Display flight data in real-time
	if airplane.is_flying:
		var flight_data = airplane.get_flight_data()
		print("Speed: %.1f m/s, Altitude: %.1f m" % [flight_data.speed, flight_data.altitude])