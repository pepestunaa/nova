[CmdletBinding()]
param(
    [Alias("y")]
    [switch]$Yes,
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$ServerArgs
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Setup = Join-Path $PSScriptRoot "setup.ps1"

$Zig = & $Setup -Yes:$Yes
if (-not $Zig) {
    throw "Astralis setup did not return a Zig executable."
}

if ($ServerArgs.Count -ne 0 -and $ServerArgs[0] -eq "--") {
    $ServerArgs = @($ServerArgs | Select-Object -Skip 1)
}

Push-Location $Root
try {
    if ($ServerArgs.Count -ne 0) {
        & $Zig build -Doptimize=ReleaseSafe serve-all -- @ServerArgs
    } else {
        & $Zig build -Doptimize=ReleaseSafe serve-all
    }
    if ($LASTEXITCODE -ne 0) {
        throw "Astralis exited with code $LASTEXITCODE."
    }
} finally {
    Pop-Location
}

