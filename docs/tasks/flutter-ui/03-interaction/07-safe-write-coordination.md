# Task 07 — Serialized, revision-safe nonblocking writes

**Status:** Planned, not implemented or live-validated.
**Prerequisite:** PR #16 must be merged before this task begins.
**Dependencies:** Task 01.
**PR scope:** One primary responsibility in a focused branch from latest merged main.

## Goal and changes

- Examine the existing synchronous GameWriteResult bridge and SDK/native process-handle boundary before choosing safe responsive execution; async alone is not offloading.
- Serialize writes and associate each request/result with exact session, field and edit revision; old results must not replace newer drafts.
- Respect SDK operation guard, reentrant observation, write/read-back verification and terminal shutdown; never open a second SDK client.

## Acceptance criteria

- Rapid requests never cause overlapping unsafe SDK operations or stale-session writes.
- Obsolete results cannot roll back newer text; failure is never mistaken for success.
- Actual UI remains responsive under measured representative RPCS3 write latency.

## Verification ownership

- Mocktail collaborator tests verify order, guards, rejected requests and forbidden calls.
- Native/Windows integration validates any off-thread memory-handle assumptions.

## Explicit exclusions

- Focus-loss commit UX (task 8).
- Duplicating SDK safety logic, fire-and-forget Redux commands or a generic command bus.

Follow the [task index](../README.md) and the current architecture, testing and Flutter conventions. Keep SDK identity/write safety and TUI unchanged; update owning conventions when a behavior changes.
