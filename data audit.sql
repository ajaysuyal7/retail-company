--CREATE DATABASE RETAIL
use retail


--1 CUSTOMER DATA
SELECT COUNT(*) AS NO_OF_CUSTOMERS 
FROM Customers

select Custid, count(*)
from Customers
group by Custid
having count(*)>1
-- no duplicated cust id

-- identify missing values
SELECT * FROM Customers
WHERE customer_city IS NULL OR customer_state IS NULL OR Gender IS NULL;

-- identify duplicate
SELECT CustID, customer_city, customer_state, COUNT(*)
FROM Customers
GROUP BY Custid,customer_city, customer_state
HAVING COUNT(*) > 1;

--checking invalid data
SELECT * 
FROM Customers
WHERE Gender NOT IN ('M', 'F');

-- NON NUMERIC VALUE IN NUMERIC
SELECT * FROM Customers
WHERE ISNUMERIC(Custid) = 0;

------------------------------------------------
--2  in Order data

SELECT COUNT(*) AS ORDERS
FROM Orders

select count(*) from(
select distinct * from Orders ) as x

-- no duplicate

-- MISSING VALUE
SELECT * FROM Orders
WHERE Customer_id IS NULL OR order_id IS NULL OR product_id IS NULL ;


--duplicated records

SELECT order_id,product_id,channel,Bill_date_timestamp
,COUNT(*) FROM Orders
GROUP BY order_id, product_id,Channel,Bill_date_timestamp
HAVING COUNT(*) > 1;
--we found 7088 data inconsistency

-- date time datatype
SELECT DISTINCT Bill_date_timestamp
FROM Orders;
--wrong formate of date

-- mismatch of total amount
SELECT * FROM Orders
WHERE round(Total_Amount,2) != ROUND((Quantity * MRP) - Discount*Quantity, 2); 
--no mismatch

-- invalid channels
SELECT * FROM Orders
WHERE Channel NOT IN ('Instore', 'Online','Phone Delivery');

--checking invalid store ids
SELECT * FROM Orders
WHERE Delivered_StoreID NOT LIKE 'ST%';

--checking less than or equal to zero quantity
SELECT * FROM Orders
WHERE Quantity <= 0;

-- Total Delevered store id
SELECT Delivered_storeid,  count(*) 
FROM Orders
group by Delivered_StoreID
--- 37 store found

----------------------------------]
-------------------------------
--3 Payment table
select count(*) from payments

SELECT COUNT(*)
FROM (SELECT DISTINCT * FROM payments) AS distinct_payments;
--found 615 duplicated record

--- missing values
SELECT * FROM Payments
WHERE order_id IS NULL OR payment_type IS NULL OR payment_value IS NULL;

--- wrong entry in payment
select * from payments
where payment_value not like '%[0-9.]%'

--- multiple time payment of same order id
SELECT order_id, COUNT(*) a 
		FROM Payments
		GROUP BY order_id
		HAVING COUNT(*) > 1

--multiple payment type and amount
select * from payments
where order_id in (
	select order_id from
		(
		SELECT order_id, COUNT(*) a 
		FROM Payments
		GROUP BY order_id
		HAVING COUNT(*) > 1) as xy
		)
order by order_id 


--found 2961 duplicated records  of order id

-- payment value negative or zero
SELECT * FROM Payments
WHERE payment_value <=0
-- ---   9 records found

SELECT * FROM Payments
WHERE payment_value <=0

--------------------------------------------------

--4 order review rating

SELECT COUNT(*) AS ORDERS
FROM ORDER_RATING

select count(*) from(
SELECT Distinct * 
FROM ORDER_RATING ) as x
--350 duplicate record

--Duplicate review for the same order
SELECT order_id, COUNT(*) FROM ORDER_RATING
group by order_id 
having COUNT(*)>1
----555 record found data inconsistency

-- zero value
select * from order_Rating
where Customer_Satisfaction_Score=0

select avg(Customer_Satisfaction_Score) from order_rating
--avg rating is 4
-----------------------
--------------------


--5 product info
select count(*) from product_info

select count(*) from (
select distinct * from product_info) as x


-- null value
SELECT * FROM Product_Info
WHERE product_id IS NULL OR Category IS NULL 

-- category not define
SELECT * FROM PRODUCT_INFO
where Category like '#%'
--623 product does not define any category

select count(distinct category) no_of_cat from product_info
-- total no of category is 14 in which one is #n/a
-------------------------
------------------------


--6 store
SELECT COUNT(*) FROM STORE
 
SELECT COUNT(*) FROM (
select distinct * from STORE) as x

-- missing value
select * from STORE
where seller_city like '%#' or seller_state  is null

--duplicate
select StoreID,count(*) from store 
group by StoreID
having count(*)>1

---------------------------------
----------------------------------
select * from Orders o
right join Customers c
on o.Customer_id=c.Custid
where order_id is null 
-- 866 customer does not purchased

----
----
select * from Orders o
right join product_info p
on o.product_id=p.product_id
where p.product_id is null
-- no null value fund in this

-------
-------

select Customer_id,order_id,Channel,count(*) from orders
group by Customer_id,order_id,Channel
-- total no of orders 98644

---------
select * from Orders

select Customer_id,order_id,Channel,count(*) as z from orders
group by Customer_id,order_id,Channel
having count(*)>1
order by order_id

---
--finding that channel have multiple 
SELECT order_id, COUNT( distinct channel) AS c
FROM Orders
GROUP BY  order_id
HAVING COUNT(DISTINCT channel) > 1

------ multiple order delivery store 
select order_id,Delivered_StoreID from Orders
where order_id in (
select order_id
from Orders
group by order_id
having count(distinct Delivered_StoreID)>1)
order by order_id

---1007 record haveing multiple store id

---- different amount is payment and order table
SELECT o.order_id, o.Total_Amount, p.payment_value
FROM Orders o
JOIN payments p ON o.order_id = p.order_id
WHERE o.Total_Amount <> p.payment_value
-- found mismatch of total amount and payment value

---- mismatch in delivery 
SELECT o.*
FROM Orders o
LEFT JOIN Store s ON o.Delivered_StoreID = s.StoreID
WHERE s.StoreID IS NULL;


-- mismatch of order and their review
select distinct * from order_Rating r
left join Orders o
on r.order_id=o.order_id
where o.order_id is null
--- 776 record found there review for the orders is different


---in order table find increase in no of orders 
SELECT DISTINCT o.*
FROM orders o
JOIN (
    SELECT customer_id, order_id, product_id
    FROM orders
    GROUP BY customer_id, order_id, product_id
    HAVING COUNT(*) > 1
) AS s
ON o.customer_id = s.customer_id
AND o.order_id = s.order_id
AND o.product_id = s.product_id;


-------------------
select distinct * from orders 
where product_id in
(
SELECT o.product_id--, COUNT(DISTINCT o.Cost_Per_Unit) AS unique_prices
FROM Orders o
GROUP BY o.product_id
HAVING COUNT(DISTINCT o.MRP) > 1
)
order by product_id 


------------------------


SELECT *
FROM orders
WHERE EXISTS (
    SELECT 1
    FROM orders AS o
    WHERE o.customer_id = orders.customer_id
    AND o.order_id = orders.order_id
    AND o.product_id = orders.product_id
    GROUP BY customer_id, order_id, product_id, channel
    HAVING COUNT(*) > 1
);