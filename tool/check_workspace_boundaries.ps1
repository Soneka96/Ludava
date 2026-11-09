$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$packages = @(
    @{
        Name = 'ludava_sdk'
        Path = 'packages\ludava_sdk'
        ForbiddenImports = 'package:(ludava|ludava_tui|ludava_app|nocterm|flutter)/'
        ForbiddenDependencies = '(?m)^\s*(ludava|ludava_tui|ludava_app|nocterm|flutter)\s*:'
    },
    @{
        Name = 'ludava_tui'
        Path = 'apps\ludava_tui'
        ForbiddenImports = 'package:(ludava|ludava_app|flutter)/|package:ludava_sdk/(?!ludava_sdk\.dart$)'
        ForbiddenDependencies = '(?m)^\s*(ludava|ludava_app|flutter)\s*:'
    },
    @{
        Name = 'ludava_app'
        Path = 'apps\ludava_app'
        ForbiddenImports = 'package:(ludava|ludava_tui)/|package:ludava_sdk/(?!ludava_sdk\.dart$)'
        ForbiddenDependencies = '(?m)^\s*(ludava|ludava_tui)\s*:'
    }
)
$uriPattern = @'
(?m)^[ \t]*(?:import|export|part)[ \t]+['"](?<uri>[^'"]+)['"]
'@
$legacyClassPattern = '(?m)^\s*(?:(?:abstract|base|final|interface|sealed)\s+)*class\s+InteractiveTrainerCli\b'

function Test-DocumentationOnlyImport {
    param(
        [string]$Contents,
        [string]$Manifest,
        [string]$Uri,
        [int]$ImportIndex
    )

    # Require a single-line import with an explicit show list; never exempt
    # exports, parts, unrestricted imports, or imports with prefixes.
    $line = ($Contents.Substring($ImportIndex) -split '\r?\n', 2)[0]
    $directive = [regex]::Match(
        $line,
        '^[ \t]*import[ \t]+[''"](?<uri>[^''"\r\n]+)[''"][ \t]+show[ \t]+(?<symbols>[A-Za-z_$][A-Za-z0-9_$]*(?:[ \t]*,[ \t]*[A-Za-z_$][A-Za-z0-9_$]*)*)[ \t]*;[ \t]*(?://[^\r\n]*)?$'
    )
    if (-not $directive.Success -or $directive.Groups['uri'].Value -cne $Uri) {
        return $false
    }

    $package = [regex]::Match($Uri, '^package:(?<name>[A-Za-z_][A-Za-z0-9_]*)/')
    if (-not $package.Success) { return $false }
    $dependency = $package.Groups['name'].Value

    # Doc links cannot add a dependency; it must already be declared.
    $section = ''
    $declared = $false
    foreach ($manifestLine in ($Manifest -split '\r?\n')) {
        if ($manifestLine -cmatch '^(?<section>[A-Za-z_][A-Za-z0-9_]*):') {
            $section = $Matches['section']
            continue
        }
        if ($section -in @('dependencies', 'dev_dependencies') -and
            $manifestLine -cmatch ('^[ ]{2}' + [regex]::Escape($dependency) + '[ \t]*:')) {
            $declared = $true
            break
        }
    }
    if (-not $declared) { return $false }

    $docComments = [regex]::Matches(
        $Contents, '(?m)^[ \t]*///[^\r\n]*|(?s:/\*\*.*?\*/)'
    )
    if ($docComments.Count -eq 0) { return $false }
    $docText = ($docComments | ForEach-Object { $_.Value }) -join [Environment]::NewLine

    # Replace doc comments and the import with equal-length spaces so every
    # remaining symbol reference is conservatively treated as executable.
    # Strings and ordinary comments remain, making uncertain cases fail closed.
    $active = $Contents
    foreach ($comment in $docComments) {
        $active = $active.Remove($comment.Index, $comment.Length).Insert(
            $comment.Index, (' ' * $comment.Length)
        )
    }
    $active = $active.Remove($ImportIndex, $line.Length).Insert(
        $ImportIndex, (' ' * $line.Length)
    )
    foreach ($symbol in ($directive.Groups['symbols'].Value -split '[ \t]*,[ \t]*')) {
        $escaped = [regex]::Escape($symbol)
        if (-not [regex]::IsMatch(
            $docText, '\[' + $escaped + '(?:\.[A-Za-z_$][A-Za-z0-9_$]*)*\]'
        )) { return $false }
        if ([regex]::IsMatch(
            $active, '(?<![A-Za-z0-9_$])' + $escaped + '(?![A-Za-z0-9_$])'
        )) { return $false }
    }
    return $true
}

$sdkRoot = Join-Path $repositoryRoot 'packages\ludava_sdk'
$sdkAppDirectory = Join-Path $sdkRoot 'lib\app'
if (Test-Path -LiteralPath $sdkAppDirectory) {
    throw 'ludava_sdk contains the forbidden unowned lib\app directory.'
}

foreach ($package in $packages) {
    $packageRoot = (Resolve-Path (Join-Path $repositoryRoot $package.Path)).Path
    $manifestPath = Join-Path $packageRoot 'pubspec.yaml'
    $manifestContents = [System.IO.File]::ReadAllText($manifestPath)
    if ($manifestContents -match $package.ForbiddenDependencies) {
        throw "$($package.Name) declares a dependency that violates its package boundary."
    }

    foreach ($directory in @('lib', 'test', 'bin')) {
        $sourceRoot = Join-Path $packageRoot $directory
        if (-not (Test-Path -LiteralPath $sourceRoot)) { continue }
        foreach ($file in Get-ChildItem -LiteralPath $sourceRoot -Recurse -Filter '*.dart') {
            $contents = [System.IO.File]::ReadAllText($file.FullName)
            if ($package.Name -eq 'ludava_tui' -and
                ($file.Name -eq 'interactive_trainer_cli.dart' -or
                    $contents -match $legacyClassPattern)) {
                throw "ludava_tui contains the removed legacy InteractiveTrainerCli in $($file.FullName)."
            }
            # Keep source offsets stable for exact directive verification.
            $spaces = [System.Text.RegularExpressions.MatchEvaluator] {
                param($comment)
                return ' ' * $comment.Length
            }
            $sourceContents = [regex]::Replace($contents, '(?s)/\*.*?\*/', $spaces)
            $sourceContents = [regex]::Replace(
                $sourceContents, '(?m)^[ \t]*//.*$', $spaces
            )
            foreach ($match in [regex]::Matches($sourceContents, $uriPattern)) {
                $uri = $match.Groups['uri'].Value
                if (($uri -match $package.ForbiddenImports) -and
                    (-not (Test-DocumentationOnlyImport -Contents $contents -Manifest $manifestContents -Uri $uri -ImportIndex $match.Index))) {
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

Write-Host 'SDK and frontend package dependency boundaries are valid.'
