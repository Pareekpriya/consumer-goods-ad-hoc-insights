-- Request 1
-- Show the markets of "Atliq Exclusive" in the "APAC" region

SELECT customer,region,market FROM gdb023.dim_customer
where region = "apac"
and customer = "atliq exclusive";

-- Request 2
-- Show the distanct product counts in 2021 as campare to 2020

with unique_count as (
select 
 count(distinct case when fiscal_year = 2020 then product_code end) as unique_product_2020,
 count(distinct case when fiscal_year = 2021 then product_code end) as unique_product_2021
 from
 fact_sales_monthly
 where fiscal_year in (2020,2021)
 )
 select unique_product_2020,unique_product_2021,
 round(((unique_product_2021 - unique_product_2020)/unique_product_2020)*100 , 2) as pct_chng

from unique_count;


-- Request 3
-- show the unique product count in each segment

with cte1 as (
SELECT segment,count(distinct(product_code)) as distinct_product_count FROM gdb023.dim_product
group by segment
)

select * from cte1 
order by distinct_product_count desc;

-- Request 4
-- show the distinct product increase in each segment in 2021 as campare to 2020 

with cte1 as (
SELECT product_code, segment, fiscal_year FROM gdb023.fact_sales_monthly s
join dim_product p 
using (product_code)
),

cte2 as (select segment, 
 count(distinct case when fiscal_year = 2020 then product_code end) as unique_product_2020,
 count(distinct case when fiscal_year = 2021 then product_code end) as unique_product_2021
from cte1
where fiscal_year in (2020,2021) 
group by segment
)

select *, (unique_product_2021 - unique_product_2020) as difference
from cte2 
order by difference desc;


-- Request 5
-- Print the products those have maximumum and minimum manufaturing_cost

SELECT 
p.product, p.product_code, round(m.manufacturing_cost,2) as manufaturing_cost
FROM gdb023.fact_manufacturing_cost m
join dim_product p
using (product_code)
where m.manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost)
or m.manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost)
order by manufacturing_cost desc;


-- Request 6
-- show the top 5 customers who received high avg pre invoice discount percentage in the India market in fiscal year 2021

SELECT customer_code, customer, round(avg(pre_invoice_discount_pct),2) as avg_dis_pct FROM gdb023.fact_pre_invoice_deductions pre
join dim_customer c
using (customer_code)
where fiscal_year = 2021
and market = "india"
group by customer_code, customer
order by avg_dis_pct desc
limit 5;


-- Request 7
-- generate monthly gross sale amount report for "Atliq Exclusive"

select s.date as month, s.fiscal_year as year,
round(sum(s.sold_quantity*g.gross_price),2) as gross_sale_amount
from fact_sales_monthly s
join fact_gross_price g
on s.product_code = g.product_code
join dim_customer c
on c.customer_code = s.customer_code
where c.customer = "atliq exclusive"
group by s.date, s.fiscal_year
order by s.date; 

-- Request 8
-- in which quarter of fiscal year 2020 get the maximum sold quantity

SELECT
case
when month(date) in (09,10,11) then "Q1"
when month(date) in (12,01,02) then "Q2"
when month(date) in (03,04,05) then "Q3"
when month(date) in (06,07,08) then "Q4"
end 
as quarter,
sum(sold_quantity) as total_sold_quantity FROM gdb023.fact_sales_monthly
where fiscal_year = 2020
group by quarter
order by total_sold_quantity;


-- Request 9
-- show which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution

with cte1 as (
SELECT c.channel, round(sum((s.sold_quantity*g.gross_price)/1000000),2) as gross_sale_mln FROM gdb023.fact_sales_monthly s
join fact_gross_price g
using (product_code) 
join dim_customer c 
using (customer_code) 
where s.fiscal_year = 2021
group by channel 
order by gross_sale_mln desc
)
select *,
round((gross_sale_mln/sum(gross_sale_mln) over())*100,2) as percentage
from cte1;


-- Request 10
-- Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021

with cte1 as (
SELECT 
p.division,
s.product_code,
p.product,
sum(s.sold_quantity) as total_sold_quantity,
dense_rank() over(
partition by p.division
order by sum(s.sold_quantity) desc
) as rank_order
FROM gdb023.dim_product p
join fact_sales_monthly s
using (product_code)
where s.fiscal_year = 2021
group by p.division, s.product_code, p.product
)
select * from cte1 
where rank_order <=3