# Research handoff: RatchetHax → Ludava

Ludava's implementation is independently written. RatchetHax supplies the research basis and remains GPLv3; no RatchetHax source has been copied or mechanically translated.

## Owner-confirmed RC2 Collection research

RatchetHax PR #1 is merged. Its RC2 Collection investigation records the following tested-session values:

- Collection title ID: `BCUS98282`.
- RC2 subgame executable: `RC2.ppu.self`; inner app ID: `NPUA80644`.
- Bolt guest offset: `0x01329E80`; unsigned 32-bit, big-endian.
- Observed guest base: `0x300000000`, translating to host address `0x301329E80`.
- Two snapshots tracked a normal HUD change from 244012 to 244016.
- A targeted owner-authorized write changed 243866 to 244866; read-back and the HUD matched.

These findings establish the bolt mapping for the tested research session. They do not validate Ludava's separate Dart implementation, every RPCS3 build, other Collection revisions, or any other game field. The memory base may vary by session.

## RC1 and RC3 Collection research

RatchetHax PR #1 also contains owner-confirmed, bolt-only research for the other two Collection games (`BCUS98282`):

| Embedded game | Bolt guest offset | Observed host address at base `0x300000000` | Value |
| --- | --- | --- | --- |
| Ratchet & Clank 1 | `0x009BC3A0` | `0x3009BC3A0` | big-endian unsigned 32-bit |
| Ratchet & Clank 3 | `0x00C1EDAC` | `0x300C1EDAC` | big-endian unsigned 32-bit |

RC1 research tracked normal HUD changes `5155 → 5105 → 5055` and a user-confirmed write to `105055`. RC3 tracked `753 → 755` and a user-confirmed HUD write to `1755`. Exact active PPU SELF names and independent restart reproduction remain unestablished. These observed fields are now implemented as independently written Ludava profiles. On November 5, 2026, the owner verified Ludava RC1 read `22` and write `12,312`, and RC3 read `248` and write `1,312,312`; the owner-provided game screenshots show the requested final balances on the HUD. The RC3 screenshot also shows a separate `+20` gameplay notification, whose timing relative to the displayed balance was not independently established. The screenshots show RPCS3 `0.0.43-20565`, but exact executable fingerprints remain unknown. Do not infer support for standalone versions or other game fields.

## Ludava implementation status

Ludava stores separate RC1, RC2 and RC3 Collection bolt fields in game-specific profiles with `researchConfirmed` write eligibility for their independently observed research offsets. A separate RPCS3 runtime experiment measured distinct PPU hashes for the Collection EBOOT and all three subgames on RPCS3 `0.0.43-20565-eee3f0f7`, including menu returns, subgame transitions, RC3 stop, and process restart. See [GAME_DETECTION.md](GAME_DETECTION.md) for the hashes and lifecycle observations.

The detector matches only fresh, ordered PPU-load evidence with the shared Collection title ID, measured hash, and executable name. It resolves a guest memory base only when fresh candidate logs agree and the selected process/session is not ambiguous. Manual profile selection remains disclosed and read-only. Before a write, the CLI rechecks process session, current PPU identity, and memory base, then uses a complete preliminary read, explicit confirmation, complete native transfer, and matching read-back.

The final compiled CLI was live-smoke-tested with RC2 after the restart: it selected the profile and base automatically and displayed a bolt read of `0`, which does not prove gameplay was active. RC1 and RC3 detector runs are still needed before calling automatic detection live-verified. Unknown hashes, unsupported games, conflicting logs, and ambiguous process ownership remain unresolved.

Automated tests cover the implementation using fakes and controlled local memory. On November 5, 2026, the owner tested Ludava live with Ratchet & Clank 2 in the PS3 Collection under RPCS3. With the game closed, the initial read failed; a startup read returned `0`, and a gameplay read returned `110`. The owner requested a write to `120`; Ludava reported success and displayed `120`, and the owner screenshot showed `120` on the game's HUD. The observed guest base was `0x300000000`.

The exact Windows/RPCS3 versions, executable fingerprint, and complete build-verification data for this earlier read/write session were not supplied. These are successful live read/write observations in the owner's tested environment, not evidence of compatibility with every RPCS3 version or game build. A successful read of `0` does not prove gameplay is active. The later PPU hash experiment is separate runtime evidence and does not retroactively identify the earlier write session.

## Sources and licensing

- [Original RatchetHax](https://github.com/ParadoxEpoch/RatchetHax) — GPLv3.
- [RatchetHax working fork](https://github.com/Soneka96/RatchetHax).
- [RatchetHax PR #1: RC2 Collection investigation](https://github.com/Soneka96/RatchetHax/pull/1) — merged; contains the investigation and validation report.

## Next live-validation work

1. Run the updated Ludava detector live through no-game startup, RC1, RC2, RC3, menu returns, stop, and restart.
2. Test an unsupported game and simultaneous RPCS3 processes; verify unknown or shared-log evidence remains unresolved.
3. Capture the exact Windows version and additional emulator builds before making broader compatibility claims.
4. Record recovery steps and any new runtime limitations in `COMPATIBILITY.md`.

Do not add health, multiplier, planet, equipped-item, weapon, gadget, or unlock fields without separate evidence. Keep snapshots and logs local unless they are deliberately scrubbed and shared.
