CREATE DATABASE CompanyDB;
GO

USE CompanyDB;
GO

CREATE TABLE tbl_regions (
    region_id INT PRIMARY KEY,
    region_name NVARCHAR(100)
);

CREATE TABLE tbl_countries (
    country_id CHAR(2) PRIMARY KEY,
    country_name NVARCHAR(100),
    region_id INT,
    FOREIGN KEY (region_id) REFERENCES tbl_regions(region_id)
);

CREATE TABLE tbl_locations (
    location_id INT PRIMARY KEY,
    street_address NVARCHAR(100),
    postal_code NVARCHAR(20),
    city NVARCHAR(100),
    state_province NVARCHAR(100),
    country_id CHAR(2),
    FOREIGN KEY (country_id) REFERENCES tbl_countries(country_id)
);

CREATE TABLE tbl_departments (
    department_id INT PRIMARY KEY,
    department_name NVARCHAR(100),
    location_id INT,
    FOREIGN KEY (location_id) REFERENCES tbl_locations(location_id)
);

CREATE TABLE tbl_jobs (
    job_id INT PRIMARY KEY,
    job_title NVARCHAR(100),
    min_salary DECIMAL(10, 2),
    max_salary DECIMAL(10, 2)
);

CREATE TABLE tbl_employees (
    employee_id INT PRIMARY KEY,
    first_name NVARCHAR(100),
    last_name NVARCHAR(100),
	gender NVARCHAR(10),
    email NVARCHAR(100),
    phone_number NVARCHAR(20),
    hire_date DATE,
    job_id INT,
    salary DECIMAL(10, 2),
    manager_id INT,
    department_id INT,
    FOREIGN KEY (job_id) REFERENCES tbl_jobs(job_id),
    FOREIGN KEY (manager_id) REFERENCES tbl_employees(employee_id),
    FOREIGN KEY (department_id) REFERENCES tbl_departments(department_id)
);

ALTER TABLE tbl_employees
ADD 
    gender NVARCHAR(10);

ALTER TABLE tbl_job_histories
ADD 
    status NVARCHAR(10);

ALTER TABLE tbl_employees
DROP COLUMN status ;
    

CREATE TABLE tbl_job_histories (
    employee_id INT,
    start_date DATE,
    end_date DATE,
    job_id INT,
	status NVARCHAR(10),
    department_id INT,
    PRIMARY KEY (employee_id, start_date),
    FOREIGN KEY (employee_id) REFERENCES tbl_employees(employee_id),
    FOREIGN KEY (job_id) REFERENCES tbl_jobs(job_id),
    FOREIGN KEY (department_id) REFERENCES tbl_departments(department_id)
);

CREATE TABLE tbl_accounts (
    account_id INT PRIMARY KEY,
    username NVARCHAR(100),
    password NVARCHAR(100),
    employee_id INT,
	otp INT,
    is_expire BIT,
    is_used_datetime DATETIME;
    FOREIGN KEY (employee_id) REFERENCES tbl_employees(employee_id)
);

ALTER TABLE tbl_accounts
ADD 
   otp_expiry_datetime DATETIME;


CREATE TABLE tbl_roles (
    role_id INT PRIMARY KEY,
    role_name NVARCHAR(100)
);

CREATE TABLE tbl_account_roles (
    account_id INT,
    role_id INT,
    PRIMARY KEY (account_id, role_id),
    FOREIGN KEY (account_id) REFERENCES tbl_accounts(account_id),
    FOREIGN KEY (role_id) REFERENCES tbl_roles(role_id)
);

CREATE TABLE tbl_permissions (
    permission_id INT PRIMARY KEY,
    permission_name NVARCHAR(100)
);

CREATE TABLE tbl_role_permissions (
    role_id INT,
    permission_id INT,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES tbl_roles(role_id),
    FOREIGN KEY (permission_id) REFERENCES tbl_permissions(permission_id)
);

-- Tabel Absensi
CREATE TABLE tbl_attendance (
    attendance_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT,
    attendance_date DATE,
    check_in_time TIME,
    check_out_time TIME,
    FOREIGN KEY (employee_id) REFERENCES tbl_employees(employee_id)
);

-- Tabel Pengajuan Cuti
CREATE TABLE tbl_leave_requests (
    leave_request_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT,
    leave_type NVARCHAR(50),
    start_date DATE,
    end_date DATE,
    status NVARCHAR(20),
    FOREIGN KEY (employee_id) REFERENCES tbl_employees(employee_id)
);