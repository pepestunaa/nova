[CmdletBinding()]
param(
    [Alias("y")]
    [switch]$Yes
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Manifest = Join-Path $Root "build.zig.zon"
$ZvmInstallerUrl = "https://git.xeondev.com/nyan/zvm/raw/branch/main/install.ps1"

function Confirm-Action([string]$Prompt) {
    if ($Yes) {
        return $true
    }
    return (Read-Host "$Prompt [y/N]") -match "^(?i:y|yes)$"
}

function Invoke-WithoutProgress([scriptblock]$Command) {
    $PreviousPreference = $ProgressPreference
    try {
        $ProgressPreference = "SilentlyContinue"
        return & $Command
    } finally {
        $ProgressPreference = $PreviousPreference
    }
}

function Get-RequiredZigVersion {
    if (-not (Test-Path -LiteralPath $Manifest -PathType Leaf)) {
        throw "Nova does not contain build.zig.zon."
    }
    $Match = [regex]::Match(
        (Get-Content -LiteralPath $Manifest -Raw),
        '(?m)^\s*\.minimum_zig_version\s*=\s*"([^"]+)"\s*,?'
    )
    if (-not $Match.Success) {
        throw "build.zig.zon does not declare a literal .minimum_zig_version."
    }
    return $Match.Groups[1].Value
}

function Get-ZvmBinDirectory {
    if ($env:ZVM_HOME) {
        return Join-Path $env:ZVM_HOME "bin"
    }
    return Join-Path $env:LocalAppData "zvm\bin"
}

function Add-PathFirst([string]$Directory) {
    $Entries = @($env:Path -split [IO.Path]::PathSeparator |
        Where-Object { $_ -and -not $_.Equals($Directory, [StringComparison]::OrdinalIgnoreCase) })
    $env:Path = (@($Directory) + $Entries) -join [IO.Path]::PathSeparator
}

function Refresh-EnvironmentPath {
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $MachinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $env:Path = (@($UserPath, $MachinePath, $env:Path) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join [IO.Path]::PathSeparator
}

function Get-ZigCandidates {
    $Candidates = @()
    $ZvmZig = Join-Path (Get-ZvmBinDirectory) "zig.exe"
    if (Test-Path -LiteralPath $ZvmZig -PathType Leaf) {
        $Candidates += $ZvmZig
    }
    $Command = Get-Command zig -CommandType Application -ErrorAction SilentlyContinue
    if ($Command) {
        $Candidates += $Command.Source
    }
    return @($Candidates | Select-Object -Unique)
}

function Find-Zig([string]$RequiredVersion) {
    foreach ($Candidate in Get-ZigCandidates) {
        $Version = (& $Candidate version 2>$null).Trim()
        if ($LASTEXITCODE -eq 0 -and $Version -eq $RequiredVersion) {
            return $Candidate
        }
    }
    return $null
}

function Find-AnyZig {
    foreach ($Candidate in Get-ZigCandidates) {
        $Version = (& $Candidate version 2>$null).Trim()
        if ($LASTEXITCODE -eq 0 -and $Version) {
            return $Version
        }
    }
    return $null
}

function Install-Zvm([string]$RequiredVersion) {
    $CurrentVersion = Find-AnyZig
    $Prompt = if ($CurrentVersion) {
        "Found Zig $CurrentVersion, but Nova needs $RequiredVersion. Install zvm?"
    } else {
        "Zig $RequiredVersion is required. Install zvm?"
    }
    if (-not (Confirm-Action $Prompt)) {
        throw "Install Zig $RequiredVersion manually, then run the starter again."
    }

    Write-Host "Installing zvm..." -ForegroundColor Cyan
    try {
        $Installer = Invoke-WithoutProgress { Invoke-RestMethod $ZvmInstallerUrl }
    } catch {
        throw "Could not download the zvm installer. Check your internet connection and try again."
    }

    $Output = & ([scriptblock]::Create($Installer)) -Yes *>&1
    if (-not $?) {
        $Output | Out-Host
        throw "zvm installation failed."
    }

    Refresh-EnvironmentPath
    Add-PathFirst (Get-ZvmBinDirectory)
}

$RequiredVersion = Get-RequiredZigVersion
Push-Location $Root
try {
    $Zig = Find-Zig $RequiredVersion
    if (-not $Zig) {
        Install-Zvm $RequiredVersion
        $Zig = Find-Zig $RequiredVersion
    }
    if (-not $Zig) {
        throw "A compatible Zig $RequiredVersion executable is still unavailable."
    }

    Add-PathFirst (Split-Path -Parent $Zig)
    Write-Output $Zig
} finally {
    Pop-Location
}

