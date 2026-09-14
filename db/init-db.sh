#!/bin/bash
set -e

DUMP_FILE="/docker-entrypoint-initdb.d/omop_vocab_baseline.sql.gz"
INDEX_FILE="/docker-entrypoint-initdb.d/055_omop_bridge_performance_indexes.sql"

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
    FILE_SIZE=$(stat -c%s "$DUMP_FILE" 2>/dev/null || stat -f%z "$DUMP_FILE" 2>/dev/null || echo "0")

    echo "Dropping existing schemas to ensure a clean import..."
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<-EOSQL
    DROP SCHEMA IF EXISTS cdm CASCADE;
    DROP SCHEMA IF EXISTS vocab CASCADE;
    DROP SCHEMA IF EXISTS staging CASCADE;
EOSQL

    # Session-level performance parameters (avoids ALTER SYSTEM permission/restart issues)
    PGOPTIONS="-c synchronous_commit=off -c maintenance_work_mem=512MB"

    pv -s "$FILE_SIZE" "$DUMP_FILE" | gunzip | sed 's/CREATE SCHEMA /CREATE SCHEMA IF NOT EXISTS /g' | PGOPTIONS="$PGOPTIONS" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" --set ON_ERROR_STOP=1

    echo "Import stream finished. Running ANALYZE..."

    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "ANALYZE;"

    if [ -f "$INDEX_FILE" ]; then
        echo "Applying custom OMOP Bridge performance indexes..."
        PGOPTIONS="$PGOPTIONS" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" --set ON_ERROR_STOP=1 -f "$INDEX_FILE"
    fi

    echo "OMOP compressed SQL database restore and performance indexing completed successfully!"
else
    echo "Error: Dump file not found at $DUMP_FILE"
    exit 1
fi