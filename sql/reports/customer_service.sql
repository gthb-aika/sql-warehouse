SELECT code,orders,shipped_orders,cancelled_orders,
       ROUND(100.0*shipped_orders/NULLIF(orders-cancelled_orders,0),2) AS shipped_percent
FROM customer_fulfillment ORDER BY orders DESC,code;
