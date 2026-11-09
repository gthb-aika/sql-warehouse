-- Read-only checks: every result should be PASS.
SELECT 'product_catalog' AS check_name,CASE WHEN COUNT(*)=300 THEN 'PASS' ELSE 'FAIL' END AS result FROM products
UNION ALL
SELECT 'warehouse_catalog' AS check_name,CASE WHEN COUNT(*)=6 THEN 'PASS' ELSE 'FAIL' END AS result FROM warehouses
UNION ALL
SELECT 'inventory_grid' AS check_name,CASE WHEN COUNT(*)=1800 THEN 'PASS' ELSE 'FAIL' END AS result FROM inventory_balance
UNION ALL
SELECT 'physical_units' AS check_name,CASE WHEN SUM(on_hand)=527537 THEN 'PASS' ELSE 'FAIL' END AS result FROM inventory_balance
UNION ALL
SELECT 'standard_cost_cents' AS check_name,CASE WHEN SUM(standard_cost_cents)=1406284577 THEN 'PASS' ELSE 'FAIL' END AS result FROM inventory_valuation
UNION ALL
SELECT 'shipped_orders' AS check_name,CASE WHEN COUNT(*)=1502 THEN 'PASS' ELSE 'FAIL' END AS result FROM order_progress WHERE stage='shipped'
UNION ALL
SELECT 'shipped_units' AS check_name,CASE WHEN SUM(quantity)=17107 THEN 'PASS' ELSE 'FAIL' END AS result FROM shipment_items
UNION ALL
SELECT 'purchase_backlog' AS check_name,CASE WHEN SUM(remaining_quantity)=1500 THEN 'PASS' ELSE 'FAIL' END AS result FROM purchase_order_progress WHERE status='open'
UNION ALL
SELECT 'returns_count' AS check_name,CASE WHEN COUNT(*)=213 THEN 'PASS' ELSE 'FAIL' END AS result FROM returns
UNION ALL
SELECT 'transfer_reconciliation' AS check_name,CASE WHEN COUNT(*)=0 THEN 'PASS' ELSE 'FAIL' END AS result FROM transfer_reconciliation WHERE quantity!=inbound_units OR quantity!=outbound_units
UNION ALL
SELECT 'supplier_coverage' AS check_name,CASE WHEN COUNT(DISTINCT supplier_id)=10 THEN 'PASS' ELSE 'FAIL' END AS result FROM purchase_orders
ORDER BY check_name;
