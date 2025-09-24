# Design Document

## Overview

The Model Airplane Launch game is built using Godot 4.5 as a 3D physics simulation with modular airplane construction. The architecture follows a component-based design where airplane parts are individual physics bodies that can be assembled into a complete aircraft. The game uses Godot's built-in physics engine for realistic flight simulation and collision detection.

## Architecture

### Core Systems

1. **Physics System**: Handles airplane flight dynamics, elastic band mechanics, and part interactions
2. **Building System**: Manages part placement, attachment, and airplane assembly
3. **Economy System**: Tracks money, purchases, and progression
4. **UI System**: Provides interfaces for building, shopping, and statistics
5. **Save System**: Persists player progress, unlocked parts, and statistics

### Scene Structure

```
Main
├── GameManager (Singleton)
├── MobileInputManager (Singleton)
├── UI Layer (CanvasLayer)
│   ├── TouchHUD (Mobile-optimized)
│   ├── BuildingInterface (Touch-friendly)
│   ├── ShopInterface (Swipe navigation)
│   └── StatsInterface (Scrollable)
├── 3D World
│   ├── LaunchArea
│   │   ├── ElasticBandLauncher (Touch-controlled)
│   │   └── LaunchPlatform
│   ├── FlightArea (Optimized terrain LOD)
│   └── BuildingWorkspace (Touch manipulation)
└── Camera System
    ├── BuildingCamera (Touch pan/zoom)
    ├── LaunchCamera (Auto-follow)
    └── FlightCamera (Smooth tracking)
```

## Components and Interfaces

### Airplane System

#### AirplanePart (Base Class)
```gdscript
class_name AirplanePart extends RigidBody3D

@export var part_type: PartType
@export var weight: float
@export var drag_coefficient: float
@export var lift_coefficient: float  # For wings
@export var attachment_points: Array[Vector3]
@export var cost: int
```

#### PartType Enum
- FUSELAGE
- WING_LEFT
- WING_RIGHT  
- TAIL
- PROPELLER
- LANDING_GEAR

#### AirplaneAssembly
```gdscript
class_name AirplaneAssembly extends RigidBody3D

var parts: Array[AirplanePart] = []
var center_of_mass: Vector3
var total_weight: float
var is_balanced: bool

func calculate_aerodynamics() -> AerodynamicData
func attach_part(part: AirplanePart, position: Vector3) -> bool
func detach_part(part: AirplanePart) -> void
```

### Physics System

#### FlightPhysics
```gdscript
class_name FlightPhysics extends Node

func calculate_lift(airplane: AirplaneAssembly, velocity: Vector3) -> Vector3
func calculate_drag(airplane: AirplaneAssembly, velocity: Vector3) -> Vector3
func apply_aerodynamic_forces(airplane: AirplaneAssembly) -> void
func check_stall_conditions(airplane: AirplaneAssembly) -> bool
```

#### ElasticBandLauncher
```gdscript
class_name ElasticBandLauncher extends Node3D

@export var max_tension: float = 100.0
@export var launch_force_multiplier: float = 10.0

var current_tension: float = 0.0
var is_pulled: bool = false

signal launch_ready(force: float)
signal airplane_launched(initial_velocity: Vector3)
```

### Building System

#### BuildingManager
```gdscript
class_name BuildingManager extends Node

var available_parts: Array[AirplanePart] = []
var current_airplane: AirplaneAssembly
var building_mode: bool = false

func enter_building_mode() -> void
func exit_building_mode() -> void
func place_part(part_type: PartType, position: Vector3) -> bool
func validate_airplane_design() -> ValidationResult
```

#### PartInventory
```gdscript
class_name PartInventory extends Resource

var owned_parts: Dictionary = {} # PartType -> count
var unlocked_parts: Array[PartType] = []

func add_part(part_type: PartType, count: int = 1) -> void
func has_part(part_type: PartType) -> bool
func use_part(part_type: PartType) -> bool
```

### Economy System

#### EconomyManager
```gdscript
class_name EconomyManager extends Node

var current_money: int = 0
var total_earned: int = 0

func earn_money(distance: float) -> int
func spend_money(amount: int) -> bool
func calculate_distance_reward(distance: float) -> int
```

## Data Models

### Flight Data
```gdscript
class_name FlightData extends Resource

var distance: float
var flight_time: float
var max_altitude: float
var money_earned: int
var timestamp: String
var airplane_config: AirplaneConfiguration
```

### Airplane Configuration
```gdscript
class_name AirplaneConfiguration extends Resource

var parts: Array[PartData] = []
var total_weight: float
var balance_rating: float

class PartData:
    var part_type: PartType
    var position: Vector3
    var rotation: Vector3
```

### Shop Item
```gdscript
class_name ShopItem extends Resource

var part_type: PartType
var cost: int
var unlock_requirement: UnlockRequirement
var performance_stats: Dictionary
```

## Error Handling

### Physics Validation
- Validate airplane assembly before launch
- Check for minimum required part (fuselage)
- Prevent launching with disconnected parts
- Handle physics simulation edge cases (NaN values, extreme forces)

### Building Constraints
- Enforce attachment point compatibility
- Prevent overlapping parts
- Validate structural integrity
- Handle invalid part placements gracefully

### Save Data Integrity
- Validate save file format
- Handle corrupted save data
- Provide fallback default values
- Auto-save progress at key moments

## Testing Strategy

### Unit Tests
- Physics calculations (lift, drag, center of mass)
- Economy calculations (distance to money conversion)
- Part attachment validation
- Save/load functionality

### Integration Tests
- Complete flight simulation from launch to landing
- Building workflow from part selection to airplane completion
- Shop purchase flow
- Statistics tracking accuracy

### Physics Tests
- Airplane stability with balanced vs unbalanced designs
- Elastic band launch force accuracy
- Collision detection and response
- Aerodynamic behavior under various conditions

### Performance Tests
- Frame rate during complex flight simulations
- Memory usage with multiple airplane parts
- Loading times for save data
- Physics simulation stability over long flights

## Mobile Optimization

### Performance Considerations
- **Rendering**: Use mobile renderer with simplified shaders and reduced polygon counts
- **Physics**: Limit simultaneous physics bodies and use simplified collision shapes
- **Memory**: Implement object pooling for airplane parts and UI elements
- **Battery**: Optimize physics tick rate and reduce unnecessary calculations during flight

### Mobile-Specific Features
- **Touch Controls**: 
  - Drag gestures for elastic band pulling
  - Pinch-to-zoom and pan for building camera
  - Touch and drag for part placement
  - Swipe gestures for UI navigation
- **Screen Adaptation**: Responsive UI that works on various screen sizes and orientations
- **Platform Integration**: Android-first development with iOS compatibility considerations

### Input System Design
```gdscript
class_name MobileInputManager extends Node

func handle_touch_input(event: InputEventScreenTouch) -> void
func handle_drag_input(event: InputEventScreenDrag) -> void
func convert_touch_to_3d_position(screen_pos: Vector2) -> Vector3
```

## Implementation Notes

### Godot-Specific Considerations
- Use RigidBody3D for airplane parts with appropriate collision shapes
- Implement custom aerodynamic forces using `_integrate_forces()`
- Utilize Godot's Joint3D system for part connections
- Leverage the built-in save system with custom Resource classes
- Configure mobile renderer settings for optimal performance

### Mobile Platform Optimization
- **Android**: Target API level 33+ with Vulkan renderer fallback to GLES3
- **iOS**: Ensure Metal compatibility and proper memory management
- **Touch Interface**: Design UI elements with minimum 44pt touch targets
- **Performance**: Maintain 60fps on mid-range devices, 30fps minimum on low-end

### Physics Tuning
- Balance realism with fun gameplay
- Provide visual feedback for physics states (stalling, spinning)
- Implement progressive difficulty through part unlock requirements
- Ensure consistent physics behavior across different frame rates
- Optimize physics calculations for mobile CPU constraints