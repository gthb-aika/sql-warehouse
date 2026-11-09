SELECT w.code,COUNT(r.id) AS reservations,
       SUM(CASE WHEN r.status='active' THEN 1 ELSE 0 END) AS active,
       SUM(CASE WHEN r.status='expired' THEN 1 ELSE 0 END) AS expired,
       SUM(CASE WHEN r.status='cancelled' THEN 1 ELSE 0 END) AS cancelled,
       SUM(CASE WHEN r.status='shipped' THEN 1 ELSE 0 END) AS shipped
FROM warehouses w LEFT JOIN reservations r ON r.warehouse_id=w.id
GROUP BY w.id,w.code ORDER BY w.code;
