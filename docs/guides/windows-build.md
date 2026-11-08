# Windows portable distributions and ROG Ally setup

Build on a Windows x64 PC with Flutter 3.47 or newer, its bundled Dart 3.13 or newer, Visual Studio's C++ desktop tools, LLVM Clang, and the Windows 10/11 SDK. Run `flutter doctor -v` to check the local toolchain.

## Build both portable packages

From the repository root, run the packaging entry point:

```powershell
.\tool\package_windows.ps1
```

If PowerShell blocks scripts because its execution policy is `Restricted`, allow the script only in the current PowerShell session, then run it:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\tool\package_windows.ps1
```

The output is:

```text
build\distributions\Ludava-Desktop-Windows-x64.zip
build\distributions\Ludava-TUI-Windows-x64.zip
```

The desktop package contains `Ludava.exe`, Flutter's runtime DLLs, `cnativeapi.dll`, the complete `data` directory, the SDK-owned `ludava_process_discovery.dll`, and the required x64 Visual C++ runtime DLLs. The TUI package contains `Ludava-TUI.exe` and `ludava_process_discovery.dll`; it does not bundle Flutter. The packaging script builds each app into an isolated directory, verifies the ZIP contents, extracts both archives to temporary relocated folders, launches the TUI diagnostic help and desktop app, and removes its temporary folders afterward.

The Visual C++ runtime files are deployed next to the desktop executable. This is Microsoft's application-local deployment model for the runtime DLLs; see [Microsoft C++ deployment guidance](https://learn.microsoft.com/en-us/cpp/windows/deployment-in-visual-cpp). No separate Visual C++ Redistributable installation is needed on the Ally. Dart, Flutter, and the Visual Studio toolchain are not required there.

The individual build scripts are also available for development. `tool/build_windows.ps1` builds the TUI executable and discovery DLL. Run `tool/build_flutter_windows.ps1` to build a standalone Flutter release bundle; it places `ludava_process_discovery.dll` beside `Ludava.exe` so SDK process discovery works from that folder. The output directory is printed by the script. Use `tool/package_windows.ps1` for both portable distributions; it reuses the native library from its isolated TUI build.

## Developer verification commands

From the repository root, resolve and inspect the workspace, then analyze and test every package explicitly:

```powershell
dart pub get
dart pub workspace list
dart analyze

Push-Location packages\ludava_sdk
dart analyze
dart test
Pop-Location

Push-Location apps\ludava_tui
dart analyze
dart test
dart run bin/ludava.dart --help
Pop-Location

Push-Location apps\ludava_app
flutter analyze
flutter test
Pop-Location

dart test
dart run bin/ludava.dart --help
```

To verify the standalone Flutter Windows bundle independently, run:

```powershell
.\tool\build_flutter_windows.ps1
```

Package both Windows applications and exercise the extracted distributions with:

```powershell
.\tool\package_windows.ps1
```

The Windows workflow also runs workspace-boundary and changed-file format checks. It uploads both ZIPs as artifacts; see [GitHub Actions](https://github.com/Soneka96/Ludava/actions) for current runs and downloads.

## Transfer and launch on a ROG Ally

1. Build the packages on the Windows PC with `.\tool\package_windows.ps1`.
2. Copy the desktop ZIP, the TUI ZIP, or both to the Ally over USB, a removable drive, or your local network.
3. Extract each package into its own folder. Keep the executable, DLLs, and `data` directory from that package together.
4. For the graphical app, launch `Ludava.exe`. For the terminal app, open PowerShell in the extracted TUI folder and run `.\Ludava-TUI.exe`.
5. Start RPCS3 and a game supported by a profile. If RPCS3 starts after Ludava, use Refresh to discover it. One process is selected automatically; when multiple are found, choose the process running your game. Game, build, and process details remain available in tooltips or the process picker.
6. The desktop header has one icon-only Refresh action. It refreshes field values or rediscovers RPCS3 when no process is selected.
7. Edit is offered only when the SDK reports a current eligible write target. Apply with ✓ or Enter; cancel with × or Escape. A successful write displays the verified read-back value. A same-session failure keeps the attempted draft and shows the error in a tooltip; a stale or disconnected target cancels editing.

The TUI keeps its terminal controls: press **1–9** to open a field directly, use **↑/↓** to move and **Enter** to edit, press **R** to refresh, **G** to re-detect, and **Q** to quit. In the TUI editor, **Enter** applies and **Escape** cancels. Before a write, the SDK rechecks process session, PPU hash, base, bounds, complete native write, and matching read-back.

## ROG Ally acceptance checklist

Run these checks on the actual device before recording ROG Ally acceptance. Leave a box unchecked until that behavior has been observed on the Ally.

- [ ] With RPCS3 closed, the desktop indicator reports that RPCS3 is absent.
- [ ] With one RPCS3 process, Ludava selects it; with multiple processes, the picker shows the choices and preserves the selected process.
- [ ] Starting a supported game shows its one-line title and SDK-provided numeric values; build and PID details are only in tooltips or the process picker.
- [ ] Refresh updates the displayed values and rediscovers RPCS3 when no process is selected.
- [ ] A verified Bolts write applies only after ✓ or Enter and displays the matching SDK read-back value.
- [ ] Invalid input and an induced write failure show error-colored, fixed-size feedback; an unfinished draft survives a same-session refresh.
- [ ] Process restart, game change, disconnection, or invalidated write target exits edit mode and discards the draft.
- [ ] Physical keyboard and touch keyboard can focus the row editor; Enter applies, Escape and × cancel, and ✓ applies once.
- [ ] At 520 × 360 and 480 × 340 logical pixels, normal, editing, validation-error, and write-error states keep row positions and heights stable without overflow or automatic window resizing.
- [ ] The title-bar close button and Alt+F4 wait for SDK cleanup; repeated close requests still close safely.
- [ ] The TUI accepts physical number keys, arrows, Enter, Escape, Backspace/Delete, R, G, and Q, then restores terminal input after exit.

For measured game/build identities and write evidence, see the [game research records](../games/collection.md). Automated tests and CI package checks do not establish ROG Ally acceptance. GitHub Actions is the source of current CI results and uploaded package artifacts.
