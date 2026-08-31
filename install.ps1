[CmdletBinding()]
param(
    [string]$TargetHome = [Environment]::GetFolderPath(
        [Environment+SpecialFolder]::UserProfile
    )
)

# Installs shared Codex and Claude defaults without copying credentials or
# replacing machine-specific settings. Compatible with Windows PowerShell 5.1
# and PowerShell 7.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$DotfilesRoot = $PSScriptRoot
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if ([string]::IsNullOrWhiteSpace($TargetHome)) {
    throw 'Could not determine the Windows user profile directory.'
}

$TargetHome = [IO.Path]::GetFullPath($TargetHome)

function New-ParentDirectory {
    param([Parameter(Mandatory)][string]$Path)

    $parent = [IO.Path]::GetDirectoryName($Path)
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        [void][IO.Directory]::CreateDirectory($parent)
    }
}

function Copy-BackupFile {
    param([Parameter(Mandatory)][string]$Path)

    $backup = "$Path.backup-$Timestamp"
    $suffix = 1
    while (Test-Path -LiteralPath $backup) {
        $backup = "$Path.backup-$Timestamp-$suffix"
        $suffix++
    }

    Copy-Item -LiteralPath $Path -Destination $backup
    Write-Host "backup $Path -> $backup"
    return $backup
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Content
    )

    [IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Install-ManagedFile {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )

    New-ParentDirectory -Path $Destination

    if (Test-Path -LiteralPath $Destination -PathType Leaf) {
        $sourceHash = (Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash
        $destinationHash = (
            Get-FileHash -LiteralPath $Destination -Algorithm SHA256
        ).Hash

        if ($sourceHash -ceq $destinationHash) {
            Write-Host "ok     $Destination (already current)"
            return
        }

        [void](Copy-BackupFile -Path $Destination)
    }
    elseif (Test-Path -LiteralPath $Destination) {
        throw "Destination exists but is not a file: $Destination"
    }

    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    Write-Host "copy   $Source -> $Destination"
}

function Merge-TomlDefaults {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )

    New-ParentDirectory -Path $Destination
    if (-not (Test-Path -LiteralPath $Destination)) {
        Copy-Item -LiteralPath $Source -Destination $Destination
        Write-Host "copy   $Source -> $Destination"
        return
    }

    $pairs = @()
    foreach ($line in [IO.File]::ReadAllLines($Source)) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith('#')) {
            continue
        }

        $match = [regex]::Match(
            $trimmed,
            '^([A-Za-z0-9_]+)\s*=\s*(.+)$'
        )
        if (-not $match.Success) {
            throw "Unsupported line in ${Source}: $line"
        }

        $pairs += [pscustomobject]@{
            Key = $match.Groups[1].Value
            Value = $match.Groups[2].Value
        }
    }

    $original = [IO.File]::ReadAllText($Destination)
    $updated = $original
    $newline = if ($updated.Contains("`r`n")) { "`r`n" } else { "`n" }

    foreach ($pair in $pairs) {
        $lines = [regex]::Split($updated, '\r?\n')
        $nextLines = New-Object System.Collections.Generic.List[string]
        $found = $false
        $pattern = '^[ \t]*' + [regex]::Escape($pair.Key) + '[ \t]*='

        foreach ($line in $lines) {
            if ($line -match $pattern) {
                if (-not $found) {
                    $nextLines.Add("$($pair.Key) = $($pair.Value)")
                    $found = $true
                }
                continue
            }

            $nextLines.Add($line)
        }

        if (-not $found) {
            $nextLines.Insert(0, "$($pair.Key) = $($pair.Value)")
        }

        $updated = [string]::Join($newline, $nextLines)
    }

    if ([string]::Equals($original, $updated, [StringComparison]::Ordinal)) {
        Write-Host "ok     $Destination (defaults already set)"
        return
    }

    [void](Copy-BackupFile -Path $Destination)
    Write-Utf8File -Path $Destination -Content $updated
    Write-Host "merge  $Source -> $Destination"
}

function Merge-ClaudeSettings {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )

    New-ParentDirectory -Path $Destination
    if (-not (Test-Path -LiteralPath $Destination)) {
        Copy-Item -LiteralPath $Source -Destination $Destination
        Write-Host "copy   $Source -> $Destination"
        return
    }

    try {
        $defaultsText = [IO.File]::ReadAllText($Source)
        $settingsText = [IO.File]::ReadAllText($Destination)
        if (-not $defaultsText.TrimStart().StartsWith('{') -or
            -not $settingsText.TrimStart().StartsWith('{')) {
            throw 'Settings must be JSON objects.'
        }

        $defaults = $defaultsText | ConvertFrom-Json
        $settings = $settingsText | ConvertFrom-Json
    }
    catch {
        throw "Cannot merge invalid JSON settings: $Destination"
    }

    $defaultProperty = $defaults.PSObject.Properties['outputStyle']
    if ($null -eq $defaultProperty) {
        throw "Missing outputStyle in defaults: $Source"
    }

    $desired = [string]$defaultProperty.Value
    $currentProperty = $settings.PSObject.Properties['outputStyle']
    if ($null -ne $currentProperty -and
        ([string]$currentProperty.Value -ceq $desired)) {
        Write-Host "ok     $Destination (output style already set)"
        return
    }

    if ($null -eq $currentProperty) {
        $settings | Add-Member -NotePropertyName outputStyle -NotePropertyValue $desired
    }
    else {
        $currentProperty.Value = $desired
    }

    $json = $settings | ConvertTo-Json -Depth 100
    $json += [Environment]::NewLine

    [void](Copy-BackupFile -Path $Destination)
    Write-Utf8File -Path $Destination -Content $json
    Write-Host "merge  $Source -> $Destination"
}

$CodexSource = Join-Path $DotfilesRoot 'codex'
$ClaudeSource = Join-Path $DotfilesRoot 'claude'
$CodexTarget = Join-Path $TargetHome '.codex'
$ClaudeTarget = Join-Path $TargetHome '.claude'

Merge-TomlDefaults `
    -Source (Join-Path $CodexSource 'config.toml') `
    -Destination (Join-Path $CodexTarget 'config.toml')
Merge-ClaudeSettings `
    -Source (Join-Path $ClaudeSource 'settings.json') `
    -Destination (Join-Path $ClaudeTarget 'settings.json')

Install-ManagedFile `
    -Source (Join-Path $CodexSource 'AGENTS.md') `
    -Destination (Join-Path $CodexTarget 'AGENTS.md')
Install-ManagedFile `
    -Source (Join-Path $ClaudeSource 'CLAUDE.md') `
    -Destination (Join-Path $ClaudeTarget 'CLAUDE.md')
Install-ManagedFile `
    -Source (
        Join-Path (Join-Path $ClaudeSource 'output-styles') `
            'clear-concise-english.md'
    ) `
    -Destination (
        Join-Path (Join-Path $ClaudeTarget 'output-styles') `
            'clear-concise-english.md'
    )

Write-Host 'done. Start new Codex and Claude sessions to load the defaults.'
