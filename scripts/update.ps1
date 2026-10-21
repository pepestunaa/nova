[CmdletBinding()]
param(
    [Alias("y")]
    [switch]$Yes
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$ConfigPaths = @(
    "servers/game/config.zon",
    "servers/sdk/config.zon"
)

function Confirm-Action([string]$Prompt) {
    if ($Yes) {
        return $true
    }
    return (Read-Host "$Prompt [y/N]") -match "^(?i:y|yes)$"
}

function Invoke-Git([Parameter(ValueFromRemainingArguments)][string[]]$Arguments) {
    & git -C $Root @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Git failed: git $($Arguments -join ' ')"
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $Root ".git") -PathType Container)) {
    throw "update.ps1 must be run from an Nova Git checkout."
}

if (-not (Get-Command git -CommandType Application -ErrorAction SilentlyContinue)) {
    throw "Git is required to update Nova."
}

$StatusLines = @(& git -C $Root status --porcelain=v1 --untracked-files=all)

if ($LASTEXITCODE -ne 0) {
    throw "Could not inspect the Nova checkout."
}

$CustomizedConfigs = [System.Collections.Generic.List[string]]::new()
$BlockingChanges = [System.Collections.Generic.List[string]]::new()
foreach ($Line in $StatusLines) {
    if ($Line.Length -lt 4) {
        $BlockingChanges.Add($Line)
        continue
    }

    $Status = $Line.Substring(0, 2)
    $ChangedPath = $Line.Substring(3).Replace('\', '/')
    if ($Status -eq " M" -and $ConfigPaths -contains $ChangedPath) {
        $CustomizedConfigs.Add($ChangedPath)
    } else {
        $BlockingChanges.Add($Line)
    }
}

if ($BlockingChanges.Count -ne 0) {
    Write-Host "Nova has local changes that cannot be migrated automatically:" -ForegroundColor Yellow
    foreach ($Change in $BlockingChanges) {
        Write-Host "    $Change"
    }
    throw "Commit, stash, or discard those changes before updating."
}

$Upstream = (& git -C $Root rev-parse --abbrev-ref --symbolic-full-name '@{u}').Trim()
if ($LASTEXITCODE -ne 0 -or -not $Upstream) {
    throw "The current branch has no upstream branch configured."
}
Invoke-Git fetch --prune origin
& git -C $Root merge-base --is-ancestor HEAD $Upstream
if ($LASTEXITCODE -ne 0) {
    throw "The local branch cannot be fast-forwarded to $Upstream."
}

$Temporary = $null
$Backup = $null
$MergedFiles = @{}
try {
    if ($CustomizedConfigs.Count -ne 0) {
        Write-Host "The following customized configs can be migrated:" -ForegroundColor Cyan
        foreach ($Config in $CustomizedConfigs) {
            Write-Host "    $Config"
        }
        if (-not (Confirm-Action "Merge these settings into the updated configs?")) {
            throw "Update cancelled; the customized configs were left untouched."
        }

        $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $Backup = Join-Path (Split-Path -Parent $Root) "Nova-config-backup-$Timestamp-$PID"
        $Temporary = Join-Path $env:TEMP "nova-update-$([guid]::NewGuid().ToString('N'))"
        [IO.Directory]::CreateDirectory($Backup) | Out-Null
        [IO.Directory]::CreateDirectory($Temporary) | Out-Null

        $HasConflict = $false
        foreach ($Config in $CustomizedConfigs) {
            $Name = $Config.Replace('/', '-')
            $Current = Join-Path $Root $Config
            $Saved = Join-Path $Backup $Name
            $Base = Join-Path $Temporary "$Name.base"
            $Incoming = Join-Path $Temporary "$Name.incoming"
            $Merged = Join-Path $Temporary "$Name.merged"

            Copy-Item -LiteralPath $Current -Destination $Saved
            Copy-Item -LiteralPath $Current -Destination $Merged

            & git -C $Root show "--output=$Base" "HEAD`:$Config"
            if ($LASTEXITCODE -ne 0) {
                throw "Could not read the previous version of $Config."
            }
            & git -C $Root show "--output=$Incoming" "$Upstream`:$Config"
            if ($LASTEXITCODE -ne 0) {
                throw "The updated branch no longer contains $Config."
            }

            & git merge-file --quiet -- $Merged $Base $Incoming
            if ($LASTEXITCODE -ne 0) {
                $HasConflict = $true
            }
            $MergedFiles[$Config] = $Merged
        }

        if ($HasConflict) {
            Write-Host "Your config files were backed up to:" -ForegroundColor Yellow
            Write-Host "    $Backup"
            throw "The customized configs conflict with the update. Nova was not updated."
        }

        Invoke-Git restore --worktree -- @CustomizedConfigs
    }

    & git -C $Root merge --ff-only $Upstream
    if ($LASTEXITCODE -ne 0) {
        if ($Backup) {
            foreach ($Config in $CustomizedConfigs) {
                Copy-Item -LiteralPath (Join-Path $Backup $Config.Replace('/', '-')) -Destination (Join-Path $Root $Config) -Force
            }
        }
        throw "Nova could not be fast-forwarded to $Upstream."
    }

    foreach ($Config in $CustomizedConfigs) {
        Copy-Item -LiteralPath $MergedFiles[$Config] -Destination (Join-Path $Root $Config) -Force
    }
} finally {
    if ($Temporary) {
        Remove-Item -LiteralPath $Temporary -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Nova is up to date." -ForegroundColor Green
