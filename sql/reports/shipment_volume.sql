SELECT SUBSTR(s.shipped_at,1,10) AS ship_date,w.code AS warehouse_code,
       COUNT(DISTINCT s.id) AS shipments,COUNT(*) AS order_lines,SUM(i.quantity) AS units
FROM shipments s JOIN shipment_items i ON i.shipment_id=s.id
JOIN warehouses w ON w.id=s.warehouse_id
GROUP BY SUBSTR(s.shipped_at,1,10),w.code ORDER BY ship_date,w.code;
