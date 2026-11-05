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
3. Start RPCS3 and Ratchet & Clank 2 in the PS3 Collection.
4. Launch `Ludava.exe` and select the detected RPCS3 process and RC2 profile.
5. Verify the current session's memory base from a fresh RPCS3 log before using
   it. The suggested `0x300000000` base is a research-session value and may not
   match the current session.
6. Refresh bolts, then deliberately confirm any write from the trainer menu.

The owner successfully read and changed RC2 bolts with Ludava in RPCS3 on
November 5, 2026. That live test does not establish compatibility with every
RPCS3 version or game build. A successful read-back confirms the value at the
selected address, but does not identify the active game or prove that the
correct target was selected. Verify the session base and use a test save before
writing. The Ally does not need Dart or Flutter installed. RPCS3 must still be
installed and running. RPCS3's [support guidance](https://github.com/RPCS3/rpcs3/wiki/How-to-ask-for-Support)
places the Windows log in the `log` folder inside the RPCS3 directory; official
support reports also describe it as near the executable. Ludava checks those
two locations and asks for an explicit base choice when it cannot identify a
fresh candidate.
