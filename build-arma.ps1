#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build both arma/client and arma/server using hemtt

.DESCRIPTION
    This script runs hemtt build for both the client and server Arma mods.
    It changes to each directory and runs the build command.

.PARAMETER Target
    Specify which target to build: 'client', 'server', or 'both' (default)

.PARAMETER BuildUI
    Rebuild the web UI bundles before running the client build.

.EXAMPLE
    .\build-arma.ps1
    Builds both client and server

.EXAMPLE
    .\build-arma.ps1 -Target client
    Builds only the client

.EXAMPLE
    .\build-arma.ps1 -Target client -BuildUI
    Rebuilds web UI bundles and then builds the client
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('client', 'server', 'both')]
    [string]$Target = 'both',

    [Parameter(Mandatory=$false)]
    [switch]$BuildUI
)

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot

function Build-WebUIAssets {
    Write-Host "`n=== Building Web UI Bundles ===" -ForegroundColor Cyan

    Push-Location $scriptDir
    try {
        & npm run build:webui
        if ($LASTEXITCODE -ne 0) {
            throw "Web UI bundle build failed with exit code $LASTEXITCODE"
        }
        Write-Host "✓ Web UI bundles built successfully" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

function Build-HemttProject {
    param(
        [string]$ProjectPath,
        [string]$ProjectName
    )
    
    Write-Host "`n=== Building $ProjectName ===" -ForegroundColor Cyan
    
    Push-Location $ProjectPath
    try {
        & hemtt utils fnl && hemtt build
        if ($LASTEXITCODE -ne 0) {
            throw "hemtt build failed for $ProjectName with exit code $LASTEXITCODE"
        }
        Write-Host "✓ $ProjectName build successful" -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

$clientPath = Join-Path $scriptDir "arma\client"
$serverPath = Join-Path $scriptDir "arma\server"

try {
    if ($Target -eq 'client' -or $Target -eq 'both') {
        if ($BuildUI) {
            Build-WebUIAssets
        }
        Build-HemttProject -ProjectPath $clientPath -ProjectName "Client"
    }
    
    if ($Target -eq 'server' -or $Target -eq 'both') {
        Build-HemttProject -ProjectPath $serverPath -ProjectName "Server"
    }
    
    Write-Host "`n=== Build Complete ===" -ForegroundColor Green
}
catch {
    Write-Host "`n✗ Build failed: $_" -ForegroundColor Red
    exit 1
}
