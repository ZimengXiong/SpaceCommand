#!/bin/bash

if [ -f ../version.txt ]; then
    source ../version.txt
else
    echo "Error: version.txt not found"
    exit 1
fi

echo "Syncing version $VERSION (build $BUILD) to all files..."

echo "Updating Sources/AboutTab.swift..."
sed -i '' "s/static let version = \".*\"/static let version = \"$VERSION\"/" ../Sources/AboutTab.swift
sed -i '' "s/static let build = \".*\"/static let build = \"$BUILD\"/" ../Sources/AboutTab.swift

echo "Updating Resources/Info.plist..."
python3 update_plist.py ../Resources/Info.plist $VERSION $BUILD

echo "Version sync complete: $VERSION (build $BUILD)"