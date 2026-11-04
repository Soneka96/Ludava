# MVP — one verified feature, one verified build

**Current status:** planned, not implemented.

## Objective

Read and, after separate safety validation, modify the bolt count for one *exactly identified* game build running in RPCS3 on Windows 11.

Initial investigation target: Ratchet & Clank 2 in the PS3 Collection (`BCUS98282`). This does **not** imply that its correct memory addresses are known.

## First user-visible capability

- Detect and establish an exact supported game/build; otherwise clearly indicate unknown/unsupported.
- Show the current bolt count after a complete, verified read.
- Distinguish a real value of zero from access denied, failed read, partial read, disconnection or unsupported build.
- Once a write has been independently verified for that exact build, permit a single explicit user-entered value in a documented safe range.
- Report write success only after complete write and read-back checks; release-level compatibility also requires in-game confirmation.
- Disable write controls wherever any precondition is unverified.

## Out of scope

Other games/builds, health, inventory, weapons, unlock states, teleportation, repeated/frozen writes, complex dashboards, plugins, cloud services and multi-platform backends.

## Gates

### Gate A — Dart read-only proof of concept

- Native process memory calls preserve full 64-bit addresses and check return codes and bytes read.
- Typed, correctly endian-decoded values have deterministic fake-based tests.
- The application layer is testable without RPCS3 or Windows memory APIs.
- At least **two different** normal in-game bolt counts match two independently collected successful reads on the exact identified build and recorded RPCS3 version.

### Gate B — guarded write

- Unknown builds and unverified addresses are rejected.
- Input range, failed/partial write and read-back mismatch tests pass.
- A deliberate write against a backed-up save is verified in-game and documented, with limitations and recovery guidance.

### Gate C — minimal Flutter desktop interface

- Shows process/build status, bolt value and meaningful errors.
- Allows a single deliberate edit only when the verified build is writable.
- Windows build and real-game scenario are tested.

The MVP is complete only after all three gates pass. Partial milestones may be documented without claiming a usable complete release.
