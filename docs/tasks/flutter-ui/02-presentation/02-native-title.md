# Task 02 — Native Windows caption and dynamic game title

**Status:** Planned, not implemented or live-validated.
**Prerequisite:** The existing static verification-status cleanup in docs/ROADMAP.md must be merged before any Flutter UI task.
**Dependencies:** Task 01.
**PR scope:** One primary responsibility in a focused branch from latest merged main.

## Goal and changes

- Replace Flutter-drawn caption and window controls with the native Windows title bar in the existing window controller/shell.
- Set title to Ludava — Game Name from authoritative active game identity, otherwise Ludava; update without recreating window.
- Keep native minimize/close, disable maximize while allowing later constrained resizing, and preserve native-close veto and SDK cleanup.

## Acceptance criteria

- Switching games changes the real native caption without moving focus or fields.
- No duplicate game title in the content header; long names truncate safely.
- No regression in native drag/minimize/close, close failure/retry or terminal operation guard.

## Verification ownership

- Controller/lifecycle unit tests for app-owned behavior, with forbidden side effects verified.
- Actual Windows native caption/close tests; widget tests cannot prove native integrations.

## Explicit exclusions

- Proportional scale or window sizing.
- Custom Snap Layouts or a recreated native caption.

Follow the [task index](../README.md) and the current architecture, testing and Flutter conventions. Keep SDK identity/write safety and TUI unchanged; update owning conventions when a behavior changes.
