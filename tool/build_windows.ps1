param(
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'

if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
    throw 'Run this build script with the Windows x64 Dart SDK bundled with Flutter 3.47 or newer.'
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputDirectory = if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    Join-Path $projectRoot 'build'
} elseif ([System.IO.Path]::IsPathRooted($OutputDirectory)) {
    [System.IO.Path]::GetFullPath($OutputDirectory)
} else {
    Join-Path $projectRoot $OutputDirectory
}
$executablePath = Join-Path $outputDirectory 'Ludava-TUI.exe'
$nativeLibraryPath = Join-Path $outputDirectory 'ludava_process_discovery.dll'
$tuiEntrypoint = Join-Path $projectRoot 'apps\ludava_tui\bin\ludava.dart'

Push-Location $projectRoot
try {
    dart pub get
    if ($LASTEXITCODE -ne 0) {
        throw "dart pub get failed with exit code $LASTEXITCODE."
    }

    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
    & (Join-Path $PSScriptRoot 'build_process_discovery.ps1') -OutputPath $nativeLibraryPath

    dart compile exe $tuiEntrypoint -o $executablePath
    if ($LASTEXITCODE -ne 0) {
        throw "Dart executable compilation failed with exit code $LASTEXITCODE."
    }

    Write-Host "Built $executablePath and $nativeLibraryPath"
} finally {
    Pop-Location
}
