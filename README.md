# Olist E-Commerce SQL Analytics Project

A portfolio project analyzing 100k real Brazilian e-commerce orders (2016–2018)
using Postgres. Focuses on revenue trends, customer segmentation (RFM),
seller performance, and delivery/review correlations.

## Stack
- **Data:** [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle, 9 CSVs, ~52 columns)
- **Database:** Supabase (hosted Postgres, free tier)
- **Analysis:** SQL only — window functions, CTEs, joins across 8 related tables

## Setup

### 1. Get the data
Download the CSVs from Kaggle (requires a free Kaggle account):
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

You'll get 9 files, e.g. `olist_orders_dataset.csv`, `olist_customers_dataset.csv`, etc.

### 2. Create a Supabase project
1. Go to https://supabase.com → New project (free tier is plenty for 100k rows)
2. Open the **SQL Editor** in the Supabase dashboard
3. Paste and run `01_schema.sql` from this project to create the tables

### 3. Load the CSVs
Easiest path: Supabase Table Editor → **Import data from CSV** for each table
(match each CSV to its corresponding table — see the mapping below).
Alternative: use `psql \copy` if you want practice with the CLI.

| CSV file | Table |
|---|---|
| olist_customers_dataset.csv | customers |
| olist_sellers_dataset.csv | sellers |
| product_category_name_translation.csv | product_category_translation |
| olist_products_dataset.csv | products |
| olist_orders_dataset.csv | orders |
| olist_order_items_dataset.csv | order_items |
| olist_order_payments_dataset.csv | order_payments |
| olist_order_reviews_dataset.csv | order_reviews |
| olist_geolocation_dataset.csv | geolocation |

**Load order matters** — load parent tables (customers, sellers, products,
product_category_translation) before orders, and orders before
order_items/order_payments/order_reviews, or the foreign keys will reject rows.

### 4. Run the queries
`02_queries.sql` has three tiers:
- **Tier 1 — Exploratory:** revenue trends, category breakdown, delivery time distribution
- **Tier 2 — Intermediate:** MoM growth, running totals, cohort sizing, window functions
- **Tier 3 — Advanced:** RFM segmentation, delivery-delay vs. review-score correlation, seller scorecards

Run them straight in the Supabase SQL Editor, or connect a local client
(TablePlus, DBeaver, `psql`) using the connection string from
Project Settings → Database.

## Suggested next steps for the case study
1. Pick 3–4 of the more interesting query results (RFM segments, seller
   rankings, delivery/review correlation tend to have the most story)
2. Write up the business question → SQL approach → finding for each,
   same format as the DynastyEvaluator case study
3. Optional stretch: build a tiny Next.js page that runs a couple of these
   queries live against Supabase and renders a chart — turns this from a
   "queries in a repo" project into something with a live URL for your portfolio
