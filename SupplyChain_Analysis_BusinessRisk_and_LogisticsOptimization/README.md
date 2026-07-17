## Result Summary

DataCo Global, a multi-category retailer (Clothing, Sports, Electronic Supplies) operating across 5 markets and 23 regions, faced two seemingly related risk signals: a high rate of late deliveries, and wide profitability variance across categories, markets, and regions. This project analyzed 180,519 order-item transactions (2015–2017, reliable period) through a end-to-end Excel/Power Query for cleaning, MySQL for exploratory data analysis, and Power BI for the interactive dashboard to quantify both risks and test whether they share a common root cause.

**Key result:** they don't. Late-delivery orders show virtually identical margin (10.73%) and discount rate (10.14%) to on-time orders (10.95% / 10.14%) — a gap of only 0.22 percentage points. Profitability risk ($12.9M, 35.3% of Sales, at risk) and delivery risk (First Class shipments late 100% of the time) are two independent problems requiring two separate remediation tracks, not one combined fix.

---

## 1. Business Understanding
 
### 1.1 Main Business Problem
DataCo faces two clear risk indicators: most orders arrive late, and profitability levels vary significantly across categories, markets, and regions - with some segments appearing to be strong revenue generators but quietly experiencing declining margins. What is still lacking is evidence of how these two issues are interrelated, as well as which of the two should be prioritized in future operational and commercial decision-making.

### 1.2 Business Objective
1. Give leadership full visibility into revenue and profit health, with risk quantified in dollar terms rather than percentages alone.
2. Give Operations a granular view of delivery performance to identify the true root cause of lateness - shipping mode, region, or product category.

### 1.3 Business Questions
 
**A. C-Level Lens (Profitability & Risk)**
| # | Question | Key Columns |
|---|---|---|
| A1 | What are total Sales and Profit Margin, and what has been the trend over the past three years has it increasing, declining, or stagnant? | `sales`, `order_profit_per_order`, `order_date` |
| A2 | Which product categories, markets, and regions are most profitable? | `category_name`, `market`, `order_region`, `profit_margin_pct` |
| A3 | How much does discounting impact margin, and is any segment over-discounting to the point of eroding profitability? | `order_item_discount_rate`, `profit_margin_pct` |
| A4 | What is the estimated Revenue at Risk from the combination of negative-margin orders, excessive discounting, and problematic order statuses (fraud, cancellation, payment issues)? | `order_profit_per_order`, `order_item_discount_rate`, `order_status` |
| A5 | How much overlap exists between Revenue at Risk and orders that experienced delivery delays? | `revenue_at_risk_flag`, `late_delivery_risk` |
 
**B. Head of Operations Lens (Logistics Performance)**
| # | Question | Key Columns |
|---|---|---|
| B1 | What is the overall On-Time Delivery Rate, and how has been the trend over the past three years? | `late_delivery_risk`, `order_date` |
| B2 | Which shipping mode is most frequently late, and by how many days on average? | `shipping_mode`, `days_for_shipping_real`, `days_for_shipment_scheduled` |
| B3 | Which regions have the worst delivery performance? | `order_region`, `late_delivery_risk` |
| B4 | Are specific product categories systematically more prone to delays than others? | `category_name`, `late_delivery_risk` |

---

## 2. Dataset Overview
 
### 2.1 Data Summary & Source
- **Source:** DataCo Global Supply Chain Dataset (Kaggle)
- **Raw file:** 180,519 rows × 53 columns, Latin-1 encoded (non-UTF-8 due to Spanish-language geography fields)
- **Original period:** January 2015 – January 2018
- **Reliable analysis period:** January 2015 – December 2017 (2018 excluded because the sample size is too small - only one month)
- **Grain:** order-item level (1 row = 1 SKU line within an order); 65,752 unique orders, ~2.75 items/order on average
- **Scope:** 50 product categories, 5 markets, 23 order regions, 4 customer segments, 9 order statuses, 4 shipping modes

### 2.2 Data Dictionary (final cleaned schema — key columns used)
 
| Field | Type | Description |
|---|---|---|
| `order_id` / `order_item_id` | Int | Order-level and order-item-level identifiers |
| `order_date` / `shipping_date` | Date/Time | Order placement and shipment date |
| `sales` | Decimal | Gross line value (Qty × Product Price) |
| `order_item_total` | Decimal | Net line value after discount |
| `order_item_discount_rate` | Decimal | Discount rate applied (0–0.25 scale) |
| `order_profit_per_order` | Decimal | Profit for the order line (can be negative) |
| `profit_margin_pct` | Decimal | Engineered: `order_profit_per_order / sales` |
| `category_name` | Text | Product category (50 unique) |
| `market` / `order_region` | Text | Geographic grouping (5 markets, 23 regions) |
| `customer_segment` | Text | Consumer / Corporate / Home Office |
| `order_status` | Text | 9 statuses incl. COMPLETE, CANCELED, SUSPECTED_FRAUD |
| `delivery_status` | Text | Advance shipping / Late delivery / Shipping canceled / On time |
| `late_delivery_risk` | Binary | 1 = late (derived from `delivery_status`, not raw day math) |
| `shipping_mode` | Text | Same Day, First Class, Second Class, Standard Class |
| `days_for_shipping_real` / `_scheduled` | Int | Actual vs. promised transit days |
| `shipping_delay_days` | Decimal | Engineered: real − scheduled |
| `is_reliable_trend_period` | Boolean | Engineered: `order_date` < Oct 1, 2017 |
| `is_valid_shipping_record` | Boolean | Engineered: excludes CANCELED/SUSPECTED_FRAUD (phantom shipping days) |
| `revenue_at_risk_flag` | Boolean | Engineered composite risk flag (see §3.3) |
 
---

## 3. Data Cleaning Summary
 
### 3.1 Key Issues Found & Fixes
 
| Issue | Impact if Unfixed | Fix Applied |
|---|---|---|
| Non-UTF-8 encoding | Corrupted geography text (mojibake) | Set File Origin to Windows-1252 on import |
| Date locale ambiguity (M/D/YYYY vs. regional default) | Silent day/month swap for day ≤ 12 | `Change Type → Using Locale → English (US)` |
| Whitespace in text fields (incl. double-space in "South of  USA") | Ugly labels, silent join failures downstream | Blanket `Text.Trim` + custom space-collapse formula |
| **Discount Rate mislabel** — 10,029 rows (5.6%) tagged "6%" actually charged 5.5% | Systemic distortion of any discount-based segmentation | Recoded label to match the real monetary discount (0.06 → 0.055) |
| 12 redundant/zero-value/dummy columns | Analytical noise, wasted schema | Removed (100% duplicate, 100% null, or zero-variance — see table below) |
| Negligible missing values (`customer_lname`: 8 rows, `customer_zipcode`: 3 rows) | <0.01% each — not worth row deletion | Flagged as "UNKNOWN," not dropped |
| Order volume drops ~60% from Oct 2017 with no seasonal precedent | False "sales decline" narrative in trend charts | Flagged via `is_reliable_trend_period`; excluded from all trend KPIs |
| Cancelled/fraud orders retain a non-null "real shipping days" value despite never shipping | Inflated/understated OTD & delay KPIs | Flagged via `is_valid_shipping_record`; excluded from delivery-performance KPIs |
 
**Columns removed (12):** `Product Description` (100% null), `Customer Email` / `Customer Password` (masked dummy values), `Product Status` (constant, zero variance), `Benefit per order` (duplicate of `order_profit_per_order`), `Sales per customer` (duplicate of `order_item_total`), `Product Category Id` (duplicate of `Category Id`), `Order Item Cardprod Id` (duplicate of `Product Card Id`), `Order Item Product Price` (duplicate of `Product Price`), `Order Customer Id` (duplicate of `Customer Id`), `Order Zipcode` (86.2% missing), `Product Image` (URL, no analytical value).
 
### 3.2 Before vs. After
 
| Metric | Before | After |
|---|---|---|
| Rows | 180,519 | 180,519 (0 dropped — no row-level integrity issues) |
| Columns | 53 | 48 (−12 removed, +7 engineered) |
| Encoding | Latin-1 (unhandled) | Latin-1 (correctly declared on import) |
| Discount Rate tiers | 18 tiers, 1 mislabeled | 18 tiers, all verified consistent with monetary discount |
| Missing values | 4 columns affected | 0 (2 negligible cases flagged as "UNKNOWN," not imputed statistically) |
 
### 3.3 Cleaning, Transformation & Feature Engineering Steps (Power Query)
 
| Step | Action | Rationale |
|---|---|---|
| 0 | Import with File Origin = Windows-1252 | Fixes non-UTF-8 encoding from Spanish-language geography fields |
| 1 | `Change Type → Using Locale (English US)` on date columns | Prevents silent day/month transposition from regional locale mismatch |
| 2 | Blanket `Text.Trim` + custom space-collapse formula on all text columns | Removes leading/trailing/internal double whitespace |
| 3 | Custom column recoding `order_item_discount_rate` (0.06 → 0.055 via `Number.Round` guard) | Corrects the systemic discount mislabel; `Number.Round` avoids missing rows due to float-storage noise |
| 4 | Remove 12 redundant/zero-value/dummy columns | Eliminates duplication and non-informative fields |
| 5 | Custom-column null handling: `customer_lname` → "UNKNOWN"; `customer_zipcode` → cast to Text first, then "UNKNOWN" | Flags negligible missingness without row deletion; type-cast order prevents numeric-inference errors |
| 6 | Feature engineering (7 columns): `order_year`, `order_year_month`, `is_reliable_trend_period`, `shipping_delay_days`, `is_valid_shipping_record`, `profit_margin_pct`, `revenue_at_risk_flag` | Purpose-built fields to support the 5 KPIs and 9 business questions directly |
| 7 | Validation query: `shipping_date >= order_date` row-count check | Confirms no logical date violations before proceeding to EDA |
| 8 | Load as Connection Only | Avoids loading 180K+ rows directly into a worksheet; keeps file performant |
 
**`revenue_at_risk_flag` final logic (Tight version, approved):**
`(order_profit_per_order < 0) OR (order_item_discount_rate ≥ 0.20) OR (order_status IN ('SUSPECTED_FRAUD', 'CANCELED', 'PAYMENT_REVIEW', 'ON_HOLD'))`
*(`PENDING_PAYMENT` deliberately excluded — it's a normal transactional state, not inherently a risk indicator.)*
 
---

## 4. Exploratory Data Analysis (EDA)

| BQ ID | Metric / Analysis Focus | Statistical Findings |
| :--- | :--- | :--- |
| **A1** | Monthly Sales & Margin Trend | Steady baseline at ~$1.0–1.1M/month with an aggregate margin of 10.4%–11.3%. *Visual Note: Monthly margins fluctuate dynamically between 9% and 13%, with a sharp visual volume drop observed in late 2017.* |
| **A2** | Margin Variance — All 50 Categories | Ranges from 4.57% (Men's Clothing) up to 17.46% (Golf Bags & Carts, n=61, low-volume niche). |
| **A2** | Margin Variance — Top-10 Categories | Sits in a tight, highly predictable 10.09%–11.19% band (anchored by Fishing and Cleats). |
| **A2** | Margin Variance — Geographic | Market Spread: 10.42%–11.23% (Europe & LATAM dominant) / Regional Spread: 9.58%–13.81%. |
| **A3** | Discount Rate vs. Margin Correlation | Spearman $r = -0.1147$ (Visually evident, weak negative monotonic relationship). |
| **A3** | Margin Sensitivity by Discount Pillar | 11.86% margin at 0–5% discount (prominently highlighted) $\rightarrow$ scales down to 9.24% margin at 20%+ discount. |
| **A4** | Revenue at Risk (RAR) Quantification | **$12.9M** (Precisely 35.34% of total $36.5M Sales, driven by negative-margin and blocked statuses). |
| **A5** | RAR × Late Delivery Overlap Rate | 50.54% (Directly maps to the remaining light-blue segment within the high-risk tier). |
| **A5** | Central Hypothesis Testing | On-time orders: 10.95% margin / Late orders: 10.73% margin. Margin gap is a negligible 0.22 percentage points. |
| **B1** | Aggregate On-Time Delivery (OTD) Rate | 42.71% overall baseline, holding rigidly flat year-over-year (42.5%–43.1%). |
| **B2** | OTD & Avg Delay by Shipping Mode | First Class: 100.00% Late (Fixed 1.00-day delay, zero variance across all 5 global markets).<br>Second Class: 79.83% Late.<br>Same Day: 47.93% Late.<br>Standard Class: 39.77% Late. |
| **B3** | OTD Variance — Geographic Regions | Narrow band spanning 51.60% to 60.15% (Central Africa showing the worst visual delay). |
| **B4** | OTD Variance — Product Categories | Ranges from 49.27% to 68.85% (Golf Bags & Carts worst; remaining top-10 core drivers stay highly uniform). |

---

## 5. Insights & Recommendations

### 5.1 Insights

#### Insight 1 — Stagnant, Not Declining, On Both Fronts (BQ A1, B1)
Sales have remained stable at $1.0–1.1 million per month for 3 years (with a drop in the last 2 months of 2017 due to incomplete data); the profit margin has remained stable at 10.4%–11.3% and has improved slightly (10.44% to 11.25%). The on-time delivery rate has remained flat in the 40% range, with no year-over-year improvement or deterioration.

#### Insight 2 — Category Is the Real Profitability Lever, But Only in the Niche Product (BQ A2)
Margins vary much more widely across categories than across markets or regions, with Fishing being the dominant profit contributor. However, within these top 10 categories, margins are actually narrow and stable (10.1%–11.2%) - nearly identical to the spreads for markets (10.4%–11.2%) and regions (9.6%–13.8%). Extreme volatility (ranging from 4.6% for Men's Clothing to 17.5% for Golf Bags & Carts) only becomes apparent when looking at all 50 categories, not within the core business drivers.

#### Insight 3 — Discounting Erodes Margin, But Modestly (BQ A3)
A Spearman correlation of -0.11 identified during EDA in SQL confirms a real but weak relationship between discount rate and profit margin. The effect is visible and monotonic: average margin falls from 11.9% at 0–5% discount to 9.2% at 20%+ discount - a real four-point decline.

#### Insight 4 — Revenue at Risk Is Over a Third of Total Sales (BQ A4)
Combining negative-margin orders, excessive discounting (≥20%), and problematic order statuses (suspected fraud, cancellations, payment review, on-hold), an estimated $12.9 million - 35.3% of total Sales - sits in a risk-exposed bucket.

#### Insight 5 — The Two Risks Are Independent (BQ A5)
Revenue Safe: 43.04% on-time, Revenue At Risk: 49.46% on-time - nearly identical, validating that the RAR-Late Delivery overlap is only 50.5%. The margin for late orders (10.73%) versus on-time orders (10.95%) also differs by only 0.22 percentage points. Late deliveries do not appear to erode margins - profitability risk and delivery risk require separate strategies.

#### Insight 6 — Shipping Mode, Not Region or Category, Drives Lateness (BQ B2, B3, B4)
First Class is late 100% of the time, without exception (a consistent 1-day delay across all markets). Second Class is late 79.8% of the time. Standard Class - which accounts for the majority of order volume - is late only 39.8% of the time. Compare this: the worst region is only 60.2% late, and the worst category (Golf Bags & Carts, small sample) is 68.9%. The effect of shipping mode is far more extreme than that of any region or category.

### 5.2 Recommendations
1. **Reset the First and Second Class shipping SLA.** A promise that fails 100% of the time is not an execution problem, it is a design problem. Re-calibrate the delivery-day commitment for First and Second Class based on actual historical fulfillment time, rather than continuing to promise a window the business has never once met.
2. **Treat Revenue at Risk as its own monitoring track.** Since it does not move together with delivery performance, the $12.9M at-risk figure needs its own dedicated tracking - flagging negative-margin orders, high-discount orders, and problematic order statuses - independent of any logistics KPI.
3. **Target discount policy at the long tail, not the whole portfolio.** Since core, high-volume categories already show stable, healthy margins, a blanket discount cap would fix a problem that mostly doesn't exist there. Discount governance should instead focus on the smaller, more volatile long-tail categories where margin swings are actually concentrated.