param(
    [string]$User = "root",
    [string]$Pass = "root",
    [string]$Bind = "127.0.0.1:8000",
    [string]$DatabasePath = "forge.db"
)

$ErrorActionPreference = "Stop"

Set-Location $PSScriptRoot

if (-not (Get-Command surreal -ErrorAction SilentlyContinue)) {
    throw "The 'surreal' command was not found. Run UpdateSurrealDB.ps1 first, then open a new terminal if PATH was updated."
}

surreal start --user $User --pass $Pass --bind $Bind "rocksdb://$DatabasePath"
