# SQL Project - Leetcode task solution

This document provides my solution and a detailed explanation of the Leetcode task called ['185. Department Top Three Salaries'](https://leetcode.com/problems/department-top-three-salaries/description/).


## SQL Schema

There are two tables: `Employee` and `Department`:

Table: `Employee`

| Column Name                                 | Type                                |
|---------------------------------------------|-------------------------------------|
| id<br> name<br> salary<br> departmentId<br> | int<br> varchar<br> int<br> int<br> |
 
*id* is the primary key (column with unique values) for this table.
*departmentId* is a foreign key (reference column) of the ID from 
the `Department` table.
Each row of this table indicates the ID, name, and salary of an employee. 
It also contains the ID of their department.

Table: `Department`
| Column Name      | Type                 |
|------------------|----------------------|
| id<br> name<br>  | int<br> varchar<br>  |


*id* is the primary key (column with unique values) for this table. Each row of this table indicates the ID of a department and its name.

## Problem
A company's executives are interested in seeing who earns the most money in each of the company's departments. A **high earner** in a department is an employee who has a salary in the **top three unique** salaries for that department.

Write a solution to find the employees who are **high earners** in each of the departments.

Return the result table in any order.

A department name, name, and salary of an employee should be displayed.

Example output:
| Department                                      | Employee                                             | Salary                                  |
|-------------------------------------------------|------------------------------------------------------|----------------------------------------|
| IT<br> IT<br> IT<br> IT<br> Sales<br> Sales<br> | Max<br> Joe<br> Randy<br> Will<br> Henry<br> Sam<br> | 90000<br> 85000<br> 85000<br> 70000<br> 80000<br> 60000<br> |

## Solution

Let's solve the problem step by step.

### Step 1

Since I need to find the employees who are high earners in each of the departments, the `Employee` table will be the main because it lists all of the employees. The first column of the example output is the name of the department, so I need to derive these names from the `Department` table. To do this, I will join the `Department` to the `Employee` table using INNER JOIN.

The reason I use the INNER JOIN instead of LEFT JOIN is that I want to find the names of the departments employees work in. I do not want to display employees who do not work in a department (the value of the *departmentId* column is NULL). The *departmentId* is a foreign key column, thus, it could contain NULL values. 

There is no difference between what table to write first when INNER JOIN is used because it is commutative. I can specify tables in any order without changing the results. I will specify `Employee` table first because it is more logical to put in that order:
```sql
SELECT *
  FROM employee AS e
       INNER JOIN department AS d
       ON e.departmentid = d.id
```
Let's display only department name, employee name, and salary columns:
```sql
SELECT d.name, e.name, e.salary
  FROM employee AS e
       INNER JOIN department AS d
       ON e.departmentid = d.id
```

Also, It could be that an employee does not have a salary (the value of the *salary* column is NULL). I do not want to have employees who do not have salaries. I will use a condition where a *salary* column cannot be NULL:
```sql
SELECT d.name, e.name, e.salary
  FROM employee AS e
       INNER JOIN department AS d
       ON e.departmentid = d.id
 WHERE e.salary IS NOT NULL
 ```

Now I have the departments, the names of the employees, and the salaries of employees that belong to corresponding departments. All of the employees in the table have salaries and work in some departments.

In a general case, it's possible that not all departments listed in the `Department` table exist in the `Employee` table. In other words, there could be departments without employees at all. I removed such departments because the description says: 'A **high earner** in a department is an employee who has a salary in the top three unique salaries for that department'. Thus, an employee must have a department and must have a salary. If a department does not have any employees, it is impossible to find top salaries for such a department. And if an employee does not have a salary, it is impossible to evaluate it.
### Step 2
Now, I display only those departments that employees work in and the salaries of the employees. If a department has an employee, and this employee has a salary, it means this department has this salary. If I have departments and their salaries, I can find the top three salaries for a department. In this step, I will identify top salaries. 

To do this, I need to rank salaries in a way where the first, second, and third highest salaries of the department would get the '1', '2', and '3' rank respectively. If the salaries are the same, they should have the same rank. 

This can be achieved by using the `DENSE_RANK()` window function. It assigns consecutive ranks without gaps, within its partition. If values are the same, they receive the same rank. The function should be used with the ORDER BY clause to rank the values in the desired order (the highest values receive the highest ranks, or the lowest values receive the highest ranks). I am going to partition the table by the department name column because I need to rank salaries for each of the departments. Also, I need to sort the salary values in descending order because the highest salaries should receive the highest rank.

```sql
SELECT d.name, e.name, e.salary,
       DENSE_RANK() OVER(PARTITION BY d.id ORDER BY e.salary DESC)
  FROM employee AS e
       INNER JOIN department AS d
       ON e.departmentid = d.id
 WHERE e.salary IS NOT NULL
```

### Step 3
Now, the salaries are ranked for each of the departments. But I want to display only the **top three salaries** for each of the departments, the employees who have such salaries and the departments they work in. I need to use the WHERE clause to filter the records. But If I apply the condition in the query, it will not work, because window functions are evaluated after the WHERE clause. As a result, WHERE clause can not reference a calculation derived from a window function because it does not exist yet. To overcome this, I need to either use the query as a subquery or as a CTE (Common Table Expression). I prefer to use CTEs over the subqueries because it allows not only structuring queries into logical order, but also it is easier to read and maintain:
```sql
  WITH cte AS
(
SELECT d.name, e.name, e.salary,
       DENSE_RANK() OVER(PARTITION BY d.id ORDER BY e.salary DESC)
  FROM EMPLOYEE AS e
       INNER JOIN department AS d
       ON e.departmentid = d.id 
 WHERE e.salary IS NOT NULL
)
```
To use custome names for the columns I can assign them within parentheses after the name of the CTE:
```sql
  WITH cte (department, employee, salary, salary_rank) AS
(
SELECT d.name, e.name, e.salary,
       DENSE_RANK() OVER(PARTITION BY d.id ORDER BY e.salary DESC)
  FROM employee AS e
       INNER JOIN department AS d
       ON e.departmentid = d.id
 WHERE e.salary IS NOT NULL
)
```
### Step 4
Finally, I can use the CTE in the main SELECT statement and apply a condition to the *salary_rank* column to find the employees who have top salaries:
```sql
  WITH cte (department, employee, salary, salary_rank) AS
(
SELECT d.name, e.name, e.salary,
       DENSE_RANK() OVER(PARTITION BY d.id ORDER BY e.salary DESC)
  FROM employee AS e
       INNER JOIN department AS d
       ON e.departmentid = d.id
 WHERE e.salary IS NOT NULL
)
SELECT department, employee, salary
  FROM cte
 WHERE salary_rank BETWEEN 1 AND 3;
```

The condition in the WHERE can be replaced with:
```sql 
WHERE salary_rank >= 1 AND salary_rank <= 3
```
## Conclusion
This document explains one of the ways how the hard task from Leetcode called 'Department Top Three Salaries' could be solved. Even though there are many other solutions to this task, the proposed sql query is structured, easy to read and maintain. Also, the document presents the step-by-step explanation of how build this query, making it easy to understand. 
