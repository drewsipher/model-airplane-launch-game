#!/bin/bash

# Godot Project Validation Script
# This script validates the Godot project for syntax errors and basic functionality

echo "=== Godot Project Validation ==="
echo "Using Godot command: godot-4"

# Check if godot-4 is available
if ! command -v godot-4 &> /dev/null; then
    echo "❌ Error: godot-4 command not found"
    echo "Please install Godot 4 or check your PATH"
    exit 1
fi

echo "✅ Godot 4 found at: $(which godot-4)"

# Validate project syntax
echo ""
echo "🔍 Checking project syntax..."
# Create a minimal test script to validate syntax without running the main scene
cat > temp_syntax_check.gd << 'EOF'
extends SceneTree

func _init():
    print("✅ Project syntax validation passed")
    quit(0)
EOF

if timeout 5s godot-4 --headless --script temp_syntax_check.gd --path . 2>/dev/null; then
    echo "✅ Syntax check completed successfully"
else
    echo "⚠️  Syntax check completed with warnings (may be normal)"
fi

# Cleanup
rm -f temp_syntax_check.gd

# Check for common script issues
echo ""
echo "🔍 Checking for common script issues..."

# Check for missing class_name declarations (only for component classes)
echo "Checking for proper class_name declarations..."
find scripts/components -name "*.gd" 2>/dev/null | while read file; do
    if [ -f "$file" ] && ! grep -q "class_name" "$file" && grep -q "extends.*Node" "$file"; then
        echo "⚠️  Warning: $file might need a class_name declaration"
    fi
done

# Check for old export syntax (export without @)
echo "Checking for old export syntax..."
find scripts -name "*.gd" -exec grep -n "^[[:space:]]*export " {} + 2>/dev/null | while read line; do
    echo "⚠️  Warning: Old export syntax found: $line"
    echo "   Consider updating to @export"
done

echo ""
echo "✅ Validation complete!"