-- VARIABLES
DECLARE OR REPLACE VARIABLE catalog_name STRING DEFAULT 'gergeljkis_serverless';
DECLARE OR REPLACE VARIABLE schema_name STRING DEFAULT 'default';

-- SET CONTEXT
USE CATALOG IDENTIFIER(catalog_name);
CREATE SCHEMA IF NOT EXISTS IDENTIFIER(schema_name);
USE SCHEMA IDENTIFIER(schema_name);

-- CREATE DEMO USERS TABLE
CREATE TABLE IF NOT EXISTS users_demo (
  id INT,
  user_name STRING,
  email STRING,
  age INT,
  tenant_name STRING
) COMMENT 'this table is part of the ABAC demo';

INSERT INTO users_demo VALUES
        (1, 'Alice', 'alice@company.com', 42, 'tenantA'),
        (2, 'Bob', 'bob@company.com', 35, 'tenantB'),
        (3, 'Charlie', 'charlie@company.com', 27, 'tenantA'),
        (4, 'Diana', 'diana@company.com', 58, 'tenantC'),
        (5, 'Edward', 'edward@company.com', 19, 'tenantB'),
        (6, 'Fiona', 'fiona@company.com', 63, 'tenantA'),
        (7, 'George', 'george@company.com', 22, 'tenantC'),
        (8, 'Hannah', 'hannah@company.com', 47, 'tenantB'),
        (9, 'Ian', 'ian@company.com', 31, 'tenantA'),
        (10, 'Julia', 'julia@company.com', 54, 'tenantC');

-- CREATE MAPPING TABLE
CREATE TABLE IF NOT EXISTS group_tenant_mapping (
  group_name STRING,
  tenant_name STRING
) COMMENT 'this table is part of the ABAC demo';

INSERT INTO group_tenant_mapping VALUES
        ('abac_demo_group_1', 'tenantB');

-- CREATE RLS FUNCTION
CREATE OR REPLACE FUNCTION filter_users_rls(tenant STRING)
RETURNS BOOLEAN
RETURN CASE
    WHEN tenant IS NULL THEN FALSE
    ELSE EXISTS (
        SELECT
        1
        FROM
        group_tenant_mapping m
        WHERE
    m.tenant_name = tenant
    AND is_account_group_member(m.group_name)
)
END;

-- CREATE EMAIL MASKING FUNCTION
CREATE OR REPLACE FUNCTION filter_email(email STRING)
RETURNS STRING
DETERMINISTIC
RETURN '***@***';

-- CREATE AGE MASKING FUNCTION
CREATE OR REPLACE FUNCTION filter_age(age INT)
RETURNS INT
DETERMINISTIC
RETURN 0;
