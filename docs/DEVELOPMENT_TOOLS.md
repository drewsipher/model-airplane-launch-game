# Development Tools

This document describes the development and validation tools available for the Model Airplane Launch project.

## Quick Start

Use the main development helper script:

```bash
./dev.sh validate      # Validate project syntax
./dev.sh test-physics  # Test flight physics
./dev.sh run          # Run the project
./dev.sh help         # Show all commands
```

## Validation Tools

### Project Validation (`./dev.sh validate`)

Validates the entire Godot project for:
- Syntax errors in GDScript files
- Missing class_name declarations
- Deprecated export syntax
- Basic project structure

### Flight Physics Testing (`./dev.sh test-physics`)

Specifically tests the FlightPhysics implementation:
- ✅ Class instantiation and script loading
- ✅ Drag calculations (returns correct values)
- ✅ Lift calculations (validates function calls)
- ✅ Stall detection logic
- ⚠️ Note: Some "not in tree" warnings are expected for mock objects

## Godot Command Reference

The correct Godot command for this system is `godot-4` (not `godot`).

Common Godot commands:
```bash
godot-4 --headless --check-only --path .     # Syntax check
godot-4 --path .                             # Run project
godot-4 --headless --quit --path .           # Quick validation
```

## File Structure

```
scripts/
├── validate_project.sh    # Main project validation
├── test_flight_physics.sh # Flight physics testing
└── components/
    ├── FlightPhysics.gd   # Flight physics system
    └── BasicAirplane.gd   # Airplane implementation

dev.sh                     # Main development helper
```

## Adding New Validation

To add new validation checks:

1. Add the check to `scripts/validate_project.sh`
2. Add a new command to `dev.sh` if needed
3. Update this documentation

## Troubleshooting

### "godot command not found"
- Use `godot-4` instead of `godot`
- Check that Godot 4 is installed: `which godot-4`

### Validation shows game initialization
- This is normal - the validation loads the project which initializes singletons
- The validation completes successfully after the initialization messages

### Physics test shows "not in tree" errors
- This is expected when testing with mock objects
- The core functionality tests still pass correctly

### Permission denied
- Make scripts executable: `chmod +x dev.sh scripts/*.sh`