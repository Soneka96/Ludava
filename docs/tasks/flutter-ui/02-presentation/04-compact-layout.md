# Task 04 — Compact and stable 1–5-field layout

**Status:** Planned, not implemented or live-validated.
**Prerequisite:** The existing static verification-status cleanup in docs/ROADMAP.md must be merged before any Flutter UI task.
**Dependencies:** Task 01, Task 03.
**PR scope:** One primary responsibility in a focused branch from latest merged main.

## Goal and changes

- Make a tight screen with one left-aligned label and one right-aligned numeric control per field, stable field-ID keys and consistent height.
- Remove excessive panel whitespace, per-field cards and controls that change width in edit mode; keep existing Graphite & Teal tokens and presets.
- Design for 1–5 fields, long names, large values, zero-field/unsupported states, small screens and accessible touch targets.

## Acceptance criteria

- One-field content is genuinely compact; five fields are consistently aligned.
- Normal, focused, writing and error states retain the same row geometry.
- No overflow at realistic minimum content widths and accessibility text scaling.

## Verification ownership

- TrainerFieldsPanel widget tests mock its exclusive ViewModel, children only at their responsibility boundary.
- Compare row geometry/overflow at representative widths and different field counts.

## Explicit exclusions

- Writing or polling logic.
- New theme framework, sliders, plus/minus or Apply/Cancel controls.

Follow the [task index](../README.md) and the current architecture, testing and Flutter conventions. Keep SDK identity/write safety and TUI unchanged; update owning conventions when a behavior changes.
