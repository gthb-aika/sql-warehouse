SELECT r.warehouse_code,r.sku,r.available,r.reorder_point,r.suggested_quantity,
       s.code AS supplier_code,r.unit_cost_cents,r.lead_days,
       r.suggested_quantity*r.unit_cost_cents AS estimated_cost_cents
FROM replenishment_candidates r LEFT JOIN suppliers s ON s.id=r.supplier_id
ORDER BY r.available-r.reorder_point,r.warehouse_code,r.sku,s.code;
