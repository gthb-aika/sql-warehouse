WITH elapsed AS (
 SELECT s.warehouse_id,o.id,
  (julianday(s.shipped_at)-julianday(o.created_at))*24 AS hours_to_ship
 FROM orders o JOIN shipments s ON s.order_id=o.id
)
SELECT w.code,COUNT(e.id) AS shipments,ROUND(AVG(e.hours_to_ship),4) AS mean_hours,
       ROUND(MAX(e.hours_to_ship),4) AS maximum_hours,
       SUM(CASE WHEN e.hours_to_ship<=24 THEN 1 ELSE 0 END) AS shipped_within_24h
FROM warehouses w LEFT JOIN elapsed e ON e.warehouse_id=w.id
GROUP BY w.id,w.code ORDER BY w.code;
