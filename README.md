<p align="center">
  <img src="Assets/readme-header.png" width="100%" alt="Sons of Mukla - Mukla Officer Suite">
</p>

# Mukla Officer Suite

Mukla Officer Suite is a World of Warcraft 1.12.1 addon for guild officers and raid leaders. It combines guild management, raid sessions, loot distribution, Soft Reserve, Reycoin, attendance, raid statistics, and CSR in one interface.

## Table of contents

- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Commands](#commands)
- [Guild](#guild)
- [Guild Statistics](#guild-statistics)
- [Raid](#raid)
- [Loot Master Mode](#loot-master-mode)
- [Raid Statistics](#raid-statistics)
- [CSR](#csr)
- [Profiler](#profiler)
- [Settings](#settings)
- [About](#about)
- [How to record raid session](#how-to-record-raid-session)
- [Start or resume the session](#1-start-or-resume-the-session)
- [Import and validate Soft Reserves](#2-import-and-validate-soft-reserves)
- [Configure and announce loot rules](#3-configure-and-announce-loot-rules)
- [Run loot distribution](#4-run-loot-distribution)
- [Monitor the session](#5-monitor-the-session)
- [Save the raid](#6-save-the-raid)
- [Load or review a saved raid](#7-load-or-review-a-saved-raid)

## Installation

1. Copy the `MuklaOfficerSuite` directory into `World of Warcraft/Interface/AddOns/`.
2. Confirm that `MuklaOfficerSuite.toc` is directly inside that directory.
3. Start the game or use `/reload` after updating the addon.

For optional profiling, also copy the separate **BootyProfiler** folder beside MuklaOfficerSuite in Interface/AddOns/. Restart the game after installing or updating the profiler and enable BootyProfiler in the character addon list.

## Basic Usage

Addon tooltips currently use the game's default bottom-right position.

LM config and Reycoin list use the same diagonal resize grip as the main window. Expanded roster details stay inside the window; use the mouse wheel over the details to reach notes when space is limited.

The top-right buttons open Settings, minimize or restore the dashboard, and close it. Minimized addon windows share the same compact header height. Addon windows use matching gold controls: a line minimizes, a square restores, and X closes. The minimized window remembers its dragged position during the current session; restoring returns to the expanded window's previous position.

Left-click the minimap icon to open or close the dashboard, or restore it when minimized. Right-click for a compact gold quick menu with guild dialogs, raid controls, the five latest saved raids, CSR, Profiler, Settings and About. Guild Stats and Raid Stats are inside their Guild and Raid menus. Hover Guild, Raid or Profiler to open its submenu; click the parent to open that page. Hold Shift and drag with the left mouse button to move the icon anywhere on screen; its position survives reloads. **Test Raid** and quick **Load Raid** are unavailable during an active raid session; **New raid** becomes **Open Raid**. Add Member appears only with invite permission. Loot Master shortcuts open their chosen dialog directly.

### Commands

- **Open or close -** Use `/mos`, `/mukla`, `/mos show`, or `/mos open`.
- **Hide -** Use `/mos hide` to close the main window.
- **Manual item roll -** Use `/mos roll [linked item]` for Tmog, OS, MS and RC. Append player names to restrict participants; append types to replace the defaults, for example `/mos roll [linked item] Player1 Player2 SR`.
- **Guild shortcut -** Use `/mos scan` to open Guild and access its scan controls.
- **Saved roster status -** Use `/mos status` to print the number of saved guild members.
- **Minimap button -** Use `/mos minimap` to show or hide the minimap button.
- **Layout diagnostics -** Use `/mos layout` when diagnosing window-layout problems.
- **Client API diagnostics -** Use `/mos capabilities` to report the available client APIs and extension markers. BootyProfiler sessions capture the same information when recording starts.

### Guild

This tab and its quick-menu entry are grey and unavailable when your character is not in a guild.

- **Guild roster -** Browse saved guild members with class, rank, level, zone, notes, online status, and last-online information.
- **Table headers -** Click sortable headings to change order; click again to reverse it.
- **Search and filters -** Narrow the roster by text, class, rank, level, and online state.
- **Member details -** Expand a player to review additional information and available officer actions.
- **Guild actions -** Invite, promote, demote, remove, ignore, report, or manage eligible members according to your permissions.
- **Guild information -** Review or edit Guild Information and Message of the Day.
- **Guild scan -** Refresh and save current guild data when you explicitly request it.

Large guild scans finish in stages; the previous saved roster stays available until the new scan completes. Guild Live Tracking pauses when its view is hidden. An explicitly requested scan can still finish after you close the window.

Expanded roster rows stay highlighted. Guild rows expand with player name, level/class, rank, last online, public and officer notes, and permitted rank arrows. The attached Window style uses compact labels, larger metadata values and smaller padded note displays. Click a note to edit it in an Accept/Cancel window. Officer notes and guild administration controls appear only with the required permissions. Right-click a member for a compact menu beside the cursor with Whisper, Invite, Target, Report or Ignore Player; click outside to close. Report opens a reason form and Submit sends a GM ticket.

### Guild Statistics

This tab is grey and unavailable when your character is not in a guild.

- **Export Guild -** Scan the guild roster and confirm a reload to save it to disk.
- **Member filters -** Filter the saved roster independently by rank, class, exact level, or the `Search...` field. Rank and Class remain as the default captions when every option is active; one selected option is shown by name and larger selections use an `X selected` count. **Select all** toggles every option on or off.
- **Grouping and sorting -** Sort by any column, or group by class, rank, or level. Group rows expand as accordions; sorting applies inside each group.
- **Raw Data -** Toggle the table to review member totals by rank, class, and non-empty level band. Each section starts collapsed and shows its unique member count; Group by is disabled in this view.
- **Visible count -** Review the number of members currently included by the filters beside the Export Guild and Refresh Data actions.

### Raid

- **Raid sessions -** Start a new raid with or without a guild, continue an active session, save it, or load a saved session. Joining a different raid while a session is open asks whether to Continue or Save and End; Continue then offers a separate Refresh choice.
- **Raid type -** Assign Blackwing Lair, Molten Core, Onyxia's Lair, Karazhan10, Zul'Gurub, or Other.
- **Attendance -** Track the raid roster and optionally include attendance when saving statistics.
- **Raid views -** Switch between the member list and a centered, configurable group layout with adjustable sizing, spacing, and typography.
- **Player actions -** Manage raid leader, assistants, removal, reporting, and ignore state.
- **Soft Reserve warnings -** Review compact, movable detail lists for missing SR, imported SR outside the raid, and SR without loot rights without blocking the game interface.
- **Removed Soft Reserves -** Deleting a player's SR returns it to Unassigned Soft Reserves. Refresh, save, load and reload keep it unassigned. Use Fix SR to assign it again; importing new SR replaces the current assignments.
- **Loot rules -** Configure SR, Highly Contested Items, Reycoin, and CSR rights by guild rank.
- **Reycoin list -** Review used Reycoins and pending item trades.
- **Narrow raid windows -** Raid Leader Tools and Loot Master Tools wrap to a left-aligned row. Warnings move below the roster as compact headers when space is limited.
- **Raid header -** The Raid section label has balanced spacing. Wide windows align identity and actions on one row. Narrow windows show Raid ID and saved status first, hide the raid name, and move Issues, Save Raid, End Raid and Raid Info to the second row. At the smallest widths, Save/End show icons and the saved date is available in its tooltip.
- **Saved raids -** Keep up to ten numbered snapshots. Saving requires a unique Raid ID. Loading, editing and saving a historical raid creates a new snapshot under that exact ID while preserving the original.

### Loot Master Mode

Open **Loot Master Tools > LM Mode** to show a separate window while keeping the main addon open. Its top bar has gold **SR** and **Loot Rules** icons beside the configuration controls. The filled dice icon opens New Roll. Their menus offer **Import SR / Share SR Link** and **Set Loot Rules / Share Loot Rules**. Shared rules start with **=== LOOT RULES ===** and abbreviate Highly Contested Items as **HCI** and Reycoin as **RC**. Click outside a menu to close it. The window starts fully opaque when out of focus; Settings can change this preference. The minimized main window keeps its controls on a black background with the project gold frame. Minimize, resize or close the LM window independently. Click a player to expand loot details within the scrollable list; neighboring players remain visible. The gold list icon opens **Reycoin List**. Enter a raid member name and click **Add** (or press Enter) to record a used Reycoin; invalid names show an explanation. **Loot Master Config** has its own close button, supports narrower widths, and colors rarity options by item quality. Config and Reycoin List remain attached when moving LM. **Set Loot Rules** can be minimized without losing unsaved edits.

Loading a saved raid with Live Tracking enabled asks whether to refresh the saved data from the current raid. Choosing No turns Live Tracking off in Settings and the prompt reminds you to enable it again when desired. Officer Wukong and Chimp Banker always use Chimp loot rights regardless of notes or saved loot rank. Officer Wukong appears in the raid list as **Officer (Chimp)**.

In **LM Config**, choose **Auto Loot**, **Shift Loot** (hold Shift when opening the loot source), or **Off**. **Auto Loot Rarity** selects item qualities. **Auto Loot Inclusions** bypasses rarity selection while the mode is enabled; **Auto Loot Exclusions** always takes priority and prevents automatic looting. Both lists accept comma-separated names and case-insensitive `*` wildcards: `Recipe *` matches recipe names, `* Sack of *` matches names containing Sack of, and `* Coin` matches names ending in Coin. Spaces next to `*` are optional. Settings profiles save both lists. **Add Exclusions Preset** supplies MC, Onyxia's Lair, BWL and ZG exclusions; Kara10 remains an empty reserved preset. Changing presets replaces preset-owned entries while preserving other manual entries.

- **Compact workspace -** Keep raid members and loot tools visible in a smaller, resizable window.
- **Loot detection -** Open the roll window from corpse loot or start it manually with `/mos roll [linked item]`.
- **New Roll -** Use Loot Master Tools > New Roll or the dice icon in the Loot Master window. Focus the item field and Shift-click an item in your bags, choose Tmog/OS/MS/RC/SR and leave Open roll checked to admit eligible raid members, or uncheck it and use Add rollers to select participants. Master Looters and raid assistants can organize custom rolls. The window leaves game controls usable.
- **Tied rolls -** Reroll tied results in the same roll type. The warning names the tied players and item; only those players and that type enter the new round.
- **Supported rolls -** Handle SR (102), Reycoin (101), MS (100), OS (99), and Transmog (98).
- **Late rolls -** Accept valid rolls until the item is assigned.
- **Manual winner -** Select any valid roll row before assigning the item.
- **Automatic SR -** Select the only eligible in-raid reserver when no competing SR roll is required.
- **Trade tracking -** Track pending SR or Reycoin delivery when a Transmog winner temporarily receives the item.
- **Roll history -** Review rounds, winners, trades, and prior rolls for the item.

Pending trades survive closing the loot window or refreshing the current roster. Starting, loading or ending a raid cancels its previous pending transactions.

Saved raids retain received loot, completed roll/trade history and used SR/Reycoin rights, even for players who leave before you save. Loading creates an independent copy of that history. Older snapshots retain only information they originally saved. Active awards and unfinished trades stay available. Repeated ordinary loot combines into one quantity entry; separately assigned items and tracked trades keep their own records.

### Raid Statistics

- **Saved raid list -** Browse date-only saved raid rows, select one or several sessions for combined results, or collapse the list to give the result table the full width.
- **Filters -** Filter by raid, date range, session name, or player; calendar choices apply immediately.
- **Raid details -** Review class-colored players, attendance, Soft Reserves, received loot, and stored roll information. With no selected raid, the result table stays empty.
- **Edit -** Change player names, attendance values and SR item IDs, add manual entries, then confirm whether Attendance and CSR are saved.
- **Remove -** Delete a saved raid and recalculate affected statistics.

### CSR

- **CSR overview -** Review unsuccessful Soft Reserves accumulated per player and item.
- **Raid filter -** Include one or more raid types in the calculation.
- **Search -** Find a player or item.
- **Raid history -** Expand a CSR record and scroll through all contributing raids.
- **View raid -** Open the selected contributing raid in Raid Statistics.
- **CSR Test Lab -** Simulate players, ranks, reservations, awards, and elapsed time without changing saved raid data.

### Profiler

- **Optional BootyProfiler -** Install the separate addon beside MOS. Profiler keeps its illustrated background across all views and dims the complete result area while content is selected and shows installation/load information when needed. **Enable** activates an installed addon with a UI reload; it is unavailable when BootyProfiler is missing. **Disable** is at the right of the top toolbar.
- **Minimap shortcuts -** Profiler's quick menu offers Live Monitor, advanced Start/Stop, Reset, Export, a Memory checkbox, Health Check and Enable/Disable at the end. Switching Memory keeps the menu open. A first quick Start records **All Addons**; later starts use your last selected MOS/All profile. Memory applies to the next All Addons scan and cannot change while recording. A missing BootyProfiler makes this menu unavailable. Export recordings before confirming Disable and its UI reload.
- **Advanced Profiler -** Beside **Live Monitor**, choose **Profile MOS**, **Profile All** or **Analyze Login** from Advanced Profiler. Profile views have one **Start / Stop** button. MOS measures selected operations; All also intercepts frame callbacks. Opening or changing views does not start or change a capture. Each view shows its matching capture status and last-scan date/duration. While one profile is recording, the other profile shows a centered notice and its recording controls are disabled; return to the recording profile to stop it.
- **MOS -** Review selected MOS operations, call counts, total/average/maximum times and recent slow calls.
- **Reading results -** Sections start closed on opening or changing views, without saving their expansion state. Expand the tables you need; a short introduction explains what to inspect. Frame callbacks is the main All Addons ranking. While recording, counters update and table rows stay in place; **Update ranking**, the last recording action, refreshes their selection/order. **Stop** shows final rankings. Click any result column to sort; click again to reverse the order. **Only addon results**, beside each table, shows identified addon rows and hides game scripts and unknown sources. Shared game measurements cannot be separated by addon, so their checkbox is grey. Export keeps the complete recording. Hover a summary card or column heading for its meaning.
- **All Addons -** Review intercepted OnEvent/OnUpdate costs by source addon and expandable frame families. Summaries show the minimum, maximum and average valid sampled FPS and network latency across the whole recording. Family and child lists have pages of 50 records. Discovery is gradual; unknown sources and partial coverage are explicit. Refresh memory requests native addon memory statistics when supported.
- **Callback memory -** Set **Memory: ON** before Start in All Addons. **Memory by addon** appears for a memory capture or native snapshot; it groups observed callback heap growth by identified source. **View: Memory** ranks frame families. Unsupported callback measurements show **Not measured**; an asterisk marks totals with unmeasured calls. Growth, net change and peak are shared-memory changes during execution, not owned addon RAM; nested readings overlap.
- **Analyze Login -** Open this view from Advanced Profiler to see the login summary and loading-stage table. Choose its **Analyze Login** action, then **Reload now** or **Later** to arm one capture. It records loading and ten seconds after entering the world, saves the report and stops. Login time ends at first world entry; Window and Net heap delta describe the interval ending at the current row. Earlier loading remains in the baseline.
- **Stop / Disable -** Stop retains the report. Disable stops recording, removes owned callback hooks and disables BootyProfiler with a UI reload. An explicitly started session can continue while the main window is hidden; reload never resumes it automatically.
- **Live Monitor -** Open a movable, resizable summary independently of advanced recording. Its default shape matches the background. It shows integer FPS, current shared Lua memory / current GC threshold, memory change per second, latest observed cleanup and its age, and Health Check. Closing or minimizing it stops these measurements; restore starts a fresh view while an advanced recording continues. It keeps no sample history or saved report.
- **Health Check -** The top-toolbar view assesses the last completed scan, with the recorded evidence, a **Reason** and concrete next steps for each finding. It preserves earlier warnings even if readings recovered before Stop; a new recording keeps the previous assessment. Live Monitor and profile summaries separately show recent conditions. Memory growth and cleanup with pauses need investigation; they do not prove a leak or identify its cause.
- **GC investigation / Export -** Expand **Memory and garbage collection** to inspect memory decreases and slow frames. **Reading interval** is the time between memory checks; **Longest frame pause** is the largest pause observed between them. Neither is GC duration. After Stop, Export stores one bounded advanced report; reload or logout writes it to disk.

Measured heap change refers to the global Lua heap, not total allocations or owned memory. MOS measures selected entry points; All Addons measures intercepted frame callbacks. Source-addon labels identify implementation sources, including shared libraries. XML scripts can omit their addon file and some functions expose no source; those owners remain Unknown. Frame labels may show actual parent/reference context without claiming addon ownership. Native memory by addon is available only when the client exposes its counters. Self time excludes timed nested callbacks, while inclusive times overlap. FPS samples do not prove the cause of a drop. Clock quality and interception overhead need verification on your client.

Statistics, CSR and Profiler adapt their controls and tables to the window size. Guild and raid statistics stack their panels in narrow windows. At very small sizes, scroll the page to reach every section. In Raid Statistics, choosing or clearing a calendar date refreshes the results immediately.

### Settings

**Game UI > Interface > Use MOS as default Raid tab** replaces the game's Raid tab with a compact MOS group view. It works without starting or saving a MOS raid session. The native Raid header keeps its action buttons and shows the MOS minimap logo while this view is selected. Use **Game UI > Layout > Raid** to customize this view independently of the main addon Raid groups; its default shows all eight groups without scrolling. Add Member and Raid Info toggle closed on a second click and close with the native Raid window. Disable the option to return to the standard panel. Raid Info shows your saved instance IDs and reset times; raid leaders and assistants can use Ready Check from Raid Leader Tools.

UI settings group Guild, Raid, Guild Statistics, Raid Statistics, CSR and Profiler in indented sections. New sections contain General and Layout placeholders for future options. Minimizing Settings temporarily narrows it; restoring returns its expanded size. Live Monitor remembers the size chosen by dragging its resize corner, including after a UI reload.

**Addon UI > Guild > General > Player details style** selects **Collapsible** (the default expanded roster row) or **Window**, a compact member panel attached to the right of the main window. Live tracking appears on the same row. The panel shows guild details, editable notes when permitted, rank controls, Remove (with confirmation), and Group Invite. Unavailable rank controls remain visible in grey. The choice is saved in settings profiles. Guild Add Member toggles its dialog closed when clicked again.

**UI > Layout** can hide the status/version bar, guild logo, or addon name and ornaments. These options default to off. **Hide header bar** removes the entire header and moves window controls to a compact row inside the content. In top Tab View the gold outer edge moves below the tabs, which retain their position. Menu type and Use Icon Tabs share one row. With the bottom bar hidden, resize by dragging the bottom-right corner. Hiding both logo and name reduces the header to the window controls. In tab views, narrow headers hide side ornaments and align the title left so window controls remain accessible. These preferences are saved in profiles under **Profile > General**. Hiding every roster filter also removes its empty row.

**Show section header** is in **UI > Guild > Layout > Display**; **Hide section header** remains in **UI > Raid > General**. In Raid it hides the section label while keeping the selected raid name visible.

Under **UI > Guild > Layout**, choose visible columns, filters and column headers. Officer notes require guild permission. Hidden class, rank and search filters do not restrict results. These preferences are saved in profiles. Show Player Status switches between guild columns (name, zone, level, class) and player-status columns (name, rank, notes, last online). Column preferences apply within each mode; both Officer note and its Settings checkbox require permission. Export Guild is in Guild Statistics; Refresh Data and guild actions stay at the bottom of Guild. Refresh Data is hidden while UI > Guild > General > Live tracking is enabled; with tracking disabled it is unavailable only while a scan is pending. MOTD, the table with member counts/status, and guild actions share the standard content frame, with horizontal separators between sections. The main window retains its project gold outer border; header keeps its bottom separator, content keeps horizontal separators, and the status bar keeps its top and right borders. Only the table section stretches when resizing vertically; its counts and status switch stay above the bottom actions, below the table. The guild message wraps to additional lines; guild status remains on one line with text fitted to the available width. Columns share the available width according to their contents. The main window can be narrowed to 350 pixels. Settings uses a compact plain header, one gold outer frame and a horizontal content separator. Resize it by dragging its unmarked bottom-right corner; UI General and Layout expand independently, and its single-line options adapt to up to four measured columns, down to a 350-pixel window.

Guild and Raid filter controls share the framed search input, aligned 24-unit controls, toolbar background and bottom separator. Their redundant Filters caption is omitted.

Under **UI > Layout**, choose **Right side view**, **Top tab view** or **Bottom tab view**. Both tab views reveal **Use Icon Tabs** beside the dropdown. Top Tab view uses a compact window-control strip; tabs overlap it and protrude above the window. Bottom Tab view places navigation below the status bar when visible, or below the content when hidden. Tabs extend beyond the bottom window frame. Top and bottom text tabs use the available window width. Saved raid lists stop growing at 500 UI units. Narrow text tabs shorten Guild Statistics and Raid Statistics to Stats and Profiler to Prof. Text and icon tabs join the content frame; the selected tab keeps its gold outline, white caption and gradient highlight while inactive tabs are recessed. Enable it to replace tab captions with the sidebar icons and matching highlights.

Drag the diagonal bottom-right grip to resize Settings. Multiselect filters can be toggled by clicking either the checkbox or its label.

- **Profiles -** Current profile shows the active configuration as text, with Save beside it. Select a saved profile under Load profile to enable Load, Delete and Export. New profile + Add creates and activates a copy of your current settings; Save updates the current profile, including pending percentage edits. Gold feedback appears beside the action buttons. Only the latest action remains visible; saving before Add or Load shows both results. Load and Add ask whether to save changed settings first. Delete requires confirmation; deleting the current snapshot leaves your live settings available to save again. Export opens saved settings for copying. Profiles exclude guild, raid and loot records.
- **Collapsible sections -** Profile, UI (including Guild and Raid), and Debug start collapsed after reload. Expansion is remembered while playing and when reopening Settings.

- **Resets -** Each Display, Size and Member tile color subsection has Reset to default with confirmation. Reset to defaults at the bottom-right of Settings resets all settings after confirmation, preserving saved profiles, guild data and raid history.
- **Saved raids -** The Raid start screen lists Name, Raid and Time. Use the load or delete icon on each row; New Raid creates a session while grouped in a raid.
- **Appearance -** Open Settings from the gear icon to configure the addon skin, colors, navigation style, and window behavior live. The skins are named **Default** (formerly Classic) and **Classic WIP** (formerly Default). Existing profile appearances are preserved.
- **Settings layout -** Consistent spacing, readable foreground labels, padded overlay dropdowns, full-width separators, and scrolling keep every accordion section accessible; dropdowns close when clicking outside them. Multiselect menus use a bottom **Select All** toggle.
- **Settings window -** Settings reopen from the top with your current saved values. Settings and saved raid lists use the full content width when scrolling is unnecessary; the scrollbar only takes space while needed.
- **Resizable window -** Settings can be resized within the available game screen; long sections remain available through scrolling.
- **Raid group interaction -** Drop a member on another member or on free group background. Hidden role icons release name space; hiding the group border and setting group spacing to zero joins the tiles.
- **Raid group appearance -** Group View > Display can hide the group border independently of its header. Group tile color controls header text, header background and border colors, with its own confirmed reset. These choices are included in settings profiles.
- **Guild preferences -** General contains live tracking and Player details style. Layout groups visibility options under Display and row appearance under Member tile color: class colors, background, main text, hover and Odd record lightness (0-100%). The lightness value brightens even rows toward white while typing; 0% keeps all row backgrounds identical. All Settings accordions start collapsed after reload. Raid Group View and List View have independent lightness fields under Member tile color. Addon UI > Layout groups Menu type under General and header/status visibility under Display; Raid List View groups its controls under Display, Size and Member tile color.
- **Raid -** Configure Loot Master opacity and related raid preferences.
- **Logging -** Enable optional concise addon messages in chat.
- **Reset options -** Restore supported settings to their defaults.

### About

Repeated update checks retain a known newer version until your installed version catches up; repeat responses do not show duplicate notifications.

- **Update notification -** MOS checks once when entering the game and provides **Check for updates!** in About. About shows the current version, checking progress, result, and last successful check. Detection compares complete running versions through private addon traffic with online MOS users and shows a GitHub Releases link for newer builds.

- **Addon information -** Review the installed version and basic project information.
- **About presentation -** Version labels, update state, last check, authorship, and rights information remain readable across supported window sizes.
- **Live Settings window -** Use the gear button to adjust the same Settings controls in a separate window while viewing another module.
- **UI visibility -** Settings can disable the login message or hide the minimap icon.

## How to record raid session

### 1. Start or resume the session

1. Enter the raid instance.
2. If no session is active, choose **Start New Raid** in the reminder.
3. In Raid, enter the session name and select the raid type.
4. Start the raid session and confirm that the current roster is visible.
5. If the session already exists, select it under **Saved raids** and choose **Load** instead.

Leaving the raid group or an observed raid instance does not automatically discard the session. After a short confirmation, choose **Continue Session** to keep working or **End & Save** to finish it. Continuing suppresses repeated prompts while travelling outside that context; returning rearms the next departure. Closing that prompt with the X ends the session without saving.

### 2. Import and validate Soft Reserves

1. Open **Raid Leader Tools** and choose **Import SR**.
2. Paste or import the prepared Soft Reserve data.
3. Review the warning cards in Raid.
4. Use **Info** to inspect affected players.
5. Use **Ping** when the raid must be informed.
6. Use **Fix SR** only for reservations that should be removed.

Warnings distinguish:

- players who have SR rights but no reservation;
- imported reservations belonging to players outside the raid;
- reservations assigned without SR or Highly Contested Item rights.

### 3. Configure and announce loot rules

1. Open **Set Loot Rules**.
2. Enable SR, Highly Contested Items, Reycoin, and CSR rights for the appropriate guild ranks.
3. Review **Set Highly Contested Items** and adjust the default item list if needed.
4. Choose **Send Loot Rules** to announce the active rules to the raid.

Highly Contested Item rights apply only when the rank also has SR rights.

### 4. Run loot distribution

1. Enable **Loot Master Mode**.
2. Loot the corpse or use `/mos roll [linked item]` for an item from a bag or chat.
3. Confirm the announced SR list and available roll types.
4. Wait for the timer, choose **Finish** early, or use **Extend** when players need more time.
5. Review valid and invalid rolls in **Current roll**.
6. Click a valid row if you need to override the automatically selected winner.
7. Assign the item to the selected recipient.

Common scenarios:

- **Direct winner -** Give the item directly to the selected player. Loot history and SR or Reycoin usage are recorded after receipt.
- **Transmog carrier -** Give the item to the Transmog winner. The target SR or Reycoin player remains in an awaiting-trade state until the real trade is detected.
- **Single eligible SR -** The only eligible reserver in the raid is selected automatically, even without a roll.
- **Second copy -** A consumed SR is not reused for another copy in the same session; normal roll rules apply when no eligible SR remains.
- **Late valid roll -** A late roll can still be selected until the item is assigned.

### 5. Monitor the session

1. Use the member list to review received loot.
2. Open **Reycoin list** to check used Reycoins and pending trades.
3. Review roll history when a result or trade needs confirmation.
4. Keep the raid session active when temporarily leaving the instance or running back from the graveyard.

### 6. Save the raid

1. Choose **Save Raid**.
2. Enter a unique **Raid ID**. The exact value is saved; no timestamp suffix is added.
3. Enable **Save raid statistics** to add the raid to Raid Statistics.
4. Enable **Save attendance** if attendance should contribute to player statistics.
5. Enable **Save CSR** if this raid should contribute to CSR.
6. Confirm **Save Raid** and complete the requested reload when shown.

Disabling **Save attendance** keeps the raid record but marks Attendance as Off. Attendance can only be enabled when raid statistics are saved.

### 7. Load or review a saved raid

1. Open **Raid** to load and continue an unfinished saved session.
2. Select the raid under **Saved raids** and choose **Load**.
3. Open **Raid Statistics** to review completed saved raids.
4. Use **Edit** to change player attendance/SR values or add a manual entry, then confirm Attendance and CSR participation.
5. Use **Remove** to delete a raid and recalculate dependent statistics.

Raid warnings overlay the content without shrinking lists or groups. They can be minimized to a bottom row and restored with the header button or **X issues**. The **X issues** button pulses for half a second every second until clicked; new issues or loading a session restart the pulse. The text turns light red during each pulse.

Raid column headers shrink together when space is tight and grow back as space returns. List and Group views reserve scrollbar space only when scrolling is needed. **Raid Leader Tools** and **Loot Master Tools** open action dropdowns; options share the width of the longest caption and show a gold outline on hover. Click an option or outside the menu to close it.

The Loot Master Tools menu can open a standalone, movable Reycoin list. Opening Loot Master Mode closes the standalone list; its toolbar can reopen the same list beside the LM window.

Raid import, save, reset and quit dialogs can be moved by dragging their background. Reset and End Raid require confirmation, with the confirming action on the right.

In Reycoin list, enter a player name and optionally an item, then choose Add. A name without an item creates a Manual entry.

Import Soft Reserves has a close control in its header. Reycoin list remains resizable from its bottom-right corner even though the resize icon is hidden.

Warning INFO windows show affected players as individual rows, colored by known class.
