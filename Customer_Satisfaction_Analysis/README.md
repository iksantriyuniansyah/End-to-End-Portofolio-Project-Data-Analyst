# Customer Satisfaction Analysis — End-to-End Data Analyst Workflow Documentation

*Portfolio Project: Analyzing customer satisfaction using the Olist (Brazil) e-commerce dataset. This documentation outlines the entire end-to-end data analyst workflow—from defining the business problem and cleaning the data to conducting exploratory data analysis and building an interactive dashboard.*

---

## CHAPTER 1 — Business Understanding

### 1.1 Main Business Problem

> The company is experiencing a decline or fluctuation in customer satisfaction (review score) that could potentially threaten customer retention and revenue, but it is not yet clear which operational factor (delivery, product category, price, shipping costs) is the primary root cause?, so resources for improvement cannot yet be prioritized appropriately. The company could end up spending a large portion of its budget on addressing issues that are not actually the main source of the problem.

### 1.2 Business Objective

> Identify the key drivers of declining satisfaction, measure their impact on repeat purchase behavior, and ensure that future improvement decisions are data-driven, not based on assumptions or guesswork by the internal team.

### 1.3 Business Questions

| No | Business Question |
|---|---|
| 1 | What is the review score trend from 2017 to 2018? Is it improving, deteriorating, or stagnating? | 
| 2 | Which product categories have the highest Detractor Rates? | 
| 3 | How severely do delivery delays impact review scores? Specifically, is there a significant difference between a 1–3 day delay versus a delay of over 7 days? | 
| 4 | Do highly satisfied customers (Promoters) exhibit a significantly higher Repeat Purchase Rate compared to Detractors? | 

---

## CHAPTER 2 — Project Summary

This project analyzed **99,441 orders** and **96,096 unique customers** from an e-commerce marketplace between January 2017 and August 2018. The dataset boasts an exceptionally high review coverage rate of 98.86% for completed orders. This ensures the sample is highly representative of the entire customer base, rather than just a vocal minority.

The four business questions were answered through a comprehensive data pipeline: **Excel Power Query (Data Cleaning) → MySQL (EDA via a Statistical Anatomy Layer Approach) → Tableau (Interactive Dashboard)**. Below are the key findings:

* **Review score trends are highly volatile rather than linear:** The average score plummeted to a low of 3.79 in March 2018 (down from a normal baseline of ~4.2–4.3) but managed a rapid recovery over the following two months.
* **High-volume mainstream categories dominate the highest Detractor Rates:** Men's Fashion, Office Furniture, and Audio recorded the highest detractor rates, hovering between 21% and 22% among the top 10 product categories.
* **Delivery delays hit a sharp critical threshold at the 4-day mark:** The Detractor Rate more than doubled the moment a delay exceeded 3 days. This surge is far more drastic than the incremental jump seen when moving from the 4–7 day bucket to the >7 day bucket.
* **The hypothesis that "Promoters are more loyal than Detractors" holds true in direction, but its effect size is negligible:** The gap in the Repeat Purchase Rate is a mere 0.20 percentage points (3.32% vs. 3.12%), falling far short of general industry assumptions.

**Strategic Conclusion:** Improving customer satisfaction at this company **cannot be boiled down to a single initiative** (such as focusing solely on shipping or assuming satisfaction automatically drives retention). Instead of assuming that happy customers will naturally return, the company should pair its satisfaction initiatives with targeted loyalty programs or structured retention incentives.

---

## CHAPTER 3 — Dataset Overview

### 3.1 Data Summary & Sources

The dataset consists of **9 relational tables** representing the end-to-end e-commerce transaction lifecycle—spanning customers, orders, items, payments, and reviews. The source data consists of 9 cleaned CSV files.

| Table | Function | Total Rows (Post-Cleaning) |
|---|---|---|
| `orders` | Central fact table — 1 row per transaction | 99,441 |
| `order_items` | Line-item fact — 1 row per product within an order | 112,650 |
| `order_reviews` | Customer reviews per order | ~98,376 |
| `order_payments` | Payment details per order | 103,883 |
| `customers` | Customer master data | 99,441 |
| `products` | Product & category master data | 32,951 |
| `sellers` | Seller master data | 3,095 |
| `geolocation` | Coordinate reference data per zip code | 19,015 |
| `product_category_name_translation` | Mapping Portuguese category names to English | 73 |

**Data Period:** January 2017 – August 2018 (20 months). Data from 2016 was intentionally excluded because the volume was too low to serve as a statistically representative sample.

### 3.2 Data Dictionary

**`orders` Table** (Central Fact Table)

| Column | Type | Description |
|---|---|---|
| `order_id` | VARCHAR (PK) | Unique order identifier |
| `customer_id` | VARCHAR (FK) | Customer identifier *per transaction* |
| `order_status` | VARCHAR | Order status (`delivered`, `shipped`, `canceled`, etc.) |
| `purchase_date` | DATETIME | Timestamp when the order was placed |
| `approved_date` | DATETIME | Timestamp when payment was approved |
| `carrier_pickup_date` | DATETIME | Timestamp when the item was handed over to the courier |
| `delivered_date` | DATETIME | Timestamp when the customer received the item |
| `estimated_delivery_date` | DATETIME | System-estimated delivery date promised to the customer |
| `data_quality_flag` | VARCHAR | Cleaning output: `CLEAN`, `CARRIER_DATE_ANOMALY`, or `DELIVERED_NO_DATE` |
| `delivery_duration_days` | INT | Net days between `delivered_date` and `purchase_date` |
| `delivery_delay_days` | INT | Net days between `delivered_date` and `estimated_delivery_date` (positive values indicate a delay) |
| `delay_bucket` | VARCHAR | Delay categories: `On-Time`, `Late 1-3 Days`, `Late 4-7 Days`, `Late >7 Days`, `No Data` |
| `delivery_outlier_flag` | VARCHAR | Flag for extreme shipping durations (>90 days) |

**`order_reviews` Table**

| Column | Type | Description |
|---|---|---|
| `review_id` | VARCHAR (PK) | Unique review identifier |
| `order_id` | VARCHAR (FK) | The order being reviewed |
| `review_score` | TINYINT | Rating from 1 to 5 |
| `review_comment_title` / `review_comment_message` | TEXT | Optional text comments (structurally sparse with high null rates) |
| `review_creation_date` | DATETIME | Timestamp when the review was submitted |
| `satisfaction_tier` | VARCHAR | Classification: `Promoter` (score ≥4), `Passive` (score =3), `Detractor` (score ≤2) — based on NPS logic |

**`products` Table**

| Column | Type | Description |
|---|---|---|
| `product_id` | VARCHAR (PK) | Unique product identifier |
| `product_category_name` | VARCHAR | Product category name in Portuguese |
| `product_category_name_english` | VARCHAR | Translated product category name in English |
| `category_missing_flag` | VARCHAR | Flag for products missing a category |

**`customers` Table**

| Column | Type | Description |
|---|---|---|
| `customer_id` | VARCHAR (PK) | Transactional identifier — changes with every new order, even for the same customer |
| `customer_unique_id` | VARCHAR | Permanent customer identifier — used for repeat purchase analysis |
| `customer_zip_code_prefix`, `customer_city`, `customer_state` | VARCHAR / CHAR | Customer geographic data |

> **Crucial Note:** The variance between the count of unique `customer_id` values (99,441) and `customer_unique_id` values (96,096) is a structural feature of the dataset, not dirty data. It confirms that roughly 3,345 orders came from repeat customers.

The **`order_items`, `order_payments`, `sellers`, `geolocation`, and `product_category_name_translation`** tables follow standard relational schemas (refer to `Create_Database_and_Datatable.sql` in the repository). They capture transaction line items, payment methods, seller profiles, regional coordinates, and category translations, respectively.

---

### Data Cleaning Summary

Data cleaning was executed in **Excel Power Query**. The guiding principle was to flag and investigate business-logic anomalies; most findings were handled via custom flagging rather than outright row deletion.

**Top 10 Findings & Remediation Steps**

| # | Finding | Category | Action Taken |
|---|---|---|---|
| 1 | 8 orders marked `delivered` but have `NULL` delivery dates | Genuine data integrity issue | **Flagged** (`DELIVERED_NO_DATE`) and retained to preserve evidence of upstream data entry issues. |
| 2 | 166 orders where `carrier_pickup_date` precedes `purchase_date` | Business logic violation | **Flagged** (`CARRIER_DATE_ANOMALY`). The maximum variance was only ±68 minutes, pointing to a timezone/clock drift rather than fraud. |
| 3 | Maximum delivery duration reaches 209 days (mean is 12 days) | Valid statistical outlier | **Flagged** (`EXTREME_DELIVERY_OUTLIER` for >90 days) and kept to avoid skewing operational realities. |
| 4 | 814 duplicate `review_id` fields (identical rows) | Genuine duplicate | **Dropped** |
| 5 | 547 orders associated with more than one review record | Repeat reviews | **Deduplicated** by retaining only the latest review timestamp to reflect final sentiment. |
| 6 | 88% of `review_comment_title` and 59% of `review_comment_message` fields are null | Structural sparsity | **Left as null**, since text comments are optional features. |
| 7 | 2 product categories missing English translations | Reference table gap | **Manually mapped** (`pc_gamer` → PC Gaming, etc.) |
| 8 | ~1.85% of products lack a category designation | Minor data gap | **Flagged** (`CATEGORY_UNKNOWN`) since it sits safely below the 5% threshold. |
| 9 | 9 rows show a `payment_value` ≤ 0 | Anomalous values | **Dropped** 3 rows classified as `not_defined` with a 0 value (garbage data); **flagged** 6 valid voucher rows with a 0 value. |
| 10 | Unique `customer_id` count does not match `customer_unique_id` | Expected behavior | **No action taken**. This validates the presence of repeat customers. |

**Before vs. After (Row Counts per Table)**

| Table | Rows Before | Rows After | Columns Added |
|---|---|---|---|
| `orders` | 99,441 | 99,441 | +5 columns (delay buckets, flags, durations, etc.) |
| `order_reviews` | 99,224 | ~98,376 | +1 column (`satisfaction_tier`) — reduced due to duplicate removal and review deduplication |
| `order_items` | 112,650 | 112,650 | +2 columns (`free_shipping_flag`, `item_total_value`) |
| `products` | 32.951 | 32,951 | +1 column (`category_missing_flag`); 7 irrelevant product dimension columns dropped |
| `order_payments` | 103,886 | 103,883 | +1 column (`zero_value_payment_flag`) — 3 garbage rows removed |
| `geolocation` | 1,000,163 | 19,015 | Deduplicated down to 1 row per zip code (from an average of 52 coordinates per zip code) |
| `customers`, `sellers` | Unchanged | Unchanged | Data types standardized |
| `product_category_name_translation` | 71 | 73 | +2 rows via manual mapping |

**Tools & Methodology:** The entire data-cleaning pipeline was managed within **Microsoft Excel Power Query** using *Custom Columns* for business-logic flagging, *Table.Distinct* for deduplication, and *Table.Group* to isolate the latest review records. Each table was loaded as a *Connection Only* query and merged into a master staging query for MySQL ingestion.

---

## CHAPTER 4 — Exploratory Data Analysis: Key Findings & Insights

The EDA phase followed a **Statistical Anatomy Layer Approach**—moving systematically from business hypotheses to data profiling, univariate exploration, bivariate/multivariate cross-tabulations, time-series analysis, and data-driven hypothesis testing.

### Layer 1 — Data Profiling & Overview

| Metric | Value |
|---|---|
| Data Period | January 2017 – August 2018 |
| Total Orders | 99,441 |
| Total Unique Customers | 96,096 |
| % of Orders Statused `delivered` | 97.07% |
| Review Coverage (Delivered orders with reviews) | 98.86% |
| Review Score Distribution | 5★: 57.86% · 4★: 19.34% · 3★: 8.23% · 2★: 3.17% · 1★: 11.40% |
| Satisfaction Tier Distribution | Promoter: 77.20% · Passive: 8.23% · Detractor: 14.57% |

While most customers left top marks (5★), a notable secondary cluster emerged at the lowest rating (1★, 11.40%), vastly outnumbering 2★ ratings (3.17%). This reflects a classic e-commerce pattern: highly satisfied customers leave positive reviews effortlessly, deeply frustrated customers use reviews as a complaints channel, while moderate customers rarely feel compelled to rate at all.

### Layer 2 — Univariate Analysis

| Metric | Value |
|---|---|
| Review Score — Mean | 4.09 |
| Review Score — Median | 5.0 |
| Review Score — Std. Dev. | 1.34 |
| Delivery Duration — Mean | 12.07 days |
| Delivery Duration — Median | 10 days |
| Delivery Duration — Q1 / Q3 | 6 days / 15 days |
| Extreme Delivery Outliers (>90 days) | 76 orders |
| Overall On-Time Delivery (OTD) Rate | 93.20% |

The median (5.0) sits higher than the mean (4.09), confirming a heavily **left-skewed distribution**. Consequently, the mean slightly understates general customer satisfaction since it is pulled downward by a small but highly critical cluster of low ratings.

### Layers 3 & 4 — Bivariate, Multivariate, and Time-Based Analysis

**BQ1 — Review Score Trends (2017–2018)**

| Period | Avg Review Score | Detractor Rate |
|---|---|---|
| Jan 2017 (Baseline) | 4.34 | 8.26% |
| Nov 2017 (Decline Starts) | 4.20 | 11.04% |
| **Mar 2018 (Historical Low)** | **3.79** | **21.69%** |
| May 2018 (Recovery) | 4.24 | 10.91% |
| Aug 2018 (End of Period) | 4.29 | 10.04% |

**Insight:** The trend is highly volatile rather than linear. The business faced a distinct 4-month operational crisis (Dec 2017 – Apr 2018) before bouncing back. Evaluating satisfaction on an annualized basis obscures these critical operational dips.

**BQ2 — Highest Detractor Rates by Product Category**

| Category | Detractor Rate | On-Time Delivery Rate | Interpretation |
|---|---|---|---|
| Men's Fashion | 23.08% | 97.09% | Driven by non-delivery issues (e.g., fit, quality) |
| Office Furniture | 21.99% | 91.96% | Driven by non-delivery issues |
| Audio | 21.74% | 88.34% | **Double Risk:** Shipping delays exacerbate poor scores |
| Home Comfort | 18.56% | 90.46% | Driven by non-delivery issues |
| Bed & Bath | 15.90% | 92.73% | Driven by non-delivery issues |

**Insight:** The highest detractor rates are concentrated in high-volume mainstream categories rather than obscure niches. Men's Fashion, Office Furniture, and Audio lead the top 10 categories with detractor concentrations between 21% and 22%.

**BQ3 — The Impact of Delivery Delays on Review Scores**

| Delay Bucket | Avg Score | Gap vs. On-Time | Detractor Rate |
|---|---|---|---|
| On-Time | 4.29 | — | 9.19% |
| Late 1–3 Days | 3.29 | −1.00 | 32.08% |
| Late 4–7 Days | 2.11 | −2.19 | 67.51% |
| Late >7 Days | 1.70 | −2.60 | 79.30% |

**Insight:** A distinct **cliff point** occurs at the 4-day delay mark. The detractor rate more than doubles when moving from "1–3 days late" to "4–7 days late" (32.08% → 67.51%). This jump is far steeper than the transition from a 4–7 day delay to a >7 day delay, showing that customer patience breaks quickly after 3 days.

**BQ4 — Repeat Purchase Rate by Satisfaction Tier**

| Satisfaction Tier | Total Unique Customers | Repeat Purchase Rate |
|---|---|---|
| Promoter | 72,858 | 3.32% |
| Passive | 7,647 | 3.23% |
| Detractor | 11,852 | 3.12% |

**Insight:** While the directional hypothesis holds true (Promoter > Passive > Detractor), the actual variance is tiny (0.20 percentage points). Within this dataset, satisfaction alone is not a strong standalone predictor of customer retention.

### Layer 5 — Data-Driven Hypothesis Validation

| Hypothesis | Status | Evidence |
|---|---|---|
| **H1:** Delivery delays are the primary driver of low satisfaction scores. | **Strongly Confirmed** | Review scores plummet predictably across all categories as delay durations increase. |
| **H2:** Promoters yield a significantly higher repeat purchase rate than Detractors. | **Directionally True, Weak Effect Size** | A razor-thin 0.20 percentage point gap indicates that satisfaction is not a primary driver of retention here. |

### Strategic Recommendations

* **Establish a strict operational SLA targeting a maximum delay threshold of under 4 days**, rather than settling for generic "on-time" shipping metrics. Because customer sentiment drops drastically after day 3, logistics investments yield the highest returns when focused on capping delays before they cross this 4-day threshold.
* **Transition to monthly review score monitoring** instead of quarterly or annual reviews. This ensures sharp operational disruptions—like the March 2018 drop—are caught and resolved in real time.
* **Decouple the retention strategy from customer satisfaction metrics alone.** Given the surprisingly weak link between high satisfaction and repeat purchases, the company must launch dedicated retention initiatives (e.g., structured loyalty tiers, personalized re-engagement incentives) instead of assuming happy customers will return automatically.

---

*This technical documentation forms part of an end-to-end Customer Satisfaction Analysis portfolio project. The full MySQL EDA queries, comprehensive cleaning scripts, and interactive Tableau workbooks are accessible in the linked GitHub repository.*