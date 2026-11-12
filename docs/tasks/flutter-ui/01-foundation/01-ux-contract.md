# Task 01 — Reconcile Flutter UX conventions

**Status:** Planned, not implemented or live-validated.
**Prerequisite:** PR #16 must be merged before this task or any later Flutter UI task begins.
**Dependencies:** PR #16 merged.
**PR scope:** One primary responsibility in a focused branch from latest merged main.

## Goal and changes

- Update authoritative Flutter interaction, architecture and test conventions to supersede the old Apply/Cancel, custom title bar, maximize, and fixed-layout assumptions.
- State who owns editor drafts, Redux snapshots, SDK write safety, UI refresh scheduling, and native window behavior; keep the TUI unchanged.
- Offer editing for registered fields with an exact successful numeric read. Keep numeric parsing in the frontend, leave field ranges and write authorization to the SDK on write submission, and bind active drafts to their originating process/session and field mapping.
- Document one fixed status slot, native dynamic title, field-blur commit, live formatting, optimistic writes, automatic refresh, touch support and geometric invariants.

## Acceptance criteria

- No contradictory old/new behavioral requirements remain in governing documents.
- No implementation code changes in this task; PR #16's SDK metadata and frontend editing-policy corrections are prerequisites and must already be merged.
- SDK identity and read/write safeguards, strict test boundaries and one-way shutdown semantics are untouched.

## Verification ownership

- Validate internal documentation links and review diff for duplicate or weakened rules.
- No code tests needed for this documentation-only PR.

## Explicit exclusions

- Redesigning app components or implementing polling.
- Reworking PR #16's SDK metadata or trainer editing behavior; those changes are prerequisites for this documentation-only task.

Follow the [task index](../README.md) and the current architecture, testing and Flutter conventions. Keep SDK identity/write safety and TUI unchanged; update owning conventions when a behavior changes.
