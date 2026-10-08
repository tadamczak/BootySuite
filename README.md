<p align="center"><img src="https://raw.githubusercontent.com/tadamczak/MuklaOfficerSuite/master/Assets/readme-header.png" width="100%" alt="Sons of Mukla"></p>

# Booty Suite

Booty Suite brings installed Booty addons into one World of Warcraft 1.12 dashboard with a common minimap menu, Settings and Plugins.

## Contents

- [Installation](#installation)
- [Usage](#usage)
- [Migration](#migration)

## Installation

Install `BootyLib`, `BootySuite` and the products you want in `Interface/AddOns`. BootyGuild, BootyRaider, BootyProfiler and BootyActionBars can each be used with BootyLib alone. Adding Suite integrates their pages, settings and Quick Menu actions automatically.

## Usage

Use `/bs`, `/booty` or the minimap icon to open the dashboard. Right click the icon for Quick Menu; Shift + left drag moves it. Use `/bs settings` for Settings and `/bs plugins` for the installed products. Loading changes take effect after `/reload`; Stop pauses a loaded product separately. Finish active raid sessions or profiler recordings before stopping or reloading.

Settings includes Search and named profiles under Profile → General. Add, Save, Load, Delete and Export manage profiles for installed products. Reset restores preferences and keeps raid, guild and profiler history.

Hover an addon's name in Plugins to see which features it provides.

Use **Open** in Plugins to select an addon's main tab. Clear **Add to menu** to
open it in a separate window instead. Adding it again restores all its tabs
immediately. The choice is saved and keeps the addon's work and settings.
BootyLib and BootySuite have no separate feature tab, so these controls are
disabled for them. Enable unloaded addons and reload before opening them.

Version discovery checks online guild and group members. An unanswered query
does not confirm the latest release; use the linked GitHub Releases page to check.

If Stop cannot close the product's windows safely, its work stays paused. Resume retries that cleanup and starts the product only after it succeeds.

## Migration

When replacing Mukla Officer Suite, keep the small `MuklaOfficerSuite` migration addon enabled alongside the new products. Existing data and settings are imported without clearing their old source. Keep the previous SavedVariables until raid history, loot and profiles have been checked in game.

Settings and each dialog open above the window that launched them. Clicking a window brings its related windows forward together.
