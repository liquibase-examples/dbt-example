{{ config(
    materialized='table'
) }}

WITH customer_orders AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.total_amount) AS lifetime_value,
        AVG(o.total_amount) AS avg_order_value,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date
    FROM {{ source('public', 'customers') }} c
    LEFT JOIN {{ source('public', 'orders') }} o ON c.customer_id = o.customer_id
    GROUP BY 1, 2, 3, 4
)

SELECT 
    *,
    DATEDIFF('day', first_order_date, last_order_date) AS customer_lifetime_days,
    CASE 
        WHEN lifetime_value > 1000 THEN 'High Value'
        WHEN lifetime_value > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM customer_orders