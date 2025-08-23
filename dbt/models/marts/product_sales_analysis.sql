{{ config(
    materialized='table'
) }}

WITH product_sales AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.category,
        p.price AS current_price,
        COUNT(DISTINCT oi.order_id) AS times_ordered,
        SUM(oi.quantity) AS total_quantity_sold,
        SUM(oi.line_total) AS total_revenue,
        AVG(oi.unit_price) AS avg_selling_price
    FROM {{ source('public', 'products') }} p
    LEFT JOIN {{ source('public', 'order_items') }} oi ON p.product_id = oi.product_id
    GROUP BY 1, 2, 3, 4
)

SELECT 
    *,
    total_revenue / NULLIF(total_quantity_sold, 0) AS revenue_per_unit,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
    RANK() OVER (PARTITION BY category ORDER BY total_quantity_sold DESC) AS category_rank
FROM product_sales