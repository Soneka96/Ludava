# Task 11 — Refresh as a meaningful recovery and reassurance action

**Status:** Planned, not implemented or live-validated.
**Prerequisite:** PR #16 must be merged before this task begins.
**Dependencies:** Task 03, Task 09, Task 10.
**PR scope:** One primary responsibility in a focused branch from latest merged main.

## Goal and changes

- Make the sole header Refresh request a real fresh sync/discovery, joining an equivalent in-progress operation rather than doing nothing or overlapping reads.
- Allow safe recovery from stale or failed background refresh; preserve single coordinator and terminal guard.
- During active editing, protect local drafts; perform safe identity checks as appropriate and defer numeric reconciliation.

## Acceptance criteria

- A healthy-session click produces a fresh check or joins already-running equivalent work.
- Repeated clicks cannot duplicate unsafe reads or interrupt typing; disconnection can attempt rediscovery.
- No layout/status noise on success; TUI remains unchanged.

## Verification ownership

- Coordinator/middleware tests cover manual priority, coalescing, recovery and shutdown.
- Header widget tests assert only its exposed action callback.

## Explicit exclusions

- Removing the button before live field testing.
- Creating another SDK/scheduler or unbounded retry loop.

Follow the [task index](../README.md) and the current architecture, testing and Flutter conventions. Keep SDK identity/write safety and TUI unchanged; update owning conventions when a behavior changes.
