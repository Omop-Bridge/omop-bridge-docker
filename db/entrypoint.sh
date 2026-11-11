#!/bin/bash
set -e

ATHENADIR="/docker-entrypoint-initdb.d/athena_data"
EXTRACT_DIR="/tmp/athena_extracted"
INDEX_FILE="/docker-entrypoint-initdb.d/omop_bridge_performance_indexes.sql"

echo "Starting PostgreSQL in the background for vocabulary check..."
docker-entrypoint.sh postgres &
pid=$!

# Wait for PostgreSQL to be ready
until pg_isready -U "${POSTGRES_USER:-omop}" -d "${POSTGRES_DB:-omop_cdm}" -h localhost -p 5432; do
  sleep 1
done

# Safely check if vocab.concept exists and has rows
CONCEPT_COUNT=$(psql -U "${POSTGRES_USER:-omop}" -d "${POSTGRES_DB:-omop_cdm}" -t -c "SELECT COALESCE((SELECT count(*) FROM vocab.concept), 0);" 2>/dev/null | tr -d ' ' || echo "0")

if [ "$CONCEPT_COUNT" -gt 0 ]; then
    echo "=================================================="
    echo "Vocabularies already loaded ($CONCEPT_COUNT concepts found). Skipping import."
    echo "=================================================="
else
    ZIP_PATH=$(find "$ATHENADIR" -maxdepth 2 -name "vocabulary_download*.zip" | head -n 1)

    if [ -n "$ZIP_PATH" ] && [ -f "$ZIP_PATH" ]; then
        echo "=================================================="
        echo "Found Athena package: $(basename "$ZIP_PATH")"
        echo "=================================================="

        mkdir -p "$EXTRACT_DIR"
        unzip -o -q "$ZIP_PATH" -d "$EXTRACT_DIR"

        if [ -f "$EXTRACT_DIR/cpt4.sh" ]; then
            echo "Running CPT4 concept decoder..."
            cd "$EXTRACT_DIR"
            chmod +x cpt4.sh
            ./cpt4.sh 5 || echo "CPT4 script skipped or completed with warnings."
            cd - > /dev/null
        fi

        echo "Loading vocabulary CSVs into PostgreSQL (vocab schema)..."
        psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER:-omop}" --dbname "${POSTGRES_DB:-omop_cdm}" <<-EOSQL
            -- Temporarily disable foreign key checks to handle circular dependencies
            SET session_replication_role = 'replica';

            \copy vocab.concept FROM '$EXTRACT_DIR/CONCEPT.csv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
            \copy vocab.domain FROM '$EXTRACT_DIR/DOMAIN.csv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
            \copy vocab.concept_class FROM '$EXTRACT_DIR/CONCEPT_CLASS.csv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
            \copy vocab.relationship FROM '$EXTRACT_DIR/RELATIONSHIP.csv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
            \copy vocab.vocabulary FROM '$EXTRACT_DIR/VOCABULARY.csv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
            \copy vocab.concept_synonym FROM '$EXTRACT_DIR/CONCEPT_SYNONYM.csv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
            \copy vocab.concept_relationship FROM '$EXTRACT_DIR/CONCEPT_RELATIONSHIP.csv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
            \copy vocab.concept_ancestor FROM '$EXTRACT_DIR/CONCEPT_ANCESTOR.csv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
            \copy vocab.drug_strength FROM '$EXTRACT_DIR/DRUG_STRENGTH.csv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
            \copy vocab.pack_content FROM '$EXTRACT_DIR/PACK_CONTENT.csv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
            \copy vocab.concept_metadata FROM '$EXTRACT_DIR/CONCEPT_METADATA.csv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');
            \copy vocab.concept_relationship_metadata FROM '$EXTRACT_DIR/CONCEPT_RELATIONSHIP_METADATA.csv' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b');

            -- Re-enable foreign key checks
            SET session_replication_role = 'origin';
EOSQL

        echo "Vocabulary load completed successfully."
        rm -rf "$EXTRACT_DIR"
    else
        echo "No file matching 'vocabulary_download*.zip' found in $ATHENADIR."
    fi
fi

# Ensure pg_trgm extension is created using the container superuser ($POSTGRES_USER)
echo "Ensuring pg_trgm extension is created..."
psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER:-omop}" --dbname "${POSTGRES_DB:-omop_cdm}" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;
    SET search_path TO vocab, public;
EOSQL

# Run performance index script if present
echo "Checking for performance index file at: $INDEX_FILE"
if [ -f "$INDEX_FILE" ]; then
    echo "Executing performance indexing script..."
    psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER:-omop}" --dbname "${POSTGRES_DB:-omop_cdm}" -f "$INDEX_FILE"
    echo "Performance indexes applied successfully."
else
    echo "WARNING: Performance index file not found at $INDEX_FILE. Skipping indexing."
fi

# Bring PostgreSQL back to the foreground so the container stays running normally
wait "$pid"