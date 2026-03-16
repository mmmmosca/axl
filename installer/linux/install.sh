#!/bin/sh

set -e

echo "Installing AXL..."

URL="https://github.com/mmmmosca/axl/releases/latest/download/axl"

# Download the latest AXL binary
curl -L "$URL" -o axl

chmod +x axl
sudo mv axl /usr/local/bin/axl

echo "AXL installed successfully!"
