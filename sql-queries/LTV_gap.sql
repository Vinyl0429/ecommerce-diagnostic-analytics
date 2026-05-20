SELECT *
INTO #ecom_sales_clean
FROM e_commerce.ecom_sales
WHERE region_code != 'RRR0001'
  AND product_code NOT IN ('PPP000002', 'PPP000010');


--- LTV by cust_type
with customer_base as(
    select
        customer_id,
        order_id,
        sales,
        profit,
        order_date
    from #ecom_sales_clean as sales
    join e_commerce.region as region on sales.region_code = region.region_code
),
customer_history as(
    select
        customer_id,
        order_id,
        sum(profit) as total_profit,
        sum(sales) as total_revenue,
        MAX(order_date) order_date
    from customer_base
    group by customer_id, order_id
),
days_between_orders as (
    select
        customer_id,
        order_id,
        order_date,
        total_profit,
        total_revenue,
        lag(order_date) over (partition by customer_id order by order_date) as prev_order_date,
        datediff(day, lag(order_date) over (partition by customer_id order by order_date), order_date) as days_between_orders
    from customer_history
),
customer_base_metrics as (
    select
        customer_id,
        count(distinct order_id) as total_orders,
        sum(total_profit) CLTV,
        sum(total_revenue) /  count(distinct order_id) AOV,
        avg(days_between_orders) avg_days_between_orders
    from days_between_orders
    group by customer_id
),
customer_classification as(
    select
        customer_id,
        total_orders,
        CLTV,
        AOV,
        avg_days_between_orders,
        case
            when total_orders = 1 then 'One-time'
            when total_orders > 1 then 'Repeat'
        end as customer_type
    from customer_base_metrics
)
select
    customer_type,
    avg(CLTV) avg_CLTV,
    avg(case when customer_type = 'One-time' then CLTV else NULL end) as onetime_CTVL,
    avg(case when customer_type = 'Repeat' then CLTV else NULL end) as repeat_CTVL,
    avg(case when customer_type = 'Repeat' then CLTV else NULL end)
        - avg(case when customer_type = 'One-time' then CLTV else NULL end) as CLTV_gap,
    sum(case when customer_type = 'Repeat' then 1 else 0 end) * 1.0 / count(distinct customer_id) as repeat_rate,
    avg(case when customer_type = 'Repeat' then avg_days_between_orders else null end) avg_days_to_repeat
from customer_classification
group by customer_type
;

with customer_base as(
    select
        customer_id,
        order_id,
        sales,
        profit,
        order_date
    from #ecom_sales_clean as sales
    join e_commerce.region as region on sales.region_code = region.region_code
),
customer_history as(
    select
        customer_id,
        order_id,
        sum(profit) as total_profit,
        sum(sales) as total_revenue,
        MAX(order_date) order_date
    from customer_base
    group by customer_id, order_id
),
days_between_orders as (
    select
        customer_id,
        order_id,
        order_date,
        total_profit,
        total_revenue,
        lag(order_date) over (partition by customer_id order by order_date) as prev_order_date,
        datediff(day, lag(order_date) over (partition by customer_id order by order_date), order_date) as days_between_orders
    from customer_history
),
customer_base_metrics as (
    select
        customer_id,
        count(distinct order_id) as total_orders,
        sum(total_profit) CLTV,
        sum(total_revenue) /  count(distinct order_id) AOV,
        avg(days_between_orders) avg_days_between_orders
    from days_between_orders
    group by customer_id
),
customer_classification as(
    select
        customer_id,
        total_orders,
        CLTV,
        AOV,
        avg_days_between_orders,
        case
            when total_orders = 1 then 'One-time'
            when total_orders > 1 then 'Repeat'
        end as customer_type
    from customer_base_metrics
)
select
    count(distinct customer_id) total_customers,
    avg(CLTV) avg_CLTV,
    avg(case when customer_type = 'One-time' then CLTV else NULL end) as onetime_CTVL,
    avg(case when customer_type = 'Repeat' then CLTV else NULL end) as repeat_CTVL,
    avg(case when customer_type = 'Repeat' then CLTV else NULL end)
        - avg(case when customer_type = 'One-time' then CLTV else NULL end) as CLTV_gap,
    sum(case when customer_type = 'Repeat' then 1 else 0 end) * 1.0 / count(distinct customer_id) as repeat_rate,
    avg(case when customer_type = 'Repeat' then avg_days_between_orders else null end) avg_days_to_repeat
from customer_classification;

--- LTV by market
with customer_base as(
    select
        market,
        customer_id,
        order_id,
        sales,
        profit,
        order_date
    from #ecom_sales_clean as sales
    join e_commerce.region as region on sales.region_code = region.region_code
),
customer_history as(
    select
        market,
        customer_id,
        order_id,
        sum(profit) as total_profit,
        sum(sales) as total_revenue,
        MAX(order_date) order_date
    from customer_base
    group by market, customer_id, order_id
),
days_between_orders as (
    select
        market,
        customer_id,
        order_id,
        order_date,
        total_profit,
        total_revenue,
        lag(order_date) over (partition by customer_id order by order_date) as prev_order_date,
        datediff(day, lag(order_date) over (partition by customer_id order by order_date), order_date) as days_between_orders
    from customer_history
),
customer_base_metrics as (
    select
        market,
        customer_id,
        count(distinct order_id) as total_orders,
        sum(total_profit) CLTV,
        sum(total_revenue) /  count(distinct order_id) AOV,
        avg(days_between_orders) avg_days_between_orders
    from days_between_orders
    group by market, customer_id
),
customer_classification as(
    select
        market,
        customer_id,
        total_orders,
        CLTV,
        AOV,
        avg_days_between_orders,
        case
            when total_orders = 1 then 'One-time'
            when total_orders > 1 then 'Repeat'
        end as customer_type
    from customer_base_metrics
)
select
    market,
    avg(CLTV) avg_CLTV,
    avg(case when customer_type = 'One-time' then CLTV else NULL end) as onetime_CTVL,
    avg(case when customer_type = 'Repeat' then CLTV else NULL end) as repeat_CTVL,
    avg(case when customer_type = 'Repeat' then CLTV else NULL end)
        - avg(case when customer_type = 'One-time' then CLTV else NULL end) as CLTV_gap,
    sum(case when customer_type = 'Repeat' then 1 else 0 end) * 1.0 / count(distinct customer_id) as repeat_rate,
    avg(case when customer_type = 'Repeat' then avg_days_between_orders else null end) avg_days_to_repeat
from customer_classification
group by market
;

--- LTV by segment
with customer_base as(
    select
        segment,
        customer_id,
        order_id,
        sales,
        profit,
        order_date
    from #ecom_sales_clean as sales
),
customer_history as(
    select
        segment,
        customer_id,
        order_id,
        sum(profit) as total_profit,
        sum(sales) as total_revenue,
        MAX(order_date) order_date
    from customer_base
    group by segment, customer_id, order_id
),
days_between_orders as (
    select
        segment,
        customer_id,
        order_id,
        order_date,
        total_profit,
        total_revenue,
        lag(order_date) over (partition by customer_id order by order_date) as prev_order_date,
        datediff(day, lag(order_date) over (partition by customer_id order by order_date), order_date) as days_between_orders
    from customer_history
),
customer_base_metrics as (
    select
        segment,
        customer_id,
        count(distinct order_id) as total_orders,
        sum(total_profit) CLTV,
        sum(total_revenue) /  count(distinct order_id) AOV,
        avg(days_between_orders) avg_days_between_orders
    from days_between_orders
    group by segment, customer_id
),
customer_classification as(
    select
        segment,
        customer_id,
        total_orders,
        CLTV,
        AOV,
        avg_days_between_orders,
        case
            when total_orders = 1 then 'One-time'
            when total_orders > 1 then 'Repeat'
        end as customer_type
    from customer_base_metrics
)
select
    segment,
    avg(CLTV) avg_CLTV,
    avg(case when customer_type = 'One-time' then CLTV else NULL end) as onetime_CTVL,
    avg(case when customer_type = 'Repeat' then CLTV else NULL end) as repeat_CTVL,
    avg(case when customer_type = 'Repeat' then CLTV else NULL end)
        - avg(case when customer_type = 'One-time' then CLTV else NULL end) as CLTV_gap,
    sum(case when customer_type = 'Repeat' then 1 else 0 end) * 1.0 / count(distinct customer_id) as repeat_rate,
    avg(case when customer_type = 'Repeat' then avg_days_between_orders else null end) avg_days_to_repeat
from customer_classification
group by segment;

--- LTV by category
with customer_base as(
    select
        category,
        customer_id,
        order_id,
        sales,
        profit,
        order_date
    from #ecom_sales_clean as sales
    inner join e_commerce.product as product on sales.product_code = product.product_code
),
customer_history as(
    select
        category,
        customer_id,
        order_id,
        sum(profit) as total_profit,
        sum(sales) as total_revenue,
        MAX(order_date) order_date
    from customer_base
    group by category, customer_id, order_id
),
days_between_orders as (
    select
        category,
        customer_id,
        order_id,
        order_date,
        total_profit,
        total_revenue,
        lag(order_date) over (partition by customer_id order by order_date) as prev_order_date,
        datediff(day, lag(order_date) over (partition by customer_id order by order_date), order_date) as days_between_orders
    from customer_history
),
customer_base_metrics as (
    select
        category,
        customer_id,
        count(distinct order_id) as total_orders,
        sum(total_profit) CLTV,
        sum(total_revenue) /  count(distinct order_id) AOV,
        avg(days_between_orders) avg_days_between_orders
    from days_between_orders
    group by category, customer_id
),
customer_classification as(
    select
        category,
        customer_id,
        total_orders,
        CLTV,
        AOV,
        avg_days_between_orders,
        case
            when total_orders = 1 then 'One-time'
            when total_orders > 1 then 'Repeat'
        end as customer_type
    from customer_base_metrics
)
select
    category,
    avg(CLTV) avg_CLTV,
    avg(case when customer_type = 'One-time' then CLTV else NULL end) as onetime_CTVL,
    avg(case when customer_type = 'Repeat' then CLTV else NULL end) as repeat_CTVL,
    avg(case when customer_type = 'Repeat' then CLTV else NULL end)
        - avg(case when customer_type = 'One-time' then CLTV else NULL end) as CLTV_gap,
    sum(case when customer_type = 'Repeat' then 1 else 0 end) * 1.0 / count(distinct customer_id) as repeat_rate,
    avg(case when customer_type = 'Repeat' then avg_days_between_orders else null end) avg_days_to_repeat
from customer_classification
group by category;
-- cần xem thêm là số lượng của mỗi line-item là bao nhiêu vì nếu mua có 1 sp mà xài lâu như vậy thì cũng k đúng.

--- retention rate by year
with cohort_base as(
    select
        customer_id,
        min(order_date) as first_order_date,
        min(year(order_date)) as cohort_year
    from #ecom_sales_clean
    group by customer_id
),
order_level as(
    select
        cohort_year,
        cohort.customer_id,
        first_order_date,
        sales.order_date
    from cohort_base as cohort
    inner join #ecom_sales_clean as sales on cohort.customer_id = sales.customer_id
    group by cohort_year, cohort.customer_id, first_order_date, sales.order_date
--  order by cohort_year, customer_id, order_date
),
cohort_period as(
    select
        cohort_year,
        customer_id,
        first_order_date,
        order_date,
        datediff(day, first_order_date, order_date) / 365 as period
    from order_level
--     order by cohort_year, customer_id, order_date
),
retained_customers as(
    select
        cohort_year,
        period,
        count(distinct customer_id) as total_customer
    from cohort_period
    group by cohort_year, period
--     order by cohort_year, period
)
select
    cohort_year,
    period,
    total_customer,
    first_value(total_customer) over (partition by cohort_year order by period) as cohort_size,
    total_customer *1.0 / first_value(total_customer) over (partition by cohort_year order by period)  as pct_retained
from retained_customers
order by cohort_year, period;

--- LTV by discount
with customer_base as(
    select
        customer_id,
        order_id,
        sales,
        profit,
        discount,
        order_date
    from #ecom_sales_clean as sales
),
customer_history as(
    select
        MAX(case when discount > 0 then 1 else 0 end) is_discount,
        customer_id,
        order_id,
        sum(profit) as total_profit,
        sum(sales) as total_revenue,
        MAX(order_date) order_date
    from customer_base
    group by
        customer_id,
        order_id
),
is_discount_customers as(
    select
        customer_id,
        order_id,
        total_profit,
        total_revenue,
        order_date,
        first_value(is_discount) over (partition by customer_id order by order_date) is_discount_cust --- lấy đơn hàng đầu làm mốc
    from customer_history
),
days_between_orders as (
    select
        is_discount_cust,
        customer_id,
        order_id,
        order_date,
        total_profit,
        total_revenue,
        lag(order_date) over (partition by customer_id order by order_date) as prev_order_date,
        datediff(day, lag(order_date) over (partition by customer_id order by order_date), order_date) as days_between_orders
    from is_discount_customers
),
customer_base_metrics as (
    select
        is_discount_cust,
        customer_id,
        count(distinct order_id) as total_orders,
        sum(total_profit) CLTV,
        sum(total_revenue) /  count(distinct order_id) AOV,
        avg(days_between_orders) avg_days_between_orders
    from days_between_orders
    group by is_discount_cust, customer_id
),
customer_classification as(
    select
        is_discount_cust,
        customer_id,
        total_orders,
        CLTV,
        AOV,
        avg_days_between_orders,
        case
            when total_orders = 1 then 'One-time'
            when total_orders > 1 then 'Repeat'
        end as customer_type
    from customer_base_metrics
)
select
    is_discount_cust,
    avg(CLTV) avg_CLTV,
    avg(case when customer_type = 'One-time' then CLTV else NULL end) as onetime_CTVL,
    avg(case when customer_type = 'Repeat' then CLTV else NULL end) as repeat_CTVL,
    avg(case when customer_type = 'Repeat' then CLTV else NULL end)
        - avg(case when customer_type = 'One-time' then CLTV else NULL end) as CLTV_gap,
    sum(case when customer_type = 'Repeat' then 1 else 0 end) * 1.0 / count(distinct customer_id) as repeat_rate,
    avg(case when customer_type = 'Repeat' then avg_days_between_orders else null end) avg_days_to_repeat
from customer_classification
group by is_discount_cust;


--- pct of customer discount
with first_orders as (
    select
        customer_id,
        order_id,
        max(order_date) order_date,
        max(case when discount > 0 then 1 else 0 end) is_discount
    from #ecom_sales_clean
    group by customer_id, order_id
),
customer_classification as(
    select
        customer_id,
        order_id,
        order_date,
        year(min(order_date) over ( partition by customer_id )) cohort_year,
        first_value(is_discount) over (partition by customer_id order by order_date, order_id) is_discount_customer
    from first_orders
)
select
    cohort_year,
    count(distinct customer_id) total_customers,
    count(distinct case when is_discount_customer = 1 then customer_id else null end) discount_cus,
    count(distinct case when is_discount_customer = 1 then customer_id else null end) *1.0
        / count(distinct customer_id) as pct_discount_cus
from customer_classification
group by cohort_year
order by cohort_year


-- =========================================================
-- RFM DISTRIBUTION ANALYSIS
-- Phân tích phân phối dữ liệu Recency / Frequency / Monetary
-- nhằm:
-- 1. Hiểu hành vi tổng quan của khách hàng
-- 2. Xác định mức độ lệch phân phối (skewness)
-- 3. Hỗ trợ xây dựng threshold cho RFM scoring
-- =========================================================

  
WITH rfm_base AS (
    -- Gói gọn việc tính toán R, F, M vào CTE để tái sử dụng, giúp code sạch hơn
    SELECT
        customer_id,
        DATEDIFF(day, MAX(order_date), '2023-12-31') AS recency,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(profit) AS monetary
    FROM #ecom_sales_clean
    GROUP BY customer_id
)
SELECT DISTINCT
    -- Recency distribution
    MIN(recency) OVER() AS min_recency,
    AVG(recency * 1.0) OVER() AS avg_recency,
    MAX(recency) OVER() AS max_recency,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY recency) OVER() AS p25_recency,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY recency) OVER() AS p50_recency,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY recency) OVER() AS p75_recency,

    -- Frequency distribution
    MIN(frequency) OVER() AS min_freq,
    AVG(frequency * 1.0) OVER() AS avg_freq,
    MAX(frequency) OVER() AS max_freq,

    -- Monetary distribution
    MIN(monetary) OVER() AS min_monetary,
    AVG(monetary * 1.0) OVER() AS avg_monetary,
    MAX(monetary) OVER() AS max_monetary,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY monetary) OVER() AS p25_monetary,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY monetary) OVER() AS p75_monetary
FROM rfm_base;


--- RFM_segmentation
WITH customer_metrics AS (
    SELECT
        customer_id,
        DATEDIFF(day, MAX(order_date), '2023-12-31') AS recency,
        COUNT(DISTINCT order_id)                      AS frequency,
        SUM(profit)                                   AS monetary
    FROM #ecom_sales_clean
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT
        customer_id,
        recency,
        frequency,
        monetary,
        -- R Score
        CASE
            WHEN recency <= 148  THEN 5
            WHEN recency <= 421  THEN 4
            WHEN recency <= 803  THEN 3
            WHEN recency <= 1095 THEN 2
            ELSE 1
        END AS r_score,
        -- F Score
        CASE
            WHEN frequency >= 5 THEN 5
            WHEN frequency = 4  THEN 4
            WHEN frequency = 3  THEN 3
            WHEN frequency = 2  THEN 2
            ELSE 1
        END AS f_score,
        -- M Score
        CASE
            WHEN monetary < 0    THEN 0
            WHEN monetary <= 1.40 THEN 1
            WHEN monetary <= 61.16 THEN 2
            WHEN monetary <= 80  THEN 3
            WHEN monetary <= 200 THEN 4
            ELSE 5
        END AS m_score
    FROM customer_metrics
),
-- Tạo thêm bước tính điểm F & M trung bình để khớp với trục dọc của biểu đồ 2D
rfm_combined AS (
    SELECT
        *,
        CAST(ROUND((f_score + m_score) / 2.0, 0) AS INT) AS fm_score
    FROM rfm_scores
),
rfm_segment AS (
    SELECT
        customer_id,
        recency, frequency, monetary,
        r_score, f_score, m_score, fm_score,
        CAST(r_score AS VARCHAR) +
        CAST(f_score AS VARCHAR) +
        CAST(m_score AS VARCHAR)    AS rfm_score,
        CASE
            -- Giữ lại tập lọc khách hàng âm tiền để không bị nhiễu model
            WHEN monetary < 0 THEN 'Loss Customer'

            -- Nhóm Top trên cùng (FM score cao)
            WHEN r_score = 5 AND fm_score >= 4 THEN 'Champions'
            WHEN r_score IN (3, 4) AND fm_score >= 4 THEN 'Loyal Customers'
            WHEN r_score IN (1, 2) AND fm_score >= 4 THEN 'Can''t Lose Them'

            -- Nhóm Giữa (FM score trung bình)
            WHEN r_score IN (1, 2) AND fm_score = 3 THEN 'Hibernating'
            WHEN r_score = 3 AND fm_score = 3 THEN 'Needs Attention'

            -- Potential Loyalist có hình chữ L lộn ngược trong biểu đồ
            WHEN r_score = 4 AND fm_score IN (2, 3) THEN 'Potential Loyalist'
            WHEN r_score = 5 AND fm_score = 3 THEN 'Potential Loyalist'

            -- Nhóm Dưới cùng (FM score thấp)
            WHEN r_score IN (1, 2) AND fm_score <= 2 THEN 'Lost'
            WHEN r_score = 3 AND fm_score <= 2 THEN 'About To Sleep'
            WHEN r_score = 5 AND fm_score = 2 THEN 'Recent Users'
            WHEN r_score = 4 AND fm_score = 1 THEN 'Promising'
            WHEN r_score = 5 AND fm_score = 1 THEN 'Price Sensitive'

            ELSE 'Other'
        END AS rfm_segment
    FROM rfm_combined
)
SELECT
    rfm_segment,
    COUNT(*)                 AS customers,
    ROUND(AVG(monetary), 2)  AS avg_cltv,
    ROUND(AVG(recency), 0)   AS avg_recency_days,
    ROUND(AVG(frequency), 2) AS avg_orders
FROM rfm_segment
GROUP BY rfm_segment
ORDER BY customers DESC;

