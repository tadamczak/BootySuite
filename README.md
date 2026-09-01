# Mukla Officer Suite

An addon for the World of Warcraft 1.12.1 client. The initial version provides:

- a minimap button that opens the dashboard,
- `/mos`, `/mos status`, `/mos minimap`, and `/mos hide` commands,
- a main window displaying the last saved guild roster,
- aligned roster columns with scrolling for the complete member list,
- manual storage of all guild members in `MuklaOfficerSuiteDB` after clicking `Scan roster`.

## Installation

Copy the top-level `MuklaOfficerSuite` addon directory into `Interface/AddOns/`, so the TOC file is located at:

`Interface/AddOns/MuklaOfficerSuite/MuklaOfficerSuite.toc`

After logging in, open the dashboard with `/mos` and click `Scan roster`. The addon does not save the roster automatically on login or when the guild changes. The client writes the data to disk during `/reload` or logout in:

`WTF/Account/<ACCOUNT>/SavedVariables/MuklaOfficerSuite.lua`

Officer notes are saved only when the logged-in character has permission to read them.

The repository layout keeps game files separate from project configuration and tools:

```text
MuklaOfficerSuite/          # IntelliJ project root
|-- MuklaOfficerSuite/      # Directory copied to Interface/AddOns
|   |-- MuklaOfficerSuite.toc
|   `-- MuklaOfficerSuite.lua
|-- Deploy-Addon.ps1
|-- README.md
`-- .idea/
```

## Deployment

Run `Deploy-Addon.ps1` to copy only the required addon files to:

`C:\Gry\OctoWoWPvP\Interface\AddOns\MuklaOfficerSuite`
