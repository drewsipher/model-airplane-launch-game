# Test Scene Documentation

## Overview

The `TestMain.tscn` scene serves as a minimal main scene for development and testing purposes. It allows us to validate that systems are working correctly after each task implementation.

## Purpose

- **Validation**: Verify that singletons load correctly
- **Testing**: Test mobile input and touch controls
- **Development**: Provide a runnable scene during development
- **Debugging**: Display system status and debug information

## Features

### Singleton Testing
- Validates that GameManager, MobileInputManager, and EconomyManager load correctly
- Displays current game state and money
- Shows checkmarks (✓) or X marks (✗) for each singleton

### Mobile Input Testing
- Connects to mobile input signals
- Logs touch events to console
- Displays touch positions on screen
- Tests touch-to-3D conversion capabilities

### Basic 3D Environment
- Simple 3D scene with camera and lighting
- Ready for testing 3D objects and physics
- Mobile-optimized camera positioning

## Usage

### Running the Test Scene
```bash
# Run in headless mode for quick testing
godot-4 --headless --quit-after 3

# Run with graphics for visual testing
godot-4 --quit-after 5

# Open in editor
godot-4 --editor
```

### Controls
- **ESC**: Quit the application
- **Touch/Click**: Test input system and display coordinates

### Console Output
The test scene provides detailed console output:
```
=== Test Main Scene Started ===
Testing singletons...
✓ GameManager loaded
✓ MobileInputManager loaded  
✓ EconomyManager loaded
Starting money: 100
✓ Mobile input signals connected
```

## Development Workflow

1. **After each task**: Run the test scene to verify systems work
2. **Add test objects**: Place new components in the scene for testing
3. **Validate functionality**: Use the console output to debug issues
4. **Mobile testing**: Test touch controls and mobile-specific features

## Future Enhancements

As development progresses, the test scene can be enhanced with:
- Test airplane objects for physics validation
- UI elements for testing building systems
- Camera controls for testing flight mechanics
- Performance monitoring displays

## Replacement

This test scene will eventually be replaced by the proper main menu and game flow system implemented in task 9. Until then, it serves as our development and testing foundation.