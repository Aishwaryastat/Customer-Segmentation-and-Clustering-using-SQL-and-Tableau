create database project_portfolio;
use project_portfolio;
create table customers_data (
customer_id int,
first_name varchar(20),
last_name varchar(20), 
gender varchar(10),
date_of_birth varchar(50),
job_title varchar(100),
job_industry_category varchar(100),
wealth_segment varchar(100), 
owns_car varchar(100)
);

create table customer_address_data(
customer_id int,
address varchar(200),
postcode int,
state varchar(50),
country varchar(100)
);

create table transaction_data(
transaction_id int, 
customer_id int, 
transaction_date varchar(50),
amount int, 
state varchar(50)
);

set sql_safe_updates=0;
update transaction_data set transaction_date=str_to_date(transaction_date,"%d-%m-%Y");
update customers_data set date_of_birth = str_to_date(date_of_birth,"%m-%d-%Y");
-----------------------------------
-- calculate recency
select c.customer_id, max(transaction_date) as last_purchase_date,
datediff(now(),max(t.transaction_date)) as recency 
from customers_data c 
left join 
transaction_data t on c.customer_id=t.customer_id
group by 
c.customer_id;

-- Calculate Frequency
SELECT
    c.customer_id,
    COUNT(t.transaction_id) AS frequency
FROM
    customers_data c
LEFT JOIN
    transaction_data t ON c.customer_id = t.customer_id
GROUP BY
    c.customer_id;

-- Calculate Monetary Value
SELECT 
    c.customer_id, SUM(t.amount) AS monetary_value
FROM
    customers_data c
        LEFT JOIN
    transaction_data t ON c.customer_id = t.customer_id
GROUP BY c.customer_id;

-- 
-- Create the customer_segment table
CREATE TABLE customer_segment (
    customer_id INT,
    rfm_segment VARCHAR(30)
);

INSERT INTO customer_segment (customer_id, rfm_segment)
SELECT
    customer_id,
    CASE
        WHEN rfm_recency = 4 AND rfm_frequency IN (4, 3) AND rfm_monetary IN (4, 3) THEN 'churned best customer'
        WHEN rfm_recency = 4 AND rfm_frequency IN (2, 1) AND rfm_monetary IN (4, 3) THEN 'lost customer'
        WHEN rfm_recency IN (3, 2) AND rfm_frequency IN (4, 3, 2) AND rfm_monetary IN (4, 3, 2) THEN 'declining customer'
        WHEN rfm_recency IN (3, 2) AND rfm_frequency = 4 AND rfm_monetary = 4 THEN 'slipping best customer'
        WHEN rfm_recency IN (1, 2) AND rfm_frequency IN (1, 2, 3) AND rfm_monetary IN (1, 2, 3) THEN 'active loyal customer'
        WHEN rfm_recency = 1 AND rfm_frequency IN (1, 2) AND rfm_monetary IN (1, 2) THEN 'new customer'
        WHEN rfm_recency = 4 AND rfm_frequency = 4 AND rfm_monetary = 4 THEN 'best customer'
        WHEN rfm_recency IN (4, 3, 2, 1) AND rfm_frequency = 1 AND rfm_monetary = 1 THEN 'one time customer'
        WHEN rfm_recency IN (2, 1) AND rfm_frequency IN (1, 2, 3) AND rfm_monetary IN (2, 3) THEN 'Potential customer'
        ELSE 'customer'
    END AS rfm_segment
FROM (
    WITH rfm AS (
        SELECT
            c.customer_id,
            MAX(t.transaction_date) AS last_purchase_date,
            DATEDIFF(NOW(), MAX(t.transaction_date)) AS recency,
            COUNT(t.transaction_id) AS frequency,
            SUM(t.amount) AS monetary_value
        FROM
            customers_data c
        JOIN
            transaction_data t ON c.customer_id = t.customer_id
        GROUP BY
            c.customer_id
    ),
    rfm_calc AS (
        SELECT
            r.*,
            NTILE(4) OVER (ORDER BY recency) AS rfm_recency,
            NTILE(4) OVER (ORDER BY frequency) AS rfm_frequency,
            NTILE(4) OVER (ORDER BY monetary_value) AS rfm_monetary
        FROM
            rfm r
    )
    SELECT
        *,
        rfm_recency + rfm_frequency + rfm_monetary AS rfm_score
    FROM
        rfm_calc
) AS rfm_tb;

select count(*) from customer_segment;

select distinct(rfm_segment) from customer_segment;

select rfm_segment, count(customer_id) from customer_segment
group by rfm_segment;

alter table customers_data
add column age int ;
UPDATE customers_data
SET age = YEAR(NOW()) - YEAR(date_of_birth) - 
    CASE WHEN DATE_FORMAT(NOW(), '%m%d') < DATE_FORMAT(date_of_birth, '%m%d') THEN 1 ELSE 0 END;
