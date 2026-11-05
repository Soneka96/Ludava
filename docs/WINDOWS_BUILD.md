# Windows x64 build and ROG Ally setup

Build Ludava on a Windows x64 development PC with the Dart SDK installed. Flutter is not required.

From the repository root, run:

```powershell
.\tool\build_windows.ps1
```

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
5. Confirm the detected log base, accept the research-tested suggestion, or enter the current session base.
6. Refresh or deliberately change bolts from the trainer menu.

The Ally does not need Dart or Flutter installed. RPCS3 must still be installed and running with the supported game. RPCS3's [support guidance](https://github.com/RPCS3/rpcs3/wiki/How-to-ask-for-Support) places the Windows log in the `log` folder inside the RPCS3 directory; official support reports also describe it as near the executable. Ludava checks those two locations and asks for an explicit base choice when it cannot identify a fresh candidate.
