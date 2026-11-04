# Ludava

> An independent game companion for reading, and eventually safely editing, verified game-state values.

**Status:** profile-driven Windows reader and CLI implemented. The only included profile is experimental RC2; no game build has been verified against a live Ludava read. The CLI rejects write requests until Ludava can verify the active game build.

## Start here

The first investigation target is Ratchet & Clank 2 in the PS3 Collection (`BCUS98282`) running in RPCS3 on 64-bit Windows 11. Its bolt field is an experimental profile entry, not a compatibility claim.

The reader uses one generic flow and selects fields from a game/build profile. To read the current RC2 bolt value, supply the RPCS3 process ID and the memory base for that session:

```powershell
dart run bin/ludava.dart read --game rc2-collection --field bolts --pid RPCS3_PID --memory-base 0xSESSION_BASE
```

The PID, memory base, and selected profile do not prove which game or build is running. Results remain labelled experimental until the build and live readings are independently verified.

The CLI accepts an explicit write request with `--value <integer> --confirm-write`, but currently returns an “active game build is not verified” status before opening the process. There is no writable profile or user-facing write path yet. The guarded write use case requires a verified build and field, a bounded value, confirmation, a complete write, and matching read-back; active build detection must be implemented before the CLI can enable it.

Run the automated checks with:

```powershell
dart analyze
dart test
dart format --output=none --set-exit-if-changed lib test bin
```

## Architecture

`lib/features/game_memory` owns shared profile-based reads and guarded writes. Games and builds are profile data; adding RC1 means adding its researched profile and registering it, not copying the reader. See [Architecture and testing](docs/ARCHITECTURE.md) for layer boundaries, class/file order, documentation links, and test naming.

- [MVP scope and acceptance gates](docs/MVP.md)
- [Compatibility evidence matrix](docs/COMPATIBILITY.md)
- [Roadmap](docs/ROADMAP.md)
- [Research handoff](docs/RESEARCH_HANDOFF.md)
- [Development policy and conventions](docs/DEVELOPMENT.md)

Technical references: [Dart native interop](https://dart.dev/interop/c-interop), [Flutter Windows development](https://docs.flutter.dev/platform-integration/windows/setup).

## Engineering principles

1. Add abstractions only for a real boundary or requirement.
2. Keep game profiles, memory access, and CLI responsibilities separate.
3. Test each behavior at its owner, using fakes for process-memory boundaries.
4. A failed read is never a zero; unsupported or unverified fields stay disabled.
5. Automated tests and plausible values do not prove game/build compatibility.
6. Keep work incremental and report limitations honestly.

## Repository status

The experimental RC2 profile uses guest offset `0x01329E80`, an unsigned 32-bit big-endian field. The session base can vary. The code has not been run against RPCS3, and it does not yet identify the active game build.

Ludava is intended as a **new, independently implemented project**, not a renamed fork or translated copy of [ParadoxEpoch's RatchetHax](https://github.com/ParadoxEpoch/RatchetHax), which is GPLv3 licensed. Cite research, independently reproduce critical measurements, and review provenance before reusing third-party code or curated data.

**Source available for learning — proprietary, all rights reserved.** Ludava is a personal project maintained by Soneka96. Everyone is welcome to view and study its source and independently implement ideas learned from it. This is **not** an open-source license: copying protected code into other projects, redistribution, or creating derivative works requires permission, except where law or GitHub's terms allow otherwise. **Commercial licensing may be negotiated individually** by contacting the repository owner; no price or automatic paid permission is offered. **External contributions are not accepted.** See [LICENSE](LICENSE) and [Development policy](docs/DEVELOPMENT.md). Third-party materials remain under their own terms.
