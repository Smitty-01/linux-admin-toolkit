
# Linux Admin Toolkit (LAT)

Linux Admin Toolkit (LAT) is a modular, installable Linux administration CLI tool designed to automate reliable system backups with observability and clean architecture.

It supports:

- Full compressed backups (tar-based)
- Incremental snapshot backups (rsync hardlink strategy)
- Automated retention enforcement
- Checksum validation
- Structured logging
- Global error trapping
- Prometheus-compatible metrics
- Modular CLI architecture



# Architecture

```

/usr/local/bin/lat                 → CLI entrypoint
/usr/local/lib/lat/
├── lib/
│   ├── logging.sh
│   ├── validation.sh
│   ├── metrics.sh
├── modules/
│   └── backup.sh
└── config/
└── default.conf

````

## Design Principles

- Strict mode (`set -euo pipefail`)
- Centralized configuration
- Dynamic module loading
- Root validation for privileged actions
- Hardlink-based snapshot deduplication
- Prometheus-style metrics export
- ShellCheck-compliant codebase

---

# Installation

## 1. Clone Repository

```bash
git clone https://github.com/<your-username>/linux-admin-toolkit.git
cd linux-admin-toolkit
````

## 2. Install System-Wide

```bash
chmod +x install.sh
sudo ./install.sh
```

This installs:

```
/usr/local/bin/lat
/usr/local/lib/lat/
```

## 3. Verify Installation

```bash
lat --version
```

Expected output:

```
Linux Admin Toolkit v1.0.0
```

---

# Configuration

Configuration file:

```
/usr/local/lib/lat/config/default.conf
```

Example:

```bash
BACKUP_SOURCE="/etc"
BACKUP_DIR="/backup"
RETENTION_DAYS=7
METRICS_FILE="/var/log/lat_metrics.prom"
```

Modify as needed.

---

# Usage

## Full Backup

Creates a compressed archive of the configured source.

```bash
sudo lat backup run full
```

### Output Files

```
/backup/backup-YYYY-MM-DD-HHMMSS.tar.gz
/backup/backup-YYYY-MM-DD-HHMMSS.tar.gz.sha256
```

---

## Incremental Snapshot Backup

Creates storage-efficient snapshots using rsync with hardlinks.

```bash
sudo lat backup run incremental
```

### Snapshot Structure

```
/backup/
  ├── 2026-02-18-000826/
  ├── 2026-02-18-000839/
  └── latest -> 2026-02-18-000839
```

Unchanged files are hardlinked between snapshots, minimizing disk usage.

---

## Restore From Full Backup

```bash
sudo lat backup restore /backup/backup-YYYY-MM-DD-HHMMSS.tar.gz
```

The archive is validated before extraction.

---

# Logging

All operations are logged to:

```
/var/log/lat.log
```

Example:

```
2026-02-18 00:08:26 [INFO] Starting INCREMENTAL snapshot backup
```

Includes global error trap:

```bash
trap 'log ERROR ...' ERR
```

Ensures no silent failures.

---

# Metrics (Prometheus-Compatible)

Metrics file:

```
/var/log/lat_metrics.prom
```

Example:

```
lat_backup_success_total 2
lat_backup_failure_total 0
lat_backup_duration_seconds 1
```

### View Metrics

```bash
sudo cat /var/log/lat_metrics.prom
```

These metrics can be scraped by Prometheus or other monitoring tools.

---

# Retention Policy

Automatically deletes:

* Full backups older than `RETENTION_DAYS`
* Snapshot directories older than `RETENTION_DAYS`

Configured in:

```bash
RETENTION_DAYS=7
```



# Example Workflow

```bash
sudo lat backup run full
sudo lat backup run incremental
sudo lat backup run incremental
sudo cat /var/log/lat_metrics.prom
```




