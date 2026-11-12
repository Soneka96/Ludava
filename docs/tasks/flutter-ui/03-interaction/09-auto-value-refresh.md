# Task 09 — Fast Flutter-only value refresh and edit pause

**Status:** Planned, not implemented or live-validated.
**Prerequisite:** PR #16 must be merged before this task begins.
**Dependencies:** Task 06, Task 07, Task 08.
**PR scope:** One primary responsibility in a focused branch from latest merged main.

## Goal and changes

- Create one coordinated Flutter scheduler that invokes existing SDK capability/Redux observation for automatic value reads; Nocterm remains manual.
- Pause numeric refresh when any field is focused or relevant writes conflict, resume after editing/write boundary; field-to-field transitions never unpause briefly.
- Prevent overlapping ticks and outdated in-flight snapshots from overwriting current drafts or optimistic values.
- Measure interval and impact on laptop and ROG Ally, and stop/throttle safely when minimized or shutting down.

## Acceptance criteria

- Visible nonedited values follow successfully read RPCS3 values; focused drafts remain untouched.
- No queued timer backlog, competing SDK operations or late calls after SDK guard closes.
- No TUI workflow changes and no direct memory reads from widgets.

## Verification ownership

- Scheduler/middleware tests verify pause/resume/coalescing and forbidden calls after shutdown.
- Widget tests only own presentation behavior through mocked ViewModels.

## Explicit exclusions

- Game detection frequency (task 10).
- Guessing fixed refresh intervals without measurements.

Follow the [task index](../README.md) and the current architecture, testing and Flutter conventions. Keep SDK identity/write safety and TUI unchanged; update owning conventions when a behavior changes.
