[CmdletBinding()]
param(
    [Alias("y")]
    [switch]$Yes,
    [string]$Path
)

$ErrorActionPreference = "Stop"
$RepositoryUrl = "https://github.com/pepestunaa/nova.git"
$Branch = "main"
$ProjectName = "Nova"
$GitReleaseApi = "https://api.github.com/repos/git-for-windows/git/releases/latest"

function Confirm-Action([string]$Prompt) {
    if ($Yes) {
        return $true
    }
    return (Read-Host "$Prompt [y/N]") -match "^(?i:y|yes)$"
}

if ($PSScriptRoot) {
    $LocalRoot = Split-Path -Parent $PSScriptRoot
    $LocalStart = Join-Path $PSScriptRoot "start.ps1"
    if ((Test-Path -LiteralPath (Join-Path $LocalRoot ".git") -PathType Container) -and
        (Test-Path -LiteralPath (Join-Path $LocalRoot "build.zig.zon") -PathType Leaf) -and
        (Test-Path -LiteralPath $LocalStart -PathType Leaf)) {
        Write-Host "Nova is already installed at $LocalRoot." -ForegroundColor Cyan
        if (Confirm-Action "Start Nova from this checkout?") {
            Clear-Host
            & $LocalStart -Yes:$Yes
        }
        return
    }
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

function Refresh-EnvironmentPath {
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $MachinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $env:Path = (@($UserPath, $MachinePath, $env:Path) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join [IO.Path]::PathSeparator
}

function Add-PathFirst([string]$Directory) {
    $Entries = @($env:Path -split [IO.Path]::PathSeparator |
        Where-Object { $_ -and -not $_.Equals($Directory, [StringComparison]::OrdinalIgnoreCase) })
    $env:Path = (@($Directory) + $Entries) -join [IO.Path]::PathSeparator
}

function Find-Git {
    $Command = Get-Command git -CommandType Application -ErrorAction SilentlyContinue
    if ($Command) {
        return $Command.Source
    }

    $Candidates = @()
    if ($env:ProgramFiles) {
        $Candidates += Join-Path $env:ProgramFiles "Git\cmd\git.exe"
    }
    if (${env:ProgramFiles(x86)}) {
        $Candidates += Join-Path ${env:ProgramFiles(x86)} "Git\cmd\git.exe"
    }
    if ($env:LocalAppData) {
        $Candidates += Join-Path $env:LocalAppData "Programs\Git\cmd\git.exe"
    }

    foreach ($Candidate in $Candidates) {
        if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
            Add-PathFirst (Split-Path -Parent $Candidate)
            return $Candidate
        }
    }
    return $null
}

function Install-Git {
    if (-not (Confirm-Action "Git is required. Install it?")) {
        throw "Install Git manually, then run the installer again."
    }

    Write-Host "Installing Git..." -ForegroundColor Cyan
    $InstallerArguments = '/VERYSILENT /SP- /NORESTART /NOCANCEL /CLOSEAPPLICATIONS /NOICONS /COMPONENTS="gitlfs,assoc,autoupdate"'

    if (Get-Command winget -CommandType Application -ErrorAction SilentlyContinue) {
        & winget install --id Git.Git --exact --source winget `
            --accept-package-agreements --accept-source-agreements `
            --override $InstallerArguments | Out-Host
        if ($LASTEXITCODE -ne 0) {
            throw "winget could not install Git (exit code $LASTEXITCODE)."
        }
    } else {
        Write-Host "    winget is unavailable; downloading the official Git installer..." -ForegroundColor DarkGray
        try {
            $Release = Invoke-WithoutProgress { Invoke-RestMethod $GitReleaseApi }
        } catch {
            throw "Could not download Git release metadata. Check your internet connection and try again."
        }

        $AssetPattern = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
            '^Git-.*-arm64\.exe$'
        } else {
            '^Git-.*-64-bit\.exe$'
        }
        $Asset = $Release.assets | Where-Object { $_.name -match $AssetPattern } | Select-Object -First 1
        if (-not $Asset) {
            throw "Could not find a suitable Git release."
        }

        $InstallerPath = Join-Path $env:TEMP $Asset.name
        try {
            Invoke-WithoutProgress {
                Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $InstallerPath
            } | Out-Null
            $Process = Start-Process -FilePath $InstallerPath -ArgumentList $InstallerArguments -Wait -PassThru
            if ($Process.ExitCode -ne 0) {
                throw "Git could not be installed (exit code $($Process.ExitCode))."
            }
        } finally {
            Remove-Item -LiteralPath $InstallerPath -ErrorAction SilentlyContinue
        }
    }

    Refresh-EnvironmentPath
    $Git = Find-Git
    if (-not $Git) {
        throw "Git was installed but is unavailable in this PowerShell process."
    }
    return $Git
}

function Ensure-Git {
    $Git = Find-Git
    if ($Git) {
        return $Git
    }
    return Install-Git
}

function Get-DownloadsFolder {
    $Shell = $null
    try {
        $Shell = New-Object -ComObject Shell.Application
        $Downloads = $Shell.NameSpace("shell:Downloads").Self.Path
        if ($Downloads) {
            return $Downloads
        }
    } catch {
    } finally {
        if ($Shell) {
            [Runtime.InteropServices.Marshal]::ReleaseComObject($Shell) | Out-Null
        }
    }
    return Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads"
}

function Select-Checkout {
    if ($Path) {
        return [IO.Path]::GetFullPath($Path)
    }

    $DefaultParent = Get-DownloadsFolder
    if ($Yes) {
        return Join-Path $DefaultParent $ProjectName
    }

    $Dialog = $null
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $Dialog = [System.Windows.Forms.FolderBrowserDialog]::new()
        $Dialog.Description = "Choose where Nova should be installed"
        $Dialog.SelectedPath = $DefaultParent
    } catch {
        $Dialog = $null
    }

    if ($Dialog) {
        try {
            if ($Dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
                throw "Installation cancelled."
            }
            $Selected = $Dialog.SelectedPath
        } finally {
            $Dialog.Dispose()
        }
    } else {
        $Selected = Read-Host "Where should Nova be installed? [$DefaultParent]"
        if ([string]::IsNullOrWhiteSpace($Selected)) {
            $Selected = $DefaultParent
        }
    }

    $Absolute = [IO.Path]::GetFullPath($Selected)
    if ((Split-Path -Leaf $Absolute) -ieq $ProjectName) {
        return $Absolute
    }
    return Join-Path $Absolute $ProjectName
}

function Normalize-Remote([string]$Remote) {
    $Value = $Remote.Trim().Replace('\', '/').TrimEnd('/')
    if ($Value.EndsWith(".git", [StringComparison]::OrdinalIgnoreCase)) {
        $Value = $Value.Substring(0, $Value.Length - 4)
    }
    return $Value
}

function Assert-Checkout([string]$Git, [string]$Checkout) {
    if (-not (Test-Path -LiteralPath (Join-Path $Checkout ".git") -PathType Container)) {
        throw "'$Checkout' already exists and is not an Nova Git checkout."
    }
    $Origin = (& $Git -C $Checkout remote get-url origin).Trim()
    if ($LASTEXITCODE -ne 0 -or (Normalize-Remote $Origin) -ine (Normalize-Remote $RepositoryUrl)) {
        throw "The checkout at '$Checkout' does not use the Nova repository as its origin."
    }
    $CurrentBranch = (& $Git -C $Checkout branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0 -or $CurrentBranch -cne $Branch) {
        throw "The checkout at '$Checkout' is on branch '$CurrentBranch', not '$Branch'."
    }
}

$Git = Ensure-Git
$Checkout = Select-Checkout
$NeedsClone = $true

if (Test-Path -LiteralPath $Checkout) {
    if (Test-Path -LiteralPath (Join-Path $Checkout ".git") -PathType Container) {
        Assert-Checkout $Git $Checkout
        $NeedsClone = $false
    } elseif (-not (Test-Path -LiteralPath $Checkout -PathType Container)) {
        throw "'$Checkout' exists and is not a directory."
    } elseif (Get-ChildItem -LiteralPath $Checkout -Force | Select-Object -First 1) {
        throw "'$Checkout' already exists and is not empty."
    }
}

if ($NeedsClone) {
    Write-Host "`nNova will be installed at:" -ForegroundColor Cyan
    Write-Host "    $Checkout" -ForegroundColor DarkGray
    if (-not (Confirm-Action "Continue?")) {
        throw "Installation cancelled."
    }

    [IO.Directory]::CreateDirectory((Split-Path -Parent $Checkout)) | Out-Null
    & $Git clone --depth=1 --branch $Branch --single-branch -- $RepositoryUrl $Checkout
    if ($LASTEXITCODE -ne 0) {
        throw "Git could not clone Nova (exit code $LASTEXITCODE)."
    }
}

$Setup = Join-Path $Checkout "scripts\setup.ps1"
if (-not (Test-Path -LiteralPath $Setup -PathType Leaf)) {
    throw "The Nova checkout does not contain scripts\setup.ps1."
}
$null = & $Setup -Yes:$Yes

Write-Host "`n[OK] Nova is ready at $Checkout" -ForegroundColor Green
Write-Host "Start it by running:" -ForegroundColor Gray
Write-Host "    $(Join-Path $Checkout 'scripts\start.cmd')" -ForegroundColor Cyan
