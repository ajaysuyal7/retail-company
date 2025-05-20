use retail
-- data cleaning steps


---1
select * FROM Orders
WHERE order_id IN (
    SELECT order_id
    FROM Orders o1
    WHERE EXISTS (
        SELECT 1
        FROM Orders o2
        WHERE o1.order_id = o2.order_id
          AND o1.product_id = o2.product_id
          AND o1.Quantity < o2.Quantity
		)
)

select count(*) from Orders

--DELETE the cummulative quantity and take only max

Delete FROM Orders
WHERE order_id IN (
    SELECT order_id
    FROM Orders o1
    WHERE EXISTS (
        SELECT 1
        FROM Orders o2
        WHERE o1.order_id = o2.order_id
          AND o1.product_id = o2.product_id
          AND o1.Quantity < o2.Quantity
    )
);

/*
----- another way 
WITH RankedRows AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY order_id, product_id ORDER BY Quantity DESC) AS rn
    FROM Orders
)
DELETE FROM Orders
WHERE order_id IN (
    SELECT order_id
    FROM RankedRows
    WHERE rn > 1
);


-- by timestamp
select * FROM Orders
WHERE order_id IN (
    SELECT order_id
    FROM Orders o1
    WHERE EXISTS (
        SELECT 1
        FROM Orders o2
        WHERE o1.order_id = o2.order_id
          AND o1.product_id = o2.product_id
          AND o1.Bill_date_timestamp < o2.Bill_date_timestamp
    )
);
*/

--2.  change the datatype
alter table orders
alter column bill_date_timestamp Datetime

--3.  finding the orders which ae not in the given range
SELECT *
FROM Orders
WHERE Bill_date_timestamp < '2021-09-01' or Bill_date_timestamp > '2023-11-01';
----------------
--  SELECT * FROM Orders
--  WHERE Bill_date_timestamp NOT BETWEEN '2021-09-01' AND '2023-11-01'

-- Delete those records
delete from Orders
where Bill_date_timestamp NOT BETWEEN '2021-09-01' AND '2023-11-01'


---4.  delete duplicate from store table
select StoreID,count(*)
from STORE
group by StoreID
having count(*) > 1


-----------------
WITH CTE AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY Storeid order by seller_city ) AS RowNumber
    FROM STORE
)
DELETE FROM CTE
WHERE RowNumber > 1;

---5. replace the values in category
select * from product_info
where product_description_lenght IS NULL OR
Category is null or category like '%#n/a'

update product_info
set Category ='orther'
where Category is null or category like '%#N/A'


------------------ UPDATEING THE PRODUCT DETAILS
UPDATE product_info
SET 
    product_name_lenght = CASE 
                             WHEN product_name_lenght IS NULL
								then 0 
                             ELSE product_name_lenght
                          END,
	product_description_lenght=CASE 
								WHEN product_description_lenght IS NULL 
									THEN 0
								ELSE product_description_lenght
								END,
	product_photos_qty= CASE 
							WHEN product_photos_qty IS NULL 
								THEN 0
							ELSE product_photos_qty
							END;


---6.  ----------------create ORDER REVIEW TABLE by agg -------------

SELECT count(*) FROM order_Rating
group by order_id
having count(*) >1

------------create new table by agg them------------
select order_id ,avg(Customer_Satisfaction_Score) as reviews
--into order_review
from order_Rating
group by order_id

-- new table 
select * from order_review

--7.   agg the payment table 
select order_id,payment_type,count(*) from payments
group by order_id,payment_type
having count(*)>1
order by order_id desc

------------------agg the payment value--------------------
select order_id,sum(payment_value) as payment_value
--into order_payments
from payments 
group by order_id

---------------------checking the values ------------------
select o.order_id,payment_value,sum(o.Total_Amount) as pay
from order_payments p
join Orders o
on p.order_id=o.order_id
group by o.order_id,payment_value

---------------------delete which payment are zero--------------------
Delete from order_payments
where payment_value <=0
---3 rows affected


----------------------Correct the delivery store -----------------------
with cte as(
	select order_id,min(Delivered_StoreID) as min_store
	from orders
	group by order_id
	) 
update Orders
set Delivered_StoreID=c.min_store
from Orders o
join cte c
on o.order_id=c.order_id
where o.Delivered_StoreID <> c.min_store
---  936 rows affected

select Customer_id,order_id,product_id,Delivered_StoreID from Orders
order by Customer_id


-----------------------------------------------
select * from Orders



--------------------------------------customer 360 profile-----------------------


