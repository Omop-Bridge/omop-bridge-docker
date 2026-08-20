-- Insert source if source_key 'OMOP_BRIDGE' doesn't already exist
INSERT INTO webapi."source"
(source_id, source_name, source_key, source_connection, source_dialect, username, "password", krb_auth_method)
VALUES(1, 'Omop Bridge', 'OMOP_BRIDGE', 'jdbc:postgresql://omop-bridge-db:5432/omop_cdm?user=omop&password=omop', 'postgresql', NULL, NULL, 'PASSWORD')
ON CONFLICT (source_key) DO NOTHING;

-- Insert source daimons, skipping if the source_daimon_id already exists
INSERT INTO webapi.source_daimon
(source_daimon_id, source_id, daimon_type, table_qualifier, priority)
VALUES(1, 1, 0, 'cdm', 0)
ON CONFLICT (source_daimon_id) DO NOTHING;

INSERT INTO webapi.source_daimon
(source_daimon_id, source_id, daimon_type, table_qualifier, priority)
VALUES(2, 1, 1, 'vocab', 10)
ON CONFLICT (source_daimon_id) DO NOTHING;

INSERT INTO webapi.source_daimon
(source_daimon_id, source_id, daimon_type, table_qualifier, priority)
VALUES(3, 1, 2, 'results', 5)
ON CONFLICT (source_daimon_id) DO NOTHING;