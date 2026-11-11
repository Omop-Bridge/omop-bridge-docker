DO $$
DECLARE
    admin_role_id INTEGER;
    admin_user_id INTEGER;
BEGIN
    -- 1. Insert or get admin user (matching the table columns: login, name, origin)
    SELECT id INTO admin_user_id FROM webapi.sec_user WHERE login = 'admin';
    IF admin_user_id IS NULL THEN
        INSERT INTO webapi.sec_user (login, name, origin)
        VALUES ('admin', 'Administrator', 'SYSTEM')
        RETURNING id INTO admin_user_id;
    END IF;

    -- 2. Ensure the 'admin' role exists
    SELECT id INTO admin_role_id FROM webapi.sec_role WHERE name = 'admin';
    IF admin_role_id IS NULL THEN
        INSERT INTO webapi.sec_role (name) VALUES ('admin') RETURNING id INTO admin_role_id;
    END IF;

    -- 3. Link all existing permissions (IDs 1000 through 1036) to the admin role
    INSERT INTO webapi.sec_role_permission (role_id, permission_id)
    SELECT admin_role_id, p.id
    FROM webapi.sec_permission p
    WHERE p.id BETWEEN 1000 AND 1036
    ON CONFLICT DO NOTHING;

    -- 4. Assign the admin user to the admin role
    INSERT INTO webapi.sec_user_role (user_id, role_id)
    VALUES (admin_user_id, admin_role_id)
    ON CONFLICT DO NOTHING;

    RAISE NOTICE 'Successfully mapped existing permissions (1000-1036) to admin role and user.';
END $$;