# SQL: Advanced Subqueries & Concurrency Exploration

## Overview
This repo is my structured deep dive into advanced SQL patterns and basic transaction concepts.  
I treated it like a learning playground (not an “assignment dump”) to understand *why* certain query patterns work and how concurrency changes outcomes.

Topics I focused on:
- Uncorrelated subqueries (`IN`, scalar subqueries)
- Subquery in `FROM` (derived tables)
- Correlated subqueries (`EXISTS` / `NOT EXISTS`)
- Views for reusable logic
- Concurrency anomalies (conceptual): dirty reads, locking, MVCC

---

## ER-Style Schema Diagram (Quick View)

I’m working with a small retail-style dataset where products are sold across multiple store locations, each store accepts a currency, and products can have alternate names.

```text
+-------------------+          +-------------------+
|     Currency      |          |   Store_location  |
|-------------------|          |-------------------|
| PK currency_id    |<---------| currency_accepted_id (FK)
| currency_name     |          | PK store_location_id
| usd_to_ratio      |          | store_name
+-------------------+          +-------------------+
                                      ^
                                      |
                                      |
                              +-------------------+
                              |       Sells       |
                              |-------------------|
                              | FK product_id     |
                              | FK store_location_id
                              +-------------------+
                                      ^
                                      |
                                      |
+-------------------+          +-------------------+
|      Product      |<---------|  Alternate_name   |
|-------------------|          |-------------------|
| PK product_id     |          | PK alt_name_id (or similar)
| product_name      |          | FK product_id
| price_in_usd      |          | name
+-------------------+          +-------------------+
