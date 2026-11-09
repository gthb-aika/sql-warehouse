-- Standard cost valuation, not FIFO/weighted-average accounting.
SELECT warehouse_code,units,standard_cost_cents,reserved_cost_cents,
       standard_cost_cents-reserved_cost_cents AS available_cost_cents
FROM inventory_valuation ORDER BY warehouse_code;
