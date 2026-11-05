# RPCS3 game detection investigation

## Current conclusion

Ludava can discover an RPCS3 process, but the available repository evidence does
not yet establish a reliable, current identity for an embedded PS3 Collection
game. Until current-session evidence uniquely identifies a game, detection must
remain unresolved and the CLI must ask for deliberate manual profile selection.

The Collection title ID `BCUS98282` is shared by Ratchet & Clank 1, 2, and 3, so
it cannot select one of those profiles. The RC1 and RC3 active PPU executable
names and build fingerprints are not established. Their observed save
namespaces are research clues only and do not prove which game is currently
running. The RC2 profile records `RC2.ppu.self`, but that profile value alone is
not evidence that this executable is currently active in a given RPCS3 process.

## Signals inspected

The current implementation obtains the selected process's executable path and
process start time, then reads RPCS3 log files near that executable. The log
resolver uses the process start time to reject logs that predate the process,
but it does not establish that a log belongs exclusively to that process or
that its most recent game record still describes a running game. A log path or
timestamp is therefore not, on its own, a confirmed active-game identity.

RPCS3's upstream `Emulator::Load` source logs game title, serial, and path while
loading a game ([RPCS3 `System.cpp`](https://github.com/RPCS3/rpcs3/blob/master/rpcs3/Emu/System.cpp)).
These boot records are useful investigation signals. The repository has no
live RPCS3 samples demonstrating how those records behave when a game exits,
when one Collection subgame transitions to another, or when multiple emulator
instances share a log location. The signals must not be treated as a current
game API until those cases are established.

Neither a plausible bolt value nor the save namespaces
`NPUA80643_RC1_SAVEDATA_A`, `NPUA80644`, and
`NPUA80645_RC3_SAVEDATA_A` establish active-game identity. Profile selection,
memory availability, and permission to write remain separate facts.

## Safe matching boundary

- An RPCS3 process is not proof that a game is loaded.
- The Collection ID `BCUS98282` alone matches none of the three embedded game
  profiles individually.
- A profile can be selected automatically only from unique, current-session
  identity evidence tied to the selected RPCS3 process.
- Missing, stale, conflicting, or incomplete evidence remains unresolved; do
  not guess from a previous selection, log history, save namespace, or memory
  contents.
- A detected but unsupported game has no trainer profile or writable fields.
- Manual profile selection must be disclosed as manual and does not verify the
  active game.
- Detection is an explicit refresh operation. Ludava does not claim continuous
  monitoring; a future UI may call the same operation periodically.
- Losing process or game identity invalidates the prior detected profile and
  displayed field values. Detection never performs a memory write.

## Implemented foundation

The domain result distinguishes RPCS3-not-running, no active game, unsupported,
supported, ambiguous, and failed outcomes. It carries the selected process,
identity fields, evidence description, confidence, optional profile, and the
profile's available fields. The profile resolver selects a profile only when a
confirmed title ID plus executable name uniquely matches a registered profile;
`BCUS98282` alone stays ambiguous. Manual selection is represented separately
from confirmed identity.

The built-in RPCS3 log source reads candidate files newer than the selected
process start and preserves distinct title, serial, and boot-path values from
the complete log. It never treats those observations as confirmed current-game
identity. As a result, the built-in CLI currently reports log values as
unverified candidates and keeps manual selection available. An injected,
confirmed, process-matched identity can bypass manual selection. The CLI's
explicit **Re-detect game** action clears the previous field reading, checks
that the selected process/session remains the same, and requires a fresh profile
choice when the result is ambiguous. It does not poll continuously.

Automated coverage exercises parsing, stale and conflicting log history,
profile matching, unsupported titles, manual fallback, and CLI state clearing.
No live RPCS3 game-detection scenario has been validated. The owner-tested
read/write sessions do not establish automatic identity or profile matching.

## Evidence needed before broader automatic matching

Capture RPCS3 runtime observations for no game loaded, each Collection game,
game exit, switching between Collection games, an unsupported title, emulator
restart, and multiple RPCS3 instances. For each observation, record each
candidate log path and whether it is shared, the process start time, relevant
new log lines, title and serial values, and the active PPU executable where
available. Establish whether the signals can be attributed to the selected
process and how game-stop or switch transitions invalidate the previous
identity.

Until then, do not add RC1 or RC3 executable names, build fingerprints, or other
identity signatures. Automated tests can validate parsing and ambiguity rules,
but cannot substitute for these live RPCS3 observations.
