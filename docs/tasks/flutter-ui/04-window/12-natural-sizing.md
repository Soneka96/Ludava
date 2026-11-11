# Task 12 — Natural Windows size from 1–5 fields

**Status:** Planned, not implemented or live-validated.
**Prerequisite:** The existing static verification-status cleanup in docs/ROADMAP.md must be merged before any Flutter UI task.
**Dependencies:** Task 02, Task 03, Task 04.
**PR scope:** One primary responsibility in a focused branch from latest merged main.

## Goal and changes

- Compute natural client height from fixed header, stable rows and field count, plus compact loading/disconnected/empty states.
- Account for measured Windows caption, native borders and DPI when setting outer window dimensions.
- Change size on meaningful field-count/game-state changes, not on edit, refresh, or header error; provide safe fallback if screen is too small.

## Acceptance criteria

- One-field trainer is smaller than five-field trainer without excess whitespace.
- Neither native title nor input controls are cut off; normal operation doesn't cause window-size jitter.
- Actual client/outer sizes are correct on Windows, including taskbar boundaries.

## Verification ownership

- Pure sizing policy tests and Flutter overflow tests.
- Windows native frame/client sizing integration.

## Explicit exclusions

- Proportional drag handling (task 13).
- Window animation (task 16).

Follow the [task index](../README.md) and the current architecture, testing and Flutter conventions. Keep SDK identity/write safety and TUI unchanged; update owning conventions when a behavior changes.
