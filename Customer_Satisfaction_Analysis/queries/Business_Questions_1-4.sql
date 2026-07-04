-- Business Question 1: "Apakah tren review score terutama satisfaction membaik, memburuk, atau stagnan dari 2017-2018?"
-- Line chart: MoM Review Score Trend
SELECT
    DATE_FORMAT(r.review_creation_date, '%Y-%m')                								AS review_month,
    COUNT(r.review_id)                                          								AS total_reviews,
    ROUND(AVG(r.review_score), 3)                               								AS avg_review_score,
    ROUND(SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(r.review_id), 2)	AS detractor_rate_percentage,
    ROUND(SUM(CASE WHEN r.review_score >= 4 THEN 1 ELSE 0 END) * 100.0 / COUNT(r.review_id), 2)	AS promoter_rate_percentage
FROM order_reviews r
JOIN orders o 
	ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
	AND r.review_creation_date >= '2017-01-01'  -- saya mengambil mulai dari tahun 2017 tidak 2016 karena sample dirasa terlalu kecil
GROUP BY review_month
ORDER BY review_month;


-- Business Question 2: "Kategori produk mana yang punya Detractor Rate tertinggi?"
-- Horizontal bar: Top Detractor Rate by Category

WITH order_category AS (
    SELECT DISTINCT
        o.order_id,
        p.product_category_name_english
    FROM orders o
    JOIN order_items oi ON o.order_id    = oi.order_id
    JOIN products p     ON oi.product_id = p.product_id
    WHERE o.order_status                  = 'delivered'
      AND o.data_quality_flag = 'CLEAN'         
      AND p.product_category_name_english IS NOT NULL	
      AND TRIM(p.product_category_name_english) != ''
)
SELECT
    oc.product_category_name_english                                                            AS category,
    COUNT(DISTINCT oc.order_id)                                                                  AS total_orders,
    ROUND(AVG(r.review_score), 3)                                                                AS avg_review_score,
    ROUND(SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(r.review_id), 2)	AS detractor_rate_percentage,
    ROUND(SUM(CASE WHEN r.review_score >= 4 THEN 1 ELSE 0 END) * 100.0 / COUNT(r.review_id), 2)   AS promoter_rate_percentage
FROM order_category oc
JOIN order_reviews r ON oc.order_id = r.order_id
GROUP BY oc.product_category_name_english
HAVING COUNT(DISTINCT oc.order_id) >= 100
ORDER BY detractor_rate_percentage DESC
LIMIT 10;


-- Business Question 3: "Seberapa besar dampak delivery delay terhadap review score?"
-- Horizontal bar: Avg Review Score per Delay Bucket
SELECT
    o.delay_bucket,
    COUNT(r.review_id)                                          								AS total_reviews,
    ROUND(AVG(r.review_score), 3)                               								AS avg_review_score,
    ROUND(STDDEV_POP(r.review_score), 3)                        								AS std_dev_score,
    ROUND(SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(r.review_id), 2)	AS detractor_rate_percentage, 
    ROUND(SUM(CASE WHEN r.review_score >= 4 THEN 1 ELSE 0 END) * 100.0 / COUNT(r.review_id), 2) AS promoter_rate_percentage,
	-- Breakdown satisfaction tier count per bucket
	SUM(CASE WHEN r.satisfaction_tier = 'Promoter'  THEN 1 ELSE 0 END)                     		AS promoter_total,
    SUM(CASE WHEN r.satisfaction_tier = 'Passive'   THEN 1 ELSE 0 END)                     		AS passive_total,
    SUM(CASE WHEN r.satisfaction_tier = 'Detractor' THEN 1 ELSE 0 END)                     		AS detractor_total
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.data_quality_flag = 'CLEAN'   
  AND o.delay_bucket != 'No Data'
GROUP BY o.delay_bucket
ORDER BY FIELD(o.delay_bucket, 'On-Time','Late 1-3 Days','Late 4-7 Days','Late >7 Days');


-- Business Question 4: Repeat Purchase Rate by Satisfaction Tier
-- Bar chart: Repeat Purchase Rate by Satisfaction Tier
WITH customer_first_order AS (
    SELECT
        c.customer_unique_id,
        MIN(o.purchase_date)                                    AS first_order_date,
        COUNT(DISTINCT o.order_id)                              AS total_orders
    FROM orders o
    JOIN customers c 
		ON o.customer_id = c.customer_id
    WHERE o.order_status      = 'delivered'
      AND o.data_quality_flag = 'CLEAN'
    GROUP BY c.customer_unique_id
)
SELECT
    r.satisfaction_tier                                         AS satisfaction_tier,
    COUNT(DISTINCT cfo.customer_unique_id)                      AS total_unique_customers,
    SUM(CASE WHEN cfo.total_orders > 1 THEN 1 ELSE 0 END)		AS repeat_customers,
    SUM(CASE WHEN cfo.total_orders = 1 THEN 1 ELSE 0 END)      	AS one_time_order_customers,
    ROUND(SUM(CASE WHEN cfo.total_orders > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT cfo.customer_unique_id), 2)	AS repeat_purchase_rate_percentage
FROM customer_first_order cfo
JOIN customers c
	ON c.customer_unique_id = cfo.customer_unique_id
JOIN orders o
	ON o.customer_id = c.customer_id
AND o.purchase_date = cfo.first_order_date
AND o.order_status = 'delivered'
AND o.data_quality_flag = 'CLEAN'
JOIN order_reviews r 
	ON r.order_id = o.order_id
GROUP BY r.satisfaction_tier
ORDER BY FIELD(r.satisfaction_tier, 'Promoter', 'Passive', 'Detractor');
