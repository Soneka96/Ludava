# Task 10 — Slower game identity checks and failure recheck

**Status:** Planned, not implemented or live-validated.
**Prerequisite:** PR #16 must be merged before this task begins.
**Dependencies:** Task 07, Task 09.
**PR scope:** One primary responsibility in a focused branch from latest merged main.

## Goal and changes

- Keep a slower Flutter game/process identity loop active even during numeric editing; keep value polling paused when editing.
- Use current SDK discovery/detection pipeline and validate every write's exact session independently of polling.
- On game/session change invalidate old editor/writes, update title/fields, and fail closed on ambiguous identity.
- When a write fails for a possibly stale session, coalesce an immediate identity recheck while preserving actual SDK error details.

## Acceptance criteria

- Game switch during editing cannot send queued writes to the former target.
- Native title and field list eventually reflect newly detected game while value polling stays paused during editing.
- Identity recheck does not multiply concurrent operations or mask non-identity write errors.

## Verification ownership

- Middleware/coordinator tests cover session changes, failures and forbidden stale writes.
- Windows integration proves dynamic native title without losing focus.

## Explicit exclusions

- Rewriting SDK detection heuristics or adding profiles.
- Manually requested Refresh semantics (task 11).

Follow the [task index](../README.md) and the current architecture, testing and Flutter conventions. Keep SDK identity/write safety and TUI unchanged; update owning conventions when a behavior changes.
