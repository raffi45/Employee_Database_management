USE CompanyDB;
GO

-- Data Dummy untuk tbl_regions
INSERT INTO tbl_regions (region_id, region_name)
VALUES 
(1, 'Americas'),
(2, 'Europe'),
(3, 'Asia');

-- Data Dummy untuk tbl_countries
INSERT INTO tbl_countries (country_id, country_name, region_id)
VALUES 
('US', 'United States', 1),
('CA', 'Canada', 1),
('DE', 'Germany', 2),
('JP', 'Japan', 3);

-- Data Dummy untuk tbl_locations
INSERT INTO tbl_locations (location_id, street_address, postal_code, city, state_province, country_id)
VALUES 
(1, '123 Elm St', '12345', 'New York', 'NY', 'US'),
(2, '456 Oak St', '54321', 'Toronto', 'ON', 'CA'),
(3, '789 Pine St', '67890', 'Berlin', 'BE', 'DE'),
(4, '321 Maple St', '09876', 'Tokyo', 'TY', 'JP');

-- Data Dummy untuk tbl_departments
INSERT INTO tbl_departments (department_id, department_name, location_id)
VALUES 
(1, 'Sales', 1),
(2, 'Marketing', 2),
(3, 'IT', 3),
(4, 'HR', 4);

-- Data Dummy untuk tbl_jobs
INSERT INTO tbl_jobs (job_id, job_title, min_salary, max_salary)
VALUES 
(1, 'Sales Manager', 50000, 100000),
(2, 'Marketing Manager', 60000, 110000),
(3, 'IT Specialist', 70000, 120000),
(4, 'HR Specialist', 40000, 90000);

-- Data Dummy untuk tbl_employees
INSERT INTO tbl_employees (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id)
VALUES 
(1, 'raffi', 'nandyka', 'raff@example.com', '555-1234', '2020-01-01', 1, 75000, 0.10, NULL, 1),
(2, 'Jane', 'Smith', 'jane.smith@example.com', '555-5678', '2019-02-01', 2, 85000, 0.15, 1, 2),
(3, 'bukan', 'raffi', 'bkn_raffi@example.com', '555-8765', '2018-03-01', 3, 95000, 0.20, 2, 3),
(4, 'yooo', 'jihooo', 'yo jihoo@example.com', '555-4321', '2021-04-01', 4, 65000, 0.05, 3, 4);

-- Data Dummy untuk tbl_job_histories
INSERT INTO tbl_job_histories (employee_id, start_date, end_date, job_id, department_id)
VALUES 
(1, '2019-01-01', '2020-01-01', 1, 1),
(2, '2018-02-01', '2019-02-01', 2, 2),
(3, '2017-03-01', '2018-03-01', 3, 3),
(4, '2020-04-01', '2021-04-01', 4, 4);

-- Data Dummy untuk tbl_accounts
INSERT INTO tbl_accounts (account_id, username, password, employee_id)
VALUES 
(1, 'raffi', 'password1', 1),
(2, 'janesmith', 'password2', 2),
(3, 'bukan_raffi', 'password3', 3),
(4, 'yooo', 'password4', 4);

-- Data Dummy untuk tbl_roles
INSERT INTO tbl_roles (role_id, role_name)
VALUES 
(1, ' Super Admin'),
(2, 'Admin'),
(3, 'Manager'),
(4,'employee')
;

-- Data Dummy untuk tbl_account_roles
INSERT INTO tbl_account_roles (account_id, role_id)
VALUES 
(1, 1),
(2, 2),
(3, 3),
(4, 4);

-- Data Dummy untuk tbl_permissions
INSERT INTO tbl_permissions (permission_id, permission_name)
VALUES 
(1, 'View'),
(2, 'Edit'),
(3, 'Delete');

-- Data Dummy untuk tbl_role_permissions
INSERT INTO tbl_role_permissions (role_id, permission_id)
VALUES 
(1, 1),
(1, 2),
(1, 3),
(2, 1);

-- Data Dummy untuk tbl_attendance
INSERT INTO tbl_attendance (employee_id, attendance_date, check_in_time, check_out_time)
VALUES 
(1, '2023-06-01', '08:00:00', '17:00:00'),
(2, '2023-06-01', '08:30:00', '17:30:00'),
(3, '2023-06-01', '09:00:00', '18:00:00'),
(4, '2023-06-01', '08:45:00', '17:45:00');

-- Data Dummy untuk tbl_leave_requests
INSERT INTO tbl_leave_requests (employee_id, leave_type, start_date, end_date, status)
VALUES 
(1, 'Annual Leave', '2023-07-01', '2023-07-10', 'Approved'),
(2, 'Sick Leave', '2023-06-10', '2023-06-12', 'Pending'),
(3, 'Annual Leave', '2023-08-15', '2023-08-20', 'Approved'),
(4, 'Maternity Leave', '2023-09-01', '2023-12-01', 'Pending');
