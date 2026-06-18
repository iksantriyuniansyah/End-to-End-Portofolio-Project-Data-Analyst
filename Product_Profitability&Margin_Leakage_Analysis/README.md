# Product Profitability & Margin Leakage Analysis
**Industry:** Retail (B2B & B2C) | **Period:** FY 2013–2017 | **Currency:** AUD

---

## Project Overview
 
This project examines whether high revenue actually leads to high profitability in the retail business, as well as where profit leakage occurs across various product categories and customer segments.

**Main Business Problem:** Management allocates resources based on revenue performance, not profitability. Without understanding the actual profit contribution by category and segment, a business risks overinvesting in areas that actually erode margins.

**Objective:** Identify the customer categories and segments that drive actual profit, measure sources of revenue leakage (discounts and shipping costs), and detect concentration risk at the product level.

---
 
## Dataset Overview
 
| Attribute | Detail |
|---|---|
| Source | Australian Retail B2B/B2C |
| Rows | 4,999 transactions |
| Columns | 23 |
| Unique Products | 257 SKUs |
| Unique Customers | 788 |
| Categories | Office Supplies, Technology, Furniture |
| Customer Types | Corporate, Consumer, Home Office, Small Business |
 
---

### Data Dictionary
 
| Column | Data Type | Description | Notes |
|---|---|---|---|
| Order No | VARCHAR | Unique order identifier | 1 order can be multi-row (multi-item) |
| Order Date | DATE | Date the order was created | Format: YYYY/MM/DD |
| Ship Date | DATE | Shipping date | |
| Customer Name | VARCHAR | Customer name | |
| City | VARCHAR | Customer city | |
| State | VARCHAR | State (NSW / VIC) | |
| Customer Type | VARCHAR | Customer segment | Corporate, Consumer, Home Office, Small Business |
| Account Manager | VARCHAR | Sales representative | |
| Order Priority | VARCHAR | Order priority | Low, Medium, High, Critical |
| Product Name | VARCHAR | Product name | |
| Product Category | VARCHAR | Product category | Office Supplies, Technology, Furniture |
| Product Container | VARCHAR | Packaging type | |
| Ship Mode | VARCHAR | Shipping method | |
| Cost Price | DECIMAL | Cost price per unit (COGS) | AUD |
| Retail Price | DECIMAL | Retail price per unit | AUD |
| Profit Margin | DECIMAL | Retail Price − Cost Price per unit | AUD, can be negative |
| Order Quantity | INTEGER | Quantity of items ordered | |
| Sub Total | DECIMAL | Retail Price × Order Quantity | Gross Revenue |
| Discount Percentage | DECIMAL | % discount given | 0–1 format |
| Discount Dollar | DECIMAL | Sub Total × Discount % | AUD |
| Order Total | DECIMAL | Sub Total − Discount Dollar | Net revenue after discount |
| Shipping Cost | DECIMAL | Shipping cost borne by business | AUD |
| Total | DECIMAL | Order Total − Shipping Cost | Net revenue after all deductions |

---

## Data Cleaning (Power Query)
 
**Key Issues Found:**
 
| Issue | Action Taken |
| :--- | :--- |
| All financial columns stored as text with `$` and `,` | Converted to numeric type via Power Query |
| Date columns stored as strings (text) | Converted to DATE type |
| 4 derived columns (*Sub Total*, *Discount $*, *Order Total*, *Total*) had mathematical inconsistencies across ~99% of rows | Recalculated using valid raw input data |
| 1 completely blank row | Removed / Deleted |
| 4 rows: Cost Price > Retail Price but with positive Profit Margin (mathematical contradiction) | Margin recalculated — resulted in negative values, kept as a valid business finding |

**Before vs After:**
```
Rows              : 5,000 → 4,999
Math Consistency  : 0.76% → 99.98%
Null Values       : 1 blank row → 0
```
 
> 💡 **Data Cleaning Decision Note:**
> Sub Total, Discount Dollar, Order Total, and Total columns had near-universal mathematical inconsistencies — likely caused by data entry errors at the source system. All four derived columns were recalculated from raw inputs (Retail Price, Quantity, Discount %, Shipping Cost) which proved 99.56% consistent after verification.

---

## Key Insights
 
```
1. Revenue $5.19M — Net Profit $2.14M (41.2% margin)
58.8% gap eroded by COGS, discount, and shipping.

2. Furniture has the highest gross margin (51.4%)
but the highest leakage rate (14.5%) — the issue is
in the discount + shipping policy, not the product.

3. Furniture × Corporate and × Consumer both have a
14.8% leakage rate → Corporate is the dominant buyer
(92 orders) with the highest avg shipping cost ($4.97).

4. Corporate contributes 34.4% net profit —
but with the existing leakage, this number
is not yet optimal.

5. 7 products (1.5% SKU) support 50% of gross profit
→ high concentration risk.
```
 
---
 
## Recommendations
 
## Recommendations
 
| Priority | Action |
|---|---|
| 🔴 High | Revise Discount Policy for Furniture × Corporate & Consumer Product Categories. The discounts given to Corporate and Consumer in Furniture do not consider that this category already has a structural cost disadvantage from shipping. The solution is not to eliminate discounts, but to adjust the maximum discount % for Furniture by including "cost to serve" (shipping) as a variable in the discount formula. Expected impact: Reduce Furniture leakage from 14.5% to <11%. |
| 🟡 Medium | Diversify from Long Tail to Core. From 436 products in the Long Tail, identify which products have the highest margin but low volume. Provide promotional push or more visibility to these products so that they can increase in volume and "move up" to Core. Expected Impact: Diversify profit base from 7 to 15+ products. |
| 🟡 Medium | Protect The Head. The 7 products that generate 50% profit must be prioritized in terms of: stock availability, shipping SLA, and not being subjected to aggressive discount experiments. Once there is a disruption at this level, it will be immediately felt on the bottom line. Expected Impact: Protect $1.17M gross profit (The Head) from disruption. |

---
 
## Analysis Method
 
```
Primary   : Product Profitability Analysis
Secondary : Pareto Analysis (80/20 Rule)
Supporting: Profit Leakage Analysis
            Customer Segment Profitability Analysis
```
 
## KPI Framework
 
| KPI | Formula | Result |
|---|---|---|
| Gross Profit Margin % | Gross Profit / Gross Revenue × 100 | 46.6% |
| Net Profit Margin % | Net Profit / Gross Revenue × 100 | 41.2% |
| Total Leakage Rate | (Discount + Shipping) / Gross Profit × 100 | 11.6% |
| Net Profit Contribution % per Segment | Net Profit Segment / Total Net Profit × 100 | Corporate 34.4% |
| Pareto Concentration Ratio | % Profit from Top 1.5% SKUs | 50% |
 
---
 
## Tools
 
| Tool | Purpose |
|---|---|
| Excel Power Query | Data cleaning, type conversion, derived column recalculation |
| MySQL Workbench 8.0 | EDA queries, window functions, CTEs |
| Tableau Public 2026.1 | Interactive dashboard, KPI cards, heatmap, Pareto chart |
 
---