<p align="center">
  <img src="Assets/readme-header.png" width="100%" alt="Sons of Mukla - Mukla Officer Suite">
</p>

# Mukla Officer Suite

Mukla Officer Suite is a World of Warcraft 1.12.1 addon for guild officers and raid leaders. It combines guild management, raid sessions, loot distribution, Soft Reserve, Reycoin, attendance, raid statistics, and CSR in one interface.

## Table of contents

- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Commands](#commands)
- [Roster](#roster)
- [Guild Statistics](#guild-statistics)
- [Raid](#raid)
- [Loot Master Mode](#loot-master-mode)
- [Raid Statistics](#raid-statistics)
- [CSR](#csr)
- [Performance](#performance)
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

## Basic Usage

LM config and Reycoin list use the same diagonal resize grip as the main window. Expanded roster details stay inside the window; use the mouse wheel over the details to reach notes when space is limited.

The top-right buttons open Settings, minimize or restore the dashboard, and close it. Addon windows use matching gold controls: a line minimizes, a square restores, and X closes. The minimized window remembers its dragged position during the current session; restoring returns to the expanded window's previous position.

### Commands

- **Open or close -** Use `/mos`, `/mukla`, `/mos show`, or `/mos open`.
- **Hide -** Use `/mos hide` to close the main window.
- **Manual item roll -** Use `/mos roll [linked item]` to start Loot Master rolling for an item from chat or a bag.
- **Roster shortcut -** Use `/mos scan` to open Roster and access its scan controls.
- **Saved roster status -** Use `/mos status` to print the number of saved guild members.
- **Minimap button -** Use `/mos minimap` to show or hide the minimap button.
- **Layout diagnostics -** Use `/mos layout` when diagnosing window-layout problems.

### Roster

- **Guild roster -** Browse saved guild members with class, rank, level, zone, notes, online status, and last-online information.
- **Table headers -** Click sortable headings to change order; click again to reverse it.
- **Search and filters -** Narrow the roster by text, class, rank, level, and online state.
- **Member details -** Expand a player to review additional information and available officer actions.
- **Guild actions -** Invite, promote, demote, remove, ignore, report, or manage eligible members according to your permissions.
- **Guild information -** Review or edit Guild Information and Message of the Day.
- **Roster scan -** Refresh and save current guild data when you explicitly request it.

Expanded roster rows stay highlighted. Roster rows expand with player name, level/class, rank, last online, public and officer notes, and permitted rank arrows. Click a note to edit it in an Accept/Cancel window. Officer notes and guild administration controls appear only with the required permissions. Right-click a member for a compact menu beside the cursor with Whisper, Invite, Target, Report or Ignore Player; click outside to close. Report opens a reason form and Submit sends a GM ticket.

### Guild Statistics

- **Export Roster -** Scan the guild roster and confirm a reload to save it to disk.
- **Class overview -** Review the saved roster grouped by class.
- **Rank overview -** Review the saved roster grouped by guild rank.
- **Level 60 filter -** Limit statistics to max-level characters.

### Raid

- **Raid sessions -** Start a new raid, continue an active session, save it, or load a saved session.
- **Raid type -** Assign Blackwing Lair, Molten Core, Onyxia's Lair, Karazhan10, Zul'Gurub, or Other.
- **Attendance -** Track the raid roster and optionally include attendance when saving statistics.
- **Raid views -** Switch between the member list and a centered, configurable group layout with adjustable sizing, spacing, and typography.
- **Player actions -** Manage raid leader, assistants, removal, reporting, and ignore state.
- **Soft Reserve warnings -** Review missing SR, imported SR outside the raid, and SR without loot rights.
- **Loot rules -** Configure SR, Highly Contested Items, Reycoin, and CSR rights by guild rank.
- **Reycoin list -** Review used Reycoins and pending item trades.
- **Narrow raid windows -** Raid Leader Tools and Loot Master Tools wrap to a left-aligned row. Warnings move below the roster as compact headers when space is limited.
- **Raid header -** In narrow windows, saved date, warning count, Save Session and Quit move together to a second row aligned to the left.
- **Saved raids -** Select and load an earlier raid session.

### Loot Master Mode

Open **Loot Master Tools > LM Mode** to show a separate window while keeping the main addon open. Its top bar has gold **SR** and **Loot Rules** icons beside the configuration controls. Their menus offer **Import SR / Share SR Link** and **Set Loot Rules / Share Loot Rules**. Shared rules start with **=== LOOT RULES ===** and abbreviate Highly Contested Items as **HCI** and Reycoin as **RC**. Click outside a menu to close it. The minimized main window keeps its controls and border without a background. Minimize, resize or close the LM window independently. Click a player to expand loot details within the scrollable list; neighboring players remain visible. The gold list icon opens **Reycoin List**. Enter a raid member name and click **Add** (or press Enter) to record a used Reycoin; invalid names show an explanation. **Loot Master Config** has its own close button, supports narrower widths, and colors rarity options by item quality. Config and Reycoin List remain attached when moving LM. **Set Loot Rules** can be minimized without losing unsaved edits.

In **LM Config**, set **LM Auto Loot** to **Auto Loot**, **Shift Loot** (hold Shift while right-clicking the loot source), or **Off**. **Auto Loot Rarity** collects only the selected qualities; none selected means no automatic item looting. Existing settings retain Poor, Common and Uncommon by default. Enter comma-separated full item names in **Auto Loot Exceptions** to always exclude them; capitalization and extra spaces are ignored. These choices are saved in Settings profiles. **Exception Presets** offers ZG, Kara10, MC, Onyxia and BWL; currently these insert test placeholder names only. Deselecting a preset removes its placeholder while preserving manual exceptions.

- **Compact workspace -** Keep raid members and loot tools visible in a smaller, resizable window.
- **Loot detection -** Open the roll window from corpse loot or start it manually with `/mos roll [linked item]`.
- **Supported rolls -** Handle SR (102), Reycoin (101), MS (100), OS (99), and Transmog (98).
- **Late rolls -** Accept valid rolls until the item is assigned.
- **Manual winner -** Select any valid roll row before assigning the item.
- **Automatic SR -** Select the only eligible in-raid reserver when no competing SR roll is required.
- **Trade tracking -** Track pending SR or Reycoin delivery when a Transmog winner temporarily receives the item.
- **Roll history -** Review rounds, winners, trades, and prior rolls for the item.

### Raid Statistics

- **Saved raid list -** Browse and select recorded raid sessions.
- **Filters -** Filter by raid, date range, session name, or player.
- **Raid details -** Review attendance, Soft Reserves, received loot, and stored roll information.
- **Edit -** Change whether a saved raid contributes to attendance or CSR.
- **Remove -** Delete a saved raid and recalculate affected statistics.

### CSR

- **CSR overview -** Review unsuccessful Soft Reserves accumulated per player and item.
- **Raid filter -** Include one or more raid types in the calculation.
- **Search -** Find a player or item.
- **Raid history -** Expand a CSR record to see the contributing raids.
- **View raid -** Open the selected contributing raid in Raid Statistics.
- **CSR Test Lab -** Simulate players, ranks, reservations, awards, and elapsed time without changing saved raid data.

### Performance

- **Runtime metrics -** Review FPS, frame time, latency, Lua memory, event rate, refresh rate, and saved-data size.
- **Live Monitor -** Open a small movable window with current runtime metrics.
- **Performance diagnosis -** Capture scoped addon activity when investigating performance problems.
- **Memory by Addon -** Compare addon memory usage when the client exposes the required data.

### Settings

**UI > Roster > General > Player details style** selects **Collapsible** (the default expanded roster row) or **Window**, a member panel attached to the right of the main window. The panel shows guild details, editable notes when permitted, rank controls, Remove (with confirmation), and Group Invite. The choice is saved in settings profiles.

**UI > Layout** can hide the status/version bar, guild logo, or addon name and ornaments. These options default to off. **Hide header bar** removes the entire header and moves window controls to a compact row inside the content. In top Tab View the gold outer edge moves below the tabs, which retain their position. Menu type and Use Icon Tabs share one row. With the bottom bar hidden, resize by dragging the bottom-right corner. Hiding both logo and name reduces the header to the window controls. In tab views, narrow headers hide side ornaments and align the title left so window controls remain accessible. These preferences are saved in profiles under **Profile > General**. Hiding every roster filter also removes its empty row.

**Show section header** is in **UI > Roster > Layout > Display**; **Hide section header** remains in **UI > Raid > General**. In Raid it hides the section label while keeping the selected raid name visible.

Under **UI > Roster > Layout**, choose visible columns, filters and column headers. Officer notes require guild permission. Hidden class, rank and search filters do not restrict results. These preferences are saved in profiles. Show Player Status switches between guild columns (name, zone, level, class) and player-status columns (name, rank, notes, last online). Column preferences apply within each mode; both Officer note and its Settings checkbox require permission. Export Roster is in Guild Statistics; Refresh Data and guild actions stay at the bottom of Roster. Refresh Data is hidden while UI > Roster > General > Live tracking is enabled; with tracking disabled it is unavailable only while a scan is pending. MOTD, the table with member counts/status, and guild actions share the standard content frame, with horizontal separators between sections. The main window retains its project gold outer border; header keeps its bottom separator, content keeps horizontal separators, and the status bar keeps its top and right borders. Only the table section stretches when resizing vertically; its counts and status switch stay above the bottom actions, below the table. The guild message wraps to additional lines; guild status remains on one line with text fitted to the available width. Columns share the available width according to their contents. The main window can be narrowed to 350 pixels. Settings uses a compact plain header, one gold outer frame and a horizontal content separator. Resize it by dragging its unmarked bottom-right corner; UI General and Layout expand independently, and its single-line options adapt to up to four measured columns, down to a 350-pixel window.

Under **UI > Layout**, choose **Right side view**, **Top tab view** or **Bottom tab view**. Both tab views reveal **Use Icon Tabs** beside the dropdown. Top Tab view uses a compact window-control strip; tabs overlap it and protrude above the window. Bottom Tab view places navigation below the status bar when visible, or below the content when hidden. Tabs extend beyond the bottom window frame. Top and bottom text tabs use the available window width. Saved raid lists stop growing at 500 UI units. Narrow text tabs shorten Guild Statistics and Raid Statistics to Stats and Performance to Perf. Text and icon tabs join the content frame; the selected tab keeps its gold outline, white caption and gradient highlight while inactive tabs are recessed. Enable it to replace tab captions with the sidebar icons and matching highlights.

Drag the diagonal bottom-right grip to resize Settings. Multiselect filters can be toggled by clicking either the checkbox or its label.

- **Profiles -** Current profile shows the active configuration as text, with Save beside it. Select a saved profile under Load profile to enable Load, Delete and Export. New profile + Add creates and activates a copy of your current settings; Save updates the current profile, including pending percentage edits. Gold feedback appears beside the action buttons. Only the latest action remains visible; saving before Add or Load shows both results. Load and Add ask whether to save changed settings first. Delete requires confirmation; deleting the current snapshot leaves your live settings available to save again. Export opens saved settings for copying. Profiles exclude guild, raid and loot records.
- **Collapsible sections -** Profile, UI (including Roster and Raid), and Debug start collapsed after reload. Expansion is remembered while playing and when reopening Settings.

- **Resets -** Each Display, Size and Member tile color subsection has Reset to default with confirmation. Reset to defaults at the bottom-right of Settings resets all settings after confirmation, preserving saved profiles, guild data and raid history.
- **Saved raids -** The Raid start screen lists Name, Raid and Time. Use the load or delete icon on each row; New Raid creates a session while grouped in a raid.
- **Appearance -** Open Settings from the gear icon to configure the addon skin, colors, navigation style, and window behavior live. The skins are named **Default** (formerly Classic) and **Classic WIP** (formerly Default). Existing profile appearances are preserved.
- **Settings layout -** Consistent spacing, readable foreground labels, padded overlay dropdowns, full-width separators, and scrolling keep every accordion section accessible; dropdowns close when clicking outside them.
- **Settings window -** Settings reopen from the top with your current saved values. Settings and saved raid lists use the full content width when scrolling is unnecessary; the scrollbar only takes space while needed.
- **Resizable window -** Settings can be resized within the available game screen; long sections remain available through scrolling.
- **Raid group interaction -** Drop a member on another member or on free group background. Hidden role icons release name space; hiding the group border and setting group spacing to zero joins the tiles.
- **Raid group appearance -** Group View > Display can hide the group border independently of its header. Group tile color controls header text, header background and border colors, with its own confirmed reset. These choices are included in settings profiles.
- **Roster preferences -** General contains live tracking and Player details style. Layout groups visibility options under Display and row appearance under Member tile color: class colors, background, main text, hover and Odd record lightness (0-100%). The lightness value brightens even rows toward white while typing; 0% keeps all row backgrounds identical. All Settings accordions start collapsed after reload. Raid Group View and List View have independent lightness fields under Member tile color. UI Layout groups Menu type under General and header/status visibility under Display; Raid List View groups its controls under Display, Size and Member tile color.
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

Leaving the instance does not automatically discard the session. Choose **Continue Session** to keep working or **End & Save** to finish it. Closing that prompt with the X ends the session without saving.

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

1. Choose **Save Session**.
2. Enable **Save raid statistics** to add the raid to Raid Statistics.
3. Enable **Save attendance** if attendance should contribute to player statistics.
4. Enable **Save CSR** if this raid should contribute to CSR.
5. Confirm **Save Session** and complete the requested reload when shown.

Disabling **Save attendance** keeps the raid record but marks Attendance as Off. Attendance can only be enabled when raid statistics are saved.

### 7. Load or review a saved raid

1. Open **Raid** to load and continue an unfinished saved session.
2. Select the raid under **Saved raids** and choose **Load**.
3. Open **Raid Statistics** to review completed saved raids.
4. Use **Edit** to change Attendance or CSR participation.
5. Use **Remove** to delete a raid and recalculate dependent statistics.

Raid warnings overlay the content without shrinking lists or groups. They can be minimized to a bottom row and restored with the header button or **X issues**. The **X issues** button pulses for half a second every second until clicked; new issues or loading a session restart the pulse. The text turns light red during each pulse.

Raid column headers shrink together when space is tight and grow back as space returns. List and Group views reserve scrollbar space only when scrolling is needed. **Raid Leader Tools** and **Loot Master Tools** open action dropdowns; options share the width of the longest caption and show a gold outline on hover. Click an option or outside the menu to close it.

The Loot Master Tools menu can open a standalone, movable Reycoin list. Opening Loot Master Mode closes the standalone list; its toolbar can reopen the same list beside the LM window.

Raid import, save, reset and quit dialogs can be moved by dragging their background. Reset and Quit require confirmation, with the confirming action on the right.

In Reycoin list, enter a player name and optionally an item, then choose Add. A name without an item creates a Manual entry.
