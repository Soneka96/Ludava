# Roadmap

Milestones describe **verified outcomes**, not completed code alone.

## M0 — Project and documentation foundation

- [x] Choose project name: Ludava.
- [x] Create `Soneka96/Ludava` and initialize `main` with documentation only.
- [x] Define MVP, architectural principles and evidence-based compatibility rules.
- [ ] Decide licensing and repository visibility before accepting contributions or releasing binaries.
- [ ] Review RatchetHax PR #1's verified real-game research.

**Exit:** evidence-backed requirements for a narrow Dart proof of concept.

## M1 — Read-only native proof of concept

- [ ] Implement a narrowly scoped Dart Windows native-memory adapter using checked process reads.
- [ ] Test address widths, byte counts, decoding, error handling and interfaces with fake dependencies.
- [ ] Identify the exact active build, rejecting unknown/unsupported builds.
- [ ] Match two distinct legitimate in-game bolt counts with successful reads.

**Exit:** repeatable read-only evidence for one build, without memory writes.

## M2 — One guarded modification

- [ ] Gate modifications by verified build/address identity.
- [ ] Validate value ranges, write success, read-back and failure cases.
- [ ] Verify one deliberate in-game modification with a backed-up save.

**Exit:** a verified, narrowly scoped read/write operation.

## M3 — Minimal Flutter desktop interface

- [ ] Present build/connection status, current bolts and meaningful errors.
- [ ] Enable a single deliberate write only for an independently verified build.
- [ ] Test the Windows build with real RPCS3 observations.

**Exit:** usable first release; not a general-purpose trainer.

## M4 — Incremental expansion

- [ ] Add game builds and new features only when individually researched and verified.
- [ ] Retain small PRs, tests, evidence and safe defaults.
- [ ] Reevaluate architecture and packaging only for concrete requirements.

**Not planned now:** a large dashboard, plugin framework, automation services, additional emulator backends or unverified feature tables.
