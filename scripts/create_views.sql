USE roblox_workforce_db;

CREATE OR REPLACE VIEW vw_workforce_composition AS
SELECT
    d.department_name,
    e.Position,
    e.Gender,
    COUNT(*) AS headcount,
    ROUND(AVG(e.Age),1) AS avg_age
FROM employee e
JOIN department d ON e.Department Code = d.department_code
GROUP BY d.department_name, e.Position, e.Gender;

CREATE OR REPLACE VIEW vw_education_vs_compensation AS
SELECT
    d.department_name,
    edu.Education Level,
    edu.Field of Study,
    COUNT(*) AS employee_count,
    ROUND(AVG(f.Basic Salary + f.Allowances), 2) AS avg_total_compensation
FROM employee e
JOIN department d ON e.Department Code = d.department_code
JOIN education edu ON e.EmployeeID = edu.employee_id
JOIN finance f ON e.EmployeeID = f.StaffID
GROUP BY d.department_name, edu.Education Level, edu.Field of Study;

CREATE OR REPLACE VIEW vw_compensation_by_department AS
SELECT
    d.department_name,
    COUNT(*) AS headcount,
    ROUND(AVG(f.Basic Salary), 2) AS avg_basic_salary,
    ROUND(AVG(f.Allowances), 2) AS avg_allowances,
    ROUND(SUM(f.Basic Salary + f.Allowances), 2) AS total_compensation_cost
FROM employee e
JOIN department d ON e.Department Code = d.department_code
JOIN finance f ON e.EmployeeID = f.StaffID
GROUP BY d.department_name;

CREATE OR REPLACE VIEW vw_department_performance_summary AS
SELECT
    Department AS department_name,
    Year,
    Average_Performance_Score,
    Total_Revenue_Generated,
    Total_Cost,
    ROUND(Total_Cost / NULLIF(Total_Revenue_Generated, 0), 3) AS cost_to_revenue_ratio,
    Training_Hours_Completed
FROM department_performance;

CREATE OR REPLACE VIEW vw_health_risk AS
SELECT
    d.department_name,
    h.Insurance_status,
    h.Insurance_plan_type,
    h.Medical_leave_eligible,
    COUNT(*) AS employee_count,
    ROUND(AVG(h.Medical_leave_balance), 1) AS avg_leave_balance,
    ROUND(AVG(ep.Performance_Score), 2) AS avg_performance_score
FROM employee e
JOIN department d ON e.Department Code = d.department_code
JOIN health h ON e.EmployeeID = h.Employee ID
LEFT JOIN employee_performance ep
    ON e.EmployeeID = ep.EmployeeID
    AND ep.Year = (SELECT MAX(Year) FROM employee_performance)
GROUP BY d.department_name, h.Insurance_status, h.Insurance_plan_type, h.Medical_leave_eligible;
