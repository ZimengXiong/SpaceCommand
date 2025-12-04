#!/bin/bash

SVG_FILE="Resources/AppIcon.svg"

OUTPUT_DIR="Resources/Assets.xcassets/AppIcon.appiconset"

mkdir -p "$OUTPUT_DIR"

declare -a SIZES=(
    "16x16"
    "32x32"
    "64x64"
    "128x128"
    "256x256"
    "512x512"
)

for SIZE in "${SIZES[@]}"; do
    WIDTH=${SIZE%x*}
    HEIGHT=${SIZE#*x}

    OUTPUT_FILE="$OUTPUT_DIR/AppIcon_${SIZE}.png"

    rsvg-convert -w $WIDTH -h $HEIGHT -f png -o "$OUTPUT_FILE" "$SVG_FILE"
done