USE roblox_workforce_db;

ALTER TABLE department ADD PRIMARY KEY (department_code);
ALTER TABLE employee ADD PRIMARY KEY (EmployeeID);
ALTER TABLE education ADD PRIMARY KEY (employee_id);
ALTER TABLE health ADD PRIMARY KEY (Employee ID);
ALTER TABLE finance ADD PRIMARY KEY (StaffID);
ALTER TABLE employee_performance ADD PRIMARY KEY (EmployeeID, Year);
ALTER TABLE department_performance ADD PRIMARY KEY (DepartmentId);

ALTER TABLE department ADD CONSTRAINT uq_department_name UNIQUE (department_name);

ALTER TABLE employee
  ADD CONSTRAINT fk_employee_department
  FOREIGN KEY (Department Code) REFERENCES department(department_code);

ALTER TABLE education
  ADD CONSTRAINT fk_education_employee
  FOREIGN KEY (employee_id) REFERENCES employee(EmployeeID);

ALTER TABLE health
  ADD CONSTRAINT fk_health_employee
  FOREIGN KEY (Employee ID) REFERENCES employee(EmployeeID);

ALTER TABLE finance
  ADD CONSTRAINT fk_finance_employee
  FOREIGN KEY (StaffID) REFERENCES employee(EmployeeID);

ALTER TABLE employee_performance
  ADD CONSTRAINT fk_empperf_employee
  FOREIGN KEY (EmployeeID) REFERENCES employee(EmployeeID);

ALTER TABLE department_performance
  ADD CONSTRAINT fk_deptperf_department
  FOREIGN KEY (Department) REFERENCES department(department_name);
