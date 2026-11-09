WITH completion AS (
 SELECT po.id,po.supplier_id,po.status,po.due_at,MAX(r.received_at) AS completed_at
 FROM purchase_orders po LEFT JOIN receipts r ON r.purchase_order_id=po.id
 GROUP BY po.id,po.supplier_id,po.status,po.due_at
)
SELECT s.code,COUNT(c.id) AS purchase_orders,
 SUM(CASE WHEN c.status='received' THEN 1 ELSE 0 END) AS completed_orders,
 SUM(CASE WHEN c.status='received' AND c.completed_at<=c.due_at THEN 1 ELSE 0 END) AS on_time_orders,
 ROUND(AVG(CASE WHEN c.status='received'
   THEN MAX((julianday(c.completed_at)-julianday(c.due_at))*24,0) END),2) AS mean_delay_hours
FROM suppliers s LEFT JOIN completion c ON c.supplier_id=s.id
GROUP BY s.id,s.code ORDER BY s.code;
