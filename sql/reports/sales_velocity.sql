-- Reference time for date-sensitive reports: 2026-04-01T12:00:00.000000Z.
SELECT p.sku,COALESCE(SUM(i.quantity),0) AS shipped_last_30_days,
       ROUND(COALESCE(SUM(i.quantity),0)/30.0,2) AS units_per_day
FROM products p
LEFT JOIN (shipment_items i JOIN shipments s ON s.id=i.shipment_id)
 ON i.product_id=p.id AND julianday(s.shipped_at)>julianday('2026-04-01T12:00:00.000000Z')-30
 AND s.shipped_at<='2026-04-01T12:00:00.000000Z'
GROUP BY p.id,p.sku ORDER BY shipped_last_30_days DESC,p.sku;
