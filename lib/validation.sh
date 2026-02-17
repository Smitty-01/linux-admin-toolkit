#!/usr/bin/env bash

require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "This command must be run as root"
        exit 1
    fi
}
