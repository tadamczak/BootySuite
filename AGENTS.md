# Mukla Officer Suite development rules

## Documentation is part of every change

- `DOCUMENTATION.md` is the single entry point to project documentation.
- `BACKLOG.md` is the single source of truth for planned, active, blocked, and deferred work.
- Completed tasks remain in `BACKLOG.md` with status `Done`; never delete them.
- Update the relevant documentation and backlog entry with every functional, architectural, UI, data, deployment, or testing change.
- Every backlog item must include: ID, module, status, date, title, scope, and concise notes or findings.
- Deferred or blocked work must state why it was not completed and what is needed to resume it.
- Keep documentation concise and factual. Do not duplicate detailed content across files; link to the owning document.
- Use stable module names in backlog entries so work can be listed reliably by module.
- Do not mark an item `Done` until its stated acceptance scope is complete. Record unverified in-game behavior explicitly.

## Versioning and changelog

- The addon follows Semantic Versioning: `MAJOR.MINOR.PATCH`.
- Every repository change must update the addon version in `MuklaOfficerSuite/MuklaOfficerSuite.toc` and the fallback version in `MuklaOfficerSuite/MuklaOfficerSuite.lua`.
- Use `PATCH` for compatible fixes, documentation, tests, and internal maintenance.
- Use `MINOR` for backward-compatible features or meaningful workflow additions.
- Use `MAJOR` for incompatible behavior or saved-data changes requiring migration.
- `CHANGELOG.md` must be updated with every change. Keep entries short; detailed scope and findings belong in `BACKLOG.md`.
- A version bump, changelog entry, and backlog update are part of the same change, not follow-up work.

## Git and release workflow

- Implement work on a dedicated branch with the `codex/` prefix. Do not develop directly on the default branch.
- Keep each branch focused on one feature, fix, refactor, or release scope.
- Use Conventional Commits, for example: `feat: add raid filters`, `fix: keep raycoin input anchored`, `docs: define release workflow`.
- Use the commit type that matches the change: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, or `chore`.
- Before a release, update `BACKLOG.md`, `CHANGELOG.md`, and both version declarations.
- Every deployed addon version must have a corresponding commit pushed to the GitHub `origin` remote.
- A deployment is complete only when the deployed version and pushed commit represent the same source state.
- Never rewrite shared branch history or force-push unless explicitly approved.

## Primary constraint: runtime performance

Performance and memory efficiency are first-class acceptance criteria for every change, especially while grouped or raiding.

- Prefer event-driven updates over polling.
- Never rebuild a complete table from `OnUpdate` unless no event-driven alternative exists.
- Reuse frames, rows, font strings, textures, and scratch tables instead of recreating them during refreshes.
- Avoid closures, temporary tables, and string-heavy work in high-frequency event handlers.
- Keep `OnUpdate` handlers disabled when their feature is not visible or active.
- Store only durable user data in SavedVariables; do not persist derived UI state or duplicate roster fields unnecessarily.
- Aggregate repeated loot records instead of appending duplicates.
- Profile new raid and roster features using the scoped MOS diagnostics before considering them complete.
- Treat increased idle event rate, UI refresh rate, retained memory, or save size as regressions unless justified.
- Maintain compatibility with the WoW 1.12 Lua runtime and available client extensions.

## Verification

For meaningful UI or data changes, verify idle behavior, a populated guild roster, and an active raid. Confirm that hidden pages and disabled tracking modes do not continue doing work.

## Architecture boundaries

- `MuklaOfficerSuite.lua` is composition and legacy migration only. Do not add new feature UI, data processing, or reusable controls there.
- `Core/` owns lifecycle, durable settings, diagnostics, and module registration.
- `Services/` owns WoW API access and domain data transformations. Services must not create frames.
- `UI/` owns reusable visual primitives. Components must not contain roster- or raid-specific rules.
- `Modules/` owns feature screens and their event-driven controllers. A module must stop its transient handlers when hidden.
- Communicate across domains through `MuklaOfficerSuite` module/service APIs or explicit factory dependencies, never by reaching into another module's local frames.
- Before adding a control or layout calculation, search for an existing reusable implementation and extend it instead of copying it.
- Refactors must preserve behavior. Do not combine structural moves with visual or functional changes.
