
--step 1. take only which total amt and payment details are matched

with Cust_order as (select A.Customer_id, A.Order_id, 
		round(sum(A.Total_Amount),0) as Total_amt from Order_Data A
		group by A.Customer_id, A.Order_id
		),
Orderpayment_grouped as
	(select  A.order_ID, round(sum(A.payment_value),0) as pay_value_total from order_payments
	A group by A.Order_id
	),
Match_order as (
		select A.* from Cust_order as A inner join Orderpayment_grouped as B 
		on A.Order_id =B.order_ID
		and A.Total_amt=B.pay_value_total)

select * --into Matched_order_1 
from Match_order

select * from Matched_order_1


----------88629 rows
----------2. takeing which deetails are not avaliable in the order table but in payment table


WITH Cust_order AS (
			SELECT 
			    A.Customer_id, 
			    A.Order_id, 
			    Round(sum(A.Total_Amount),0) AS Total_amt 
			FROM 
			    Order_Data A
			GROUP BY 
			    A.Customer_id, 
			    A.Order_id 

				),
Orderpayment_grouped AS (
			 SELECT 
			     A.Order_ID, 
			     Round(sum(A.payment_value ),0) AS pay_value_total 
			 FROM 
				order_payments A
			 GROUP BY 
			     A.Order_ID
		),
--- We are right joining as we are having null values 
Null_list AS (
    SELECT 
        B.* 
    FROM 
        Cust_order AS A 
    RIGHT JOIN 
        Orderpayment_grouped AS B 
    ON 
        A.Order_id = B.Order_ID 
        AND A.Total_amt = B.pay_value_total
    WHERE 
        A.Customer_id IS NULL
),

Remaining_ids as (SELECT 
    O.Customer_id ,O.Order_id, N.pay_value_total
FROM 
    Null_list  N inner join Order_Data O on N.Order_ID =O.Order_id and  N.pay_value_total = round(O.Total_Amount,0))	 

select * --into Remaining_orders_1 
from Remaining_ids

select * from Remaining_orders_1

---7268 rows effected
--------------------------------------------------------
with T1 as 
(select B.* from Matched_order_1 A inner join Order_Data B 
		on A.Customer_id=B.Customer_id and A.Order_id =B.Order_id),
T2 as 
(select B.* from Remaining_orders_1 A inner join  Order_Data B 
	on A.Customer_id=B.Customer_id and A.Order_id =B.Order_id and A.pay_value_total=round(B.Total_Amount,0) ),
T as (select * from T1 union all select * from T2 )
Select * into NEW_ORDER_TABLE_1 
	from T

select * from NEW_ORDER_TABLE_1


---95,898 rows affected

---------------------------------------------------------------
Select * into Integrated_Table_1 
from (
select A.*, D.Category ,C.Avg_rating,E.seller_city ,E.seller_state,E.Region,F.customer_city,F.customer_state,F.Gender from NEW_ORDER_TABLE_1 A  
	inner join (
	select A.ORDER_id,avg(A.reviews) as Avg_rating from order_review A group by A.ORDER_id) as C on C.ORDER_id =A.Order_id 
	inner join product_info as D on A.product_id =D.product_id
	inner join 
	(Select distinct * from STORE) as E on A.Delivered_StoreID =E.StoreID
	inner join Customers as F on A.Customer_id =F.Custid) as T

Select * From Integrated_Table_1

----------------------------
-------------FINAL RECORDS-------------

Select * Into Finalised_Records_no from (
Select * From Integrated_Table_1

UNION ALL

(Select T.Customer_id,T.order_id,T.product_id,T.Channel,T.Delivered_StoreID,T.Bill_date_timestamp,Sum(T.Net_QTY)as Quantity,T.Cost_Per_Unit,
T.MRP,T.Discount,SUM(Net_amount) as Total_Amount ,C.Category,F.reviews as Avg_rating,
G.seller_city,G.seller_state,G.Region,E.customer_city,E.customer_state,E.Gender from 
(
Select Distinct A.*,(A.Total_Amount/A.Quantity) as Net_amount, (A.Quantity/A.Quantity) as Net_QTY From Order_Data A
join Order_Data B
on A.order_id = B.order_id
where A.Delivered_StoreID <> B.Delivered_StoreID 
) 
as T
Inner Join product_info C
on T.product_id = C.product_id
inner join order_payments as D
on T.order_id = D.order_id
inner Join Customers As E
on T.Customer_id = E.Custid
inner join order_review F
on T.order_id = F.order_id
inner join STORE G
on T.Delivered_StoreID = G.StoreID
Group by T.Customer_id,T.order_id,T.product_id,T.Channel,T.Bill_date_timestamp,T.Cost_Per_Unit,T.Delivered_StoreID,
T.Discount,T.MRP,T.Total_Amount,T.Quantity,T.Net_amount,T.Net_QTY,C.Category,F.reviews,
G.seller_city,G.seller_state,G.Region,E.customer_city,E.customer_state,E.Gender) 
) as x





select o.order_id,sum(o.Total_Amount),sum(p.payment_value) as ta from Order_Data o
join payments p
on o.order_id=p.order_id
group by o.order_id
having sum(o.Total_Amount)<> sum(p.payment_value)


select * from Finalised_Records_no


------------ Creating the Table and storing the above Code output to Add_records table------------

Select * into Add_records from 
(
Select T.Customer_id,T.order_id,T.product_id,T.Channel,T.Delivered_StoreID,T.Bill_date_timestamp,Sum(T.Net_QTY)as Quantity,T.Cost_Per_Unit,
T.MRP,T.Discount,SUM(Net_amount) as Total_Amount ,C.Category,F.reviews as Avg_rating,
G.seller_city,G.seller_state,G.Region,E.customer_city,E.customer_state,E.Gender
from (
Select Distinct A.*,(A.Total_Amount/A.Quantity) as Net_amount, (A.Quantity/A.Quantity) as Net_QTY From Order_Data A
join Orders B
on A.order_id = B.order_id
where A.Delivered_StoreID <> B.Delivered_StoreID 
) as T
Inner Join product_info C
on T.product_id = C.product_id
inner join order_payments as D
on T.order_id = D.order_id
inner Join Customers As E
on T.Customer_id = E.Custid
inner join order_review F
on T.order_id = F.order_id
inner join STORE G
on T.Delivered_StoreID = G.StoreID
Group by T.Customer_id,T.order_id,T.product_id,T.Channel,T.Bill_date_timestamp,T.Cost_Per_Unit,T.Delivered_StoreID,
T.Discount,T.MRP,T.Total_Amount,T.Quantity,T.Net_amount,T.Net_QTY,C.Category,F.reviews,
G.seller_city,G.seller_state,G.Region,E.customer_city,E.customer_state,E.Gender
) a
--- 936 row affected


Select * --Into Finalised_Records From
(
Select * From Finalised_Records_no
except
---------------Checking whether the records in Add_records table are also available with Integratable_Table _1 
(Select A.* From Add_records A
inner Join Integrated_Table_1 B
on A.order_id = B.order_id) 
) x
----- We found some records thus these needed to be deleted so using the Except function from Finalised Records 
----- And storing the data into new table Finalised_Records 
Select * From Finalised_Records

--98266 rows
-------------------------------------------------------------------------------------------------------------

-- Need to create customer 360, order 360, store 360 tables for further analysis
select * from Finalised_Records

delete from Finalised_Records
where Bill_date_timestamp NOT BETWEEN '2021-09-01' AND '2023-11-01'


select * from Finalised_Records
where Bill_date_timestamp NOT BETWEEN '2021-09-01' AND '2023-11-01'


---------------finding some duplicate values--------------------------------

select * from
(
select Customer_id,order_id,product_id,Bill_date_timestamp, 
ROW_NUMBER() over(partition by customer_id,order_id,product_id order by order_id) rn
from Finalised_Records
where order_id in (
select order_id
from Finalised_Records
group by order_id,Customer_id,product_id
having count(*) >1
)
)as x
where rn <>1


--------------------delete the duplicate values------------------------

with duplicate as
(select Customer_id,order_id,product_id,Bill_date_timestamp, 
ROW_NUMBER() over(partition by customer_id,order_id,product_id order by order_id) rn
from Finalised_Records)
delete from duplicate
where rn<>1

select count (distinct order_id) from Finalised_Records





------------------------------


