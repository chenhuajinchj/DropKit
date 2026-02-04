#!/bin/bash

# bump-version.sh - Update version numbers in Info.plist
# Usage: ./bump-version.sh 1.0.3

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.3"
    exit 1
fi

VERSION="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PLIST_PATH="$PROJECT_ROOT/DropKit/Sources/Info.plist"

if [ ! -f "$PLIST_PATH" ]; then
    echo "Error: Info.plist not found at $PLIST_PATH"
    exit 1
fi

echo "Updating version to $VERSION..."

# Update CFBundleShortVersionString (marketing version)
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PLIST_PATH"

# Update CFBundleVersion (build number) - use same value for simplicity
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$PLIST_PATH"

echo "✓ Updated Info.plist"
echo "  CFBundleShortVersionString: $VERSION"
echo "  CFBundleVersion: $VERSION"
