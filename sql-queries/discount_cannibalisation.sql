
-- DATA CLEANING
-- NULL check toàn bộ ecom_sales
SELECT
  SUM(CASE WHEN order_id    IS NULL THEN 1 ELSE 0 END) AS null_order_id,
  SUM(CASE WHEN order_date  IS NULL THEN 1 ELSE 0 END) AS null_order_date,
  SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
  SUM(CASE WHEN segment     IS NULL THEN 1 ELSE 0 END) AS null_segment,
  SUM(CASE WHEN region_code IS NULL THEN 1 ELSE 0 END) AS null_region_code,
  SUM(CASE WHEN product_code IS NULL THEN 1 ELSE 0 END) AS null_product_code,
  SUM(CASE WHEN sales       IS NULL THEN 1 ELSE 0 END) AS null_sales,
  SUM(CASE WHEN profit      IS NULL THEN 1 ELSE 0 END) AS null_profit
FROM e_commerce.ecom_sales;

-- NULL check customer demographics
SELECT
  SUM(CASE WHEN birth_date       IS NULL THEN 1 ELSE 0 END) AS null_birth_date,
  SUM(CASE WHEN annual_income    IS NULL THEN 1 ELSE 0 END) AS null_income,
  SUM(CASE WHEN education_level  IS NULL THEN 1 ELSE 0 END) AS null_education,
  COUNT(*) AS total_customers
FROM e_commerce.customer;


-- region_code trong ecom_sales có khớp với region table không?
SELECT *
FROM e_commerce.ecom_sales s
LEFT JOIN e_commerce.region r ON s.region_code = r.region_code
WHERE r.region_code IS NULL; -- region_code: RRR0001

-- product_code trong ecom_sales có khớp với product table không?
SELECT distinct s.product_code
FROM e_commerce.ecom_sales s
LEFT JOIN e_commerce.product p ON s.product_code = p.product_code
WHERE p.product_code IS NULL; -- product_code: PPP000002, PPP000010

-- customer_id trong ecom_sales có khớp với customer table không?
SELECT distinct s.customer_id
FROM e_commerce.ecom_sales s
LEFT JOIN e_commerce.customer c ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- segment values có consistent không? (typo, case mismatch)
SELECT DISTINCT segment, COUNT(*) AS cnt
FROM e_commerce.ecom_sales
GROUP BY segment;

-- market values trong region table
SELECT DISTINCT market, COUNT(*) AS cnt
FROM e_commerce.region
GROUP BY market;

-- Có bao nhiêu orders bị ảnh hưởng bởi region_code lạ?
SELECT
  region_code,
  COUNT(*)                    AS affected_rows,
  ROUND(SUM(sales), 0)        AS affected_sales,
  ROUND(SUM(profit), 0)       AS affected_profit,
  COUNT(DISTINCT customer_id) AS affected_customers
FROM e_commerce.ecom_sales
WHERE region_code = 'RRR0001'
GROUP BY region_code;

-- Có bao nhiêu orders bị ảnh hưởng bởi product_code lạ?
SELECT
  product_code,
  COUNT(distinct order_id)  AS affected_orders,
  ROUND(SUM(sales), 0) AS affected_sales,
  ROUND(SUM(profit), 0) AS affected_profit
FROM e_commerce.ecom_sales
WHERE product_code IN ('PPP000002', 'PPP000010')
GROUP BY product_code;

--- CLEAN DATA
SELECT *
INTO #ecom_sales_clean
FROM e_commerce.ecom_sales
WHERE region_code != 'RRR0001'
  AND product_code NOT IN ('PPP000002', 'PPP000010');


------------- PHÂN TÍCH -----------------

select
    category,
    sum(s.profit) loss_profit
from #ecom_sales_clean as s
inner join e_commerce.product as p on s.product_code = p.product_code
where profit < 0
group by category
order by loss_profit;

select
    segment,
    sum(s.profit) loss_profit
from #ecom_sales_clean as s
where profit < 0
group by segment
order by loss_profit;

select
    market,
    sum(s.profit) loss_profit
from #ecom_sales_clean as s
inner join e_commerce.region as r on s.region_code = r.region_code
where profit < 0
group by market
order by loss_profit;

-- profit theo thời gian
SELECT
    YEAR(order_date)  AS year,
    MONTH(order_date) AS month,
    SUM(CASE WHEN profit < 0 THEN profit ELSE 0 END) AS loss_profit,
    SUM(profit) AS total_profit
FROM #ecom_sales_clean
GROUP BY
    YEAR(order_date),
    MONTH(order_date)
ORDER BY year, month


-- phân tích lãi lỗ theo % discount
select
    CASE
        WHEN discount = 0          THEN '1. No discount (0%)'
        WHEN discount <= 0.20      THEN '2. Low (1-20%)'
        WHEN discount <= 0.40      THEN '3. Medium (21-40%)'
        WHEN discount <= 0.60      THEN '4. High (41-60%)'
        ELSE                            '5. Extreme (61%+)'
      END AS discount_bucket,
    count(order_id) num_line_orders,
    sum(profit) profit,
    sum(sales) revenue,
    sum(profit) / nullif(sum(sales), 0) profit_margin,
    sum(sales) / count(distinct  order_id) AOV
from #ecom_sales_clean
group by
    CASE
        WHEN discount = 0          THEN '1. No discount (0%)'
        WHEN discount <= 0.20      THEN '2. Low (1-20%)'
        WHEN discount <= 0.40      THEN '3. Medium (21-40%)'
        WHEN discount <= 0.60      THEN '4. High (41-60%)'
        ELSE                            '5. Extreme (61%+)'
      END;

-- discount rate theo category
with discount_rate_by_cat as(
select
    CASE
        WHEN discount = 0          THEN '1. No discount (0%)'
        WHEN discount <= 0.20      THEN '2. Low (1-20%)'
        WHEN discount <= 0.40      THEN '3. Medium (21-40%)'
        WHEN discount <= 0.60      THEN '4. High (41-60%)'
        ELSE                            '5. Extreme (61%+)'
      END AS discount_bucket,
    p.category,
    count(order_id) num_line_items,
    sum(profit) profit,
    sum(sales) revenue,
    sum(profit) / nullif(sum(sales), 0) profit_margin,
    sum(sales) / count(distinct  order_id) AOV,
    sum(case when profit < 0 then profit else 0 end) loss_profit,
    cast(sum(case when profit < 0 then 1 else 0 end) * 100/ count(order_id) as decimal(10,2)) pct_unprofitable
from #ecom_sales_clean as s
inner join e_commerce.product as p on s.product_code = p.product_code
group by
    p.category,
    CASE
        WHEN discount = 0          THEN '1. No discount (0%)'
        WHEN discount <= 0.20      THEN '2. Low (1-20%)'
        WHEN discount <= 0.40      THEN '3. Medium (21-40%)'
        WHEN discount <= 0.60      THEN '4. High (41-60%)'
        ELSE                            '5. Extreme (61%+)'
      END

),
ranking as (
select
    *,
    row_number() over (partition by discount_bucket order by loss_profit) ranking
from discount_rate_by_cat
)
select * from ranking order by discount_bucket, category;


-- discount rate theo sub-category
with discount_rate_by_sub_cat as(
select
    CASE
        WHEN discount = 0          THEN '1. No discount (0%)'
        WHEN discount <= 0.20      THEN '2. Low (1-20%)'
        WHEN discount <= 0.40      THEN '3. Medium (21-40%)'
        WHEN discount <= 0.60      THEN '4. High (41-60%)'
        ELSE                            '5. Extreme (61%+)'
      END AS discount_bucket,
    p.category,
    p.subcategory,
    count(order_id) num_line_items,
    sum(profit) profit,
    sum(case when profit < 0 then profit else 0 end) loss_profit,
    cast(sum(case when profit < 0 then 1 else 0 end) * 100/ count(order_id) as decimal(10,2)) pct_unprofitable_orders,
    sum(sales) revenue,
    sum(profit) / nullif(sum(sales), 0) profit_margin,
    sum(sales) / count(distinct  order_id) AOV
from #ecom_sales_clean as s
inner join e_commerce.product as p on s.product_code = p.product_code
group by
    p.category,
    p.subcategory,
    CASE
        WHEN discount = 0          THEN '1. No discount (0%)'
        WHEN discount <= 0.20      THEN '2. Low (1-20%)'
        WHEN discount <= 0.40      THEN '3. Medium (21-40%)'
        WHEN discount <= 0.60      THEN '4. High (41-60%)'
        ELSE                            '5. Extreme (61%+)'
      END

),
ranking as (
select
    *,
    row_number() over (order by loss_profit) ranking
from discount_rate_by_sub_cat
)
select top 10*
from ranking
where discount_bucket not in ('1. No discount (0%)', '2. Low (1-20%)')
order by ranking;


-- discount_rate x category X market X time
with discount_rate_by_cat as (
    select
        -- Thêm các trường thời gian
        YEAR(s.order_date) as [year],
        datepart(quarter , order_date) as [quarter], -- Hoặc DATEPART(QUARTER, s.order_date) tùy DB
        MONTH(s.order_date) as [month],

        CASE
            WHEN discount = 0          THEN '1. No discount (0%)'
            WHEN discount <= 0.20      THEN '2. Low (1-20%)'
            WHEN discount <= 0.40      THEN '3. Medium (21-40%)'
            WHEN discount <= 0.60      THEN '4. High (41-60%)'
            ELSE                            '5. Extreme (61%+)'
        END AS discount_bucket,
        p.category,
        r.market,
        count(order_id) num_line_items,
        sum(profit) profit,
        sum(sales) revenue,
        sum(profit) / nullif(sum(sales), 0) profit_margin,
        sum(sales) / count(distinct order_id) AOV,
        sum(case when profit < 0 then profit else 0 end) loss_profit,
        cast(sum(case when profit < 0 then 1 else 0 end) * 100 / count(order_id) as decimal(10,2)) pct_unprofitable
    from #ecom_sales_clean as s
    inner join e_commerce.product as p on s.product_code = p.product_code
    inner join e_commerce.region as r on s.region_code = r.region_code
    group by
        YEAR(s.order_date),
        datepart(quarter , order_date),
        MONTH(s.order_date),
        p.category,
        r.market,
        CASE
            WHEN discount = 0          THEN '1. No discount (0%)'
            WHEN discount <= 0.20      THEN '2. Low (1-20%)'
            WHEN discount <= 0.40      THEN '3. Medium (21-40%)'
            WHEN discount <= 0.60      THEN '4. High (41-60%)'
            ELSE                            '5. Extreme (61%+)'
        END
),
ranking as (
    select
        *,
        row_number() over (partition by [year], [month], discount_bucket order by loss_profit) as ranking
    from discount_rate_by_cat
)
select * from ranking order by [year], [month], discount_bucket, category, market;


-- discount rate theo market
select
    CASE
        WHEN discount = 0          THEN '1. No discount (0%)'
        WHEN discount <= 0.20      THEN '2. Low (1-20%)'
        WHEN discount <= 0.40      THEN '3. Medium (21-40%)'
        WHEN discount <= 0.60      THEN '4. High (41-60%)'
        ELSE                            '5. Extreme (61%+)'
      END AS discount_bucket,
    r.market,
    count(order_id) num_line_orders,
    sum(profit) profit,
    sum(sales) revenue,
    sum(profit) / nullif(sum(sales), 0) profit_margin,
    sum(sales) / count(distinct  order_id) AOV
from #ecom_sales_clean as s
inner join e_commerce.region as r on s.region_code = r.region_code
group by
    r.market,
    CASE
        WHEN discount = 0          THEN '1. No discount (0%)'
        WHEN discount <= 0.20      THEN '2. Low (1-20%)'
        WHEN discount <= 0.40      THEN '3. Medium (21-40%)'
        WHEN discount <= 0.60      THEN '4. High (41-60%)'
        ELSE                            '5. Extreme (61%+)'
      END
order by
    CASE
        WHEN discount = 0          THEN '1. No discount (0%)'
        WHEN discount <= 0.20      THEN '2. Low (1-20%)'
        WHEN discount <= 0.40      THEN '3. Medium (21-40%)'
        WHEN discount <= 0.60      THEN '4. High (41-60%)'
        ELSE                            '5. Extreme (61%+)'
      END,
    profit;


-- discount rate theo time

select
    year(order_date) year,
    datepart(quarter , order_date) quarter,
    CASE
        WHEN discount = 0          THEN '1. No discount (0%)'
        WHEN discount <= 0.20      THEN '2. Low (1-20%)'
        WHEN discount <= 0.40      THEN '3. Medium (21-40%)'
        WHEN discount <= 0.60      THEN '4. High (41-60%)'
        ELSE                            '5. Extreme (61%+)'
      END AS discount_bucket,
    count(order_id) num_line_orders,
    sum(profit) profit,
    sum(case when profit < 0 then profit else 0 end) loss_profit,
    sum(sales) revenue,
    sum(profit) / nullif(sum(sales), 0) profit_margin,
    sum(sales) / count(distinct  order_id) AOV
from #ecom_sales_clean
group by
    CASE
        WHEN discount = 0          THEN '1. No discount (0%)'
        WHEN discount <= 0.20      THEN '2. Low (1-20%)'
        WHEN discount <= 0.40      THEN '3. Medium (21-40%)'
        WHEN discount <= 0.60      THEN '4. High (41-60%)'
        ELSE                            '5. Extreme (61%+)'
      END,
    year(order_date),
    datepart(quarter , order_date)
order by
    CASE
        WHEN discount = 0          THEN '1. No discount (0%)'
        WHEN discount <= 0.20      THEN '2. Low (1-20%)'
        WHEN discount <= 0.40      THEN '3. Medium (21-40%)'
        WHEN discount <= 0.60      THEN '4. High (41-60%)'
        ELSE                            '5. Extreme (61%+)'
      END,
    year(order_date),
    datepart(quarter , order_date);

