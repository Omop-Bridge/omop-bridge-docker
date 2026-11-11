-- =============================================================
-- 0. SESSION SEARCH PATH ENFORCEMENT
-- =============================================================
SET search_path TO vocab, public;

-- =============================================================
-- 1. CONTEXT & EXTENSION VERIFICATION
-- =============================================================
SELECT current_database() AS active_db, current_schema() AS active_schema;

-- Ensure extension is created in public
-- CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;

-- Verify that gin_trgm_ops is visible
SELECT opcname FROM pg_opclass WHERE opcname = 'gin_trgm_ops';

-- =============================================================
-- 2. DROP ALL EXISTING / LEGACY INDEXES FRESH
-- =============================================================
DROP INDEX IF EXISTS vocab.idx_concept_code_upper;
DROP INDEX IF EXISTS vocab.idx_concept_code_exact;
DROP INDEX IF EXISTS vocab.idx_concept_standard;
DROP INDEX IF EXISTS vocab.idx_concept_std_vocab_domain;
DROP INDEX IF EXISTS vocab.idx_concept_name_btree_standard;
DROP INDEX IF EXISTS vocab.idx_concept_name_lower_btree;
DROP INDEX IF EXISTS vocab.idx_concept_name_trgm_standard;
DROP INDEX IF EXISTS vocab.idx_concept_name_trgm;
DROP INDEX IF EXISTS vocab.idx_concept_rel_maps_to;
DROP INDEX IF EXISTS vocab.idx_concept_rel_maps_to_active;
DROP INDEX IF EXISTS vocab.idx_concept_rel_maps_to_target_active;
DROP INDEX IF EXISTS vocab.idx_concept_upper_name_std;
DROP INDEX IF EXISTS vocab.idx_concept_norm_name_std;
DROP INDEX IF EXISTS vocab.idx_concept_synonym_concept_id;
DROP INDEX IF EXISTS vocab.idx_concept_synonym_upper_name;
DROP INDEX IF EXISTS vocab.idx_concept_synonym_norm_name;
DROP INDEX IF EXISTS vocab.idx_concept_synonym_name_trgm;
DROP INDEX IF EXISTS vocab.idx_concept_rel_hierarchical_active;

-- =============================================================
-- 3. EXACT & CODE MATCHING INDEXES
-- =============================================================

CREATE INDEX idx_concept_code_upper
    ON vocab.concept (UPPER(concept_code), UPPER(vocabulary_id))
    INCLUDE (concept_id, standard_concept, domain_id);

CREATE INDEX idx_concept_code_exact
    ON vocab.concept (concept_code, vocabulary_id);

-- =============================================================
-- 4. STANDARD CONCEPT & DOMAIN FILTERING INDEXES
-- =============================================================

CREATE INDEX idx_concept_standard
    ON vocab.concept (concept_id)
    WHERE standard_concept = 'S';

CREATE INDEX idx_concept_std_vocab_domain
    ON vocab.concept (vocabulary_id, domain_id, standard_concept)
    WHERE standard_concept = 'S';

-- =============================================================
-- 5. EXACT & FUNCTIONAL TEXT SEARCH INDEXES (vocab.concept)
-- =============================================================

CREATE INDEX idx_concept_upper_name_std
    ON vocab.concept (UPPER(concept_name))
    WHERE standard_concept = 'S';

CREATE INDEX idx_concept_norm_name_std
    ON vocab.concept (UPPER(REGEXP_REPLACE(concept_name, '[\(\)\-\,\.]', ' ', 'g')))
    WHERE standard_concept = 'S';

CREATE INDEX idx_concept_name_btree_standard
    ON vocab.concept (concept_name text_pattern_ops)
    WHERE standard_concept = 'S';

CREATE INDEX idx_concept_name_lower_btree
    ON vocab.concept (LOWER(concept_name) text_pattern_ops)
    WHERE standard_concept = 'S';

CREATE INDEX idx_concept_name_trgm_standard
    ON vocab.concept USING gin (concept_name public.gin_trgm_ops)
    WHERE standard_concept = 'S';

CREATE INDEX idx_concept_name_trgm
    ON vocab.concept USING gin (concept_name public.gin_trgm_ops);

-- =============================================================
-- 6. EXACT & FUNCTIONAL SYNONYM SEARCH INDEXES (vocab.concept_synonym)
-- =============================================================

CREATE INDEX idx_concept_synonym_concept_id
    ON vocab.concept_synonym (concept_id);

CREATE INDEX idx_concept_synonym_upper_name
    ON vocab.concept_synonym (UPPER(concept_synonym_name));

CREATE INDEX idx_concept_synonym_norm_name
    ON vocab.concept_synonym (UPPER(REGEXP_REPLACE(concept_synonym_name, '[\(\)\-\,\.]', ' ', 'g')));

CREATE INDEX idx_concept_synonym_name_trgm
    ON vocab.concept_synonym USING gin (concept_synonym_name public.gin_trgm_ops);

-- =============================================================
-- 7. CONCEPT RELATIONSHIP LOOKUP INDEXES (vocab.concept_relationship)
-- =============================================================

CREATE INDEX idx_concept_rel_hierarchical_active
    ON vocab.concept_relationship (concept_id_1, relationship_id, concept_id_2)
    WHERE relationship_id IN ('Maps to', 'Is a', 'Subsumes')
  AND (invalid_reason IS NULL OR invalid_reason = '');

CREATE INDEX idx_concept_rel_maps_to_active
    ON vocab.concept_relationship (relationship_id, concept_id_1, concept_id_2)
    WHERE relationship_id = 'Maps to' AND (invalid_reason IS NULL OR invalid_reason = '');

CREATE INDEX idx_concept_rel_maps_to_target_active
    ON vocab.concept_relationship (concept_id_2, relationship_id, concept_id_1)
    WHERE relationship_id = 'Maps to' AND (invalid_reason IS NULL OR invalid_reason = '');

-- =============================================================
-- 8. REFRESH TABLE STATISTICS
-- =============================================================
ANALYZE vocab.concept;
ANALYZE vocab.concept_synonym;
ANALYZE vocab.concept_relationship;