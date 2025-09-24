#!/bin/bash

# Development Helper Script for Model Airplane Launch
# Usage: ./dev.sh [command]

GODOT_CMD="godot-4"

show_help() {
    echo "Model Airplane Launch - Development Helper"
    echo ""
    echo "Usage: ./dev.sh [command]"
    echo ""
    echo "Commands:"
    echo "  validate     - Validate project syntax and check for issues"
    echo "  test-physics - Test flight physics implementation"
    echo "  run          - Run the project"
    echo "  run-headless - Run project in headless mode"
    echo "  export       - Export project for mobile"
    echo "  clean        - Clean temporary files"
    echo "  help         - Show this help message"
    echo ""
}

validate_project() {
    echo "🔍 Validating project..."
    if [ -f "scripts/validate_project.sh" ]; then
        ./scripts/validate_project.sh
    else
        echo "Running basic validation..."
        $GODOT_CMD --headless --check-only --path .
    fi
}

test_physics() {
    echo "🧪 Testing flight physics..."
    if [ -f "scripts/test_flight_physics.sh" ]; then
        ./scripts/test_flight_physics.sh
    else
        echo "❌ Flight physics test script not found"
        exit 1
    fi
}

run_project() {
    echo "🚀 Running project..."
    $GODOT_CMD --path .
}

run_headless() {
    echo "🤖 Running project in headless mode..."
    $GODOT_CMD --headless --path .
}

export_project() {
    echo "📦 Exporting project..."
    # This would need to be configured based on export presets
    $GODOT_CMD --headless --export-release "Android" --path .
}

clean_project() {
    echo "🧹 Cleaning temporary files..."
    find . -name "*.tmp" -delete
    find . -name "*_temp.gd" -delete
    find . -name ".import" -type d -exec rm -rf {} + 2>/dev/null || true
    echo "✅ Cleanup complete"
}

# Main command handling
case "${1:-help}" in
    "validate")
        validate_project
        ;;
    "test-physics")
        test_physics
        ;;
    "run")
        run_project
        ;;
    "run-headless")
        run_headless
        ;;
    "export")
        export_project
        ;;
    "clean")
        clean_project
        ;;
    "help"|*)
        show_help
        ;;
esac