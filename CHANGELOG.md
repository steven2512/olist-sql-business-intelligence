## Session 19 - 2 Apr 2026
- Finished `01_business_performance.sql`
- Added concentration analysis across customers, sellers, and products, with supporting top-N chart inputs
- Began `02_customer_behaviour.sql` with early customer frequency and repeat purchase analysis
- Added one-time versus repeat customer comparisons for average order value and items per order

## Session 18 - 1 Apr 2026
- Updated `README.md` to reflect the Analytics Phase
- Added top-N customer revenue concentration analysis to `01_business_performance.sql`

## Session 17 - 31 Mar 2026
- Added the first stacked bar chart version for monthly new versus repeat customer mix
- Exported supporting customer mix CSVs and linked them into the analytics graph workflow

## Session 16 - 30 Mar 2026
- Added monthly order, revenue, and average order value trend analysis to `01_business_performance.sql`
- Added strongest and weakest month comparisons by revenue
- Added monthly business contribution analysis for new versus repeat customers

## Session 15 - 29 Mar 2026
- Finalised `05_distribution_exploration.sql` with payment installment distribution
- Added `.gitignore` and reorganised `graph_materials/` into a cleaner CSV and scripts structure
- Began `01_business_performance.sql` and added the first analytics graph script

## Session 14 - 28 Mar 2026
- Added freight ratio, delivery time, and seller distribution analysis
- Exported supporting CSVs for the new distribution charts
- Continued refining graph scripts for EDA visuals

## Session 13 - 27 Mar 2026
- Added order value distribution exports and graph support files
- Continued building the visual analysis workflow for `05_distribution_exploration.sql`

## Session 12 - 25 Mar 2026
- Expanded `05_distribution_exploration.sql` for visual distribution analysis
- Added chart inputs for hour-of-day and day-of-week order patterns
- Refined distribution structure and supporting notes before further analysis

## Session 11 - 24 Mar 2026
- Began `05_distribution_exploration.sql`
- Added distribution analysis for order value and freight value
- Documented summary statistics and interpretation for both distributions

## Session 10 - 22 Mar 2026
- Completed `04_geolocation_exploration.sql`
- Added customer and seller geographic coverage analysis by state
- Documented cross-region order flow and remaining geolocation quality issues

## Session 9 - 21 Mar 2026
- Finalised `03_overview_metrics.sql`
- Added further analysis on delivery, reviews, and freight contribution to GMV
- Refined and simplified `README.md` ahead of the analytics phase

## Session 8 - 20 Mar 2026
- Reorganised remaining analytics files for a cleaner analysis structure
- Began `03_overview_metrics.sql` with platform scale, GMV, and average order value
- Added initial operational health findings and documented key quality consistencies

## Session 7 - 19 Mar 2026
- Completed '02_data_quality.sql' with all remaining checks
- Built dynamic stored procedures negative_checks and zero_checks for negative and zero value detection across all columns of all tables
- Added consistency, sequential integrity, and referential integrity checks
- Added discrete domain checks on categorical columns across all tables

## Session 6 - 18 Mar 2026
- Finalised `01_database_exploration.sql` and began `02_data_quality.sql`
- Built dynamic stored procedures `sp_null_counter` and `duplicate_counts` 
  for null and duplicate detection across all tables
- Documented findings for both checks

## Session 5 - 17 Mar 2026
- Added date range analysis for `orders`, `order_items`, and `order_reviews`
- Resolved outstanding issues in `01_database_exploration.sql`
- Confirmed `01_database_exploration.sql` complete; ready to move to `02_data_quality.sql`

## Session 4 - 16 Mar 2026
- Completed grain analysis for `order_payments` and `order_items`
- Finalised and simplified grain comment for `order_items`

## Session 3 - 15 Mar 2026
- Continued grain analysis for `order_reviews`, `sellers`, 
  `product_category_name_translation`, and `geolocation`
- Documented geolocation data issues and grain findings
- Began `order_items` grain investigation

## Session 2 - 14 Mar 2026
- Wrote and executed first exploration queries in `01_database_exploration.sql`
- Documented table names, row counts, column counts, and data types for all 9 tables
- Began grain analysis for `orders`, `customers`, and `products`

## Session 1 - 13 Mar 2026
- Initialised repository and set up full project folder structure
- Added `data/` directory with schema diagram and data dictionary
- Wrote and published `README.md`
