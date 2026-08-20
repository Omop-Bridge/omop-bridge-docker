-- create OHDSI Eunomia demo data source generation permission
INSERT INTO webapi.sec_permission (value, description)
     VALUES ('cohortdefinition:*:generate:OMOP-Bridge:get', 'Generate Cohort on Source with SourceKey = OMOP_Bridge');

-- create OHDSI Eunomia demo data source cohort inclusion rule report permission
INSERT INTO webapi.sec_permission (value, description)
     VALUES ('cohortdefinition:*:report:OMOP-Bridge:get', 'Get Inclusion Rule Report for Source with SourceKey = OMOP_Bridge');

-- create OHDSI Eunomia demo data source role and ohdsi role
INSERT INTO webapi.sec_role (name)
    VALUES
    ('Source user (OMOP-Bridge)'), -- role id 1000
    ('ohdsi'); -- role id 1001

-- link data source generation permission to EUNOMIA data source role
INSERT INTO webapi.sec_role_permission (role_id, permission_id, status)
    VALUES (1000, 1000, NULL); -- EUNOMIA user role, generate cohort on source EUNOMIA permission

-- link DEMO data source inclusion role report permission to EUNOMIA data source role
INSERT INTO webapi.sec_role_permission (role_id, permission_id, status)
    VALUES (1000, 1001, NULL); -- EUNOMIA user role, inclusion role report on source EUNOMIA permission

-- create ordinary user called 'ohdsi' and admin user called 'admin'
INSERT INTO webapi.sec_user(login, name)
    VALUES
    ('ohdsi','ohdsi'), -- ohdsi user
    ('admin','admin'); -- admin user

-- assign required roles to ohdsi user (user_id 1000) and admin user (user_id 1001)
INSERT INTO webapi.sec_user_role (id, user_id, role_id, status, origin)
VALUES
  (DEFAULT, 1000, 1001, null, 'SYSTEM'), -- ohdsi user -> 'ohdsi' role
  (DEFAULT, 1000, 1, null, 'SYSTEM'),    -- ohdsi user -> 'public' role
  (DEFAULT, 1000, 3, null, 'SYSTEM'),    -- ohdsi user -> 'concept set creator' role
  (DEFAULT, 1000, 5, null, 'SYSTEM'),    -- ohdsi user -> 'cohort creator' role
  (DEFAULT, 1000, 6, null, 'SYSTEM'),    -- ohdsi user -> 'cohort reader' role
  (DEFAULT, 1000, 1000, null, 'SYSTEM'), -- ohdsi user -> 'Source user (OMOP-Bridge)' role
  (DEFAULT, 1001, 2, null, 'SYSTEM'),    -- admin user -> 'admin' role
  (DEFAULT, 1001, 1, null, 'SYSTEM')     -- admin user -> 'public' role
ON CONFLICT DO NOTHING;