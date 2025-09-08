CREATE SCHEMA IF NOT EXISTS erp;
SET search_path TO erp, public;

CREATE TABLE customers (
  customer_id   SERIAL PRIMARY KEY,
  name          TEXT NOT NULL,
  email         TEXT UNIQUE,
  created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE products (
  product_id    SERIAL PRIMARY KEY,
  sku           TEXT UNIQUE NOT NULL,
  name          TEXT NOT NULL,
  price_cents   INTEGER NOT NULL CHECK (price_cents >= 0),
  created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE orders (
  order_id      SERIAL PRIMARY KEY,
  customer_id   INTEGER NOT NULL REFERENCES customers(customer_id),
  order_date    DATE NOT NULL DEFAULT CURRENT_DATE,
  status        TEXT NOT NULL CHECK (status IN ('NEW','PAID','SHIPPED','CANCELLED')),
  created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE order_items (
  order_item_id SERIAL PRIMARY KEY,
  order_id      INTEGER NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
  product_id    INTEGER NOT NULL REFERENCES products(product_id),
  quantity      INTEGER NOT NULL CHECK (quantity > 0),
  unit_price_cents INTEGER NOT NULL CHECK (unit_price_cents >= 0),
  created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

INSERT INTO customers (name, email) VALUES
  ('Alice', 'alice@example.com'),
  ('Bob',   'bob@example.com');

INSERT INTO products (sku, name, price_cents) VALUES
  ('SKU-001', 'Teclado Mecânico', 19900),
  ('SKU-002', 'Mouse Óptico',     9900),
  ('SKU-003', 'Monitor 24"',      89900);

INSERT INTO orders (customer_id, order_date, status) VALUES
  (1, CURRENT_DATE, 'PAID'),
  (2, CURRENT_DATE, 'NEW');

INSERT INTO order_items (order_id, product_id, quantity, unit_price_cents) VALUES
  (1, 1, 1, 19900),
  (1, 2, 2,  9900),
  (2, 3, 1, 89900);