-- =========================================================
-- E-COMMERCE ORDER & SUPPLY CHAIN ANALYSIS
-- Google BigQuery SQL
-- =========================================================

-- 01. SQL Data Validation
-- Dataset Validation

SELECT
  'orders' AS table_name,
  COUNT(*) AS total_rows
FROM `projek-muhroni-dqlab.ecommerce.orders`

UNION ALL

SELECT
  'order_items',
  COUNT(*)
FROM `projek-muhroni-dqlab.ecommerce.order_items`

UNION ALL

SELECT
  'products',
  COUNT(*)
FROM `projek-muhroni-dqlab.ecommerce.products`

UNION ALL

SELECT
  'customers',
  COUNT(*)
FROM `projek-muhroni-dqlab.ecommerce.customers`

UNION ALL

SELECT
  'payments',
  COUNT(*)
FROM `projek-muhroni-dqlab.ecommerce.payments`;

-- Check Primsry Key in Table Orders & Products

SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT order_id) AS unique_order_id
FROM `projek-muhroni-dqlab.ecommerce.orders`;

SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT product_id) AS unique_product_id
FROM `projek-muhroni-dqlab.ecommerce.products`;

-- 02. Overall Business Performance
-- Overall Business Performance by Status Category Delivered & Canceled

SELECT
  COUNT(DISTINCT o.order_id) AS total_orders,

  COUNTIF(o.order_status = 'delivered') AS delivered_orders,

  COUNTIF(o.order_status = 'canceled') AS canceled_orders,

  ROUND(
    SUM(
      CASE
        WHEN o.order_status = 'delivered'
        THEN oi.price
      END
    ), 2
  ) AS total_product_sales,

  ROUND(
    SUM(
      CASE
        WHEN o.order_status = 'delivered'
        THEN oi.shipping_charges
      END
    ), 2
  ) AS total_shipping_charges,

  ROUND(
    SUM(
      CASE
        WHEN o.order_status = 'delivered'
        THEN oi.order_value
      END
    ), 2
  ) AS total_order_value,

  ROUND(
    AVG(
      CASE
        WHEN o.order_status = 'delivered'
        THEN oi.order_value
      END
    ), 2
  ) AS average_order_value,

  ROUND(
    AVG(
      CASE
        WHEN o.order_status = 'delivered'
        THEN o.delivery_days
      END
    ), 2
  ) AS average_delivery_days

FROM `projek-muhroni-dqlab.ecommerce.orders` o

LEFT JOIN `projek-muhroni-dqlab.ecommerce.order_items` oi
  ON o.order_id = oi.order_id;


-- 03. Analysis Product Sales Performance & Order Trends
-- Monthly Sales Performance

WITH monthly_order_data AS (

  SELECT
    o.order_id,
    FORMAT_DATE('%Y-%m', o.order_purchase_timestamp) AS month_key,
    oi.price,
    oi.order_value,
    o.order_status
  FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

  LEFT JOIN `projek-muhroni-dqlab.ecommerce.order_items` AS oi
    ON o.order_id = oi.order_id
)
SELECT

  FORMAT_DATE('%Y - %B', PARSE_DATE('%Y-%m', month_key)) AS purchase_month,

  COUNT(DISTINCT order_id) AS total_orders,

  ROUND(
    SUM(price),
    2
  ) AS total_sales,

  ROUND(
    AVG(order_value),
    2
  ) AS average_order_value

FROM monthly_order_data

WHERE order_status = 'delivered'

GROUP BY
  month_key

ORDER BY
  PARSE_DATE('%Y-%m', month_key);


-- Monthly Sales Growth

WITH monthly_sales AS (

SELECT
  FORMAT_DATE('%Y-%m', o.order_purchase_timestamp) AS month_key,

  SUM(oi.price) AS total_sales

FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

LEFT JOIN `projek-muhroni-dqlab.ecommerce.order_items` AS oi
ON o.order_id = oi.order_id

WHERE o.order_status = 'delivered'

GROUP BY
  month_key

)

SELECT

  FORMAT_DATE('%Y - %B', PARSE_DATE('%Y-%m', month_key)) AS purchase_month,

  ROUND(total_sales,2) AS total_sales,

  ROUND(
    LAG(total_sales)
    OVER(
      ORDER BY PARSE_DATE('%Y-%m', month_key)
    ),
    2
  ) AS previous_month_sales,

  ROUND(
    SAFE_DIVIDE(
      total_sales -
      LAG(total_sales)
      OVER(
        ORDER BY PARSE_DATE('%Y-%m', month_key)
      ),

      LAG(total_sales)
      OVER(
        ORDER BY PARSE_DATE('%Y-%m', month_key)
      )

    ) * 100,
    2
  ) AS growth_percentage

FROM monthly_sales

ORDER BY PARSE_DATE('%Y-%m', month_key);


-- Day of Week Performance

SELECT

  purchase_day,

  COUNT(DISTINCT o.order_id) AS total_orders,

  ROUND(
    SUM(oi.price),
    2
  ) AS total_sales

FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

LEFT JOIN `projek-muhroni-dqlab.ecommerce.order_items` AS oi

ON o.order_id = oi.order_id

WHERE order_status = 'delivered'

GROUP BY
  purchase_day

ORDER BY
  total_orders DESC;


-- Yearly Sales Performance

SELECT

  purchase_year,

  COUNT(DISTINCT o.order_id) AS total_orders,

  ROUND(
    SUM(oi.price),
    2
  ) AS total_sales

FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

LEFT JOIN `projek-muhroni-dqlab.ecommerce.order_items` AS oi

ON o.order_id = oi.order_id

WHERE order_status = 'delivered'

GROUP BY
  purchase_year

ORDER BY
  purchase_year;


-- Product Category Performance

SELECT
  p.product_category_name,

  COUNT(DISTINCT o.order_id) AS total_orders,

  ROUND(
    SUM(oi.price),
    2
  ) AS total_sales,

  ROUND(
    AVG(oi.price),
    2
  ) AS average_product_price,

  ROUND(
    AVG(oi.order_value),
    2
  ) AS average_order_value

FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

LEFT JOIN `projek-muhroni-dqlab.ecommerce.order_items` AS oi
  ON o.order_id = oi.order_id

LEFT JOIN ecommerce.products AS p
  ON oi.product_id = p.product_id

WHERE o.order_status = 'delivered'

GROUP BY
  p.product_category_name

ORDER BY
  total_sales DESC;


--Top 10 Product Categories by Sales

SELECT
  p.product_category_name,

  COUNT(DISTINCT o.order_id) AS total_orders,

  ROUND(
    SUM(oi.price),
    2
  ) AS total_sales

FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

JOIN `projek-muhroni-dqlab.ecommerce.order_items` AS oi
  ON o.order_id = oi.order_id

JOIN `projek-muhroni-dqlab.ecommerce.products` AS p
  ON oi.product_id = p.product_id

WHERE o.order_status = 'delivered'

GROUP BY
  p.product_category_name

ORDER BY
  total_sales DESC

LIMIT 10;


-- Sales Contribution by Category

WITH category_sales AS (

  SELECT
    p.product_category_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.price) AS total_sales

  FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

  JOIN `projek-muhroni-dqlab.ecommerce.order_items` AS oi
    ON o.order_id = oi.order_id

  JOIN `projek-muhroni-dqlab.ecommerce.products` AS p
    ON oi.product_id = p.product_id

  WHERE o.order_status = 'delivered'

  GROUP BY
    p.product_category_name
)

SELECT
  product_category_name,
  total_orders,

  ROUND(
    total_sales,
    2
  ) AS total_sales,

  ROUND(
    SAFE_DIVIDE(
      total_sales,
      SUM(total_sales) OVER()
    ) * 100,
    2
  ) AS sales_contribution_percent

FROM category_sales

ORDER BY
  total_sales DESC;


-- Category Ranking

WITH category_performance AS (

  SELECT
    p.product_category_name,

    COUNT(DISTINCT o.order_id) AS total_orders,

    SUM(oi.price) AS total_sales

  FROM `projek-muhroni-dqlab.ecommerce.orders` o

  JOIN `projek-muhroni-dqlab.ecommerce.order_items` oi
    ON o.order_id = oi.order_id

  JOIN `projek-muhroni-dqlab.ecommerce.products` p
    ON oi.product_id = p.product_id

  WHERE o.order_status = 'delivered'

  GROUP BY
    p.product_category_name
)

SELECT
  product_category_name,

  total_orders,

  ROUND(total_sales, 2) AS total_sales,

  RANK() OVER(
    ORDER BY total_sales DESC
  ) AS sales_rank,

  RANK() OVER(
    ORDER BY total_orders DESC
  ) AS order_volume_rank

FROM category_performance

ORDER BY
  sales_rank;


-- 04. Delivery & Logistics Performance
-- Overall Delivery Performance

SELECT

  delivery_status,

  COUNT(order_id) AS total_orders,

  ROUND(
    AVG(delivery_days),
    2
  ) AS average_delivery_days

FROM `projek-muhroni-dqlab.ecommerce.orders`

GROUP BY
  delivery_status

ORDER BY
  total_orders DESC;


-- Late Delivery Rate

SELECT

  COUNTIF(delivery_status = 'Late')
  AS late_orders,

  COUNTIF(
    delivery_status IN ('Late','On Time')
  )
  AS completed_deliveries,

  ROUND(

    SAFE_DIVIDE(
      COUNTIF(delivery_status = 'Late'),

      COUNTIF(
        delivery_status IN ('Late','On Time')
      )

    ) * 100,

    2

  ) AS late_delivery_rate

FROM `projek-muhroni-dqlab.ecommerce.orders`;


-- Actual Delivery vs Estimated Delivery

SELECT

  ROUND(
    AVG(
      delivery_days
    ),
    2
  ) AS actual_delivery_days,

  ROUND(
    AVG(
      DATE_DIFF(
        order_estimated_delivery_date,
        DATE(order_purchase_timestamp),
        DAY
      )
    ),
    2
  ) AS estimated_delivery_days

FROM `projek-muhroni-dqlab.ecommerce.orders`

WHERE
  order_status = 'delivered';


-- Delivery Performance by State

SELECT

  c.customer_state,

  COUNT(o.order_id) AS total_orders,

  COUNTIF(
    o.delivery_status = 'Late'
  ) AS late_orders,

  ROUND(

    SAFE_DIVIDE(
      COUNTIF(
        o.delivery_status = 'Late'
      ),
      COUNT(o.order_id)

    ) * 100,

    2

  ) AS late_delivery_rate,

  ROUND(
    AVG(o.delivery_days),
    2
  ) AS avg_delivery_days

FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

JOIN `projek-muhroni-dqlab.ecommerce.customers` AS c

ON o.customer_id = c.customer_id

WHERE
  o.delivery_status != 'Not Delivered'

GROUP BY
  c.customer_state

ORDER BY
  late_delivery_rate DESC;


-- Delivery Performance by State

  SELECT

  c.customer_state,

  COUNT(o.order_id) AS total_orders,

  COUNTIF(
    o.delivery_status = 'Late'
  ) AS late_orders,

  ROUND(

    SAFE_DIVIDE(
      COUNTIF(
        o.delivery_status = 'Late'
      ),
      COUNT(o.order_id)

    ) * 100,

    2

  ) AS late_delivery_rate,

  ROUND(
    AVG(o.delivery_days),
    2
  ) AS avg_delivery_days

FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

JOIN `projek-muhroni-dqlab.ecommerce.customers` AS c

ON o.customer_id = c.customer_id

WHERE
  o.delivery_status != 'Not Delivered'

GROUP BY
  c.customer_state

ORDER BY
  late_delivery_rate DESC;


-- Delivery Trend Over Time

SELECT

  purchase_month,

  COUNT(order_id) AS total_orders,

  ROUND(

    SAFE_DIVIDE(
      COUNTIF(
        delivery_status = 'Late'
      ),

      COUNTIF(
        delivery_status IN ('Late','On Time')
      )

    ) * 100,

    2

  ) AS late_delivery_rate

FROM `projek-muhroni-dqlab.ecommerce.orders`

GROUP BY
  purchase_month

ORDER BY
  purchase_month;

-- 05. Geographic Performance Analysis
-- Customer Distribution by State

SELECT

  c.customer_state,

  COUNT(DISTINCT c.customer_id) AS total_customers,

  COUNT(DISTINCT o.order_id) AS total_orders

FROM `projek-muhroni-dqlab.ecommerce.customers` AS c

JOIN `projek-muhroni-dqlab.ecommerce.orders` AS o

ON c.customer_id = o.customer_id

WHERE
  o.order_status = 'delivered'

GROUP BY
  c.customer_state

ORDER BY
  total_orders DESC;


-- Sales Performance by State

SELECT

  c.customer_state,

  COUNT(DISTINCT o.order_id) AS total_orders,

  ROUND(
    SUM(oi.price),
    2
  ) AS total_sales,

  ROUND(
    AVG(oi.order_value),
    2
  ) AS average_order_value

FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

JOIN `projek-muhroni-dqlab.ecommerce.order_items` AS oi

ON o.order_id = oi.order_id

JOIN `projek-muhroni-dqlab.ecommerce.customers` AS c

ON o.customer_id = c.customer_id

WHERE
  o.order_status = 'delivered'

GROUP BY
  c.customer_state

ORDER BY
  total_sales DESC;


-- Sales Contribution by State

WITH state_sales AS (

SELECT

  c.customer_state,

  SUM(oi.price) AS total_sales

FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

JOIN `projek-muhroni-dqlab.ecommerce.order_items` AS oi

ON o.order_id = oi.order_id

JOIN `projek-muhroni-dqlab.ecommerce.customers` AS c

ON o.customer_id = c.customer_id

WHERE
  o.order_status = 'delivered'

GROUP BY
  c.customer_state

)

SELECT

  customer_state,

  ROUND(total_sales,2) AS total_sales,

  ROUND(

    SAFE_DIVIDE(
      total_sales,
      SUM(total_sales) OVER()
    ) * 100,

    2

  ) AS sales_contribution_percent

FROM state_sales

ORDER BY
  total_sales DESC;


-- Average Order Value by Region

SELECT

  c.customer_state,

  ROUND(
    AVG(oi.order_value),
    2
  ) AS average_order_value,

  COUNT(DISTINCT o.order_id) AS total_orders

FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

JOIN `projek-muhroni-dqlab.ecommerce.order_items` AS oi

ON o.order_id = oi.order_id

JOIN `projek-muhroni-dqlab.ecommerce.customers` AS c

ON o.customer_id = c.customer_id

WHERE
  o.order_status = 'delivered'

GROUP BY
  c.customer_state

HAVING
  total_orders >= 100

ORDER BY
  average_order_value DESC;


-- Regional Delivery Performance

SELECT

  c.customer_state,

  COUNT(o.order_id) AS total_orders,

  COUNTIF(
    o.delivery_status = 'Late'
  ) AS late_orders,

  ROUND(

    SAFE_DIVIDE(
      COUNTIF(
        o.delivery_status = 'Late'
      ),
      COUNTIF(
        o.delivery_status IN ('Late','On Time')
      )
    ) * 100,

    2

  ) AS late_delivery_rate

FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

JOIN `projek-muhroni-dqlab.ecommerce.customers` AS c

ON o.customer_id = c.customer_id

WHERE
  o.delivery_status != 'Not Delivered'

GROUP BY
  c.customer_state

ORDER BY
  late_delivery_rate DESC;

-- 06. Seller Performance Analysis
-- Seller Sales Performance Analysis

SELECT
  oi.seller_id,

  COUNT(DISTINCT o.order_id) AS total_orders,

  ROUND(
    SUM(oi.price),
    2
  ) AS total_sales,

  ROUND(
    AVG(oi.order_value),
    2
  ) AS average_order_value

FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

JOIN `projek-muhroni-dqlab.ecommerce.order_items` AS oi

ON o.order_id = oi.order_id

WHERE
  o.order_status = 'delivered'

GROUP BY
  oi.seller_id

ORDER BY
  total_sales DESC;


-- Top 10 Sellers by Revenue

SELECT

  oi.seller_id,

  COUNT(DISTINCT o.order_id) AS total_orders,

  ROUND(
    SUM(oi.price),
    2
  ) AS total_sales

FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

JOIN `projek-muhroni-dqlab.ecommerce.order_items` AS oi

ON o.order_id = oi.order_id

WHERE
  o.order_status = 'delivered'

GROUP BY
  oi.seller_id

ORDER BY
  total_sales DESC

LIMIT 10;


-- Seller Contribution Percentage Analysis

WITH seller_sales AS (

SELECT

  oi.seller_id,

  SUM(oi.price) AS total_sales

FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

JOIN `projek-muhroni-dqlab.ecommerce.order_items` AS oi

ON o.order_id = oi.order_id

WHERE
  o.order_status = 'delivered'

GROUP BY
  oi.seller_id

)

SELECT

  seller_id,

  ROUND(
    total_sales,
    2
  ) AS total_sales,

  ROUND(

    SAFE_DIVIDE(
      total_sales,
      SUM(total_sales) OVER()
    ) * 100,

    2

  ) AS sales_contribution_percent

FROM seller_sales

ORDER BY
  total_sales DESC;


-- Seller Transaction Volume Ranking Analysis

WITH seller_orders AS (

SELECT

  oi.seller_id,

  COUNT(DISTINCT o.order_id) AS total_orders,

  SUM(oi.price) AS total_sales

FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

JOIN `projek-muhroni-dqlab.ecommerce.order_items` AS oi

ON o.order_id = oi.order_id

WHERE
  o.order_status = 'delivered'

GROUP BY
  oi.seller_id

)

SELECT

  seller_id,

  total_orders,

  ROUND(total_sales,2) AS total_sales,

  RANK() OVER(
    ORDER BY total_orders DESC
  ) AS order_volume_rank

FROM seller_orders

ORDER BY
  order_volume_rank;


-- Seller Delivery Performance Analysis

SELECT

  oi.seller_id,

  COUNT(DISTINCT o.order_id) AS total_orders,

  COUNTIF(
    o.delivery_status = 'Late'
  ) AS late_orders,

  ROUND(

    SAFE_DIVIDE(
      COUNTIF(
        o.delivery_status = 'Late'
      ),

      COUNTIF(
        o.delivery_status IN ('Late','On Time')
      )

    ) * 100,

    2

  ) AS late_delivery_rate

FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

JOIN `projek-muhroni-dqlab.ecommerce.order_items` AS oi

ON o.order_id = oi.order_id

WHERE
  o.delivery_status != 'Not Delivered'

GROUP BY
  oi.seller_id

HAVING
  total_orders >= 50

ORDER BY
  late_delivery_rate DESC;

-- 07. Payment Analysis
-- Payment Method Distribution

SELECT

  payment_type,

  COUNT(DISTINCT order_id) AS total_orders,

  ROUND(
    SUM(payment_value),
    2
  ) AS total_payment_value,

  ROUND(
    AVG(payment_value),
    2
  ) AS average_payment_value

FROM `projek-muhroni-dqlab.ecommerce.payments`

GROUP BY
  payment_type

ORDER BY
  total_orders DESC;


-- Percantage Contribution by Payment Method

WITH payment_summary AS (

SELECT

  payment_type,

  SUM(payment_value) AS total_payment_value

FROM `projek-muhroni-dqlab.ecommerce.payments`

GROUP BY
  payment_type

)

SELECT

  payment_type,

  ROUND(
    total_payment_value,
    2
  ) AS total_payment_value,

  ROUND(

    SAFE_DIVIDE(
      total_payment_value,
      SUM(total_payment_value) OVER()
    ) * 100,

    2

  ) AS contribution_percentage

FROM payment_summary

ORDER BY
  total_payment_value DESC;


-- Payment Installments Behavior Analysis

SELECT

  payment_installments,

  COUNT(DISTINCT order_id) AS total_orders,

  ROUND(
    AVG(payment_value),
    2
  ) AS average_payment_value,

  ROUND(
    SUM(payment_value),
    2
  ) AS total_payment_value


FROM `projek-muhroni-dqlab.ecommerce.payments`

GROUP BY
  payment_installments

ORDER BY
  payment_installments;


-- High Value Transaction by Payment Type

SELECT

  payment_type,

  ROUND(
    MAX(payment_value),
    2
  ) AS highest_transaction,

  ROUND(
    AVG(payment_value),
    2
  ) AS average_transaction,

  COUNT(order_id) AS total_transactions

FROM `projek-muhroni-dqlab.ecommerce.payments`

GROUP BY
  payment_type

ORDER BY
  highest_transaction DESC;


-- Monthly Payment Trend

WITH monthly_payment AS (

SELECT

  DATE_TRUNC(
    DATE(o.order_purchase_timestamp),
    MONTH
  ) AS month_date,

  FORMAT_DATE(
    '%Y-%B',
    DATE(o.order_purchase_timestamp)
  ) AS purchase_month,

  p.payment_type,

  SUM(p.payment_value) AS total_payment_value

FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

JOIN `projek-muhroni-dqlab.ecommerce.payments` AS p

ON o.order_id = p.order_id

GROUP BY

  month_date,
  purchase_month,
  payment_type

)

SELECT

  purchase_month,

  payment_type,

  ROUND(
    total_payment_value,
    2
  ) AS total_payment_value

FROM monthly_payment

ORDER BY
  month_date,
  total_payment_value DESC;

-- 08. Advanced Analytics
--     8.1 Customer Spending Segmentation
WITH customer_spending AS (

SELECT

  o.customer_id,

  SUM(p.payment_value) AS total_spending

FROM `projek-muhroni-dqlab.ecommerce.orders` o

JOIN `projek-muhroni-dqlab.ecommerce.payments` p

ON o.order_id = p.order_id

WHERE
  o.order_status = 'delivered'

GROUP BY
  o.customer_id

)

SELECT

CASE

  WHEN total_spending < 100 THEN 'Low Spender'

  WHEN total_spending BETWEEN 100 AND 500 THEN 'Medium Spender'

  ELSE 'High Spender'

END AS spending_segment,

COUNT(customer_id) AS total_customers

FROM customer_spending

GROUP BY
  spending_segment

ORDER BY
  total_customers DESC;


--     8.2 Pareto Analysis
WITH seller_sales AS (
    SELECT
        seller_id,
        SUM(price) AS total_sales
    FROM `projek-muhroni-dqlab.ecommerce.order_items`
    GROUP BY seller_id
),

ranked_sellers AS (
    SELECT
        seller_id,
        total_sales,

        ROW_NUMBER() OVER (
            ORDER BY total_sales DESC
        ) AS seller_rank,

        COUNT(*) OVER () AS total_sellers,

        SUM(total_sales) OVER (
            ORDER BY total_sales DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_sales,

        SUM(total_sales) OVER () AS overall_sales

    FROM seller_sales
)

SELECT
    seller_id,
    total_sales,

    ROUND(
        SAFE_DIVIDE(seller_rank, total_sellers) * 100,
        2
    ) AS cumulative_seller_percentage,

    ROUND(
        SAFE_DIVIDE(cumulative_sales, overall_sales) * 100,
        2
    ) AS cumulative_sales_percentage

FROM ranked_sellers

ORDER BY seller_rank;


--     8.3 Product Ranking Performance
SELECT

  oi.product_id,
  p.product_category_name,
  COUNT(oi.order_id) AS total_orders,

  ROUND(
    SUM(oi.price),
    2
  ) AS total_sales,


  RANK()
  OVER(
    ORDER BY SUM(oi.price) DESC
  ) AS sales_rank

FROM `projek-muhroni-dqlab.ecommerce.order_items` AS oi 

LEFT JOIN `projek-muhroni-dqlab.ecommerce.products` AS p

ON oi.product_id = p.product_id

GROUP BY
  oi.product_id,p. product_category_name

ORDER BY
  sales_rank

LIMIT 20;
