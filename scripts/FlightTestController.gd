extends Node3D

## Flight test controller for visual demonstration of airplane physics
## Allows launching airplanes and observing flight behavior

@onready var launcher = $ElasticBandLauncher
@onready var airplane = $BasicAirplane
@onready var flight_camera = $FlightCamera
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
var launch_point: Vector3 = Vector3.ZERO

func _ready() -> void:
	print("=== Flight Test Controller Started ===")
	
	# Set up launcher
	if launcher:
		launcher.airplane_launched.connect(_on_airplane_launched)
		launcher.pull_updated.connect(_on_pull_updated)
	
	# Set up flight camera
	if flight_camera:
		flight_camera.set_target_airplane(airplane)
		flight_camera.set_launch_view()
		flight_camera.camera_mode_changed.connect(_on_camera_mode_changed)
		flight_camera.distance_updated.connect(_on_distance_updated)
	
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
	
	# Reset camera to launch view
	if flight_camera:
		flight_camera.set_target_airplane(airplane)
		flight_camera.set_launch_view()
		flight_camera.reset_distance_tracking()
	
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
	launch_point = airplane.global_position
	
	# Switch camera to flight tracking mode
	if flight_camera:
		flight_camera.reset_distance_tracking()
		flight_camera.start_flight_tracking()
	
	print("Flight started with velocity: ", velocity)

func _on_pull_updated(distance: float, force: float) -> void:
	"""Handle launcher pull update"""
	# This could be used for visual feedback during pull
	pass

func _on_camera_mode_changed(new_mode) -> void:
	"""Handle camera mode changes"""
	print("Camera mode changed to: ", new_mode)

func _on_distance_updated(distance: float, max_distance: float) -> void:
	"""Handle distance measurement updates"""
	# Distance information is automatically included in UI updates
	pass

func _process(_delta: float) -> void:
	# Update flight tracking
	if is_flight_active and airplane:
		# Check if flight ended
		if not airplane.is_flying:
			_on_flight_ended()
		
		# Update UI with flight data
		update_ui_display()

func _on_flight_ended() -> void:
	"""Handle flight ending"""
	is_flight_active = false
	
	# Switch camera back to launch view after a delay
	if flight_camera:
		# Wait a moment before switching back to launch view
		await get_tree().create_timer(2.0).timeout
		flight_camera.stop_flight_tracking()
	
	print("Flight ended")

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
		
		# Add distance information from flight camera
		if flight_camera:
			var distance_data = flight_camera.get_flight_distance_data()
			ui_text += "Distance: %.1f m\n" % distance_data.current_distance
			ui_text += "Max Distance: %.1f m\n" % distance_data.max_distance
		
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
		
		# Show max distance from previous flight if available
		if flight_camera:
			var distance_data = flight_camera.get_flight_distance_data()
			if distance_data.max_distance > 0:
				ui_text += "Last Max Distance: %.1f m\n" % distance_data.max_distance
	
	ui_text += "\n=== CONTROLS ===\n"
	ui_text += "SPACE - Launch\n"
	ui_text += "ENTER - Reset\n"
	ui_text += "← → - Change Scenario\n"
	ui_text += "↑ - Toggle Unbalanced\n"
	ui_text += "ESC or Q - Quit"
	
	ui_label.text = ui_text