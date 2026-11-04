# Architecture and testing strategy

**The first read-only implementation now follows these boundaries.** It remains a small set of files, not a multi-package class hierarchy.

## Responsibilities

| Component | Responsibility | Excludes |
| --- | --- | --- |
| Presentation (Flutter later) | Show connection/build status, bolts and errors; collect explicit user actions | Calling Windows memory APIs or determining offsets |
| Bolt service | Resolve and decode the experimental bolt read; return explicit results | Native platform calls, treating a selected PID as game identity, writes |
| Build compatibility/profile | Describe the RC2 experimental field and its unverified status | Claiming that a user-selected process or profile proves the active build |
| Process-memory adapter | Open/close handles; checked read-only byte transfers; preserve native address width | Understanding bolts, weapons or planets; writing memory |

The RC2 profile cannot be marked trusted or writable in this implementation. Gate A still requires exact build identification and two different live in-game bolt readings.

Keep interfaces small and dependencies injectable where they materially improve testability. Use classes for stateful/lifecycle responsibilities, plain functions and data types for simple logic. Do not add a plugin architecture or an unnecessary inheritance hierarchy.

## Test approach

- **Unit tests:** Test behavior at its owner. Use mock/fake collaborators in consumers instead of retesting decoding or native calls everywhere.
- **Integration tests:** Exercise a few important seams (adapter/decoder, compatibility/service, failed reads and write guards).
- **Real environment tests:** Compare exact build and RPCS3 version with live gameplay; record enough evidence to reproduce the observations.

Do not treat passing mocks or plausible readings as game compatibility.

## Safety invariants

1. Reject unidentified and unsupported builds before enabling modifications.
2. Preserve full 64-bit host addresses; check ranges and native pointer width.
3. Verify read success and exact byte count. Never interpret a failed read as the value zero.
4. Decode explicit field types and endianness using deterministic tests.
5. Separate read and write permissions; keep unknown mappings unavailable.
6. Validate requested write values, require deliberate user action, check full write and read-back, then verify effect in actual gameplay during validation.
7. Surface errors and lost connections; never silently retry dangerous writes.

## Technology direction

Dart core with Windows native interop via [dart:ffi](https://dart.dev/interop/c-interop) is implemented for read-only diagnostics. A minimal [Flutter Windows](https://docs.flutter.dev/platform-integration/windows/setup) interface remains future work; the core has not been validated against RPCS3.
