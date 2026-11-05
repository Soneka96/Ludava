# Ludava

> A Windows game-memory trainer with a small, profile-driven RC2 bolt read/write CLI.

**Status:** the CLI reads and writes the RC2 Collection bolt field using owner-confirmed research. Ludava itself has not been tested against a live RPCS3 session, so this is not a Ludava compatibility claim.

## Start here

The included profile targets Ratchet & Clank 2 in the PS3 Collection (`BCUS98282`) running in RPCS3 on 64-bit Windows. The owner-confirmed research field is guest offset `0x01329E80`, an unsigned 32-bit big-endian value. It is not the standalone RC2 profile.

Select the RPCS3 process ID and supply that session's guest memory base. `0x300000000` is the base observed during the tested research session; check the current `RPCS3.log` before using a different session. Ludava does not identify the active game build, so use the RC2 profile only when RC2 is running inside the Collection.

Read the current bolt count:

```powershell
dart run bin/ludava.dart read --game rc2-collection --field bolts --pid RPCS3_PID --memory-base 0x300000000
```

Repeat the `read` command to refresh the value. Each command opens the process for that operation and closes its handle before exiting.

Write an unsigned 32-bit bolt value explicitly with `--value` and `--confirm-write`:

```powershell
dart run bin/ludava.dart write --game rc2-collection --field bolts --pid RPCS3_PID --memory-base 0x300000000 --value 244866 --confirm-write
```

The CLI writes four big-endian bytes, checks the native result and byte count, then reads the field back. It reports success only when the observed read-back equals the requested value. The process ID and chosen profile are manual inputs; Ludava does not validate the running game or RPCS3 build. RatchetHax's owner-confirmed RC2 research is separate from live validation of Ludava's Dart implementation.

Run the automated checks with:

```powershell
dart analyze
dart test
dart format --output=none --set-exit-if-changed lib test bin
```

## Architecture

`lib/features/game_memory` owns shared profile-based reads and writes. Games and builds are profile data; adding a game means adding its researched profile and registering it, not copying the reader. See [Architecture and testing](docs/ARCHITECTURE.md) for layer boundaries, class/file order, documentation links, and test naming.

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
4. A failed read is never a zero; fields without write-enabling research stay disabled.
5. Automated tests and plausible values do not prove game/build compatibility.
6. Keep work incremental and report limitations honestly.

## Repository status

The RC2 profile uses guest offset `0x01329E80`, an unsigned 32-bit big-endian field, with write eligibility marked `researchConfirmed`. The tested research session used guest base `0x300000000`; the base can vary. Ludava's code has not been run against RPCS3 and does not identify the active game build.

Ludava is intended as a **new, independently implemented project**, not a renamed fork or translated copy of [ParadoxEpoch's RatchetHax](https://github.com/ParadoxEpoch/RatchetHax), which is GPLv3 licensed. Cite research, independently reproduce critical measurements, and review provenance before reusing third-party code or curated data.

**Source available for learning — proprietary, all rights reserved.** Ludava is a personal project maintained by Soneka96. Everyone is welcome to view and study its source and independently implement ideas learned from it. This is **not** an open-source license: copying protected code into other projects, redistribution, or creating derivative works requires permission, except where law or GitHub's terms allow otherwise. **Commercial licensing may be negotiated individually** by contacting the repository owner; no price or automatic paid permission is offered. **External contributions are not accepted.** See [LICENSE](LICENSE) and [Development policy](docs/DEVELOPMENT.md). Third-party materials remain under their own terms.
