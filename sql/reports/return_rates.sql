WITH sold AS (
 SELECT product_id,SUM(quantity) AS shipped_units FROM shipment_items GROUP BY product_id
), returned AS (
 SELECT i.product_id,SUM(i.quantity) AS returned_units,
  SUM(CASE WHEN r.restock=1 THEN i.quantity ELSE 0 END) AS restocked_units
 FROM return_items i JOIN returns r ON r.id=i.return_id GROUP BY i.product_id
)
SELECT p.sku,s.shipped_units,COALESCE(r.returned_units,0) AS returned_units,
       COALESCE(r.restocked_units,0) AS restocked_units,
       ROUND(100.0*COALESCE(r.returned_units,0)/s.shipped_units,2) AS return_percent
FROM sold s JOIN products p ON p.id=s.product_id
LEFT JOIN returned r ON r.product_id=s.product_id ORDER BY return_percent DESC,p.sku;
