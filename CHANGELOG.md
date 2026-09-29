# Changelog

## 0.5.0-dev.26 - 2026-09-29

- Remove empty filter-row spacing and fix main-window width limits after Loot Master transitions.
- Nest profile options under General; align Settings indentation, reduce text/checkbox sizes and correct current-profile colors.

## 0.5.0-dev.25 - 2026-09-29

- Fix hidden roster filters excluding every member; restore white centered filter labels.
- Move Refresh Data after Export Roster and reduce the main window minimum width to 350.

## 0.5.0-dev.24 - 2026-09-29

- Add roster column, filter and column-header visibility preferences with profile support.
- Compact the Settings header and remove resize artwork and its reserved footer space.

## 0.5.0-dev.23 - 2026-09-29

- Unify icon and text tab borders, anchor all tabs to the content edge, and retain hover shading on the selected tab.
- Match dropdown panel backgrounds and limit selected tab overlap to two pixels.

## 0.5.0-dev.22 - 2026-09-29

- Connect the selected navigation tab to the content frame and recess inactive tabs with darker borders and spacing.

## 0.5.0-dev.21 - 2026-09-29

- Move roster actions below the aligned guild MOTD frame and lower window minimum sizes.
- Add Bottom Tab view and shared gold tab borders open toward the content.

## 0.5.0-dev.20 - 2026-09-29

- Add optional status/version bar, header logo and header name visibility settings.
- Reclaim hidden chrome space, keep corner resizing without an icon, and compact the header when both decorations are hidden.

## 0.5.0-dev.19 - 2026-09-29

- Add multi-select exception test presets to LM Config.
- Match LM labels, gold titles and toolbar borders; show expanded Loot Master Mode title and label-only exception tooltip.

## 0.5.0-dev.18 - 2026-09-29

- Keep LM Config fields and dropdown options above their panel backgrounds after reparenting.

## 0.5.0-dev.17 - 2026-09-29

- Add Auto Loot, Shift Loot and Off modes to LM Config.
- Add exact rarity selection and case/whitespace-insensitive item-name exceptions, including profile support.

## 0.5.0-dev.16 - 2026-09-29

- Preserve known update availability across repeated checks without duplicate notifications.
- Refresh roster detail clipping after resize settles and ignore programmatic scrollbar callbacks during layout.

## 0.5.0-dev.15 - 2026-09-29

- Keep expanded roster details and scrolling stable during window resize.
- Refresh selected menu layout labels and add optional icon tabs with saved profile support.

## 0.5.0-dev.14 - 2026-09-29

- Softened hover captions and radial highlights; standardized Classic button borders on dropdown chrome.
- Restored sidebar hover, matched menu/arrow and Guild Information title gold, and capped roster details width.

## 0.5.0-dev.13 - 2026-09-29

- Added a symmetric center-out red-button hover gradient.
- Saved-raid borders now use the same surface and gold hover as dropdown options.

## 0.5.0-dev.12 - 2026-09-29

- Red action buttons now use white hover text and an inset gradient highlight while keeping their resting border unchanged.
- Removed native stretched press/disabled artwork from saved-raid selection rows.

## 0.5.0-dev.11 - 2026-09-29

- Fixed WoW 1.12 texture ownership errors interrupting Raid Management and skin refresh.
- Restored textured red action buttons with independent first-display hover.
- Kept expanded roster details within short windows with scrollable note content.

## 0.5.0-dev.10 - 2026-09-29

- Rebuilt red action and saved-raid button visuals with solid borders and native hover/pressed states.
- Matched LM and Master Loot title gold, reduced the Reycoin icon and replaced side-panel square grips with diagonal resize handles.

## 0.5.0-dev.9 - 2026-09-29

- Fixed Raid Settings accordion spacing and profile feedback for save-before-switch actions.
- Reduced Settings text and checkbox sizes, with compact Reset to default buttons.

## 0.5.0-dev.8 - 2026-09-29

- Matched Settings frame spacing and resize grip to dashboard chrome; aligned General and Layout controls.
- Kept red button surfaces persistent and changed roster hover/expanded highlights to neutral gray.

## 0.5.0-dev.7 - 2026-09-29

- Added a visible Settings resize control and a framed inner content area.
- Changed level-1 headings to gold and made multiselect labels toggle their checkboxes across roster, CSR and raid statistics filters.

## 0.5.0-dev.6 - 2026-09-29

- Fixed roster name padding after refresh and Class/Rank dropdown hit testing.
- Kept expanded rows highlighted, moved rank arrows to the top-right and matched guild action buttons to the red/gold Quit style without icons.

## 0.5.0-dev.5 - 2026-09-29

- Fixed lower-row expansion, full-width member details and row text margins.
- Hid unavailable guild actions without gaps and made the context menu compact and cursor-relative.
- Reworked member information, rank arrows and permission-aware note panels with Accept/Cancel editors; removed extra member buttons.

## 0.5.0-dev.4 - 2026-09-29

- Added permission-aware guild controls, member details, editable notes and rank arrows in Roster Management.
- Added right-click Whisper, Invite, Target, Report and Ignore actions, row hover and name padding.
- Reduced spacing between Profile labels and values.

## 0.5.0-dev.3 - 2026-09-29

- Simplified Profile to three rows with compact action buttons and gold inline feedback; Save sits beside the current profile name.
- Save commits focused percentage edits before taking a snapshot; UI General places Skin above the checkboxes.

## 0.5.0-dev.2 - 2026-09-29

- Fixed LM Config checkbox persistence and grouped roster/raid settings under the UI accordion; all sections start collapsed after reload.
- Reworked profile controls with current identity, selection-based actions, confirmed deletion and save-before-switch prompts.

## 0.5.0-dev.1 - 2026-09-29

- Added named Settings profiles with Add, Save, Load and copyable Export, plus collapsible Profile, UI and Debug sections.
- Fixed persistent saved-raid selection borders and standardized the Reycoin resize control and spelling.

## 0.4.1-dev.4 - 2026-09-29

- Unified close, minimize and maximize controls across addon windows.
- Added three heading sizes and shared component/column labels with white, gold and orange variants.
- Load text is gray when disabled and white when enabled.

## 0.4.1-dev.3 - 2026-09-29

- Halved saved raid row width, preserved text padding and restored Load hover feedback.
- Kept chat item tooltips above the dashboard and restored all controls when exiting minimized LM Mode.

## 0.4.1-dev.2 - 2026-09-29

- Centralized UI construction in isolated component factories with explicit dependencies, preserving existing workflows and appearance.

## 0.4.1-dev.1 - 2026-09-28

- Centered the Settings gear, padded the minimize glyph and matched dashboard/About text to menu gold.
- Kept the minimized dashboard at its last dragged position while preserving expanded window geometry.

## 0.4.0 - 2026-09-28

- Added a movable, resizable Settings window with session-only accordions and UI visibility preferences.
- Added configurable Raid Group View sizing, spacing, columns and text sizes.
- Added peer version discovery with update status and manual checks in About.
- Fixed Settings scrolling, dropdown overlays, input handling, separators and label contrast.
- Fixed tab navigation, About layout, Loot Master cleanup and restored corpse rolls.
- Published addon files directly at repository root for installation.

## 0.3.0 - 2026-09-27

- Added a regression-integrated static-analysis gate for Lua compatibility, architecture boundaries, and performance-sensitive patterns.
- Added critical-journey E2E coverage for raid persistence, recalculation, failures, migration, and scale limits.
- Added automated statement-line coverage reporting for the complete Lua test suite.
- Completed automated E2E coverage for Performance, About, and addon manifest composition.
- Added E2E coverage for native raid actions and session behavior across raid-context changes.
- Added E2E coverage for Settings, Navigation, and Dashboard state, layout, minimization, and resize cleanup.
- Added E2E coverage for Roster Management and Guild Statistics scanning, filters, refreshes, and lifecycle cleanup.
- Added E2E coverage for Raid Management session actions, history, save options, tracking, and cleanup.
- Added E2E coverage for CSR and Raid Statistics filters, selection, expansion, navigation, and cleanup, and fixed record collapse and deselection.
- Added integration coverage for dropdown primitives, text-input focus, and date selection.
- Added integration coverage for reusable prompts, item lists, editors, and read-only dialogs.
- Added a reusable WoW frame double and integration coverage for shared UI controls.
- Added unit coverage for pure feature-module logic and established a maintained public API coverage matrix.
- Expanded unit coverage for RaidRes persistence, test tools, commands, and guild scan state transitions.
- Added focused unit coverage for core lifecycle, persistence, roster, raid statistics, CSR calculations, and reusable UI helpers.
- Added the modular raid, loot, statistics, CSR, UI, and diagnostics workflows.
- Added the develop/production release process and limited repository contents to release files.
- Added the production quality gate and refreshed the user-facing README.
- Fixed distorted proportions in the README visual header.
- Expanded the README with module usage and a complete raid-session guide.
- Added linked README navigation and mandatory README review for future changes.
- Defined mandatory unit, E2E, regression, and production test responsibilities.
- Defined full regression as every automated and required in-game test without scope-based shortcuts.

## 0.20.0

- Introduced a shared addon namespace and an extensible module registry with consistent lifecycle methods.
- Extracted database access and roster, raid, and loot persistence into dedicated core and service files.
- Added reusable theme, button, dropdown, search box, and scroll-table components.
- Migrated Roster Management, Raid Management, and Guild Statistics to shared UI calculations without changing saved-data formats.
- Added a lightweight Performance module with memory growth, session peak, FPS, frame time, latency, MOS event and UI refresh rates, scan timing, and saved-data counters.
- Added concise help tooltips to every metric and the baseline control, removed the redundant manual refresh, and fixed early addon-memory detection and sub-kilobyte rounding.
- Split Performance into addon and global sections, added expandable per-addon memory details, a movable live monitor, and full main-window minimization.
- Added responsive Performance columns, scoped MOS allocation counters, calls-per-second reporting, and richer diagnosis results.
- Added collapsible navigation, a shared bottom status/progress bar, compact window controls, and a Configuration page with opt-in chat logging.
- Expanded Roster Management with offline filtering, muted offline rows, zone and last-online data, Guild-style column modes, guild information actions, and MOTD/information editors.
- Expanded Raid Management with responsive columns, online status, leader/assistant markers, resettable filters, and inline leader, assistant, removal, report, and ignore actions.
- Replaced periodic raid table rebuilding with event-driven live tracking to reduce CPU use and transient allocations.
- Completed the architecture refactor: the root file now only composes modules and performs legacy migration, while dashboard chrome, dialogs, commands, events, roster UI, raid UI, settings, and domain services live in their owning layers.
- Reused Performance operation rows and metric buffers and removed per-drag handler allocation from dashboard resizing and the minimap button.

## 0.19.6

- Reduced and unified the Roster Management content margins.
- Recalculate the roster after its anchored page reaches the final resized dimensions.
- Extended roster stripes and columns farther toward the right edge.

## 0.19.5

- Extended roster rows closer to the right and bottom edges of the data panel.
- Matched the roster scrollbar height to the visible record area.
- Aligned player names with the Name column header.
- Added local voice-controlled diagnostic screen capture helpers.

## 0.19.4

- Expanded Guild Statistics and Raid Management row pools so resized windows use the available table height.
- Hidden statistics and raid scrollbars whenever every visible record fits in the table.
- Reduced safe bottom spacing in Raid Management and kept the scan summary on one line.
- Added double-click CSV export launchers that keep the result or error visible.

## 0.19.3

- Increased the Roster Management row pool from 13 to 25 records.
- Filled available vertical table space while preserving a consistent safe bottom margin.
- Calculated expanded-row capacity separately so member actions never push records outside the frame.

## 0.19.2

- Refreshed the active page continuously while resizing and once more when resize ends.
- Made responsive roster rows, columns, action panels, and text widths update immediately with the window.
- Kept the roster scrollbar visually attached to the resized table edge.
- Added click-outside dismissal to Raid Management Class and Rank dropdowns.

## 0.19.1

- Limited LM opacity and out-of-focus opacity behavior strictly to Loot Master Mode.
- Kept the Loot Master Mode button hidden until a raid scan has completed.
- Automatically adjusted the raid scroll offset so a clicked member remains visible when expansion reduces the table to one row.

## 0.19.0

- Centered the full dashboard whenever Loot Master Mode is turned off.
- Clamped the dashboard to the screen where supported by the WoW 1.12 client.
- Made Roster Management column widths, row widths, action panels, and text truncation follow the current window width.
- Kept the roster scrollbar aligned with the expanded table rather than detached from fixed-width rows.
- Moved Only level 60 beside Refresh Data in Guild Statistics.
- Shifted statistics panels upward and made their height and visible row capacity follow the window height.

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
