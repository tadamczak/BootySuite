# Mukla Officer Suite

## Release channels

- `master` and tags contain production releases.
- `develop` contains test builds such as `0.3.0-dev.1`.
- Development build numbers do not represent missed production releases.

An addon for the World of Warcraft 1.12.1 client. The initial version provides:

- a minimap button that opens the dashboard,
- `/mos`, `/mos status`, `/mos minimap`, and `/mos hide` commands,
- a main window displaying the last saved guild roster,
- aligned roster columns with scrolling for the complete member list,
- dashboard navigation with dedicated roster, export, and about pages,
- sortable roster columns and full-field search,
- expandable roster member actions with confirmed promote and demote controls,
- collapsible roster filters for class and guild rank,
- manually refreshed shared guild data for roster and statistics views,
- guild class and rank statistics with a level 60 filter,
- Raid Management snapshots enriched with guild roster data,
- attendance snapshots exported with `Export-Attendance.ps1`,
- roster export controls integrated directly into Roster Management,

The addon follows semantic versioning. The installed version is defined in `MuklaOfficerSuite.toc`, displayed in the dashboard, and stored with every guild roster scan.

New snapshots are stored under `MuklaOfficerSuiteDB["rosterData"]` and `MuklaOfficerSuiteDB["raidAttendance"]`.

Raid Management records loot received after the raid roster has been scanned. Click a raid member to expand or collapse their aggregated item list.

Loot Master Mode hides the dashboard navigation, title chrome, attendance export, and scan metadata while keeping the raid controls and table visible. It opens as a compact 30%-opacity window and becomes fully opaque while the cursor is anywhere inside the addon. Drag the bottom-right grip to resize width and height independently; normal and Loot Master sizes are saved separately.

Its compact toolbar keeps filters, the mode toggle, scan, and search on one line. The Group column is hidden. Expanding loot temporarily increases a window that is too short and restores the previous height when the row is collapsed.

Use Minimize to collapse Loot Master Mode to an exit/restore bar. Full Raid Management also provides Reset loot, with confirmation, to clear every recorded item from the current attendance snapshot.

Full Raid Management exposes LM opacity and Out of focus opacity percentage fields. Values are clamped to 0-100; 100 keeps the window fully opaque.

Turning off Loot Master Mode restores the full dashboard at the center of the screen. Roster and statistics tables adapt their visible layout to the resized dashboard.

The Performance page reports scoped MOS allocations and calls, total Lua UI memory, garbage-collection behavior, FPS and frame time, latency, event and UI refresh rates, scan timing, and compact saved-data counters. Its responsive layout uses the available panel width. Sampling runs only while Performance, Live Monitor, or an active diagnosis needs it.

Click Total UI memory to open a sortable memory breakdown for all addons supported by the client. Open Live Monitor creates a small movable FPS, frame-time, latency, and memory window that can be minimized independently. The main dashboard title bar also provides full-window minimization.

The left navigation can be collapsed or replaced with top tabs. A shared bottom status bar contains scan progress and the current Roster/Raid Live Tracking states. Settings persist layout, raid-view, color, and opt-in chat logging preferences.

Roster Management can switch between notes and Guild-style player-status columns. It supports zone and last-online data, filtering offline members, muted offline rows, guild invitations, Guild Information, and Message of the Day editing. Raid Management provides configurable list and draggable group views, online state, leader/assistant/Loot Master markers, resettable filters, and player actions. Its event-driven tracking runs only while the page is active.

## Installation

Copy the top-level `MuklaOfficerSuite` addon directory into `Interface/AddOns/`, so the TOC file is located at:

`Interface/AddOns/MuklaOfficerSuite/MuklaOfficerSuite.toc`

After logging in, open the dashboard with `/mos`. In `Roster Management`, click `Export Roster`, then confirm `Reload now` to write the roster to disk. The addon does not scan automatically on login or when the guild changes. The client writes the data to disk during `/reload` or logout in:

`WTF/Account/<ACCOUNT>/SavedVariables/MuklaOfficerSuite.lua`

Officer notes are saved only when the logged-in character has permission to read them.

The addon uses a load-ordered modular architecture compatible with the WoW 1.12 Lua runtime. `Core` owns the namespace, database defaults, and module lifecycle; `Services` owns roster, raid, and loot data; `UI` owns reusable presentation components. Feature pages register a consistent `Show`, `Hide`, `Refresh`, and optional `OnResize` lifecycle. No runtime `require` implementation is needed because the TOC defines module load order.

The repository layout keeps game files separate from project configuration and tools:

```text
MuklaOfficerSuite/          # IntelliJ project root
|-- MuklaOfficerSuite/      # Directory copied to Interface/AddOns
|   |-- MuklaOfficerSuite.toc
|   |-- MuklaOfficerSuite.lua
|   |-- Core/
|   |-- Services/
|   |-- UI/
|   |-- Modules/
|   `-- Textures/
|-- Deploy-Addon.ps1
|-- Tools/
|-- README.md
`-- .idea/
```

## Deployment

Run `Deploy-Addon.ps1` to copy only the required addon files to:

`C:\Gry\OctoWoWPvP\Interface\AddOns\MuklaOfficerSuite`

## Screen capture shortcut

`Tools/Capture-LatestScreen.ps1` captures the monitor containing the mouse pointer to `Screenshots/latest-screen.png`. A desktop shortcut can run it globally with `Ctrl+Alt+F12`; move the pointer onto the WoW monitor before pressing the shortcut.

`Tools/Toggle-DiagnosticCapture.ps1` starts or stops a temporary diagnostic recording of the rightmost monitor used for WoW. It stores a short sequence of JPEG frames under `Screenshots/recording-frames`; the frames are removed after analysis.

`Tools/DiagnosticCaptureService.ps1` can remain running in the background and accepts local start/stop flags, allowing repeated voice-controlled recordings without repeated Windows process approvals.

## CSV export

After saving and reloading in game, double-click `Export-Roster.cmd` or `Export-Attendance.cmd`. The launcher keeps its window open, reports any error, and writes the UTF-8 CSV file to `exports/`.

The matching `.ps1` files can still be run directly from PowerShell. They automatically locate the newest `MuklaOfficerSuite.lua` under the game's `WTF/Account` directory.

For a CSR export, join a raid, use `Scan & Save` on the CSR page, confirm the reload, and run `Export-CSR.ps1`.

An explicit input or output path can be supplied when needed:

```powershell
.\Export-Roster.ps1 -InputPath "C:\path\to\MuklaOfficerSuite.lua" -OutputPath "C:\path\to\roster.csv"
```
