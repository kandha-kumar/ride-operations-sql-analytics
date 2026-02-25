create database uber
use uber
select * from city   --500 rows
select * from driver --500 rows
select * from payment --500 rows
select * from rides  --500 rows

/*Data Cleaning
Before analysis, the dataset will undergo a thorough cleaning process to address issues such
as:
● Handling missing values in critical columns (e.g., fare, ride_id, population).
● Resolving duplicate records.
● Ensuring data consistency across tables (e.g., matching driver ratings with actual ride data)*/

select * from city

--Handling missing values (so deleting the data)
--Deleting the so that there will be no problem when we are giving the relation between tables
delete from city where population is null --53 rows are deleted --447 left

delete from driver where driver_id is null  --27 rows are deleted --473 rows left

delete from payment where fare is null --54 rows are deleted --446 rows left

delete from rides where ride_id is null --25 rows are deleted --475 rows left
delete from rides where fare is null    --52 rows are deleted --423 rows left

--Checking duplicate rows
select distinct * from city   --No duplicated found
select distinct * from driver --No duplicated found
select distinct * from rides  --No duplicated found
select distinct * from payment--No duplicated found

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

---Creating the primary keys

--For rides table
alter table rides 
alter column ride_id nvarchar(255) not null 

alter table rides
add constraint pk_ride_id primary key (ride_id)

--For drivertable
alter table driver
alter column driver_id nvarchar(50) not null 

alter table driver
add constraint pk_driver_id primary key (driver_id)

--For payment table
alter table payment 
alter column payment_id nvarchar(50) not null 

alter table payment
add constraint pk_payment_id primary key (payment_id)

--For city table
alter table city
alter column city_id nvarchar(50) not null 

alter table city
add constraint pk_city_id primary key (city_id)

---Building the relationship between the tables using foreign key
Alter table rides with nocheck
add constraint fk_driver_id foreign key (driver_id)
references driver(driver_id)

---Questions
---City-Level Performance Analysis:
/*
Which are the top 3 cities where Uber should focus more on driver recruitment based on key
metrics such as demand high cancellation rates and driver ratings?
*/
select * from rides
SELECT TOP 3
    end_city, 
    COUNT(ride_id) AS total_rides,
    AVG(CAST(rating AS FLOAT)) AS avg_driver_rating,
    (CAST(COUNT(CASE WHEN ride_status = 'Cancelled' THEN 1 END) AS FLOAT) / COUNT(ride_id)) AS cancellation_rate
FROM 
    rides
GROUP BY 
    end_city
ORDER BY 
    total_rides DESC,
    avg_driver_rating DESC,
    cancellation_rate ASC;
select * from payment


--Revenue Leakage Analysis :
/*
How can you detect rides with fare discrepancies or those marked as "completed" without any
corresponding payment?
*/
SELECT 
    rides.ride_id, 
    payment.fare, 
    transaction_status,
    ride_status
FROM 
    rides
join payment on rides.ride_id=payment.ride_id
WHERE 
    transaction_status = 'Pending' and ride_status = 'Completed' 

select * from rides
---Cancellation Analysis :
/*What are the cancellation patterns across cities and ride categories? How do these patterns
correlate with revenue from completed rides?*/
SELECT 
    start_city, 
    COUNT(*) AS cancellation_count, 
    ROUND(SUM(fare), 2) AS revenue_loss
FROM rides
WHERE ride_status = 'Cancelled'
GROUP BY start_city
ORDER BY cancellation_count DESC, revenue_loss DESC;

--Cancellation Patterns by Time of Day (MS SQL):
/*Analyze the cancellation patterns based on different times of day. Which hours have the highest
cancellation rates, and what is their impact on revenue?*/
SELECT 
    DATEPART(HOUR, start_time) AS hour_of_day,
    COUNT(ride_id) AS total_rides,
    ROUND(CAST(COUNT(CASE WHEN ride_status = 'Cancelled' THEN 1 END) AS FLOAT) / COUNT(ride_id) * 100, 2) AS cancellation_rate,
    SUM(CASE WHEN ride_status = 'Completed' THEN fare ELSE 0 END) AS completed_revenue
FROM 
    rides
GROUP BY 
    DATEPART(HOUR, start_time)
ORDER BY 
    cancellation_rate DESC;

--Seasonal Fare Variations :
/*How do fare amounts vary across different seasons? Identify any significant trends or anomalies
in fare distributions.*/
SELECT 
    DATEPART(MONTH, ride_date) AS month,
    ROUND(AVG(CAST(fare AS FLOAT)), 2) AS avg_fare,
    MIN(fare) AS min_fare,
    MAX(fare) AS max_fare,
    STDEV(fare) AS fare_variation
FROM 
    rides
GROUP BY 
    DATEPART(MONTH, ride_date)
ORDER BY 
    month;

--Average Ride Duration by City :
/*What is the average ride duration for each city? How does this relate to customer satisfaction?*/

SELECT 
    end_city,
    ROUND(AVG(DATEDIFF(MINUTE, start_time, end_time)), 2) AS avg_ride_duration_minutes
FROM 
    rides
GROUP BY 
    end_city
ORDER BY 
    avg_ride_duration_minutes;

--Index for Ride Date:
/*How can query performance be improved when filtering rides by date?*/

CREATE NONCLUSTERED INDEX idx_ride_date 
ON rides(ride_date);

--View for Average Fare by City :
/*How can you quickly access information on average fares for each city?*/

CREATE VIEW avg_fare_by_city AS
SELECT 
    end_city,
    ROUND(AVG(CAST(fare aS FLOAT)), 2) AS average_fare,
    COUNT(ride_id) AS total_rides
FROM 
    rides
GROUP BY 
    end_city;

select * from avg_fare_by_city

--Trigger for Ride Status Change Logging:
/*How can you track changes in ride statuses for auditing purposes?*/
CREATE TABLE ride_status_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    ride_id INT,
    old_status VARCHAR(50),
    new_status VARCHAR(50),
    change_timestamp DATETIME DEFAULT GETDATE()
);

GO

CREATE TRIGGER track_ride_status_changes
ON rides
AFTER UPDATE
AS
BEGIN
    IF UPDATE(ride_status)
    BEGIN
        INSERT INTO ride_status_log (ride_id, old_status, new_status)
        SELECT 
            i.ride_id,
            d.ride_status,
            i.ride_status
        FROM 
            deleted d
            INNER JOIN inserted i ON d.ride_id = i.ride_id
        WHERE 
            d.ride_status != i.ride_status;
    END
END;

--View for Driver Performance Metrics:
/*What performance metrics can be summarized to assess driver efficiency?*/
CREATE VIEW driver_performance_metrics AS
SELECT 
    driver_id,
    COUNT(ride_id) AS total_rides,
    ROUND(AVG(CAST(rating AS FLOAT)), 2) AS avg_rating,
    SUM(fare) AS total_earnings,
    ROUND(AVG(CAST(DATEDIFF(MINUTE,start_time, end_time) AS FLOAT)), 2) AS avg_ride_duration
FROM 
    rides
GROUP BY 
    driver_id;

select * from driver_performance_metrics

select * from rides

--Index on Payment Method:
/*How can you optimize query performance for payment-related queries?*/
CREATE NONCLUSTERED INDEX idx_payment_method 
ON rides(payment_method);