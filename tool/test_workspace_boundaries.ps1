$ErrorActionPreference = 'Stop'

$fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) (
    'ludava-boundary-check-' + [guid]::NewGuid().ToString('N')
)
$toolDirectory = Join-Path $fixtureRoot 'tool'
$sdkRoot = Join-Path $fixtureRoot 'packages\ludava_sdk'
$tuiRoot = Join-Path $fixtureRoot 'apps\ludava_tui'
$appRoot = Join-Path $fixtureRoot 'apps\ludava_app'
$boundaryScript = Join-Path $toolDirectory 'check_workspace_boundaries.ps1'

function Write-FixtureFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,
        [Parameter(Mandatory = $true)]
        [string]$Contents
    )

    $path = Join-Path $fixtureRoot $RelativePath
    $directory = Split-Path -Parent $path
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    [System.IO.File]::WriteAllText($path, $Contents)
}

function Assert-BoundaryCheck {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Description,
        [Parameter(Mandatory = $true)]
        [bool]$ShouldPass
    )

    $failure = $null
    try {
        & $boundaryScript *>&1 | Out-Null
    }
    catch {
        $failure = $_.Exception.Message
    }

    if ($ShouldPass -and $null -ne $failure) {
        throw "$Description should pass, but failed: $failure"
    }
    if (-not $ShouldPass -and $null -eq $failure) {
        throw "$Description should fail the workspace boundary check."
    }
}

try {
    New-Item -ItemType Directory -Path (Join-Path $toolDirectory '.') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $sdkRoot 'lib') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tuiRoot 'lib') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $appRoot 'lib') -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'check_workspace_boundaries.ps1') `
        -Destination $boundaryScript

    Write-FixtureFile 'packages/ludava_sdk/pubspec.yaml' "name: ludava_sdk`n"
    Write-FixtureFile 'apps/ludava_tui/pubspec.yaml' "name: ludava_tui`ndependencies:`n  ludava_sdk: ^0.1.0`n"
    Write-FixtureFile 'apps/ludava_app/pubspec.yaml' @'
name: ludava_app
dependencies:
  flutter:
    sdk: flutter
  ludava_sdk: ^0.1.0
'@
    Write-FixtureFile 'packages/ludava_sdk/lib/ludava_sdk.dart' "library;`n"
    Write-FixtureFile 'apps/ludava_tui/lib/ludava_tui.dart' `
        "// import 'package:flutter/material.dart';`n/* class InteractiveTrainerCli {} */`nimport /* public API */ 'package:ludava_sdk/ludava_sdk.dart';`n"
    Write-FixtureFile 'apps/ludava_app/lib/ludava_app.dart' @'
import 'package:flutter/material.dart';
import 'package:ludava_sdk/ludava_sdk.dart';
'@
    Assert-BoundaryCheck 'public SDK imports from both frontends' $true

    Write-FixtureFile 'packages/ludava_sdk/pubspec.yaml' `
        "name: ludava_sdk`ndependencies:`n  nocterm: ^0.9.0`n"
    Assert-BoundaryCheck 'SDK forbidden dependency declarations' $false
    Write-FixtureFile 'packages/ludava_sdk/pubspec.yaml' @'
name: ludava_sdk
dependencies:
  ludava_app: ^0.1.0
'@
    Assert-BoundaryCheck 'SDK app dependency' $false
    Write-FixtureFile 'packages/ludava_sdk/pubspec.yaml' "name: ludava_sdk`n"

    Write-FixtureFile 'apps/ludava_tui/pubspec.yaml' `
        "name: ludava_tui`ndependencies:`n  ludava_sdk: ^0.1.0`n  flutter: any`n"
    Assert-BoundaryCheck 'TUI forbidden dependency declarations' $false
    Write-FixtureFile 'apps/ludava_tui/pubspec.yaml' @'
name: ludava_tui
dependencies:
  ludava_sdk: ^0.1.0
  ludava_app: ^0.1.0
'@
    Assert-BoundaryCheck 'TUI app dependency' $false
    Write-FixtureFile 'apps/ludava_tui/pubspec.yaml' `
        "name: ludava_tui`ndependencies:`n  ludava_sdk: ^0.1.0`n"

    Write-FixtureFile 'apps/ludava_app/pubspec.yaml' @'
name: ludava_app
dependencies:
  ludava_sdk: ^0.1.0
  ludava_tui: ^0.1.0
'@
    Assert-BoundaryCheck 'Flutter app frontend dependencies' $false
    Write-FixtureFile 'apps/ludava_app/pubspec.yaml' @'
name: ludava_app
dependencies:
  flutter:
    sdk: flutter
  ludava_sdk: ^0.1.0
'@

    Write-FixtureFile 'packages/ludava_sdk/lib/bad_import.dart' `
        "import 'package:nocterm/nocterm.dart';`n"
    Assert-BoundaryCheck 'SDK frontend imports' $false
    [System.IO.File]::Delete((Join-Path $sdkRoot 'lib/bad_import.dart'))

    Write-FixtureFile 'packages/ludava_sdk/lib/bad_app_import.dart' @'
import 'package:ludava_app/app/ludava_app.dart';
'@
    Assert-BoundaryCheck 'SDK app imports' $false
    [System.IO.File]::Delete((Join-Path $sdkRoot 'lib/bad_app_import.dart'))

    Write-FixtureFile 'apps/ludava_tui/lib/ludava_tui.dart' `
        "import 'package:ludava_sdk/features/trainer/application/trainer_session_controller.dart';`n"
    Assert-BoundaryCheck 'TUI SDK internals imports' $false

    Write-FixtureFile 'apps/ludava_tui/lib/ludava_tui.dart' @'
import 'package:ludava_app/app/ludava_app.dart';
'@
    Assert-BoundaryCheck 'TUI app imports' $false

    Write-FixtureFile 'apps/ludava_app/lib/ludava_app.dart' @'
import 'package:ludava_sdk/features/trainer/application/trainer_session_controller.dart';
'@
    Assert-BoundaryCheck 'Flutter app SDK internals imports' $false

    Write-FixtureFile 'apps/ludava_app/lib/ludava_app.dart' @'
import 'package:ludava_tui/ludava_tui.dart';
'@
    Assert-BoundaryCheck 'Flutter app TUI imports' $false

    Write-FixtureFile 'apps/ludava_app/lib/ludava_app.dart' @'
import '../../../packages/ludava_sdk/lib/ludava_sdk.dart';
'@
    Assert-BoundaryCheck 'Flutter app cross-package relative imports' $false

    Write-FixtureFile 'apps/ludava_tui/lib/ludava_tui.dart' `
        "import '../../../packages/ludava_sdk/lib/ludava_sdk.dart';`n"
    Assert-BoundaryCheck 'cross-package relative imports' $false

    Write-FixtureFile 'apps/ludava_tui/lib/ludava_tui.dart' `
        "final class InteractiveTrainerCli {}`n"
    Assert-BoundaryCheck 'legacy interactive CLI reintroduction' $false

    New-Item -ItemType Directory -Path (Join-Path $sdkRoot 'lib/app') -Force | Out-Null
    Assert-BoundaryCheck 'SDK lib/app reintroduction' $false

    Write-Host 'Workspace boundary checker fixture tests passed.'
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        $resolvedFixtureRoot = (Resolve-Path -LiteralPath $fixtureRoot).Path
        $resolvedTemporaryRoot = (Resolve-Path -LiteralPath ([System.IO.Path]::GetTempPath())).Path.TrimEnd('\', '/')
        $temporaryPrefix = $resolvedTemporaryRoot + [System.IO.Path]::DirectorySeparatorChar
        if (-not $resolvedFixtureRoot.StartsWith(
            $temporaryPrefix,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Refusing to remove a boundary fixture outside the temporary root: $resolvedFixtureRoot"
        }
        Remove-Item -LiteralPath $resolvedFixtureRoot -Recurse -Force
    }
}
