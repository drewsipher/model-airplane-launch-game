# BasicAirplane Component

## Overview

The BasicAirplane class is a RigidBody3D-based component that implements simple airplane physics for initial flight testing. It provides basic weight, drag, and lift properties that affect flight behavior.

## Features

- **Physics Properties**: Configurable weight, drag coefficient, and lift coefficient
- **Aerodynamic Forces**: Real-time calculation of drag and lift forces during flight
- **Flight State Tracking**: Monitors flight status and provides flight data
- **Collision Detection**: Handles landing and crash scenarios

## Usage

### Scene Setup

1. Instance the `BasicAirplane.tscn` scene in your game world
2. Position it at the desired launch location
3. Configure physics properties in the inspector

### Launching the Airplane

```gdscript
# Get reference to airplane
var airplane: BasicAirplane = $BasicAirplane

# Launch with initial velocity
var launch_velocity = Vector3(0, 5, 15)  # x, y, z components
airplane.launch_airplane(launch_velocity)
```

### Monitoring Flight

```gdscript
# Get current flight data
var flight_data = airplane.get_flight_data()
print("Speed: ", flight_data.speed)
print("Altitude: ", flight_data.altitude)
print("Is Flying: ", flight_data.is_flying)
```

## Physics Properties

### Weight (airplane_weight)
- **Type**: float
- **Default**: 50.0 grams
- **Description**: Total weight of the airplane affecting physics simulation

### Drag Coefficient (drag_coefficient)
- **Type**: float  
- **Default**: 0.02
- **Description**: Resistance to motion through air

### Lift Coefficient (lift_coefficient)
- **Type**: float
- **Default**: 0.1
- **Description**: Ability to generate lift force from forward motion

## Physics Implementation

### Drag Force
Applied opposite to velocity direction using the formula:
```
F_drag = 0.5 * ρ * v² * Cd
```
Where:
- ρ = air density (1.225 kg/m³)
- v = velocity magnitude
- Cd = drag coefficient

### Lift Force
Applied upward relative to airplane orientation based on forward velocity:
```
F_lift = 0.5 * ρ * v_forward² * Cl
```
Where:
- v_forward = forward velocity component
- Cl = lift coefficient

## Testing

Use the `AirplaneTest.tscn` scene to test airplane functionality:

1. Open the test scene
2. Run the scene
3. Press SPACE to launch the airplane
4. Observe flight behavior and console output

## Requirements Compliance

This implementation satisfies:
- **Requirement 4.1**: Real-time calculation of lift, drag, and weight distribution
- **Requirement 4.2**: Physics simulation that responds to airplane properties

## Next Steps

This basic implementation will be extended in future tasks to support:
- Modular part system
- Advanced aerodynamics
- Unbalanced flight behavior
- Environmental factors