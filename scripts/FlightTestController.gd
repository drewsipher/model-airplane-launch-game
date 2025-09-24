extends Node3D

## Flight test controller for visual demonstration of airplane physics
## Allows launching airplanes and observing flight behavior

@onready var launcher = $ElasticBandLauncher
@onready var airplane = $BasicAirplane
@onready var camera: Camera3D = $FlightCamera
@onready var ui_label: Label = $UI/FlightInfo

# Test parameters
var test_scenarios: Array[Dictionary] = [
	{
		"name": "Balanced Flight",
		"unbalanced": false,
		"pull_distance": 2.0,
		"description": "Normal balanced airplane flight"
	},
	{
		"name": "Unbalanced Tumbling",
		"unbalanced": true,
		"pull_distance": 2.0,
		"description": "Unbalanced airplane with tumbling behavior"
	},
	{
		"name": "High Speed Launch",
		"unbalanced": false,
		"pull_distance": 3.0,
		"description": "Maximum pull distance launch"
	},
	{
		"name": "Low Speed Stall",
		"unbalanced": false,
		"pull_distance": 0.8,
		"description": "Low speed launch to demonstrate stall"
	}
]

var current_scenario_index: int = 0
var is_flight_active: bool = false
var flight_start_time: float = 0.0

func _ready() -> void:
	print("=== Flight Test Controller Started ===")
	
	# Set up launcher
	if launcher:
		launcher.airplane_launched.connect(_on_airplane_launched)
		launcher.pull_updated.connect(_on_pull_updated)
	
	# Position camera for good view
	if camera:
		camera.position = Vector3(0, 3, 8)
		camera.look_at(Vector3.ZERO, Vector3.UP)
	
	# Set up airplane
	reset_airplane()
	
	# Update UI
	update_ui_display()
	
	print("Controls:")
	print("SPACE - Launch current scenario")
	print("ENTER - Reset airplane")
	print("← → - Change scenario")
	print("↑ - Toggle unbalanced mode")
	print("ESC or Q - QUIT")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # SPACE
		launch_current_scenario()
	elif event.is_action_pressed("ui_cancel"):  # ESC
		print("Quitting flight test...")
		get_tree().quit()
	elif event.is_action_pressed("ui_select"):  # ENTER
		reset_airplane()
	elif event.is_action_pressed("ui_right"):  # RIGHT ARROW
		next_scenario()
	elif event.is_action_pressed("ui_left"):  # LEFT ARROW
		previous_scenario()
	elif event.is_action_pressed("ui_up"):  # UP ARROW
		toggle_unbalanced_mode()
	
	# Also handle raw key events as backup
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			print("ESC key detected - quitting...")
			get_tree().quit()
		elif event.keycode == KEY_Q:
			print("Q key detected - quitting...")
			get_tree().quit()

func launch_current_scenario() -> void:
	"""Launch airplane with current scenario settings"""
	if is_flight_active:
		print("Flight already in progress - reset first")
		return
	
	if not airplane or not launcher:
		print("Missing airplane or launcher")
		return
	
	var scenario = test_scenarios[current_scenario_index]
	
	# Configure airplane for scenario
	airplane.is_unbalanced = scenario.unbalanced
	
	# Attach airplane to launcher
	launcher.attach_airplane(airplane)
	
	# Simulate pull and release
	var pull_position = launcher.global_position + Vector3.BACK * scenario.pull_distance
	launcher.start_pull()
	launcher.update_pull(pull_position)
	launcher.release_pull()
	
	print("Launched scenario: ", scenario.name)

func reset_airplane() -> void:
	"""Reset airplane to launch position"""
	if not airplane:
		return
	
	# Stop any current flight
	if is_flight_active:
		airplane.stop_flight()
		is_flight_active = false
	
	# Reset airplane position and state
	airplane.global_position = Vector3(0, 1, 0)
	airplane.rotation = Vector3.ZERO
	airplane.linear_velocity = Vector3.ZERO
	airplane.angular_velocity = Vector3.ZERO
	airplane.freeze = false
	
	# Reset camera
	if camera:
		camera.position = Vector3(0, 3, 8)
		camera.look_at(Vector3.ZERO, Vector3.UP)
	
	print("Airplane reset")
	update_ui_display()

func next_scenario() -> void:
	"""Switch to next test scenario"""
	current_scenario_index = (current_scenario_index + 1) % test_scenarios.size()
	print("Switched to scenario: ", test_scenarios[current_scenario_index].name)
	update_ui_display()

func previous_scenario() -> void:
	"""Switch to previous test scenario"""
	current_scenario_index = (current_scenario_index - 1 + test_scenarios.size()) % test_scenarios.size()
	print("Switched to scenario: ", test_scenarios[current_scenario_index].name)
	update_ui_display()

func toggle_unbalanced_mode() -> void:
	"""Toggle unbalanced mode for current scenario"""
	test_scenarios[current_scenario_index].unbalanced = not test_scenarios[current_scenario_index].unbalanced
	var status = "enabled" if test_scenarios[current_scenario_index].unbalanced else "disabled"
	print("Unbalanced mode ", status, " for current scenario")
	update_ui_display()

func _on_airplane_launched(velocity: Vector3) -> void:
	"""Handle airplane launch event"""
	is_flight_active = true
	flight_start_time = Time.get_time_dict_from_system().second
	print("Flight started with velocity: ", velocity)

func _on_pull_updated(distance: float, force: float) -> void:
	"""Handle launcher pull update"""
	# This could be used for visual feedback during pull
	pass

func _process(_delta: float) -> void:
	# Update flight tracking
	if is_flight_active and airplane:
		# Follow airplane with camera
		_update_flight_camera()
		
		# Check if flight ended
		if not airplane.is_flying:
			is_flight_active = false
			print("Flight ended")
		
		# Update UI with flight data
		update_ui_display()

func _update_flight_camera() -> void:
	"""Update camera to follow airplane during flight"""
	if not airplane or not camera:
		return
	
	# Smooth camera following
	var target_position = airplane.global_position + Vector3(0, 2, 5)
	camera.global_position = camera.global_position.lerp(target_position, 0.02)
	
	# Look at airplane
	camera.look_at(airplane.global_position, Vector3.UP)

func update_ui_display() -> void:
	"""Update UI with current status and flight information"""
	if not ui_label:
		return
	
	var scenario = test_scenarios[current_scenario_index]
	var ui_text = "=== Flight Physics Test ===\n\n"
	
	# Current scenario info
	ui_text += "Scenario %d/%d: %s\n" % [current_scenario_index + 1, test_scenarios.size(), scenario.name]
	ui_text += "Description: %s\n" % scenario.description
	ui_text += "Unbalanced: %s\n" % ("Yes" if scenario.unbalanced else "No")
	ui_text += "Pull Distance: %.1f m\n\n" % scenario.pull_distance
	
	# Flight status
	if is_flight_active and airplane:
		var flight_data = airplane.get_flight_data()
		ui_text += "=== FLIGHT ACTIVE ===\n"
		ui_text += "Speed: %.1f m/s\n" % flight_data.speed
		ui_text += "Altitude: %.1f m\n" % flight_data.altitude
		
		if flight_data.has("is_stalled"):
			ui_text += "Stalled: %s\n" % ("Yes" if flight_data.is_stalled else "No")
		
		# Show aerodynamic info if available
		var aero_info = airplane.get_detailed_aerodynamic_info()
		if not aero_info.is_empty():
			ui_text += "Angle of Attack: %.1f°\n" % aero_info.get("angle_of_attack_deg", 0)
			ui_text += "Lift: %.2f N\n" % aero_info.get("lift_magnitude", 0)
			ui_text += "Drag: %.2f N\n" % aero_info.get("drag_magnitude", 0)
	else:
		ui_text += "=== READY TO LAUNCH ===\n"
	
	ui_text += "\n=== CONTROLS ===\n"
	ui_text += "SPACE - Launch\n"
	ui_text += "ENTER - Reset\n"
	ui_text += "← → - Change Scenario\n"
	ui_text += "↑ - Toggle Unbalanced\n"
	ui_text += "ESC or Q - Quit"
	
	ui_label.text = ui_text