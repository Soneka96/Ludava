$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'check_changed_dart_format.ps1')

$testDirectory = Join-Path ([System.IO.Path]::GetTempPath()) (
    'ludava-format-check-' + [guid]::NewGuid().ToString('N')
)
New-Item -ItemType Directory -Path $testDirectory | Out-Null

try {
    $nameStatus = @(
        'A', 'new.dart',
        'M', 'directory/updated.dart',
        'R100', 'old.dart', 'renamed file.dart',
        'D', 'deleted.dart'
    ) -join [string][char]0
    $changedPaths = @(ConvertFrom-GitNameStatus $nameStatus)
    if ($changedPaths.Count -ne 3 -or
        $changedPaths[0] -cne 'new.dart' -or
        $changedPaths[1] -cne 'directory/updated.dart' -or
        $changedPaths[2] -cne 'renamed file.dart') {
        throw 'Git name-status parsing must keep additions, modifications, and renamed destinations only.'
    }
    if (@(ConvertFrom-GitNameStatus '').Count -ne 0) {
        throw 'An empty successful Git name-status result must produce no changed paths.'
    }

    $originalProcessInvoker = (Get-Command Invoke-CapturedProcess -CommandType Function).ScriptBlock
    $script:fetchCount = 0
    $script:failFetch = $false
    Set-Item Function:\Invoke-CapturedProcess -Value {
        param($FileName, $Arguments, $WorkingDirectory)
        if ($Arguments[0] -eq 'rev-parse' -and
            $Arguments[3] -match '^([0-9a-fA-F]{40,64})\^\{commit\}$') {
            return [pscustomobject]@{
                ExitCode = 0
                StandardOutput = "$($Matches[1])`n"
                StandardError = ''
            }
        }
        if ($Arguments[0] -eq 'fetch') {
            $script:fetchCount++
            $script:fetchArguments = $Arguments
            if ($script:failFetch) {
                return [pscustomobject]@{
                    ExitCode = 1
                    StandardOutput = ''
                    StandardError = 'fetch failed'
                }
            }
        }
        if ($Arguments[0] -eq 'rev-parse' -and $script:fetchCount -eq 0) {
            return [pscustomobject]@{
                ExitCode = 1
                StandardOutput = ''
                StandardError = ''
            }
        }
        return [pscustomobject]@{
            ExitCode = 0
            StandardOutput = "0123456789abcdef`n"
            StandardError = ''
        }
    }
    try {
        $baseCommit = Resolve-TargetBaseCommit 'main' $testDirectory
        if ($baseCommit -cne '0123456789abcdef') {
            throw 'Base resolution did not return the fetched commit.'
        }
        if ($script:fetchCount -ne 1 -or
            $script:fetchArguments[3] -cne '+refs/heads/main:refs/remotes/origin/main') {
            throw 'Base recovery must fetch the target branch into its origin tracking ref.'
        }

        $script:failFetch = $true
        $script:fetchCount = 0
        $failureMessage = $null
        try {
            Resolve-TargetBaseCommit 'main' $testDirectory | Out-Null
        }
        catch {
            $failureMessage = $_.Exception.Message
        }
        if ([string]::IsNullOrWhiteSpace($failureMessage) -or
            -not $failureMessage.Contains("Could not fetch target base 'main'")) {
            throw 'A failed base fetch must fail the formatting check clearly.'
        }

        $pushBeforeCommit = 'a' * 40
        if ((Resolve-TargetBaseCommit $pushBeforeCommit $testDirectory) -cne $pushBeforeCommit) {
            throw 'Push verification must accept the previous commit as its comparison base.'
        }
    }
    finally {
        Set-Item Function:\Invoke-CapturedProcess -Value $originalProcessInvoker
        Remove-Variable fetchCount, failFetch, fetchArguments -Scope Script -ErrorAction SilentlyContinue
    }

    $originalProcessInvoker = (Get-Command Invoke-CapturedProcess -CommandType Function).ScriptBlock
    $originalRepositoryRoot = $script:repositoryRoot
    $script:repositoryRoot = $testDirectory
    $script:fakeDiffOutput = @(
        'A', 'formatted with spaces.dart',
        'R100', 'old.dart', 'renamed with spaces.dart',
        'D', 'deleted.dart'
    ) -join [string][char]0
    $script:formatCallCount = 0
    $script:failMergeBase = $false
    $script:failDiff = $false
    Set-Item Function:\Invoke-CapturedProcess -Value {
        param($FileName, $Arguments, $WorkingDirectory)
        if ($Arguments[0] -eq 'rev-parse') {
            return [pscustomobject]@{
                ExitCode = 0
                StandardOutput = "base-commit`n"
                StandardError = ''
            }
        }
        if ($Arguments[0] -eq 'merge-base') {
            $script:mergeBaseArguments = $Arguments
            if ($script:failMergeBase) {
                return [pscustomobject]@{
                    ExitCode = 1
                    StandardOutput = ''
                    StandardError = 'no merge base'
                }
            }
            return [pscustomobject]@{
                ExitCode = 0
                StandardOutput = "common-base`n"
                StandardError = ''
            }
        }
        if ($Arguments[0] -eq 'diff') {
            $script:diffArguments = $Arguments
            if ($script:failDiff) {
                return [pscustomobject]@{
                    ExitCode = 1
                    StandardOutput = ''
                    StandardError = 'diff failed'
                }
            }
            return [pscustomobject]@{
                ExitCode = 0
                StandardOutput = $script:fakeDiffOutput
                StandardError = ''
            }
        }
        if ($Arguments[0] -eq 'format') {
            $script:formatCallCount++
            return [pscustomobject]@{
                ExitCode = 0
                StandardOutput = ''
                StandardError = ''
            }
        }
        throw "Unexpected mocked Git command: $($Arguments -join ' ')"
    }
    try {
        $formattedWithSpaces = Join-Path $testDirectory 'formatted with spaces.dart'
        $renamedWithSpaces = Join-Path $testDirectory 'renamed with spaces.dart'
        [System.IO.File]::WriteAllText($formattedWithSpaces, $formattedSource)
        [System.IO.File]::WriteAllText($renamedWithSpaces, $formattedSource)
        Invoke-ChangedDartFormattingCheck 'main'

        if ($script:mergeBaseArguments[1] -cne 'base-commit' -or
            $script:mergeBaseArguments[2] -cne 'HEAD' -or
            $script:diffArguments[5] -cne 'common-base' -or
            $script:diffArguments[6] -cne 'HEAD' -or
            -not ($script:diffArguments -contains '--find-renames') -or
            -not ($script:diffArguments -contains '--diff-filter=ACMRD')) {
            throw 'Changed-file comparison must use the target merge base and include rename/deletion statuses.'
        }

        $script:fakeDiffOutput = ''
        $script:formatCallCount = 0
        $emptyDiffMessages = @(
            Invoke-ChangedDartFormattingCheck 'main' 6>&1 |
                ForEach-Object { $_.ToString() }
        )
        if ($emptyDiffMessages -notcontains "No added or modified Dart files differ from 'main'.") {
            throw 'A successful empty Dart diff must report that no files need formatting.'
        }
        if ($script:formatCallCount -ne 0) {
            throw 'A successful empty Dart diff must not invoke Dart formatting.'
        }

        $script:failMergeBase = $true
        $failureMessage = $null
        try {
            Invoke-ChangedDartFormattingCheck 'main'
        }
        catch {
            $failureMessage = $_.Exception.Message
        }
        if ([string]::IsNullOrWhiteSpace($failureMessage) -or
            -not $failureMessage.Contains('merge-base') -or
            -not $failureMessage.Contains('failed with exit code 1')) {
            throw 'A failed merge-base comparison must stop the check with an error.'
        }

        $script:failMergeBase = $false
        $script:failDiff = $true
        $failureMessage = $null
        try {
            Invoke-ChangedDartFormattingCheck 'main'
        }
        catch {
            $failureMessage = $_.Exception.Message
        }
        if ([string]::IsNullOrWhiteSpace($failureMessage) -or
            -not $failureMessage.Contains('git diff') -or
            -not $failureMessage.Contains('failed with exit code 1')) {
            throw 'A failed Git diff with empty output must stop the check with an error.'
        }
    }
    finally {
        Set-Item Function:\Invoke-CapturedProcess -Value $originalProcessInvoker
        $script:repositoryRoot = $originalRepositoryRoot
        Remove-Variable -Name @(
            'fakeDiffOutput', 'failMergeBase', 'failDiff', 'formatCallCount',
            'mergeBaseArguments', 'diffArguments'
        ) -Scope Script -ErrorAction SilentlyContinue
    }

    $formattedPath = Join-Path $testDirectory 'dart file with spaces.dart'
    $formattedSource = "void main() {`n  print('formatted');`n}`n"
    [System.IO.File]::WriteAllText($formattedPath, $formattedSource)
    Invoke-DartFormatCheck $testDirectory @('dart file with spaces.dart')
    if ([System.IO.File]::ReadAllText($formattedPath) -cne $formattedSource) {
        throw 'The formatting check modified a correctly formatted Dart file.'
    }

    $unformattedPath = Join-Path $testDirectory 'unformatted file.dart'
    $unformattedSource = "void main(){print('needs formatting');}`n"
    [System.IO.File]::WriteAllText($unformattedPath, $unformattedSource)
    $failureMessage = $null
    try {
        Invoke-DartFormatCheck $testDirectory @('unformatted file.dart')
    }
    catch {
        $failureMessage = $_.Exception.Message
    }

    if ([string]::IsNullOrWhiteSpace($failureMessage) -or
        -not $failureMessage.Contains('Changed Dart files are not formatted') -or
        -not $failureMessage.Contains('unformatted file.dart')) {
        throw 'The formatting check did not report an unformatted changed file clearly.'
    }
    if ([System.IO.File]::ReadAllText($unformattedPath) -cne $unformattedSource) {
        throw 'The formatting check modified an unformatted Dart file.'
    }

    $originalProcessInvoker = (Get-Command Invoke-CapturedProcess -CommandType Function).ScriptBlock
    $script:worktreeStatus = "D`0deleted.dart`0"
    $script:formatCallCount = 0
    Set-Item Function:\Invoke-CapturedProcess -Value {
        param($FileName, $Arguments, $WorkingDirectory)
        if ($Arguments[0] -eq 'diff') {
            return [pscustomobject]@{
                ExitCode = 0
                StandardOutput = $script:worktreeStatus
                StandardError = ''
            }
        }
        if ($Arguments[0] -eq 'format') {
            $script:formatCallCount++
        }
        return [pscustomobject]@{
            ExitCode = 0
            StandardOutput = ''
            StandardError = ''
        }
    }
    try {
        Invoke-DartFormatCheck $testDirectory @('deleted.dart')
        if ($script:formatCallCount -ne 0) {
            throw 'A deleted worktree file must not be passed to Dart format.'
        }

        $script:worktreeStatus = "M`0missing.dart`0"
        $missingMessage = $null
        try {
            Invoke-DartFormatCheck $testDirectory @('missing.dart')
        }
        catch {
            $missingMessage = $_.Exception.Message
        }
        if ([string]::IsNullOrWhiteSpace($missingMessage) -or
            -not $missingMessage.Contains('is missing from the checkout')) {
            throw 'A missing changed file without a deletion status must still fail.'
        }
    }
    finally {
        Set-Item Function:\Invoke-CapturedProcess -Value $originalProcessInvoker
        Remove-Variable -Name @('worktreeStatus', 'formatCallCount') -Scope Script -ErrorAction SilentlyContinue
    }

    Write-Host 'Changed-file formatter tests passed (spaces, useful failure, no rewrites).'
}
finally {
    if (Test-Path -LiteralPath $testDirectory) {
        $resolvedTestDirectory = (Resolve-Path -LiteralPath $testDirectory).Path
        $resolvedTemporaryRoot = (Resolve-Path -LiteralPath ([System.IO.Path]::GetTempPath())).Path.TrimEnd('\', '/')
        $temporaryPrefix = $resolvedTemporaryRoot + [System.IO.Path]::DirectorySeparatorChar
        if (-not $resolvedTestDirectory.StartsWith(
            $temporaryPrefix,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Refusing to remove test directory outside the temporary root: $resolvedTestDirectory"
        }
        Remove-Item -LiteralPath $resolvedTestDirectory -Recurse -Force
    }
}
