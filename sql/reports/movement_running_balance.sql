SELECT m.id,w.code AS warehouse_code,p.sku,m.created_at,m.kind,m.quantity,
       SUM(m.quantity) OVER (
         PARTITION BY m.warehouse_id,m.product_id ORDER BY m.created_at,m.id
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_quantity,m.reference
FROM stock_movements m JOIN warehouses w ON w.id=m.warehouse_id
JOIN products p ON p.id=m.product_id ORDER BY w.code,p.sku,m.created_at,m.id;
