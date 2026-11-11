# Task 03 — One fixed-height status and Refresh header

**Status:** Planned, not implemented or live-validated.
**Prerequisite:** The existing static verification-status cleanup in docs/ROADMAP.md must be merged before any Flutter UI task.
**Dependencies:** Task 01, Task 02.
**PR scope:** One primary responsibility in a focused branch from latest merged main.

## Goal and changes

- Simplify TrainerGameHeader to connection/error status and one accessible Refresh action, not a second game title.
- Use the same fixed status slot for connected, disconnected, unsupported and field write failures; connection failure takes precedence.
- Provide tap-accessible details through an overlay/popover without inserting or moving layout content.

## Acceptance criteria

- Status text and failure details never enlarge header or shift field rows, including long messages.
- Write successes have no checkmarks, saving animations, spinners or toasts.
- Refresh remains a working callback and is accessible for touch and keyboard.

## Verification ownership

- Ordinary connected-widget tests Mocktail-mock its exclusive ViewModel.
- Test stable header bounds, error precedence, long text and action exposure.

## Explicit exclusions

- New refresh coordination (task 11).
- Extra error row, per-field indicators or hover-only information.

Follow the [task index](../README.md) and the current architecture, testing and Flutter conventions. Keep SDK identity/write safety and TUI unchanged; update owning conventions when a behavior changes.
