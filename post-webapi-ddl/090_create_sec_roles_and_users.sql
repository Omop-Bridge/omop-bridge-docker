-- Ensure the webapi schema exists
CREATE SCHEMA IF NOT EXISTS webapi;

-- ==========================================
-- TABLE DEFINITIONS & UNIQUE CONSTRAINTS
-- ==========================================

CREATE TABLE IF NOT EXISTS webapi.sec_permission (
                                                     id SERIAL PRIMARY KEY,
                                                     value VARCHAR(500) NOT NULL,
    description TEXT,
    CONSTRAINT sec_permission_value_key UNIQUE (value)
    );

CREATE TABLE IF NOT EXISTS webapi.sec_role (
                                               id SERIAL PRIMARY KEY,
                                               name VARCHAR(255) NOT NULL,
    CONSTRAINT sec_role_name_key UNIQUE (name)
    );

CREATE TABLE IF NOT EXISTS webapi.sec_role_permission (
                                                          id SERIAL PRIMARY KEY,
                                                          role_id INT NOT NULL,
                                                          permission_id INT NOT NULL,
                                                          status VARCHAR(50),
    CONSTRAINT sec_role_permission_role_id_permission_id_key UNIQUE (role_id, permission_id)
    );

CREATE TABLE IF NOT EXISTS webapi.sec_user (
                                               id SERIAL PRIMARY KEY,
                                               login VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    CONSTRAINT sec_user_login_key UNIQUE (login)
    );

CREATE TABLE IF NOT EXISTS webapi.sec_user_role (
                                                    id SERIAL PRIMARY KEY,
                                                    user_id INT NOT NULL,
                                                    role_id INT NOT NULL,
                                                    status VARCHAR(50),
    origin VARCHAR(50),
    CONSTRAINT sec_user_role_user_id_role_id_key UNIQUE (user_id, role_id)
    );

-- ==========================================
-- DATA INITIALIZATION & SEEDING SCRIPTS
-- ==========================================

-- 1. Insert permissions dynamically (omit id to let PostgreSQL handle auto-increment)
INSERT INTO webapi.sec_permission (value, description)
VALUES
    ('cohortdefinition:*:generate:OMOP-Bridge:get', 'Generate Cohort on Source with SourceKey = OMOP-Bridge'),
    ('cohortdefinition:*:report:OMOP-Bridge:get', 'Get Inclusion Rule Report for Source with SourceKey = OMOP-Bridge')
    ON CONFLICT (value) DO NOTHING;

-- 2. Insert roles dynamically
INSERT INTO webapi.sec_role (name)
VALUES
    ('Source user (OMOP-Bridge)'),
    ('ohdsi')
    ON CONFLICT (name) DO NOTHING;

-- 3. Link permissions to 'Source user (OMOP-Bridge)' role
INSERT INTO webapi.sec_role_permission (role_id, permission_id, status)
SELECT
    r.id,
    p.id,
    NULL
FROM webapi.sec_role r
         CROSS JOIN webapi.sec_permission p
WHERE r.name = 'Source user (OMOP-Bridge)'
  AND p.value IN (
                  'cohortdefinition:*:generate:OMOP-Bridge:get',
                  'cohortdefinition:*:report:OMOP-Bridge:get'
    )
    ON CONFLICT (role_id, permission_id) DO NOTHING;

-- 4. Create users 'ohdsi' and 'admin'
INSERT INTO webapi.sec_user (login, name)
VALUES
    ('ohdsi', 'ohdsi'),
    ('admin', 'admin')
    ON CONFLICT (login) DO NOTHING;

-- 5. Dynamically assign roles by Role Name and User Login
INSERT INTO webapi.sec_user_role (user_id, role_id, status, origin)
SELECT
    u.id,
    r.id,
    NULL,
    'SYSTEM'
FROM webapi.sec_user u
         JOIN webapi.sec_role r ON r.name IN (
                                              'ohdsi',
                                              'public',
                                              'concept set creator',
                                              'cohort creator',
                                              'cohort reader',
                                              'Source user (OMOP-Bridge)'
    )
WHERE u.login = 'ohdsi'

UNION ALL

SELECT
    u.id,
    r.id,
    NULL,
    'SYSTEM'
FROM webapi.sec_user u
         JOIN webapi.sec_role r ON r.name IN (
                                              'admin',
                                              'public'
    )
WHERE u.login = 'admin'
    ON CONFLICT (user_id, role_id) DO NOTHING;