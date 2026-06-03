@echo off
setlocal EnableExtensions
set "FORGE_SURREALDB_VERSION=%~1"
if not defined FORGE_SURREALDB_VERSION set "FORGE_SURREALDB_VERSION=3"

call "%~dp0UpdateMe.bat" "%FORGE_SURREALDB_VERSION%"
if errorlevel 1 exit /b %errorlevel%
call "%~dp0RunMe.bat"
