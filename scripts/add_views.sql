USE roblox_workforce_db;

-- VIEW 6: Education vs Job Placement Quality
CREATE OR REPLACE VIEW vw_education_placement_quality AS
SELECT 
    e.EmployeeID,
    CONCAT(e.First Name, ' ', e.Last Name) AS employee_name,
    d.department_name,
    e.Position,
    edu.Education Level,
    edu.Field of Study,
    CASE 
        WHEN e.Position LIKE '%Engineer%' AND edu.Field of Study IN ('Computer Science', 'Engineering', 'Information Technology') 
            THEN 'Good Match'
        WHEN e.Position LIKE '%Finance%' AND edu.Field of Study IN ('Finance', 'Accounting', 'Economics')
            THEN 'Good Match'
        WHEN e.Position LIKE '%HR%' AND edu.Field of Study IN ('Human Resources', 'Psychology')
            THEN 'Good Match'
        WHEN e.Position LIKE '%Manager%' AND edu.Education Level IN ('Master''s', 'MBA')
            THEN 'Good Match'
        ELSE 'Review Needed'
    END AS placement_quality,
    ep.Performance_Score
FROM employee e
JOIN department d ON e.Department Code = d.department_code
JOIN education edu ON e.EmployeeID = edu.employee_id
LEFT JOIN employee_performance ep ON e.EmployeeID = ep.EmployeeID 
    AND ep.Year = (SELECT MAX(Year) FROM employee_performance);

-- VIEW 7: Compensation Effectiveness
CREATE OR REPLACE VIEW vw_compensation_effectiveness AS
SELECT 
    d.department_name,
    COUNT(e.EmployeeID) AS headcount,
    ROUND(AVG(f.Basic Salary + f.Allowances), 0) AS avg_compensation,
    ROUND(AVG(ep.Performance_Score), 2) AS avg_performance,
    ROUND((AVG(ep.Performance_Score) / (AVG(f.Basic Salary + f.Allowances) / 10000)), 2) AS performance_per_10k,
    RANK() OVER (ORDER BY (AVG(ep.Performance_Score) / (AVG(f.Basic Salary + f.Allowances) / 10000)) DESC) AS roi_rank
FROM employee e
JOIN department d ON e.Department Code = d.department_code
JOIN finance f ON e.EmployeeID = f.StaffID
JOIN employee_performance ep ON e.EmployeeID = ep.EmployeeID
WHERE ep.Year = (SELECT MAX(Year) FROM employee_performance)
GROUP BY d.department_name
HAVING headcount > 10;

-- VIEW 8: Automated Risk Alerts
CREATE OR REPLACE VIEW vw_risk_alerts AS
SELECT 
    department_name,
    'HIGH INSURANCE RISK' AS risk_type,
    CONCAT(ROUND(100 - (insurance_covered / total_employees * 100), 1), '% uninsured') AS risk_description,
    'Immediate' AS priority
FROM (
    SELECT 
        d.department_name,
        COUNT(*) AS total_employees,
        SUM(CASE WHEN h.Insurance_status = 'Covered' THEN 1 ELSE 0 END) AS insurance_covered
    FROM employee e
    JOIN department d ON e.Department Code = d.department_code
    JOIN health h ON e.EmployeeID = h.Employee ID
    GROUP BY d.department_name
) t
WHERE (insurance_covered / total_employees * 100) < 70

UNION

SELECT 
    department_name,
    'HIGH LEAVE BALANCE' AS risk_type,
    CONCAT('Avg ', ROUND(avg_leave, 1), ' days - exceeds 15-day threshold') AS risk_description,
    'High' AS priority
FROM (
    SELECT 
        d.department_name,
        AVG(h.Medical_leave_balance) AS avg_leave
    FROM employee e
    JOIN department d ON e.Department Code = d.department_code
    JOIN health h ON e.EmployeeID = h.Employee ID
    GROUP BY d.department_name
) t
WHERE avg_leave > 15

UNION

SELECT 
    department_name,
    'POOR PERFORMANCE' AS risk_type,
    CONCAT('Avg score ', ROUND(avg_perf, 2), ' - below 7.0 threshold') AS risk_description,
    'High' AS priority
FROM (
    SELECT 
        d.department_name,
        AVG(ep.Performance_Score) AS avg_perf
    FROM employee e
    JOIN department d ON e.Department Code = d.department_code
    JOIN employee_performance ep ON e.EmployeeID = ep.EmployeeID
    WHERE ep.Year = (SELECT MAX(Year) FROM employee_performance)
    GROUP BY d.department_name
) t
WHERE avg_perf < 7.0;
