# Changelog

## 0.18.0

- Fixed the title-bar close button so it closes the complete addon dashboard.
- Made Roster Management calculate visible records from the current window height.
- Tightened the minimized Loot Master bar so Exit LM Mode and Restore fit inside it.
- Removed Scan again from Loot Master Mode and reduced its width to 380-420 pixels.
- Moved the raid scrollbar inward and narrowed expanded loot content to stay inside the frame.
- Added editable LM opacity and Out of focus opacity percentage settings to full Raid Management.
- Applied out-of-focus opacity to the complete addon and treated 100% as no transparency change.

## 0.17.0

- Added Loot Master minimize and restore controls.
- Collapsed minimized Loot Master Mode to a compact bar containing only exit and restore actions.
- Reduced Loot Master Mode to a constrained 400-460 pixel width.
- Removed the Filters label and tightened filter, mode, scan, search, and table columns.
- Reduced the automatic loot-detail expansion height to remove excess bottom space.
- Added a confirmation-protected Reset loot action to full Raid Management.

## 0.16.1

- Fixed the WoW 1.12 Lua 5.0 `too many upvalues` load error in Raid Management.
- Moved newly referenced dashboard controls to named global frames to stay below the 32-upvalue function limit.

## 0.16.0

- Kept expanded Raid Management row text fully highlighted like Roster Management.
- Matched Raid Management filter controls to the Roster Management styling.
- Moved the close button inside the title bar with consistent padding.
- Rebuilt the Loot Master toolbar as one compact row containing filters, mode, scan, and search.
- Hid the Group column and Import SR action in Loot Master Mode.
- Reduced Loot Master outer and inner margins and tightened its remaining columns.
- Reduced minimum window sizes, including a Loot Master height that still shows at least three rows.
- Temporarily expands a short Loot Master window for loot details and restores its previous height on collapse.

## 0.15.0

- Sorted expanded Guild Statistics members by guild rank and then by name.
- Increased space for rank names in statistics detail rows.
- Added alternating row colors to statistics summaries, expanded members, and Raid Management.
- Highlighted expanded statistics summaries consistently with selected roster members.
- Reduced the minimum normal and Loot Master window sizes.
- Tightened Loot Master margins and column widths while keeping labels on one line.
- Hid attendance export and scan metadata in Loot Master Mode.
- Changed inactive Loot Master opacity to 30% and detect hover against the complete addon bounds.

## 0.14.1

- Replaced proportional UI scaling with native independent width and height resizing.
- Kept the resize corner attached to the cursor and persisted normal and Loot Master window sizes separately.
- Made Loot Master Mode open in a compact layout at 50% opacity.
- Restored full opacity while hovering over Loot Master Mode and returned to 50% when leaving it.
- Kept the resize grip available in Loot Master Mode and adjusted visible raid rows to its compact height.
- Moved and reduced the top-right close button so it fits cleanly inside the dashboard frame.

## 0.14.0

- Added explicit success feedback after Refresh Data finishes loading guild data.
- Added a toggleable minimalist Loot Master Mode to Raid Management.
- Added a bottom-right resize grip that scales the complete dashboard between safe minimum and maximum sizes.
- Persisted the selected dashboard scale in SavedVariables.
- Fixed raid row left padding and item icon retrieval for the WoW 1.12 `GetItemInfo` result layout.
- Added deferred icon refresh when item information becomes available after the loot message.

## 0.13.1

- Rebuilt Guild Statistics drill-downs as rows in the main class and rank tables.
- Made each statistics table scroll as one bounded list without overlay panels.
- Fixed the WoW 1.12 FauxScrollFrame error when expanding Raid Management loot.

## 0.13.0

- Added expandable Raid Management rows with each member's recorded loot.
- Added automatic raid loot tracking from loot chat messages.
- Displayed loot with item icons, names, and aggregated quantities.
- Preserved recorded loot when rescanning the same raid instance.
- Kept expanded raid records within the full-height scrollable table area.

## 0.12.1

- Changed Guild Statistics details from floating overlays to toggleable inline expansions.
- Aligned the Name, Rank, and optional Level columns in expanded statistics.
- Made Raid Management filter dropdowns fit their longest option on one line.
- Reduced and repositioned Raid Management action buttons.
- Kept Raid Management column headers on one line.
- Reserved table space for expanded roster actions so all records remain inside the scrollable area.

## 0.12.0

- Added a shared progress bar for guild, roster export, raid, and quiet refresh scans.
- Moved new SavedVariables snapshots to `rosterData` and `raidAttendance`.
- Reduced raid attendance exports to attendance-relevant fields only.
- Added expandable, scrollable member details to class and rank statistics.
- Added SR and an Import SR placeholder to Raid Management.
- Added Raid Management search, Class/Rank filters, and sortable table columns.
- Added three-state sorting: ascending, descending, and default.
- Unified primary content margins across dashboard sections.

## 0.11.1

- Reworked guild roster loading around a shared completion check used by both events and the retry timer.
- Increased the roster loading window to 15 seconds with six throttled requests.
- Validate that every reported guild member has loaded before accepting a snapshot.
- Restore the relevant scan controls cleanly after a timeout.

## 0.11.0

- Show only Scan Guild Data before the first roster scan and reveal Export Roster afterward.
- Standardized dashboard action buttons around the compact Raid Management style.
- Increased spacing around roster search, filters, sorting guidance, and table headers.
- Narrowed filter dropdowns to match their option content.
- Removed statistics charts and rebuilt class and rank results as aligned table rows.
- Separated statistics section headings from their values and increased row spacing.
- Removed the About heading and vertically centered its text block beside the artwork.

## 0.10.0

- Removed the separate Export Roster navigation page and moved export into Roster Management.
- Preserved the original aspect ratio of the About artwork and removed the description row.
- Reworked Select all and action controls with a compact custom button style.
- Aligned Search with roster filters and moved the sorting hint to the left above the table.
- Reduced spacing between roster headers and the first member row.
- Removed the Raid Management enrichment subtitle and refined raid action buttons.
- Added class distribution bars and cleaned up Guild Statistics controls.

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
