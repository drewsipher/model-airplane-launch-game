extends Node3D

## Flight test controller with bow/ballista launcher mechanics
## Click and drag the airplane to pull it back, release to launch

@onready var launcher = $ElasticBandLauncher
@onready var airplane = $BasicAirplane
@onready var flight_camera = $FlightCamera
@onready var ui_label: Label = $UI/FlightInfo

# Launcher state
var is_flight_active: bool = false
var is_pulling: bool = false
var pull_start_position: Vector2
var airplane_start_position: Vector3

func _ready() -> void:
	print("=== Bow/Ballista Launcher Test ===")
	
	# Set up launcher
	if launcher and airplane:
		launcher.attach_airplane(airplane)
		launcher.airplane_launched.connect(_on_airplane_launched)
		launcher.pull_started.connect(_on_pull_started)
		launcher.pull_updated.connect(_on_pull_updated)
		launcher.pull_released.connect(_on_pull_released)
		print("Launcher ready - airplane attached")
	else:
		print("ERROR: Missing launcher or airplane")
	
	# Set up flight camera
	if flight_camera:
		flight_camera.set_target_airplane(airplane)
		flight_camera.set_launch_view()
		flight_camera.distance_updated.connect(_on_distance_updated)
	
	# Connect to MobileInputManager for direct control
	if MobileInputManager:
		MobileInputManager.launcher_pull_started.connect(_on_launcher_pull_started)
		MobileInputManager.launcher_pull_updated.connect(_on_launcher_pull_updated)
		MobileInputManager.launcher_pull_released.connect(_on_launcher_pull_released)
		print("Connected to MobileInputManager")
	
	reset_airplane()
	update_ui_display()
	
	print("=== Controls ===")
	print("• Click and drag the AIRPLANE to pull back")
	print("• Release to launch")
	print("• ENTER - Reset airplane")
	print("• ESC - Quit")

func _input(event: InputEvent) -> void:
	# Handle key events
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE, KEY_Q:
				print("Quitting...")
				get_tree().quit()
			KEY_ENTER:
				reset_airplane()

# Launcher event handlers
func _on_launcher_pull_started(position: Vector2):
	print("Launcher pull started at: ", position)
	is_pulling = true
	pull_start_position = position
	if airplane:
		airplane_start_position = airplane.global_position

func _on_launcher_pull_updated(position: Vector2, pull_distance: float):
	if is_pulling:
		update_ui_display()

func _on_launcher_pull_released(position: Vector2, pull_distance: float):
	print("Launcher released - pull distance: %.2f" % pull_distance)
	is_pulling = false

func reset_airplane() -> void:
	"""Reset airplane to launch position"""
	if not airplane:
		return
	
	# Stop any current flight
	if is_flight_active:
		is_flight_active = false
	
	# Reset airplane position and state
	airplane.global_position = Vector3(0, 1, 0)
	airplane.rotation = Vector3.ZERO
	airplane.linear_velocity = Vector3.ZERO
	airplane.angular_velocity = Vector3.ZERO
	airplane.freeze = false
	
	# Reattach to launcher
	if launcher:
		launcher.attach_airplane(airplane)
	
	# Reset camera to launch view
	if flight_camera:
		flight_camera.set_target_airplane(airplane)
		flight_camera.set_launch_view()
		flight_camera.reset_distance_tracking()
	
	is_pulling = false
	print("Airplane reset and reattached to launcher")
	update_ui_display()

# Launcher signal handlers
func _on_pull_started():
	print("Launcher pull started")

func _on_pull_updated(distance: float, force: float):
	# Visual feedback is handled by the launcher itself
	pass

func _on_pull_released():
	print("Launcher pull released")

func _on_airplane_launched(velocity: Vector3) -> void:
	"""Handle airplane launch event"""
	is_flight_active = true
	
	# Switch camera to flight tracking mode
	if flight_camera:
		flight_camera.reset_distance_tracking()
		flight_camera.start_flight_tracking()
	
	print("Airplane launched with velocity: %.2f m/s" % velocity.length())
	update_ui_display()

func _on_distance_updated(distance: float, max_distance: float) -> void:
	"""Handle distance measurement updates"""
	update_ui_display()

func _process(_delta: float) -> void:
	# Update UI regularly
	if is_pulling or is_flight_active:
		update_ui_display()
	
	# Check if flight ended
	if is_flight_active and airplane:
		if airplane.linear_velocity.length() < 0.5 and airplane.global_position.y < 0.5:
			_on_flight_ended()

func _on_flight_ended() -> void:
	"""Handle flight ending"""
	is_flight_active = false
	print("Flight ended")
	
	# Switch camera back to launch view after a delay
	if flight_camera:
		await get_tree().create_timer(2.0).timeout
		flight_camera.stop_flight_tracking()
	
	update_ui_display()

func update_ui_display() -> void:
	"""Update UI with current status and flight information"""
	if not ui_label:
		return
	
	var ui_text = "=== BOW/BALLISTA LAUNCHER ===\n\n"
	
	# Launcher status
	if is_pulling:
		ui_text += "=== PULLING BACK ===\n"
		if launcher:
			var launch_info = launcher.get_launch_info()
			ui_text += "Pull Distance: %.2f m\n" % launch_info.pull_distance
			ui_text += "Pull Power: %.1f%%\n" % launch_info.pull_percentage
			ui_text += "Est. Launch Speed: %.1f m/s\n" % launch_info.estimated_launch_speed
	elif is_flight_active and airplane:
		# Flight status
		var flight_data = airplane.get_flight_data()
		ui_text += "=== FLIGHT ACTIVE ===\n"
		ui_text += "Speed: %.1f m/s\n" % flight_data.speed
		ui_text += "Altitude: %.1f m\n" % flight_data.altitude
		
		# Add distance information from flight camera
		if flight_camera:
			var distance_data = flight_camera.get_flight_distance_data()
			ui_text += "Distance: %.1f m\n" % distance_data.current_distance
			ui_text += "Max Distance: %.1f m\n" % distance_data.max_distance
	else:
		ui_text += "=== READY TO LAUNCH ===\n"
		ui_text += "Click and drag the airplane to pull back\n"
		ui_text += "Release to launch!\n\n"
		
		# Show max distance from previous flight if available
		if flight_camera:
			var distance_data = flight_camera.get_flight_distance_data()
			if distance_data.max_distance > 0:
				ui_text += "Last Max Distance: %.1f m\n" % distance_data.max_distance
	
	ui_text += "\n=== CONTROLS ===\n"
	ui_text += "• Click & drag airplane to pull back\n"
	ui_text += "• Release to launch\n"
	ui_text += "• ENTER - Reset airplane\n"
	ui_text += "• ESC - Quit"
	
	ui_label.text = ui_text
