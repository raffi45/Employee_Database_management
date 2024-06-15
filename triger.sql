CREATE TRIGGER tr_insert_employee
ON tbl_employees
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EmployeeId INT;

    -- Ambil employee_id dari data yang baru dimasukkan
    SELECT @EmployeeId = employee_id
    FROM inserted;

    -- Insert ke tabel tbl_job_histories dengan status "Active"
    INSERT INTO tbl_job_histories (employee_id, start_date, end_date, job_id, department_id)
    VALUES (@EmployeeId, GETDATE(), NULL, (SELECT job_id FROM inserted), (SELECT department_id FROM inserted));
END;

-----------------------------------------------------

CREATE TRIGGER tr_update_employee_job
ON tbl_employees
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EmployeeId INT;
    DECLARE @OldJobId INT;
    DECLARE @NewJobId INT;

    -- Ambil data lama dan baru dari kolom job
    SELECT 
        @EmployeeId = i.employee_id,
        @OldJobId = d.job_id,
        @NewJobId = i.job_id
    FROM 
        inserted i
    INNER JOIN 
        deleted d ON i.employee_id = d.employee_id;

    -- Insert ke tabel tbl_job_histories dengan status "Hand Over"
    INSERT INTO tbl_job_histories (employee_id, start_date, end_date, job_id, department_id)
    VALUES (@EmployeeId, GETDATE(), NULL, @OldJobId, (SELECT department_id FROM inserted));

    -- Insert lagi untuk status "Active" dengan job baru jika ada perubahan
    IF @OldJobId <> @NewJobId
    BEGIN
        INSERT INTO tbl_job_histories (employee_id, start_date, end_date, job_id, department_id)
        VALUES (@EmployeeId, GETDATE(), NULL, @NewJobId, (SELECT department_id FROM inserted));
    END;
END;


---------------------------------------------------------------------------------
CREATE TRIGGER tr_update_department
ON tbl_employees
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Update data di tbl_job_histories jika terjadi perubahan pada department_id
    UPDATE jh
    SET jh.department_id = i.department_id
    FROM tbl_job_histories jh
    INNER JOIN inserted i ON jh.employee_id = i.employee_id
    WHERE jh.end_date IS NULL; -- Hanya update jika status masih "Active"
END;



-------------------------------------
CREATE TRIGGER tr_delete_department
ON tbl_departments
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DeletedDepartmentId INT;

    -- Ambil department_id dari data yang dihapus
    SELECT @DeletedDepartmentId = department_id
    FROM deleted;

    -- Update data di tbl_employees
    UPDATE tbl_employees
    SET department_id = NULL
    WHERE department_id = @DeletedDepartmentId;

    -- Update data di tbl_job_histories
    UPDATE tbl_job_histories
    SET department_id = NULL
    WHERE department_id = @DeletedDepartmentId;

    
END;

-------------------------------------------------
CREATE TRIGGER tr_delete_job
ON tbl_jobs
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DeletedJobId INT;

    -- Ambil job_id dari data yang dihapus
    SELECT @DeletedJobId = job_id
    FROM deleted;

    -- Update data di tbl_employees
    UPDATE tbl_employees
    SET job_id = NULL
    WHERE job_id = @DeletedJobId;

    -- Update data di tbl_job_histories
    UPDATE tbl_job_histories
    SET job_id = NULL
    WHERE job_id = @DeletedJobId;
END;

--------------------------------------
CREATE TRIGGER tr_delete_country
ON tbl_countries
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DeletedCountryId CHAR(2);

    -- Ambil country_id dari data yang dihapus
    SELECT @DeletedCountryId = country_id
    FROM deleted;

    -- Update data di tbl_locations
    UPDATE tbl_locations
    SET country_id = NULL
    WHERE country_id = @DeletedCountryId;

    -- Update data di tbl_regions
    UPDATE tbl_regions
    SET region_id = NULL
    WHERE region_id IN (
        SELECT r.region_id
        FROM tbl_regions r
        INNER JOIN tbl_countries c ON r.region_id = c.region_id
        WHERE c.country_id = @DeletedCountryId
    );
END;


-----------------------------------------------------------
CREATE TRIGGER tr_delete_role
ON tbl_roles
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DeletedRoleId INT;

    -- Ambil role_id dari data yang dihapus
    SELECT @DeletedRoleId = role_id
    FROM deleted;

    -- Update data di tbl_account_roles
    UPDATE tbl_account_roles
    SET role_id = NULL
    WHERE role_id = @DeletedRoleId;

    -- Update data di tbl_role_permissions
    DELETE FROM tbl_role_permissions
    WHERE role_id = @DeletedRoleId;

    -- Update data di tbl_permissions jika tidak ada role yang memilikinya
    UPDATE tbl_permissions
    SET permission_id = NULL
    WHERE permission_id NOT IN (
        SELECT rp.permission_id
        FROM tbl_role_permissions rp
    );
END;


---------
CREATE TRIGGER tr_status_leave_history
ON tbl_leave_requests
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LeaveId INT;
    DECLARE @OldStatus NVARCHAR(100);
    DECLARE @NewStatus NVARCHAR(100);
    DECLARE @StartDate DATE;
    DECLARE @EndDate DATE;
    DECLARE @EmployeeId INT;

    -- Ambil data dari tabel inserted (data yang di-update)
    SELECT 
        @LeaveId = i.leave_request_id,
        @OldStatus = d.status,  -- Status lama
        @NewStatus = i.status,  -- Status baru
        @StartDate = i.start_date,  -- Tanggal mulai cuti
        @EndDate = i.end_date,  -- Tanggal akhir cuti
        @EmployeeId = i.employee_id  -- ID karyawan
    FROM 
        inserted i
    INNER JOIN 
        deleted d ON i.leave_request_id = d.leave_request_id;

    -- Cek apakah status baru adalah "Approved" dan status lama bukan "Approved"
    IF @NewStatus = 'Approved' AND @OldStatus <> 'Approved'
    BEGIN
        -- Insert ke tabel tbl_job_histories dengan status "Hand Over"
        INSERT INTO tbl_job_histories (employee_id, start_date, end_date, job_id, department_id)
        SELECT 
            @EmployeeId,
            @StartDate,
            NULL,  -- Tanggal akhir kosong karena status "Hand Over" masih berlaku
            e.job_id,
            e.department_id
        FROM 
            tbl_employees e
        WHERE 
            e.employee_id = @EmployeeId;
    END
    ELSE IF @OldStatus = 'Approved' AND @NewStatus <> 'Approved'
    BEGIN
        -- Update catatan "Hand Over" menjadi "Active" setelah cuti selesai
        UPDATE tbl_job_histories
        SET end_date = @EndDate,  -- Tanggal akhir cuti
            status = 'Active'
        WHERE 
            employee_id = @EmployeeId
            AND end_date IS NULL;  -- Memastikan hanya catatan "Hand Over" yang masih aktif yang diperbarui
    END;
END;

-----------------------------------
CREATE TRIGGER trg_update_otp_status
ON tbl_accounts
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(otp)  -- Cek apakah kolom otp diupdate
    BEGIN
        UPDATE tbl_accounts
        SET is_expire = 1,  -- Set is_expire menjadi 1 (true)
            is_used_datetime = GETDATE()  -- Set is_used_datetime menjadi waktu saat ini
        FROM tbl_accounts a
        INNER JOIN inserted i ON a.username = i.username
        WHERE i.otp IS NOT NULL;  -- Hanya lakukan update jika otp tidak NULL (sudah digunakan)
    END
END;

-------------------------------------------------------------------------

CREATE TRIGGER trg_after_insert_employee
ON dbo.tbl_employees
AFTER INSERT
AS
BEGIN
    -- Insert into tbl_accounts if not exists
    INSERT INTO dbo.tbl_accounts (username, password, employee_id, otp, is_expire, is_used_datetime, otp_expiry_datetime)
    SELECT
        CONCAT(NEWID(), '@company.com'), -- Assuming you want to auto-generate a username
        'default_password',             -- Set a default password, should be changed
        i.employee_id,
        NULL,                           -- Assuming no OTP at creation
        0,                              -- Assuming the OTP is not expired
        NULL,                           -- Assuming no datetime of OTP usage
        NULL                            -- Assuming no OTP expiry datetime
    FROM
        inserted i
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.tbl_accounts a
        WHERE a.employee_id = i.employee_id
    );

    -- Insert the employee role into tbl_account_roles
    INSERT INTO dbo.tbl_account_roles (account_id, role_id)
    SELECT 
        a.account_id, 4 -- Assuming the role_id for 'employee' is 4
    FROM 
        dbo.tbl_accounts a
    JOIN 
        inserted i ON a.employee_id = i.employee_id;
END;
GO


