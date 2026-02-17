#!/usr/bin/env bash
set -e

INSTALL_DIR="/usr/local/lib/lat"

sudo mkdir -p "$INSTALL_DIR"

sudo cp -r lib modules config "$INSTALL_DIR"
sudo cp bin/lat /usr/local/bin/lat

echo "Installed to /usr/local/bin/lat"
echo "Toolkit files in $INSTALL_DIR"
