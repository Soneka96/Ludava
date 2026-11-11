# Task 16 — Loading, game-change and safe-close transitions

**Status:** Planned, not implemented or live-validated.
**Prerequisite:** PR #16 must be merged before this task begins.
**Dependencies:** Task 02, Task 12, Task 14, Task 15.
**PR scope:** One primary responsibility in a focused branch from latest merged main.

## Goal and changes

- Open a compact loading window promptly, then expand to content size when ready without artificial startup delay.
- Animate genuine game/field-count bounds changes when supported and keep bounds on-screen; no motion on ordinary refresh, edits, failures or success.
- Make closing motion subordinate to terminal guard, existing SDK cleanup/disposal and native close veto/retry.
- Respect reduced motion and touch keyboard focus; avoid promising native window animation from Flutter AnimatedSize alone.

## Acceptance criteria

- Opening and game changes feel smooth where actually supported, with a safe immediate fallback.
- No SDK operation happens after terminal guard closure and native close still awaits disposal.
- No row shift, input flicker, focus loss or off-screen geometry from animations.

## Verification ownership

- Lifecycle tests retain once-only cleanup, close veto and terminal-blocking coverage.
- Actual Windows motion and ROG Ally focus checks.

## Explicit exclusions

- Custom caption, flashy success animations or new loading screens.
- Sacrificing safe shutdown for appearance.

Follow the [task index](../README.md) and the current architecture, testing and Flutter conventions. Keep SDK identity/write safety and TUI unchanged; update owning conventions when a behavior changes.
