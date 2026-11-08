[CmdletBinding()]
param(
    [string]$BaseRef
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Invoke-CapturedProcess {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $FileName
    $startInfo.WorkingDirectory = $WorkingDirectory
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.StandardOutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $startInfo.StandardErrorEncoding = [System.Text.UTF8Encoding]::new($false)
    if ($FileName -eq 'git') {
        $startInfo.Environment['GIT_TERMINAL_PROMPT'] = '0'
    }
    foreach ($argument in $Arguments) {
        $startInfo.ArgumentList.Add($argument)
    }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) {
            throw "Could not start $FileName."
        }
        $standardOutput = $process.StandardOutput.ReadToEndAsync()
        $standardError = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(120000)) {
            $process.Kill()
            $process.WaitForExit()
            throw "$FileName timed out after 120 seconds."
        }
        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            StandardOutput = $standardOutput.GetAwaiter().GetResult()
            StandardError = $standardError.GetAwaiter().GetResult()
        }
    }
    finally {
        $process.Dispose()
    }
}

function Get-RequiredOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    $result = Invoke-CapturedProcess $FileName $Arguments $WorkingDirectory
    if ($result.ExitCode -ne 0) {
        $details = $result.StandardError.Trim()
        throw "$FileName $($Arguments -join ' ') failed with exit code $($result.ExitCode). $details"
    }
    return $result.StandardOutput
}

function Resolve-DartExecutable {
    $dartCommand = Get-Command 'dart' -ErrorAction Stop
    $commandPath = $dartCommand.Source
    if ([string]::IsNullOrWhiteSpace($commandPath)) {
        throw 'The Dart SDK executable could not be resolved.'
    }
    if ($commandPath.EndsWith('.bat', [System.StringComparison]::OrdinalIgnoreCase) -or
        $commandPath.EndsWith('.cmd', [System.StringComparison]::OrdinalIgnoreCase)) {
        $commandDirectory = Split-Path -Parent $commandPath
        $candidates = @(
            (Join-Path $commandDirectory 'cache\dart-sdk\bin\dart.exe'),
            (Join-Path $commandDirectory 'dart.exe')
        )
        foreach ($candidate in $candidates) {
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                return (Resolve-Path -LiteralPath $candidate).Path
            }
        }
        throw "The Dart command resolves to '$commandPath', but its dart.exe could not be found."
    }
    return $commandPath
}

function Resolve-TargetBaseCommit {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetBranch,
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    $branch = $TargetBranch.Trim()
    if ($branch.StartsWith('origin/')) {
        $branch = $branch.Substring('origin/'.Length)
    }
    if ([string]::IsNullOrWhiteSpace($branch)) {
        throw 'A target base branch is required for changed-file formatting.'
    }

    if ($branch -match '^[0-9a-fA-F]{40,64}$') {
        $commit = Invoke-CapturedProcess 'git' @(
            'rev-parse', '--verify', '--quiet', "$branch^{commit}"
        ) $WorkingDirectory
        if ($commit.ExitCode -ne 0 -or
            [string]::IsNullOrWhiteSpace($commit.StandardOutput.Trim())) {
            throw "Comparison base commit '$branch' is unavailable."
        }
        return $commit.StandardOutput.Trim()
    }

    $remoteRef = "refs/remotes/origin/$branch"
    $resolved = Invoke-CapturedProcess 'git' @(
        'rev-parse', '--verify', '--quiet', "$remoteRef^{commit}"
    ) $WorkingDirectory
    if ($resolved.ExitCode -ne 0) {
        $fetch = Invoke-CapturedProcess 'git' @(
            'fetch', '--no-tags', 'origin', "+refs/heads/${branch}:${remoteRef}"
        ) $WorkingDirectory
        if ($fetch.ExitCode -ne 0) {
            throw "Could not fetch target base '$branch': $($fetch.StandardError.Trim())"
        }
        $resolved = Invoke-CapturedProcess 'git' @(
            'rev-parse', '--verify', '--quiet', "$remoteRef^{commit}"
        ) $WorkingDirectory
    }
    if ($resolved.ExitCode -ne 0 -or
        [string]::IsNullOrWhiteSpace($resolved.StandardOutput.Trim())) {
        throw "Target base '$branch' is unavailable after fetch; refusing to format an empty file list."
    }
    return $resolved.StandardOutput.Trim()
}

function Invoke-DartFormatCheck {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory,
        [Parameter(Mandatory = $true)]
        [string[]]$ChangedPaths
    )

    if ($ChangedPaths.Count -eq 0) {
        Write-Host 'No added or modified Dart files need formatting.'
        return
    }

    $absolutePaths = [System.Collections.Generic.List[string]]::new()
    foreach ($changedPath in $ChangedPaths) {
        $relativePath = $changedPath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
        $absolutePath = [System.IO.Path]::GetFullPath((Join-Path $WorkingDirectory $relativePath))
        if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
            $worktreeStatus = Get-RequiredOutput 'git' @(
                'diff', '--name-status', '-z', 'HEAD', '--', $changedPath
            ) $WorkingDirectory
            $statusParts = $worktreeStatus.Split(
                [char]0,
                [System.StringSplitOptions]::RemoveEmptyEntries
            )
            if ($statusParts.Length -ge 2 -and $statusParts[0][0] -eq 'D') {
                continue
            }
            throw "Git reported changed Dart file '$changedPath', but it is missing from the checkout."
        }
        $absolutePaths.Add($absolutePath)
    }

    if ($absolutePaths.Count -eq 0) {
        Write-Host 'All changed Dart files were deleted from the checkout.'
        return
    }

    $formatArguments = @('format', '--output=none', '--set-exit-if-changed') + $absolutePaths.ToArray()
    $formatResult = Invoke-CapturedProcess (Resolve-DartExecutable) $formatArguments $WorkingDirectory
    if ($formatResult.ExitCode -ne 0) {
        $details = @($formatResult.StandardOutput.Trim(), $formatResult.StandardError.Trim()) |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        $fileList = $ChangedPaths -join "`n"
        throw "Changed Dart files are not formatted. Run 'dart format' on these files:`n$fileList`n$($details -join "`n")"
    }
}

function ConvertFrom-GitNameStatus {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$NameStatusOutput
    )

    $parts = $NameStatusOutput.Split(
        [char]0,
        [System.StringSplitOptions]::RemoveEmptyEntries
    )
    $paths = [System.Collections.Generic.List[string]]::new()
    $index = 0
    while ($index -lt $parts.Length) {
        $status = $parts[$index]
        $index++
        if ($status.Length -eq 0) {
            throw 'Git returned an empty file status in its name-status output.'
        }

        switch ($status[0]) {
            { $_ -in @('A', 'M') } {
                if ($index -ge $parts.Length) {
                    throw "Git omitted the path for status '$status'."
                }
                $paths.Add($parts[$index])
                $index++
                break
            }
            { $_ -in @('R', 'C') } {
                if ($index + 1 -ge $parts.Length) {
                    throw "Git omitted a source or destination path for status '$status'."
                }
                $index++
                $paths.Add($parts[$index])
                $index++
                break
            }
            'D' {
                if ($index -ge $parts.Length) {
                    throw "Git omitted the path for status '$status'."
                }
                $index++
                break
            }
            default {
                throw "Git returned unsupported file status '$status'."
            }
        }
    }
    return $paths.ToArray()
}

function Invoke-ChangedDartFormattingCheck {
    param([string]$TargetBaseRef)

    if ([string]::IsNullOrWhiteSpace($TargetBaseRef)) {
        if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_BASE_REF)) {
            $TargetBaseRef = $env:GITHUB_BASE_REF
        }
        elseif ($env:LUDAVA_FORMAT_EVENT_NAME -eq 'push' -and
            $env:LUDAVA_FORMAT_REF_NAME -eq 'main' -and
            $env:LUDAVA_FORMAT_PUSH_BEFORE -match '^[0-9a-fA-F]{40,64}$') {
            $TargetBaseRef = $env:LUDAVA_FORMAT_PUSH_BEFORE
        }
        else {
            $TargetBaseRef = 'main'
        }
    }

    $baseCommit = Resolve-TargetBaseCommit $TargetBaseRef $repositoryRoot
    $mergeBase = Get-RequiredOutput 'git' @(
        'merge-base', $baseCommit, 'HEAD'
    ) $repositoryRoot
    if ([string]::IsNullOrWhiteSpace($mergeBase.Trim())) {
        throw "Git did not return a merge base for target '$TargetBaseRef' and HEAD."
    }

    $changedOutput = Get-RequiredOutput 'git' @(
        'diff', '--name-status', '-z', '--find-renames', '--diff-filter=ACMRD',
        $mergeBase.Trim(), 'HEAD', '--', '*.dart'
    ) $repositoryRoot
    $changedPaths = @(
        (ConvertFrom-GitNameStatus $changedOutput) |
            Where-Object { $_.EndsWith('.dart', [System.StringComparison]::OrdinalIgnoreCase) }
    )

    if ($changedPaths.Count -eq 0) {
        Write-Host "No added or modified Dart files differ from '$TargetBaseRef'."
        return
    }

    Write-Host "Checking formatting for $($changedPaths.Count) changed Dart file(s) against '$TargetBaseRef'."
    Invoke-DartFormatCheck $repositoryRoot $changedPaths
    Write-Host 'All changed Dart files are formatted.'
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-ChangedDartFormattingCheck $BaseRef
}
