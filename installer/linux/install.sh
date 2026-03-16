#!/bin/sh
set -e

echo "Installing AXL from source..."

# Check for D compiler
if ! command -v dmd >/dev/null 2>&1 && ! command -v ldc2 >/dev/null 2>&1; then
  echo "Error: You need D compiler (dmd or ldc2) installed."
  exit 1
fi

# Create temp dir
TMP=$(mktemp -d)
cd "$TMP"

echo "Downloading AXL source..."
curl -L -o axl.zip https://github.com/mmmmosca/axl/archive/refs/heads/main.zip
unzip axl.zip
cd axl-main/interpreter

echo "Compiling..."
# Try DMD first
if command -v dmd >/dev/null 2>&1; then
  dmd -O -release -inline interpreter.d -of=axl
else
  ldc2 -O3 -release interpreter.d -of=axl
fi

chmod +x axl
sudo mv axl /usr/local/bin/

echo "AXL installed successfully!"
echo "Run it with: axl yourfile.axl"

# Cleanup
cd /
rm -rf "$TMP"
