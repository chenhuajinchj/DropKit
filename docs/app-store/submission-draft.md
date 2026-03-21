# DropKit App Store Submission Draft

## App Basics

- App name: `DropKit`
- Subtitle: `Menu bar shelf and clipboard history`
- Primary category: `Utilities`
- Platform: `macOS`
- Target version: `1.0.5`

## Description

DropKit is a lightweight macOS menu bar utility for quick file staging and clipboard history.

Use the floating shelf to hold files temporarily while you work, then drag them out when you need them. Keep recent clipboard items close at hand, search them instantly, and pin the ones you reuse often.

DropKit focuses on fast access, low overhead, and native macOS behavior for everyday multitasking.

## Keywords

`clipboard,menu bar,files,shelf,productivity,drag and drop`

## What's New in 1.0.5

- Improved thumbnail and clipboard performance
- Fixed watched-folder feedback loops caused by thumbnail generation
- Improved overall stability and file-monitoring behavior

## Accessibility Permission Explanation

DropKit requests Accessibility permission only for the optional shake gesture used while dragging files. Without this permission, the app still works through the menu bar and keyboard shortcuts.

## Review Notes

- DropKit is a menu bar app for temporary file staging and clipboard history.
- Accessibility permission is used only to observe global drag-related mouse movement for the optional shake-to-show shelf gesture.
- Core app functionality remains available without Accessibility permission:
  - menu bar access
  - keyboard shortcuts
  - clipboard history
  - watched-folder import
- The Mac App Store version does not include an external updater or GitHub download flow.
- Watched folders are user-selected explicitly through an open panel and stored using sandbox-compatible bookmarks.

## App Privacy Draft

Current draft based on the local codebase:

- Data collection: `No data collected`
- Rationale:
  - clipboard history is stored locally on device
  - watched-folder access is user-selected and local
  - no analytics, crash SDK, or third-party telemetry is currently integrated

Re-check this section after any future SDK or network integration.

## URLs To Prepare

- Support URL: required in App Store Connect
- Privacy Policy URL: required in App Store Connect

## Screenshot Plan

- Menu bar main menu
- Clipboard history panel with search
- Floating shelf in collapsed state
- Floating shelf in expanded state
- Settings window showing shortcuts and watched-folder configuration
