-- ==========================================================
-- E-COMMERCE ORDER & SUPPLY CHAIN ANALYSIS
-- Looker Studio Dashboard
-- Google BigQuery SQL
-- ==========================================================

-- Create a consolidated view for the Looker Studio dashboard

CREATE OR REPLACE VIEW
`projek-muhroni-dqlab.ecommerce.looker_dashboard`
AS

SELECT
    o.order_id,
    o.customer_id,
    o.order_purchase_timestamp,
    o.order_status,
    o.delivery_status,
    o.delivery_days,
    o.order_estimated_delivery_date,
    o.order_delivered_timestamp,

    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.shipping_charges,
    oi.order_value,

    p.product_category_name,

    c.customer_city,
    c.customer_state,

    pay.payment_type,
    pay.payment_installments,
    pay.payment_value

FROM `projek-muhroni-dqlab.ecommerce.orders` AS o

LEFT JOIN `projek-muhroni-dqlab.ecommerce.order_items` AS oi
    ON o.order_id = oi.order_id

LEFT JOIN `projek-muhroni-dqlab.ecommerce.products` AS p
    ON oi.product_id = p.product_id

LEFT JOIN `projek-muhroni-dqlab.ecommerce.customers` AS c
    ON o.customer_id = c.customer_id

LEFT JOIN `projek-muhroni-dqlab.ecommerce.payments` AS pay
    ON o.order_id = pay.order_id;
