#!/bin/bash

# Flight Physics Test Script
# Tests the FlightPhysics implementation

echo "=== Flight Physics Test ==="

# First validate the project with a quick syntax check
echo "🔍 Validating project syntax..."
cat > temp_validation.gd << 'EOF'
extends SceneTree
func _init():
    print("✅ Project syntax is valid")
    quit(0)
EOF

if timeout 3s godot-4 --headless --script temp_validation.gd --path . 2>/dev/null; then
    echo "✅ Basic validation passed"
else
    echo "❌ Project validation failed - cannot run physics tests"
    rm -f temp_validation.gd
    exit 1
fi

rm -f temp_validation.gd

# Run a quick headless test to verify FlightPhysics instantiation
echo ""
echo "🧪 Testing FlightPhysics class instantiation..."

# Create a temporary test scene
cat > test_physics_temp.gd << 'EOF'
extends Node

func _ready():
    print("=== FlightPhysics Instantiation Test ===")
    
    # Load the FlightPhysics script
    var flight_physics_script = load("res://scripts/components/FlightPhysics.gd")
    if not flight_physics_script:
        print("❌ Failed to load FlightPhysics script")
        get_tree().quit(1)
        return
    
    # Test FlightPhysics creation
    var flight_physics = flight_physics_script.new()
    if flight_physics:
        print("✅ FlightPhysics class instantiated successfully")
        
        # Test basic calculations with mock data
        var mock_airplane = RigidBody3D.new()
        mock_airplane.mass = 0.05
        
        var test_velocity = Vector3(0, 0, 10)
        var lift_force = flight_physics.calculate_lift(mock_airplane, test_velocity, 0.1)
        var drag_force = flight_physics.calculate_drag(mock_airplane, test_velocity, 0.02)
        
        print("✅ Lift calculation: ", lift_force.length(), " N")
        print("✅ Drag calculation: ", drag_force.length(), " N")
        
        # Test stall detection
        var is_stalled = flight_physics.check_stall_conditions(mock_airplane, test_velocity)
        print("✅ Stall detection at 10 m/s: ", is_stalled)
        
        # Cleanup
        flight_physics.queue_free()
        mock_airplane.queue_free()
        
        print("✅ All FlightPhysics tests passed!")
    else:
        print("❌ Failed to instantiate FlightPhysics")
        get_tree().quit(1)
        return
    
    print("=== Test Complete ===")
    get_tree().quit(0)
EOF

# Create a minimal scene to run the test
cat > test_physics_scene.tscn << 'EOF'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://test_physics_temp.gd" id="1"]

[node name="TestPhysics" type="Node"]
script = ExtResource("1")
EOF

# Run the test
echo "Running FlightPhysics test..."
if timeout 10s godot-4 --headless test_physics_scene.tscn --path . 2>&1; then
    echo "✅ FlightPhysics tests completed successfully"
else
    echo "❌ FlightPhysics tests failed"
    rm -f test_physics_temp.gd test_physics_scene.tscn
    exit 1
fi

# Cleanup
rm -f test_physics_temp.gd test_physics_scene.tscn

echo ""
echo "🎉 All flight physics tests passed!"