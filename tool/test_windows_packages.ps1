param(
    [string]$PackageDirectory
)

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if ([string]::IsNullOrWhiteSpace($PackageDirectory)) {
    $PackageDirectory = Join-Path $projectRoot 'build\distributions'
}
$packageRoot = (Resolve-Path -LiteralPath $PackageDirectory).Path
$tuiZip = Join-Path $packageRoot 'Ludava-TUI-Windows-x64.zip'
$desktopZip = Join-Path $packageRoot 'Ludava-Desktop-Windows-x64.zip'
foreach ($archive in @($tuiZip, $desktopZip)) {
    if (-not (Test-Path -LiteralPath $archive -PathType Leaf)) {
        throw "Portable distribution archive was not found: $archive"
    }
}

$temporaryRoot = Join-Path $env:TEMP ("ludava-portable-check-" + [guid]::NewGuid().ToString('N'))
$tuiDirectory = Join-Path $temporaryRoot 'tui'
$desktopDirectory = Join-Path $temporaryRoot 'desktop'

function Assert-RequiredFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Directory,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $path = Join-Path $Directory $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Portable package is missing required file $RelativePath under $Directory."
    }
}

function Assert-TemporaryPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ParentDirectory,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $parent = [System.IO.Path]::GetFullPath($ParentDirectory).TrimEnd('\') + '\'
    $target = [System.IO.Path]::GetFullPath($TargetPath)
    if (-not $target.StartsWith($parent, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove a path outside temporary verification storage: $target"
    }
}

if (-not ('LudavaNativeLibraryProbe' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class LudavaNativeLibraryProbe
{
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr LoadLibraryEx(string path, IntPtr file, uint flags);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool FreeLibrary(IntPtr module);
}
'@
}

function Assert-NativeLibraryLoadable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LibraryPath
    )

    $module = [LudavaNativeLibraryProbe]::LoadLibraryEx($LibraryPath, [IntPtr]::Zero, 0x00000008)
    if ($module -eq [IntPtr]::Zero) {
        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        throw "The relocated native library could not be loaded: $LibraryPath (error $errorCode)."
    }
    if (-not [LudavaNativeLibraryProbe]::FreeLibrary($module)) {
        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        throw "The relocated native library handle could not be released: $LibraryPath (error $errorCode)."
    }
}

try {
    New-Item -ItemType Directory -Force -Path $tuiDirectory, $desktopDirectory | Out-Null
    Expand-Archive -LiteralPath $tuiZip -DestinationPath $tuiDirectory -Force
    Expand-Archive -LiteralPath $desktopZip -DestinationPath $desktopDirectory -Force

    Assert-RequiredFile -Directory $tuiDirectory -RelativePath 'Ludava-TUI.exe'
    Assert-RequiredFile -Directory $tuiDirectory -RelativePath 'ludava_process_discovery.dll'
    if (Test-Path -LiteralPath (Join-Path $tuiDirectory 'Ludava.exe')) {
        throw 'The TUI distribution must contain Ludava-TUI.exe, not the desktop executable.'
    }

    foreach ($requiredFile in @(
        'Ludava.exe',
        'flutter_windows.dll',
        'cnativeapi.dll',
        'ludava_process_discovery.dll',
        'msvcp140.dll',
        'vcruntime140.dll',
        'vcruntime140_1.dll',
        'data\app.so',
        'data\icudtl.dat'
    )) {
        Assert-RequiredFile -Directory $desktopDirectory -RelativePath $requiredFile
    }
    if (-not (Test-Path -LiteralPath (Join-Path $desktopDirectory 'data\flutter_assets') -PathType Container)) {
        throw 'The desktop distribution is missing data\flutter_assets.'
    }
    if (Test-Path -LiteralPath (Join-Path $desktopDirectory 'ludava_app.exe')) {
        throw 'The desktop distribution contains the obsolete executable name ludava_app.exe.'
    }
    if (Test-Path -LiteralPath (Join-Path $desktopDirectory 'Ludava-TUI.exe')) {
        throw 'The desktop distribution must not contain the TUI executable.'
    }
    Assert-NativeLibraryLoadable -LibraryPath (Join-Path $desktopDirectory 'cnativeapi.dll')

    Push-Location $tuiDirectory
    try {
        & (Join-Path $tuiDirectory 'Ludava-TUI.exe') --help | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "The relocated TUI help command failed with exit code $LASTEXITCODE."
        }
    } finally {
        Pop-Location
    }

    $application = Start-Process `
        -FilePath (Join-Path $desktopDirectory 'Ludava.exe') `
        -WorkingDirectory $desktopDirectory `
        -PassThru `
        -WindowStyle Hidden
    try {
        $requiredLoadedModules = @(
            'flutter_windows.dll',
            'ludava_process_discovery.dll'
        )
        $missingModules = $requiredLoadedModules
        for ($attempt = 0; $attempt -lt 30 -and $missingModules.Count -gt 0; $attempt++) {
            Start-Sleep -Milliseconds 500
            $application.Refresh()
            if ($application.HasExited) {
                throw "The relocated desktop app exited with code $($application.ExitCode)."
            }
            $loadedModules = @($application.Modules | ForEach-Object { $_.ModuleName })
            $missingModules = @(
                $requiredLoadedModules | Where-Object { $_ -notin $loadedModules }
            )
        }
        if ($missingModules.Count -gt 0) {
            throw "The relocated desktop app did not load required modules: $($missingModules -join ', '). Loaded: $($loadedModules -join ', ')"
        }
    } finally {
        try {
            $application.Refresh()
            if (-not $application.HasExited) {
                Stop-Process -Id $application.Id -Force -ErrorAction SilentlyContinue
            }
            if (-not $application.WaitForExit(10000)) {
                throw 'The relocated desktop app did not exit after termination was requested.'
            }
        } finally {
            $application.Dispose()
        }
    }

    Write-Host 'Both portable ZIP distributions passed extraction and launch checks.'
} finally {
    if (Test-Path -LiteralPath $temporaryRoot -PathType Container) {
        Assert-TemporaryPath -ParentDirectory $env:TEMP -TargetPath $temporaryRoot
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
