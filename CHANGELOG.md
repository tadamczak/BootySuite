# Changelog

## 0.9.0

- Added full-height About artwork and expanded the sidebar artwork to its full height.
- Refined compact roster filter controls and moved Select all below filter options.
- Removed pre-scan roster metadata and repositioned the sorting hint above the table.
- Rebuilt Guild Statistics into balanced class and rank panels with clean metadata hierarchy.
- Fixed the stale statistics scan button remaining above loaded results.
- Added Export Attendance to Raid Management with reload confirmation and a CSV conversion script.
- Improved Export Roster instructions and restored a clean left-aligned workflow.

## 0.8.0

- Unified Roster Management and Guild Statistics around one manually refreshed guild snapshot.
- Added shared Scan Guild Data and Refresh Data controls with last-scan timestamps.
- Added graphical filter arrows and click-outside dismissal for filter panels.
- Preserved roster scroll position after promotion and demotion refreshes.
- Refined expanded member spacing and strengthened alternating roster rows.
- Reworked statistics spacing, class icons, typography, and level 60 filter placement.
- Rebuilt raid results with independently aligned table columns.
- Refined the Export Roster layout and scan hierarchy.

## 0.7.0

- Added manual Guild Statistics scanning with a visible percentage progress bar.
- Added a default-enabled level 60 statistics filter and class icons.
- Ordered rank statistics from highest to lowest guild rank.
- Added Raid Management with raid availability detection and a scrollable result table.
- Moved raid scanning out of CSR and left CSR as a placeholder for future tools.
- Increased spacing around expanded roster member actions.

## 0.6.0

- Moved the guild artwork to the navigation sidebar and added a dark content background.
- Added collapsible Class and Rank checkbox filters with Select all controls.
- Refined selected roster rows and compact member action panels.
- Added the Guild Statistics dashboard with class, rank, level, activity, and average-level metrics.
- Added CSR raid scanning enriched with guild data and a dedicated CSV exporter.

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
