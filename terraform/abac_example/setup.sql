CREATE OR REPLACE FUNCTION gergeljkis_serverless.default.filter_users_rls(tenant STRING)
RETURNS BOOLEAN
RETURN CASE
    WHEN tenant IS NULL THEN FALSE
    ELSE EXISTS (
        SELECT
        1
        FROM
        gergeljkis_serverless.default.group_tenant_mapping m
        WHERE
    m.tenant_name = tenant
    AND is_account_group_member(m.group_name)
)
END;