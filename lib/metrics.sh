#!/usr/bin/env bash

increment_metric() {
    local metric="$1"

    mkdir -p "$(dirname "$METRICS_FILE")"

    if [[ ! -f "$METRICS_FILE" ]]; then
        echo "$metric 1" > "$METRICS_FILE"
        return
    fi

    if grep -q "^$metric " "$METRICS_FILE"; then
        local current
        current=$(grep "^$metric " "$METRICS_FILE" | awk '{print $2}')
        local new=$((current + 1))
        sed -i "s/^$metric .*/$metric $new/" "$METRICS_FILE"
    else
        echo "$metric 1" >> "$METRICS_FILE"
    fi
}
