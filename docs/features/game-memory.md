# Game memory operations

The SDK's `game_memory` feature owns generic address resolution, encoding/decoding, native memory access, complete-transfer checks, preliminary reads, read-back and process-handle cleanup. It does not contain game-specific offsets or RPCS3 detection policy. Per-game offsets, value types, endianness, and bounds are profile data in `game_catalog`; sources, measured builds, limitations, and historical research evidence belong under `docs/games/`. Production catalog membership means the owner approved the profile and fields for read/write use; it is not runtime authorization.

## Read and write contracts

A read uses a valid field mapping and address and decodes bytes using the field's declared representation only after native read-result validation succeeds. A failed or partial read is **not** a valid zero. The frontend should clear stale values on failed refreshes. Diagnostic reads may use a manually selected profile while current game identity is unconfirmed when the request does not require identity confirmation; the result must say that identity is unverified. Reads do not require write confirmation, a preliminary read, or read-back.

A write requires a deliberate user action and current process/session revalidation; matching game and executable identity and memory base; a field registered in the selected profile; valid type and numeric range; explicit confirmation; a complete preliminary read; a complete native transfer; and an exact matching read-back. Failures must remain accurately classified; the operation guard, process cleanup, and terminal disposal safeguards remain in force. The TUI applies deliberate edits on Enter; diagnostic CLI writes require `--confirm-write`. SDK safeguards remain mandatory regardless of how a memory address was researched. See [game detection](game-detection.md) for current identity rules.

A successful native call, plausible read, or matching read-back alone does not prove compatibility with a game build.

## Research and status interpretation

- Research records may describe candidate, externally tested, or Ludava-tested mappings. Preserve provenance, assumptions, observed behavior, representation, limits, and exact build scope. These historical labels do not grant or deny runtime access.
- A new mapping stays on a development branch until the owner confirms a successful Ludava read and guarded write with the intended in-game result using either the TUI or Flutter. Only then may it enter the production catalog.

The registered profile and field determine which mapping the SDK operates on; current process identity, session, memory base, value constraints, explicit confirmation, complete transfers, and matching read-back determine whether each operation can proceed. Test the reusable memory engine and codecs generically once; add focused mapping tests when registering a game field. Do not create a new memory engine for every game.
