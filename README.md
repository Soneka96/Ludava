# Ludava

> An independent, lightweight game companion for inspecting and safely modifying **verified** game-state values.

**Status: planning / documentation only (November 2026).** Ludava has no application code, verified memory addresses, supported game builds, or usable modifications yet.

## Vision

Start with one feature and one verified game build, then extend only when real evidence supports it. The name is deliberately unrelated to bolts, particular emulators, or specific games.

The initial investigation target is **Ratchet & Clank 2** inside *Ratchet & Clank Collection* (`BCUS98282`), running through RPCS3 on Windows 11.

Our first feature is **reading the current bolt count**. A guarded write operation is a separate milestone and requires independent verification. Other games and features are unsupported until individually validated.

## Technology direction

- **Dart:** application logic, testing, and a small Windows native-memory adapter using FFI.
- **Flutter for Windows:** a minimal interface **after** the read-only proof of concept is reliable.
- **Native APIs:** checked process access with correct 64-bit address handling, explicit byte counts, endianness, and meaningful errors.

These are planned technologies, not an implemented or tested solution. Windows-specific memory access remains Windows-specific even if Flutter can target multiple platforms.

Technical references: [Dart native interop](https://dart.dev/interop/c-interop), [Flutter Windows development](https://docs.flutter.dev/platform-integration/windows/setup).

## Engineering principles

1. **Simplicity first.** Add abstractions only when a concrete requirement warrants them.
2. **Separation of responsibilities.** UI, game behavior, compatibility checks, and process memory access remain distinct.
3. **Tests at the behavior owner.** Use fakes/mocks for dependencies; add small integration tests and independent real-game verification.
4. **Safe by default.** A failed read is not a zero, an unidentified build is not supported, and unverified builds cannot be written to.
5. **Evidence-based compatibility.** Successful connection or plausible values do not prove support.
6. **Focused PRs.** One implementation task per branch, with explicit acceptance criteria and honest test results.

## Initial repository status

This `main` branch contains **documentation only**. We will review [RatchetHax PR #1](https://github.com/Soneka96/RatchetHax/pull/1) for reproducible technical findings **before** opening the first implementation PR.

Ludava is intended as a **new, independently implemented project**, not a renamed fork or translated copy of [ParadoxEpoch's RatchetHax](https://github.com/ParadoxEpoch/RatchetHax), which is GPLv3 licensed. Cite research, independently reproduce critical measurements, and review provenance before reusing third-party code or curated data.

**Source available for learning — proprietary, all rights reserved.** Ludava is a personal project maintained by Soneka96. Everyone is welcome to view and study its source and independently implement ideas learned from it. This is **not** an open-source license: copying protected code into other projects, redistribution, or creating derivative works requires permission, except where law or GitHub's terms allow otherwise. **Commercial licensing may be negotiated individually** by contacting the repository owner; no price or automatic paid permission is offered. **External contributions are not accepted.** See [LICENSE](LICENSE) and [Development policy](docs/DEVELOPMENT.md). Third-party materials remain under their own terms.

## Documentation

- [First-release scope and acceptance criteria](docs/MVP.md)
- [Roadmap](docs/ROADMAP.md)
- [Architecture and testing](docs/ARCHITECTURE.md)
- [Compatibility evidence matrix](docs/COMPATIBILITY.md)
- [RatchetHax research handoff](docs/RESEARCH_HANDOFF.md)
- [Development and no-contributions policy](docs/DEVELOPMENT.md)
