#!/usr/bin/env bash
#
# Back up a PostgreSQL database, one dump file per schema.
# Intended to be run daily from cron on the database server.
#
# Configuration (environment variables, all optional except PGDATABASE):
#   PGDATABASE      database to back up (required)
#   PGUSER, PGHOST, PGPORT, PGPASSWORD / ~/.pgpass   standard libpq settings
#   BACKUP_DIR      where backups go            (default: /var/backups/traveller)
#   RETENTION_DAYS  delete backups older than N (default: 14)
#
# Output: $BACKUP_DIR/<YYYY-MM-DD>/<schema>.dump  (pg_dump custom format)
#
# Restore a single schema:
#   pg_restore --clean --if-exists -d <database> <schema>.dump
#
# Cron example (daily at 02:30):
#   30 2 * * * PGDATABASE=mtu_production /opt/traveller/backup_schemas.sh >> /var/log/traveller-backup.log 2>&1

set -euo pipefail

: "${PGDATABASE:?PGDATABASE must be set}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/traveller}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*"; }

day_dir="$BACKUP_DIR/$(date +%F)"
umask 077
mkdir -p "$day_dir"

# Every schema except PostgreSQL internals.
schemas=$(psql --no-psqlrc -XAtqc "
  SELECT nspname FROM pg_namespace
  WHERE nspname NOT LIKE 'pg\_%' AND nspname <> 'information_schema'
  ORDER BY nspname")

if [ -z "$schemas" ]; then
  log "ERROR: no schemas found in $PGDATABASE"
  exit 1
fi

failed=0
while IFS= read -r schema; do
  [ -z "$schema" ] && continue
  tmp="$day_dir/$schema.dump.partial"
  if pg_dump --format=custom --no-owner --schema="$schema" --file="$tmp" "$PGDATABASE"; then
    mv "$tmp" "$day_dir/$schema.dump"
    log "OK   $schema ($(du -h "$day_dir/$schema.dump" | cut -f1))"
  else
    rm -f "$tmp"
    log "FAIL $schema"
    failed=$((failed + 1))
  fi
done <<< "$schemas"

# Prune old backup directories.
find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -mtime "+$RETENTION_DAYS" -exec rm -rf {} +

if [ "$failed" -gt 0 ]; then
  log "ERROR: $failed schema(s) failed to back up"
  exit 1
fi
log "Backup complete: $day_dir"
