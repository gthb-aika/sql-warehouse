SELECT transfer_id,product_id,quantity,outbound_units,inbound_units
FROM transfer_reconciliation
WHERE outbound_units!=quantity OR inbound_units!=quantity
ORDER BY transfer_id,product_id;
