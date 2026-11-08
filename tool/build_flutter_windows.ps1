param(
    [string]$BuildDirectory = 'build'
)

$ErrorActionPreference = 'Stop'

if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
    throw 'Run this build script with the Windows x64 Flutter SDK.'
}
if ([System.IO.Path]::IsPathRooted($BuildDirectory) -or
    $BuildDirectory -match '(^|[\\/])\.\.([\\/]|$)') {
    throw 'The Flutter build directory must be a safe project-relative path.'
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$flutterProject = Join-Path $projectRoot 'apps\ludava_app'
$flutterBuildDirectory = Join-Path $flutterProject $BuildDirectory
$releaseDirectory = Join-Path $flutterBuildDirectory 'windows\x64\runner\Release'

Push-Location $flutterProject
try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter dependency resolution failed with exit code $LASTEXITCODE."
    }

    $configuration = flutter config --list
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter configuration lookup failed with exit code $LASTEXITCODE."
    }
    $buildDirectorySetting = $configuration |
        Where-Object { $_ -match '^\s*build-dir:' } |
        Select-Object -First 1
    $previousBuildDirectory = if ($null -eq $buildDirectorySetting) {
        $null
    } else {
        ($buildDirectorySetting -replace '^\s*build-dir:\s*', '').Trim()
    }
    if ($previousBuildDirectory -eq '(Not set)') {
        $previousBuildDirectory = $null
    }

    try {
        flutter config "--build-dir=$BuildDirectory"
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter build directory configuration failed with exit code $LASTEXITCODE."
        }

        flutter build windows --release
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter Windows release build failed with exit code $LASTEXITCODE."
        }
    } finally {
        if ([string]::IsNullOrWhiteSpace($previousBuildDirectory)) {
            flutter config '--build-dir='
        } else {
            flutter config "--build-dir=$previousBuildDirectory"
        }
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter build directory configuration could not be restored (exit code $LASTEXITCODE)."
        }
    }
} finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath $releaseDirectory -PathType Container)) {
    throw "Flutter release output was not found at $releaseDirectory."
}

$requiredFiles = @(
    'Ludava.exe',
    'flutter_windows.dll',
    'cnativeapi.dll',
    'data\app.so',
    'data\icudtl.dat'
)
foreach ($requiredFile in $requiredFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $releaseDirectory $requiredFile) -PathType Leaf)) {
        throw "Flutter release output is missing $requiredFile."
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $releaseDirectory 'data\flutter_assets') -PathType Container)) {
    throw 'Flutter release output is missing data\flutter_assets.'
}

Write-Host "Built the Flutter Windows release output at $releaseDirectory"
