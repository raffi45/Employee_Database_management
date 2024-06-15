-- Insert data dummy ke tbl_regions
INSERT INTO tbl_regions (region_name)
VALUES 
    ('Region A'),
    ('Region B'),
    ('Region C');

-- Insert data dummy ke tbl_countries
INSERT INTO tbl_countries (country_name, region_id)
VALUES 
    ('Country 1', 1),
    ('Country 2', 1),
    ('Country 3', 2),
    ('Country 4', 2),
    ('Country 5', 3);

-- Insert data dummy ke tbl_locations
INSERT INTO tbl_locations (street_address, postal_code, city, state_province, country_id)
VALUES 
    ('123 Main St', '12345', 'City A', 'State A', 1),
    ('456 Elm St', '23456', 'City B', 'State B', 2),
    ('789 Oak St', '34567', 'City C', 'State C', 3);

-- Insert data dummy ke tbl_departments
INSERT INTO tbl_departments (department_name, location_id)
VALUES 
    ('Department 1', 1),
    ('Department 2', 2),
    ('Department 3', 3),
	('Department 4', 3);

-- Insert data dummy ke tbl_jobs
INSERT INTO tbl_jobs (job_title, min_salary, max_salary)
VALUES 
    ('Job 1', 30000.00, 50000.00),
    ('Job 2', 40000.00, 60000.00),
    ('Job 3', 35000.00, 55000.00),
	('Job 4', 30000.00, 50000.00);



-- Insert data dummy ke tbl_employees
INSERT INTO tbl_employees (first_name, last_name, gender, email, phone_number, hire_date, job_id, salary, manager_id, department_id)
VALUES 
( 'raffi', 'nandyka','male', 'raff@example.com', '555-1234', '2020-01-01', 1, 75000, NULL, 1),
( 'Jane', 'Smith','male' ,'jane.smith@example.com', '555-5678', '2019-02-01', 2, 85000,  NULL, 2),
( 'bukan', 'raffi','male', 'bkn_raffi@example.com', '555-8765', '2018-03-01', 3, 95000, NULL, 3),
( 'yooo', 'jihooo', 'male', 'yo jihoo@example.com', '555-4321', '2021-04-01', 4, 65000, NULL, 4);



-- Insert data dummy ke tbl_accounts
INSERT INTO tbl_accounts (username, password, employee_id)
VALUES 
 ( 'raffi', 'password1', 1),
( 'janesmith', 'password2',2),
( 'bukan_raffi', 'password3', 3),
( 'yooo', 'password4', 4);


-- Insert data dummy ke tbl_roles
INSERT INTO tbl_roles (role_name)
VALUES 
( ' Super Admin'),
( 'Admin'),
( 'Manager'),
('employee');


-- Insert data dummy ke tbl_account_roles
INSERT INTO tbl_account_roles (account_id, role_id)
VALUES 
(1, 1),
(2, 2),
(3, 3),
(4, 4);

-- Insert data dummy ke tbl_permissions
INSERT INTO tbl_permissions (permission_name)
VALUES 
    ('View'),
    ('Edit'),
    ('Delete');

-- Insert data dummy ke tbl_role_permissions
INSERT INTO tbl_role_permissions (role_id, permission_id)
VALUES 
(1, 1),
(1, 2),
(1, 3),
(2, 1),
(2, 2),
(2, 3),
(3, 1),
(3, 2),
(4, 1),
(4, 2);

-- Insert data dummy ke tbl_attendance
INSERT INTO tbl_attendance (employee_id, attendance_date, check_in_time, check_out_time)
VALUES 
    (1, '2023-01-01', '08:00:00', '17:00:00'),
    (2, '2023-02-01', '08:30:00', '16:30:00'),
    (3, '2023-03-01', '09:00:00', '18:00:00');

-- Insert data dummy ke tbl_leave_requests
INSERT INTO tbl_leave_requests (employee_id, leave_type, start_date, end_date, status)
VALUES 
    (1, 'Annual Leave', '2023-04-01', '2023-04-05', 'Pending'),
    (2, 'Sick Leave', '2023-05-01', '2023-05-02', 'Approved'),
    (3, 'Maternity Leave', '2023-06-01', '2023-06-30', 'Pending');
