<p align="center"><img src="https://raw.githubusercontent.com/tadamczak/BootyLib/develop/Assets/readme-header.png" width="100%" alt="Sons of Mukla"></p>

# Booty Suite

Booty Suite brings installed Booty addons into one World of Warcraft 1.12 dashboard with a common minimap menu, Settings and Plugins.

## Contents

- [Installation](#installation)
- [Usage](#usage)
- [Migration](#migration)

## Installation

Install `BootyLib`, `BootySuite` and the products you want in `Interface/AddOns`. BootyGuild, BootyRaider, BootyProfiler and BootyActionBars can each be used with BootyLib alone. Adding Suite integrates their pages, settings and Quick Menu actions automatically.

## Usage

Use `/bs` or `/booty` to list commands. `/bs open` or the minimap icon opens the dashboard; `/bs about` opens About and `/bs versions` lists versions of all installed Booty addons. Right click the icon for Quick Menu; Shift + left drag moves it. Use `/bs settings` for Settings and `/bs plugins` for the installed products. Loading changes take effect after `/reload`; Stop pauses a loaded product separately. Finish active raid sessions or profiler recordings before stopping or reloading.

The dashboard remembers its position and size across login and `/reload`. Minimizing keeps its expanded window bounds for restoration.

Settings groups options by addon, using the same icons as the menu. Click its cog again to close it. Under Profile, each addon has its own profile list and BootySuite has a combined list. Saving a Suite profile also saves the current addon profiles; missing selections get unique Custom profiles. Loading the Suite profile restores its saved settings and addon profile selections, even if an addon profile was changed or deleted later. Reset restores preferences and keeps raid, guild and profiler history.

Plugins uses a compact table with separate addon, version and status columns. Hover an addon name for its description or a shortened version/status for the full text. The Menu and Quick columns independently choose where each addon appears. **Add to menu** controls only the window tabs; **Add to Quick Menu** independently controls the minimap menu. Disabled or unavailable addons appear in neither menu. Assign shortcuts under **Booty addons and tabs** in WoW Key Bindings to open individual sections.

Use **Open** in Plugins to select an addon's main tab. Clear **Add to menu** to
open it in a separate window instead. Adding it again restores all its tabs
immediately. The choice is saved and keeps the addon's work and settings.
BootyLib and BootySuite have no separate feature tab, so these controls are
disabled for them. Enable unloaded addons and reload before opening them.

Version discovery checks online guild and group members. **Up to date!** means
those peers reported no newer version. An unanswered query keeps the previous
successful check time; use the linked GitHub Releases page to check the latest release.

If Stop cannot close the product's windows safely, its work stays paused. Resume retries that cleanup and starts the product only after it succeeds.

## Migration

To import previous data, keep **Booty Legacy Data Import** enabled alongside the new products. Its historical `MuklaOfficerSuite` folder name lets the client load your previous save file. Existing data and settings are imported without clearing their old source. Keep the previous SavedVariables until raid history, loot and profiles have been checked in game.

Settings and each dialog open above the window that launched them. Clicking a window brings its related windows forward together.

With current BootyProfiler installed, **Booty Diagnostics → Profile Booty** can measure selected BootySuite operations after you select the addon and press **Start**. **Stop** ends the capture. The report covers the listed Lua entry points; it does not measure total addon CPU, RAM or disk size.

`/bs` explains each available command. Suite chat messages use the `[BootySuite]` prefix.
