# Mukla Officer Suite backlog

Single source of truth for all project work. Keep entries short, update them with every related change, and retain completed tasks permanently.

## Statuses

- `Planned`: accepted, not started.
- `In progress`: currently being implemented.
- `Blocked`: cannot continue; notes state the blocker.
- `Deferred`: intentionally postponed; notes state why and how to resume.
- `Verification`: implemented, awaiting defined verification.
- `Done`: scope and required verification completed.

## Tasks

| ID | Module | Status | Date | Title | Scope | Notes / reason deferred |
|---|---|---|---|---|---|---|
| MOS-001 | Roster Management | Planned | 2026-09-27 | Restyle expanded member details | Match the standard Guild details panel without duplicating visible columns. | Existing inline behavior remains; visual work was postponed while raid and loot workflows were stabilized. |
| MOS-002 | Roster Tracking | Verification | 2026-09-27 | Verify live tracking | Test start, stop, and guild roster changes. | Requires in-game roster changes. |
| MOS-003 | Raid Tracking | Verification | 2026-09-27 | Verify live tracking and loot capture | Test start, stop, raid composition changes, and loot capture. | Requires an active raid in the WoW client. |
| MOS-004 | Performance | Verification | 2026-09-27 | Verify diagnostics windows | Check profiler, report, Live Monitor, Memory by Addon, layers, dragging, and idle work. | Requires in-game measurements; mocks are insufficient. |
| MOS-005 | UI | Verification | 2026-09-27 | Verify responsive layouts | Test every page at minimum, default, and maximum supported sizes. | Requires visual verification in the client. |
| MOS-006 | Core | Verification | 2026-09-27 | Reload smoke test | Confirm no Lua errors after `/reload`. | Run after the current UI change batch is complete. |
| MOS-007 | Master Loot | Deferred | 2026-09-27 | Verify real item trade | Verify detection and finalization using a real tradable blue or epic item. | Deferred because a suitable item and trade event were unavailable; simulated chat path passed manual testing. |
| MOS-008 | Documentation | Done | 2026-09-27 | Establish documentation workflow | Add one documentation index, persistent backlog, mandatory SemVer, and concise changelog rules. | Versioning resumed at 0.21.0. |
| MOS-009 | Architecture | Done | 2026-09-27 | Modular architecture migration | Split lifecycle, services, reusable UI, feature modules, and composition boundaries. | Migrated from the former TODO history. |
| MOS-010 | Performance | Done | 2026-09-27 | Event-driven diagnostics and tracking | Add scoped diagnostics and remove unconditional raid refresh polling. | In-game verification remains separately tracked by MOS-004. |
| MOS-011 | Roster Management | Done | 2026-09-27 | Roster workflow redesign | Add filters, status columns, guild actions, responsive rows, and expanded details behavior. | Remaining visual restyle is MOS-001. |
| MOS-012 | Raid Management | Done | 2026-09-27 | Raid workflow redesign | Add list/group views, player actions, warnings, session controls, and loot tools. | Runtime verification is tracked separately. |
| MOS-013 | Master Loot | Done | 2026-09-27 | Loot rules and roll workflow | Add SR, HCI, Raycoin, MS, OS, Transmog policies, manual rolls, trade handling, and regression coverage. | Real trade verification remains MOS-007. |
| MOS-014 | Raid Statistics | Done | 2026-09-27 | Saved raid statistics management | Add save options, history selection, filters, edit, remove, and CSR integration. | Further defects create new backlog items; this completed scope stays recorded. |
| MOS-015 | CSR | Done | 2026-09-27 | CSR history and test lab | Add raid/search filters, expandable history, View navigation, and transient test tooling. | Further defects create new backlog items; this completed scope stays recorded. |
| MOS-016 | UI | Done | 2026-09-27 | Shared visual components | Add shared skins, controls, dropdowns, dialogs, tables, hover, selected states, and responsive dashboard chrome. | Full responsive verification remains MOS-005. |
| MOS-017 | Development Process | Done | 2026-09-27 | Establish Git and release workflow | Require focused `codex/` branches, Conventional Commits, SemVer, and GitHub push for every deployed version. | Release source and deployed source must remain identical. |

## Rules

- One row per independently actionable task.
- Use stable module names.
- Update `Date` when status, scope, or findings change.
- A deferred or blocked task must explain why and what is required to resume.
- Never remove completed tasks. Set them to `Done` and keep concise findings in this table.
- `CHANGELOG.md` contains only short release summaries; detailed scope stays here.
