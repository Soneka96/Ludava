# Task 13 — Native proportional resizing and DPI-aware content scale

**Status:** Planned, not implemented or live-validated.
**Prerequisite:** The existing static verification-status cleanup in docs/ROADMAP.md must be merged before any Flutter UI task.
**Dependencies:** Task 12.
**PR scope:** One primary responsibility in a focused branch from latest merged main.

## Goal and changes

- Keep a client-content aspect ratio based on field count during interactive Windows edge/corner resizing, without resize-then-snap artifacts.
- Apply a coherent user scale to typography, spacing, icons, inputs and hit areas; native caption remains Windows-owned.
- Separate Windows DPI from user scale, enforce reasonable work-area/min/max bounds, and handle accessibility scaling.
- Validate any window_manager/Win32 native sizing integration rather than assuming Flutter AspectRatio alone controls OS bounds.

## Acceptance criteria

- Dragging resizes proportionally; no stretching or caret misplacement.
- Changing DPI does not double-apply scale or clip inputs.
- Native minimize/close stay standard and maximize remains disabled.

## Verification ownership

- Pure scaling geometry and widget overflow tests.
- Real Windows drag-resize and mixed-DPI validation.

## Explicit exclusions

- Persistence/monitor recovery (task 14).
- New design token or sizing framework.

Follow the [task index](../README.md) and the current architecture, testing and Flutter conventions. Keep SDK identity/write safety and TUI unchanged; update owning conventions when a behavior changes.
