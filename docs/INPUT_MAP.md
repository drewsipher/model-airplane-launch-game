# Mobile Input Map Configuration

This document describes the mobile input configuration for the Model Airplane Launch game.

## Input Actions

### Core Game Actions
- **launch_pull**: Primary touch for pulling the elastic band launcher
  - Device: Touch screen (index 0)
  - Used for: Elastic band tension control

- **camera_pan**: Drag gesture for camera movement
  - Device: Touch screen drag
  - Used for: Camera panning in building mode

- **camera_zoom**: Two-finger touch for zoom control
  - Device: Touch screen (index 1, secondary touch)
  - Used for: Pinch-to-zoom camera control

- **ui_select**: General UI interaction
  - Device: Touch screen (index 0)
  - Used for: Button presses, menu navigation

## Mobile Input Settings

### Touch Emulation
- **Emulate touch from mouse**: Enabled (for desktop testing)
- **Emulate mouse from touch**: Disabled (pure touch interface)

### Physics Settings
- **Physics ticks per second**: 60 (smooth mobile performance)
- **Max physics steps per frame**: 8 (prevent slowdown)

## Touch Gesture Handling

The MobileInputManager singleton handles:
- Single touch events (tap, drag)
- Multi-touch gestures (pinch-to-zoom)
- Touch-to-3D world position conversion
- Camera control integration

## Screen Orientation
- **Primary orientation**: Portrait (1)
- **Window mode**: Fullscreen (3)
- **Stretch mode**: Canvas items with expand aspect

## Performance Considerations
- Touch input is processed at 60fps
- 3D ray casting is used for touch-to-world conversion
- Input events are batched to prevent frame drops