# Complete Technical Documentation -- Ride Operations and Revenue Optimization Analysis(All Problems + Data Cleaning)

## 📌 Project Description

This document contains the FULL technical documentation of the Uber
Operational SQL Project including: - Data Cleaning Process - Database
Design - ALL Capstone Problems (as per guideline) - SQL Queries -
Technical Explanation - Business Insights - Indexes, Views, and Trigger
Documentation

------------------------------------------------------------------------

# 🧹 DATA CLEANING PROCESS (STEP-BY-STEP)

## Step 1: Handling Missing Values

### SQL Query:

DELETE FROM city WHERE population IS NULL;
DELETE FROM driver WHERE driver_id IS NULL;
DELETE FROM payment WHERE fare IS NULL;
DELETE FROM rides WHERE ride_id IS NULL;
DELETE FROM rides WHERE fare IS NULL;
```

### Explanation:

-   Removed NULL values in critical columns like fare, ride_id, and
    population
-   Prevents incorrect joins and wrong aggregations
-   Ensures data reliability before analysis

### Business Impact:

Improves accuracy of revenue, demand, and performance analysis.

------------------------------------------------------------------------

## Step 2: Duplicate Removal Using CTE

### SQL Query:

WITH CTE AS (
    SELECT 
        ride_id, 
        ROW_NUMBER() OVER (PARTITION BY ride_id ORDER BY (SELECT NULL)) AS RowNum
    FROM rides
)
DELETE FROM rides
WHERE ride_id IN (
    SELECT ride_id FROM CTE WHERE RowNum > 1
);
```

### Explanation:

-   ROW_NUMBER identifies duplicate ride_ids
-   Keeps only the first unique record
-   Industry-standard deduplication technique

------------------------------------------------------------------------

## Step 3: Primary Key Creation

### SQL Query:

ALTER TABLE rides ADD CONSTRAINT pk_ride_id PRIMARY KEY (ride_id);
ALTER TABLE driver ADD CONSTRAINT pk_driver_id PRIMARY KEY (driver_id);
ALTER TABLE payment ADD CONSTRAINT pk_payment_id PRIMARY KEY (payment_id);
ALTER TABLE city ADD CONSTRAINT pk_city_id PRIMARY KEY (city_id);
```

### Explanation:

-   Enforces uniqueness
-   Improves indexing and query speed
-   Maintains entity integrity

------------------------------------------------------------------------

## Step 4: Foreign Key Relationship

### SQL Query:

ALTER TABLE rides WITH NOCHECK
ADD CONSTRAINT fk_driver_id FOREIGN KEY (driver_id)
REFERENCES driver(driver_id);
```

### Explanation:

-   Links rides and driver tables
-   Ensures referential integrity

------------------------------------------------------------------------

# 📊 CAPSTONE PROBLEM 1: City-Level Performance Optimization

## Objective:

Identify top 3 cities for driver recruitment based on demand, ratings,
and cancellations.

### SQL Query:


SELECT TOP 3
    end_city, 
    COUNT(ride_id) AS total_rides,
    AVG(CAST(rating AS FLOAT)) AS avg_driver_rating,
    (CAST(COUNT(CASE WHEN ride_status = 'Cancelled' THEN 1 END) AS FLOAT) / COUNT(ride_id)) AS cancellation_rate
FROM rides
GROUP BY end_city
ORDER BY total_rides DESC, avg_driver_rating DESC, cancellation_rate ASC;
```

### Technical Explanation:

-   COUNT → measures demand
-   AVG(rating) → service quality
-   Conditional COUNT → cancellation rate

### Business Insight:

High-demand cities with high cancellations need more driver recruitment.

------------------------------------------------------------------------

# 💰 CAPSTONE PROBLEM 2: Revenue Leakage Analysis

## Objective:

Detect completed rides without proper payment.

### SQL Query:

SELECT 
    rides.ride_id, 
    payment.fare, 
    transaction_status,
    ride_status
FROM rides
JOIN payment ON rides.ride_id = payment.ride_id
WHERE transaction_status = 'Pending' AND ride_status = 'Completed';
```

### Explanation:

-   Join between operational and financial data
-   Identifies payment discrepancies

### Business Insight:

Shows financial leakage risk and need for payment reconciliation.

------------------------------------------------------------------------

# ❌ CAPSTONE PROBLEM 3: Cancellation Analysis by City

### SQL Query:


SELECT 
    start_city, 
    COUNT(*) AS cancellation_count, 
    ROUND(SUM(fare), 2) AS revenue_loss
FROM rides
WHERE ride_status = 'Cancelled'
GROUP BY start_city
ORDER BY cancellation_count DESC, revenue_loss DESC;
```

### Explanation:

-   Filters cancelled rides
-   Calculates revenue loss using SUM(fare)

### Business Insight:

High cancellation cities indicate operational inefficiency.

------------------------------------------------------------------------

# ⏰ CAPSTONE PROBLEM 4: Cancellation Patterns by Time of Day

### SQL Query:


SELECT 
    DATEPART(HOUR, start_time) AS hour_of_day,
    COUNT(ride_id) AS total_rides,
    ROUND(CAST(COUNT(CASE WHEN ride_status = 'Cancelled' THEN 1 END) AS FLOAT) / COUNT(ride_id) * 100, 2) AS cancellation_rate,
    SUM(CASE WHEN ride_status = 'Completed' THEN fare ELSE 0 END) AS completed_revenue
FROM rides
GROUP BY DATEPART(HOUR, start_time)
ORDER BY cancellation_rate DESC;
```

### Explanation:

-   DATEPART extracts hour
-   Conditional aggregation for cancellation rate

### Business Insight:

Peak-hour cancellations indicate driver shortages.

------------------------------------------------------------------------

# 📅 CAPSTONE PROBLEM 5: Seasonal Fare Variation

### SQL Query:


SELECT 
    DATEPART(MONTH, ride_date) AS month,
    ROUND(AVG(CAST(fare AS FLOAT)), 2) AS avg_fare,
    MIN(fare) AS min_fare,
    MAX(fare) AS max_fare,
    STDEV(fare) AS fare_variation
FROM rides
GROUP BY DATEPART(MONTH, ride_date)
ORDER BY month;
```

### Explanation:

-   Monthly grouping for seasonal analysis
-   STDEV shows price fluctuation

### Business Insight:

Dynamic pricing influenced by seasonal demand.

------------------------------------------------------------------------

# 🚗 CAPSTONE PROBLEM 6: Average Ride Duration by City

### SQL Query:


SELECT 
    end_city,
    ROUND(AVG(DATEDIFF(MINUTE, start_time, end_time)), 2) AS avg_ride_duration_minutes
FROM rides
GROUP BY end_city
ORDER BY avg_ride_duration_minutes;
```

### Explanation:

-   DATEDIFF calculates trip duration
-   AVG measures operational efficiency

### Business Insight:

Longer durations may indicate traffic or routing inefficiencies.

------------------------------------------------------------------------

# ⚡ ADDITIONAL SQL IMPLEMENTATIONS

## View: Average Fare by City


CREATE VIEW avg_fare_by_city AS
SELECT 
    end_city,
    ROUND(AVG(CAST(fare AS FLOAT)), 2) AS average_fare,
    COUNT(ride_id) AS total_rides
FROM rides
GROUP BY end_city;
```

## View: Driver Performance Metrics


CREATE VIEW driver_performance_metrics AS
SELECT 
    driver_id,
    COUNT(ride_id) AS total_rides,
    ROUND(AVG(CAST(rating AS FLOAT)), 2) AS avg_rating,
    SUM(fare) AS total_earnings,
    ROUND(AVG(CAST(DATEDIFF(MINUTE,start_time, end_time) AS FLOAT)), 2) AS avg_ride_duration
FROM rides
GROUP BY driver_id;
```

------------------------------------------------------------------------

# 🧾 TRIGGER IMPLEMENTATION (ADVANCED)

## Purpose:

Track ride status changes automatically for auditing.

### Logic:

-   AFTER UPDATE trigger
-   Uses inserted (new data) and deleted (old data)
-   Logs status changes into audit table

### Technical Value:

Demonstrates advanced SQL auditing and real-world database monitoring.

------------------------------------------------------------------------

# 🚀 DATABASE OPTIMIZATION

## Index on Ride Date


CREATE NONCLUSTERED INDEX idx_ride_date ON rides(ride_date);
```

## Index on Payment Method


CREATE NONCLUSTERED INDEX idx_payment_method ON rides(payment_method);
```

### Explanation:

-   Improves query performance
-   Faster filtering and reporting

------------------------------------------------------------------------

# 🏁 FINAL CONCLUSION

This project demonstrates complete industry-level SQL workflow: - Data
Cleaning & Validation - Relational Database Design - Advanced SQL
Queries - Views & Triggers - Index Optimization - Business Insight
Generation

Suitable for: Data Analyst \| SQL Developer \| Business Analyst \| BI
Analyst roles
