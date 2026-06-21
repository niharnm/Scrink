#!/bin/bash

# Script to generate all iOS app icon sizes from a source image
# Usage: ./generate_app_icons.sh <source_image.png>

if [ -z "$1" ]; then
    echo "Usage: ./generate_app_icons.sh <source_image.png>"
    echo "Example: ./generate_app_icons.sh logo.png"
    exit 1
fi

SOURCE_IMAGE="$1"
ICON_DIR="Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "Error: Source image '$SOURCE_IMAGE' not found"
    exit 1
fi

echo "Generating app icons from $SOURCE_IMAGE..."

# iPhone icons
sips -z 40 40 "$SOURCE_IMAGE" --out "$ICON_DIR/AppIcon-20x20@2x.png"
sips -z 60 60 "$SOURCE_IMAGE" --out "$ICON_DIR/AppIcon-20x20@3x.png"
sips -z 58 58 "$SOURCE_IMAGE" --out "$ICON_DIR/AppIcon-29x29@2x.png"
sips -z 87 87 "$SOURCE_IMAGE" --out "$ICON_DIR/AppIcon-29x29@3x.png"
sips -z 80 80 "$SOURCE_IMAGE" --out "$ICON_DIR/AppIcon-40x40@2x.png"
sips -z 120 120 "$SOURCE_IMAGE" --out "$ICON_DIR/AppIcon-40x40@3x.png"
sips -z 120 120 "$SOURCE_IMAGE" --out "$ICON_DIR/AppIcon-60x60@2x.png"
sips -z 180 180 "$SOURCE_IMAGE" --out "$ICON_DIR/AppIcon-60x60@3x.png"

# iPad icons
sips -z 20 20 "$SOURCE_IMAGE" --out "$ICON_DIR/AppIcon-20x20@1x.png"
sips -z 40 40 "$SOURCE_IMAGE" --out "$ICON_DIR/AppIcon-20x20@2x.png"
sips -z 29 29 "$SOURCE_IMAGE" --out "$ICON_DIR/AppIcon-29x29@1x.png"
sips -z 58 58 "$SOURCE_IMAGE" --out "$ICON_DIR/AppIcon-29x29@2x.png"
sips -z 40 40 "$SOURCE_IMAGE" --out "$ICON_DIR/AppIcon-40x40@1x.png"
sips -z 80 80 "$SOURCE_IMAGE" --out "$ICON_DIR/AppIcon-40x40@2x.png"
sips -z 76 76 "$SOURCE_IMAGE" --out "$ICON_DIR/AppIcon-76x76@1x.png"
sips -z 152 152 "$SOURCE_IMAGE" --out "$ICON_DIR/AppIcon-76x76@2x.png"
sips -z 167 167 "$SOURCE_IMAGE" --out "$ICON_DIR/AppIcon-83.5x83.5@2x.png"

# App Store icon
sips -z 1024 1024 "$SOURCE_IMAGE" --out "$ICON_DIR/AppIcon-1024x1024.png"

echo "Done! All app icon sizes have been generated in $ICON_DIR"
