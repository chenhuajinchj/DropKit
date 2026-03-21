# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Reworked watched-folder access to use sandbox-compatible bookmarks for Mac App Store submission.
- Removed the in-app GitHub update path and updated release/distribution documentation for App Store distribution.
- Added submission notes, privacy draft content, and stronger test coverage for folder bookmark persistence.

## [1.0.5] - 2026-03-21

### Fixed
- Eliminated disk writes during thumbnail generation to avoid feedback loops in watched folders.
- Improved sandbox readiness for folder monitoring and App Store distribution.

## [1.0.4] - 2026-03-13

### Fixed
- Reduced repeated object creation and unnecessary I/O in clipboard handling.
- Prevented `ThumbnailCache` from creating an infinite loop when the watched folder changed.

## [1.0.3] - 2026-03-07

### Fixed
- Fixed the search field so Chinese IME space-selection no longer triggers preview unexpectedly.

## [1.0.2] - 2026-02-06

### Changed
- Refined the settings layout for a clearer preferences experience.

### Added
- Added update-checker infrastructure and simplified HTML clipboard conversion.

### Fixed
- Removed the status item from the expanded shelf view for a cleaner workspace.

## [1.0.0] - 2026-02-04

### Added
- **Shelf Feature**
  - Mouse shake detection to summon floating shelf while dragging
  - Drag and drop file staging
  - Grid and list view modes
  - Collapsed and expanded states
  - File thumbnails and metadata display
  - Quick Look preview support
  - Context menu with "Show in Finder" option

- **Clipboard History**
  - Automatic clipboard monitoring
  - Support for text, rich text, images, files, and URLs
  - Search and filter functionality
  - Pin important items
  - Privacy mode to pause monitoring
  - Configurable history limit

- **Menu Bar Integration**
  - Status bar icon with dropdown menu
  - Quick access to all features
  - Keyboard shortcuts

- **Settings**
  - General preferences (launch at login, etc.)
  - Shelf customization (sensitivity, appearance)
  - Clipboard settings (history limit, excluded apps)
  - Keyboard shortcut configuration
  - About section with version info

- **UI/UX**
  - Native macOS design with vibrancy effects
  - Dark mode support
  - Hover effects and smooth animations
  - Floating panel behavior
