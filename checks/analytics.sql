-- Read-only checks: every result should be PASS.
SELECT 'orders' AS check_name,CASE WHEN COUNT(*)=16 THEN 'PASS' ELSE 'FAIL' END AS result FROM orders
UNION ALL
SELECT 'order_lines' AS check_name,CASE WHEN COUNT(*)=22 THEN 'PASS' ELSE 'FAIL' END AS result FROM order_lines
UNION ALL
SELECT 'shipped_orders' AS check_name,CASE WHEN COUNT(*)=13 THEN 'PASS' ELSE 'FAIL' END AS result FROM shipments
UNION ALL
SELECT 'ordered_units' AS check_name,CASE WHEN SUM(quantity)=84 THEN 'PASS' ELSE 'FAIL' END AS result FROM order_lines
UNION ALL
SELECT 'shipped_units' AS check_name,CASE WHEN SUM(quantity)=65 THEN 'PASS' ELSE 'FAIL' END AS result FROM shipment_items
UNION ALL
SELECT 'january_shipments' AS check_name,CASE WHEN SUM(i.quantity)=19 THEN 'PASS' ELSE 'FAIL' END AS result FROM shipments s JOIN shipment_items i ON i.shipment_id=s.id WHERE substr(s.shipped_at,1,7)='2026-01'
UNION ALL
SELECT 'february_shipments' AS check_name,CASE WHEN SUM(i.quantity)=24 THEN 'PASS' ELSE 'FAIL' END AS result FROM shipments s JOIN shipment_items i ON i.shipment_id=s.id WHERE substr(s.shipped_at,1,7)='2026-02'
UNION ALL
SELECT 'march_shipments' AS check_name,CASE WHEN SUM(i.quantity)=22 THEN 'PASS' ELSE 'FAIL' END AS result FROM shipments s JOIN shipment_items i ON i.shipment_id=s.id WHERE substr(s.shipped_at,1,7)='2026-03'
UNION ALL
SELECT 'returned_units' AS check_name,CASE WHEN SUM(quantity)=5 THEN 'PASS' ELSE 'FAIL' END AS result FROM return_items
UNION ALL
SELECT 'restocked_units' AS check_name,CASE WHEN SUM(i.quantity)=4 THEN 'PASS' ELSE 'FAIL' END AS result FROM returns r JOIN return_items i ON i.return_id=r.id WHERE r.restock=1
UNION ALL
SELECT 'two_returns_one_line' AS check_name,CASE WHEN COUNT(*)=2 AND SUM(i.quantity)=2 THEN 'PASS' ELSE 'FAIL' END AS result FROM returns r JOIN return_items i ON i.return_id=r.id WHERE r.shipment_id=1 AND i.product_id=1
UNION ALL
SELECT 'north_stock' AS check_name,CASE WHEN SUM(on_hand)=506 THEN 'PASS' ELSE 'FAIL' END AS result FROM inventory_balance WHERE warehouse_id=1
UNION ALL
SELECT 'south_stock' AS check_name,CASE WHEN SUM(on_hand)=495 THEN 'PASS' ELSE 'FAIL' END AS result FROM inventory_balance WHERE warehouse_id=2
UNION ALL
SELECT 'total_stock' AS check_name,CASE WHEN SUM(on_hand)=1001 THEN 'PASS' ELSE 'FAIL' END AS result FROM inventory_balance
UNION ALL
SELECT 'held_units' AS check_name,CASE WHEN SUM(reserved)=7 THEN 'PASS' ELSE 'FAIL' END AS result FROM inventory_balance
UNION ALL
SELECT 'available_units' AS check_name,CASE WHEN SUM(available)=994 THEN 'PASS' ELSE 'FAIL' END AS result FROM inventory_balance
UNION ALL
SELECT 'standard_cost_cents' AS check_name,CASE WHEN SUM(standard_cost_cents)=1043400 THEN 'PASS' ELSE 'FAIL' END AS result FROM inventory_valuation
UNION ALL
SELECT 'warehouse_product_pairs' AS check_name,CASE WHEN COUNT(*)=18 THEN 'PASS' ELSE 'FAIL' END AS result FROM inventory_balance
UNION ALL
SELECT 'zero_stock_pairs' AS check_name,CASE WHEN COUNT(*)=8 THEN 'PASS' ELSE 'FAIL' END AS result FROM inventory_balance WHERE on_hand=0
UNION ALL
SELECT 'products_without_shipments' AS check_name,CASE WHEN COUNT(*)=2 THEN 'PASS' ELSE 'FAIL' END AS result FROM products p WHERE NOT EXISTS(SELECT 1 FROM shipment_items i WHERE i.product_id=p.id)
UNION ALL
SELECT 'customer_without_orders' AS check_name,CASE WHEN COUNT(*)=1 THEN 'PASS' ELSE 'FAIL' END AS result FROM customers c WHERE NOT EXISTS(SELECT 1 FROM orders o WHERE o.customer_id=c.id)
UNION ALL
SELECT 'outstanding_purchase_units' AS check_name,CASE WHEN SUM(remaining_quantity)=18 THEN 'PASS' ELSE 'FAIL' END AS result FROM purchase_order_progress WHERE status='open'
ORDER BY check_name;
