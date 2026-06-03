@echo off
setlocal EnableExtensions
set "DEFAULT_SURREALDB_VERSION=3"
set "TARGET_SURREALDB_VERSION=%~1"

if not defined TARGET_SURREALDB_VERSION set "TARGET_SURREALDB_VERSION=%FORGE_SURREALDB_VERSION%"
if not defined TARGET_SURREALDB_VERSION set "TARGET_SURREALDB_VERSION=%DEFAULT_SURREALDB_VERSION%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0UpdateSurrealDB.ps1" -Version "%TARGET_SURREALDB_VERSION%"
exit /b %errorlevel%
