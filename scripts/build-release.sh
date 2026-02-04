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

# Step 1: Clean previous build and remove extended attributes
echo -e "\n${YELLOW}[1/5] Cleaning previous build...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$RELEASES_DIR"

# Remove resource forks, .DS_Store, and extended attributes
echo -e "${YELLOW}Removing .DS_Store files and extended attributes...${NC}"
find "$PROJECT_ROOT" -name ".DS_Store" -delete 2>/dev/null || true
find "$PROJECT_ROOT" -name "._*" -delete 2>/dev/null || true
xattr -cr "$PROJECT_ROOT/DropKit" 2>/dev/null || true

# Step 2: Build Release version (using build instead of archive)
echo -e "\n${YELLOW}[2/5] Building Release version...${NC}"
xcodebuild -project "$XCODE_PROJECT" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION="$VERSION" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build 2>&1 | grep -E "(Compiling|Linking|Build|error:|warning:)" || true

# Find the built app
APP_PATH="$BUILD_DIR/DerivedData/Build/Products/Release/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: Build failed - $APP_NAME.app not found${NC}"
    exit 1
fi

echo -e "${GREEN}Build completed successfully${NC}"

# Step 3: Clean extended attributes from built app and re-sign
echo -e "\n${YELLOW}[3/5] Preparing app for distribution...${NC}"
xattr -cr "$APP_PATH"
codesign --force --deep --sign - "$APP_PATH"
echo -e "${GREEN}App prepared and signed${NC}"

# Step 4: Create ZIP
echo -e "\n${YELLOW}[4/5] Creating $APP_NAME-$VERSION.zip...${NC}"
rm -f "$RELEASES_DIR/$APP_NAME-$VERSION.zip"
ditto -c -k --keepParent "$APP_PATH" "$RELEASES_DIR/$APP_NAME-$VERSION.zip"
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

# Summary
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\nOutput files in ${YELLOW}$RELEASES_DIR${NC}:"
ls -lh "$RELEASES_DIR/$APP_NAME-$VERSION".* 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'

echo -e "\n${GREEN}Done!${NC}"
