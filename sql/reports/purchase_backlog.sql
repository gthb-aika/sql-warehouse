-- Reference time for date-sensitive reports: 2026-04-01T12:00:00.000000Z.
SELECT p.reference,s.code AS supplier_code,w.code AS warehouse_code,p.due_at,
       SUM(p.remaining_quantity) AS outstanding_units,
       SUM(p.remaining_quantity*p.unit_cost_cents) AS outstanding_cost_cents,
       CASE WHEN p.due_at<'2026-04-01T12:00:00.000000Z' THEN 1 ELSE 0 END AS overdue
FROM purchase_order_progress p
JOIN suppliers s ON s.id=p.supplier_id JOIN warehouses w ON w.id=p.warehouse_id
WHERE p.status='open' AND p.remaining_quantity>0
GROUP BY p.purchase_order_id,p.reference,s.code,w.code,p.due_at
ORDER BY p.due_at,p.purchase_order_id;
