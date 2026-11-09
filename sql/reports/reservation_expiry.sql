-- Reference time for date-sensitive reports: 2026-04-01T12:00:00.000000Z.
SELECT r.id,r.order_id,w.code AS warehouse_code,r.expires_at,
       SUM(i.quantity) AS units,
       CASE WHEN r.expires_at<='2026-04-01T12:00:00.000000Z' THEN 'expiry_pending' ELSE 'active' END AS time_state
FROM reservations r JOIN warehouses w ON w.id=r.warehouse_id
JOIN reservation_items i ON i.reservation_id=r.id
WHERE r.status='active' GROUP BY r.id,r.order_id,w.code,r.expires_at
ORDER BY r.expires_at,r.id;
