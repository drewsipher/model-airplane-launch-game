# Project Structure

This document outlines the directory structure and organization of the Model Airplane Launch game project.

## Root Directory Structure

```
/
├── docs/                    # Documentation files
├── resources/               # Game resources and assets
│   ├── materials/          # Materials and shaders
│   ├── meshes/            # 3D models and meshes
│   └── parts/             # Airplane part definitions
├── scenes/                 # Godot scene files
│   ├── airplane/          # Airplane-related scenes
│   ├── ui/                # User interface scenes
│   └── world/             # Game world scenes
├── scripts/                # GDScript source files
│   ├── components/        # Reusable game components
│   ├── singletons/        # Autoload singleton scripts
│   └── ui/                # UI-specific scripts
├── .kiro/                  # Kiro IDE configuration
│   └── specs/             # Feature specifications
├── .godot/                 # Godot engine cache (auto-generated)
├── export_presets.cfg      # Export configuration for platforms
├── project.godot           # Main project configuration
└── icon.svg               # Application icon
```

## Singletons (Autoload)

The following singletons are automatically loaded:

1. **GameManager** (`scripts/singletons/GameManager.gd`)
   - Manages game state transitions
   - Handles flow between building, launching, flying modes

2. **MobileInputManager** (`scripts/singletons/MobileInputManager.gd`)
   - Processes touch input and gestures
   - Converts screen coordinates to 3D world positions
   - Handles pinch-to-zoom and drag gestures

3. **EconomyManager** (`scripts/singletons/EconomyManager.gd`)
   - Manages player money and purchases
   - Calculates distance-based rewards
   - Tracks spending and earning statistics

## Mobile Configuration

### Display Settings
- **Resolution**: 1080x1920 (portrait orientation)
- **Window mode**: Fullscreen
- **Stretch mode**: Canvas items with expand aspect

### Rendering Settings
- **Renderer**: Mobile (GL compatibility fallback)
- **MSAA**: 1x (performance optimized)
- **3D Scaling**: 0.75 (performance optimization)
- **Occlusion culling**: Enabled

### Physics Layers
1. **World** - Static world geometry
2. **Airplane** - Complete airplane assemblies
3. **Parts** - Individual airplane parts
4. **UI** - User interface elements
5. **Launcher** - Elastic band launcher system

## Development Guidelines

- Place reusable components in `scripts/components/`
- Keep UI logic separate in `scripts/ui/`
- Use the singleton pattern for global managers
- Organize scenes by functional area
- Document new systems in the `docs/` directory