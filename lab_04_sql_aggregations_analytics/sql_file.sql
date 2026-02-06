-- ============================================================
-- Lab 3 (Aggregating Data)
-- Author: Jai Sharma
--
--
--
-- Notes:
-- - The provided Lab 3 template describes the tasks but does not include
--   the flattened data table in the uploaded document, so this script
--   includes a clean, realistic sample dataset that matches the prompt.
-- - If your instructor provided a specific dataset elsewhere, replace
--   ONLY the INSERT statements below (schema + queries can stay).
-- ============================================================

-- ---------- Clean re-run ----------
DROP TABLE IF EXISTS sale_items;
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS booth_products;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS booths;
DROP TABLE IF EXISTS merchants;
DROP TABLE IF EXISTS markets;

-- ---------- Schema ----------
CREATE TABLE markets (
  market_id      INT PRIMARY KEY,
  market_name    VARCHAR(60) NOT NULL UNIQUE,
  city           VARCHAR(60) NOT NULL,
  state          CHAR(2)     NOT NULL
);

CREATE TABLE merchants (
  merchant_id    INT PRIMARY KEY,
  merchant_name  VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE booths (
  booth_id        INT PRIMARY KEY,
  market_id       INT NOT NULL REFERENCES markets(market_id),
  booth_name      VARCHAR(60) NOT NULL,
  seasonal_fee    NUMERIC(10,2),
  CHECK (seasonal_fee IS NULL OR seasonal_fee >= 0),
  UNIQUE (market_id, booth_name)
);

CREATE TABLE products (
  product_id     INT PRIMARY KEY,
  product_name   VARCHAR(80) NOT NULL,
  unit_price     NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0)
);

-- Which merchant is in which booth (and what products they offer from there)
CREATE TABLE booth_products (
  booth_id       INT NOT NULL REFERENCES booths(booth_id),
  merchant_id    INT NOT NULL REFERENCES merchants(merchant_id),
  product_id     INT NOT NULL REFERENCES products(product_id),
  PRIMARY KEY (booth_id, product_id)
);

-- Each sale happens at a booth, run by a merchant, on a date
CREATE TABLE sales (
  sale_id        INT PRIMARY KEY,
  booth_id       INT NOT NULL REFERENCES booths(booth_id),
  merchant_id    INT NOT NULL REFERENCES merchants(merchant_id),
  sale_date      DATE NOT NULL
);

-- Line items per sale
CREATE TABLE sale_items (
  sale_id        INT NOT NULL REFERENCES sales(sale_id) ON DELETE CASCADE,
  product_id     INT NOT NULL REFERENCES products(product_id),
  quantity       INT NOT NULL CHECK (quantity > 0),
  unit_price     NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
  PRIMARY KEY (sale_id, product_id)
);

-- ---------- Seed Data ----------
INSERT INTO markets (market_id, market_name, city, state) VALUES
  (1, 'Saratoga Farmers Market', 'Saratoga Springs', 'NY'),
  (2, 'Woodstock Farmers Market', 'Woodstock', 'NY');

INSERT INTO merchants (merchant_id, merchant_name) VALUES
  (1, 'FreshDumplings'),
  (2, 'Daisy Dairy'),
  (3, 'Orchard Lane'),
  (4, 'Bee Bright Honey'),
  (5, 'GreenLeaf Veggies');

INSERT INTO booths (booth_id, market_id, booth_name, seasonal_fee) VALUES
  (1, 1, 'Saratoga - Booth A', 250.00),
  (2, 1, 'Saratoga - Booth B', 175.00),
  (3, 1, 'Saratoga - Booth C', 300.00),
  (4, 2, 'Woodstock - Booth A', NULL),
  (5, 2, 'Woodstock - Booth B', NULL);

INSERT INTO products (product_id, product_name, unit_price) VALUES
  (1, 'Pork Dumplings (6pc)', 8.00),
  (2, 'Veg Dumplings (6pc)', 7.00),
  (3, 'Milk (1L)', 4.50),
  (4, 'Cheese (200g)', 6.50),
  (5, 'Apple Cider (500ml)', 5.00),
  (6, 'Honey Jar (250g)', 9.50),
  (7, 'Mixed Greens', 3.75),
  (8, 'Seasonal Veg Box', 12.00);

-- Booth offerings (booth -> merchant -> product)
INSERT INTO booth_products (booth_id, merchant_id, product_id) VALUES
  -- Saratoga
  (1, 1, 1), (1, 1, 2),
  (2, 2, 3), (2, 2, 4),
  (3, 3, 5), (3, 4, 6), (3, 5, 7), (3, 5, 8),
  -- Woodstock
  (4, 3, 5), (4, 4, 6),
  (5, 5, 7), (5, 5, 8);

-- Sales (a mix across markets; enough variety for aggregations)
INSERT INTO sales (sale_id, booth_id, merchant_id, sale_date) VALUES
  -- Saratoga sales
  (101, 1, 1, '2026-01-10'),
  (102, 1, 1, '2026-01-17'),
  (103, 2, 2, '2026-01-10'),
  (104, 2, 2, '2026-01-24'),
  (105, 3, 3, '2026-01-17'),
  (106, 3, 4, '2026-01-17'),
  (107, 3, 5, '2026-01-24'),
  -- Woodstock sales
  (201, 4, 3, '2026-01-11'),
  (202, 4, 4, '2026-01-18'),
  (203, 5, 5, '2026-01-18'),
  (204, 5, 5, '2026-01-25');

-- Sale line items
INSERT INTO sale_items (sale_id, product_id, quantity, unit_price) VALUES
  (101, 1, 3, 8.00),  -- 3 units triggers Step #2
  (101, 2, 1, 7.00),

  (102, 1, 2, 8.00),
  (102, 2, 2, 7.00),

  (103, 3, 2, 4.50),
  (103, 4, 1, 6.50),

  (104, 4, 3, 6.50),  -- 3 units triggers Step #2

  (105, 5, 4, 5.00),  -- cider
  (106, 6, 2, 9.50),  -- honey
  (107, 7, 5, 3.75),  -- greens
  (107, 8, 1, 12.00), -- veg box (premium)

  (201, 5, 2, 5.00),
  (202, 6, 3, 9.50),  -- 3 units triggers Step #2
  (203, 7, 2, 3.75),
  (203, 8, 2, 12.00),
  (204, 8, 1, 12.00);

-- ============================================================
-- SECTION ONE — REQUIRED QUERIES
-- ============================================================

-- 2) Counting Matches
-- "How many sales include at least three units of the item?"
-- Interpretation: a sale qualifies if ANY line item in that sale has quantity >= 3.
SELECT COUNT(DISTINCT si.sale_id) AS sales_with_item_qty_at_least_3
FROM sale_items si
WHERE si.quantity >= 3;

-- 3) Determining Highest and Lowest seasonal booth fees (across all booths)
-- 3a)
SELECT
  MIN(seasonal_fee) AS min_seasonal_fee,
  MAX(seasonal_fee) AS max_seasonal_fee
FROM booths;

-- 3b) Explanation (in plain SQL comments):
-- MIN/MAX/AVG ignore NULLs. So booths with NULL seasonal_fee (Woodstock)
-- do not affect min/max results. For a merchant, this means:
-- - The min/max returned reflect only booths with known fees.
-- - If they need Woodstock fee info, they must ask the market for those values.

-- 4) Grouping Aggregate Results
-- "Each merchant’s name, total quantity sold, and avg revenue per sale"
WITH sale_totals AS (
  SELECT
    s.sale_id,
    s.merchant_id,
    SUM(si.quantity * si.unit_price) AS sale_revenue,
    SUM(si.quantity) AS sale_qty
  FROM sales s
  JOIN sale_items si ON si.sale_id = s.sale_id
  GROUP BY s.sale_id, s.merchant_id
)
SELECT
  m.merchant_name,
  SUM(st.sale_qty) AS total_quantity_sold,
  ROUND(AVG(st.sale_revenue), 2) AS avg_revenue_per_sale
FROM sale_totals st
JOIN merchants m ON m.merchant_id = st.merchant_id
GROUP BY m.merchant_name
ORDER BY m.merchant_name;

-- 5) Limiting Results by Aggregation
-- "Only merchants who sold at least 3 distinct products AND earned >= $50 total revenue"
WITH merchant_stats AS (
  SELECT
    s.merchant_id,
    COUNT(DISTINCT si.product_id) AS distinct_products_sold,
    SUM(si.quantity * si.unit_price) AS total_revenue
  FROM sales s
  JOIN sale_items si ON si.sale_id = s.sale_id
  GROUP BY s.merchant_id
)
SELECT
  m.merchant_name,
  ms.distinct_products_sold,
  ROUND(ms.total_revenue, 2) AS total_revenue
FROM merchant_stats ms
JOIN merchants m ON m.merchant_id = ms.merchant_id
WHERE ms.distinct_products_sold >= 3
  AND ms.total_revenue >= 50
ORDER BY ms.total_revenue DESC;

-- 6) Adding Up Values
-- For each booth: name, total revenue, revenue from high-priced products (>= $6),
-- and % of booth revenue from high-priced products.
WITH booth_revenue AS (
  SELECT
    b.booth_id,
    b.booth_name,
    SUM(si.quantity * si.unit_price) AS total_revenue,
    SUM(CASE WHEN p.unit_price >= 6.00 THEN si.quantity * si.unit_price ELSE 0 END) AS high_price_revenue
  FROM booths b
  JOIN sales s ON s.booth_id = b.booth_id
  JOIN sale_items si ON si.sale_id = s.sale_id
  JOIN products p ON p.product_id = si.product_id
  GROUP BY b.booth_id, b.booth_name
)
SELECT
  booth_name,
  ROUND(total_revenue, 2) AS total_revenue,
  ROUND(high_price_revenue, 2) AS high_price_revenue,
  CASE
    WHEN total_revenue = 0 THEN 0
    ELSE ROUND((high_price_revenue / total_revenue) * 100, 2)
  END AS pct_revenue_high_price
FROM booth_revenue
ORDER BY total_revenue DESC;

-- 7) Integrating Aggregation with Other Constructs
-- For each merchant:
-- - Saratoga-sold items (units)
-- - Total items across all markets (units)
-- - % sold at Saratoga
-- - Avg revenue per sale across all markets
-- Filter: avg revenue per sale >= $10, order high->low.
WITH sale_totals AS (
  SELECT
    s.sale_id,
    s.merchant_id,
    b.market_id,
    SUM(si.quantity) AS sale_units,
    SUM(si.quantity * si.unit_price) AS sale_revenue
  FROM sales s
  JOIN booths b ON b.booth_id = s.booth_id
  JOIN sale_items si ON si.sale_id = s.sale_id
  GROUP BY s.sale_id, s.merchant_id, b.market_id
),
merchant_rollup AS (
  SELECT
    merchant_id,
    SUM(CASE WHEN market_id = 1 THEN sale_units ELSE 0 END) AS saratoga_units,
    SUM(sale_units) AS total_units,
    AVG(sale_revenue) AS avg_revenue_per_sale
  FROM sale_totals
  GROUP BY merchant_id
)
SELECT
  m.merchant_name,
  mr.saratoga_units,
  mr.total_units,
  CASE
    WHEN mr.total_units = 0 THEN 0
    ELSE ROUND((mr.saratoga_units::NUMERIC / mr.total_units) * 100, 2)
  END AS pct_units_sold_at_saratoga,
  ROUND(mr.avg_revenue_per_sale, 2) AS avg_revenue_per_sale
FROM merchant_rollup mr
JOIN merchants m ON m.merchant_id = mr.merchant_id
WHERE mr.avg_revenue_per_sale >= 10.00
ORDER BY mr.avg_revenue_per_sale DESC;

-- ============================================================
-- OPTIONAL: Quick sanity checks (on seeded data)
-- ============================================================
-- SELECT * FROM markets;
-- SELECT * FROM booths;
-- SELECT * FROM products;
-- SELECT * FROM sales ORDER BY sale_id;
-- SELECT * FROM sale_items ORDER BY sale_id, product_id;
