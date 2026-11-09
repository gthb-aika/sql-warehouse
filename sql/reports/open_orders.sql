-- Reference time for date-sensitive reports: 2026-04-01T12:00:00.000000Z.
SELECT external_reference,stage,units,warehouse_id,expires_at,
       ROUND((julianday('2026-04-01T12:00:00.000000Z')-julianday(created_at))*24,2) AS age_hours
FROM order_progress WHERE stage NOT IN ('shipped','cancelled')
ORDER BY created_at,id;
