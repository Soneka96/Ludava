# Ludava

> A Windows game-memory trainer with an interactive, profile-driven RC2 bolt CLI.

**Status:** the interactive CLI discovers RPCS3 processes, reads RC2 Collection bolts, and can request guarded writes using owner-confirmed research. The owner has tested a Ludava read against a live RPCS3 session. A live Ludava write and ROG Ally validation are not yet confirmed.

## Start here

Start the interactive trainer in a Windows terminal:

```powershell
dart run bin/ludava.dart
```

Ludava selects a single running RPCS3 process automatically or asks you to choose when multiple instances are found. It checks fresh `RPCS3.log` files near the selected executable for a guest memory base. A log value remains a candidate and must be confirmed. If no candidate is found, you can accept the research-tested `0x300000000` suggestion for that session or enter another base. That value may differ between sessions.

Choose the Ratchet & Clank 2 PS3 Collection profile (`BCUS98282`), then refresh or set bolts from the menu. Writes require entering a value and confirming the target process, profile, and base. Ludava reuses the existing write validation and read-back verification. It does not identify the active game build; use the profile only when RC2 is running inside the Collection.

The bolt field is guest offset `0x01329E80`, an unsigned 32-bit big-endian value. It is not the standalone RC2 profile.

## Diagnostic commands

The existing explicit commands remain available for troubleshooting and automation. Read the current bolt count:

```powershell
dart run bin/ludava.dart read --game rc2-collection --field bolts --pid RPCS3_PID --memory-base 0x300000000
```

Repeat the `read` command to refresh the value. Each command opens the selected process for that operation and closes its handle before exiting.

Write an unsigned 32-bit bolt value explicitly with `--value` and `--confirm-write`:

```powershell
dart run bin/ludava.dart write --game rc2-collection --field bolts --pid RPCS3_PID --memory-base 0x300000000 --value 244866 --confirm-write
```

The CLI writes four big-endian bytes, checks the native result and byte count, then reads the field back. It reports success only when the observed read-back equals the requested value. The selected process and profile do not prove the running game or RPCS3 build. RatchetHax's owner-confirmed RC2 research is separate from live validation of Ludava's Dart implementation.

## Portable Windows executable

Build a standalone Windows x64 executable with:

```powershell
.\tool\build_windows.ps1
```

Copy `build\Ludava.exe` to the ROG Ally and launch it from a terminal. Dart and Flutter are not required on the Ally. See [Windows build and ROG Ally setup](docs/WINDOWS_BUILD.md) for the build and transfer steps.

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
- [Windows build and ROG Ally setup](docs/WINDOWS_BUILD.md)
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

The RC2 profile uses guest offset `0x01329E80`, an unsigned 32-bit big-endian field, with write eligibility marked `researchConfirmed`. The tested research session used guest base `0x300000000`; the base can vary. The owner reports a successful live RPCS3 bolt read with Ludava. The write operation still requires live validation, and process discovery does not identify the active game build.

Ludava is intended as a **new, independently implemented project**, not a renamed fork or translated copy of [ParadoxEpoch's RatchetHax](https://github.com/ParadoxEpoch/RatchetHax), which is GPLv3 licensed. Cite research, independently reproduce critical measurements, and review provenance before reusing third-party code or curated data.

**Source available for learning — proprietary, all rights reserved.** Ludava is a personal project maintained by Soneka96. Everyone is welcome to view and study its source and independently implement ideas learned from it. This is **not** an open-source license: copying protected code into other projects, redistribution, or creating derivative works requires permission, except where law or GitHub's terms allow otherwise. **Commercial licensing may be negotiated individually** by contacting the repository owner; no price or automatic paid permission is offered. **External contributions are not accepted.** See [LICENSE](LICENSE) and [Development policy](docs/DEVELOPMENT.md). Third-party materials remain under their own terms.
