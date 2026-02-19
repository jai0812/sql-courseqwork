/*
==========================================================
SQL Advanced Querying Playground
Exploring Subqueries, EXISTS, Derived Tables, and Concurrency
Author: Jai Sharma
==========================================================

This script is not an assignment submission.
This is my structured exploration of:

- Uncorrelated subqueries
- Correlated subqueries
- IN vs EXISTS
- Derived tables (subquery in FROM)
- Views for reusable logic
- Concurrency anomalies
- Locking vs MVCC behavior

The goal here was to deeply understand how SQL behaves
under both logical querying and concurrent execution.
==========================================================
*/


/* ==========================================================
   PART 1 — Finding Products Sold in ALL Store Locations
   ==========================================================

   Thought process:
   I wanted to understand how to express a “for all” condition in SQL.
   SQL does not directly have a FOR ALL operator,
   so I explored three approaches:
   - IN + GROUP BY
   - Derived table (FROM subquery)
   - Correlated subquery with NOT EXISTS
*/


/* ----------------------------------------------------------
   Approach 1: IN + Uncorrelated Subquery
-----------------------------------------------------------*/

SELECT
    p.product_name,
    a.name AS alternate_name
FROM Product p
LEFT JOIN Alternate_name a
    ON a.product_id = p.product_id
WHERE p.product_id IN (
    SELECT s.product_id
    FROM Sells s
    GROUP BY s.product_id
    HAVING COUNT(DISTINCT s.store_location_id) =
           (SELECT COUNT(*) FROM Store_location)
)
ORDER BY p.product_name, a.name;

/*
What’s happening here:
- I group products in Sells.
- I compare how many stores sell each product
  against total number of stores.
- If equal → product is available everywhere.
*/


/* ----------------------------------------------------------
   Approach 2: Subquery in FROM (Derived Table)
-----------------------------------------------------------*/

SELECT
    p.product_name,
    a.name AS alternate_name
FROM (
    SELECT s.product_id
    FROM Sells s
    GROUP BY s.product_id
    HAVING COUNT(DISTINCT s.store_location_id) =
           (SELECT COUNT(*) FROM Store_location)
) AS all_store_products
JOIN Product p
    ON p.product_id = all_store_products.product_id
LEFT JOIN Alternate_name a
    ON a.product_id = p.product_id
ORDER BY p.product_name, a.name;

/*
Same logic as before,
but instead of filtering with IN,
I build a temporary result set in the FROM clause.
Conceptually cleaner in some cases.
*/


/* ----------------------------------------------------------
   Approach 3: Correlated Subquery with NOT EXISTS
-----------------------------------------------------------*/

SELECT
    p.product_name,
    a.name AS alternate_name
FROM Product p
LEFT JOIN Alternate_name a
    ON a.product_id = p.product_id
WHERE NOT EXISTS (
    SELECT 1
    FROM Store_location sl
    WHERE NOT EXISTS (
        SELECT 1
        FROM Sells s
        WHERE s.product_id = p.product_id
          AND s.store_location_id = sl.store_location_id
    )
)
ORDER BY p.product_name, a.name;

/*
This one is interesting.

Instead of counting stores,
I check if there exists ANY store
where the product is missing.

If such a store exists → exclude it.
If no store is missing → keep it.

This is a classic “for all” pattern in SQL.
*/


/* ----------------------------------------------------------
   View Version (Reusable Logic)
-----------------------------------------------------------*/

CREATE OR REPLACE VIEW products_sold_in_all_stores AS
SELECT s.product_id
FROM Sells s
GROUP BY s.product_id
HAVING COUNT(DISTINCT s.store_location_id) =
       (SELECT COUNT(*) FROM Store_location);

SELECT
    p.product_name,
    a.name AS alternate_name
FROM products_sold_in_all_stores v
JOIN Product p
    ON p.product_id = v.product_id
LEFT JOIN Alternate_name a
    ON a.product_id = p.product_id
ORDER BY p.product_name, a.name;

/*
Creating a view made the query reusable.
Cleaner logic.
Better separation of concerns.
Feels more production-ready.
*/


/* ==========================================================
   PART 2 — Concurrency Exploration (Conceptual Only)
   ==========================================================

   I studied:
   - Dirty reads (Uncommitted dependency)
   - Lost updates
   - Locking behavior
   - Multiversion concurrency control (MVCC)

   Key Insight:
   MVCC prevents dirty reads by allowing transactions
   to read the last committed version.

   Locking prevents simultaneous writes
   to the same row.

   Together, they change both:
   - The execution schedule
   - The final state of the table
*/
