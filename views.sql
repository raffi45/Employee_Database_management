CREATE VIEW vw_employee_details
AS
SELECT
    e.employee_id AS id,
    a.username,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    e.gender,
    e.email,
    e.hire_date,
    e.salary,
    e.manager_id,
    CONCAT(m.first_name, ' ', m.last_name) AS manager_name,
    j.job_title AS job,
    d.department_name AS department,
    r.role_name AS role,
    CONCAT(l.city, ', ', l.state_province, ', ', c.country_name) AS location,
    CASE
        WHEN e.employee_id IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS status
FROM
    tbl_employees e
    LEFT JOIN tbl_accounts a ON e.employee_id = a.employee_id
    LEFT JOIN tbl_employees m ON e.manager_id = m.employee_id
    LEFT JOIN tbl_jobs j ON e.job_id = j.job_id
    LEFT JOIN tbl_departments d ON e.department_id = d.department_id
    LEFT JOIN tbl_locations l ON e.department_id = l.location_id
    LEFT JOIN tbl_countries c ON l.country_id = c.country_id
    LEFT JOIN tbl_account_roles ar ON a.account_id = ar.account_id
    LEFT JOIN tbl_roles r ON ar.role_id = r.role_id;
GO

----------------------------------------------

CREATE VIEW vw_attendance
AS
SELECT
    e.employee_id AS id,
    a.username,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    j.job_title AS job,
    CASE
        WHEN a.employee_id IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS status,
    CASE
        WHEN at.attendance_date = CAST(GETDATE() AS DATE) THEN 'Present'
        ELSE 'Absent'
    END AS attendance
FROM
    tbl_employees e
    LEFT JOIN tbl_accounts a ON e.employee_id = a.employee_id
    LEFT JOIN tbl_jobs j ON e.job_id = j.job_id
    LEFT JOIN tbl_attendance at ON e.employee_id = at.employee_id;
GO
--------------------------------------

CREATE VIEW vw_leave_application_detail
AS
SELECT
    e.employee_id AS id,
    a.username,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    j.job_title AS job,
    la.start_date AS start_date_of_leave,
    la.end_date AS end_date_of_leave,
    la.status
FROM
    tbl_employees e
    LEFT JOIN tbl_accounts a ON e.employee_id = a.employee_id
    LEFT JOIN tbl_jobs j ON e.job_id = j.job_id
    LEFT JOIN tbl_leave_requests la ON e.employee_id = la.employee_id;
GO
------------------------------------------------------

CREATE VIEW vw_leave_approval_detail
AS
SELECT
    e.employee_id AS id,
    a.username,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    j.job_title AS job,
    la.start_date AS start_date_of_leave,
    la.end_date AS end_date_of_leave,
    'Pending' AS status
   
FROM
    tbl_leave_requests la
    INNER JOIN tbl_employees e ON la.employee_id = e.employee_id
    INNER JOIN tbl_accounts a ON e.employee_id = a.employee_id
    INNER JOIN tbl_jobs j ON e.job_id = j.job_id
WHERE
    la.status = 'Pending';
GO

-------------------------------------------------------

CREATE VIEW vw_leave_approval_status
AS
SELECT
    e.employee_id AS id,
    a.username,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    la.status
FROM
    tbl_employees e
    INNER JOIN tbl_accounts a ON e.employee_id = a.employee_id
    LEFT JOIN tbl_leave_requests la ON e.employee_id = la.employee_id;
GO
