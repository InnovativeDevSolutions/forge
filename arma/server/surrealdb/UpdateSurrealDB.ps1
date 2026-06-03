param(
    [string]$Version = "3",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$VersionUrl = "https://version.surrealdb.com"
$DownloadBaseUrl = "https://download.surrealdb.com"
$Architecture = "windows-amd64"

function Normalize-Version {
    param([string]$Value)

    $trimmed = $Value.Trim()
    if ($trimmed -match "(?i)^latest$") {
        return "latest"
    }
    if ($trimmed -match "^v?\d+$") {
        return $trimmed.TrimStart("v")
    }
    if ($trimmed -match "^v?\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$") {
        return "v$($trimmed.TrimStart("v"))"
    }

    throw "Unsupported SurrealDB version '$Value'. Use a major version like '3', an exact version like 'v3.1.2', or 'latest'."
}

function Get-Latest-Version {
    return (Invoke-WebRequest $VersionUrl -UseBasicParsing).Content.Trim()
}

function Resolve-Version {
    param([string]$Target)

    $normalized = Normalize-Version $Target
    if ($normalized -eq "latest") {
        return Get-Latest-Version
    }

    if ($normalized -match "^\d+$") {
        $latest = Get-Latest-Version
        if ($latest -notmatch "^v?$normalized\.") {
            throw "Latest SurrealDB is $latest, not $normalized.x. Pass an exact $normalized.x version or use 'latest' after confirming Forge compatibility."
        }

        return $latest
    }

    return $normalized
}

function Confirm-Latest {
    if ($Force) {
        return
    }

    Write-Host ""
    Write-Host "WARNING: This will install the latest stable SurrealDB release, even if it is newer"
    Write-Host "than the Forge server extension was compiled and tested against."
    Write-Host ""
    Write-Host "The Forge server extension currently targets SurrealDB 3.x. A newer major"
    Write-Host "SurrealDB release can require rebuilding Forge from source with a compatible"
    Write-Host "surrealdb Rust crate before the extension works correctly."
    Write-Host ""

    $answer = Read-Host "Install latest SurrealDB anyway? [Y/N]"
    if ($answer -notmatch "^(?i)y(es)?$") {
        exit 1
    }
}

function Get-Install-Path {
    $existing = Get-Command surreal -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $existing -and $existing.Source -and (Split-Path -Leaf $existing.Source) -ieq "surreal.exe") {
        return $existing.Source
    }

    $installDirectory = Join-Path $env:LOCALAPPDATA "SurrealDB"
    New-Item -ItemType Directory -Force -Path $installDirectory | Out-Null
    return Join-Path $installDirectory "surreal.exe"
}

function Ensure-User-Path {
    param([string]$Directory)

    $pathParts = $env:Path -split ";" | Where-Object { $_ }
    if ($pathParts -notcontains $Directory) {
        $env:Path = "$Directory;$env:Path"
    }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $userPathParts = $userPath -split ";" | Where-Object { $_ }
    if ($userPathParts -notcontains $Directory) {
        $newUserPath = if ([string]::IsNullOrWhiteSpace($userPath)) { $Directory } else { "$Directory;$userPath" }
        [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
        Write-Host "Added $Directory to the user PATH. Open a new terminal if 'surreal' is not found later."
    }
}

$normalizedTarget = Normalize-Version $Version
if ($normalizedTarget -eq "latest") {
    Confirm-Latest
}

$resolvedVersion = Resolve-Version $Version
$installPath = Get-Install-Path
$installDirectory = Split-Path -Parent $installPath
New-Item -ItemType Directory -Force -Path $installDirectory | Out-Null

$downloadUrl = "$DownloadBaseUrl/$resolvedVersion/surreal-$resolvedVersion.$Architecture.exe"
$tempPath = Join-Path ([System.IO.Path]::GetTempPath()) "surreal-$resolvedVersion.$Architecture.exe"

Write-Host "Installing SurrealDB $resolvedVersion from $downloadUrl"
Invoke-WebRequest $downloadUrl -OutFile $tempPath -UseBasicParsing
Move-Item -Force -Path $tempPath -Destination $installPath
Ensure-User-Path $installDirectory

& $installPath version
