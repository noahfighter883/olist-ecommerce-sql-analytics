-- Olist E-Commerce Analytics — Query Set
-- Organized in three tiers so you can build the project incrementally
-- and show progression in your case study/README.

-- =========================================================
-- TIER 1: EXPLORATORY
-- =========================================================

-- 1.1 Monthly order volume and revenue trend
select
    date_trunc('month', o.order_purchase_timestamp) as order_month,
    count(distinct o.order_id) as num_orders,
    round(sum(oi.price + oi.freight_value), 2) as revenue
from orders o
join order_items oi on oi.order_id = o.order_id
where o.order_status = 'delivered'
group by 1
order by 1;

-- 1.2 Revenue by product category (English names)
select
    coalesce(t.product_category_name_english, p.product_category_name, 'unknown') as category,
    count(*) as items_sold,
    round(sum(oi.price), 2) as revenue
from order_items oi
join products p on p.product_id = oi.product_id
left join product_category_translation t on t.product_category_name = p.product_category_name
group by 1
order by revenue desc
limit 15;

-- 1.3 Orders by customer state
select
    c.customer_state,
    count(distinct o.order_id) as num_orders
from orders o
join customers c on c.customer_id = o.customer_id
group by 1
order by num_orders desc;

-- 1.4 Delivery time distribution (days from purchase to delivery)
select
    width_bucket(
        extract(day from (order_delivered_customer_date - order_purchase_timestamp)),
        0, 60, 12
    ) as delivery_days_bucket,
    count(*) as num_orders
from orders
where order_status = 'delivered'
  and order_delivered_customer_date is not null
group by 1
order by 1;

-- =========================================================
-- TIER 2: INTERMEDIATE (window functions, CTEs)
-- =========================================================

-- 2.1 Month-over-month revenue growth %
with monthly as (
    select
        date_trunc('month', o.order_purchase_timestamp) as order_month,
        sum(oi.price + oi.freight_value) as revenue
    from orders o
    join order_items oi on oi.order_id = o.order_id
    where o.order_status = 'delivered'
    group by 1
)
select
    order_month,
    round(revenue, 2) as revenue,
    round(
        (revenue - lag(revenue) over (order by order_month))
        / nullif(lag(revenue) over (order by order_month), 0) * 100
    , 1) as mom_growth_pct
from monthly
order by order_month;

-- 2.2 Running total of revenue by month
select
    date_trunc('month', o.order_purchase_timestamp) as order_month,
    round(sum(oi.price), 2) as monthly_revenue,
    round(sum(sum(oi.price)) over (order by date_trunc('month', o.order_purchase_timestamp)), 2) as running_total
from orders o
join order_items oi on oi.order_id = o.order_id
where o.order_status = 'delivered'
group by 1
order by 1;

-- 2.3 First purchase cohort: are customers coming back?
with first_purchase as (
    select
        customer_unique_id,
        min(date_trunc('month', o.order_purchase_timestamp)) as cohort_month
    from orders o
    join customers c on c.customer_id = o.customer_id
    group by 1
)
select
    cohort_month,
    count(*) as cohort_size
from first_purchase
group by 1
order by 1;
-- Note: Olist is mostly single-purchase customers — a real finding worth
-- calling out in your writeup rather than a limitation to hide.

-- 2.4 Top 5 sellers by revenue per state
with seller_revenue as (
    select
        s.seller_id,
        s.seller_state,
        sum(oi.price) as revenue,
        rank() over (partition by s.seller_state order by sum(oi.price) desc) as state_rank
    from order_items oi
    join sellers s on s.seller_id = oi.seller_id
    group by s.seller_id, s.seller_state
)
select * from seller_revenue where state_rank <= 5 order by seller_state, state_rank;

-- =========================================================
-- TIER 3: ADVANCED
-- =========================================================

-- 3.1 RFM segmentation (Recency, Frequency, Monetary)
with customer_orders as (
    select
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        sum(oi.price) as order_value
    from orders o
    join customers c on c.customer_id = o.customer_id
    join order_items oi on oi.order_id = o.order_id
    where o.order_status = 'delivered'
    group by c.customer_unique_id, o.order_id, o.order_purchase_timestamp
),
rfm as (
    select
        customer_unique_id,
        extract(day from (current_date - max(order_purchase_timestamp))) as recency_days,
        count(distinct order_id) as frequency,
        round(sum(order_value), 2) as monetary
    from customer_orders
    group by customer_unique_id
),
scored as (
    select
        *,
        ntile(4) over (order by recency_days desc) as r_score,
        ntile(4) over (order by frequency asc) as f_score,
        ntile(4) over (order by monetary asc) as m_score
    from rfm
)
select
    customer_unique_id,
    recency_days, frequency, monetary,
    r_score, f_score, m_score,
    (r_score + f_score + m_score) as rfm_total
from scored
order by rfm_total desc
limit 100;

-- 3.2 Delivery delay vs. review score correlation
select
    case
        when order_delivered_customer_date <= order_estimated_delivery_date then 'on_time_or_early'
        else 'late'
    end as delivery_status,
    round(avg(r.review_score), 2) as avg_review_score,
    count(*) as num_orders
from orders o
join order_reviews r on r.order_id = o.order_id
where o.order_status = 'delivered'
  and o.order_delivered_customer_date is not null
group by 1;

-- 3.3 Seller performance ranking: revenue, avg review, late delivery rate
with seller_stats as (
    select
        s.seller_id,
        s.seller_state,
        sum(oi.price) as total_revenue,
        count(distinct oi.order_id) as num_orders,
        avg(r.review_score) as avg_review_score,
        avg(
            case when o.order_delivered_customer_date > o.order_estimated_delivery_date
                 then 1.0 else 0.0 end
        ) as late_delivery_rate
    from order_items oi
    join sellers s on s.seller_id = oi.seller_id
    join orders o on o.order_id = oi.order_id
    left join order_reviews r on r.order_id = o.order_id
    where o.order_status = 'delivered'
    group by s.seller_id, s.seller_state
    having count(distinct oi.order_id) >= 10  -- filter out low-volume noise
)
select
    *,
    round(total_revenue, 2) as revenue,
    round(avg_review_score, 2) as avg_review,
    round(late_delivery_rate * 100, 1) as pct_late
from seller_stats
order by total_revenue desc
limit 20;

-- 3.4 Payment installment behavior by order value bracket
select
    case
        when order_total < 50 then 'under_50'
        when order_total < 150 then '50_150'
        when order_total < 500 then '150_500'
        else 'over_500'
    end as order_value_bracket,
    round(avg(payment_installments), 1) as avg_installments,
    count(*) as num_orders
from (
    select
        op.order_id,
        sum(op.payment_value) as order_total,
        avg(op.payment_installments) as payment_installments
    from order_payments op
    group by op.order_id
) sub
group by 1
order by 1;
