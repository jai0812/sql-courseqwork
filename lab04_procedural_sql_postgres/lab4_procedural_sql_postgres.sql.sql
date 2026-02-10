/* ============================================================================
Lab 4 (PostgreSQL) — Procedural SQL + Triggers + Normalization (Portfolio Version)
Author: Jai Sharma
Purpose: Showcase my learning curve with PL/pgSQL procedures, variables, and triggers.

How to run (pgAdmin or psql):
  1) Open this file and run top-to-bottom.
  2) It drops/recreates everything so it is repeatable.
============================================================================ */

/* ---------------------------
0) Clean start (repeatable)
---------------------------- */

DROP TRIGGER IF EXISTS trg_check_menu_code ON ice_cream_treat;
DROP TRIGGER IF EXISTS trg_check_sale_total ON ice_cream_sale;
DROP TRIGGER IF EXISTS trg_treat_name_history ON ice_cream_treat;

DROP FUNCTION IF EXISTS check_menu_code();
DROP FUNCTION IF EXISTS check_sale_total();
DROP FUNCTION IF EXISTS log_treat_name_change();

DROP PROCEDURE IF EXISTS add_classic_vanilla();
DROP PROCEDURE IF EXISTS add_treat(VARCHAR, INT, INT, INT, NUMERIC, VARCHAR);
DROP PROCEDURE IF EXISTS add_treat_deriving(VARCHAR, INT, INT, INT, NUMERIC);
DROP PROCEDURE IF EXISTS add_sale(VARCHAR, INT);

DROP TABLE IF EXISTS treat_history;
DROP TABLE IF EXISTS ice_cream_sale;
DROP TABLE IF EXISTS ice_cream_treat;
DROP TABLE IF EXISTS ice_cream_serving_type;
DROP TABLE IF EXISTS ice_cream_container;
DROP TABLE IF EXISTS ice_cream_flavor;
DROP TABLE IF EXISTS decision;
DROP TABLE IF EXISTS attorney;
DROP TABLE IF EXISTS person;
DROP TABLE IF EXISTS court_appearance;
DROP TABLE IF EXISTS court_case;
DROP TABLE IF EXISTS appearance_attorney;
DROP TABLE IF EXISTS appearance_decision;

DROP SEQUENCE IF EXISTS flavor_seq;
DROP SEQUENCE IF EXISTS container_seq;
DROP SEQUENCE IF EXISTS serving_type_seq;
DROP SEQUENCE IF EXISTS treat_seq;
DROP SEQUENCE IF EXISTS sale_seq;
DROP SEQUENCE IF EXISTS history_seq;

/* ---------------------------
1) Sequences (IDs)
---------------------------- */

CREATE SEQUENCE flavor_seq;
CREATE SEQUENCE container_seq;
CREATE SEQUENCE serving_type_seq;
CREATE SEQUENCE treat_seq;
CREATE SEQUENCE sale_seq;
CREATE SEQUENCE history_seq;

/* ---------------------------
2) Ice cream schema tables
   (I kept this simple + readable)
---------------------------- */

CREATE TABLE ice_cream_flavor (
  ice_cream_flavor_id INTEGER PRIMARY KEY,
  flavor_name VARCHAR(50) NOT NULL
);

CREATE TABLE ice_cream_container (
  ice_cream_container_id INTEGER PRIMARY KEY,
  container_name VARCHAR(50) NOT NULL
);

CREATE TABLE ice_cream_serving_type (
  ice_cream_serving_type_id INTEGER PRIMARY KEY,
  serving_type_name VARCHAR(50) NOT NULL
);

CREATE TABLE ice_cream_treat (
  ice_cream_treat_id INTEGER PRIMARY KEY,
  treat_name VARCHAR(100) NOT NULL,
  ice_cream_flavor_id INTEGER NOT NULL,
  ice_cream_container_id INTEGER NOT NULL,
  ice_cream_serving_type_id INTEGER NOT NULL,
  price NUMERIC(6,2) NOT NULL,
  menu_code VARCHAR(20) NOT NULL,

  FOREIGN KEY (ice_cream_flavor_id)
    REFERENCES ice_cream_flavor(ice_cream_flavor_id),

  FOREIGN KEY (ice_cream_container_id)
    REFERENCES ice_cream_container(ice_cream_container_id),

  FOREIGN KEY (ice_cream_serving_type_id)
    REFERENCES ice_cream_serving_type(ice_cream_serving_type_id)
);

CREATE TABLE ice_cream_sale (
  ice_cream_sale_id INTEGER PRIMARY KEY,
  ice_cream_treat_id INTEGER NOT NULL,
  quantity INTEGER NOT NULL,
  total_price NUMERIC(8,2) NOT NULL,
  sale_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (ice_cream_treat_id)
    REFERENCES ice_cream_treat(ice_cream_treat_id)
);

CREATE TABLE treat_history (
  history_id INTEGER PRIMARY KEY,
  ice_cream_treat_id INTEGER NOT NULL,
  old_treat_name VARCHAR(100) NOT NULL,
  new_treat_name VARCHAR(100) NOT NULL,
  changed_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

/* ---------------------------
3) Seed lookup tables
---------------------------- */

-- Flavors
INSERT INTO ice_cream_flavor (ice_cream_flavor_id, flavor_name)
VALUES (nextval('flavor_seq'), 'Vanilla');

INSERT INTO ice_cream_flavor (ice_cream_flavor_id, flavor_name)
VALUES (nextval('flavor_seq'), 'Chocolate');

INSERT INTO ice_cream_flavor (ice_cream_flavor_id, flavor_name)
VALUES (nextval('flavor_seq'), 'Strawberry');

INSERT INTO ice_cream_flavor (ice_cream_flavor_id, flavor_name)
VALUES (nextval('flavor_seq'), 'Peanut Butter Swirl');

INSERT INTO ice_cream_flavor (ice_cream_flavor_id, flavor_name)
VALUES (nextval('flavor_seq'), 'Chocolate Chip');

-- Containers
INSERT INTO ice_cream_container (ice_cream_container_id, container_name)
VALUES (nextval('container_seq'), 'Compostable Cup');

INSERT INTO ice_cream_container (ice_cream_container_id, container_name)
VALUES (nextval('container_seq'), 'Waffle Cone');

INSERT INTO ice_cream_container (ice_cream_container_id, container_name)
VALUES (nextval('container_seq'), 'Sugar Cone');

INSERT INTO ice_cream_container (ice_cream_container_id, container_name)
VALUES (nextval('container_seq'), 'Glass Jar');

-- Serving types
INSERT INTO ice_cream_serving_type (ice_cream_serving_type_id, serving_type_name)
VALUES (nextval('serving_type_seq'), 'One Scoop');

INSERT INTO ice_cream_serving_type (ice_cream_serving_type_id, serving_type_name)
VALUES (nextval('serving_type_seq'), 'Two Scoops');

INSERT INTO ice_cream_serving_type (ice_cream_serving_type_id, serving_type_name)
VALUES (nextval('serving_type_seq'), 'Sundae');

INSERT INTO ice_cream_serving_type (ice_cream_serving_type_id, serving_type_name)
VALUES (nextval('serving_type_seq'), 'Root Beer Float');

/* ---------------------------
4) Procedures (PL/pgSQL)
---------------------------- */

-- 4.1 Hardcoded procedure (no params)
CREATE OR REPLACE PROCEDURE add_classic_vanilla()
LANGUAGE plpgsql
AS $$
DECLARE
  v_flavor_id INT;
  v_container_id INT;
  v_serving_id INT;
BEGIN
  SELECT ice_cream_flavor_id INTO v_flavor_id
  FROM ice_cream_flavor
  WHERE flavor_name = 'Vanilla';

  SELECT ice_cream_container_id INTO v_container_id
  FROM ice_cream_container
  WHERE container_name = 'Waffle Cone';

  SELECT ice_cream_serving_type_id INTO v_serving_id
  FROM ice_cream_serving_type
  WHERE serving_type_name = 'One Scoop';

  INSERT INTO ice_cream_treat
    (ice_cream_treat_id, treat_name, ice_cream_flavor_id, ice_cream_container_id,
     ice_cream_serving_type_id, price, menu_code)
  VALUES
    (nextval('treat_seq'), 'Classic Vanilla Cone', v_flavor_id, v_container_id,
     v_serving_id, 3.50, 'CL-CONE');
END;
$$;

-- 4.2 Reusable procedure (params for all non-PK columns)
CREATE OR REPLACE PROCEDURE add_treat(
  p_treat_name VARCHAR,
  p_flavor_id INT,
  p_container_id INT,
  p_serving_type_id INT,
  p_price NUMERIC,
  p_menu_code VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO ice_cream_treat
    (ice_cream_treat_id, treat_name, ice_cream_flavor_id, ice_cream_container_id,
     ice_cream_serving_type_id, price, menu_code)
  VALUES
    (nextval('treat_seq'), p_treat_name, p_flavor_id, p_container_id,
     p_serving_type_id, p_price, p_menu_code);
END;
$$;

-- 4.3 Deriving procedure (menu_code derived internally)
CREATE OR REPLACE PROCEDURE add_treat_deriving(
  p_treat_name VARCHAR,
  p_flavor_id INT,
  p_container_id INT,
  p_serving_type_id INT,
  p_price NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_menu_code VARCHAR(20);
BEGIN
  v_menu_code := upper(left(p_treat_name, 2)) || '-' || upper(right(p_treat_name, 4));

  INSERT INTO ice_cream_treat
    (ice_cream_treat_id, treat_name, ice_cream_flavor_id, ice_cream_container_id,
     ice_cream_serving_type_id, price, menu_code)
  VALUES
    (nextval('treat_seq'), p_treat_name, p_flavor_id, p_container_id,
     p_serving_type_id, p_price, v_menu_code);
END;
$$;

-- 4.4 Lookup procedure (pass treat name, compute total inside)
CREATE OR REPLACE PROCEDURE add_sale(
  p_treat_name VARCHAR,
  p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_treat_id INT;
  v_price NUMERIC(6,2);
  v_total NUMERIC(8,2);
BEGIN
  SELECT ice_cream_treat_id, price
  INTO v_treat_id, v_price
  FROM ice_cream_treat
  WHERE treat_name = p_treat_name;

  v_total := p_quantity * v_price;

  INSERT INTO ice_cream_sale (ice_cream_sale_id, ice_cream_treat_id, quantity, total_price)
  VALUES (nextval('sale_seq'), v_treat_id, p_quantity, v_total);
END;
$$;

/* ---------------------------
5) Triggers
---------------------------- */

-- 5.1 Validate menu_code matches treat_name pattern
CREATE OR REPLACE FUNCTION check_menu_code()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  expected_code VARCHAR(20);
BEGIN
  expected_code := upper(left(NEW.treat_name, 2)) || '-' || upper(right(NEW.treat_name, 4));

  IF NEW.menu_code <> expected_code THEN
    RAISE EXCEPTION 'Wrong menu_code. Expected %, got %', expected_code, NEW.menu_code;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_menu_code
BEFORE INSERT ON ice_cream_treat
FOR EACH ROW
EXECUTE FUNCTION check_menu_code();

-- 5.2 Validate sale.total_price = quantity * treat.price
CREATE OR REPLACE FUNCTION check_sale_total()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_price NUMERIC(6,2);
  v_expected NUMERIC(8,2);
BEGIN
  SELECT price INTO v_price
  FROM ice_cream_treat
  WHERE ice_cream_treat_id = NEW.ice_cream_treat_id;

  v_expected := NEW.quantity * v_price;

  IF abs(NEW.total_price - v_expected) > 0.01 THEN
    RAISE EXCEPTION 'Wrong total_price. Expected %, got %', v_expected, NEW.total_price;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_check_sale_total
BEFORE INSERT ON ice_cream_sale
FOR EACH ROW
EXECUTE FUNCTION check_sale_total();

-- 5.3 History: log treat name changes
CREATE OR REPLACE FUNCTION log_treat_name_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.treat_name <> OLD.treat_name THEN
    INSERT INTO treat_history (history_id, ice_cream_treat_id, old_treat_name, new_treat_name, changed_time)
    VALUES (nextval('history_seq'), OLD.ice_cream_treat_id, OLD.treat_name, NEW.treat_name, CURRENT_TIMESTAMP);
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_treat_name_history
AFTER UPDATE ON ice_cream_treat
FOR EACH ROW
EXECUTE FUNCTION log_treat_name_change();

/* ---------------------------
6) Demo run (data + tests)
   Note: CALL doesn't accept subqueries directly in Postgres,
         so I use DO blocks to fetch IDs into variables.
---------------------------- */

-- Add first hardcoded item
CALL add_classic_vanilla();

-- Add three treats with reusable procedure (DO blocks)
DO $$
DECLARE
  v_flavor_id INT;
  v_container_id INT;
  v_serving_id INT;
BEGIN
  SELECT ice_cream_flavor_id INTO v_flavor_id FROM ice_cream_flavor WHERE flavor_name = 'Chocolate Chip';
  SELECT ice_cream_container_id INTO v_container_id FROM ice_cream_container WHERE container_name = 'Compostable Cup';
  SELECT ice_cream_serving_type_id INTO v_serving_id FROM ice_cream_serving_type WHERE serving_type_name = 'Two Scoops';

  CALL add_treat('Double Chocolate Chip Crunch', v_flavor_id, v_container_id, v_serving_id, 4.25, 'DO-UNCH');
END $$;

DO $$
DECLARE
  v_flavor_id INT;
  v_container_id INT;
  v_serving_id INT;
BEGIN
  SELECT ice_cream_flavor_id INTO v_flavor_id FROM ice_cream_flavor WHERE flavor_name = 'Strawberry';
  SELECT ice_cream_container_id INTO v_container_id FROM ice_cream_container WHERE container_name = 'Glass Jar';
  SELECT ice_cream_serving_type_id INTO v_serving_id FROM ice_cream_serving_type WHERE serving_type_name = 'Sundae';

  CALL add_treat('Strawberry Shortcake Sundae', v_flavor_id, v_container_id, v_serving_id, 6.00, 'ST-NDAE');
END $$;

DO $$
DECLARE
  v_flavor_id INT;
  v_container_id INT;
  v_serving_id INT;
BEGIN
  SELECT ice_cream_flavor_id INTO v_flavor_id FROM ice_cream_flavor WHERE flavor_name = 'Peanut Butter Swirl';
  SELECT ice_cream_container_id INTO v_container_id FROM ice_cream_container WHERE container_name = 'Compostable Cup';
  SELECT ice_cream_serving_type_id INTO v_serving_id FROM ice_cream_serving_type WHERE serving_type_name = 'One Scoop';

  CALL add_treat('PB Swirl Bliss Bowl', v_flavor_id, v_container_id, v_serving_id, 3.75, 'PB-BOWL');
END $$;

-- Add two treats with deriving procedure
DO $$
DECLARE
  v_flavor_id INT;
  v_container_id INT;
  v_serving_id INT;
BEGIN
  SELECT ice_cream_flavor_id INTO v_flavor_id FROM ice_cream_flavor WHERE flavor_name = 'Chocolate';
  SELECT ice_cream_container_id INTO v_container_id FROM ice_cream_container WHERE container_name = 'Compostable Cup';
  SELECT ice_cream_serving_type_id INTO v_serving_id FROM ice_cream_serving_type WHERE serving_type_name = 'Root Beer Float';

  CALL add_treat_deriving('Old-Fashioned Chocolate Float', v_flavor_id, v_container_id, v_serving_id, 5.95);
END $$;

DO $$
DECLARE
  v_flavor_id INT;
  v_container_id INT;
  v_serving_id INT;
BEGIN
  SELECT ice_cream_flavor_id INTO v_flavor_id FROM ice_cream_flavor WHERE flavor_name = 'Vanilla';
  SELECT ice_cream_container_id INTO v_container_id FROM ice_cream_container WHERE container_name = 'Compostable Cup';
  SELECT ice_cream_serving_type_id INTO v_serving_id FROM ice_cream_serving_type WHERE serving_type_name = 'One Scoop';

  CALL add_treat_deriving('Vanilla Bean Mini', v_flavor_id, v_container_id, v_serving_id, 3.25);
END $$;

-- Trigger test: valid insert then invalid insert
DO $$
DECLARE
  v_flavor_id INT;
  v_container_id INT;
  v_serving_id INT;
BEGIN
  SELECT ice_cream_flavor_id INTO v_flavor_id FROM ice_cream_flavor WHERE flavor_name = 'Vanilla';
  SELECT ice_cream_container_id INTO v_container_id FROM ice_cream_container WHERE container_name = 'Compostable Cup';
  SELECT ice_cream_serving_type_id INTO v_serving_id FROM ice_cream_serving_type WHERE serving_type_name = 'One Scoop';

  -- valid menu code for "Mango Delight" => MA-IGHT
  CALL add_treat('Mango Delight', v_flavor_id, v_container_id, v_serving_id, 3.99, 'MA-IGHT');

  -- invalid menu code on purpose (should fail)
  -- CALL add_treat('Mango Delight', v_flavor_id, v_container_id, v_serving_id, 3.99, 'XX-1234');
END $$;

-- Add sales via lookup procedure
CALL add_sale('Classic Vanilla Cone', 2);
CALL add_sale('Vanilla Bean Mini', 3);

-- Trigger test for sales total (one good, one bad)
-- Good (example uses treat_id 1, but it depends on your sequence order; keep this as an example)
-- INSERT INTO ice_cream_sale (ice_cream_sale_id, ice_cream_treat_id, quantity, total_price)
-- VALUES (nextval('sale_seq'), 1, 2, 7.00);

-- Bad (should fail)
-- INSERT INTO ice_cream_sale (ice_cream_sale_id, ice_cream_treat_id, quantity, total_price)
-- VALUES (nextval('sale_seq'), 1, 2, 1.00);

-- History test: rename a treat to create a history record
UPDATE ice_cream_treat
SET treat_name = 'Vanilla Mini'
WHERE treat_name = 'Vanilla Bean Mini';

/* ---------------------------
7) Quick “portfolio” queries
---------------------------- */

-- Treat menu (what's available)
SELECT
  t.ice_cream_treat_id,
  t.treat_name,
  f.flavor_name,
  c.container_name,
  s.serving_type_name,
  t.price,
  t.menu_code
FROM ice_cream_treat t
JOIN ice_cream_flavor f ON f.ice_cream_flavor_id = t.ice_cream_flavor_id
JOIN ice_cream_container c ON c.ice_cream_container_id = t.ice_cream_container_id
JOIN ice_cream_serving_type s ON s.ice_cream_serving_type_id = t.ice_cream_serving_type_id
ORDER BY t.ice_cream_treat_id;

-- Sales ledger
SELECT
  sale.ice_cream_sale_id,
  t.treat_name,
  sale.quantity,
  sale.total_price,
  sale.sale_time
FROM ice_cream_sale sale
JOIN ice_cream_treat t ON t.ice_cream_treat_id = sale.ice_cream_treat_id
ORDER BY sale.ice_cream_sale_id;

-- Treat rename history
SELECT * FROM treat_history ORDER BY history_id;
