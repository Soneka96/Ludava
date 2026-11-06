# Windows x64 build and ROG Ally setup

Build Ludava on a Windows x64 development PC with the Dart SDK, LLVM Clang,
and the Windows 10/11 SDK installed. Flutter is not required.

From the repository root, run:

```powershell
.\tool\build_windows.ps1
```

If PowerShell blocks the script because its execution policy is `Restricted`,
allow it only for the current PowerShell session, then run the script:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\tool\build_windows.ps1
```

This process-scoped setting ends when that PowerShell session closes. Use the
script so the native discovery library and executable are built together.
The script resolves the repository root from its own location, so it can also
be invoked by absolute path while the current directory is elsewhere.

The script resolves Dart packages, compiles the process-discovery native shim,
and compiles `apps/ludava_tui/bin/ludava.dart` into `build\Ludava.exe`. The output includes
`build\ludava_process_discovery.dll`, which must remain beside the executable.
The executable includes the Dart runtime; the companion DLL captures Win32
last-error values at the native call boundary. `build/` is ignored by Git.

The root CLI remains available as a compatibility entry point. For the TUI
package-native command, run `dart run bin/ludava.dart` from `apps/ludava_tui`.
Diagnostic help is available from either directory with `dart run bin/ludava.dart --help`.

Resolve the workspace and analyze the root and both packages:

```powershell
dart pub get
dart pub workspace list
dart analyze
```

Run `dart analyze` and `dart test` from each package directory, then `dart test`
at the repository root for compatibility entry points. Root commands do not
automatically replace the package suites.

## Copy to a ROG Ally

1. Build `build\Ludava.exe` and `build\ludava_process_discovery.dll` on the Windows x64 development PC.
2. Copy both files to the ROG Ally and keep them in the same directory.
3. Start RPCS3 and a supported Ratchet & Clank Collection game.
4. Launch `Ludava.exe`. With one RPCS3 process and measured identity evidence, Ludava selects the embedded game and session base automatically. When multiple processes share a log folder, or the game/hash/base is unresolved, Ludava does not authorize a trainer write.
5. If RPCS3 is open with no game, Ludava reports no active game and shows no field value until a game is detected and refreshed.
6. Use **↑/↓**, **1–9**, and **Enter** to navigate and open fields. Press **R** to refresh, **G** to re-detect, and **Q** to quit. The value editor starts with the current ungrouped value and cursor at the end. **Enter** applies a changed, valid value without an extra confirmation prompt; **Escape** cancels.
7. Before every write, Ludava rechecks the process session, PPU hash, and base. It requires a complete preliminary read, complete native write, and matching read-back before reporting success.

## Physical keyboard acceptance

Nocterm's Windows backend reads Win32 console key events and translates them directly. Ludava leaves Kitty keyboard and `modifyOtherKeys` negotiation disabled on this backend, so Escape and Ctrl+C use the native key-event path instead of terminal-encoded key sequences.

For final keyboard acceptance, run the TUI in both the VS Code integrated PowerShell terminal and standalone Windows Terminal. Use the physical keyboard to open an available field, press Escape, and confirm the editor closes without writing or displaying protocol text. Press Ctrl+C and confirm the app exits safely without inserting protocol text. Also verify number shortcuts, arrows, Home/End, Backspace/Delete, Enter, refresh selection, and terminal input restoration after exit. Automated byte-stream tests do not replace this physical-key check.

The owner tested live bolt reads and writes in all three Collection games on November 5, 2026. A separate RPCS3 log experiment measured their PPU hashes on RPCS3 `0.0.43-20565-eee3f0f7`. The final compiled CLI was live-smoke-tested with RC2. The owner later confirmed automatic detection and trainer operation across RC1, RC2, and RC3 during Windows laptop and ROG Ally testing. The records do not map each game to each device or identify the exact RPCS3 build for that later confirmation; compatibility with other RPCS3 builds remains unverified. The Ally does not need Dart or Flutter installed, but it needs both files listed above. RPCS3 must still be installed and running. RPCS3's [support guidance](https://github.com/RPCS3/rpcs3/wiki/How-to-ask-for-Support) places the Windows log in the `log` folder inside the RPCS3 directory; support reports also describe it as near the executable.
