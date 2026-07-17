-- EDA STATISTICAL LAYER — Layer 4 (Bivariate) + Layer 5 (Multivariate)

-- LAYER 4 — BIVARIATE

-- 4.1 (BQ A2) Category vs Profitability 
SELECT category_name,
       COUNT(*)                            AS order_items,
       ROUND(SUM(sales), 2)                AS total_sales,
       ROUND(SUM(order_profit_per_order), 2) AS total_profit,
       ROUND(AVG(profit_margin_pct) * 100, 2) AS avg_margin_pct
FROM dataco_supply_chain
GROUP BY category_name
ORDER BY avg_margin_pct ASC;

-- 4.2 (BQ A2) Market vs Profitability
SELECT market,
       COUNT(*)                              AS order_items,
       ROUND(SUM(sales), 2)                  AS total_sales,
       ROUND(SUM(order_profit_per_order), 2) AS total_profit,
       ROUND(AVG(profit_margin_pct) * 100, 2) AS avg_margin_pct
FROM dataco_supply_chain
GROUP BY market
ORDER BY total_profit ASC;

-- 4.3 (BQ A2) Order Region vs Profitability
SELECT order_region,
       COUNT(*)                              AS order_items,
       ROUND(SUM(sales), 2)                  AS total_sales,
       ROUND(SUM(order_profit_per_order), 2) AS total_profit,
       ROUND(AVG(profit_margin_pct) * 100, 2) AS avg_margin_pct
FROM dataco_supply_chain
GROUP BY order_region
ORDER BY total_profit ASC;


-- 4.4 (BQ A3) Discount Rate vs Margin — Pearson correlation coefficient
-- dihitung manual pake formula Pearson

WITH base AS (
    SELECT
        order_item_discount_rate,
        profit_margin_pct,
        ROW_NUMBER() OVER (ORDER BY order_item_discount_rate) AS rn_x,
        ROW_NUMBER() OVER (ORDER BY profit_margin_pct)        AS rn_y
    FROM dataco_supply_chain
),
ranked AS (
    SELECT
        AVG(rn_x) OVER (PARTITION BY order_item_discount_rate) AS rank_x,
        AVG(rn_y) OVER (PARTITION BY profit_margin_pct)        AS rank_y
    FROM base
)
SELECT
    (COUNT(*) * SUM(rank_x * rank_y) - SUM(rank_x) * SUM(rank_y))
    /
    (SQRT(COUNT(*) * SUM(POW(rank_x,2)) - POW(SUM(rank_x),2))
     * SQRT(COUNT(*) * SUM(POW(rank_y,2)) - POW(SUM(rank_y),2)))
    AS spearman_correlation_discount_vs_margin
FROM ranked;


-- 4.5 (BQ A3) Discount Rate bucketed vs avg margin 
SELECT
    CASE
        WHEN order_item_discount_rate < 0.05 THEN '1) 0-5%'
        WHEN order_item_discount_rate < 0.10 THEN '2) 5-10%'
        WHEN order_item_discount_rate < 0.15 THEN '3) 10-15%'
        WHEN order_item_discount_rate < 0.20 THEN '4) 15-20%'
        ELSE '5) 20%+'
    END AS discount_bucket,
    COUNT(*)                               AS order_items,
    ROUND(AVG(profit_margin_pct) * 100, 2) AS avg_margin_pct,
    ROUND(SUM(sales), 2)                   AS total_sales
FROM dataco_supply_chain
GROUP BY discount_bucket
ORDER BY discount_bucket;

-- 4.6 (BQ A5) Overlap Revenue at Risk x Late Delivery Risk
SELECT
    revenue_at_risk_flag,
    late_delivery_risk,
    COUNT(*)                                            AS order_items,
    ROUND(SUM(sales), 2)                                AS total_sales,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)  AS pct_of_total
FROM dataco_supply_chain
GROUP BY revenue_at_risk_flag, late_delivery_risk;

SELECT DISTINCT revenue_at_risk_flag, COUNT(*) FROM dataco_supply_chain GROUP BY revenue_at_risk_flag;

-- 4.7 (BQ A5) Overlap dalam satu angka — % dari RAR yang juga kena telat
SELECT
    ROUND(
        SUM(CASE WHEN revenue_at_risk_flag = 1 AND late_delivery_risk = 1 THEN sales ELSE 0 END)
        / NULLIF(SUM(CASE WHEN revenue_at_risk_flag = 1 THEN sales ELSE 0 END), 0) * 100
    , 2) AS pct_rar_yang_juga_telat_kirim
FROM dataco_supply_chain;

SELECT DISTINCT revenue_at_risk_flag FROM dataco_supply_chain;
SELECT COUNT(*) FROM dataco_supply_chain WHERE revenue_at_risk_flag = 1;

-- 4.8 (BQ B2) Shipping Mode vs Late Delivery Rate & Avg Delay
SELECT shipping_mode,
       COUNT(*)                              AS order_items,
       ROUND(AVG(late_delivery_risk) * 100, 2) AS late_delivery_rate_pct,
       ROUND(AVG(shipping_delay_days), 2)    AS avg_delay_days
FROM dataco_supply_chain
WHERE is_valid_shipping_record = 1 
GROUP BY shipping_mode
ORDER BY late_delivery_rate_pct DESC;

-- 4.9 (BQ B3) Order Region vs Delivery Performance
SELECT order_region,
       COUNT(*)                              AS order_items,
       ROUND(AVG(late_delivery_risk) * 100, 2) AS late_delivery_rate_pct,
       ROUND(AVG(shipping_delay_days), 2)    AS avg_delay_days
FROM dataco_supply_chain
WHERE is_valid_shipping_record = 1 
GROUP BY order_region
ORDER BY late_delivery_rate_pct DESC;

-- 4.10 (BQ B4) Category vs Late Delivery Risk
SELECT category_name,
       COUNT(*)                                AS order_items,
       ROUND(AVG(late_delivery_risk) * 100, 2) AS late_delivery_rate_pct
FROM dataco_supply_chain
WHERE is_valid_shipping_record = 1 
GROUP BY category_name
ORDER BY late_delivery_rate_pct DESC;



-- LAYER 5 — MULTIVARIATE & TIME-BASED

-- 5.1 (BQ A1) Trend bulanan Sales & Profit Margin — exclude periode yang udah
-- di-flag "is_reliable_trend_period = 0" 
SELECT order_year_month,
       COUNT(*)                                AS order_items,
       ROUND(SUM(sales), 2)                    AS total_sales,
       ROUND(SUM(order_profit_per_order), 2)   AS total_profit,
       ROUND(AVG(profit_margin_pct) * 100, 2)  AS avg_margin_pct
FROM dataco_supply_chain
WHERE is_reliable_trend_period = 1
GROUP BY order_year_month
ORDER BY order_year_month;
-- self review: sama kayak dibawah
	
-- 5.2 (BQ B1) Trend bulanan On-Time Delivery Rate
SELECT order_year_month,
       COUNT(*)                                     AS order_items,
       ROUND((1 - AVG(late_delivery_risk)) * 100, 2) AS on_time_delivery_rate_pct
FROM dataco_supply_chain
WHERE is_reliable_trend_period = 1
GROUP BY order_year_month
ORDER BY order_year_month;

-- 5.3 Multivariate: Category x Region x Profit — 20 kombinasi paling rugi
SELECT category_name, order_region,
       COUNT(*)                                AS order_items,
       ROUND(SUM(sales), 2)                    AS total_sales,
       ROUND(SUM(order_profit_per_order), 2)   AS total_profit,
       ROUND(AVG(profit_margin_pct) * 100, 2)  AS avg_margin_pct
FROM dataco_supply_chain
GROUP BY category_name, order_region
ORDER BY total_profit ASC
LIMIT 10;

-- 5.4 Multivariate: Shipping Mode x Region x Late Delivery — 20 kombinasi paling parah
SELECT shipping_mode, order_region,
       COUNT(*)                                AS order_items,
       ROUND(AVG(late_delivery_risk) * 100, 2) AS late_delivery_rate_pct,
       ROUND(AVG(shipping_delay_days), 2)      AS avg_delay_days
FROM dataco_supply_chain
GROUP BY shipping_mode, order_region
ORDER BY late_delivery_rate_pct DESC
LIMIT 10;

-- 5.5 HYPOTHESIS TEST yang mana nguji "apakah late delivery beneran berhubungan sama
-- discount tinggi/margin rendah, atau dua isu yang berdiri sendiri?" based on framing business problem
SELECT late_delivery_risk,
       COUNT(*)                                    AS order_items,
       ROUND(AVG(order_item_discount_rate) * 100, 2) AS avg_discount_rate_pct,
       ROUND(AVG(profit_margin_pct) * 100, 2)      AS avg_margin_pct,
       ROUND(AVG(order_profit_per_order), 2)       AS avg_profit_per_order
FROM dataco_supply_chain
GROUP BY late_delivery_risk;
-- yg mana kalo avg_discount_rate_pct & avg_margin_pct beda jauh antara
-- late_delivery_risk=0 vs =1, hipotesis "delay ikut gerus margin" tapi kalau angkanya mirip, berarti dua
-- masalah ini sendiri2 ga terkait alias isu terpisah, prioritas beda