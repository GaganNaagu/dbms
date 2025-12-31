drop database if exists order_processing;
create database order_processing;
use order_processing;

create table if not exists Customers (
	cust_id int primary key,
	cname varchar(35) not null,
	city varchar(35) not null
);

create table if not exists Orders (
	order_id int primary key,
	odate date not null,
	cust_id int,
	order_amt int not null,
	foreign key (cust_id) references Customers(cust_id) on delete cascade
);

create table if not exists Items (
	item_id  int primary key,
	unitprice int not null
);

create table if not exists OrderItems (
	order_id int not null,
	item_id int not null,
	qty int not null,
	foreign key (order_id) references Orders(order_id) on delete cascade,
	foreign key (item_id) references Items(item_id) on delete cascade
);

create table if not exists Warehouses (
	warehouse_id int primary key,
	city varchar(35) not null
);

create table if not exists Shipments (
	order_id int not null,
	warehouse_id int not null,
	ship_date date not null,
	foreign key (order_id) references Orders(order_id) on delete cascade,
	foreign key (warehouse_id) references Warehouses(warehouse_id) on delete cascade
);

INSERT INTO Customers VALUES
(0001, "Customer_1", "Mysuru"),
(0002, "Customer_2", "Bengaluru"),
(0003, "Kumar", "Mumbai"),
(0004, "Customer_4", "Dehli"),
(0005, "Customer_5", "Bengaluru");

INSERT INTO Orders VALUES
(001, "2020-01-14", 0001, 2000),
(002, "2021-04-13", 0002, 500),
(003, "2019-10-02", 0003, 2500),
(004, "2019-05-12", 0005, 1000),
(005, "2020-12-23", 0004, 1200);

INSERT INTO Items VALUES
(0001, 400),
(0002, 200),
(0003, 1000),
(0004, 100),
(0005, 500);

INSERT INTO Warehouses VALUES
(0001, "Mysuru"),
(0002, "Bengaluru"),
(0003, "Mumbai"),
(0004, "Dehli"),
(0005, "Chennai");

INSERT INTO OrderItems VALUES
(001, 0001, 5),
(002, 0005, 1),
(003, 0005, 5),
(004, 0003, 1),
(005, 0004, 12);

INSERT INTO Shipments VALUES
(001, 0002, "2020-01-16"),
(002, 0001, "2021-04-14"),
(003, 0004, "2019-10-07"),
(004, 0003, "2019-05-16"),
(005, 0005, "2020-12-23");


SELECT * FROM Customers;
SELECT * FROM Orders;
SELECT * FROM OrderItems;
SELECT * FROM Items;
SELECT * FROM Shipments;
SELECT * FROM Warehouses;


-- 1. List the Order# and Ship_date for all orders shipped from Warehouse# "0001".
select order_id,ship_date from Shipments where warehouse_id=0001;

-- 2. List the Warehouse information from which the Customer named "Kumar" was supplied his orders. Produce a listing of Order#, Warehouse#
SELECT s.order_id, s.warehouse_id
FROM Shipments s
JOIN Orders o    ON s.order_id = o.order_id
JOIN Customers c ON o.cust_id = c.cust_id
WHERE c.cname = 'Kumar';

-- 3. Produce a listing: Cname, #ofOrders, Avg_Order_Amt, where the middle column is the total number of orders by the customer and the last column is the average order amount for that customer. (Use aggregate functions)
SELECT c.cname,
       COUNT(o.order_id) AS no_of_orders,
       AVG(o.order_amt) AS avg_order_amt
FROM Customers c
JOIN Orders o ON c.cust_id = o.cust_id
GROUP BY c.cname;

-- 4. Delete all orders for customer named "Kumar".
delete from Orders where cust_id = (select cust_id from Customers where cname like "%Kumar%");


-- 5. Find the item with the maximum unit price.
select max(unitprice) from Items;

-- 6. Create a view to display orderID and shipment date of all orders shipped from a warehouse 2.

create view ShipmentDatesFromWarehouse2 as
select order_id, ship_date
from Shipments
where warehouse_id=2;

select * from ShipmentDatesFromWarehouse2;


-- 7. A tigger that updates order_amount based on quantity and unit price of order_item

DELIMITER //
CREATE TRIGGER UpdateOrderAmt
AFTER INSERT ON OrderItems
FOR EACH ROW
BEGIN
    UPDATE Orders
    SET order_amt = NEW.qty * (
        SELECT unitprice
        FROM Items
        WHERE item_id = NEW.item_id
    )
    WHERE order_id = NEW.order_id;
END;
//
DELIMITER ;


INSERT INTO Orders VALUES
(006, "2020-12-23", 0004, 1200);

INSERT INTO OrderItems VALUES
(006, 0001, 5); -- This will automatically update the Orders Table also

select * from Orders;

--
--
--    EEEEEEEEEEEEEEEEEEEEEE                             tttt
--    E::::::::::::::::::::E                          ttt:::t
--    E::::::::::::::::::::E                          t:::::t
--    EE::::::EEEEEEEEE::::E                          t:::::t
--      E:::::E       EEEEEExxxxxxx      xxxxxxxttttttt:::::ttttttt   rrrrr   rrrrrrrrr   aaaaaaaaaaaaa
--      E:::::E              x:::::x    x:::::x t:::::::::::::::::t   r::::rrr:::::::::r  a::::::::::::a
--      E::::::EEEEEEEEEE     x:::::x  x:::::x  t:::::::::::::::::t   r:::::::::::::::::r aaaaaaaaa:::::a
--      E:::::::::::::::E      x:::::xx:::::x   tttttt:::::::tttttt   rr::::::rrrrr::::::r         a::::a
--      E:::::::::::::::E       x::::::::::x          t:::::t          r:::::r     r:::::r  aaaaaaa:::::a
--      E::::::EEEEEEEEEE        x::::::::x           t:::::t          r:::::r     rrrrrrraa::::::::::::a
--      E:::::E                  x::::::::x           t:::::t          r:::::r           a::::aaaa::::::a
--      E:::::E       EEEEEE    x::::::::::x          t:::::t    ttttttr:::::r          a::::a    a:::::a
--    EE::::::EEEEEEEE:::::E   x:::::xx:::::x         t::::::tttt:::::tr:::::r          a::::a    a:::::a
--    E::::::::::::::::::::E  x:::::x  x:::::x        tt::::::::::::::tr:::::r          a:::::aaaa::::::a
--    E::::::::::::::::::::E x:::::x    x:::::x         tt:::::::::::ttr:::::r           a::::::::::aa:::a
--    EEEEEEEEEEEEEEEEEEEEEExxxxxxx      xxxxxxx          ttttttttttt  rrrrrrr            aaaaaaaaaa  aaaa
--
--
--
--
--
--
--

-- 8. Trigger that prevents warehouse details from being deleted if any item has to be shipped from that warehouse

DELIMITER $$
CREATE TRIGGER PreventWarehouseDelete
	BEFORE DELETE ON Warehouses
    FOR EACH ROW
    BEGIN
		IF OLD.warehouse_id IN (SELECT warehouse_id FROM Shipments NATURAL JOIN Warehouses) THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'An item has to be shipped from this warehouse!';
		END IF;
	END;
$$
DELIMITER ;


DELETE FROM Warehouses WHERE warehouse_id = 2; -- Will give error since an item has to be shipped from warehouse 2


-- 9. A view that shows the warehouse ids from where the kumar’s orders are being shipped.

create view WharehouseWithKumarOrders as
select s.warehouse_id
from Warehouses w, Customers c, Orders o, Shipments s
where w.warehouse_id = s.warehouse_id and s.order_id=o.order_id and o.cust_id=c.cust_id and c.cname="Kumar";

select * from WharehouseWithKumarOrders;
