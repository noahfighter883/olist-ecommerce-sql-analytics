-- Olist Brazilian E-Commerce Dataset — Schema
-- Target: Postgres (Supabase)
-- Source CSVs: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
-- Load order matters for FK constraints: customers/sellers/products first,
-- then orders, then order_items/payments/reviews.

drop table if exists order_reviews cascade;
drop table if exists order_payments cascade;
drop table if exists order_items cascade;
drop table if exists orders cascade;
drop table if exists products cascade;
drop table if exists sellers cascade;
drop table if exists customers cascade;
drop table if exists geolocation cascade;
drop table if exists product_category_translation cascade;

create table customers (
    customer_id varchar primary key,
    customer_unique_id varchar not null,
    customer_zip_code_prefix varchar,
    customer_city varchar,
    customer_state varchar
);

create table sellers (
    seller_id varchar primary key,
    seller_zip_code_prefix varchar,
    seller_city varchar,
    seller_state varchar
);

create table product_category_translation (
    product_category_name varchar primary key,
    product_category_name_english varchar
);

-- Note: product_category_name is intentionally NOT a foreign key to
-- product_category_translation. A handful of categories in the raw Kaggle
-- products file (e.g. 'pc_gamer') are missing from the translation file,
-- so a strict FK rejects valid product rows. Queries use a LEFT JOIN to
-- translation and fall back to the Portuguese name when no match exists.
--
-- Column names product_name_lenght / product_description_lenght intentionally
-- keep the original dataset's misspelling ("lenght") so they match the raw
-- Kaggle CSV headers exactly for a clean \copy import.
create table products (
    product_id varchar primary key,
    product_category_name varchar,
    product_name_lenght int,
    product_description_lenght int,
    product_photos_qty int,
    product_weight_g numeric,
    product_length_cm numeric,
    product_height_cm numeric,
    product_width_cm numeric
);

create table orders (
    order_id varchar primary key,
    customer_id varchar references customers(customer_id),
    order_status varchar,
    order_purchase_timestamp timestamp,
    order_approved_at timestamp,
    order_delivered_carrier_date timestamp,
    order_delivered_customer_date timestamp,
    order_estimated_delivery_date timestamp
);

create table order_items (
    order_id varchar references orders(order_id),
    order_item_id int,
    product_id varchar references products(product_id),
    seller_id varchar references sellers(seller_id),
    shipping_limit_date timestamp,
    price numeric,
    freight_value numeric,
    primary key (order_id, order_item_id)
);

create table order_payments (
    order_id varchar references orders(order_id),
    payment_sequential int,
    payment_type varchar,
    payment_installments int,
    payment_value numeric,
    primary key (order_id, payment_sequential)
);

create table order_reviews (
    review_id varchar,
    order_id varchar references orders(order_id),
    review_score int,
    review_comment_title varchar,
    review_comment_message text,
    review_creation_date timestamp,
    review_answer_timestamp timestamp,
    primary key (review_id, order_id)
);

create table geolocation (
    geolocation_zip_code_prefix varchar,
    geolocation_lat numeric,
    geolocation_lng numeric,
    geolocation_city varchar,
    geolocation_state varchar
);

-- Helpful indexes for the analytical queries in 02_queries.sql
create index idx_orders_purchase_ts on orders(order_purchase_timestamp);
create index idx_order_items_order on order_items(order_id);
create index idx_order_items_product on order_items(product_id);
create index idx_order_payments_order on order_payments(order_id);
create index idx_order_reviews_order on order_reviews(order_id);
