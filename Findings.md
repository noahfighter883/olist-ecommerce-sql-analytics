
# Findings: Olist E-Commerce SQL Analysis

These are the results from running `02_queries.sql` against the live Olist dataset
(about 99k orders, 2016 to 2018). Each one follows the same format: the business
question, how I answered it in SQL, and what the data actually showed.

## 1. Revenue grew steadily, with a clear Black Friday spike

**Question:** How has order volume and revenue trended over time?
**Approach:** Query 1.1, monthly order count and revenue, filtered to delivered orders.
**Finding:** Revenue climbed from almost nothing in late 2016 to a steady ~$1M/month by
late 2017 and held there through mid-2018. November 2017 is the clear standout: 7,289
orders and $1.15M in revenue, a 53.6% jump from the month before (query 2.1), which
lines up with Black Friday. After that, growth flattened out instead of continuing to
climb, so the platform seems to have hit a stable plateau rather than kept scaling.

## 2. Revenue is concentrated in a few categories, and it's not the ones selling the most units

**Question:** Which product categories actually drive the business?
**Approach:** Query 1.2, items sold and revenue by category, using a left join to the
translation table for English category names.
**Finding:** Bed, bath, and table products sell the most units by far (11,115) but
health and beauty brings in more total revenue ($1.26M vs $1.04M) on fewer items sold
(9,670). Watches and gifts is the real outlier here: only 5,991 items sold but $1.2M in
revenue, almost matching the top category despite much lower volume. That tells you
volume and revenue leaders aren't the same categories, which matters if you're deciding
where to focus inventory versus where the margin actually is.

## 3. The business is heavily concentrated in São Paulo

**Question:** Where are customers actually located, and does that matter for logistics?
**Approach:** Query 1.3, order count grouped by customer state.
**Finding:** São Paulo alone accounts for 41,746 of about 99,441 total orders, roughly
42% of everything. That's more than the next five states combined. This concentration
shows up again in the seller data below, where most of the top sellers by revenue are
also SP-based, which makes sense given the shipping advantage of being in-state.

## 4. Most deliveries finish within two weeks, but late ones really hurt satisfaction

**Question:** How reliable is delivery, and does it affect how customers feel about
their order?
**Approach:** Query 1.4 for the delivery time distribution, and query 3.2 comparing
review scores for on-time versus late deliveries.
**Finding:** Most orders (33,050) arrive within 5 to 10 days, and things drop off
sharply after 15 days. But delivery timing has a real effect on how people rate their
experience: orders delivered on time or early average a 4.29 review score, while late
ones average just 2.57. That's a 1.7-point swing on a 5-point scale from one factor
alone. Late deliveries are a minority of orders, about 8%, but they're doing a lot of
damage to overall satisfaction.

## 5. Customers are almost entirely one-time buyers

**Question:** Do customers actually come back and order again?
**Approach:** Query 2.3, cohort sizing by each customer's first purchase month.
**Finding:** Cohort sizes basically track new customer acquisition month over month,
and the RFM query (3.1) confirms it directly: even the highest-scoring customers by
recency, frequency, and monetary value only placed 1 to 3 orders total. This looks like
a real feature of how Olist works (it's a marketplace aggregating many small sellers,
so there's less reason for a customer to come back to any one seller specifically)
rather than a data issue. Worth stating plainly as a finding instead of treating
retention like something this dataset can really speak to.

## 6. Seller performance splits along geography and delivery reliability

**Question:** Which sellers perform best, and what separates the top ones from the rest?
**Approach:** Query 3.3, seller revenue, order count, average review score, and late
delivery rate, limited to sellers with at least 10 orders.
**Finding:** Almost all of the top 10 sellers by revenue are based in São Paulo. Late
delivery rate varies a fair amount across them, from about 4% up to nearly 12%, and it
loosely tracks with review score. Sellers under 6% late tend to sit around 4.3 or
higher in average reviews, while sellers above 10% late tend to sit closer to 3.8 or
4.1. It's not a perfectly clean relationship, but it points in the same direction as
finding 4.

## 7. Bigger purchases get paid off in installments, a distinctly Brazilian pattern

**Question:** How does payment behavior change as order size goes up?
**Approach:** Query 3.4, average payment installments grouped by order value bracket.
**Finding:** Average installments scale directly with order size, from 1.5 installments
on orders under R$50 up to 6.0 installments on orders over R$500. This reflects a
common Brazilian consumer credit habit called parcelamento, and it's the kind of thing
that would matter if you were modeling cash flow or payment processing costs for a
marketplace like this.

---

*Data source: [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
on Kaggle. Orders span September 2016 to August 2018. All revenue figures are in BRL.*
