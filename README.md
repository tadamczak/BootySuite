# Mukla Officer Suite

An addon for the World of Warcraft 1.12.1 client. The initial version provides:

- a minimap button that opens the dashboard,
- `/mos`, `/mos status`, `/mos minimap`, and `/mos hide` commands,
- a main window displaying the last saved guild roster,
- aligned roster columns with scrolling for the complete member list,
- dashboard navigation with dedicated roster, export, and about pages,
- sortable roster columns and full-field search,
- an `Export Roster` page with `Scan & Save` and last-scan information,

The addon follows semantic versioning. The installed version is defined in `MuklaOfficerSuite.toc`, displayed in the dashboard, and stored with every guild roster scan.

## Installation

Copy the top-level `MuklaOfficerSuite` addon directory into `Interface/AddOns/`, so the TOC file is located at:

`Interface/AddOns/MuklaOfficerSuite/MuklaOfficerSuite.toc`

After logging in, open the dashboard with `/mos`. Open `Export Roster`, click `Scan & Save`, then confirm `Reload now` to write the roster to disk. The addon does not scan automatically on login or when the guild changes. The client writes the data to disk during `/reload` or logout in:

`WTF/Account/<ACCOUNT>/SavedVariables/MuklaOfficerSuite.lua`

Officer notes are saved only when the logged-in character has permission to read them.

The repository layout keeps game files separate from project configuration and tools:

```text
MuklaOfficerSuite/          # IntelliJ project root
|-- MuklaOfficerSuite/      # Directory copied to Interface/AddOns
|   |-- MuklaOfficerSuite.toc
|   |-- MuklaOfficerSuite.lua
|   `-- Textures/
|-- Deploy-Addon.ps1
|-- Tools/
|-- README.md
`-- .idea/
```

## Deployment

Run `Deploy-Addon.ps1` to copy only the required addon files to:

`C:\Gry\OctoWoWPvP\Interface\AddOns\MuklaOfficerSuite`

## CSV export

Run `Export-Roster.ps1` after using `Scan & Save` in game. The script automatically locates the newest `MuklaOfficerSuite.lua` under the game's `WTF/Account` directory and writes a UTF-8 CSV file to `exports/`.

An explicit input or output path can be supplied when needed:

```powershell
.\Export-Roster.ps1 -InputPath "C:\path\to\MuklaOfficerSuite.lua" -OutputPath "C:\path\to\roster.csv"
```
