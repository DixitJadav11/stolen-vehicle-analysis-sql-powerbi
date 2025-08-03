-- Project: Stolen Vehicles Analysis using SQL Server
-- Author: Dixit Jadav
-- Objective: Analyze stolen vehicle data to derive meaningful insights such as theft patterns by location, vehicle type, population, etc., and present trends to aid strategic decision-making.

-- -----------------------------------------------------------
-- STEP 1: DATABASE CREATION & TABLE STRUCTURE
-- -----------------------------------------------------------
CREATE DATABASE projectdatabase;
USE projectdatabase;

-- TABLE: locations
CREATE TABLE locations (
    location_id INT,
    region VARCHAR(MAX),
    country VARCHAR(MAX),
    population INT,
    density FLOAT
);

-- TABLE: stolen_vehicles
CREATE TABLE stolen_vehicles (
    vehicle_id INT,
    vehicle_type VARCHAR(MAX),
    make_id INT,
    model_year INT,
    vehicle_desc VARCHAR(MAX),
    color VARCHAR(MAX),
    date_stolen VARCHAR(MAX),
    location_id INT
);

-- TABLE: make_details
CREATE TABLE make_details (
    make_id INT,
    make_name VARCHAR(MAX),
    make_type VARCHAR(MAX)
);

-- 🧠 Insight:
-- Using VARCHAR(MAX) initially allows flexible import from CSVs. Later we convert to appropriate types (INT, DATE, FLOAT) for analysis.

-- -----------------------------------------------------------
-- STEP 2: DATA IMPORT (Example for SQL Server BULK INSERT)
-- -----------------------------------------------------------

BULK INSERT locations FROM "C:\Users\DIXIT JADAV\OneDrive\Dokumen\sql_project_data\locations.csv" WITH (FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', FIRSTROW = 2);
BULK INSERT stolen_vehicles FROM "C:\Users\DIXIT JADAV\OneDrive\Dokumen\sql_project_data\stolen_vehicles.csv" WITH (FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', FIRSTROW = 2);
BULK INSERT make_details FROM "C:\Users\DIXIT JADAV\OneDrive\Dokumen\sql_project_data\make_details.csv" WITH (FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', FIRSTROW = 2);

-- -----------------------------------------------------------
-- STEP 3: DATA CLEANING & TYPE CONVERSION WITH TRANSACTION
-- -----------------------------------------------------------
-- Fix malformed dates
BEGIN TRANSACTION;

-- Fix malformed dates
UPDATE stolen_vehicles
SET date_stolen = CASE 
    WHEN date_stolen = '2021/15/10' THEN '2021-10-15'
    WHEN date_stolen = '13-02-2022' THEN '2022-02-13'
    ELSE date_stolen
END
WHERE TRY_CONVERT(DATE, date_stolen) IS NULL;

-- Convert types for accurate analysis
ALTER TABLE stolen_vehicles ALTER COLUMN date_stolen DATE;
ALTER TABLE locations ALTER COLUMN population INT;
ALTER TABLE locations ALTER COLUMN density FLOAT;

COMMIT;
-- If anything fails above, use ROLLBACK instead of COMMIT

-- 🧠 Insight:
-- Accurate data types improve sorting, filtering, and numeric calculations, especially for trend analysis.
-- Wrapping in a transaction ensures consistency and safety.

-- -----------------------------------------------------------
-- STEP 4: ADD TRIGGER TO LOG VEHICLE INSERTS
-- -----------------------------------------------------------
-- Create log table
CREATE TABLE insert_logs (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    inserted_time DATETIME DEFAULT GETDATE(),
    vehicle_id INT,
    message VARCHAR(255)
);

-- Trigger: Log every new stolen vehicle inserted
CREATE TRIGGER trg_vehicle_insert_log
ON stolen_vehicles
AFTER INSERT
AS
BEGIN
    INSERT INTO insert_logs (vehicle_id, message)
    SELECT vehicle_id, 'New stolen vehicle record inserted.' FROM inserted;
END;

-- 🧠 Insight:
-- Trigger ensures any insert is automatically recorded for future tracking or audit.

-- -----------------------------------------------------------
-- STEP 5: EXPLORATORY DATA ANALYSIS (EDA)
-- -----------------------------------------------------------
-- A. Segmentation of Vehicle Models by Age
SELECT *,
    CASE 
        WHEN model_year BETWEEN 1940 AND 1960 THEN 'vintage_model'
        WHEN model_year BETWEEN 1961 AND 2000 THEN 'oldest_model'
        WHEN model_year BETWEEN 2001 AND 2017 THEN 'mid_range_model'
        ELSE 'latest_model'
    END AS vehicle_segment
FROM stolen_vehicles;

-- B. Count of stolen vehicles by type
SELECT vehicle_type, COUNT(vehicle_id) AS theft_count
FROM stolen_vehicles
WHERE vehicle_type IS NOT NULL
GROUP BY vehicle_type
ORDER BY theft_count DESC;

-- C. Most stolen vehicle colors
SELECT color, COUNT(*) AS total_thefts
FROM stolen_vehicles
GROUP BY color
ORDER BY total_thefts DESC;

-- D. Make type distribution
SELECT make_type, COUNT(vehicle_id) AS total_stolen
FROM make_details m
JOIN stolen_vehicles s ON m.make_id = s.make_id
GROUP BY make_type;

-- 🧠 Insight:
-- Helps businesses and law enforcement know which models/colors are most targeted.
-- Also tells us that standard vehicles dominate theft incidents.

-- -----------------------------------------------------------
-- STEP 6: TIME-BASED PATTERNS
-- -----------------------------------------------------------
-- Weekday vs Weekend Thefts
SELECT 
    CASE 
        WHEN DATENAME(WEEKDAY, date_stolen) IN ('Saturday', 'Sunday') THEN 'Weekend'
        ELSE 'Weekday' 
    END AS day_type,
    COUNT(*) AS theft_count
FROM stolen_vehicles
GROUP BY CASE 
    WHEN DATENAME(WEEKDAY, date_stolen) IN ('Saturday', 'Sunday') THEN 'Weekend'
    ELSE 'Weekday' 
END;

-- 🧠 Insight:
-- Theft rates are significantly higher on weekdays (>70%), suggesting the need for enhanced weekday surveillance.

-- -----------------------------------------------------------
-- STEP 7: THEFT TRENDS OVER TIME (CTE + LEAD)
-- -----------------------------------------------------------
WITH monthly_theft AS (
    SELECT 
        s.location_id,
        l.region,
        MONTH(date_stolen) AS theft_month,
        COUNT(vehicle_id) AS monthly_thefts
    FROM stolen_vehicles s
    JOIN locations l ON s.location_id = l.location_id
    GROUP BY s.location_id, l.region, MONTH(date_stolen)
),
trend_check AS (
    SELECT *, LEAD(monthly_thefts) OVER (PARTITION BY location_id ORDER BY theft_month) AS next_month_thefts
    FROM monthly_theft
)
SELECT * FROM trend_check
WHERE monthly_thefts < next_month_thefts
ORDER BY location_id, theft_month;

-- 🧠 Insight:
-- We identified specific locations with increasing theft trends month over month. This informs regional policy decisions.

-- -----------------------------------------------------------
-- STEP 8: VEHICLE PROFILE BY REGION
-- -----------------------------------------------------------
WITH vehicle_profile AS (
    SELECT 
        s.vehicle_id,
        m.make_type,
        m.make_name,
        s.vehicle_type,
        s.model_year,
        s.color,
        s.date_stolen,
        l.region,
        l.population,
        l.density
    FROM stolen_vehicles s
    JOIN make_details m ON s.make_id = m.make_id
    JOIN locations l ON s.location_id = l.location_id
)
SELECT region,
       COUNT(vehicle_id) AS stolen_count,
       COUNT(DISTINCT make_name) AS unique_makes,
       COUNT(DISTINCT color) AS color_variation,
       AVG(CAST(population AS FLOAT)) AS avg_population,
       AVG(density) AS avg_density
FROM vehicle_profile
GROUP BY region
ORDER BY stolen_count DESC;

-- 🧠 Insight:
-- Regions with higher population and density tend to have more vehicle thefts.
-- More unique makes and colors indicate a broader vehicle variety, increasing theft opportunities.

-- -----------------------------------------------------------
-- STEP 9: CREATE VIEW FOR QUICK DASHBOARD ACCESS
-- -----------------------------------------------------------
-- STEP 9: CREATE VIEW FOR QUICK DASHBOARD ACCESS
CREATE VIEW vehicle_theft_summary AS
SELECT 
    l.region,
    s.vehicle_type,
    COUNT(s.vehicle_id) AS total_thefts,
    COUNT(DISTINCT s.color) AS color_variety,
    COUNT(DISTINCT m.make_name) AS unique_makes
FROM stolen_vehicles s
JOIN make_details m ON s.make_id = m.make_id
JOIN locations l ON s.location_id = l.location_id
GROUP BY l.region, s.vehicle_type;

select * from vehicle_theft_summary;


-- -----------------------------------------------------------
-- CONCLUSION
-- -----------------------------------------------------------
-- 🔹 Vehicle theft is more frequent in high-population regions and weekdays.
-- 🔹 Standard make vehicles are far more stolen than luxury ones.
-- 🔹 Vehicles from 2000–2017 are targeted the most.
-- 🔹 Color-wise, black and white dominate thefts.
-- 🔹 Trends show some regions are experiencing rising thefts over time.

-- ✅ Recommendations:
-- 1. Enhance surveillance during weekdays and in high-density regions.
-- 2. Educate car owners in risky regions to install anti-theft mechanisms.
-- 3. Law enforcement can prioritize efforts based on make_type, color, and segment risk.
-- 4. Monitor upward theft trends using monthly snapshots for future prediction.
