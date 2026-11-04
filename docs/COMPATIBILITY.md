# Compatibility and verification matrix

**Ludava currently supports no games, game builds, memory reads or modifications.** The following are research targets, not shipped capabilities.

| Game/edition | Identifier | Environment | Capability | Status |
| --- | --- | --- | --- | --- |
| Ratchet & Clank 2 — PS3 Collection | `BCUS98282` | RPCS3 / Windows 11 | Read bolts | Unverified |
| Ratchet & Clank 2 — PS3 Collection | `BCUS98282` | RPCS3 / Windows 11 | Write bolts | Unverified; disabled |
| Ratchet & Clank 2 — standalone PS3 | `NPUA80644` | RPCS3 / Windows 11 | Read/write bolts | Not investigated for Ludava |

A standalone profile's memory mapping must not be assumed to apply to the Collection.

## Evidence vocabulary

- **Unverified:** insufficient reproducible information.
- **Documented:** source material exists; runtime behavior not verified.
- **Investigated:** diagnostic observations exist but correlation is incomplete.
- **Read verified:** exact build and runtime recorded; complete memory reads match two different genuine in-game values.
- **Write verified:** read verified first; guarded write validated by full write/read-back and in-game outcome with documented precautions.
- **Blocked/unsupported:** do not execute the feature, due to missing or negative evidence.

A connected process, successful native addon import or plausible memory value is not verification.

## Evidence required

- Date, Windows version, RPCS3 version, exact game/build identity method and gameplay state.
- On-screen bolt counts **before and after an ordinary gameplay change**, with associated read-only diagnostic output.
- Host address translation and endianness rationale, linked sources and reproducible steps.
- Exact results, failures, partial reads, limitations and relevant PRs.
- For writes: documented verified mapping, range, save backup, complete write, read-back and actual game effect.

Avoid exposing personal local paths, save data or incidental private information in public logs.
