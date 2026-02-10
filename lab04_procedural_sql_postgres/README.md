# Lab 4 — Procedural SQL & Triggers (PostgreSQL) 

This project is my “learning curve” build for **procedural SQL in PostgreSQL (PL/pgSQL)**.  
Instead of only running one-off SQL queries, I practiced writing **stored procedures**, using **variables**, and creating **triggers** for real database validation rules.

---

## What I built

### 1) Ice Cream Shop Mini Database
A small relational model with:
- lookup tables: `ice_cream_flavor`, `ice_cream_container`, `ice_cream_serving_type`
- business tables: `ice_cream_treat`, `ice_cream_sale`
- history table: `treat_history`
- sequences to generate IDs: `*_seq`

---

## Key skills demonstrated

###  Procedural SQL (PL/pgSQL)
I created stored procedures that show increasing complexity:

- **Hardcoded procedure**
  - `add_classic_vanilla()` inserts one fixed “Classic Vanilla Cone”
  - shows how to use `SELECT INTO` to look up foreign keys

- **Reusable insert procedure**
  - `add_treat(...)` inserts any treat using parameters
  - uses sequences for primary keys

- **Deriving logic inside a procedure**
  - `add_treat_deriving(...)` generates `menu_code` internally (string manipulation + variable)

- **Cross-table lookup + calculation**
  - `add_sale(treat_name, quantity)` looks up treat ID + price, then calculates total price inside the procedure

---

### Triggers (data validation + auditing)

- **Trigger 1: Treat menu code validation**
  - blocks inserts where `menu_code` doesn’t match the required rule:
    - first 2 letters of treat name + '-' + last 4 letters (uppercase)

- **Trigger 2: Sale total validation**
  - blocks inserts where `total_price != quantity * treat.price`

- **Trigger 3: History tracking**
  - logs treat name changes to `treat_history`
  - helpful for auditing / data lineage

---

## Normalization (BCNF) — “Court Case” scenario (design work)

Separately from the ice cream schema, I worked through a normalization problem:
- Identified **functional dependencies (FDs)**
- Proposed a **BCNF decomposition**
- Modeled repeating groups (attorney1..3, decision1..2) using bridge tables
- Built a physical ERD (primary keys, foreign keys, constraints)

---

## How to run

### Requirements
- PostgreSQL 12+ (works fine on newer versions)
- pgAdmin or psql

### Run steps
1. Open `lab4_procedural_sql_postgres.sql`
2. Run the entire file **top-to-bottom**
3. The script is **repeatable**: it drops & recreates objects each run

---

## Outputs you can expect
After running the script:
- `ice_cream_treat` contains seeded treats (including derived menu codes)
- `ice_cream_sale` contains sales added by procedure
- invalid inserts get blocked by triggers (menu codes, totals)
- name updates get logged into `treat_history`

---

## Notes / small PostgreSQL detail I learned
PostgreSQL does **not** allow subqueries directly inside `CALL procedure(...)` arguments.  
So for passing foreign key IDs into `CALL`, I used `DO $$ ... $$` blocks to:
1) look up IDs into variables  
2) then call the procedure with normal values

This is a very practical “real-world” PostgreSQL habit.

---

## What I’d improve next
- Add CHECK constraints (`quantity > 0`, `price > 0`)
- Add UNIQUE constraints (`flavor_name`, `container_name`, etc.)
- Add more reporting queries (top-selling treats, revenue per day)
- Add transactions + concurrency demo (locking / isolation) if needed

---

## File structure
- `lab4_procedural_sql_postgres.sql` → the full runnable build + demo
- `README.md` → project overview and learning notes

---

#### Part 1: Database Setup (Foundations)

- Step 1: Sequences and Tables

I began by creating sequences to generate primary keys instead of manually assigning IDs.
This mirrors real production databases where IDs are system-generated.

Sequences created

flavor_seq

container_seq

serving_type_seq

treat_seq

sale_seq

history_seq

Core tables created

ice_cream_flavor

ice_cream_container

ice_cream_serving_type

ice_cream_treat

ice_cream_sale

treat_history

Each table has:

a clear primary key

appropriate foreign keys

realistic datatypes

This step helped me understand how relational structure comes before logic.

#### Part 2: Populating Lookup Tables
- Step 2: Insert Reference Data

Before adding business logic, I populated lookup tables such as:

flavors

containers

serving types

I intentionally inserted rows one at a time using nextval() to:

understand how sequences increment

verify data visually using SELECT *

This reinforced the idea that lookup tables stabilize a schema and prevent inconsistent data later.

#### Part 3: Stored Procedures (PL/pgSQL)

This was the core learning objective of the lab.

- Step 3: Hard-coded Procedure (add_classic_vanilla)

I created my first procedure with:

no parameters

hard-coded business logic

foreign keys resolved using SELECT INTO

This procedure inserts a predefined item:

Classic Vanilla Cone

What I learned

how procedures differ from functions

how variables are declared

how to look up foreign keys inside PL/pgSQL

- Step 4: Reusable Insert Procedure (add_treat)

Next, I generalized the logic.

This procedure:

accepts treat details as parameters

generates the primary key using a sequence

inserts into ice_cream_treat

What this taught me

how to design reusable database logic

how procedures reduce duplication

how databases can enforce structure, not just store data

- Step 5: Derived Values Inside Procedures (add_treat_deriving)

In this step, I removed menu_code from the parameters.

Instead, the procedure:

derives menu_code automatically from treat_name

uses string functions (left, right, upper)

stores the result in a local variable

Why this matters

reduces human error

centralizes business rules

demonstrates that SQL can behave like application logic

- wStep 6: Lookup + Calculation Procedure (add_sale)

This procedure simulates a real transaction.

Inputs

treat name

quantity

Inside the procedure

the treat ID is looked up

the treat price is retrieved

total price is calculated

the sale is inserted

Key learning

PostgreSQL does not allow subqueries inside CALL.

I learned to use DO $$ ... $$ blocks to:

fetch values into variables

then call procedures safely

This is a very practical PostgreSQL-specific lesson.

#### Part 4: Triggers (Automatic Validation)

Triggers allow the database to protect itself, even if bad data is sent.

- Step 7: Menu Code Validation Trigger

I created a BEFORE INSERT trigger on ice_cream_treat.

The trigger:

computes the expected menu_code

compares it with the inserted value

blocks the insert if it doesn’t match

This showed me how:

databases enforce business rules

logic can live below the application layer

- Step 8: Sale Total Validation Trigger

Another BEFORE INSERT trigger ensures:

total_price = quantity × treat.price


If the calculation is wrong:

the insert fails

an error is raised

This prevents:

incorrect financial data

silent data corruption

- Step 9: History / Audit Trigger

I implemented an AFTER UPDATE trigger to track:

old treat name

new treat name

timestamp of change

Each rename creates a row in treat_history.

This taught me:

how databases handle auditing

how history tables are implemented in real systems

why AFTER triggers are useful

#### Part 5: Normalization to BCNF (Design Thinking)
Step 10(a): Functional Dependencies

I analyzed a flat spreadsheet containing:

case details

plaintiffs and defendants

multiple attorneys

multiple decisions per appearance

I identified functional dependencies such as:

case_number → case_description, parties

(case_number, appearance_date) → appearance details

(appearance, attorney_number) → attorney

(appearance, decision_number) → decision

This showed why the spreadsheet was not normalized.

- Step 10:  BCNF Decomposition + ERD

Using the dependencies, I decomposed the design into:

Case

Person

Court_Appearance

Attorney

Decision

bridge tables for many-to-many relationships

Key improvements

repeating groups removed

composite keys introduced

unique constraints added to enforce business rules

An ER diagram was created to visually represent the final schema.

### What This Project Demonstrates

procedural SQL is real programming

databases can enforce logic, not just store data

triggers are essential for data integrity

normalization prevents long-term data problems

PostgreSQL has its own quirks that matter in practice

--  Possible Extensions

If expanded further, I would:

add CHECK constraints (price > 0, quantity > 0)

add indexes for performance

add revenue analytics queries

demonstrate transactions and rollbacks

connect this schema to a backend API
