-- Diagnostic check: Verify which database and schema context you are executing in
SELECT current_database() AS active_db, current_schema() AS active_schema;

-- Forcefully drop and recreate the extension in the current database's public schema
DROP EXTENSION IF EXISTS pg_trgm CASCADE;
CREATE EXTENSION pg_trgm WITH SCHEMA public;

-- Verify that the operator class now exists in the system catalogs
SELECT opcname FROM pg_opclass WHERE opcname = 'gin_trgm_ops';

-- Set search path explicitly
SET search_path TO vocab, public;

-- 1. Functional uppercase index for concept code & vocabulary
CREATE INDEX IF NOT EXISTS idx_concept_code_upper
    ON vocab.concept (UPPER(concept_code), UPPER(vocabulary_id))
    INCLUDE (concept_id, standard_concept, domain_id);

-- 2. Partial index for 'Maps to' relationships
CREATE INDEX IF NOT EXISTS idx_concept_rel_maps_to
    ON vocab.concept_relationship (concept_id_1, concept_id_2)
    WHERE relationship_id = 'Maps to' AND (invalid_reason IS NULL OR invalid_reason = '');

-- 3. Fast filter for standard concepts
CREATE INDEX IF NOT EXISTS idx_concept_standard
    ON vocab.concept (concept_id)
    WHERE standard_concept = 'S';

-- 4. Trigram index for fast ILIKE concept name searching
CREATE INDEX IF NOT EXISTS idx_concept_name_trgm
    ON vocab.concept USING gin (concept_name public.gin_trgm_ops);

-- 5. Optimized lookup for active 'Maps to' relationships
CREATE INDEX IF NOT EXISTS idx_concept_rel_maps_to_active
    ON vocab.concept_relationship (relationship_id, concept_id_1, concept_id_2)
    WHERE relationship_id = 'Maps to' AND (invalid_reason IS NULL OR invalid_reason = '');