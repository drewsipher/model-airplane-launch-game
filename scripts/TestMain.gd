extends Node3D

## Test main scene for development and validation
## This scene helps verify that systems are working during development

@onready var test_label: Label = $UI/TestLabel

func _ready():
	print("=== Test Main Scene Started ===")
	
	# Test singleton availability
	test_singletons()
	
	# Test mobile input if available
	test_mobile_input()
	
	# Update UI with system status
	update_status_display()

func _input(event):
	# Allow ESC to quit for testing
	if event.is_action_pressed("ui_cancel"):
		print("Quitting test scene...")
		get_tree().quit()
	
	# Test touch input
	if event is InputEventScreenTouch:
		print("Touch detected at: ", event.position)
		if test_label:
			test_label.text += "\nTouch at: " + str(event.position)

func test_singletons():
	print("Testing singletons...")
	
	# Test GameManager
	if GameManager:
		print("✓ GameManager loaded")
		GameManager.change_state(GameManager.GameState.MAIN_MENU)
	else:
		print("✗ GameManager not found")
	
	# Test MobileInputManager
	if MobileInputManager:
		print("✓ MobileInputManager loaded")
	else:
		print("✗ MobileInputManager not found")
	
	# Test EconomyManager
	if EconomyManager:
		print("✓ EconomyManager loaded")
		print("Starting money: ", EconomyManager.get_money())
	else:
		print("✗ EconomyManager not found")

func test_mobile_input():
	if MobileInputManager:
		# Connect to mobile input signals for testing
		MobileInputManager.touch_started.connect(_on_touch_started)
		MobileInputManager.touch_ended.connect(_on_touch_ended)
		print("✓ Mobile input signals connected")

func _on_touch_started(position: Vector2, index: int):
	print("Touch started at: ", position, " (finger ", index, ")")

func _on_touch_ended(position: Vector2, index: int):
	print("Touch ended at: ", position, " (finger ", index, ")")

func update_status_display():
	if not test_label:
		return
	
	var status_text = "Model Airplane Launch - Test Scene\n"
	
	# Singleton status
	status_text += "Singletons: "
	status_text += "GM✓ " if GameManager else "GM✗ "
	status_text += "MI✓ " if MobileInputManager else "MI✗ "
	status_text += "EM✓ " if EconomyManager else "EM✗ "
	status_text += "\n"
	
	# Current game state
	if GameManager:
		var state_name = GameManager.GameState.keys()[GameManager.get_current_state()]
		status_text += "Game State: " + state_name + "\n"
	
	# Money
	if EconomyManager:
		status_text += "Money: $" + str(EconomyManager.get_money()) + "\n"
	
	status_text += "\nPress ESC to quit\nTouch screen to test input"
	
	test_label.text = status_text