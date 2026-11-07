# Diagnostic CLI usage

Ludava's Nocterm frontend is intended for normal interaction. The CLI commands below are optional troubleshooting tools for development; they are **not** required to use Ludava while playing.

From the repository root, run `dart run bin/ludava.dart --help` for current command syntax. The TUI package's entry point is `apps/ludava_tui/bin/ludava.dart`.

## Read a named field

```powershell
dart run bin/ludava.dart read --game rc2-collection --field bolts --pid RPCS3_PID --memory-base SESSION_BASE
```

Replace the sample profile, PID and `SESSION_BASE` with values from the *current* RPCS3 process/session. The profile in the example is illustrative; available profiles and fields are defined in the SDK catalog. Never assume an observed research base is universal.

Manual profile selection does **not** establish the currently running game. Diagnostic reads disclose when current identity evidence is missing.

## Deliberate guarded write

```powershell
dart run bin/ludava.dart write --game rc2-collection --field bolts --pid RPCS3_PID --memory-base SESSION_BASE --value 1000 --confirm-write
```

Substitute your actual verified game/profile, session base, PID and desired value. This is **not** an instruction to write the example value to an arbitrary process. Writes revalidate current executable identity and session base, field/profile permissions, bounds, preliminary read, complete transfer and read-back. They fail closed on missing or ambiguous evidence. See [game detection](../features/game-detection.md) and [game memory](../features/game-memory.md) for the contracts.

For building the executable and native discovery DLL, see the [Windows build guide](windows-build.md).
