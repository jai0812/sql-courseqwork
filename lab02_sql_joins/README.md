## Lab 2 — PostgreSQL 

This repo contains my **Lab 2** work clean & friendly way.

Topics covered:
- Primary key + foreign key relationships
- INNER JOIN / LEFT JOIN / RIGHT JOIN / FULL JOIN / CROSS JOIN
- Formatting output using `to_char()`
- Expressions (discounted prices)
- Boolean conditions in `WHERE`
- Generated columns (`GENERATED ALWAYS AS (...) STORED`)

---

###  Repository Structure

- `sql/lab2.sql` → Full step-by-step solution (copy/paste runnable)
- `docs/study_notes.md` → Easy explanations + common reasoning (why each option is correct/incorrect)

---

## How to Run (PostgreSQL)

### Option A: pgAdmin
1. Open **pgAdmin**
2. Open **Query Tool**
3. Run `sql/lab2.sql` section by section
4. Take screenshots after each step (query + output)

### Option B: psql
```bash
psql -d your_db_name -f sql/lab2.sql
```
---

##  Skills demonstrated 
- SQL data modeling (PK/FK)
- Relational integrity constraints
- Join logic and null-handling
- SQL formatting for reporting outputs
- Computed fields (generated columns)

