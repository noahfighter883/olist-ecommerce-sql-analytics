# Olist E-Commerce SQL Analytics Project

A portfolio project analyzing 100k real Brazilian e-commerce orders (2016 to 2018)
using Postgres. It covers revenue trends, customer segmentation (RFM), seller
performance, and how delivery delays relate to review scores.

Full write-up: [FINDINGS.md](./FINDINGS.md)

A couple of highlights: revenue has a clear Black Friday spike in November 2017, and
late deliveries drop the average review score from 4.29 to 2.57, a bigger swing than
you'd expect from timing alone.

## Stack
- **Data:** [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle, 9 CSVs, about 52 columns)
- **Database:** Supabase (hosted Postgres, free tier)
- **Analysis:** SQL only, no other tools. Joins across 8 related tables, window functions, CTEs.

## What's in this repo
- `01_schema.sql`, table definitions, matching what's actually live in the database
- `02_queries.sql`, all the analysis queries, tiered by difficulty
- `FINDINGS.md`, the write-up of what came out of running these queries
- `.gitignore`, keeps the raw CSVs out of the repo since they're not mine to redistribute

## Possible next steps
A small Next.js page that runs a couple of these queries live against Supabase and
renders a chart or two would turn this from "queries in a repo" into something with a
live URL, similar to how the DynastyEvaluator project works.

---

## Setup (if you want to reproduce this)

### 1. Get the data
Download the CSVs from Kaggle (you'll need a free Kaggle account):
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

You'll get 9 files, things like `olist_orders_dataset.csv` and `olist_customers_dataset.csv`.

### 2. Create a Supabase project
1. Go to https://supabase.com and start a new project (the free tier handles 100k rows fine)
2. Open the **SQL Editor** in the dashboard
3. Paste and run `01_schema.sql` from this repo to create the tables

### 3. Load the CSVs
The most reliable way is `psql` and its `\copy` command, run from a terminal connected
directly to the database (the browser-based CSV importer in Supabase's Table Editor can
be flaky on larger files). Grab your connection string from **Connect** in the Supabase
dashboard. If you're on a home network, use the **session pooler** connection string
rather than the direct connection, since direct connections default to IPv6 and most
home networks won't reach that.

```bash
psql 'your-session-pooler-connection-string'
```

Then, in order:

```sql
\copy customers from '/path/to/olist_customers_dataset.csv' with (format csv, header true);
\copy sellers from '/path/to/olist_sellers_dataset.csv' with (format csv, header true);
\copy product_category_translation from '/path/to/product_category_name_translation.csv' with (format csv, header true);
\copy products from '/path/to/olist_products_dataset.csv' with (format csv, header true);
\copy orders from '/path/to/olist_orders_dataset.csv' with (format csv, header true);
\copy order_items from '/path/to/olist_order_items_dataset.csv' with (format csv, header true);
\copy order_payments from '/path/to/olist_order_payments_dataset.csv' with (format csv, header true);
\copy order_reviews from '/path/to/olist_order_reviews_dataset.csv' with (format csv, header true);
\copy geolocation from '/path/to/olist_geolocation_dataset.csv' with (format csv, header true);
```

The order matters here. Parent tables (customers, sellers, products,
product_category_translation) have to load before orders, and orders has to load before
order_items, order_payments, and order_reviews, or the foreign keys will reject the rows.

**Note on the data itself:** a handful of product categories in the raw file (like
`pc_gamer`) don't actually exist in the translation file, so `product_category_name`
isn't set up as a strict foreign key. The queries handle this with a left join and fall
back to the Portuguese name when there's no English translation.

### 4. Run the queries
`02_queries.sql` is organized into three tiers:
- **Tier 1, exploratory:** revenue trends, category breakdown, delivery time distribution
- **Tier 2, intermediate:** month-over-month growth, running totals, cohort sizing, window functions
- **Tier 3, advanced:** RFM segmentation, delivery delay vs. review score, seller scorecards

Run them in the Supabase SQL Editor, or straight in `psql` if you're already connected
from the load step above.
