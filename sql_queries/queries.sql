use Osha
select * from osha_fatalities

-- 1️. What is the yearly trend of fatal incidents?
-- Purpose: To analyze how fatalities have evolved over the years.

SELECT 
    YEAR(incident_date) AS Year,
    COUNT(*) AS Total_Incidents
FROM osha_fatalities
GROUP BY YEAR(incident_date)
ORDER BY Year;

-- 2️. Which day of the week records the highest fatalities?
-- Purpose: Identify the riskiest workdays for targeted safety measures.

SELECT 
    day_of_week,
    COUNT(*) AS Total_Incidents
FROM osha_fatalities
GROUP BY day_of_week
ORDER BY Total_Incidents DESC;

-- 3️. Top 10 states with the highest fatalities
-- Purpose: To know where fatalities are most concentrated geographically.

SELECT TOP 10 
    state,
    COUNT(*) AS Total_Incidents
FROM osha_fatalities
GROUP BY state
ORDER BY Total_Incidents DESC;

-- 4️. Top 10 cities with the highest fatalities
-- Purpose: To spot local clusters of workplace accidents.

SELECT TOP 10 
    city,
    COUNT(*) AS Total_Incidents
FROM osha_fatalities
GROUP BY city
ORDER BY Total_Incidents DESC;

-- 5️. Which types of incidents appear most often in the description? (keyword search: "fall")
-- Purpose: Detect frequent accident causes from narrative data.

SELECT 
    COUNT(*) AS Fall_Incidents
FROM osha_fatalities
WHERE description LIKE '%fall%';

-- 6️. Distribution of fatalities by month
-- Purpose: To find seasonal patterns in workplace accidents.

SELECT 
    DATENAME(MONTH, incident_date) AS Month,
    COUNT(*) AS Total_Incidents
FROM osha_fatalities
GROUP BY DATENAME(MONTH, incident_date), MONTH(incident_date)
ORDER BY MONTH(incident_date);

-- 7️. Which states have the highest percentage of “unknown” safety plans?
-- Purpose: Highlight reporting and compliance weaknesses.

SELECT 
    state,
    COUNT(*) AS Total_Incidents,
    SUM(CASE WHEN [plan] = 'unknown' THEN 1 ELSE 0 END) AS Unknown_Plans,
    CAST(100.0 * SUM(CASE WHEN [plan] = 'unknown' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS Unknown_Percentage
FROM osha_fatalities
GROUP BY state
ORDER BY Unknown_Percentage DESC;

-- 8️. Year-over-year growth rate in fatalities
-- Purpose: To evaluate if fatalities are increasing or decreasing annually.

WITH Yearly AS (
    SELECT YEAR(incident_date) AS Year, COUNT(*) AS Total
    FROM osha_fatalities
    GROUP BY YEAR(incident_date)
)
SELECT 
    Year,
    Total,
    LAG(Total) OVER (ORDER BY Year) AS Prev_Year,
    (Total - LAG(Total) OVER (ORDER BY Year)) * 100.0 / LAG(Total) OVER (ORDER BY Year) AS Growth_Rate_Percent
FROM Yearly
ORDER BY Year;

-- 9️⃣ Which states report the most “falls from ladders”?
-- Purpose: Narrow down high-risk regions for ladder-related incidents.

SELECT 
    state,
    COUNT(*) AS Ladder_Falls
FROM osha_fatalities
WHERE description LIKE '%ladder%'
GROUP BY state
ORDER BY Ladder_Falls DESC;

-- 10.  Most common causes of incidents (keyword frequency: fall, struck, collapse, heat, electrocution)
-- Purpose: Categorize causes based on keywords.

SELECT 
    SUM(CASE WHEN description LIKE '%fall%' THEN 1 ELSE 0 END) AS Fall_Incidents,
    SUM(CASE WHEN description LIKE '%struck%' THEN 1 ELSE 0 END) AS Struck_Incidents,
    SUM(CASE WHEN description LIKE '%collapse%' THEN 1 ELSE 0 END) AS Collapse_Incidents,
    SUM(CASE WHEN description LIKE '%heat%' THEN 1 ELSE 0 END) AS Heat_Incidents,
    SUM(CASE WHEN description LIKE '%electrocution%' THEN 1 ELSE 0 END) AS Electrocution_Incidents
FROM osha_fatalities;

-- 1️1. What percentage of incidents have missing citations?
-- Purpose: Assess data completeness and enforcement.

SELECT 
    COUNT(*) AS Total_Incidents,
    SUM(CASE WHEN citation = 'unknown' THEN 1 ELSE 0 END) AS Unknown_Citations,
    CAST(100.0 * SUM(CASE WHEN citation = 'unknown' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS Unknown_Citation_Percentage
FROM osha_fatalities;

-- 1️2. Identify peak accident periods (quarterly analysis)
-- Purpose: Detect high-risk times of the year.

SELECT 
    YEAR(incident_date) AS Year,
    DATEPART(QUARTER, incident_date) AS Quarter,
    COUNT(*) AS Total_Incidents
FROM osha_fatalities
GROUP BY YEAR(incident_date), DATEPART(QUARTER, incident_date)
ORDER BY Year, Quarter;

-- 1️3. Top 5 states with “heat” related incidents
-- Purpose: To identify regions with high heat-stress accidents.

SELECT TOP 5
    state,
    COUNT(*) AS Heat_Incidents
FROM osha_fatalities
WHERE description LIKE '%heat%'
GROUP BY state
ORDER BY Heat_Incidents DESC;

-- 1️4. Ranking states by fatality density (per year average)
-- Purpose: Normalize fatalities by time span for fair comparison.

WITH StateYearly AS (
    SELECT state, YEAR(incident_date) AS Year, COUNT(*) AS Total
    FROM osha_fatalities
    GROUP BY state, YEAR(incident_date)
)
SELECT 
    state,
    AVG(Total) AS Avg_Incidents_Per_Year
FROM StateYearly
GROUP BY state
ORDER BY Avg_Incidents_Per_Year DESC;

-- 1️5. Detect multi-incident cities (cities with > 50 fatalities)
-- Purpose: Highlight hotspot cities for workplace safety.

SELECT 
    city,
    COUNT(*) AS Total_Incidents
FROM osha_fatalities
GROUP BY city
HAVING COUNT(*) > 50
ORDER BY Total_Incidents DESC;

-- 1️6. Earliest and latest recorded incidents in the dataset
-- Purpose: Define dataset coverage for analysis.

SELECT 
    MIN(incident_date) AS Earliest_Incident,
    MAX(incident_date) AS Latest_Incident
FROM osha_fatalities;

-- 1️7 Top 5 most common words in descriptions (excluding stopwords) (requires string_split)
-- Purpose: To extract frequent terms for text analysis.

WITH Words AS (
    SELECT LTRIM(RTRIM(value)) AS Word
    FROM osha_fatalities
    CROSS APPLY STRING_SPLIT(description, ' ')
    WHERE value NOT IN ('the','a','an','and','of','on','in','at','to','was')
)
SELECT TOP 5 
    Word,
    COUNT(*) AS Frequency
FROM Words
GROUP BY Word
ORDER BY Frequency DESC;

-- 1️8. Which states consistently appear in the top 5 fatalities each year?
-- Purpose: Identify persistently high-risk states.

WITH RankedStates AS (
    SELECT 
        YEAR(incident_date) AS Year,
        state,
        COUNT(*) AS Total_Incidents,
        RANK() OVER (PARTITION BY YEAR(incident_date) ORDER BY COUNT(*) DESC) AS Rank_Incidents
    FROM osha_fatalities
    GROUP BY YEAR(incident_date), state
)
SELECT state, COUNT(DISTINCT Year) AS Years_In_Top5
FROM RankedStates
WHERE Rank_Incidents <= 5
GROUP BY state
ORDER BY Years_In_Top5 DESC;

-- 1️9. Longest streak of incidents on the same day of week
-- Purpose: To test if a specific day is repeatedly risky.

SELECT 
    day_of_week,
    COUNT(*) AS Total_Incidents
FROM osha_fatalities
GROUP BY day_of_week
ORDER BY Total_Incidents DESC;


-- 2️0. How many incidents mention both “roof” and “fall”?
-- Purpose: To study dangerous combinations of risk factors.

SELECT 
    COUNT(*) AS Roof_Fall_Incidents
FROM osha_fatalities
WHERE description LIKE '%roof%' AND description LIKE '%fall%';

-- 2️1. Average incidents per weekday vs. weekend
-- Purpose: Compare weekday vs. weekend safety outcomes.

SELECT 
    CASE 
        WHEN day_of_week IN ('saturday','sunday') THEN 'Weekend'
        ELSE 'Weekday'
    END AS Day_Type,
    COUNT(*) AS Total_Incidents
FROM osha_fatalities
GROUP BY CASE 
             WHEN day_of_week IN ('saturday','sunday') THEN 'Weekend'
             ELSE 'Weekday'
           END;

-- 2️2. Rolling 12-month fatalities trend
-- Purpose: Smooth time-series for trend detection.

WITH Monthly AS (
    SELECT 
        YEAR(incident_date) AS Yr,
        MONTH(incident_date) AS Mo,
        COUNT(*) AS Total
    FROM osha_fatalities
    GROUP BY YEAR(incident_date), MONTH(incident_date)
)
SELECT 
    Yr,
    Mo,
    Total,
    SUM(Total) OVER (ORDER BY Yr, Mo ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS Rolling_12M
FROM Monthly
ORDER BY Yr, Mo;

-- 2️3. Which states report incidents but mostly have “unknown” citations?
-- Purpose: Pinpoint poor enforcement or missing follow-ups.

SELECT 
    state,
    COUNT(*) AS Total,
    SUM(CASE WHEN citation = 'unknown' THEN 1 ELSE 0 END) AS Unknown_Citations,
    CAST(100.0 * SUM(CASE WHEN citation = 'unknown' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS Percent_Unknown
FROM osha_fatalities
GROUP BY state
ORDER BY Percent_Unknown DESC;


-- 2️4. Which 5 years had the most fatalities overall?
-- Purpose: Benchmark extreme years for deeper study.

SELECT TOP 5
    YEAR(incident_date) AS Year,
    COUNT(*) AS Total_Incidents
FROM osha_fatalities
GROUP BY YEAR(incident_date)
ORDER BY Total_Incidents DESC;


-- 2️5. Incidents mentioning “scaffold” by year
-- Purpose: Track scaffold-related accidents over time.

SELECT 
    YEAR(incident_date) AS Year,
    COUNT(*) AS Scaffold_Incidents
FROM osha_fatalities
WHERE description LIKE '%scaffold%'
GROUP BY YEAR(incident_date)
ORDER BY Year;







