SELECT w.code,COALESCE(SUM(d.movements),0) AS movements,
       COALESCE(SUM(d.inbound_units),0) AS inbound_units,
       COALESCE(SUM(d.outbound_units),0) AS outbound_units
FROM warehouses w LEFT JOIN daily_inventory_activity d ON d.warehouse_id=w.id
GROUP BY w.id,w.code ORDER BY movements DESC,w.code;
