SELECT
  event_time,
  identity_metadata.run_by as run_by_identifier,
  identity_metadata.run_by_display_name as run_by_name,
  request_params.securable_type as securable_type,
  request_params.securable_full_name as securable_identifier,
  from_json(request_params.changes, 'ARRAY<MAP<STRING, STRING>>')[0].principal as grantee,
  from_json(from_json(request_params.changes, 'ARRAY<MAP<STRING, STRING>>')[0].add, 'ARRAY<STRING>') as granted,
  from_json(from_json(request_params.changes, 'ARRAY<MAP<STRING, STRING>>')[0].remove, 'ARRAY<STRING>') as revoked
FROM system.access.audit
WHERE action_name = 'updatePermissions'
  AND event_time >= current_date() - INTERVAL 30 DAYS
  AND response.status_code = 200
ORDER BY event_time DESC
LIMIT 200