$ErrorActionPreference = 'Stop'

if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
    throw 'Run this build script with the Windows x64 Dart SDK.'
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$outputDirectory = Join-Path $projectRoot 'build'
$executablePath = Join-Path $outputDirectory 'Ludava.exe'

Push-Location $projectRoot
try {
    dart pub get
    if ($LASTEXITCODE -ne 0) {
        throw "dart pub get failed with exit code $LASTEXITCODE."
    }

    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
    dart compile exe bin/ludava.dart -o $executablePath
    if ($LASTEXITCODE -ne 0) {
        throw "Dart executable compilation failed with exit code $LASTEXITCODE."
    }

    Write-Host "Built $executablePath"
} finally {
    Pop-Location
}
