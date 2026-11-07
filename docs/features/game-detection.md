# RPCS3 game detection

## Responsibility

The SDK's `game_detection` feature identifies the **current active executable** for a selected RPCS3 process and resolves a matching game profile. `rpcs3_connection` owns process discovery, metadata, raw log access and memory-base candidate extraction; the detection feature interprets the ordered events. Per-game PPU hashes and build observations are owned by individual documents under [`docs/games/`](../games/collection.md), not this mechanism guide.

## Active identity

- Ludava selects an RPCS3 process using PID, executable path and process creation time. Finding `rpcs3.exe` is not proof a game is running.
- For a supported game, the current title ID, executable basename and **complete measured PPU hash** must match its registered profile.
- Detection reads fresh, ordered executable-load and process-finished events. Historical hashes alone are never treated as current identity.
- A stop, process restart, menu executable, unknown hash, pending load or conflicting log evidence invalidates or leaves identity unresolved. An outer Collection title cannot identify its embedded game.
- If multiple RPCS3 processes share log ownership or fresh candidate logs conflict, detection fails closed. A manually selected profile, game title text, save namespace, cache entry, plausible field value or successful memory read cannot replace measured active executable identity.
- A standalone game uses the same resolver; its lifecycle is not inferred from Collection-specific transitions.

## Session memory base and operations

Once the game is identified, Ludava resolves the guest base from the current RPCS3 session's `vm::g_base_addr` evidence. All readable fresh candidates must agree; no universal address is assumed. Missing or ambiguous base evidence prevents automatic trainer access.

On refresh/write Ludava revalidates the chosen process and creation time, current profile identity/hash and guest base. Failed reads clear stale displayed values. The Nocterm frontend does **not** continuously poll: **G** requests re-detection, **R** refreshes, and a requested write triggers fresh validation. Diagnostic reads can use a specified profile but label unconfirmed identity appropriately. See [game-memory safeguards](game-memory.md).

## Evidence limitations

Automated tests cover parsing, missing/ambiguous events, stop/restart invalidation and guards, but they are not real-game compatibility evidence. Verified title hashes, emulator builds, observed menu transitions and remaining session limitations live with the respective [game records](../games/collection.md).

Unsupported games, multiple simultaneous RPCS3 processes, and emulator/build variants require separate real-world evidence before claiming compatibility.
