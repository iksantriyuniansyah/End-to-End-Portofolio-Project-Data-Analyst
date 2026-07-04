-- AUTHOR/ROLE				: Iksan Tri Yuniansyah / Commercial Data Analyst
-- E2E PORTOFOLIO PROJECT	: Customer Satisfaction Analysis - Olist Brazilian E-Commerce Dataset
-- Exploratory Data Analysis Menggunakan Pendekatan (5-Layer Statistical Anatomy Approach)
-- Layer 1: Data Profiling/Overview / Layer 2: Univariate Analysis / Layer 3: Bivariate Analysis / Layer 4: Multivariate Analysis / Layer 5: Data-driven Hypothesis
-- BUSINESS PROBLEM: Identifikasi driver utama penurunan satisfaction
-- KPI:
--   1. Average Review Score 
--   2. Detractor Rate (% review <= 2)
--   3. On-Time Delivery Rate 
--   4. Delivery Delay Impact on Satisfaction 
--   5. Repeat Purchase Rate by Satisfaction Tier

-- LAYER 1: DATA PROFILING / OVERVIEW
-- Goalsnya: Mastiin scope dan batas temporal atau ruang lingkupnya data valid sebelum masuk ke analisa yang lainnya

-- LAYER 1 PART 1
-- Mencari tau kapan datanya mulai dan berakhir, yang mana ini important untuk framing "period of analysis"
SELECT
    MIN(purchase_date)                                          AS earliest_order,
    MAX(purchase_date)                                          AS latest_order,
    DATEDIFF(MAX(purchase_date), MIN(purchase_date))            AS total_days_span,
    COUNT(DISTINCT order_id)                                    AS total_orders,
    COUNT(DISTINCT customer_id)                                 AS total_customers
FROM orders;

-- LAYER 1 PART 2
-- Melihat distribusi order_status untuk melihat seberapa banyak data order_status
-- yang "usable", dan outputnya hanya status 'delivered' yang valid untuk hampir semua KPI
SELECT
    order_status,
    COUNT(*)                                              		AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)    		AS pct_of_total
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- LAYER 1 PART 3
-- Mengecek berapa % delivered orders yang punya review
-- kalau terlalu rendah, ada potensi bias pada satisfaction analysis
SELECT
    COUNT(DISTINCT o.order_id)                                  				AS total_delivered,
    COUNT(DISTINCT r.order_id)                                  				AS orders_with_review,
    ROUND(COUNT(DISTINCT r.order_id) * 100.0 / COUNT(DISTINCT o.order_id), 2)	AS review_coverage_pct
FROM orders o
LEFT JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status  = 'delivered';

-- LAYER 1 PART 4
-- Melihat distribusi review_score apakah bentuk distribusi awal (skewed ke kiri atau kanan) melalui persentasenya
-- ini dipake buat nentuin apakah mean itu sudah merepresentasikan rata2nya atau perlu median? 
SELECT
    review_score,
    COUNT(*)                                                    AS total_reviews,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)         	AS percentage_of_total
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

-- LAYER 1 PART 5
-- Mengidentifikasi distribusi satisfaction_tier apakah menyebar rata atau condong ke salah satu variabel
SELECT
    satisfaction_tier,
    COUNT(*)                                                    AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)         	AS percentage_of_total
FROM order_reviews
GROUP BY satisfaction_tier
ORDER BY FIELD(satisfaction_tier, 'Promoter', 'Passive', 'Detractor');


-- ============================================================


-- LAYER 2: UNIVARIATE ANALYSIS
-- Goalsnya: Mengidentifikasi distribusi data menggunakan descriptive statistics method di tiap variabel 
--           secara individual, sebelum nantinya dihubungkan atau mencari korelasi dengan variabel lain

-- LAYER 2 PART 1
-- Statistik deskriptif implemented pada review_score
-- untuk melihat Mean, Median, Standard Deviation, Min, Max dan memvalidasi apakah mean nilai rata-ratanya bias
SELECT
    ROUND(AVG(review_score), 4)                                 									AS mean_score,
    AVG(CASE WHEN review_number IN (FLOOR((total+1)/2), CEIL((total+1)/2)) THEN review_score END)	AS median_score,
    ROUND(STDDEV_POP(review_score), 4)                          									AS std_dev,
    MIN(review_score)                                           									AS min_score,
    MAX(review_score)                                           									AS max_score,
    COUNT(*)                                                    									AS total_rows
FROM (
    SELECT
        review_score,
        ROW_NUMBER() OVER (ORDER BY review_score)               AS review_number,
        COUNT(*) OVER ()                                        AS total
    FROM order_reviews
) ranked;

-- LAYER 2 PART 2
-- Melihat distribusi delivery_duration_days untuk mengidentifikasi bentuk dari distribusi datanya:
-- apakah right/left-skewed, lalu mencari apakah ada outlier dan berapa jumlahnya
SELECT
    ROUND(AVG(delivery_duration_days), 2)                       			AS mean_days,
    ROUND(STDDEV_POP(delivery_duration_days), 2)               	 			AS std_dev,
    MIN(delivery_duration_days)                                 			AS min_days,
    MAX(delivery_duration_days)                                 			AS max_days,
    MAX(CASE WHEN percentage_rank <= 0.25 THEN delivery_duration_days END) 	AS quartiles1,
    MAX(CASE WHEN percentage_rank <= 0.50 THEN delivery_duration_days END) 	AS median,
    MAX(CASE WHEN percentage_rank <= 0.75 THEN delivery_duration_days END) 	AS quartiles3,
    COUNT(*)                                                    			AS total_rows,
    SUM(CASE WHEN delivery_duration_days > 90 THEN 1 ELSE 0 END) 			AS 'extreme_outliers_>90d'
FROM (
    SELECT
        delivery_duration_days,
        PERCENT_RANK() OVER (ORDER BY delivery_duration_days)   			AS percentage_rank
    FROM orders
    WHERE delivery_duration_days IS NOT NULL
      AND order_status = 'delivered'
) ranked;


-- LAYER 2 PART 3
-- Melihat distribusi delay_bucket alias frekuensi tiap bucket
-- hasilnya punya korelasi dan apakah ada (Delivery Delay Impact) nya
SELECT
    delay_bucket,
    COUNT(*)                                                    AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)         	AS percentage_of_total
FROM orders
WHERE order_status = 'delivered' AND data_quality_flag IS NULL 
GROUP BY delay_bucket
ORDER BY FIELD(delay_bucket, 'On-Time','Late 1-3 Days','Late 4-7 Days','Late >7 Days','No Data');

-- LAYER 2 PART 4
-- Melihat distribusi payment_type, yang mana konteksnya payment method dominan itu berpengaruh ke risk profile order
SELECT
    payment_type,
    COUNT(DISTINCT order_id)                                    						AS total_orders,
    ROUND(AVG(payment_value), 2)                               							AS avg_payment_value,
    ROUND(AVG(payment_installments), 2)                         						AS avg_installments,
    ROUND(COUNT(DISTINCT order_id) * 100.0 / SUM(COUNT(DISTINCT order_id)) OVER (), 2)	AS percentage_of_orders
FROM order_payments
GROUP BY payment_type
ORDER BY total_orders DESC;

-- LAYER 2 PART 5
-- Melihat distribusi produk per kategori dengan segmentasi top 15 most ordered categories
SELECT
    p.product_category_name_english                             			AS category,
    COUNT(oi.order_id)                                          			AS total_order_items,
    ROUND(COUNT(oi.order_id) * 100.0 / SUM(COUNT(oi.order_id)) OVER (), 2) 	AS percentage_of_items
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
WHERE p.product_category_name_english IS NOT NULL
GROUP BY p.product_category_name_english
ORDER BY total_order_items DESC
LIMIT 15;


-- ============================================================


-- LAYER 3: BIVARIATE ANALYSIS
-- Goalsnya: Menghubungkan sekaligus mencari korelasi antar 2 variabel untuk
-- menemukan hubungan kuat antar variabel yang jadi core dari business questions

-- LAYER 3 PART 1
-- KPI1 Average Review Score per delay_bucket 
-- BQ3: "Seberapa besar dampak delivery delay terhadap review score?"
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

-- LAYER 3 PART 2
-- KPI2 Detractor Rate per product category (top 20)
-- BQ2: "Kategori produk mana yang punya Detractor Rate tertinggi?"

-- BQ2A: Detractor Rate per product category

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


-- BQ2B: Detractor Rate per city
SELECT
    c.customer_city                                                                            	AS city,
    COUNT(DISTINCT o.order_id)                                                                  AS total_orders,
    ROUND(AVG(r.review_score), 2)                                                               AS avg_review_score,
    ROUND(SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(r.review_id), 2)	AS detractor_rate_percentage,
    ROUND(SUM(CASE WHEN r.review_score >= 4 THEN 1 ELSE 0 END) * 100.0 / COUNT(r.review_id), 2) AS promoter_rate_percentage
FROM order_reviews r
JOIN orders o    ON r.order_id    = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status      = 'delivered'
  AND o.data_quality_flag IS NULL
GROUP BY c.customer_city
HAVING COUNT(DISTINCT o.order_id) >= 100
ORDER BY detractor_rate_percentage DESC
LIMIT 10;
 
-- LAYER 3 PART 3
-- BQ4: Repeat Purchase Rate by Satisfaction Tier
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

-- LAYER 3 PART 4
-- OTD Rate overall
SELECT
    COUNT(*)                                                    							AS total_delivered,
    SUM(CASE WHEN delay_bucket = 'On-Time' THEN 1 ELSE 0 END)  								AS on_time_count,
    ROUND(SUM(CASE WHEN delay_bucket = 'On-Time' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)	AS overall_otd_rate_percentage
FROM orders
WHERE order_status     = 'delivered'
	AND data_quality_flag IS NULL
	AND delay_bucket      != 'No Data';


-- ============================================================


-- LAYER 4: MULTIVARIATE & TIME-BASED ANALYSIS
-- Goalsnya: Track perubahan metriks bulan ke bulan (MoM trend) dan
--           menghubungkan 3 variabel (kategori × region × satisfaction)

-- LAYER 4 PART 1
-- Monthly review score trend
-- BQ1: "Apakah tren review score terutama satisfaction membaik, memburuk, atau stagnan dari 2017-2018?"
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

-- LAYER 4 PART 2
-- Melihat MoM OTD Rate trendnya, untuk melihat apakah delivery performancenya konsisten membaik/memburuk
SELECT
    DATE_FORMAT(o.purchase_date, '%Y-%m')                       								AS order_month,
    COUNT(*)                                                    								AS total_delivered,
    ROUND(SUM(CASE WHEN o.delay_bucket = 'On-Time' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)	AS otd_rate_percentage,
    ROUND(AVG(o.delivery_duration_days), 2)                     								AS avg_delivery_days
FROM orders o
WHERE o.order_status    = 'delivered'
  AND o.data_quality_flag IS NULL
  AND o.delay_bucket      != 'No Data'
  AND o.purchase_date     >= '2017-01-01'
GROUP BY order_month
ORDER BY order_month;

-- LAYER 4 PART 3
-- Melihat korelasi Avg review score antara variabel per kategori dengan delay_bucket
-- dan mengidentifikasi kategori mana yang paling sensitif terhadap delay
SELECT
    p.product_category_name_english                             AS category,
    o.delay_bucket												AS delay_category,
    COUNT(r.review_id)                                          AS total_reviews,
    ROUND(AVG(r.review_score), 3)                               AS avg_review_score
FROM order_reviews r
JOIN orders o       ON r.order_id    = o.order_id
JOIN order_items oi ON o.order_id    = oi.order_id
JOIN products p     ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
  AND o.delay_bucket  != 'No Data'
  AND p.product_category_name_english IS NOT NULL
  AND p.product_category_name_english != ''
GROUP BY
    p.product_category_name_english,
    o.delay_bucket
HAVING COUNT(r.review_id) >= 30
ORDER BY p.product_category_name_english, FIELD(o.delay_bucket, 'On-Time','Late 1-3 Days','Late 4-7 Days','Late >7 Days');


-- LAYER 4 PART 4
-- Melihat korelasi Detractor Rate antara variabel per state dengan delay_bucket
-- jika state dan delivery digabung maka state mana yang paling bermasalah alias detractor ratenya paling tinggi?
SELECT
    c.customer_state,
    o.delay_bucket																				AS delay_category,
    COUNT(r.review_id)                                          								AS total_reviews,
    ROUND(AVG(r.review_score), 3)                               								AS avg_review_score,
    ROUND(SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(r.review_id), 2)	AS detractor_rate_percentage
FROM order_reviews r
JOIN orders o    
	ON r.order_id    = o.order_id
JOIN customers c 
	ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.delay_bucket  != 'No Data'
GROUP BY c.customer_state, o.delay_bucket
HAVING COUNT(r.review_id) >= 50
ORDER BY detractor_rate_percentage DESC
LIMIT 20;


-- ============================================================


-- LAYER 5: DATA-DRIVEN HYPOTHESIS
-- Goalsnya: Memvalidasi dari hipotesis bisnis spesifik
--         yang sudah termapping dan dari data yang terbentuk dari proses eksplorasi di Layer 1-4

-- LAYER 5 PART 1 HIPOTESIS A: "Delivery delay adalah driver utama satisfaction
--              rendah, yang mana customer yang order deliverynya telat >7 hari
--              punya Detractor Rate jauh lebih tinggi dibandingkan yang deliverynya tepat waktu" artinya ada korelasi yang kuat = adanya kausalitas antar 2 variabel tersebut

-- KPI4 Gap analysis antara On-Time vs Late >7 Days (Delivery Delay Impact on Satisfaction)
-- Score delta mulai turun drastis disaat keterlambatan 4-7 hari, artinya threshold keterlambatan tidak lebih dari 3 hari
WITH satisfaction_by_bucket AS (
    SELECT
        o.delay_bucket																			    AS delay_category,
        COUNT(r.review_id)                                      									AS total,
        ROUND(AVG(r.review_score), 4)                           									AS avg_score,
        ROUND(SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(r.review_id), 2)	AS detractor_rate_percentage,
        ROUND(SUM(CASE WHEN r.review_score >= 4 THEN 1 ELSE 0 END) * 100.0 / COUNT(r.review_id), 2)	AS promoter_rate_percentage
    FROM orders o
    JOIN order_reviews r
		ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.data_quality_flag IS NULL
      AND o.delay_bucket != 'No Data'
    GROUP BY o.delay_bucket
),
on_time_score AS (
    SELECT avg_score AS baseline_score, detractor_rate_percentage AS baseline_detractor
    FROM satisfaction_by_bucket
    WHERE delay_category = 'On-Time'
)
SELECT
    s.delay_category, s.total, s.avg_score, s.detractor_rate_percentage, s.promoter_rate_percentage,
    ROUND(s.avg_score - ot.baseline_score, 4)                    		AS score_delta_vs_ontime,
    ROUND(s.detractor_rate_percentage - ot.baseline_detractor, 2)       AS detractor_delta_vs_ontime
FROM satisfaction_by_bucket s
CROSS JOIN on_time_score ot
ORDER BY FIELD(s.delay_category, 'On-Time','Late 1-3 Days','Late 4-7 Days','Late >7 Days');


-- LAYER 5 PART 2 HIPOTESIS B: "Promoter customer (score 4-5) punya repeat
--              purchase rate yang signifikan lebih tinggi
--              dibanding Detractor"
-- KPI5 Repeat Purchase Rate by Satisfaction Tier
WITH customer_tier AS (
    SELECT
        c.customer_unique_id,
        FIRST_VALUE(r.satisfaction_tier) OVER (PARTITION BY c.customer_unique_id ORDER BY o.purchase_date ASC) 	AS first_order_tier,
        COUNT(o.order_id) OVER (PARTITION BY c.customer_unique_id)                                            	AS total_orders
    FROM orders o
    JOIN customers c    
		ON o.customer_id  = c.customer_id
    JOIN order_reviews r 
		ON o.order_id   = r.order_id
    WHERE o.order_status = 'delivered'
),
unique_customers AS (
    SELECT DISTINCT customer_unique_id, first_order_tier, total_orders
    FROM customer_tier
)
SELECT
    first_order_tier                                            									AS satisfaction_tier,
    COUNT(customer_unique_id)                                   									AS total_customers,
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)          										AS repeat_customers,
    ROUND(SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_unique_id), 2) AS repeat_purchase_rate_percentage,
    ROUND(AVG(total_orders), 2)                                 									AS avg_orders_per_customer
FROM unique_customers
GROUP BY first_order_tier
ORDER BY FIELD(first_order_tier, 'Promoter', 'Passive', 'Detractor');