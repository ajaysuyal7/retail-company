	
-----------------customer 360----------

with cte as (
select Customer_id,Gender,customer_city,customer_state,
	count(distinct order_id) no_of_transaction, 
	sum(quantity) total_qty,
	count(distinct product_id) as unique_item_purchase,
	min(Bill_date_timestamp) first_purchase,
	max(Bill_date_timestamp) last_purchase,
	ROUND(sum(MRP*Quantity),2) MRP,
	round(sum(Total_Amount),2) as revenue,
	round(sum(Cost_Per_Unit*Quantity),2) total_cost,
	sum(Discount) total_discount,
	round(sum(Total_Amount)-sum(Cost_Per_Unit*Quantity),2) profit_per_cust,--PROFIT
	avg(Avg_rating) rating,--RATING
	count(distinct channel) no_of_channel_for_purchase, --no of channel for purchase
	count(Distinct Delivered_StoreID) no_of_store,  -- no of store 
	count(distinct seller_city) no_of_city_purchased,  --no of city
	DATEDIFF(DAY,MIN(Bill_date_timestamp),max(bill_date_timestamp)) AS Tenure, ---Tenure	Last Transaction date - first transaction date
	DATEDIFF(DAY,MIN(Bill_date_timestamp),(select max(bill_date_timestamp) from Finalised_Records)) AS Inactive_Days,---Inactive Days (Recency)	max_date in the data - Last_transaction_date	
	COUNT( Case when datepart(WEEKDAY,Bill_date_timestamp) in (1, 7) then 1 end) as no_of_transaction_in_weekends,  --tran_weekend
	COUNT( Case when datepart(WEEKDAY,Bill_date_timestamp) not in (1, 7) then 1 end) as no_of_transaction_in_weekday,  --tran_wekdays
	COUNT( case when DATEPART(HOUR,Bill_date_timestamp)>=12 then 1 end) as transaction_after_12pm, --after 12
	COUNT( case when datepart (hour,Bill_date_timestamp)<12 then 1 end) as transaction_before_12pm,  --before 12
	count( case when Discount <>0 then 1 end) as No_of_transactions_with_discount,	
	count( case when cost_per_unit*Quantity > Total_Amount then 1 end) as no_of_transactions_with_loss---No.of transactions with loss		
	from Finalised_Records
	group by Customer_id,customer_city,customer_state, gender 
),
--second cte
payment_summary as (
    select 
        order_id,
        count(case when payment_type = 'credit_card' then 1 end) as transaction_with_credit_card,
        count(case when payment_type = 'upi/cash' then 1 end) as transaction_with_cash_upi,
        count(case when payment_type = 'debit_card' then 1 end) as transaction_with_debit_card,
        count(case when payment_type = 'voucher' then 1 end) as transaction_with_voucher
    from payments
    group by order_id
),
--third cte
cte2 as 
(
select c.*,
sum(ps.transaction_with_credit_card) as transaction_with_credit_card,
        sum(ps.transaction_with_cash_upi) as transaction_with_cash_upi,
        sum(ps.transaction_with_debit_card) as transaction_with_debit_card,
        sum(ps.transaction_with_voucher) as transaction_with_voucher
from cte c join Finalised_Records o
on c.Customer_id=o.Customer_id
join payment_summary ps
	on o.order_id=ps.order_id
	 GROUP BY 
        c.Customer_id, c.Gender, c.customer_city, c.customer_state,
        c.no_of_transaction, c.total_qty, c.unique_item_purchase,
        c.first_purchase, c.last_purchase, c.MRP, c.revenue,
        c.total_cost, c.total_discount, c.profit_per_cust, c.rating,
        c.no_of_channel_for_purchase, c.no_of_store, c.no_of_city_purchased,
        c.Tenure, c.Inactive_Days, c.no_of_transaction_in_weekends,
        c.no_of_transaction_in_weekday, c.transaction_after_12pm,
        c.transaction_before_12pm, c.No_of_transactions_with_discount,
        c.no_of_transactions_with_loss
)
select * 
--into customer_360 
from cte2 

select * from customer_360

--drop table customer_360

----------------------- store 360 -----------------

WITH store_cte AS (
    SELECT 
        Delivered_StoreID AS StoreID, 
        seller_city, 
        seller_state, 
        Region,
        COUNT(DISTINCT order_id) AS total_transaction, 
        SUM(Quantity) AS total_quantity_sold, 
        SUM(Discount) AS total_discounts,
        ROUND(SUM(cost_per_unit * quantity), 2) AS total_cost,
        ROUND(SUM(Total_Amount), 2) AS total_sales,
        ROUND((SUM(Total_Amount - (Quantity * Cost_Per_Unit)) * 100.0) / SUM(Total_Amount), 2) AS margin_PERCENT,
        ROUND(SUM(Total_Amount - (Quantity * Cost_Per_Unit)), 2) AS net_profit,
        COUNT(DISTINCT Customer_id) AS unique_customers,
        COUNT(DISTINCT Category) AS no_of_distinct_category_purchased,
        COUNT(DISTINCT product_id) AS no_of_distinct_product_purchased,
        COUNT(CASE WHEN Discount <> 0 THEN 1 END) AS no_of_transactions_with_discount,
        COUNT(CASE WHEN cost_per_unit * Quantity > Total_Amount THEN 1 END) AS no_of_transactions_with_loss,
        COUNT(DISTINCT channel) AS no_of_channel_for_purchase,
        COUNT(CASE WHEN DATEPART(WEEKDAY, Bill_date_timestamp) IN (1, 7) THEN 1 END) AS no_of_transaction_in_weekends,
        COUNT(CASE WHEN DATEPART(WEEKDAY, Bill_date_timestamp) NOT IN (1, 7) THEN 1 END) AS no_of_transaction_in_weekday,
        AVG(avg_rating) AS rating
    FROM Finalised_Records
    GROUP BY Delivered_StoreID, seller_city, seller_state, Region
),
payment_summary AS (
    SELECT 
        order_id,
        COUNT(CASE WHEN payment_type = 'credit_card' THEN 1 END) AS transaction_with_credit_card,
        COUNT(CASE WHEN payment_type = 'upi/cash' THEN 1 END) AS transaction_with_cash_upi,
        COUNT(CASE WHEN payment_type = 'debit_card' THEN 1 END) AS transaction_with_debit_card,
        COUNT(CASE WHEN payment_type = 'voucher' THEN 1 END) AS transaction_with_voucher
    FROM payments
    GROUP BY order_id
),
final_cte AS (
    SELECT 
        s.*,
        SUM(ps.transaction_with_credit_card) AS transaction_with_credit_card,
        SUM(ps.transaction_with_cash_upi) AS transaction_with_cash_upi,
        SUM(ps.transaction_with_debit_card) AS transaction_with_debit_card,
        SUM(ps.transaction_with_voucher) AS transaction_with_voucher
    FROM store_cte s
    JOIN Finalised_Records f ON s.StoreID = f.Delivered_StoreID
    JOIN payment_summary ps ON f.order_id = ps.order_id
    GROUP BY 
        s.StoreID, s.seller_city, s.seller_state, s.Region, s.total_transaction,
        s.total_quantity_sold, s.total_discounts, s.total_cost, s.total_sales,
        s.margin, s.net_profit, s.unique_customers, s.no_of_distinct_category_purchased,
        s.no_of_distinct_product_purchased, s.no_of_transactions_with_discount,
        s.no_of_transactions_with_loss, s.no_of_channel_for_purchase,
        s.no_of_transaction_in_weekends, s.no_of_transaction_in_weekday, s.rating
)
SELECT * 
--into store_360
FROM final_cte

select * from store_360

--drop table store_360

----------------------------order 360---------------

select * --into order_360 
from(
select 
o.order_id as Order_id,
max(o.Bill_date_timestamp) Bill_date_timestamp ,
count(distinct o.product_id) as No_of_product,
sum(o.quantity) as Quantity,
round(sum(o.total_amount), 2) as Total_Amount,
sum(o.discount) as Discount,
count(case when o.discount > 0 then 1 end) as Items_with_discount,
round(sum(o.cost_per_unit * o.quantity), 2) as Total_cost, 
AVG(o.Avg_rating) as Avg_Ratings,
round(sum(o.total_amount  - (o.cost_per_unit * o.quantity)), 2) as Total_profit,
count(case when (o.total_amount - (o.cost_per_unit * o.quantity)) < 0 then 1 end) as orders_with_loss,
count(case when (o.total_amount  - (o.cost_per_unit * o.quantity)) > 50 then 1 end) as Orders_with_high_profit,
count(distinct o.category) as Distinct_categories,
max(case when datepart(weekday, o.bill_date_timestamp) in (1, 7) then 1 else 0 end) as Weekend_trans_flag,
max(case when o.discount > 0 then 1 else 0 end) as Orders_with_discount,
round((sum(o.total_amount - (o.cost_per_unit * o.quantity)) * 1.0 / nullif(sum(o.total_amount), 0)) * 100, 2) as Profit_margin_percent,
max(datename(weekday, o.bill_date_timestamp)) as Day_of_week,
max(case 
when datepart(hour, o.bill_date_timestamp) between 6 and 12 then 'Morning'
when datepart(hour, o.bill_date_timestamp) between 12 and 18 then 'Afternoon'
when datepart(hour, o.bill_date_timestamp) between 18 and 21 then 'Evening'
else 'Night'
end) as Time_of_day,
max(case 
when o.channel = 'Online' then 'Online'
when o.channel = 'instore' then 'Instore'
when o.channel = 'Phone Delivery' then 'Phone Delivery'
else 'Other'
end) as Channel_used
from finalised_records o
group by o.order_id --,o.Bill_date_timestamp
) as o


select * from order_360

--drop table order_360


----==========================================================
---------------======================= high level metrics--------------

-- Total Revenue/spend(SALES INFORMACTION)

select sum(total_sales) total_revenue,
sum(total_cost) total_Cost,
sum(net_profit) total_Profit, 
concat(round(avg(MARGIN_PERCENT),2),'%') net_percent,
sum(total_discounts) total_discount,
concat(round((sum(total_discounts)/sum(total_sales)*100),2),'%') discount_percent,
count(distinct seller_state) no_of_state,
count(distinct seller_city) no_of_cityes,
count(distinct region) no_of_region
from store_360


-- Total customer
select count(distinct customer_id) total_cust, 
count(distinct customer_city) no_of_cust_city,
round(avg(revenue*1.0),2) avg_spend_per_cust,
cast(avg(total_discount*1.0) as float) avg_discount_Per_cust,
round(avg(profit_per_cust),2) avg_profit_per_cust,
(select count(customer_id) from customer_360 where no_of_transaction>1) repated_buyers,
avg(Tenure) avg_tenure,
avg(Inactive_Days) avg_incative_days,
cast(avg(rating*1.0) as float) rating 
from customer_360


---order 360

SELECT 
    COUNT(DISTINCT order_id) AS no_of_order,
    SUM(quantity) AS total_quantity,
    AVG(CAST(quantity AS FLOAT)) AS avg_quantity,
    AVG(CAST(total_amount*1.0 AS FLOAT)) AS avg_spend_per_order,
    AVG(CAST(discount*1.0 AS FLOAT)) AS avg_discount_Per_order,
    AVG(CAST(no_of_items AS FLOAT)) AS avg_product_Per_order,
    AVG(CAST(Avg_ratings*1.0 AS FLOAT)) AS rating
FROM order_360;



-------CUSTOMER BY STATE-------
SELECT customer_state,
	COUNT(CASE WHEN Gender = 'm' THEN 1 END) male_cust,
	COUNT(CASE WHEN Gender = 'f' THEN 1 END) female_cust
FROM customer_360
GROUP BY customer_state
order by female_cust desc


-- state wise customers
select customer_state,count(*) customer from customer_360
group by customer_state
order by customer desc


--avg cust spend per month
WITH monthly_spend AS (
    SELECT 
        Customer_id,
        YEAR(Bill_date_timestamp) AS yr,
        MONTH(Bill_date_timestamp) AS mn,
        SUM(Total_Amount) AS monthly
    FROM Finalised_Records
    GROUP BY Customer_id, YEAR(Bill_date_timestamp), MONTH(Bill_date_timestamp)
)
SELECT 
    ROUND(AVG(monthly), 2) AS avg_spend_per_customer_per_month
FROM monthly_spend;





---------------------------



---------------store wise sales and profit -----

select top 10 StoreID, sum(total_sales) revenue ,
sum(net_profit) profit
from store_360
group by StoreID
order by revenue desc
--- revenue of store 103 is high now see


select  ROUND(total_sales/total_transaction,2) AVG_ORDER_VALUE
from store_360
where StoreID='ST103'
-----------

----============new customers acquired every month (who made transaction first time in the data)

select datePART(MONTH,first_purchase) as months,DATENAME(MONTH, first_purchase) months_,
count(Customer_id) no_of_cust_aqure from customer_360
group by month(first_purchase),DATENAME(MONTH, first_purchase)
order by months

--new customer by years
select year(first_purchase) years, count(Customer_id) no_of_cust_aqure from customer_360
group by year(first_purchase)
order by years

-- NEW CUSTOMER BY QUARTER
SELECT CASE
	WHEN DATEPART(QUARTER, first_purchase) = 1 THEN 4 
		ELSE DATEPART(QUARTER, first_purchase)-1
	END AS QUARTER_NAME,
    YEAR(first_purchase) AS years,
    COUNT(Customer_id) AS no_of_cust_acquired
FROM customer_360
GROUP BY 
    YEAR(first_purchase), 
    DATEPART(QUARTER, first_purchase)
ORDER BY years, quarter_name

----=================Revenue from new customers on monthly basis

select year(first_purchase) as years,
DATENAME(MONTH,first_purchase) as month_name,--count(Customer_id) customer_count,
round(sum(revenue),2) as total_amt
from customer_360
GROUP BY year(first_purchase),DATENAME(MONTH,first_purchase),month(first_purchase)
ORDER BY YEARS,month(first_purchase)

--- revenue by monthly bases

select year(Bill_date_timestamp) as years,
DATENAME(MONTH,Bill_date_timestamp) as month_name,
round(sum(Total_Amount),2) as total_amt
from order_360
GROUP BY year(Bill_date_timestamp),DATENAME(MONTH,Bill_date_timestamp),month(Bill_date_timestamp)
ORDER BY YEARS,month(Bill_date_timestamp)

---------  PROFIT AT MONTHLY
select year(Bill_date_timestamp) as years,
DATENAME(MONTH,Bill_date_timestamp) as month_name,
round(sum(Total_profit),2) as PROFIT
from order_360
GROUP BY year(Bill_date_timestamp),DATENAME(MONTH,Bill_date_timestamp),month(Bill_date_timestamp)
ORDER BY YEARS,month(Bill_date_timestamp)


----- REGION WISE REVENUE AND PROFIT

select Region,round(sum(Total_Amount),2) revenue,
round(sum(Total_Amount-(COST_PER_UNIT*QUANTITY)),2) profit
from Finalised_Records
group by Region
ORDER BY revenue DESC

SELECT * FROM Finalised_Records

------- CHANNEL USED
select Channel_used,sum(Quantity) TOTAL_QUANTITY,
round(sum(Total_Amount),2) REVENUE
from order_360
group by Channel_used


---------------------- ========================================





--------------============CATEGORY ANALYSIS=====================

-- Highest Selling Category
SELECT TOP 5 Category, SUM(quantity) AS total_qty
FROM Finalised_Records 
GROUP BY Category 
ORDER BY total_qty DESC;

--- BOTTOM 5 SELLING CATEGORY
SELECT TOP 5 Category, SUM(quantity) AS total_qty
FROM Finalised_Records 
GROUP BY Category 
ORDER BY total_qty

-----------CATEGORY WISE REVENUE (PARETO)
SELECT Category, ROUND(SUM(Total_Amount),2) AS REVENUE
FROM Finalised_Records 
GROUP BY Category 
ORDER BY REVENUE DESC

---(pareto)
WITH RevenueData AS (
    SELECT Category, ROUND(SUM(Total_Amount),2) AS Revenue
    FROM Finalised_Records
    GROUP BY Category    
)
SELECT 
    Category, 
    Revenue, 
    ROUND((SUM(Revenue) OVER (ORDER BY Revenue DESC) / (SELECT SUM(Revenue) FROM RevenueData)) * 100, 2) AS Cumulative_Percentage
FROM RevenueData
ORDER BY Revenue DESC

------------DISCOUNT BY CATEGORY
SELECT  Category, SUM(Discount) AS TOTAL_DISCOUNT
FROM Finalised_Records 
GROUP BY Category 
ORDER BY TOTAL_DISCOUNT DESC;


-------------PROFIT BY CATEGORY
SELECT  Category, ROUND(SUM(Total_Amount)-SUM(Cost_Per_Unit*Quantity),2) AS TOTAL_PROFIT
FROM Finalised_Records 
GROUP BY Category 
ORDER BY TOTAL_PROFIT DESC;



 ------List the top 2 most expensive products sorted by price 
 
 select Category, product_id ,MRP from(
 select  Category, product_id,ROUND(MRP,2) MRP,
 rank() over (partition by CATEGORY order by MRP desc) rn
 from Finalised_Records
 group by Category, product_id,MRP
 ) as x 
 where rn< 3

 --Popular categories/Popular Products by store, state, region. 

select region ,category,orders,revenue from(
select region,Category,sum(Quantity) orders,sum(Total_Amount) revenue,
rank() over(partition by region order by sum(quantity) desc) rn
from Finalised_Records
group by region, category
) as x
where rn<=4
ORDER BY REGION, orders


--- by state CATEGORY 
select seller_state ,category,ORDERS from(
select seller_state,Category,sum(Quantity) ORDERS,
rank() over(partition by seller_state order by sum(Quantity) desc) rn
from Finalised_Records
group by seller_state, category
) as x
where rn<=2

----- by store WISE 
select Delivered_StoreID,category,Orders from(
select Delivered_StoreID,Category,sum(Quantity) ORDERS,
rank() over(partition by Delivered_StoreID order by sum(Quantity) desc) rn
from Finalised_Records
group by Delivered_StoreID, category
) as x
where rn<=2

select * from Finalised_Records

-------------- customer preferences CATEGORY WISE
SELECT Category,count(distinct Customer_id) no_of_Cust
FROM Finalised_Records
group by category
order by no_of_Cust desc
--------------- category wise analysis
--============================(REMAINING)--------------------
-- Highest Selling Product
SELECT TOP 10 product_id, SUM(quantity) AS total_qty 
FROM Finalised_Records 
GROUP BY product_id 
ORDER BY total_qty DESC;

--------------------------------
select month(first_purchase) as mon,count(Customer_id)as tot,
round(count(Customer_id)*100.0/sum(count(Customer_id))over(),2) percent_
from customer_360
group by month(first_purchase)

--------------------------------







