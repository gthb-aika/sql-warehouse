SELECT c.count_id,w.code AS warehouse_code,p.sku,c.counted_at,
       c.expected_quantity,c.counted_quantity,c.variance,
       c.variance*p.unit_cost_cents AS variance_cost_cents
FROM inventory_count_variance c JOIN warehouses w ON w.id=c.warehouse_id
JOIN products p ON p.id=c.product_id WHERE c.variance!=0
ORDER BY ABS(c.variance*p.unit_cost_cents) DESC,c.count_id,p.sku;
