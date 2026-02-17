#!/usr/bin/env bash

backup_command() {
    case "${1:-}" in
        run)
            run_backup "${2:-full}"
            ;;
        restore)
            restore_backup "${2:-}"
            ;;
        *)
            echo "Usage: lat backup run [full|incremental]"
            exit 1
            ;;
    esac
}

run_backup() {
    require_root

    local type="${1:-full}"
    local timestamp
    timestamp=$(date +%F-%H%M%S)

    mkdir -p "$BACKUP_DIR"

    case "$type" in
        full)
            run_full_backup "$timestamp"
            ;;
        incremental)
            run_incremental_backup "$timestamp"
            ;;
        *)
            log ERROR "Invalid backup type: $type"
            exit 1
            ;;
    esac
}

restore_backup() {
    require_root

    local file="$1"

    if [[ -z "$file" || ! -f "$file" ]]; then
        log ERROR "Invalid restore file"
        exit 1
    fi

    if ! tar -tzf "$file" &>/dev/null; then
        log ERROR "Corrupted archive"
        exit 1
    fi

    log INFO "Restoring from $file"
    tar -xzf "$file" -C /
    log INFO "Restore completed"
}

generate_checksum() {
    local file="$1"
    sha256sum "$file" > "$file.sha256"
    log INFO "Checksum generated"
}

cleanup_old_backups() {
    log INFO "Removing full backups older than $RETENTION_DAYS days"

    find "$BACKUP_DIR" -type f -name "backup-*.tar.gz" -mtime +"$RETENTION_DAYS" -delete
    find "$BACKUP_DIR" -type f -name "backup-*.tar.gz.sha256" -mtime +"$RETENTION_DAYS" -delete
}

cleanup_old_snapshots() {
    log INFO "Cleaning snapshots older than $RETENTION_DAYS days"

    find "$BACKUP_DIR" -maxdepth 1 -type d -mtime +"$RETENTION_DAYS" \
        ! -name "latest" \
        -exec rm -rf {} +
}

update_duration_metric() {
    local duration="$1"

    if grep -q "^lat_backup_duration_seconds " "$METRICS_FILE" 2>/dev/null; then
        sed -i "s/^lat_backup_duration_seconds .*/lat_backup_duration_seconds $duration/" "$METRICS_FILE"
    else
        echo "lat_backup_duration_seconds $duration" >> "$METRICS_FILE"
    fi
}

run_full_backup() {
    local timestamp="$1"
    local archive="$BACKUP_DIR/backup-$timestamp.tar.gz"

    local start_time
    start_time=$(date +%s)

    log INFO "Starting FULL backup of $BACKUP_SOURCE"

    if tar -czf "$archive" -C / "${BACKUP_SOURCE#/}"; then
        generate_checksum "$archive"
        cleanup_old_backups
        increment_metric "lat_backup_success_total"
        log INFO "Full backup successful"
    else
        increment_metric "lat_backup_failure_total"
        log ERROR "Full backup failed"
        exit 1
    fi

    local end_time
    end_time=$(date +%s)

    update_duration_metric "$((end_time - start_time))"
}

run_incremental_backup() {
    local timestamp="$1"
    local snapshot_dir="$BACKUP_DIR/$timestamp"
    local latest_link="$BACKUP_DIR/latest"

    local start_time
    start_time=$(date +%s)

    log INFO "Starting INCREMENTAL snapshot backup"

    if [[ -d "$latest_link" ]]; then
        rsync -a --delete --numeric-ids \
            --link-dest="$latest_link" \
            "$BACKUP_SOURCE/" \
            "$snapshot_dir"
    else
        rsync -a --numeric-ids "$BACKUP_SOURCE/" "$snapshot_dir"
    fi

    if [[ $? -ne 0 ]]; then
        increment_metric "lat_backup_failure_total"
        log ERROR "Incremental backup failed"
        exit 1
    fi

    rm -f "$latest_link"
    ln -s "$snapshot_dir" "$latest_link"

    cleanup_old_snapshots

    increment_metric "lat_backup_success_total"

    local end_time
    end_time=$(date +%s)

    update_duration_metric "$((end_time - start_time))"

    log INFO "Incremental snapshot created: $snapshot_dir"
}
