#!/bin/bash

# Script to regenerate PNG icons from SVG using rsvg-convert (librsvg)
# This fixes the corruption issue with the current PNG files

# Source SVG file
SVG_FILE="Resources/AppIcon.svg"

# Output directory for app icons
OUTPUT_DIR="Resources/Assets.xcassets/AppIcon.appiconset"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Define the required icon sizes
declare -a SIZES=(
    "16x16"
    "32x32"
    "64x64"
    "128x128"
    "256x256"
    "512x512"
)

echo "Regenerating PNG icons from SVG using rsvg-convert..."

# Loop through each size and generate PNG
for SIZE in "${SIZES[@]}"; do
    WIDTH=${SIZE%x*}
    HEIGHT=${SIZE#*x}

    OUTPUT_FILE="$OUTPUT_DIR/AppIcon_${SIZE}.png"

    echo "Generating $SIZE icon: $OUTPUT_FILE"

    # Use rsvg-convert to generate high-quality PNG
    rsvg-convert -w $WIDTH -h $HEIGHT -f png -o "$OUTPUT_FILE" "$SVG_FILE"

    # Check if conversion was successful
    if [ $? -eq 0 ]; then
        echo "✓ Successfully generated $SIZE icon"
    else
        echo "✗ Failed to generate $SIZE icon"
        exit 1
    fi
done

echo "All PNG icons have been regenerated successfully!"