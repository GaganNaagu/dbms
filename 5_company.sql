drop database if exists company;
create database company;
use company;

create table if not exists Employee(
	ssn varchar(35) primary key,
	name varchar(35) not null,
	address varchar(255) not null,
	sex varchar(7) not null,
	salary int not null,
	super_ssn varchar(35),
	d_no int,
	foreign key (super_ssn) references Employee(ssn) on delete set null
);

create table if not exists Department(
	d_no int primary key,
	dname varchar(100) not null,
	mgr_ssn varchar(35),
	mgr_start_date date,
	foreign key (mgr_ssn) references Employee(ssn) on delete cascade
);

create table if not exists DLocation(
	d_no int not null,
	d_loc varchar(100) not null,
	foreign key (d_no) references Department(d_no) on delete cascade
);

create table if not exists Project(
	p_no int primary key,
	p_name varchar(25) not null,
	p_loc varchar(25) not null,
	d_no int not null,
	foreign key (d_no) references Department(d_no) on delete cascade
);

create table if not exists WorksOn(
	ssn varchar(35) not null,
	p_no int not null,
	hours int not null default 0,
	foreign key (ssn) references Employee(ssn) on delete cascade,
	foreign key (p_no) references Project(p_no) on delete cascade
);

INSERT INTO Employee VALUES
("01NB235", "Likith_Scott","Siddartha Nagar, Mysuru", "Male", 1500000, "01NB235", 5),
("01NB354", "Employee_2", "Lakshmipuram, Mysuru", "Female", 1200000,"01NB235", 2),
("02NB254", "Employee_3", "Pune, Maharashtra", "Male", 1000000,"01NB235", 4),
("03NB653", "Employee_4", "Hyderabad, Telangana", "Male", 2500000, "01NB354", 5),
("04NB234", "Employee_5", "JP Nagar, Bengaluru", "Female", 1700000, "01NB354", 1);


INSERT INTO Department VALUES
(001, "Human Resources", "01NB235", "2020-10-21"),
(002, "Quality Assesment", "03NB653", "2020-10-19"),
(003,"System assesment","04NB234","2020-10-27"),
(005,"Production","02NB254","2020-08-16"),
(004,"Accounts","01NB354","2020-09-4");


INSERT INTO DLocation VALUES
(001, "Jaynagar, Bengaluru"),
(002, "Vijaynagar, Mysuru"),
(003, "Chennai, Tamil Nadu"),
(004, "Mumbai, Maharashtra"),
(005, "Kuvempunagar, Mysuru");

INSERT INTO Project VALUES
(241563, "System Testing", "Mumbai, Maharashtra", 004),
(532678, "IOT", "JP Nagar, Bengaluru", 001),
(453723, "Product Optimization", "Hyderabad, Telangana", 005),
(278345, "Yeild Increase", "Kuvempunagar, Mysuru", 005),
(426784, "Product Refinement", "Saraswatipuram, Mysuru", 002);

INSERT INTO WorksOn VALUES
("01NB235", 278345, 5),
("01NB354", 426784, 6),
("04NB234", 532678, 3),
("02NB254", 241563, 3),
("03NB653", 453723, 6);

alter table Employee add constraint foreign key (d_no) references Department(d_no) on delete cascade;

SELECT * FROM Department;
SELECT * FROM Employee;
SELECT * FROM DLocation;
SELECT * FROM Project;
SELECT * FROM WorksOn;


-- 1. Make a list of all project numbers for projects that involve an employee whose last name is ‘Scott’, either as a worker or as a manager of the department that controls the project.

-- Scott works on the project
SELECT DISTINCT p.p_no
FROM Project p
JOIN WorksOn w ON p.p_no = w.p_no
JOIN Employee e ON w.ssn = e.ssn
WHERE e.name LIKE '%Scott'

UNION

-- Scott manages the department that controls the project
SELECT DISTINCT p.p_no
FROM Project p
JOIN Department d ON p.d_no = d.d_no
JOIN Employee e ON d.mgr_ssn = e.ssn
WHERE e.name LIKE '%Scott';


-- 2. Show the resulting salaries if every employee working on the ‘IoT’ project is given a 10 percent raise
SELECT e.ssn, e.name,
       e.salary AS old_salary,
       e.salary * 1.1 AS new_salary
FROM Employee e
JOIN WorksOn w ON e.ssn = w.ssn
JOIN Project p ON w.p_no = p.p_no
WHERE p.p_name = 'IOT';


-- 3. Find the sum of the salaries of all employees of the ‘Accounts’ department, as well as the maximum salary, the minimum salary, and the average salary in this department
SELECT SUM(salary) AS total_salary,
       MAX(salary) AS max_salary,
       MIN(salary) AS min_salary,
       AVG(salary) AS avg_salary
FROM Employee e
JOIN Department d ON e.d_no = d.d_no
WHERE d.dname = 'Accounts';



-- 4. Retrieve the name of each employee who works on all the projects controlled by department number 1 (use NOT EXISTS operator).

SELECT e.name
FROM Employee e
JOIN WorksOn w ON e.ssn = w.ssn
JOIN Project p ON w.p_no = p.p_no
WHERE p.d_no = 1
GROUP BY e.ssn, e.name
HAVING COUNT(DISTINCT p.p_no) = (
    SELECT COUNT(*)
    FROM Project
    WHERE d_no = 1
);

-- 5. For each department that has more than one employees, retrieve the department number and the number of its employees who are making more than Rs. 6,00,000.
SELECT e.d_no, COUNT(*)
FROM Employee e
WHERE e.salary > 600000
GROUP BY e.d_no
HAVING COUNT(*) > 1;

-- 6. Create a view that shows name, dept name and location of all employees
CREATE VIEW emp_details AS
SELECT e.name, d.dname, dl.d_loc
FROM Employee e
JOIN Department d ON e.d_no = d.d_no
JOIN DLocation dl ON d.d_no = dl.d_no;

select * from emp_details;

-- 7. Create a trigger that prevents a project from being deleted if it is currently being worked by any employee.

DELIMITER //
CREATE TRIGGER PreventDelete
BEFORE DELETE ON Project
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT *
        FROM WorksOn
        WHERE p_no = OLD.p_no
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Project has assigned employees';
    END IF;
END;
//
DELIMITER ;


delete from Project where p_no=241563; -- Will give error