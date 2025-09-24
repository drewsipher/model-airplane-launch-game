# Flight Physics Demo Guide

## Overview

The Flight Physics Demo allows you to visually test and observe the airplane flight physics system in action. You can launch airplanes with different configurations and watch realistic flight behavior including tumbling, stalling, and aerodynamic forces.

## Running the Demo

```bash
# Run the demo
./dev.sh run

# Or run directly with Godot
godot-4 --path .
```

The demo will open with the FlightTest scene as the main scene.

## Controls

| Key | Action |
|-----|--------|
| **SPACE** | Launch current scenario |
| **ENTER** | Reset airplane to launch position |
| **← →** | Change between test scenarios |
| **↑** | Toggle unbalanced mode for current scenario |
| **ESC** or **Q** | Quit the demo |

## Test Scenarios

The demo includes 4 different test scenarios:

### 1. Balanced Flight
- **Description**: Normal balanced airplane flight
- **Behavior**: Smooth, stable flight with realistic lift and drag
- **Physics**: Demonstrates proper aerodynamic forces

### 2. Unbalanced Tumbling  
- **Description**: Unbalanced airplane with tumbling behavior
- **Behavior**: Airplane tumbles and spins due to uneven weight distribution
- **Physics**: Shows realistic instability and tumbling forces

### 3. High Speed Launch
- **Description**: Maximum pull distance launch
- **Behavior**: High-speed launch with extended flight time
- **Physics**: Demonstrates high-speed aerodynamics

### 4. Low Speed Stall
- **Description**: Low speed launch to demonstrate stall
- **Behavior**: Airplane stalls and falls due to insufficient airspeed
- **Physics**: Shows stall detection and behavior

## What to Observe

### Flight Data Display
The UI shows real-time flight information:
- **Speed**: Current airspeed in m/s
- **Altitude**: Height above ground in meters
- **Stalled**: Whether the airplane is in a stall condition
- **Angle of Attack**: Current angle of attack in degrees
- **Lift/Drag Forces**: Aerodynamic forces in Newtons

### Visual Behavior
Watch for these realistic flight behaviors:
- **Lift Generation**: Airplane gains altitude when moving forward
- **Drag Effects**: Airplane slows down over time due to air resistance
- **Stall Behavior**: Low-speed flight causes loss of lift and falling
- **Tumbling**: Unbalanced airplanes spin and tumble realistically
- **Ground Collision**: Flight ends when airplane hits the ground

### Camera Tracking
- Camera automatically follows the airplane during flight
- Smooth tracking provides good view of flight behavior
- Camera resets when airplane is reset

## Physics Features Demonstrated

### ✅ Implemented Features
- **Lift Calculation**: Based on airspeed and angle of attack
- **Drag Forces**: Realistic air resistance opposing motion
- **Gravity**: Constant downward force
- **Stall Detection**: Automatic detection of stall conditions
- **Tumbling Behavior**: Unbalanced airplanes exhibit realistic instability
- **Ground Collision**: Flight ends on ground contact

### 🔧 Technical Details
- Uses realistic aerodynamic formulas (F = 0.5 * ρ * v² * C * A)
- Air density: 1.225 kg/m³ (sea level)
- Stall angle: ~20 degrees
- Minimum flying speed: 3 m/s

## Troubleshooting

### Demo Won't Start
- Check that all scripts are error-free: `./dev.sh validate`
- Ensure Godot 4 is installed: `which godot-4`

### Can't Quit Demo
- Try **ESC** key
- Try **Q** key  
- Use Ctrl+C in terminal as backup

### No Flight Behavior
- Make sure airplane is properly attached to launcher
- Check that physics system is initialized
- Verify ground collision detection is working

## Development Notes

This demo is built using:
- **FlightPhysics.gd**: Core aerodynamics calculations
- **BasicAirplane.gd**: Airplane physics body with FlightPhysics integration
- **ElasticBandLauncher.gd**: Launch mechanism with visual feedback
- **FlightTestController.gd**: Demo control and UI management

The demo serves as both a visual test and a development tool for validating the flight physics implementation.