# Changelog

## 0.5.1

- Rebuilt the main window chrome with the original WoW dialog border texture.
- Restored the thick metallic edges and corner ornaments used by the reference UI.
- Removed border tinting that made the original artwork appear flat and dark.
- Unified the sidebar and content outlines with the neutral reference-frame palette.

## 0.5.0

- Added expandable member actions directly below the selected roster row.
- Added click-again deselection behavior.
- Replaced prominent action buttons with compact contextual controls.
- Added current-version fallback for rosters saved before version metadata existed.
- Simplified the outer window border to better match the reference layout.

## 0.4.1

- Fixed roster row clicks on WoW 1.12 by using button widgets instead of generic frames.

## 0.4.0

- Added selectable roster rows with persistent visual highlighting.
- Added confirmed guild member promotion and demotion actions.
- Added permanent sort indicators and sorting tooltips to sortable columns.
- Refined the window chrome and increased background artwork visibility.

## 0.3.0

- Added sidebar navigation with Roster Management, Export Roster, and About pages.
- Added roster sorting by name, level, class, and rank.
- Added full-field roster search.
- Added a dedicated Scan & Save workflow with last-scan information.
- Added a custom translucent dashboard background and refreshed visual styling.

## 0.2.2

- Added automatic guild roster retries when the WoW 1.12 roster cache is not ready after the first request.

## 0.2.1

- Replaced the asynchronous reload timer with a user-confirmed reload dialog for WoW 1.12 compatibility.

## 0.2.0

- Added aligned, scrollable guild roster columns.
- Added separate `Scan` and `Scan & Reload` dashboard actions.
- Added CSV roster export tooling.
- Added addon version, scan timestamp, and scan duration metadata to SavedVariables.

## 0.1.0

- Added the initial dashboard, minimap button, slash commands, and persistent guild roster.
