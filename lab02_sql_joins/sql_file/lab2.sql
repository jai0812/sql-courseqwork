-- ======================================================================
-- CS669 Lab 2 - PostgreSQL
-- Author: Jai Sharma
-- ======================================================================

-- Step 1: Create Tables
CREATE TABLE Game (
  game_id      DECIMAL(12) PRIMARY KEY,
  title        VARCHAR(64) NOT NULL,
  release_date DATE NOT NULL,
  price        DECIMAL(6,2) NOT NULL
);

CREATE TABLE Player (
  player_id        DECIMAL(12) PRIMARY KEY,
  player_name      VARCHAR(64) NOT NULL,
  games_played     DECIMAL(6) NOT NULL,
  favorite_game_id DECIMAL(12) NULL,
  CONSTRAINT player_favorite_game_fk
    FOREIGN KEY (favorite_game_id)
    REFERENCES Game(game_id)
);

-- Step 2: Insert Data
INSERT INTO Game (game_id, title, release_date, price) VALUES
(1001, 'Gran Turismo Sport',  '2017-10-17', 49.99),
(1002, 'Forza Horizon 4',     '2018-10-02', 45.99),
(1003, 'FIFA 21',             '2020-10-09', 59.99),
(1004, 'Tony Hawk Pro Skater','2020-09-04', 39.99);

INSERT INTO Player (player_id, player_name, games_played, favorite_game_id) VALUES
(2001, 'Alex Morgan',    0,  NULL),
(2002, 'Samantha Ortiz', 42, 1002),
(2003, 'Michael Chen',   87, 1003),
(2004, 'Priya Kapoor',   29, 1003),
(2005, 'Liam Connor',    15, 1004);

SELECT * FROM Game ORDER BY game_id;
SELECT * FROM Player ORDER BY player_id;

-- Step 3: Invalid Reference Attempt (should FAIL)
INSERT INTO Player (player_id, player_name, games_played, favorite_game_id)
VALUES (2999, 'Bad FK Player', 1, 999999);

-- Step 4: INNER JOIN
SELECT g.title, p.player_name
FROM Game g
JOIN Player p
  ON p.favorite_game_id = g.game_id
ORDER BY g.title, p.player_name;

-- Step 5: ALL games (LEFT JOIN + RIGHT JOIN)
SELECT g.title, g.release_date, p.player_name
FROM Game g
LEFT JOIN Player p
  ON p.favorite_game_id = g.game_id
ORDER BY g.release_date ASC;

SELECT g.title, g.release_date, p.player_name
FROM Player p
RIGHT JOIN Game g
  ON p.favorite_game_id = g.game_id
ORDER BY g.release_date ASC;

-- Step 6: ALL players (LEFT JOIN + RIGHT JOIN)
SELECT p.player_name, p.games_played, g.title AS favorite_game
FROM Player p
LEFT JOIN Game g
  ON p.favorite_game_id = g.game_id
ORDER BY p.player_name DESC;

SELECT p.player_name, p.games_played, g.title AS favorite_game
FROM Game g
RIGHT JOIN Player p
  ON p.favorite_game_id = g.game_id
ORDER BY p.player_name DESC;

-- Step 7: FULL JOIN (all games + all players)
SELECT g.title, p.player_name
FROM Game g
FULL JOIN Player p
  ON p.favorite_game_id = g.game_id
ORDER BY g.title, p.player_name;

-- Step 8: Format as USD
SELECT title,
       to_char(price, 'FM$999,999,990.00') AS price_usd
FROM Game
ORDER BY title;

-- Step 9: Discount by $10 + format
SELECT title,
       to_char(price - 10, 'FM$999,999,990.00') AS discounted_price_usd
FROM Game
ORDER BY title;

-- Step 10: Advanced formatting line
SELECT
  p.player_name || ' (' || g.title || ' - ' || to_char(g.price, 'FM$999,999,990.00') || ')' AS formatted_line
FROM Player p
JOIN Game g
  ON p.favorite_game_id = g.game_id
ORDER BY p.player_name;

-- Step : Premium games filter
SELECT title, price, release_date
FROM Game
WHERE price >= 50.00
  AND release_date >= DATE '2020-05-01'
  AND title <> 'Gran Turismo Sport'
ORDER BY title;

-- Step : Generated reduced_price (example $11 off)
ALTER TABLE Game
ADD COLUMN reduced_price DECIMAL(6,2)
GENERATED ALWAYS AS (price - 11) STORED;

SELECT title,
       to_char(price, 'FM$999,999,990.00') AS regular_price,
       to_char(reduced_price, 'FM$999,999,990.00') AS reduced_price
FROM Game
ORDER BY title;
