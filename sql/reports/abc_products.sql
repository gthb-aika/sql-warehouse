-- Rank by shipped standard-cost value, with explicit tie breaking.
WITH value AS (
 SELECT p.id,p.sku,COALESCE(SUM(i.quantity),0) AS units,
        COALESCE(SUM(i.quantity),0)*p.unit_cost_cents AS shipped_cost_cents
 FROM products p LEFT JOIN shipment_items i ON i.product_id=p.id GROUP BY p.id,p.sku,p.unit_cost_cents
), cumulative AS (
 SELECT *,SUM(shipped_cost_cents) OVER () AS total_value,
  SUM(shipped_cost_cents) OVER (ORDER BY shipped_cost_cents DESC,sku
   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_value
 FROM value
)
SELECT sku,units,shipped_cost_cents,
 CASE WHEN total_value=0 THEN 'C'
      WHEN 1.0*(cumulative_value-shipped_cost_cents)/total_value<0.8 THEN 'A'
      WHEN 1.0*(cumulative_value-shipped_cost_cents)/total_value<0.95 THEN 'B'
      ELSE 'C' END AS abc_class
FROM cumulative ORDER BY shipped_cost_cents DESC,sku;
