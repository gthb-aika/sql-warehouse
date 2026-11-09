-- SQLite 3.38+. Run once in a NEW EMPTY database.
PRAGMA foreign_keys=ON;
BEGIN;

-- 001_legacy_schema.sql
CREATE TABLE warehouses(id INTEGER PRIMARY KEY, code TEXT NOT NULL UNIQUE);
CREATE TABLE products(id INTEGER PRIMARY KEY, sku TEXT NOT NULL UNIQUE, name TEXT NOT NULL);
CREATE TABLE stock_movements(
 id INTEGER PRIMARY KEY,
 warehouse_id INTEGER NOT NULL REFERENCES warehouses(id),
 product_id INTEGER NOT NULL REFERENCES products(id),
 quantity INTEGER NOT NULL CHECK(quantity != 0),
 reference TEXT NOT NULL UNIQUE,
 created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX movements_stock ON stock_movements(warehouse_id,product_id);
CREATE TABLE orders(
 id INTEGER PRIMARY KEY,
 external_reference TEXT NOT NULL UNIQUE,
 status TEXT NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','confirmed','cancelled'))
);
CREATE TABLE order_lines(
 order_id INTEGER NOT NULL REFERENCES orders(id),
 product_id INTEGER NOT NULL REFERENCES products(id),
 quantity INTEGER NOT NULL CHECK(quantity > 0),
 PRIMARY KEY(order_id,product_id)
);

-- 002_legacy_views.sql
CREATE VIEW stock_on_hand AS
SELECT w.id AS warehouse_id,p.id AS product_id,
       COALESCE(SUM(m.quantity),0) AS quantity
FROM warehouses w CROSS JOIN products p
LEFT JOIN stock_movements m ON m.warehouse_id=w.id AND m.product_id=p.id
GROUP BY w.id,p.id;
CREATE VIEW order_totals AS
SELECT o.id AS order_id,o.status,COALESCE(SUM(l.quantity),0) AS units
FROM orders o LEFT JOIN order_lines l ON l.order_id=o.id
GROUP BY o.id,o.status;

-- 003_catalog_and_parties.sql
CREATE TABLE categories (
 id INTEGER PRIMARY KEY,
 code TEXT NOT NULL UNIQUE,
 name TEXT NOT NULL
);
CREATE TABLE suppliers (
 id INTEGER PRIMARY KEY,
 code TEXT NOT NULL UNIQUE,
 name TEXT NOT NULL,
 active INTEGER NOT NULL DEFAULT 1 CHECK(active IN (0,1))
);
CREATE TABLE customers (
 id INTEGER PRIMARY KEY,
 code TEXT NOT NULL UNIQUE,
 name TEXT NOT NULL
);
ALTER TABLE products ADD COLUMN category_id INTEGER REFERENCES categories(id);
ALTER TABLE products ADD COLUMN unit_cost_cents INTEGER NOT NULL DEFAULT 100 CHECK(unit_cost_cents >= 0);
ALTER TABLE products ADD COLUMN reorder_point INTEGER NOT NULL DEFAULT 10 CHECK(reorder_point >= 0);
ALTER TABLE products ADD COLUMN active INTEGER NOT NULL DEFAULT 1 CHECK(active IN (0,1));
ALTER TABLE orders ADD COLUMN customer_id INTEGER REFERENCES customers(id);
ALTER TABLE orders ADD COLUMN created_at TEXT NOT NULL DEFAULT '2026-01-01T00:00:00.000000Z';
ALTER TABLE orders ADD COLUMN fulfillment_status TEXT NOT NULL DEFAULT 'open' CHECK(fulfillment_status IN ('open','shipped'));
ALTER TABLE orders ADD COLUMN shipped_at TEXT;
ALTER TABLE stock_movements ADD COLUMN kind TEXT NOT NULL DEFAULT 'adjustment'
 CHECK(kind IN ('opening','receipt','shipment','transfer_out','transfer_in','return','count','adjustment'));
CREATE TABLE product_suppliers (
 product_id INTEGER NOT NULL REFERENCES products(id),
 supplier_id INTEGER NOT NULL REFERENCES suppliers(id),
 unit_cost_cents INTEGER NOT NULL CHECK(unit_cost_cents >= 0),
 lead_days INTEGER NOT NULL CHECK(lead_days >= 0),
 PRIMARY KEY(product_id,supplier_id)
);
CREATE INDEX orders_customer ON orders(customer_id,created_at);

-- 004_reservations_and_shipping.sql
CREATE TABLE reservations (
 id INTEGER PRIMARY KEY,
 order_id INTEGER NOT NULL REFERENCES orders(id),
 warehouse_id INTEGER NOT NULL REFERENCES warehouses(id),
 status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','expired','cancelled','shipped')),
 created_at TEXT NOT NULL,
 expires_at TEXT NOT NULL,
 closed_at TEXT,
 CHECK(expires_at > created_at),
 CHECK((status='active' AND closed_at IS NULL) OR (status!='active' AND closed_at IS NOT NULL))
);
CREATE UNIQUE INDEX one_active_reservation ON reservations(order_id) WHERE status='active';
CREATE INDEX reservations_expiry ON reservations(expires_at) WHERE status='active';
CREATE TABLE reservation_items (
 reservation_id INTEGER NOT NULL REFERENCES reservations(id),
 product_id INTEGER NOT NULL REFERENCES products(id),
 quantity INTEGER NOT NULL CHECK(quantity > 0),
 PRIMARY KEY(reservation_id,product_id)
);
CREATE INDEX reserved_product ON reservation_items(product_id,reservation_id);
CREATE TABLE shipments (
 id INTEGER PRIMARY KEY,
 order_id INTEGER NOT NULL UNIQUE REFERENCES orders(id),
 reservation_id INTEGER NOT NULL UNIQUE REFERENCES reservations(id),
 warehouse_id INTEGER NOT NULL REFERENCES warehouses(id),
 shipped_at TEXT NOT NULL
);
CREATE TABLE shipment_items (
 shipment_id INTEGER NOT NULL REFERENCES shipments(id),
 product_id INTEGER NOT NULL REFERENCES products(id),
 quantity INTEGER NOT NULL CHECK(quantity > 0),
 PRIMARY KEY(shipment_id,product_id)
);

-- 005_purchasing.sql
CREATE TABLE purchase_orders (
 id INTEGER PRIMARY KEY,
 reference TEXT NOT NULL UNIQUE,
 supplier_id INTEGER NOT NULL REFERENCES suppliers(id),
 warehouse_id INTEGER NOT NULL REFERENCES warehouses(id),
 status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open','received','cancelled')),
 created_at TEXT NOT NULL,
 due_at TEXT NOT NULL,
 CHECK(due_at >= created_at)
);
CREATE TABLE purchase_order_lines (
 purchase_order_id INTEGER NOT NULL REFERENCES purchase_orders(id),
 product_id INTEGER NOT NULL REFERENCES products(id),
 quantity INTEGER NOT NULL CHECK(quantity > 0),
 unit_cost_cents INTEGER NOT NULL CHECK(unit_cost_cents >= 0),
 PRIMARY KEY(purchase_order_id,product_id)
);
CREATE TABLE receipts (
 id INTEGER PRIMARY KEY,
 purchase_order_id INTEGER NOT NULL REFERENCES purchase_orders(id),
 received_at TEXT NOT NULL
);
CREATE TABLE receipt_items (
 receipt_id INTEGER NOT NULL REFERENCES receipts(id),
 product_id INTEGER NOT NULL REFERENCES products(id),
 quantity INTEGER NOT NULL CHECK(quantity > 0),
 PRIMARY KEY(receipt_id,product_id)
);
CREATE INDEX receipts_purchase ON receipts(purchase_order_id);

-- 006_transfers_returns_counts.sql
CREATE TABLE transfers (
 id INTEGER PRIMARY KEY,
 source_warehouse_id INTEGER NOT NULL REFERENCES warehouses(id),
 destination_warehouse_id INTEGER NOT NULL REFERENCES warehouses(id),
 created_at TEXT NOT NULL,
 CHECK(source_warehouse_id != destination_warehouse_id)
);
CREATE TABLE transfer_items (
 transfer_id INTEGER NOT NULL REFERENCES transfers(id),
 product_id INTEGER NOT NULL REFERENCES products(id),
 quantity INTEGER NOT NULL CHECK(quantity > 0),
 PRIMARY KEY(transfer_id,product_id)
);
CREATE TABLE returns (
 id INTEGER PRIMARY KEY,
 shipment_id INTEGER NOT NULL REFERENCES shipments(id),
 restock INTEGER NOT NULL CHECK(restock IN (0,1)),
 reason TEXT NOT NULL CHECK(reason IN ('damaged','wrong_item','unwanted')),
 created_at TEXT NOT NULL
);
CREATE TABLE return_items (
 return_id INTEGER NOT NULL REFERENCES returns(id),
 product_id INTEGER NOT NULL REFERENCES products(id),
 quantity INTEGER NOT NULL CHECK(quantity > 0),
 PRIMARY KEY(return_id,product_id)
);
CREATE INDEX returns_shipment ON returns(shipment_id);
CREATE TABLE inventory_counts (
 id INTEGER PRIMARY KEY,
 warehouse_id INTEGER NOT NULL REFERENCES warehouses(id),
 counted_at TEXT NOT NULL
);
CREATE TABLE inventory_count_lines (
 count_id INTEGER NOT NULL REFERENCES inventory_counts(id),
 product_id INTEGER NOT NULL REFERENCES products(id),
 expected_quantity INTEGER NOT NULL CHECK(expected_quantity >= 0),
 counted_quantity INTEGER NOT NULL CHECK(counted_quantity >= 0),
 PRIMARY KEY(count_id,product_id)
);

-- 007_audit_and_requests.sql
CREATE TABLE audit_events (
 id INTEGER PRIMARY KEY,
 entity_type TEXT NOT NULL,
 entity_id INTEGER NOT NULL,
 event TEXT NOT NULL,
 details_json TEXT NOT NULL,
 occurred_at TEXT NOT NULL
);
CREATE INDEX audit_entity ON audit_events(entity_type,entity_id,id);

-- 008_inventory_views.sql
CREATE VIEW inventory_balance AS
WITH physical AS (
 SELECT warehouse_id,product_id,SUM(quantity) AS on_hand
 FROM stock_movements GROUP BY warehouse_id,product_id
), held AS (
 SELECT r.warehouse_id,i.product_id,SUM(i.quantity) AS reserved
 FROM reservations r JOIN reservation_items i ON i.reservation_id=r.id
 WHERE r.status='active' GROUP BY r.warehouse_id,i.product_id
)
SELECT w.id AS warehouse_id,w.code AS warehouse_code,
 p.id AS product_id,p.sku,p.name,p.unit_cost_cents,p.reorder_point,
 COALESCE(ph.on_hand,0) AS on_hand,COALESCE(h.reserved,0) AS reserved,
 COALESCE(ph.on_hand,0)-COALESCE(h.reserved,0) AS available
FROM warehouses w CROSS JOIN products p
LEFT JOIN physical ph ON ph.warehouse_id=w.id AND ph.product_id=p.id
LEFT JOIN held h ON h.warehouse_id=w.id AND h.product_id=p.id;

CREATE VIEW order_progress AS
SELECT o.id,o.external_reference,o.status,o.fulfillment_status,o.customer_id,
 o.created_at,o.shipped_at,COALESCE(l.units,0) AS units,
 CASE WHEN o.status='cancelled' THEN 'cancelled'
      WHEN o.fulfillment_status='shipped' THEN 'shipped'
      WHEN r.id IS NOT NULL THEN 'reserved'
      ELSE o.status END AS stage,
 r.id AS reservation_id,r.warehouse_id,r.expires_at
FROM orders o
LEFT JOIN (SELECT order_id,SUM(quantity) AS units FROM order_lines GROUP BY order_id) l ON l.order_id=o.id
LEFT JOIN reservations r ON r.order_id=o.id AND r.status='active';

CREATE VIEW purchase_order_progress AS
WITH received AS (
 SELECT r.purchase_order_id,i.product_id,SUM(i.quantity) AS received_quantity
 FROM receipts r JOIN receipt_items i ON i.receipt_id=r.id
 GROUP BY r.purchase_order_id,i.product_id
)
SELECT po.id AS purchase_order_id,po.reference,po.supplier_id,po.warehouse_id,
 po.status,po.due_at,l.product_id,l.quantity AS ordered_quantity,
 COALESCE(r.received_quantity,0) AS received_quantity,
 l.quantity-COALESCE(r.received_quantity,0) AS remaining_quantity,
 l.unit_cost_cents
FROM purchase_orders po JOIN purchase_order_lines l ON l.purchase_order_id=po.id
LEFT JOIN received r ON r.purchase_order_id=po.id AND r.product_id=l.product_id;

CREATE VIEW shipment_return_balance AS
WITH returned AS (
 SELECT r.shipment_id,i.product_id,SUM(i.quantity) AS returned_quantity
 FROM returns r JOIN return_items i ON i.return_id=r.id
 GROUP BY r.shipment_id,i.product_id
)
SELECT s.id AS shipment_id,s.order_id,s.warehouse_id,i.product_id,
 i.quantity AS shipped_quantity,COALESCE(r.returned_quantity,0) AS returned_quantity,
 i.quantity-COALESCE(r.returned_quantity,0) AS returnable_quantity
FROM shipments s JOIN shipment_items i ON i.shipment_id=s.id
LEFT JOIN returned r ON r.shipment_id=s.id AND r.product_id=i.product_id;

CREATE VIEW inventory_count_variance AS
SELECT c.id AS count_id,c.warehouse_id,c.counted_at,l.product_id,
 l.expected_quantity,l.counted_quantity,
 l.counted_quantity-l.expected_quantity AS variance
FROM inventory_counts c JOIN inventory_count_lines l ON l.count_id=c.id;

CREATE VIEW stock_integrity AS
SELECT warehouse_id,product_id,on_hand,reserved,available
FROM inventory_balance WHERE on_hand < 0 OR reserved < 0 OR available < 0;

-- 010_reporting_views.sql
CREATE VIEW inventory_valuation AS
SELECT warehouse_id,warehouse_code,SUM(on_hand) AS units,
 SUM(on_hand*unit_cost_cents) AS standard_cost_cents,
 SUM(reserved*unit_cost_cents) AS reserved_cost_cents
FROM inventory_balance GROUP BY warehouse_id,warehouse_code;

CREATE VIEW replenishment_candidates AS
SELECT b.warehouse_id,b.warehouse_code,b.product_id,b.sku,b.available,
 b.reorder_point,MAX(b.reorder_point*2-b.available,0) AS suggested_quantity,
 ps.supplier_id,ps.unit_cost_cents,ps.lead_days
FROM inventory_balance b JOIN products p ON p.id=b.product_id AND p.active=1
LEFT JOIN product_suppliers ps ON ps.product_id=b.product_id
 AND EXISTS(SELECT 1 FROM suppliers s WHERE s.id=ps.supplier_id AND s.active=1)
WHERE b.available < b.reorder_point;

CREATE VIEW daily_inventory_activity AS
SELECT SUBSTR(created_at,1,10) AS movement_date,warehouse_id,kind,
 COUNT(*) AS movements,SUM(CASE WHEN quantity>0 THEN quantity ELSE 0 END) AS inbound_units,
 SUM(CASE WHEN quantity<0 THEN -quantity ELSE 0 END) AS outbound_units
FROM stock_movements GROUP BY SUBSTR(created_at,1,10),warehouse_id,kind;

CREATE VIEW customer_fulfillment AS
SELECT c.id AS customer_id,c.code,COUNT(o.id) AS orders,
 SUM(CASE WHEN o.fulfillment_status='shipped' THEN 1 ELSE 0 END) AS shipped_orders,
 SUM(CASE WHEN o.status='cancelled' THEN 1 ELSE 0 END) AS cancelled_orders
FROM customers c LEFT JOIN orders o ON o.customer_id=c.id GROUP BY c.id,c.code;

CREATE VIEW transfer_reconciliation AS
SELECT t.id AS transfer_id,i.product_id,i.quantity,
 COALESCE((SELECT SUM(-m.quantity) FROM stock_movements m
  WHERE m.reference='transfer:'||t.id||':out:'||i.product_id),0) AS outbound_units,
 COALESCE((SELECT SUM(m.quantity) FROM stock_movements m
  WHERE m.reference='transfer:'||t.id||':in:'||i.product_id),0) AS inbound_units
FROM transfers t JOIN transfer_items i ON i.transfer_id=t.id;
COMMIT;
