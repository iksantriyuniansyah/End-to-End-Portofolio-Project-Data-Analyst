-- EDA STATISTICAL LAYER — DataCo Supply Chain: Business Risk & Logistics Optimization
-- Layer 2 (Profiling) + Layer 3 (Univariate)

-- LAYER 2 — PROFILING 

-- 2.1 Row count & rentang waktu analisis
SELECT
    COUNT(*)                                   AS total_rows,
    MIN(order_date)                            AS earliest_order,
    MAX(order_date)                            AS latest_order,
    DATEDIFF(MAX(order_date), MIN(order_date)) AS date_span_days
FROM dataco_supply_chain;

-- 2.2 Grain check 
SELECT
    COUNT(*)                                            AS total_rows,
    COUNT(DISTINCT order_id)                            AS distinct_orders,
    ROUND(COUNT(*) / COUNT(DISTINCT order_id), 2)       AS avg_items_per_order
FROM dataco_supply_chain;

-- 2.3 Cardinality kolom kategorikal
SELECT 'category_name' AS column_name, COUNT(DISTINCT category_name) AS cardinality FROM dataco_supply_chain
UNION ALL
SELECT 'order_region',   COUNT(DISTINCT order_region)   FROM dataco_supply_chain
UNION ALL
SELECT 'market',          COUNT(DISTINCT market)          FROM dataco_supply_chain
UNION ALL
SELECT 'shipping_mode',   COUNT(DISTINCT shipping_mode)   FROM dataco_supply_chain
UNION ALL
SELECT 'order_status',    COUNT(DISTINCT order_status)    FROM dataco_supply_chain
UNION ALL
SELECT 'customer_segment',COUNT(DISTINCT customer_segment) FROM dataco_supply_chain;



-- LAYER 3 — UNIVARIATE: NUMERIC VARIABLES
-- Central tendency + dispersion

-- 3.1 Basic statistics (MIN, MAX, MEAN, STDDEV, Coefficient of Variation)

SELECT 'sales' AS variable,
       ROUND(MIN(sales), 2)  AS min_val,
       ROUND(MAX(sales), 2)  AS max_val,
       ROUND(AVG(sales), 2)  AS mean_val,
       ROUND(STDDEV(sales), 2) AS stddev_val,
       ROUND(STDDEV(sales) / NULLIF(AVG(sales), 0), 3) AS coef_variation
FROM dataco_supply_chain
UNION ALL
SELECT 'order_profit_per_order',
       ROUND(MIN(order_profit_per_order), 2),
       ROUND(MAX(order_profit_per_order), 2),
       ROUND(AVG(order_profit_per_order), 2),
       ROUND(STDDEV(order_profit_per_order), 2),
       ROUND(STDDEV(order_profit_per_order) / NULLIF(AVG(order_profit_per_order), 0), 3)
FROM dataco_supply_chain
UNION ALL
SELECT 'profit_margin_pct',
       ROUND(MIN(profit_margin_pct), 4),
       ROUND(MAX(profit_margin_pct), 4),
       ROUND(AVG(profit_margin_pct), 4),
       ROUND(STDDEV(profit_margin_pct), 4),
       ROUND(STDDEV(profit_margin_pct) / NULLIF(AVG(profit_margin_pct), 0), 3)
FROM dataco_supply_chain
UNION ALL
SELECT 'order_item_discount_rate',
       ROUND(MIN(order_item_discount_rate), 4),
       ROUND(MAX(order_item_discount_rate), 4),
       ROUND(AVG(order_item_discount_rate), 4), 
       ROUND(STDDEV(order_item_discount_rate), 4),
       ROUND(STDDEV(order_item_discount_rate) / NULLIF(AVG(order_item_discount_rate), 0), 3)
FROM dataco_supply_chain
UNION ALL
SELECT 'shipping_delay_days',
       ROUND(MIN(shipping_delay_days), 2),
       ROUND(MAX(shipping_delay_days), 2),
       ROUND(AVG(shipping_delay_days), 2),
       ROUND(STDDEV(shipping_delay_days), 2),
       ROUND(STDDEV(shipping_delay_days) / NULLIF(AVG(shipping_delay_days), 0), 3)
FROM dataco_supply_chain;


-- 3.2 MEDIAN + QUARTILE (IQR) — dipake buat deteksi skewness & outlier 

WITH ranked_sales AS (
    SELECT
        sales,
        ROW_NUMBER() OVER (ORDER BY sales) AS rn,
        COUNT(*)     OVER ()               AS total_n,
        NTILE(4)     OVER (ORDER BY sales) AS quartile_bucket
    FROM dataco_supply_chain
)
SELECT
    (SELECT ROUND(AVG(sales), 2) FROM ranked_sales
     WHERE rn IN (FLOOR((total_n + 1) / 2), CEIL((total_n + 1) / 2)))  AS median_val,
    (SELECT ROUND(MAX(sales), 2) FROM ranked_sales WHERE quartile_bucket = 1) AS q1_approx,
    (SELECT ROUND(MAX(sales), 2) FROM ranked_sales WHERE quartile_bucket = 3) AS q3_approx,
    (SELECT ROUND(MAX(sales), 2) FROM ranked_sales WHERE quartile_bucket = 3)
      - (SELECT ROUND(MAX(sales), 2) FROM ranked_sales WHERE quartile_bucket = 1) AS iqr_approx;

WITH ranked_profit AS (
    SELECT order_profit_per_order AS val,
           ROW_NUMBER() OVER (ORDER BY order_profit_per_order) AS rn,
           COUNT(*) OVER () AS total_n,
           NTILE(4) OVER (ORDER BY order_profit_per_order) AS quartile_bucket
    FROM dataco_supply_chain
)
SELECT
    (SELECT ROUND(AVG(val), 2) FROM ranked_profit
     WHERE rn IN (FLOOR((total_n + 1) / 2), CEIL((total_n + 1) / 2))) AS median_val,
    (SELECT ROUND(MAX(val), 2) FROM ranked_profit WHERE quartile_bucket = 1) AS q1_approx,
    (SELECT ROUND(MAX(val), 2) FROM ranked_profit WHERE quartile_bucket = 3) AS q3_approx;

WITH ranked_margin AS (
    SELECT profit_margin_pct AS val,
           ROW_NUMBER() OVER (ORDER BY profit_margin_pct) AS rn,
           COUNT(*) OVER () AS total_n,
           NTILE(4) OVER (ORDER BY profit_margin_pct) AS quartile_bucket
    FROM dataco_supply_chain
)
SELECT
    (SELECT ROUND(AVG(val), 4) FROM ranked_margin
     WHERE rn IN (FLOOR((total_n + 1) / 2), CEIL((total_n + 1) / 2))) AS median_val,
    (SELECT ROUND(MAX(val), 4) FROM ranked_margin WHERE quartile_bucket = 1) AS q1_approx,
    (SELECT ROUND(MAX(val), 4) FROM ranked_margin WHERE quartile_bucket = 3) AS q3_approx;

WITH ranked_discount AS (
    SELECT order_item_discount_rate AS val,
           ROW_NUMBER() OVER (ORDER BY order_item_discount_rate) AS rn,
           COUNT(*) OVER () AS total_n,
           NTILE(4) OVER (ORDER BY order_item_discount_rate) AS quartile_bucket
    FROM dataco_supply_chain
)
SELECT
    (SELECT ROUND(AVG(val), 4) FROM ranked_discount
     WHERE rn IN (FLOOR((total_n + 1) / 2), CEIL((total_n + 1) / 2))) AS median_val,
    (SELECT ROUND(MAX(val), 4) FROM ranked_discount WHERE quartile_bucket = 1) AS q1_approx,
    (SELECT ROUND(MAX(val), 4) FROM ranked_discount WHERE quartile_bucket = 3) AS q3_approx;


WITH ranked_delay AS (
    SELECT shipping_delay_days AS val,
           ROW_NUMBER() OVER (ORDER BY shipping_delay_days) AS rn,
           COUNT(*) OVER () AS total_n,
           NTILE(4) OVER (ORDER BY shipping_delay_days) AS quartile_bucket
    FROM dataco_supply_chain
)
SELECT
    (SELECT ROUND(AVG(val), 2) FROM ranked_delay
     WHERE rn IN (FLOOR((total_n + 1) / 2), CEIL((total_n + 1) / 2))) AS median_val,
    (SELECT ROUND(MAX(val), 2) FROM ranked_delay WHERE quartile_bucket = 1) AS q1_approx,
    (SELECT ROUND(MAX(val), 2) FROM ranked_delay WHERE quartile_bucket = 3) AS q3_approx;


-- LAYER 3 — UNIVARIATE: CATEGORICAL VARIABLES
-- Frekuensi distribusimya

-- 3.3 Category Name
SELECT
    category_name,
    COUNT(*)                                              AS freq,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)    AS pct_of_total
FROM dataco_supply_chain
GROUP BY category_name
ORDER BY freq DESC;

-- 3.4 Order Region
SELECT
    order_region,
    COUNT(*)                                           AS freq,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM dataco_supply_chain
GROUP BY order_region
ORDER BY freq DESC;

-- 3.5 Shipping Mode
SELECT
    shipping_mode,
    COUNT(*)                                           AS freq,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM dataco_supply_chain
GROUP BY shipping_mode
ORDER BY freq DESC;

-- 3.6 Order Status 
SELECT
    order_status,
    COUNT(*)                                           AS freq,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM dataco_supply_chain
GROUP BY order_status
ORDER BY freq DESC;

-- 3.7 Binary rate — Late Delivery Risk (basis KPI On-Time Delivery Rate)
SELECT
    late_delivery_risk,
    COUNT(*)                                           AS freq,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM dataco_supply_chain
GROUP BY late_delivery_risk;

-- 3.8 Binary rate — Revenue at Risk Flag (basis KPI 3) 
SELECT
    revenue_at_risk_flag,
    COUNT(*)                                           AS freq,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total,
    ROUND(SUM(sales), 2)                               AS total_sales_in_bucket
FROM dataco_supply_chain
GROUP BY revenue_at_risk_flag;

SELECT
    category_name,
    SUM(sales)                                        AS category_sales,
    ROUND(SUM(sales) * 100.0 / (SELECT SUM(sales) FROM dataco_supply_chain), 2) AS pct_of_total
FROM dataco_supply_chain
GROUP BY category_name
ORDER BY category_sales DESC
LIMIT 10;

SELECT COUNT(DISTINCT order_region) as tot
FROM dataco_supply_chain;