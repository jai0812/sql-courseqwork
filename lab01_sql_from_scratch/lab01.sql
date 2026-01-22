-- =========================================
-- Lab 01: SQL From Scratch
-- Author: Jai Sharma
-- Purpose: Practice core SQL fundamentals,
--          constraints, updates, deletions,
--          and data anomalies
-- =========================================

-- Everything will be detailed
/* 
   SECTION 1: ABSOLUTE FUNDAMENTALS
*/

-- 1. Create table
CREATE TABLE Work_achievement (
    achievement_id INT,
    reward DECIMAL(10,2)
);

-- 2. Insert a row
INSERT INTO Work_achievement (achievement_id, reward)
VALUES (1, 150.00);

-- 3. Select all rows
SELECT * FROM Work_achievement;

-- 4. Update reward
UPDATE Work_achievement
SET reward = 200.25;

-- Verify update
SELECT * FROM Work_achievement;

-- 5. Delete all rows
DELETE FROM Work_achievement;

-- Verify deletion
SELECT * FROM Work_achievement;

-- 6. Drop table
DROP TABLE Work_achievement;


/* 
   SECTION 2: PRECISE DATA HANDLING
*/

-- 7. Create Community Garden table
CREATE TABLE Community_garden_plot (
    plot_num INT PRIMARY KEY,
    plot_name VARCHAR(50) NOT NULL,
    description VARCHAR(100),
    last_tended_date DATE,
    available_date DATE
);

-- 8. Insert initial rows
INSERT INTO Community_garden_plot VALUES
(101, 'Deer Creek Garden', 'Near river trail', DATE '2026-04-20', DATE '2026-05-01'),
(102, 'Paradise Palms', NULL, DATE '2026-03-18', DATE '2026-04-10'),
(103, 'Town Square Beds', 'Community center plot', DATE '2026-02-12', DATE '2026-03-01');

-- Verify inserts
SELECT * FROM Community_garden_plot;

-- 9. Invalid insertion (violates NOT NULL constraint)
-- This statement should fail
INSERT INTO Community_garden_plot
VALUES (259, NULL, 'Close to downtown shops', DATE '2026-07-17', DATE '2026-07-13');

-- 10. Valid insertion
INSERT INTO Community_garden_plot
VALUES (259, 'Garden of Light', 'Close to downtown shops',
        DATE '2026-07-17', DATE '2026-07-13');

-- Verify insertion
SELECT * FROM Community_garden_plot;

-- 11. Filtered results using primary key
SELECT plot_name, description
FROM Community_garden_plot
WHERE plot_num = 101;

-- 12. Targeted update
UPDATE Community_garden_plot
SET description = 'A mile walk to the beach'
WHERE plot_name = 'Paradise Palms';

-- Verify update
SELECT * FROM Community_garden_plot;

-- 13. Update description to NULL
UPDATE Community_garden_plot
SET description = NULL
WHERE plot_name = 'Town Square Beds';

-- Verify update
SELECT * FROM Community_garden_plot;

-- 14. Targeted deletion
DELETE FROM Community_garden_plot
WHERE last_tended_date > DATE '2026-05-01';

-- Verify deletion
SELECT * FROM Community_garden_plot;


/*
   SECTION 3: DATA ANOMALIES
*/

-- 15a. Create table WITHOUT constraints
CREATE TABLE Person_data (
    name VARCHAR(50),
    age INT,
    weight INT
);

-- Insert duplicate and inconsistent data
INSERT INTO Person_data VALUES
('Alex', 25, 70),
('Alex', 25, 75),
('Carlo', 30, 67),
('Carlo', 30, 67);

-- View data
SELECT * FROM Person_data;

-- 15b. Demonstrate deletion anomaly
DELETE FROM Person_data
WHERE name = 'Carlo';

-- Verify unintended data loss
SELECT * FROM Person_data;


/* 
   END OF LAB
*/
