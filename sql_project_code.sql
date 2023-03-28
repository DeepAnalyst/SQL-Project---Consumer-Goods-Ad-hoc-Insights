-- The list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT 
    market
FROM
    dim_customer
WHERE
    customer = 'Atliq Exclusive'
        AND region = 'APAC';
        
-- The percentage of unique product increase in 2021 vs. 2020.

with cte1 as (
  select count(distinct product_code) as unique_products_2020 
  from fact_sales_monthly 
  where fiscal_year = 2020
),
cte2 as (
  select count(distinct product_code) as unique_products_2021 
  from fact_sales_monthly 
  where fiscal_year = 2021
)
select 
  cte1.unique_products_2020, 
  cte2.unique_products_2021,
  ROUND(((cte2.unique_products_2021 - cte1.unique_products_2020) / cte1.unique_products_2020) * 100, 2) as percentage_chg
from cte1, cte2;

-- Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.

SELECT 
    segment, COUNT(DISTINCT product_code) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- The segment had the most increase in unique products in 2021 vs 2020.

SELECT
  d.segment AS segment,
  COUNT(DISTINCT CASE WHEN f.fiscal_year = 2020 THEN f.product_code END) AS product_count_2020,
  COUNT(DISTINCT CASE WHEN f.fiscal_year = 2021 THEN f.product_code END) AS product_count_2021,
  COUNT(DISTINCT CASE WHEN f.fiscal_year = 2021 THEN f.product_code END) -
  COUNT(DISTINCT CASE WHEN f.fiscal_year = 2020 THEN f.product_code END) AS difference
FROM
  dim_product d
  JOIN fact_sales_monthly f ON d.product_code = f.product_code
WHERE
  f.fiscal_year IN (2020, 2021)
GROUP BY
  d.segment
ORDER BY
  difference DESC;
  
-- Get the products that have the highest and lowest manufacturing costs.
  
SELECT 
  d.product_code,
  d.product,
  f.manufacturing_cost
FROM 
  dim_product d
  JOIN fact_manufacturing_cost f ON d.product_code = f.product_code
  JOIN (
    SELECT 
      MAX(manufacturing_cost) AS max_cost, 
      MIN(manufacturing_cost) AS min_cost 
    FROM 
      fact_manufacturing_cost
  ) m ON f.manufacturing_cost = m.max_cost OR f.manufacturing_cost = m.min_cost
ORDER BY 
  f.manufacturing_cost DESC;

--  A report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.

SELECT 
    d.customer_code,
    d.customer,
    ROUND(AVG(f.pre_invoice_discount_pct), 4) AS average_discount_percentage
FROM
    dim_customer d
        JOIN
    fact_pre_invoice_deductions f ON d.customer_code = f.customer_code
WHERE
    market = 'India' AND fiscal_year = 2021
GROUP BY customer_code , customer
ORDER BY average_discount_percentage DESC
LIMIT 5;

/* The complete report of the Gross sales amount for the customer “Atliq 
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions */

SELECT 
  MONTH(fsm.date) AS months,
  YEAR(fsm.date) AS year,
  ROUND(SUM(fsm.sold_quantity * fgp.gross_price),2) AS gross_sales_amount
FROM 
  fact_sales_monthly fsm
  JOIN dim_customer dc ON fsm.customer_code = dc.customer_code
  JOIN fact_gross_price fgp ON fsm.product_code = fgp.product_code
WHERE 
  dc.customer = 'Atliq Exclusive'
GROUP BY 
  yEAR, 
  months
ORDER BY 
  year, 
  months;
  
-- In which quarter of 2020, got the maximum total_sold_quantity

  WITH monthly_sales AS (
  SELECT 
    product_code, 
    customer_code, 
    sold_quantity,
    CASE 
      WHEN EXTRACT(MONTH FROM date) IN (9,10,11) THEN 'Q1' 
      WHEN EXTRACT(MONTH FROM date) IN (12,1,2) THEN 'Q2' 
      WHEN EXTRACT(MONTH FROM date) IN (3,4,5) THEN 'Q3' 
      ELSE 'Q4'
    END AS Quarter
  FROM fact_sales_monthly
  WHERE fiscal_year = 2020
)
SELECT 
  Quarter,
  FORMAT(SUM(sold_quantity)/1000000, 2) AS total_sold_quantity_in_million
FROM monthly_sales
GROUP BY Quarter
ORDER BY total_sold_quantity_in_million DESC;


-- The channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution

WITH sales_revenue AS (
  SELECT
    dc.channel,
    SUM(fgp.gross_price * fsm.sold_quantity) AS gross_sales_mln
  FROM
    fact_sales_monthly fsm
    JOIN fact_gross_price fgp ON fsm.product_code = fgp.product_code AND fsm.fiscal_year = fgp.fiscal_year
    JOIN dim_customer dc ON fsm.customer_code = dc.customer_code
  WHERE
    fsm.fiscal_year = 2021
  GROUP BY
    dc.channel
)
SELECT
  sr.channel,
  ROUND(sr.gross_sales_mln, 2) AS gross_sales_mln,
  ROUND(sr.gross_sales_mln / SUM(sr.gross_sales_mln) OVER (), 2) * 100 AS percentage
FROM
  sales_revenue sr
ORDER BY
  sr.gross_sales_mln DESC;
  
  
  
  --  The Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021.
  
  WITH sales AS (
  SELECT p.division, s.product_code, p.product, SUM(s.sold_quantity) AS total_sold_quantity,
    RANK() OVER (PARTITION BY p.division ORDER BY SUM(s.sold_quantity) DESC) AS rank_order
  FROM fact_sales_monthly s
  JOIN dim_product p ON s.product_code = p.product_code
  WHERE s.fiscal_year = 2021
  GROUP BY p.division, s.product_code, p.product
)
SELECT division, product_code, product, total_sold_quantity, rank_order
FROM sales
WHERE rank_order <= 3;




  


