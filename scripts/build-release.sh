#!/bin/bash

# DropKit Release Build Script
# Usage: ./build-release.sh <version>
# Example: ./build-release.sh 1.0.3

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check version argument
if [ -z "$1" ]; then
    echo -e "${RED}Error: Version number required${NC}"
    echo "Usage: ./build-release.sh <version>"
    echo "Example: ./build-release.sh 1.0.3"
    exit 1
fi

VERSION="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
XCODE_PROJECT="$PROJECT_ROOT/DropKit/DropKit.xcodeproj"
BUILD_DIR="$PROJECT_ROOT/build"
RELEASES_DIR="$PROJECT_ROOT/releases"
APP_NAME="DropKit"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  DropKit Release Build v${VERSION}${NC}"
echo -e "${GREEN}========================================${NC}"

# Step 1: Clean previous build
echo -e "\n${YELLOW}[1/5] Cleaning previous build...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$RELEASES_DIR"

# Step 2: Build Release version
echo -e "\n${YELLOW}[2/5] Building Release version...${NC}"
xcodebuild -project "$XCODE_PROJECT" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
    archive \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION="$VERSION" \
    | grep -E "(Compiling|Linking|Archive|error:|warning:)" || true

# Check if archive was created
if [ ! -d "$BUILD_DIR/$APP_NAME.xcarchive" ]; then
    echo -e "${RED}Error: Archive failed${NC}"
    exit 1
fi

echo -e "${GREEN}Archive created successfully${NC}"

# Step 3: Export .app from archive
echo -e "\n${YELLOW}[3/5] Exporting $APP_NAME.app...${NC}"
APP_PATH="$BUILD_DIR/$APP_NAME.xcarchive/Products/Applications/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: $APP_NAME.app not found in archive${NC}"
    exit 1
fi

# Copy app to releases
cp -R "$APP_PATH" "$RELEASES_DIR/$APP_NAME.app"
echo -e "${GREEN}Exported $APP_NAME.app${NC}"

# Step 4: Create ZIP
echo -e "\n${YELLOW}[4/5] Creating $APP_NAME-$VERSION.zip...${NC}"
cd "$RELEASES_DIR"
rm -f "$APP_NAME-$VERSION.zip"
ditto -c -k --keepParent "$APP_NAME.app" "$APP_NAME-$VERSION.zip"
echo -e "${GREEN}Created $APP_NAME-$VERSION.zip${NC}"

# Step 5: Create DMG
echo -e "\n${YELLOW}[5/5] Creating $APP_NAME-$VERSION.dmg...${NC}"
DMG_TEMP="$BUILD_DIR/dmg_temp"
DMG_PATH="$RELEASES_DIR/$APP_NAME-$VERSION.dmg"

rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"
cp -R "$APP_PATH" "$DMG_TEMP/"

# Create symbolic link to Applications folder
ln -s /Applications "$DMG_TEMP/Applications"

# Remove old DMG if exists
rm -f "$DMG_PATH"

# Create DMG
hdiutil create -volname "$APP_NAME $VERSION" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$DMG_PATH"

echo -e "${GREEN}Created $APP_NAME-$VERSION.dmg${NC}"

# Cleanup
echo -e "\n${YELLOW}Cleaning up...${NC}"
rm -rf "$DMG_TEMP"
rm -rf "$RELEASES_DIR/$APP_NAME.app"

# Summary
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\nOutput files in ${YELLOW}$RELEASES_DIR${NC}:"
ls -lh "$RELEASES_DIR"/*.zip "$RELEASES_DIR"/*.dmg 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'

echo -e "\n${GREEN}Done!${NC}"
