# Windows x64 build and ROG Ally setup

Build Ludava on a Windows x64 development PC with the Dart SDK installed. Flutter is not required.

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

This process-scoped setting ends when that PowerShell session closes. You can
also run the manual build commands below without running the script.

The script resolves Dart packages and compiles `bin/ludava.dart` into `build\Ludava.exe`. `build/` is ignored by Git; do not commit the generated executable. The compiled file includes the Dart runtime and has no external runtime files to copy.

You can also run the build commands directly:

```powershell
dart pub get
New-Item -ItemType Directory -Force build | Out-Null
dart compile exe bin/ludava.dart -o build/Ludava.exe
```

The source CLI checks are:

```powershell
dart analyze
dart test
dart format --output=none --set-exit-if-changed lib test bin
```

## Copy to a ROG Ally

1. Build `build\Ludava.exe` on the Windows x64 development PC.
2. Copy `Ludava.exe` to the ROG Ally.
3. Start RPCS3 and a supported Ratchet & Clank Collection game.
4. Launch `Ludava.exe`. With one RPCS3 process and measured identity evidence, Ludava selects the embedded game and session base automatically. When multiple processes share a log folder, or the game/hash/base is unresolved, Ludava does not authorize a trainer write.
5. If RPCS3 is open with no game, Ludava reports no active game and does not request a memory base. Manual profile selection remains unverified and read-only.
6. Use **Re-detect game** to clear the displayed field value and check current identity again. Before a write, Ludava rechecks the process session, PPU hash, and base, then requires deliberate confirmation and matching read-back.

The owner tested live bolt reads and writes in all three Collection games on November 5, 2026. A separate RPCS3 log experiment measured their PPU hashes on RPCS3 `0.0.43-20565-eee3f0f7`. The final compiled CLI was live-smoke-tested with RC2; live Ludava detection runs for RC1 and RC3 and on the Ally remain pending. These observations do not establish compatibility with every RPCS3 build. The Ally does not need Dart or Flutter installed. RPCS3 must still be installed and running. RPCS3's [support guidance](https://github.com/RPCS3/rpcs3/wiki/How-to-ask-for-Support) places the Windows log in the `log` folder inside the RPCS3 directory; support reports also describe it as near the executable.
