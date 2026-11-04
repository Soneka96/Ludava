# Research handoff: RatchetHax → Ludava

**Reviewed; evidence remains incomplete.** Ludava is independently implemented; this process transfers research observations, not source code. The linked RatchetHax PR is still a draft and lists live validation as pending. Its current probe code is not treated as proof of Ludava compatibility.

## Historical observations supplied for this implementation

The owner reports testing the bolt location in RC2 inside Collection `BCUS98282`, with the HUD confirming a bolt change. The reported field is guest offset `0x01329E80`, unsigned 32-bit, big-endian; the tested session used guest memory base `0x300000000`, yielding host address `0x301329E80`. The active executable was reported as `RC2.ppu.self`, with internal app ID `NPUA80644`. Two snapshots tracked ordinary gameplay movement from 244,012 to 244,016; a separate owner-authorized write experiment reportedly changed 243,866 to 244,866.

These are historical owner/research observations. The implementation in this repository has not been run against RPCS3, does not identify the active build, and does not treat those observations as compatibility verification. The base may vary by session and no exact executable fingerprint or RPCS3 version is recorded here. RatchetHax PR #1 remains draft with validation pending, so its code and findings are not substituted for Ludava runtime evidence.

## Sources

- [Original RatchetHax](https://github.com/ParadoxEpoch/RatchetHax) — GPLv3.
- [RatchetHax working fork](https://github.com/Soneka96/RatchetHax).
- [RatchetHax PR #1: RC2 Collection memory investigation](https://github.com/Soneka96/RatchetHax/pull/1).

## Findings needed

1. Exact RC2 Collection game/build identification and live RPCS3 version.
2. RPCS3 guest-to-host mapping assumptions, address width and pointer truncation analysis.
3. How invalid or partial native reads are distinguished from valid zero values.
4. At least two independent read-only measurements matching distinct real in-game bolt counts.
5. Candidate versus verified addresses with sources and experimental method.
6. Contradictory results, environmental constraints, tests not run and next diagnostic steps.

## Handoff and independent implementation

1. Review PR #1 findings and real machine logs, not just the PR's existence or merge status.
2. Preserve citations to original references and observed experiments.
3. Reproduce critical facts using a new Dart read-only implementation.
4. Do not copy or mechanically translate RatchetHax's GPLv3 source or curated tables without a separate license and provenance assessment.
5. Permit guarded writes only in a later, independently validated change.

## Checklist

- [x] Historical owner observations from the implementation brief are recorded above.
- [ ] RatchetHax PR #1 provides reproducible live diagnostic findings; its validation is still pending.
- [ ] Exact build and RPCS3 version are recorded.
- [x] The Dart adapter and service distinguish complete reads from failures and partial reads.
- [x] The RC2 mapping is labelled experimental and separated from verified compatibility.
- [x] Licensing and source provenance were reviewed; RatchetHax implementation code was not reused.
- [x] The narrow Dart read-only implementation scope was authorized and implemented.
- [ ] Two distinct real in-game values have been independently verified through Ludava.

**Next action:** record the exact active build and RPCS3 version, then perform and document two read-only Ludava observations that match different in-game bolt counts. Do not mark Gate A complete before that evidence exists.
