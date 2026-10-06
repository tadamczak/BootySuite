<p align="center"><img src="https://raw.githubusercontent.com/tadamczak/MuklaOfficerSuite/master/Assets/readme-header.png" width="100%" alt="Sons of Mukla"></p>

# Booty Suite

Booty Suite brings installed Booty addons into one World of Warcraft 1.12 dashboard with a common minimap menu, Settings and Plugins.

## Contents

- [Installation](#installation)
- [Usage](#usage)
- [Migration](#migration)

## Installation

Install `BootyLib`, `BootySuite` and the products you want in `Interface/AddOns`. BootyGuild, BootyRaider, BootyProfiler, BootyActionBars and BootyUI can each be used with BootyLib alone. Adding Suite integrates their pages, settings and Quick Menu actions automatically.

## Usage

Use `/bs`, `/booty` or the minimap icon to open the dashboard. Right click the icon for Quick Menu; Shift + left drag moves it. Use `/bs settings` for Settings and `/bs plugins` for the installed products. Loading changes take effect after `/reload`; Stop pauses a loaded product separately. Finish active raid sessions or profiler recordings before stopping or reloading.

Settings includes Search and named profiles under Profile → General. Add, Save, Load, Delete and Export manage profiles for installed products. Reset restores preferences and keeps raid, guild and profiler history.

Hover an addon's name in Plugins to see which features it provides.

With current BootyUI installed, drag and resize the dashboard normally, or use **Move** and its grid/snap aids, then Apply or Cancel. Closing or minimizing the dashboard cancels an unfinished preview; the previous saved layout is retained. BootyUI keeps window scale at100% and restores older saved scales at login. Type `/bui rescue` to cancel an unfinished edit and restore100% without opening its editor; expand a minimized dashboard first.
Dragging the dashboard normally updates the editor's position and offsets. During an active preview it remains a draft until Apply.

BootyUI also previews shared Booty skins and selects native or BootyRaider content for the game's Raid tab. Its pages appear in the dashboard and Quick Menu alongside other installed products.

Appearance previews from current BootyUI survive page navigation so you can inspect Raider before applying. Closing or minimizing the shared window cancels that preview even while another page is active.

## Migration

When replacing Mukla Officer Suite, keep the small `MuklaOfficerSuite` migration addon enabled alongside the new products. Existing data and settings are imported without clearing their old source. Keep the previous SavedVariables until raid history, loot and profiles have been checked in game.

Settings and each dialog open above the window that launched them. Clicking a window brings its related windows forward together.
