@echo off
where surreal >nul 2>nul
if %errorlevel% equ 0 (
    surreal upgrade
    surreal version
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "iwr https://windows.surrealdb.com -useb | iex"
    where surreal >nul 2>nul
    if %errorlevel% equ 0 (
        surreal version
    ) else (
        echo SurrealDB install finished. Open a new terminal if the surreal command is not available yet.
    )
)
