SELECT *
INTO #ecom_sales_clean
FROM e_commerce.ecom_sales
WHERE region_code != 'RRR0001'
  AND product_code NOT IN ('PPP000002', 'PPP000010');

--- profit and loss by segment
select
    segment,
    sum(profit) total_profit,
    sum(sales) total_revenue,
    cast(sum(profit) * 100.0 / nullif(sum(sales), 0) as decimal(10,2) ) profit_margin,
    avg(discount) avg_discount,
    sum(sales) / count(distinct customer_id) revenue_per_customer,
    sum(profit) / count(distinct customer_id) profit_per_customer,
    sum(sales) / count(distinct order_id) AOV,
    cast(COUNT(DISTINCT order_id) *1.00 / COUNT(DISTINCT customer_id) as decimal(10,2)) order_frequency
from #ecom_sales_clean
group by segment;

select
    segment,
    sum(profit) total_profit,
    sum(sales) total_revenue,
    cast(sum(profit) * 100.0 / nullif(sum(sales), 0) as decimal(10,2) ) profit_margin
from #ecom_sales_clean
group by segment;

--- profit and loss by segment x category
with profitnloss as(
select
    segment,
    category,
    sum(profit) total_profit,
    sum(sales) total_revenue,
    cast(sum(profit) * 100.0 / nullif(sum(sales), 0) as decimal(10,2) ) profit_margin,
    avg(discount) avg_discount,
    sum(sales) / count(distinct customer_id) revenue_per_customer,
    sum(profit) / count(distinct customer_id) profit_per_customer,
    sum(sales) / count(distinct order_id) AOV,
    cast(COUNT(DISTINCT order_id) *1.00 / COUNT(DISTINCT customer_id) as decimal(10,2)) order_frequency
from #ecom_sales_clean
inner join e_commerce.product p on #ecom_sales_clean.product_code = p.product_code
group by segment, category
)
select
    *,
    cast(total_revenue *100.0 / sum(total_revenue) over(partition by segment) as decimal(10,2)) as pct_revenue_contribution
from profitnloss
order by segment, category;

--- profit and loss by segment x discount bucket
with profitnloss as(
select
    segment,
    CASE
        WHEN discount = 0          THEN '1. No discount (0%)'
        WHEN discount <= 0.20      THEN '2. Low (1-20%)'
        WHEN discount <= 0.40      THEN '3. Medium (21-40%)'
        WHEN discount <= 0.60      THEN '4. High (41-60%)'
        ELSE                            '5. Extreme (61%+)'
      END AS discount_bucket,
    sum(profit) total_profit,
    sum(sales) total_revenue,
    count(distinct order_id) order_count,
    cast(sum(profit) * 100.0 / nullif(sum(sales), 0) as decimal(10,2) ) profit_margin,
    avg(discount) avg_discount,
    sum(sales) / count(distinct customer_id) revenue_per_customer,
    sum(profit) / count(distinct customer_id) profit_per_customer,
    sum(sales) / count(distinct order_id) AOV,
    cast(COUNT(DISTINCT order_id) *1.00 / COUNT(DISTINCT customer_id) as decimal(10,2)) order_frequency
from #ecom_sales_clean
inner join e_commerce.product p on #ecom_sales_clean.product_code = p.product_code
group by
    segment,
    CASE
        WHEN discount = 0          THEN '1. No discount (0%)'
        WHEN discount <= 0.20      THEN '2. Low (1-20%)'
        WHEN discount <= 0.40      THEN '3. Medium (21-40%)'
        WHEN discount <= 0.60      THEN '4. High (41-60%)'
        ELSE                            '5. Extreme (61%+)'
      END
)
select
    *,
    cast(total_revenue *100 / sum(total_revenue) over(partition by segment) as decimal(10,2)) as pct_revenue_contribution
from profitnloss
order by segment, discount_bucket;


--- profit and loss by segment x time
select
    segment,
    year(order_date) year,
    month(order_date) month,
    datepart(quarter, order_date) quarter,
    sum(profit) total_profit,
    sum(sales) total_revenue,
    cast(sum(profit) * 100.0 / nullif(sum(sales), 0) as decimal(10,2) ) profit_margin
from #ecom_sales_clean
group by segment, year(order_date), datepart(quarter, order_date), month(order_date)
order by segment,year,quarter, month(order_date)

--- profit and loss by segment x market
select
    segment,
    market,
    sum(profit) total_profit,
    sum(sales) total_revenue,
    cast(sum(profit) * 100.0 / nullif(sum(sales), 0) as decimal(10,2) ) profit_margin
from #ecom_sales_clean
inner join e_commerce.region as r on #ecom_sales_clean.region_code = r.region_code
group by market, segment
order by market, segment

