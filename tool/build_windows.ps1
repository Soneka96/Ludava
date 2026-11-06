$ErrorActionPreference = 'Stop'

if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
    throw 'Run this build script with the Windows x64 Dart SDK.'
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputDirectory = Join-Path $projectRoot 'build'
$executablePath = Join-Path $outputDirectory 'Ludava.exe'
$nativeLibraryPath = Join-Path $outputDirectory 'ludava_process_discovery.dll'
$nativeLibrarySource = Join-Path $projectRoot 'packages\ludava_sdk\lib\features\rpcs3_connection\data\datasources\native\windows_process_discovery.c'
$tuiEntrypoint = Join-Path $projectRoot 'apps\ludava_tui\bin\ludava.dart'

$clang = Get-Command clang.exe -ErrorAction SilentlyContinue
if ($null -eq $clang) {
    throw 'LLVM clang is required to build the Ludava Windows discovery library.'
}

$windowsSdkRoot = $env:WindowsSdkDir
if ([string]::IsNullOrWhiteSpace($windowsSdkRoot)) {
    $windowsSdkRoot = 'C:\Program Files (x86)\Windows Kits\10'
}
$windowsSdkLibRoot = Join-Path $windowsSdkRoot 'Lib'
$windowsSdkVersion = Get-ChildItem -LiteralPath $windowsSdkLibRoot -Directory |
    Sort-Object { [version]$_.Name } -Descending |
    Select-Object -First 1 -ExpandProperty Name
if ([string]::IsNullOrWhiteSpace($windowsSdkVersion)) {
    throw "Windows SDK libraries were not found under $windowsSdkLibRoot."
}
$kernel32LibraryDirectory = Join-Path $windowsSdkLibRoot "$windowsSdkVersion\um\x64"
if (-not (Test-Path -LiteralPath (Join-Path $kernel32LibraryDirectory 'kernel32.lib'))) {
    throw "The x64 Windows SDK kernel32.lib was not found under $kernel32LibraryDirectory."
}

Push-Location $projectRoot
try {
    dart pub get
    if ($LASTEXITCODE -ne 0) {
        throw "dart pub get failed with exit code $LASTEXITCODE."
    }

    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
    $nativeArguments = @(
        '--target=x86_64-pc-windows-msvc',
        '-fuse-ld=lld',
        '-shared',
        '-nostdlib',
        '-Wl,/noentry',
        "-L$kernel32LibraryDirectory",
        $nativeLibrarySource,
        '-lkernel32',
        '-o',
        $nativeLibraryPath
    )
    & $clang.Source @nativeArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Native Windows process-discovery library build failed with exit code $LASTEXITCODE."
    }

    dart compile exe $tuiEntrypoint -o $executablePath
    if ($LASTEXITCODE -ne 0) {
        throw "Dart executable compilation failed with exit code $LASTEXITCODE."
    }

    Write-Host "Built $executablePath and $nativeLibraryPath"
} finally {
    Pop-Location
}
