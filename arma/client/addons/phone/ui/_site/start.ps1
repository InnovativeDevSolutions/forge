Write-Host "Building JS and CSS bundles..."
node tools/concat-all.js

Write-Host "Starting local server..."
$pythonCommand = "python -m http.server"
try {
    Start-Process python -ArgumentList "-m", "http.server" -NoNewWindow
    Write-Host "Server started! Opening browser..."
    Start-Sleep -Seconds 1
    Start-Process "http://localhost:8000"
} catch {
    Write-Host "Error starting server. Make sure Python is installed."
    Write-Host "You can install Python from: https://www.python.org/downloads/"
    pause
}
