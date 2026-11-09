-- Run after data loading.
PRAGMA foreign_keys=ON;
BEGIN;
CREATE TRIGGER stock_movement_immutable_update
BEFORE UPDATE ON stock_movements BEGIN
 SELECT RAISE(ABORT,'stock movements are append-only');
END;
CREATE TRIGGER stock_movement_immutable_delete
BEFORE DELETE ON stock_movements BEGIN
 SELECT RAISE(ABORT,'stock movements are append-only');
END;
CREATE TRIGGER protect_available_stock
BEFORE INSERT ON stock_movements WHEN NEW.quantity < 0 BEGIN
 SELECT CASE WHEN COALESCE((
  SELECT SUM(quantity) FROM stock_movements
  WHERE warehouse_id=NEW.warehouse_id AND product_id=NEW.product_id
 ),0)+NEW.quantity < COALESCE((
  SELECT SUM(i.quantity) FROM reservation_items i
  JOIN reservations r ON r.id=i.reservation_id
  WHERE r.warehouse_id=NEW.warehouse_id AND i.product_id=NEW.product_id AND r.status='active'
 ),0) THEN RAISE(ABORT,'insufficient unreserved stock') END;
END;
CREATE TRIGGER protect_reservation_stock
BEFORE INSERT ON reservation_items BEGIN
 SELECT CASE WHEN NOT EXISTS(
  SELECT 1 FROM reservations r JOIN inventory_balance b ON b.warehouse_id=r.warehouse_id
  WHERE r.id=NEW.reservation_id AND r.status='active'
    AND b.product_id=NEW.product_id AND b.available>=NEW.quantity
 ) THEN RAISE(ABORT,'insufficient unreserved stock') END;
END;
CREATE TRIGGER reservation_item_immutable_update
BEFORE UPDATE ON reservation_items BEGIN
 SELECT RAISE(ABORT,'reservation items are immutable');
END;
CREATE TRIGGER reservation_item_immutable_delete
BEFORE DELETE ON reservation_items BEGIN
 SELECT RAISE(ABORT,'reservation items are immutable');
END;
CREATE TRIGGER confirmed_order_line_insert
BEFORE INSERT ON order_lines WHEN (SELECT status FROM orders WHERE id=NEW.order_id)!='draft' BEGIN
 SELECT RAISE(ABORT,'confirmed order lines are immutable');
END;
CREATE TRIGGER confirmed_order_line_update
BEFORE UPDATE ON order_lines WHEN
 (SELECT status FROM orders WHERE id=OLD.order_id)!='draft' OR
 (SELECT status FROM orders WHERE id=NEW.order_id)!='draft' BEGIN
 SELECT RAISE(ABORT,'confirmed order lines are immutable');
END;
CREATE TRIGGER confirmed_order_line_delete
BEFORE DELETE ON order_lines WHEN (SELECT status FROM orders WHERE id=OLD.order_id)!='draft' BEGIN
 SELECT RAISE(ABORT,'confirmed order lines are immutable');
END;
CREATE TRIGGER audit_immutable_update BEFORE UPDATE ON audit_events BEGIN
 SELECT RAISE(ABORT,'audit is append-only');
END;
CREATE TRIGGER audit_immutable_delete BEFORE DELETE ON audit_events BEGIN
 SELECT RAISE(ABORT,'audit is append-only');
END;
COMMIT;
