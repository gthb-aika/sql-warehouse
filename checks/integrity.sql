-- Every row must show violations=0 and result=PASS. Read-only.
PRAGMA foreign_keys=ON;
WITH checks AS (
SELECT 'counts' AS check_name,COUNT(*) AS violations FROM (
SELECT c.id AS count_id,l.product_id,
 l.counted_quantity-l.expected_quantity AS expected_delta,
 COALESCE(SUM(m.quantity),0) AS actual_delta
FROM inventory_counts c JOIN inventory_count_lines l ON l.count_id=c.id
LEFT JOIN stock_movements m ON m.reference='count:'||c.id||':'||l.product_id
 AND m.warehouse_id=c.warehouse_id AND m.product_id=l.product_id AND m.kind='count'
GROUP BY c.id,l.product_id,l.counted_quantity,l.expected_quantity
HAVING expected_delta!=COALESCE(SUM(m.quantity),0)
)
UNION ALL
SELECT 'order_reservations' AS check_name,COUNT(*) AS violations FROM (
WITH expected AS (
 SELECT r.id AS reservation_id,l.product_id,l.quantity
 FROM reservations r JOIN order_lines l ON l.order_id=r.order_id
), observed AS (
 SELECT reservation_id,product_id,quantity FROM reservation_items
), differences AS (
 SELECT e.reservation_id,e.product_id,e.quantity AS expected_quantity,i.quantity AS observed_quantity
 FROM expected e LEFT JOIN observed i
  ON i.reservation_id=e.reservation_id AND i.product_id=e.product_id
 WHERE i.quantity IS NULL OR i.quantity!=e.quantity
 UNION ALL
 SELECT i.reservation_id,i.product_id,NULL,i.quantity FROM observed i
 LEFT JOIN expected e ON e.reservation_id=i.reservation_id AND e.product_id=i.product_id
 WHERE e.product_id IS NULL
)
SELECT * FROM differences ORDER BY reservation_id,product_id
)
UNION ALL
SELECT 'receipt_limits' AS check_name,COUNT(*) AS violations FROM (
SELECT purchase_order_id,product_id,ordered_quantity,received_quantity
FROM purchase_order_progress WHERE received_quantity>ordered_quantity
)
UNION ALL
SELECT 'receipts' AS check_name,COUNT(*) AS violations FROM (
SELECT r.id AS receipt_id,i.product_id,i.quantity AS expected_units,
 COALESCE(SUM(m.quantity),0) AS actual_units
FROM receipts r JOIN purchase_orders po ON po.id=r.purchase_order_id
JOIN receipt_items i ON i.receipt_id=r.id
LEFT JOIN stock_movements m ON m.reference='receipt:'||r.id||':'||i.product_id
 AND m.warehouse_id=po.warehouse_id AND m.product_id=i.product_id AND m.kind='receipt'
GROUP BY r.id,i.product_id,i.quantity
HAVING i.quantity!=COALESCE(SUM(m.quantity),0)
)
UNION ALL
SELECT 'return_limits' AS check_name,COUNT(*) AS violations FROM (
SELECT shipment_id,product_id,shipped_quantity,returned_quantity
FROM shipment_return_balance WHERE returnable_quantity<0
)
UNION ALL
SELECT 'returns' AS check_name,COUNT(*) AS violations FROM (
SELECT r.id AS return_id,i.product_id,
 CASE WHEN r.restock=1 THEN i.quantity ELSE 0 END AS expected_units,
 COALESCE(SUM(m.quantity),0) AS actual_units
FROM returns r JOIN shipments s ON s.id=r.shipment_id
JOIN return_items i ON i.return_id=r.id
LEFT JOIN stock_movements m ON m.reference='return:'||r.id||':'||i.product_id
 AND m.warehouse_id=s.warehouse_id AND m.product_id=i.product_id AND m.kind='return'
GROUP BY r.id,i.product_id,r.restock,i.quantity
HAVING expected_units!=COALESCE(SUM(m.quantity),0)
)
UNION ALL
SELECT 'shipment_states' AS check_name,COUNT(*) AS violations FROM (
SELECT s.id AS shipment_id,s.order_id,r.status AS reservation_status,
 o.status AS order_status,o.fulfillment_status
FROM shipments s JOIN reservations r ON r.id=s.reservation_id
JOIN orders o ON o.id=s.order_id
WHERE r.status!='shipped' OR o.status!='confirmed' OR o.fulfillment_status!='shipped'
 OR s.order_id!=r.order_id OR s.warehouse_id!=r.warehouse_id
)
UNION ALL
SELECT 'shipments' AS check_name,COUNT(*) AS violations FROM (
SELECT s.id AS shipment_id,i.product_id,i.quantity AS expected_units,
 COALESCE(SUM(-m.quantity),0) AS actual_units
FROM shipments s JOIN shipment_items i ON i.shipment_id=s.id
LEFT JOIN stock_movements m ON m.reference='shipment:'||s.id||':'||i.product_id
 AND m.warehouse_id=s.warehouse_id AND m.product_id=i.product_id AND m.kind='shipment'
GROUP BY s.id,i.product_id,i.quantity
HAVING i.quantity!=COALESCE(SUM(-m.quantity),0)
)
UNION ALL
SELECT 'stock' AS check_name,COUNT(*) AS violations FROM (
SELECT * FROM stock_integrity ORDER BY warehouse_id,product_id
)
UNION ALL
SELECT 'transfers' AS check_name,COUNT(*) AS violations FROM (
SELECT t.id AS transfer_id,i.product_id,i.quantity,
 COALESCE((SELECT SUM(-m.quantity) FROM stock_movements m
  WHERE m.reference='transfer:'||t.id||':out:'||i.product_id
   AND m.product_id=i.product_id AND m.warehouse_id=t.source_warehouse_id
   AND m.kind='transfer_out'),0) AS outbound_units,
 COALESCE((SELECT SUM(m.quantity) FROM stock_movements m
  WHERE m.reference='transfer:'||t.id||':in:'||i.product_id
   AND m.product_id=i.product_id AND m.warehouse_id=t.destination_warehouse_id
   AND m.kind='transfer_in'),0) AS inbound_units
FROM transfers t JOIN transfer_items i ON i.transfer_id=t.id
WHERE outbound_units!=i.quantity OR inbound_units!=i.quantity
)
UNION ALL
SELECT 'sqlite_integrity',COUNT(*) FROM pragma_integrity_check WHERE integrity_check!='ok'
UNION ALL
SELECT 'foreign_keys',COUNT(*) FROM pragma_foreign_key_check
)
SELECT check_name,violations,CASE WHEN violations=0 THEN 'PASS' ELSE 'FAIL' END AS result FROM checks ORDER BY check_name;
