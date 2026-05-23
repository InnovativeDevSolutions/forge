#!/bin/bash

set -e

echo "Building JS and CSS bundles..."
node tools/concat-all.js

echo "Starting local server..."
python3 -m http.server &
SERVER_PID=$!
sleep 1

# Try to open the browser automatically (Linux: xdg-open, macOS: open)
if command -v xdg-open > /dev/null; then
  xdg-open http://localhost:8000
elif command -v open > /dev/null; then
  open http://localhost:8000
else
  echo "Please open http://localhost:8000 in your browser."
fi

wait $SERVER_PID 