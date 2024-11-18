-- This file provides my solution and a detailed explanation
-- to the Leetcode task called '185. Department Top Three Salaries'
-- Task Link: https://leetcode.com/problems/department-top-three-salaries/description/


-- TASK DESCRIPTION:


-- There are two tables: 'Employee' and 'Department'

-- Table: Employee
-- +--------------+---------+
-- | Column Name  | Type    |
-- +--------------+---------+
-- | id           | int     |
-- | name         | varchar |
-- | salary       | int     |
-- | departmentId | int     |
-- +--------------+---------+

-- id is the primary key (column with unique values) for this table.
-- departmentId is a foreign key (reference column) of the ID from 
-- the 'Department' table.
-- Each row of this table indicates the ID, name, and salary of an employee. 
-- It also contains the ID of their department.

-- Table: Department
-- +-------------+---------+
-- | Column Name | Type    |
-- +-------------+---------+
-- | id          | int     |
-- | name        | varchar |
-- +-------------+---------+

-- id is the primary key (column with unique values) for this table.
-- Each row of this table indicates the ID of a department and its name.

-- PROBLEM:
-- A company's executives are interested in seeing 
-- who earns the most money in each of the company's departments. 
-- A high earner in a department is an employee 
-- who has a salary in the top three unique salaries for that department.

-- Write a solution to find the employees 
-- who are high earners in each of the departments.

-- Return the result table in any order.

-- A department, name and salary of an employee should be displayed.

-- Example output:
-- +------------+----------+--------+
-- | Department | Employee | Salary |
-- +------------+----------+--------+
-- | IT         | Max      | 90000  |
-- | IT         | Joe      | 85000  |
-- | IT         | Randy    | 85000  |
-- | IT         | Will     | 70000  |
-- | Sales      | Henry    | 80000  |
-- | Sales      | Sam      | 60000  |
-- +------------+----------+--------+


-- SOLUTION:

-- Let's solve the problem step by step:

-- 1. First, I need to find the name of the department for each employee. 
-- To do this, I will join the table 'Department' to the 'Employee' table.
-- I will use 'INNER JOIN' to join the tables.
SELECT *
  FROM employee AS e
       INNER JOIN departmentid AS d
       ON e.departmentid = d.id

-- Let's display only department name, employee name, and salary columns:
SELECT d.name, e.name, e.salary
  FROM employee AS e
       INNER JOIN departmentid AS d
       ON e.departmentid = d.id

-- Now we have employees, the departments they work in, and employee salaries.
-- In other words, we have departments, the employees that work in corresponding departments, 
-- and all of the salaries of employees that belong to corresponding departments. 
-- Thus, we have all of the salaries of the departments.

-- 2. Second, I need to find the top three unique salaries for each of the departments that have salaries.
-- To do this, I need to rank salaries in a way where the highest salary of the department would get the highest rank '1'.
-- The second highest would get '2' rank and the third would get '3'. If the salaries are the same, they should have the same rank.
-- To do this, I will use the 'DENSE_RANK' window function. 
-- The function assigns consecutive ranks without gaps, within its partition. 
-- If values are the same, they receive the same rank. 
-- The function should be used with the 'ORDER BY' clause to rank the values in the desired order 
-- (highest values receive the highest ranks or the lowest values receive the highest ranks)
-- I will partition the table by the 'd.name' column because I need to rank salaries for each of the departments.
-- Also, I need to sort the salary values in descending order, because I want the highest salaries to receive the highest rank.
SELECT d.name, e.name, e.salary,
       DENSE_RANK() OVER(PARTITION BY d.id ORDER BY e.salary DESC)
  FROM employee AS e
       INNER JOIN departmentid AS d
       ON e.departmentid = d.id

-- 3. Next, I want to display only the top three salaries for each of the departments, 
-- the employees who have such salaries and the departments they work in.
-- I need to use the 'WHERE' clause to filter the records. But If I apply the condition in this query it will not work,
-- because window functions are evaluated after the 'WHERE' clause.
-- Because of the fact that the 'WHERE' clause is executed first, 
-- The 'WHERE' clause can not reference a calculation derived from a window function because it does not exist yet.
-- To overcome this, I need to either use the query as a subquery or use the query as a CTE (Common Table Expression)
-- I prefer to use CTEs over the subqueries because it allows not only structuring queries into logical order, 
-- but also it is easier to read and maintain:
  WITH cte AS
(
SELECT d.name, e.name, e.salary,
       DENSE_RANK() OVER(PARTITION BY d.id ORDER BY e.salary DESC)
  FROM EMPLOYEE AS e
       INNER JOIN department AS d
       ON e.departmentid = d.id
)

-- To use custom names for the columns 
-- I can assign them within parentheses after the name of the CTE:
  WITH cte (department, employee, salary, salary_rank) AS
(
SELECT d.name, e.name, e.salary,
       DENSE_RANK() OVER(PARTITION BY d.id ORDER BY e.salary DESC)
  FROM employee AS e
       INNER JOIN department AS d
       ON e.departmentid = d.id
)

-- 4. Finally, I can use this CTE in the main 'SELECT' statement 
-- and apply a condition to the 'salary_rank' column to find the employees who has top salaries.
  WITH t (department, employee, salary, salary_rank) AS
(
SELECT d.name, e.name, e.salary,
       dense_rank() over(partition by d.id ORDER BY e.salary DESC)
  FROM employee AS e
       INNER JOIN department AS d
       ON e.departmentid = d.id
)
SELECT department, employee, salary
  FROM t
 WHERE salary_rank BETWEEN 1 AND 3;

-- The condition in the 'WHERE' clause is analogous to:
 WHERE salary_rank >= 1 AND salary_rank <= 3
 
-- ###
