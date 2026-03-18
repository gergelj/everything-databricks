CREATE OR REFRESH STREAMING TABLE users_scd2;

CREATE FLOW users_scd2_flow AS AUTO CDC INTO users_scd2
FROM STREAM(users_cdf)
KEYS (id)
APPLY AS DELETE WHEN _change_type = 'delete'
SEQUENCE BY _commit_timestamp
COLUMNS * EXCEPT (_change_type, _commit_version, _commit_timestamp)
STORED AS SCD TYPE 2;
