# DropKit App Store Submission Draft

## App Basics

- App name: `DropKit`
- Subtitle: `Menu bar shelf and clipboard history`
- Primary category: `Utilities`
- Platform: `macOS`
- Target version: `1.0.6`
- Bundle ID: `com.dropkit.DropKit`

## Description

DropKit is a lightweight macOS menu bar utility for quick file staging and clipboard history.

Use the floating shelf to hold files temporarily while you work, then drag them out when you need them. Keep recent clipboard items close at hand, search them instantly, and pin the ones you reuse often.

DropKit focuses on fast access, low overhead, and native macOS behavior for everyday multitasking.

## Keywords

`clipboard,menu bar,files,shelf,productivity,drag and drop`

## What's New in 1.0.6

- More reliable watched-folder monitoring, with safeguards against stale file reports.
- Smarter thumbnail memory handling that releases cached images under system memory pressure.
- Smoother shelf scrolling and selection with lazy-loaded thumbnails.
- General stability and performance improvements.

## Accessibility Permission Explanation

DropKit uses Accessibility permission only for the optional shake gesture used while dragging files. If Accessibility permission is not granted, DropKit does not register its global drag/shake event monitors. The app still works through the menu bar, keyboard shortcuts, clipboard history, and user-selected watched folders.

## Review Notes

- DropKit is a menu bar app for temporary file staging and clipboard history.
- Accessibility permission is used only to observe global drag-related mouse movement for the optional shake-to-show shelf gesture.
- DropKit checks Accessibility permission before registering global drag/shake monitors and does not start those monitors when permission is missing.
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
  - clipboard entries from common password managers are skipped by default, and password-manager concealed pasteboard types are ignored
  - watched-folder access is user-selected and local
  - no analytics, crash SDK, or third-party telemetry is currently integrated

Re-check this section after any future SDK or network integration.

## URLs To Prepare

Hosted on GitHub Pages (gh-pages branch of this repo), independent of the xiaochens.com homepage migration:

- Support URL: `https://chenyuxiaojin.github.io/DropKit/support.html`
- Privacy Policy URL: `https://chenyuxiaojin.github.io/DropKit/privacy.html`

Both are static pages (source in `docs/app-store/web/`). The privacy page states clearly that DropKit collects no data; the support page lists a contact email for user issues. To update them, edit the source and run `docs/app-store/web/deploy.sh`.

## Screenshot Plan

- Menu bar main menu
- Clipboard history panel with search
- Floating shelf in collapsed state
- Floating shelf in expanded state
- Settings window showing shortcuts and watched-folder configuration
