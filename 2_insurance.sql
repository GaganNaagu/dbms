DROP DATABASE IF EXISTS insurance;
CREATE DATABASE insurance;
USE insurance;

CREATE TABLE IF NOT EXISTS person (
driver_id VARCHAR(255) NOT NULL,
driver_name TEXT NOT NULL,
address TEXT NOT NULL,
PRIMARY KEY (driver_id)
);

CREATE TABLE IF NOT EXISTS car (
reg_no VARCHAR(255) NOT NULL,
model TEXT NOT NULL,
c_year INTEGER,
PRIMARY KEY (reg_no)
);

CREATE TABLE IF NOT EXISTS accident (
report_no INTEGER NOT NULL,
accident_date DATE,
location TEXT,
PRIMARY KEY (report_no)
);

CREATE TABLE IF NOT EXISTS owns (
driver_id VARCHAR(255) NOT NULL,
reg_no VARCHAR(255) NOT NULL,
FOREIGN KEY (driver_id) REFERENCES person(driver_id) ON DELETE CASCADE,
FOREIGN KEY (reg_no) REFERENCES car(reg_no) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS participated (
driver_id VARCHAR(255) NOT NULL,
reg_no VARCHAR(255) NOT NULL,
report_no INTEGER NOT NULL,
damage_amount FLOAT NOT NULL,
FOREIGN KEY (driver_id) REFERENCES person(driver_id) ON DELETE CASCADE,
FOREIGN KEY (reg_no) REFERENCES car(reg_no) ON DELETE CASCADE,
FOREIGN KEY (report_no) REFERENCES accident(report_no)
);

INSERT INTO person VALUES
("D111", "Driver_1", "Kuvempunagar, Mysuru"),
("D222", "Smith", "JP Nagar, Mysuru"),
("D333", "Driver_3", "Udaygiri, Mysuru"),
("D444", "Driver_4", "Rajivnagar, Mysuru"),
("D555", "Driver_5", "Vijayanagar, Mysore");

INSERT INTO car VALUES
("KA-20-AB-4223", "Swift", 2020),
("KA-20-BC-5674", "Mazda", 2017),
("KA-21-AC-5473", "Alto", 2015),
("KA-21-BD-4728", "Triber", 2019),
("KA-09-MA-1234", "Tiago", 2018);

INSERT INTO accident VALUES
(43627, "2020-04-05", "Nazarbad, Mysuru"),
(56345, "2019-12-16", "Gokulam, Mysuru"),
(63744, "2020-05-14", "Vijaynagar, Mysuru"),
(54634, "2019-08-30", "Kuvempunagar, Mysuru"),
(65738, "2021-01-21", "JSS Layout, Mysuru"),
(66666, "2021-01-21", "JSS Layout, Mysuru");

INSERT INTO owns VALUES
("D111", "KA-20-AB-4223"),
("D222", "KA-20-BC-5674"),
("D333", "KA-21-AC-5473"),
("D444", "KA-21-BD-4728"),
("D222", "KA-09-MA-1234");

INSERT INTO participated VALUES
("D111", "KA-20-AB-4223", 43627, 20000),
("D222", "KA-20-BC-5674", 56345, 49500),
("D333", "KA-21-AC-5473", 63744, 15000),
("D444", "KA-21-BD-4728", 54634, 5000),
("D222", "KA-09-MA-1234", 65738, 25000);



-- 1. Find the total number of people who owned a car that were involved in accidents in 2021

select COUNT(DISTINCT p.driver_id)
from participated p
join accident a on p.report_no = a.report_no
where year(a.accident_date) = 2021;

-- 2. Find the number of accident in which cars belonging to smith were involved

SELECT COUNT(DISTINCT a.report_no)
FROM accident a
JOIN participated ptd ON a.report_no = ptd.report_no
JOIN person p ON ptd.driver_id = p.driver_id
WHERE p.driver_name = 'Smith';

-- 3. Add a new accident to the database

insert into accident values
(45562, "2024-04-05", "Mandya");

insert into participated values
("D222", "KA-21-BD-4728", 45562, 50000);


-- 4. Delete the Mazda belonging to Smith

DELETE c
FROM car c
JOIN owns o   ON c.reg_no = o.reg_no
JOIN person p ON o.driver_id = p.driver_id
WHERE c.model = 'Mazda' AND p.driver_name = 'Smith';

-- 5. Update the damage amount for the car with reg_no of KA-09-MA-1234 in the accident with report_no 65738

update participated set damage_amount=10000 where report_no=65738 and reg_no="KA-09-MA-1234";

-- 6. View that shows models and years of car that are involved in accident

create view CarsInAccident as
select distinct model, c_year
from car c, participated p
where c.reg_no=p.reg_no;

select * from CarsInAccident;

-- 7. A trigger that prevents a driver from participating in more than 3 accidents in a given year.

DELIMITER //
CREATE TRIGGER PreventParticipation
BEFORE INSERT ON participated
FOR EACH ROW
BEGIN
    DECLARE acc_year INT;

    SELECT YEAR(accident_date)
    INTO acc_year
    FROM accident
    WHERE report_no = NEW.report_no;

    IF (
        SELECT COUNT(*)
        FROM participated p
        JOIN accident a ON p.report_no = a.report_no
        WHERE p.driver_id = NEW.driver_id
          AND YEAR(a.accident_date) = acc_year
    ) >= 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Driver has already participated in 3 accidents in this year';
    END IF;
END;
//
DELIMITER ;


INSERT INTO participated VALUES
("D222", "KA-20-AB-4223", 66666, 20000);