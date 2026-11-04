# Research handoff: RatchetHax → Ludava

**Pending.** Ludava is independently implemented; this process transfers reproducible knowledge, not source code.

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

- [ ] PR #1 provides reproducible diagnostic findings.
- [ ] Exact build and RPCS3 version are recorded.
- [ ] Read failures and valid values are distinguishable.
- [ ] Candidate mappings are clearly separated from verified measurements.
- [ ] License and source/data provenance are reviewed.
- [ ] A narrow Dart read-only implementation task is approved.

**Next action:** complete the RatchetHax investigation and review the evidence before starting application code in Ludava.
