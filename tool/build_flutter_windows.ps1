$ErrorActionPreference = 'Stop'

if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
    throw 'Run this build script with the Windows x64 Flutter SDK.'
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$nativeLibraryPath = Join-Path $projectRoot 'build\ludava_process_discovery.dll'
$flutterProject = Join-Path $projectRoot 'apps\ludava_app'
$releaseDirectory = Join-Path $flutterProject 'build\windows\x64\runner\Release'

& (Join-Path $PSScriptRoot 'build_process_discovery.ps1') -OutputPath $nativeLibraryPath
if ($LASTEXITCODE -ne 0) {
    throw "Native process-discovery library build failed with exit code $LASTEXITCODE."
}

Push-Location $flutterProject
try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter dependency resolution failed with exit code $LASTEXITCODE."
    }

    flutter build windows --release
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter Windows release build failed with exit code $LASTEXITCODE."
    }
} finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath $releaseDirectory -PathType Container)) {
    throw "Flutter release bundle was not found at $releaseDirectory."
}

Copy-Item -LiteralPath $nativeLibraryPath -Destination $releaseDirectory -Force

$requiredFiles = @(
    'ludava_app.exe',
    'flutter_windows.dll',
    'cnativeapi.dll',
    'ludava_process_discovery.dll'
)
foreach ($requiredFile in $requiredFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $releaseDirectory $requiredFile) -PathType Leaf)) {
        throw "Flutter release bundle is missing $requiredFile."
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $releaseDirectory 'data\flutter_assets') -PathType Container)) {
    throw 'Flutter release bundle is missing data\flutter_assets.'
}

Write-Host "Built the movable Flutter Windows bundle at $releaseDirectory"
