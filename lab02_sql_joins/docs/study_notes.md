# Lab 2 — Study Notes 


## Step 7 (FULL JOIN)
A FULL JOIN includes:
- all games
- all players
- plus the matches

Rows with no match show NULL for the other table.

## Step 9 (Expressions)
This step uses:
- `price - 10` in the SELECT list
- formatting using `to_char()`
No updates and no joins are needed.

## Step 10 (Advanced Formatting)
We build a string like:
PlayerName (GameTitle - $Price)

Best practice is to format the price using `to_char()` for 2 decimals.

## Step 12a (Boolean filter)
Premium games must satisfy ALL conditions:
- not Gran Turismo Sport
- release_date >= 2020-05-01
- price >= 50

## Step 13a (Generated Column)
Generated columns auto-compute and should not be manually updated.
Insert statements omit them.
