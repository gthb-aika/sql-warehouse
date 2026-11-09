SELECT warehouse_code,sku,on_hand,reserved,available,reorder_point,
       CASE WHEN available=0 THEN 'out_of_stock'
            WHEN available<reorder_point THEN 'reorder' ELSE 'healthy' END AS stock_status
FROM inventory_balance ORDER BY warehouse_code,sku;
