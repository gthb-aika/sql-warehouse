-- Reference time for date-sensitive reports: 2026-04-01T12:00:00.000000Z.
WITH recent_sale AS (
 SELECT s.warehouse_id,i.product_id,MAX(s.shipped_at) AS last_shipped_at
 FROM shipments s JOIN shipment_items i ON i.shipment_id=s.id
 WHERE s.shipped_at<='2026-04-01T12:00:00.000000Z' GROUP BY s.warehouse_id,i.product_id
)
SELECT b.warehouse_code,b.sku,b.on_hand,r.last_shipped_at,
       ROUND(julianday('2026-04-01T12:00:00.000000Z')-julianday(r.last_shipped_at),1) AS days_since_last_shipment
FROM inventory_balance b
LEFT JOIN recent_sale r ON r.warehouse_id=b.warehouse_id AND r.product_id=b.product_id
WHERE b.on_hand>0 AND (r.last_shipped_at IS NULL OR julianday(r.last_shipped_at)<julianday('2026-04-01T12:00:00.000000Z')-30)
ORDER BY b.warehouse_code,b.sku;
