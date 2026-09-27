# Mukla Officer Suite architecture

## Composition

`MuklaOfficerSuite.lua` is the composition root and legacy SavedVariables migration boundary. It wires factories, services, callbacks, and page lifecycles; new feature UI and domain processing must not be added to it.

## Core

- `Core/Bootstrap.lua` creates the root namespace and version metadata.
- `Core/Database.lua` owns SavedVariables defaults and durable data access.
- `Core/Diagnostics.lua` owns scoped counters and profiling wrappers.
- `Core/ModuleRegistry.lua` owns page lifecycle (`Show`, `Hide`, `Refresh`, `OnResize`).
- `Core/EventDispatcher.lua` owns registration and dispatch of client events.
- `Core/Commands.lua` owns slash-command registration and routing.
- `Core/GuildScanController.lua` owns the transient, event-driven guild scan lifecycle.

## Services

Services are frame-free adapters around the WoW API and domain data:

- `Services/RosterService.lua`
- `Services/RaidResService.lua`
- `Services/RaidService.lua`
- `Services/TestRaidService.lua` owns the transient raid sandbox and never persists generated members.

## UI

Reusable presentation primitives live in `UI/`:

- theme and class colors;
- buttons, dropdowns, search fields, and table helpers;
- reusable filter panels that retain and recycle their controls;
- Settings sections, accordions, checkboxes, sliders, and color controls.
- dashboard chrome, pages, status bar, minimap control, and persistence dialogs.

UI primitives accept callbacks and setting keys. They do not know the roster or raid workflows.

## Modules

Feature modules own screens and their transient state:

- `Modules/Navigation.lua` owns Button View and Tab View.
- `Modules/RosterManagement.lua` owns the roster screen, deterministic layout, recycled rows, and guild actions.
- `Modules/RaidManagement.lua` owns raid actions, sorting, and deterministic list/group layout calculations.
- `Modules/RaidSoftReserve.lua` owns the Soft Reserve importer, warnings, and assignment dialog.
- `Modules/RaidRules.lua` owns loot-rule and Highly Contested Items dialogs.
- `Modules/RaidHistory.lua` owns the saved-raid selection shown before starting Raid Management.
- `Modules/Settings.lua` owns Settings screen state synchronization and reset workflows.
- `Modules/Performance.lua` owns diagnostics UI and sampling lifecycle.

## Dependency direction

`Core -> UI/Services -> Modules -> composition`

Services never depend on UI. Reusable UI never depends on feature modules. Modules receive external callbacks explicitly and shut down work when hidden.

## Runtime lifecycle

Pages are activated exclusively through `Core/ModuleRegistry.lua`. Hidden roster and raid pages detach transient work; raid tracking is active only while Raid Management is visible. Performance sampling is active only while its page, live monitor, or an explicit diagnosis requires it. Resize and drag `OnUpdate` handlers exist only for the duration of the user interaction.
