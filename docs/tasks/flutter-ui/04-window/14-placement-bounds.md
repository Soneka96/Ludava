# Task 14 — Persist scale/position and keep window on-screen

**Status:** Planned, not implemented or live-validated.
**Prerequisite:** The existing static verification-status cleanup in docs/ROADMAP.md must be merged before any Flutter UI task.
**Dependencies:** Task 12, Task 13.
**PR scope:** One primary responsibility in a focused branch from latest merged main.

## Goal and changes

- Persist preferred scale and ordinary position rather than an independent width/height per game.
- On startup, game changes, scale changes, monitor removal, taskbar/work-area or DPI changes, clamp/anchor to an appropriate monitor's usable area.
- Avoid recentering every Redux rebuild; choose fallback scale/scroll behavior if full content cannot fit.

## Acceptance criteria

- Growing from one to five fields near screen edge never strands controls off-screen.
- Returning from another monitor arrangement restores an accessible caption/window.
- Editing and value refresh don't reposition the window.

## Verification ownership

- Bounds and persistence tests cover edge, taskbar, multi-monitor and DPI cases.
- Windows monitor/screen integration validates real work-area behavior.

## Explicit exclusions

- Virtual keyboard avoidance (task 15).
- Settings screen or per-game window-size storage.

Follow the [task index](../README.md) and the current architecture, testing and Flutter conventions. Keep SDK identity/write safety and TUI unchanged; update owning conventions when a behavior changes.
