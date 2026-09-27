# Mukla Officer Suite documentation

This is the single entry point to project documentation.

## Start here

- [Project overview and usage](README.md)
- [Architecture](ARCHITECTURE.md)
- [Development rules](AGENTS.md)
- [Backlog](BACKLOG.md)
- [Change history](CHANGELOG.md)
- [Current handoff context](HANDOFF.md)

## Source ownership

- `MuklaOfficerSuite/Core/`: lifecycle, settings, diagnostics, registration.
- `MuklaOfficerSuite/Services/`: WoW API access and domain logic; no frames.
- `MuklaOfficerSuite/UI/`: reusable presentation components; no feature rules.
- `MuklaOfficerSuite/Modules/`: feature screens and event-driven controllers.
- `MuklaOfficerSuite/MuklaOfficerSuite.lua`: composition and legacy migration only.

## Documentation workflow

1. Before work, find the module in [BACKLOG.md](BACKLOG.md) or add a task.
2. During work, record concise findings that affect scope or future decisions.
3. After work, update status, date, verification state, and the owning document.
4. Keep completed tasks in the backlog with status `Done`.
5. Apply the appropriate SemVer bump in the TOC and fallback version.
6. Add a short version entry to [CHANGELOG.md](CHANGELOG.md); keep details in the backlog.
7. Commit on a dedicated `codex/` branch using Conventional Commits.
8. Push every deployed version to the GitHub `origin` remote.

Use `Module` and `Status` columns in `BACKLOG.md` to answer module-specific backlog questions.
