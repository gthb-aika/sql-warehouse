-- Load ONE of the 02 data files, never both.
PRAGMA foreign_keys=ON;
BEGIN;
-- Small, fully fictional analyst dataset: January-March 2026.
-- Same schema and business invariants as the large workload fixture.
-- Run after 01_schema.sql and before 03_guards.sql.

INSERT INTO warehouses(id,code) VALUES(1,'NORTH'),(2,'SOUTH'),(3,'EMPTY');
INSERT INTO categories VALUES(1,'OFFICE','Office supplies'),(2,'ACCESSORIES','Accessories');
INSERT INTO suppliers(id,code,name) VALUES
 (1,'SUP-A','Synthetic supplier A'),(2,'SUP-B','Synthetic supplier B');
INSERT INTO customers(id,code,name) VALUES
 (1,'CLIENT-A','Synthetic client A'),(2,'CLIENT-B','Synthetic client B'),
 (3,'CLIENT-C','Synthetic client C'),(4,'CLIENT-NONE','Synthetic client without orders');
INSERT INTO products(id,sku,name,category_id,unit_cost_cents,reorder_point) VALUES
 (1,'NOTEBOOK','Notebook',1,1000,10),
 (2,'PEN','Pen',1,200,20),
 (3,'FOLDER','Folder',1,500,5),
 (4,'BAG','Bag',2,2000,5),
 (5,'NEW-ITEM','Product without sales',2,1500,5),
 (6,'ZERO-STOCK','Product without stock',1,100,1);
INSERT INTO product_suppliers VALUES
 (1,1,900,3),(2,1,180,2),(3,1,450,4),(4,2,1800,7),(5,2,1300,6),(6,1,90,2);

-- 100 units of products 1-5 in each of the first two warehouses: 1,000 units.
INSERT INTO stock_movements(warehouse_id,product_id,quantity,reference,kind,created_at)
SELECT w.id,p.id,100,'opening:'||w.id||':'||p.id,'opening','2026-01-01T00:00:00.000000Z'
FROM warehouses w CROSS JOIN products p WHERE w.id IN (1,2) AND p.id<=5;

INSERT INTO orders(id,external_reference,status,customer_id,created_at,fulfillment_status) VALUES
 (1,'AN-001','confirmed',1,'2026-01-03T08:00:00.000000Z','shipped'),
 (2,'AN-002','confirmed',2,'2026-01-03T08:00:00.000000Z','shipped'),
 (3,'AN-003','confirmed',1,'2026-01-10T08:00:00.000000Z','shipped'),
 (4,'AN-004','cancelled',3,'2026-01-15T08:00:00.000000Z','open'),
 (5,'AN-005','confirmed',2,'2026-01-31T08:00:00.000000Z','shipped'),
 (6,'AN-006','confirmed',1,'2026-02-01T08:00:00.000000Z','shipped'),
 (7,'AN-007','confirmed',2,'2026-02-05T08:00:00.000000Z','shipped'),
 (8,'AN-008','confirmed',3,'2026-02-05T08:00:00.000000Z','shipped'),
 (9,'AN-009','confirmed',1,'2026-02-14T08:00:00.000000Z','shipped'),
 (10,'AN-010','confirmed',2,'2026-02-28T08:00:00.000000Z','shipped'),
 (11,'AN-011','confirmed',1,'2026-03-01T08:00:00.000000Z','shipped'),
 (12,'AN-012','confirmed',3,'2026-03-07T08:00:00.000000Z','shipped'),
 (13,'AN-013','confirmed',2,'2026-03-15T08:00:00.000000Z','shipped'),
 (14,'AN-014','confirmed',1,'2026-03-20T08:00:00.000000Z','open'),
 (15,'AN-015','draft',3,'2026-03-21T08:00:00.000000Z','open'),
 (16,'AN-016','confirmed',3,'2026-03-31T08:00:00.000000Z','shipped');
INSERT INTO order_lines VALUES
 (1,1,2),(1,2,5),(2,1,2),(3,3,4),(4,1,9),(5,4,1),(5,2,5),
 (6,1,3),(7,2,10),(8,4,1),(9,3,2),(9,2,5),(10,1,3),
 (11,1,4),(12,4,2),(12,3,2),(13,2,10),(14,1,5),(14,2,2),
 (15,3,3),(16,1,1),(16,2,3);

-- Shipped orders use IDs as shipment/reservation IDs for easy tracing.
UPDATE orders SET shipped_at=substr(created_at,1,10)||'T12:00:00.000000Z'
WHERE fulfillment_status='shipped';
INSERT INTO reservations(id,order_id,warehouse_id,status,created_at,expires_at,closed_at)
SELECT id,id,CASE WHEN id IN (3,7,8,10,12,16) THEN 2 ELSE 1 END,'shipped',
 substr(created_at,1,10)||'T09:00:00.000000Z',
 date(created_at,'+1 day')||'T09:00:00.000000Z',shipped_at
FROM orders WHERE fulfillment_status='shipped';
INSERT INTO reservations VALUES
 (14,14,1,'active','2026-03-20T09:00:00.000000Z','2026-04-02T09:00:00.000000Z',NULL);
INSERT INTO reservation_items
SELECT r.id,l.product_id,l.quantity FROM reservations r JOIN order_lines l ON l.order_id=r.order_id;
INSERT INTO shipments(id,order_id,reservation_id,warehouse_id,shipped_at)
SELECT r.id,r.order_id,r.id,r.warehouse_id,r.closed_at FROM reservations r WHERE r.status='shipped';
INSERT INTO shipment_items
SELECT s.id,l.product_id,l.quantity FROM shipments s JOIN order_lines l ON l.order_id=s.order_id;
INSERT INTO stock_movements(warehouse_id,product_id,quantity,reference,kind,created_at)
SELECT s.warehouse_id,i.product_id,-i.quantity,'shipment:'||s.id||':'||i.product_id,'shipment',s.shipped_at
FROM shipments s JOIN shipment_items i ON i.shipment_id=s.id;

INSERT INTO purchase_orders(id,reference,supplier_id,warehouse_id,status,created_at,due_at) VALUES
 (1,'AN-PO-001',1,1,'received','2026-01-05T08:00:00.000000Z','2026-01-10T08:00:00.000000Z'),
 (2,'AN-PO-002',2,2,'open','2026-02-10T08:00:00.000000Z','2026-02-20T08:00:00.000000Z'),
 (3,'AN-PO-003',1,1,'open','2026-03-25T08:00:00.000000Z','2026-04-05T08:00:00.000000Z');
INSERT INTO purchase_order_lines VALUES(1,1,20,900),(1,2,40,180),(2,4,10,1800),(3,3,12,450);
INSERT INTO receipts VALUES
 (1,1,'2026-01-08T10:00:00.000000Z'),(2,1,'2026-01-09T10:00:00.000000Z'),
 (3,2,'2026-02-15T10:00:00.000000Z');
INSERT INTO receipt_items VALUES(1,1,20),(1,2,20),(2,2,20),(3,4,4);
INSERT INTO stock_movements(warehouse_id,product_id,quantity,reference,kind,created_at)
SELECT p.warehouse_id,i.product_id,i.quantity,'receipt:'||r.id||':'||i.product_id,'receipt',r.received_at
FROM receipts r JOIN receipt_items i ON i.receipt_id=r.id JOIN purchase_orders p ON p.id=r.purchase_order_id;

INSERT INTO transfers VALUES(1,1,2,'2026-01-20T10:00:00.000000Z');
INSERT INTO transfer_items VALUES(1,3,5),(1,2,10);
INSERT INTO stock_movements(warehouse_id,product_id,quantity,reference,kind,created_at)
SELECT 1,product_id,-quantity,'transfer:1:out:'||product_id,'transfer_out','2026-01-20T10:00:00.000000Z' FROM transfer_items;
INSERT INTO stock_movements(warehouse_id,product_id,quantity,reference,kind,created_at)
SELECT 2,product_id,quantity,'transfer:1:in:'||product_id,'transfer_in','2026-01-20T10:00:00.000000Z' FROM transfer_items;

-- Two separate returns belong to the same notebook line of shipment 1.
-- The bag return is accepted but not restocked.
INSERT INTO returns VALUES
 (1,7,1,'unwanted','2026-02-10T10:00:00.000000Z'),
 (2,12,0,'damaged','2026-03-10T10:00:00.000000Z'),
 (3,1,1,'unwanted','2026-01-08T10:00:00.000000Z'),
 (4,1,1,'unwanted','2026-01-09T10:00:00.000000Z');
INSERT INTO return_items VALUES(1,2,2),(2,4,1),(3,1,1),(4,1,1);
INSERT INTO stock_movements(warehouse_id,product_id,quantity,reference,kind,created_at)
SELECT s.warehouse_id,i.product_id,i.quantity,'return:'||r.id||':'||i.product_id,'return',r.created_at
FROM returns r JOIN return_items i ON i.return_id=r.id JOIN shipments s ON s.id=r.shipment_id WHERE r.restock=1;

INSERT INTO inventory_counts VALUES(1,1,'2026-03-22T10:00:00.000000Z');
INSERT INTO inventory_count_lines VALUES(1,2,105,103);
INSERT INTO stock_movements(warehouse_id,product_id,quantity,reference,kind,created_at)
VALUES(1,2,-2,'count:1:2','count','2026-03-22T10:00:00.000000Z');

INSERT INTO audit_events(entity_type,entity_id,event,details_json,occurred_at)
SELECT 'order',id,'created',json_object('units',(SELECT SUM(quantity) FROM order_lines WHERE order_id=orders.id)),created_at FROM orders;
INSERT INTO audit_events(entity_type,entity_id,event,details_json,occurred_at)
SELECT 'reservation',id,'created',json_object('order_id',order_id,'warehouse_id',warehouse_id,'expires_at',expires_at),created_at FROM reservations;
INSERT INTO audit_events(entity_type,entity_id,event,details_json,occurred_at)
SELECT 'shipment',id,'shipped',json_object('order_id',order_id),shipped_at FROM shipments;
INSERT INTO audit_events(entity_type,entity_id,event,details_json,occurred_at)
SELECT 'reservation',id,'shipped',json_object('shipment_id',id),closed_at FROM reservations WHERE status='shipped';
INSERT INTO audit_events(entity_type,entity_id,event,details_json,occurred_at)
SELECT 'purchase',id,'created',json_object('supplier_id',supplier_id),created_at FROM purchase_orders;
INSERT INTO audit_events(entity_type,entity_id,event,details_json,occurred_at)
SELECT 'purchase',purchase_order_id,'received',json_object('receipt_id',id),received_at FROM receipts;
INSERT INTO audit_events(entity_type,entity_id,event,details_json,occurred_at)
SELECT 'return',id,'accepted',json_object('shipment_id',shipment_id,'restock',json(CASE WHEN restock=1 THEN 'true' ELSE 'false' END)),created_at FROM returns;
INSERT INTO audit_events(entity_type,entity_id,event,details_json,occurred_at) VALUES
 ('transfer',1,'completed','{"source":1,"destination":2}','2026-01-20T10:00:00.000000Z'),
 ('count',1,'posted','{"warehouse_id":1}','2026-03-22T10:00:00.000000Z'),
 ('order',4,'cancelled','{}','2026-01-15T10:00:00.000000Z');
COMMIT;
