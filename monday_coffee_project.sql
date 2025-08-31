select *
from customers;
select *
from city;
select *
from products;
select *
from sales;

-- 1. **Coffee Consumers Count**  
--   How many people in each city are estimated to consume coffee, given that 25% of the population does?

select city_name,
population,
cast(population * 0.25 as int) as coffee_consumers_in_city,
city_rank
from city
order by 3 desc;

-- 2. **Total Revenue from Coffee Sales**  
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
 
select ci.city_name,
sum(total) as total_revenue
from sales s
left join customers c
	on s.customer_id = c.customer_id
join city ci
	on ci.city_id = c.city_id
where datepart(quarter,sale_date) = 4
and year(sale_date) = 2023
group by city_name
order by total_revenue desc

-- 3. **Sales Count for Each Product**  
 -- How many units of each coffee product have been sold?

select product_name,
count(distinct sale_id) as number_sales
from products p
left join sales s
	on p.product_id = s.product_id
group by product_name
order by number_sales desc


-- 4. **Average Sales Amount per City**  
-- What is the average sales amount per customer in each city?

select ci.city_name, 
sum(total) as total_revenue,
count(distinct c.customer_id) as unique_customers ,
sum(total)/count(distinct c.customer_id) as avg_revenue_customer
from sales s
join customers c
	on s.customer_id = c.customer_id
join city ci
	on ci.city_id = c.city_id
group by city_name
order by total_revenue desc

-- 5. **City Population and Coffee Consumers**  
-- Provide a list of cities along with their populations and estimated coffee consumers.

select ci.city_name,
population,
population * 0.25 as coffee_consumers_city,
count(distinct c.customer_id) as unique_customers
from city ci
join customers c
	on ci.city_id = c.city_id
group by ci.city_name,
population
order by coffee_consumers_city desc;

-- 6. **Top Selling Products by City**  
-- What are the top 3 selling products in each city based on sales volume?

with sales_table as
(select ci.city_name, 
product_name,
count(distinct sale_id) as number_sales,
dense_rank() over(partition by city_name order by count(distinct sale_id) desc) as products_rank
from products p
left join sales s
	on p.product_id = s.product_id
join customers c
	on c.customer_id = s.customer_id
join city ci
	on ci.city_id = c.city_id
group by ci.city_name,
product_name
)
select *
from sales_table
where products_rank <=3;

-- Based on revenue generated
select *
from
(select ci.city_name,
p.product_name,
sum(total) as total_sales_volume,
dense_rank() over(partition by ci.city_name order by sum(total) desc) as rank_products
from products p
left join sales s 
	on p.product_id = s.product_id
join customers c
	on c.customer_id = s.customer_id
join city ci
	on ci.city_id = c.city_id
group by ci.city_name,
p.product_name) as sales_table
where rank_products <=3

-- 7. **Customer Segmentation by City**  
-- How many unique customers are there in each city who have purchased coffee products?

select ci.city_name,
count(distinct c.customer_id) as unique_customers
from products p
left join sales s
	on p.product_id = s.product_id
join customers c
	on c.customer_id = s.customer_id
join city ci
	on ci.city_id = c.city_id
group by ci.city_name
order by unique_customers desc

-- 8. **Average Sale vs Rent**  
-- Find each city and their average sale per customer and avg rent per customer

select ci.city_name, 
sum(total) as total_revenue,
estimated_rent,
count(distinct c.customer_id) as unique_customers ,
sum(total)/count(distinct c.customer_id) as avg_revenue_customer,
estimated_rent/count(distinct c.customer_id) as avg_rent_customer
from sales s
join customers c
	on s.customer_id = c.customer_id
join city ci
	on ci.city_id = c.city_id
group by city_name,
estimated_rent
order by avg_revenue_customer desc

-- 9. **Monthly Sales Growth**  
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) per city

with t1 as 
(select ci.city_name,
format(sale_date,'yyyy-MM') as monthly,
sum(total) as current_month_sales
from sales s
left join customers c
	on s.customer_id = c.customer_id
join city ci
	on ci.city_id = c.city_id
group by ci.city_name, 
format(sale_date,'yyyy-MM')
),
t2 as
(select *,
lag(current_month_sales , 1) over(partition by city_name order by monthly) as last_month_sales
from t1
)
select *,
((current_month_sales - last_month_sales) * 100)/last_month_sales as sales_trend_pct
from t2

-- 10. **Market Potential Analysis**  
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated  coffee consumer


select ci.city_name,
population * 0.25 as coffee_consumers_city,
sum(total) as total_revenue,
estimated_rent,
count(distinct c.customer_id) as unique_customers ,
sum(total)/count(distinct c.customer_id) as avg_revenue_customer,
estimated_rent/count(distinct c.customer_id) as avg_rent_customer
from sales s
join customers c
	on s.customer_id = c.customer_id
join city ci
	on ci.city_id = c.city_id
group by city_name,
population,
estimated_rent
order by avg_revenue_customer desc