# Olist SQL Business Intelligence

End-to-end business intelligence project on 100k+ real Brazilian e-commerce orders from Olist.

This project goes beyond writing SQL queries. It is structured as a full analytics workflow:
- SQL for data exploration, data quality auditing, KPI logic, segmentation, and business analysis
- R for charting, exploratory visuals, and analytical validation
- Excel for analyst-friendly reporting packs and last-mile business review outputs
- Power BI for stakeholder-facing dashboards and interactive presentation of final insights

The goal is to analyze the marketplace from the perspective of the operator: how the business grows, where revenue is concentrated, how customers behave, how sellers and products perform, and where operational weaknesses exist.

---

## Project Status
In Progress - Advanced analytics built in SQL, with reporting and dashboard delivery layers being added through Excel and Power BI.

Current state:
- Core EDA and data quality work completed
- Overview metrics completed
- Geolocation exploration completed
- Distribution exploration completed
- Business performance completed
- Customer behaviour completed
- RFM analysis completed
- Cohort analysis completed
- Seller performance completed
- Product intelligence completed
- Review, logistics, payment, reporting, and validation layers still being expanded

---

## What This Project Demonstrates
- Translating business questions into structured SQL analysis
- Auditing raw marketplace data before trusting downstream metrics
- Building reusable analytical logic for customer, seller, and product performance
- Converting SQL outputs into chart-ready datasets for downstream reporting
- Combining technical analysis with business storytelling rather than stopping at query output

---

## Business Questions Covered

### 1. Business Performance
- How are monthly orders, revenue, and average order value changing over time?
- Which months are the strongest and weakest by revenue?
- How much of monthly business comes from new customers versus repeat customers?
- How concentrated is total revenue across customers, sellers, and products?

### 2. Customer Behaviour
- How many orders does a typical customer place?
- What share of customers purchase only once versus more than once?
- How long does it typically take for a customer to place a second order?
- Do repeat customers spend more or buy more items per order?

### 3. Customer Segmentation
- How should recency, frequency, and monetary value be measured at customer level?
- Which RFM segments drive the most orders and revenue?
- Which segments appear most at risk of churn?

### 4. Cohort Retention
- What share of each customer cohort returns in later months?
- Where does retention drop off most sharply?
- Which cohorts retain best and generate the most revenue over time?

### 5. Seller Performance
- Which sellers lead in revenue, orders, and units sold?
- How concentrated is seller-side marketplace performance?
- Are top sellers also stronger in reviews and delivery outcomes?
- Which leading sellers are growing and which are declining?

### 6. Product Intelligence
- Which products and categories lead revenue, volume, and order frequency?
- How concentrated is sales performance across products and categories?
- Which products are high-volume/low-value versus high-value/low-volume?
- Which categories show the strongest repeat purchase demand?

### 7. Remaining Buildout
- Review patterns
- Logistics quality
- Payment behaviour
- Final report tables
- Cross-check validation layer
- Excel reporting pack
- Power BI dashboard

---

## Dataset
- **Source:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- **Size:** 100k+ orders across 9 tables
- **Period:** September 2016 to October 2018
- **Context:** Olist is a Brazilian marketplace connecting small businesses to customers nationwide

Core entities used:
- orders
- customers
- sellers
- order_items
- order_payments
- order_reviews
- products
- product_category_name_translation
- geolocation

---

## Assumptions and Definitions

Read this section before interpreting any figures in the project.

**Perspective**  
All analysis is framed around what Olist as the marketplace operator can influence, incentivize, or act upon.

**GMV / Revenue**  
Throughout the project, GMV is defined as total customer payment value per delivered order, inclusive of freight. GMV and revenue are used interchangeably. Source column: `payment_value` from `order_payments`.

**Commission Rate**  
During the dataset period, Olist's commission structure covered partner marketplace fees plus its own operating margin. This project uses a conservative midpoint assumption of **~20%** as the effective commission rate applied to delivered GMV.

The commonly repeated 10% figure seen in some online notebooks is not used here.

**Scope**  
Main business calculations are based on confirmed and successfully delivered orders unless a section explicitly states otherwise. Cancelled, unavailable, or undelivered orders are excluded from core performance metrics.

**Customer Identity**  
`customer_unique_id` is treated as the real customer identifier.  
`customer_id` is order-instance specific and should not be used as the long-term customer key.

---

## Tools
- Microsoft SQL Server
- T-SQL
- R
- ggplot2
- Excel
- Power BI
- Git / GitHub

Tool roles in this project:
- **SQL Server / T-SQL:** core analysis, data quality checks, metric definitions, segmentation, and business logic
- **R / ggplot2:** exploratory charting, distribution visuals, and analytical support graphics
- **Excel:** reporting pack layer for analyst-friendly summaries, pivots, and business review tables
- **Power BI:** stakeholder-facing dashboard layer for interactive KPI and insight presentation

Excel and Power BI are being integrated as the final business delivery layer so the project shows not only analysis, but also reporting and stakeholder communication.

---

## Workflow
1. Explore database structure, grain, and date ranges
2. Audit nulls, duplicates, invalid values, consistency, and inferred referential integrity
3. Build overview metrics to establish platform scale and operating health
4. Develop business-theme SQL analysis files
5. Export selected SQL outputs to CSV
6. Visualize analytical outputs in R
7. Package key outputs into Excel and Power BI for business-facing delivery

---

## Current Findings

These are partial findings from the work completed so far and will be expanded as the remaining themes are finished.

### Platform Scale and Operating Health
- The dataset contains **99,441 total orders**, **96,096 unique customers**, **3,095 sellers**, and **32,951 products**
- Based on delivered orders, approximately **32,216 products** have been sold across **73 product categories**
- Delivered GMV is approximately **15.42M**, implying estimated platform revenue of roughly **3.08M** under the 20% commission assumption
- Average order value is about **159.86**
- Average review score is about **4.09 / 5**
- Average delivery time is about **12 days**, with a **10-day median**
- Freight accounts for roughly **14.25% of GMV**

### Customer Behaviour
- The customer base is overwhelmingly one-time: roughly **97%** of customers purchase only once
- Repeat behaviour is weak, with only about **3%** of customers placing more than one order
- Customers who do return typically place their second order about **29 days** after their first purchase when measured by the median
- Repeat customers buy slightly more items per order, but one-time customers currently appear to spend more per order on average

### Revenue Concentration
- Revenue is moderately concentrated at customer level: the **top 20% of customers generate about 53.5% of GMV**
- Seller concentration is much stronger: the **top 20% of sellers generate about 82% of GMV**
- Product concentration is also high: the **top 20% of products generate about 73% of GMV**
- Overall, marketplace value is driven disproportionately by a relatively small share of sellers and products

### Customer Segmentation and Retention
- Current RFM segmentation suggests a very large share of customers fall into lower-engagement groups such as **Needs Attention** and **Hibernating**
- High-value groups such as **Champions** and **Loyalists** are small in number, even though they spend more on average
- Cohort retention is weak overall, with most cohorts dropping sharply after the first purchase month
- The project so far points to a marketplace that is much stronger at acquisition than retention

### Geography and Marketplace Structure
- Customer demand is concentrated geographically, with Sao Paulo representing the largest customer base
- Seller supply is even more concentrated, with Sao Paulo dominating seller presence
- Roughly **63%** of item units move across regions rather than staying within the same state flow
- This suggests the marketplace relies heavily on cross-region fulfillment rather than purely local matching

### Product and Seller Insights
- Category leadership is concentrated in a relatively small number of standout categories
- High-volume products and high-value products are often not the same products
- Top categories tend to show more stable growth than individual top products
- Among top sellers, growth is uneven, with a few strong gainers carrying much of the upside

---

## Project Structure
| Folder | Purpose |
|---|---|
| `01_eda` | Database exploration, grain checks, data quality checks, overview metrics, geolocation analysis, and distribution analysis |
| `02_analytics` | Core business analysis by theme: performance, customer behaviour, RFM, cohort retention, seller performance, product intelligence, and upcoming review/logistics/payment work |
| `03_reports` | Final report-layer SQL outputs for business-ready summary tables |
| `04_validation` | Cross-check and reconciliation logic to verify core numbers |
| `data` | Source flat files and supporting data assets |
| `graph_materials/csv` | Exported CSV files used as inputs for charts and downstream reporting |
| `graph_materials/scripts` | R scripts for EDA, analytics, report, and validation visuals |
| `notes` | Local project notes and connection notes |

---

## Reporting Layer

The project is being extended beyond pure SQL analysis into business-facing delivery.

### Excel
Planned use:
- analyst-friendly report tables
- pivot-based summary views
- quick review packs for stakeholders
- last-mile validation and business review outputs

### Power BI
Planned use:
- executive overview dashboard
- customer retention and segmentation dashboard
- seller and product performance dashboard
- operational quality dashboard

This helps position the project as a realistic end-to-end analytics case rather than a query-only repository.

---

## Why This Project Is Different
- It starts with data structure and quality instead of jumping straight into charts
- It documents assumptions explicitly before calculating business metrics
- It focuses on business interpretation, not only technical correctness
- It separates analytical logic, reporting outputs, and visualization layers
- It is being built toward the same workflow many real analyst roles use: SQL -> analysis -> reporting -> dashboard delivery

---

## Next Steps
- Complete review patterns, logistics quality, and payment behaviour analyses
- Populate `03_reports` with finalized report tables
- Build `04_validation/cross_checks.sql`
- Add Excel-based reporting outputs
- Add Power BI dashboard artifacts and screenshots
- Expand the findings section once the remaining themes are complete

---

## References
- Olist. (n.d.). *Comissão e frete: As 3 regras que você precisa saber.* https://blog.olist.com/3-regras-comissao-e-frete-olist/
- Bling Blog. (2022, March 7). *Nova regra de comissão e frete do Olist.* https://blog.bling.com.br/nova-regra-de-comissao-e-frete-do-olist-como-funciona-e-quais-sao-as-vantagens/
- Chen, D., Sakia, S., & Olist. (2018). *Brazilian E-Commerce Public Dataset by Olist* [Dataset]. Kaggle. https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

---

## Author
Nguyen Duong  
[GitHub](https://github.com/steven2512) · [LinkedIn](https://www.linkedin.com/in/nguyenduong251202/)
