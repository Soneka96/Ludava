# Task 01 — Reconcile Flutter UX conventions

**Status:** Planned, not implemented or live-validated.
**Prerequisite:** The existing static verification-status cleanup in docs/ROADMAP.md must be merged before any Flutter UI task.
**Dependencies:** None beyond preceding cleanup.
**PR scope:** One primary responsibility in a focused branch from latest merged main.

## Goal and changes

- Update authoritative Flutter interaction, architecture and test conventions to supersede the old Apply/Cancel, custom title bar, maximize, and fixed-layout assumptions.
- State who owns editor drafts, Redux snapshots, SDK write safety, UI refresh scheduling, and native window behavior; keep the TUI unchanged.
- Document one fixed status slot, native dynamic title, field-blur commit, live formatting, optimistic writes, automatic refresh, touch support and geometric invariants.

## Acceptance criteria

- No contradictory old/new behavioral requirements remain in governing documents.
- No implementation code changes in this task; the static verification-status cleanup has already merged.
- SDK identity and read/write safeguards, strict test boundaries and one-way shutdown semantics are untouched.

## Verification ownership

- Validate internal documentation links and review diff for duplicate or weakened rules.
- No code tests needed for this documentation-only PR.

## Explicit exclusions

- Redesigning app components or implementing polling.
- Reworking static verification-status metadata; that is the preceding roadmap initiative.

Follow the [task index](../README.md) and the current architecture, testing and Flutter conventions. Keep SDK identity/write safety and TUI unchanged; update owning conventions when a behavior changes.
