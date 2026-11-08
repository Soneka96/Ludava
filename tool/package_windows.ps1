$ErrorActionPreference = 'Stop'

if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
    throw 'Run Windows packaging with the Windows x64 Flutter and C++ toolchain.'
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$buildDirectory = Join-Path $projectRoot 'build'
$distributionDirectory = Join-Path $buildDirectory 'distributions'
$stagingParent = Join-Path $buildDirectory 'package-staging'
$runId = [guid]::NewGuid().ToString('N')
$flutterProject = Join-Path $projectRoot 'apps\ludava_app'
$flutterBuildDirectoryName = "build\windows-package-$runId"
$flutterBuildDirectory = Join-Path $flutterProject $flutterBuildDirectoryName
$flutterReleaseDirectory = Join-Path $flutterBuildDirectory 'windows\x64\runner\Release'
$stagingDirectory = Join-Path $stagingParent $runId
$tuiBuildDirectory = Join-Path $stagingDirectory 'tui-build'
$tuiStage = Join-Path $stagingDirectory 'tui'
$desktopStage = Join-Path $stagingDirectory 'desktop'
$tuiZip = Join-Path $distributionDirectory 'Ludava-TUI-Windows-x64.zip'
$desktopZip = Join-Path $distributionDirectory 'Ludava-Desktop-Windows-x64.zip'
$tuiExecutable = Join-Path $tuiBuildDirectory 'Ludava-TUI.exe'
$nativeLibrary = Join-Path $tuiBuildDirectory 'ludava_process_discovery.dll'

function Get-VisualCppRuntimeDirectory {
    $vswhereCandidates = @(
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'),
        (Join-Path $env:ProgramFiles 'Microsoft Visual Studio\Installer\vswhere.exe')
    )
    $vswhere = $vswhereCandidates |
        Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
        Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($vswhere)) {
        throw 'Visual Studio Installer vswhere.exe is required to locate the x64 Visual C++ runtime.'
    }

    $visualStudioRoot = & $vswhere -latest -products '*' `
        -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        -property installationPath
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($visualStudioRoot)) {
        throw 'The Visual Studio x64 C++ toolchain could not be located.'
    }

    $redistRoot = Join-Path $visualStudioRoot 'VC\Redist\MSVC'
    $runtimeDirectory = Get-ChildItem -LiteralPath $redistRoot -Directory -Recurse `
        -Filter 'Microsoft.VC*.CRT' |
        Where-Object { $_.FullName -match '[\\/]x64[\\/]Microsoft\.VC\d+\.CRT$' } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($null -eq $runtimeDirectory) {
        throw "The x64 Visual C++ runtime files were not found under $redistRoot."
    }

    return $runtimeDirectory.FullName
}

function Assert-PathIsWithinDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ParentDirectory,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $parent = [System.IO.Path]::GetFullPath($ParentDirectory).TrimEnd('\') + '\'
    $target = [System.IO.Path]::GetFullPath($TargetPath)
    if (-not $target.StartsWith($parent, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove path outside the expected directory: $target"
    }
}

New-Item -ItemType Directory -Force -Path $distributionDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $stagingParent | Out-Null
New-Item -ItemType Directory -Force -Path $tuiBuildDirectory, $tuiStage, $desktopStage | Out-Null

try {
    & (Join-Path $PSScriptRoot 'build_windows.ps1') -OutputDirectory $tuiBuildDirectory
    & (Join-Path $PSScriptRoot 'build_flutter_windows.ps1') `
        -BuildDirectory $flutterBuildDirectoryName `
        -ProcessDiscoveryLibraryPath $nativeLibrary

    foreach ($requiredPath in @($tuiExecutable, $nativeLibrary)) {
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
            throw "Windows build output is missing $requiredPath."
        }
    }
    if (-not (Test-Path -LiteralPath $flutterReleaseDirectory -PathType Container)) {
        throw "Flutter release output was not found at $flutterReleaseDirectory."
    }

    Copy-Item -LiteralPath $tuiExecutable -Destination $tuiStage
    Copy-Item -LiteralPath $nativeLibrary -Destination $tuiStage

    foreach ($releaseItem in Get-ChildItem -LiteralPath $flutterReleaseDirectory -Force) {
        if ($releaseItem.Name -in @('ludava_app.exe', 'ludava_process_discovery.dll')) {
            continue
        }
        Copy-Item -LiteralPath $releaseItem.FullName -Destination $desktopStage -Recurse -Force
    }
    Copy-Item -LiteralPath $nativeLibrary -Destination $desktopStage

    $visualCppRuntimeDirectory = Get-VisualCppRuntimeDirectory
    foreach ($runtimeName in @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')) {
        $runtimePath = Join-Path $visualCppRuntimeDirectory $runtimeName
        if (-not (Test-Path -LiteralPath $runtimePath -PathType Leaf)) {
            throw "The x64 Visual C++ runtime is missing $runtimeName."
        }
        Copy-Item -LiteralPath $runtimePath -Destination $desktopStage
    }

    Compress-Archive -Path (Join-Path $tuiStage '*') `
        -DestinationPath $tuiZip -CompressionLevel Optimal -Force
    Compress-Archive -Path (Join-Path $desktopStage '*') `
        -DestinationPath $desktopZip -CompressionLevel Optimal -Force

    & (Join-Path $PSScriptRoot 'test_windows_packages.ps1') `
        -PackageDirectory $distributionDirectory
    Write-Host "Created and validated $desktopZip"
    Write-Host "Created and validated $tuiZip"
} finally {
    if (Test-Path -LiteralPath $stagingDirectory -PathType Container) {
        Assert-PathIsWithinDirectory -ParentDirectory $stagingParent -TargetPath $stagingDirectory
        Remove-Item -LiteralPath $stagingDirectory -Recurse -Force
    }
    if (Test-Path -LiteralPath $flutterBuildDirectory -PathType Container) {
        Assert-PathIsWithinDirectory `
            -ParentDirectory (Join-Path $flutterProject 'build') `
            -TargetPath $flutterBuildDirectory
        Remove-Item -LiteralPath $flutterBuildDirectory -Recurse -Force
    }
}
