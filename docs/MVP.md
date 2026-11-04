# MVP — one verified feature, one verified build

**Current status:** the profile-driven read foundation and generic CLI are implemented. Gate A live verification is incomplete. The guarded write use case is implemented, but active-build identification is not, so the CLI rejects every write request and no profile is writable.

## Objective

Read and, after separate safety validation, edit a selected value for one exactly identified game build running in RPCS3 on Windows 11. The initial target is Ratchet & Clank 2 in the PS3 Collection (`BCUS98282`).

## First user-visible capability

- Select a supported game profile and a named field such as `bolts`.
- Show a value only after a complete, correctly decoded read.
- Distinguish a real zero from access denied, failed/partial reads, disconnection, invalid mapping, and unsupported fields.
- Reject unknown or unverified builds and fields.
- Allow editing only after both the active build and field are verified, within a documented range, after explicit confirmation, and only report success after complete write and matching read-back.
- Keep edit requests disabled while any precondition is missing.

The current CLI supports generic reads. It parses a write request but rejects it before opening the process because it cannot yet identify the active game build. This limitation is intentional.

## Out of scope

Other capabilities such as health, inventory, weapons, unlock states, teleportation, repeated/frozen writes, complex dashboards, plugins, cloud services, and multi-platform backends.

## Gates

### Gate A — read one verified field

- Generic profile/field definitions, a read use case, checked Windows memory adapter, and profile-selecting CLI exist.
- Native reads preserve 64-bit addresses and require native success plus the exact requested byte count.
- Typed values decode with explicit endianness; fake-based tests distinguish zero from failure.
- Identify the exact active game/build and RPCS3 version.
- Match at least **two different** normal in-game values against independent Ludava reads.

Code and mocked tests do not satisfy the live verification requirement.

### Gate B — one guarded edit

- Identify the active build from process/game evidence; a PID and selected profile alone are not proof.
- Verify the exact profile and field for writing, set an allowed range, and reject all other fields.
- Require explicit user confirmation, a complete native write, and a matching read-back.
- Verify one deliberate edit in-game with a backed-up save and document recovery steps.
- Enable the CLI write path only after active-build verification is implemented.

### Gate C — minimal Flutter desktop interface

- Show process/build status, selected field, value, and meaningful errors.
- Enable editing only when the verified build and field are writable.
- Test the Windows build and the real-game scenario.

The MVP is complete only after all three gates pass. Partial milestones may be documented without claiming a usable complete release.
