$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$packages = @(
    @{
        Name = 'ludava_sdk'
        Path = 'packages\ludava_sdk'
        ForbiddenImports = 'package:(ludava_tui|nocterm|flutter)/'
        ForbiddenDependencies = '(?m)^\s*(ludava_tui|nocterm|flutter)\s*:'
    },
    @{
        Name = 'ludava_tui'
        Path = 'apps\ludava_tui'
        ForbiddenImports = 'package:(ludava|flutter)/'
        ForbiddenDependencies = '(?m)^\s*(ludava|flutter)\s*:'
    }
)
$uriPattern = @'
\b(?:import|export|part)\s+['"](?<uri>[^'"]+)['"]
'@

foreach ($package in $packages) {
    $packageRoot = (Resolve-Path (Join-Path $repositoryRoot $package.Path)).Path
    $manifestPath = Join-Path $packageRoot 'pubspec.yaml'
    if ([System.IO.File]::ReadAllText($manifestPath) -match $package.ForbiddenDependencies) {
        throw "$($package.Name) declares a dependency that violates its package boundary."
    }

    foreach ($directory in @('lib', 'test', 'bin')) {
        $sourceRoot = Join-Path $packageRoot $directory
        if (-not (Test-Path -LiteralPath $sourceRoot)) { continue }
        foreach ($file in Get-ChildItem -LiteralPath $sourceRoot -Recurse -Filter '*.dart') {
            $contents = [System.IO.File]::ReadAllText($file.FullName)
            foreach ($match in [regex]::Matches($contents, $uriPattern)) {
                $uri = $match.Groups['uri'].Value
                if ($uri -match $package.ForbiddenImports) {
                    throw "$($package.Name) imports forbidden package URI '$uri' in $($file.FullName)."
                }
                if ($uri.StartsWith('dart:') -or $uri.StartsWith('package:')) { continue }

                $target = [System.IO.Path]::GetFullPath((Join-Path $file.DirectoryName $uri))
                $packagePrefix = $packageRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
                if (-not $target.StartsWith($packagePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                    throw "$($package.Name) uses a relative import outside its package in $($file.FullName): $uri"
                }
            }
        }
    }
}

Write-Host 'SDK and TUI package dependency boundaries are valid.'
