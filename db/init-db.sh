#!/bin/bash
set -e

DUMP_FILE="/docker-entrypoint-initdb.d/omop_vocab_baseline.sql.gz"

# Skip the heavy import if the vocabulary baseline is already populated
if psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT to_regclass('vocab.concept');" | grep -q "concept"; then
    ROW_COUNT=$(psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT count(*) FROM vocab.concept;" 2>/dev/null || echo "0")
    if [ "$ROW_COUNT" -gt 0 ]; then
        echo "OMOP database already initialized with data ($ROW_COUNT concepts found). Skipping import."
        exit 0
    fi
fi

echo "Starting optimized OMOP compressed SQL database restore..."

if [ -f "$DUMP_FILE" ]; then
    FILE_SIZE=$(stat -c%s "$DUMP_FILE" 2>/dev/null || stat -f%z "$DUMP_FILE")

    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<-EOSQL
        SET synchronous_commit = OFF;
        ALTER SYSTEM SET maintenance_work_mem = '1GB';
        ALTER SYSTEM SET max_wal_size = '4GB';
        SELECT pg_reload_conf();
EOSQL

    pv -s "$FILE_SIZE" "$DUMP_FILE" | gunzip | psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" --set ON_ERROR_STOP=1

    echo "Import stream finished. Re-enabling safety settings and running vacuum..."

    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<-EOSQL
        RESET synchronous_commit;
        VACUUM ANALYZE;
EOSQL

    echo "OMOP compressed SQL database restore completed successfully!"
else
    echo "Error: Dump file not found at $DUMP_FILE"
    exit 1
fi