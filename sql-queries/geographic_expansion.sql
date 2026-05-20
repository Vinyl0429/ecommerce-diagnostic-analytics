--- tạo dim_date
DECLARE @StartDate DATE = '2020-01-01';
DECLARE @EndDate   DATE = '2023-12-31';

SET DATEFIRST 1;

WITH DateRange AS (
    SELECT @StartDate AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateRange
    WHERE DateValue < @EndDate
),
Virtual_Date_Dim AS (
    SELECT
        DateValue AS date_actual,
        YEAR(DateValue) AS [year],
        MONTH(DateValue) AS [month],
        DATENAME(MONTH, DateValue) AS month_name,
        DATEPART(DAY, DateValue) AS day_of_month,
        DATENAME(WEEKDAY, DateValue) AS day_name,
        CASE WHEN DATEPART(WEEKDAY, DateValue) IN (6, 7) THEN 1 ELSE 0 END AS is_weekend
    FROM DateRange
)
SELECT * INTO #dim_date
FROM Virtual_Date_Dim
OPTION (MAXRECURSION 0);

SELECT *
INTO #ecom_sales_clean
FROM e_commerce.ecom_sales
WHERE region_code != 'RRR0001'
  AND product_code NOT IN ('PPP000002', 'PPP000010');

-- growth_n_profitability_per_market
WITH AllMonths AS (
    -- Lấy danh sách Năm-Tháng từ bảng #dim_date
    SELECT
        DISTINCT [year],
                 [month],
                 datepart(quarter , date_actual) as quarter
    FROM #dim_date
),
AllMarkets AS (
    SELECT DISTINCT market FROM e_commerce.region
),
Time_Market_Backbone AS (
    -- Phân rã mọi tháng cho mọi thị trường
    SELECT
        m.market,
        d.[year],
        d.quarter,
        d.[month]
    FROM AllMarkets m CROSS JOIN AllMonths d
),

-- TÌM NGÀY MUA ĐẦU TIÊN
First_Orders AS (
    SELECT
        customer_id,
        MIN(order_date) AS first_order_date
    FROM #ecom_sales_clean
    GROUP BY customer_id
),
Classified_Sales AS (
    SELECT
        r.market,
        YEAR(s.order_date) AS [year],
        DATEPART(quarter , s.order_date) as quarter,
        MONTH(s.order_date) AS [month],
        s.customer_id,
        s.order_id,
        s.sales,
        s.profit,
        CASE
            WHEN s.order_date = f.first_order_date THEN 'New'
            ELSE 'Repeat'
        END AS cust_type
    FROM #ecom_sales_clean s
    INNER JOIN e_commerce.region r ON s.region_code = r.region_code
    INNER JOIN First_Orders f ON s.customer_id = f.customer_id
),
Aggregated_Metrics AS (
    SELECT
        market,
        [year],
        [month],
        quarter,
        SUM(sales) AS total_revenue,
        SUM(profit) AS total_profit,
        SUM(sales) / COUNT(DISTINCT customer_id) revenue_per_cus,
        SUM(profit) / COUNT(DISTINCT customer_id) profit_per_cus,
        SUM(sales) / COUNT(distinct order_id) AOV,
        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(DISTINCT customer_id) AS total_customers,
        COUNT(DISTINCT CASE WHEN cust_type = 'New' THEN customer_id END) AS new_customers,
        COUNT(DISTINCT CASE WHEN cust_type = 'Repeat' THEN customer_id END) AS repeat_customers
    FROM Classified_Sales
    GROUP BY market, [year], quarter, [month]
),
Continuous_Data AS (
    SELECT
        b.market,
        b.[year],
        b.quarter,
        b.[month],
        ISNULL(a.AOV, 0) AOV,
        ISNULL(a.total_revenue, 0) AS total_revenue,
        ISNULL(a.total_profit, 0) AS total_profit,
        ISNULL(a.total_orders, 0) AS total_orders,
        ISNULL(a.total_customers, 0) AS total_customers,
        ISNULL(a.new_customers, 0) AS new_customers,
        ISNULL(a.repeat_customers, 0) AS repeat_customers
    FROM Time_Market_Backbone b
    LEFT JOIN Aggregated_Metrics a
        ON b.market = a.market AND b.[year] = a.[year] AND b.quarter = a.quarter AND b.[month] = a.[month]
)

SELECT
    market,
    [year],
    [quarter],
    [month],
    AOV,
    total_revenue,
    total_profit,
    CAST(total_profit * 1.0 / NULLIF(total_revenue, 0) AS DECIMAL(10,4)) AS profit_margin,
    total_customers,
    new_customers,
    repeat_customers,
    CAST((total_orders - LAG(total_orders, 12) OVER (PARTITION BY market ORDER BY year, month)) * 1.0
             / NULLIF(LAG(total_orders, 12) OVER (PARTITION BY market ORDER BY year, month), 0)  AS DECIMAL(10,2)) AS order_growth_rate,
    CAST((new_customers - LAG(new_customers, 12)  OVER (PARTITION BY market ORDER BY year, month)) * 1.0
             / NULLIF(LAG(new_customers, 12) OVER (PARTITION BY market ORDER BY year, month), 0) AS DECIMAL(10,2)) AS customer_growth_rate,
    CAST(repeat_customers * 1.0 / NULLIF(total_customers, 0) AS DECIMAL(10,4)) AS repeat_ratio,
    LAG(total_revenue, 12) OVER(PARTITION BY market ORDER BY [year], [month]) AS prev_year_revenue,
    CAST((total_revenue - LAG(total_revenue, 12) OVER(PARTITION BY market ORDER BY [year], [month])) * 1.0
        / NULLIF(LAG(total_revenue, 12) OVER(PARTITION BY market ORDER BY [year], [month]), 0) AS DECIMAL(10,4)) AS revenue_yoy_growth
FROM Continuous_Data




SELECT
    customer_id,
    COUNT(DISTINCT r.market) AS market_count
FROM #ecom_sales_clean s
JOIN e_commerce.region r ON s.region_code = r.region_code
GROUP BY customer_id
HAVING COUNT(DISTINCT r.market) > 1;


SELECT
    r.market,
    p.category,
    SUM(s.sales)     AS revenue,
    SUM(s.profit)    AS profit,
    SUM(s.profit) / SUM(s.sales) AS profit_margin,
    AVG(s.discount)  AS avg_discount,
    -- % revenue contribution per market
    SUM(s.sales) * 100.0 /
        SUM(SUM(s.sales)) OVER(PARTITION BY r.market)
                         AS pct_revenue
FROM #ecom_sales_clean s
JOIN e_commerce.region r  ON s.region_code = r.region_code
JOIN e_commerce.product p ON s.product_code = p.product_code
GROUP BY r.market, p.category
ORDER BY r.market, pct_revenue DESC;

WITH customer_orders AS (
    SELECT
        segment,
        customer_id,
        COUNT(DISTINCT order_id)  AS order_count,
        SUM(profit)               AS lifetime_profit,
        MIN(order_date)           AS first_order,
        MAX(order_date)           AS last_order
    FROM #ecom_sales_clean
    GROUP BY segment, customer_id
)
SELECT
    segment,
    SUM(CASE WHEN order_count = 1 THEN 1 ELSE 0 END) AS one_time,
    SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) AS repeat,
    CAST(SUM(CASE WHEN order_count > 1 THEN 1.0 ELSE 0 END)
         / COUNT(*) * 100 AS DECIMAL(10,2))           AS repeat_rate_pct,
    ROUND(AVG(CASE WHEN order_count = 1
              THEN lifetime_profit END), 2)           AS avg_ltv_onetime,
    ROUND(AVG(CASE WHEN order_count > 1
              THEN lifetime_profit END), 2)           AS avg_ltv_repeat,
    ROUND(AVG(CASE WHEN order_count > 1
              THEN lifetime_profit END) /
          NULLIF(AVG(CASE WHEN order_count = 1
              THEN lifetime_profit END), 0), 2)       AS ltv_multiplier
FROM customer_orders
group by segment;


-- classify first purchase category per customer
WITH first_purchase AS (
    SELECT customer_id, category AS first_category
    FROM (
        SELECT
            s.customer_id,
            p.category,
            ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date ASC, s.order_id ASC) as rn
        FROM #ecom_sales_clean s
        JOIN e_commerce.product p ON s.product_code = p.product_code
    ) t
    WHERE rn = 1 -- Chỉ lấy bản ghi đầu tiên
),
customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS order_count,
        SUM(profit)              AS lifetime_profit
    FROM #ecom_sales_clean
    GROUP BY customer_id
)
SELECT
    fp.first_category,
    COUNT(*)                                          AS total_customers,
    SUM(CASE WHEN co.order_count = 1
        THEN 1 ELSE 0 END)                           AS one_time,
    SUM(CASE WHEN co.order_count > 1
        THEN 1 ELSE 0 END)                           AS repeat,
    CAST(SUM(CASE WHEN co.order_count > 1
        THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100 AS DECIMAL(10,2))           AS repeat_rate_pct,
    ROUND(AVG(CASE WHEN co.order_count = 1
        THEN co.lifetime_profit END), 2)             AS avg_ltv_onetime,
    ROUND(AVG(CASE WHEN co.order_count > 1
        THEN co.lifetime_profit END), 2)             AS avg_ltv_repeat
FROM first_purchase fp
JOIN customer_orders co
    ON fp.customer_id = co.customer_id
GROUP BY fp.first_category
ORDER BY repeat_rate_pct DESC;
