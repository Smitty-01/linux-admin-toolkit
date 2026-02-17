#!/usr/bin/env bash


LOG_FILE="/var/log/lat.log"
# If not root, fallback to user directory
if [[ "$EUID" -ne 0 ]]; then
    LOG_FILE="$HOME/lat.log"
fi

log() {
    local level="$1"
    local message="$2"
    printf "%s [%s] %s\n" "$(date '+%F %T')" "$level" "$message" | tee -a "$LOG_FILE"
}
