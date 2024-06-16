
CREATE PROCEDURE dbo.sp_edit_employee_mng
    @EmployeeId INT, 
    @FirstName NVARCHAR(100) = NULL, 
    @LastName NVARCHAR(100) = NULL, 
    @Gender NVARCHAR(10) = NULL,
    @Email NVARCHAR(100) = NULL,
    @PhoneNumber NVARCHAR(20) = NULL, 
    @HireDate DATE = NULL,
    @JobId INT = NULL, 
    @Salary DECIMAL(10, 2) = NULL, 
    @ManagerId INT = NULL,
    @DepartmentId INT = NULL,
    @EditingEmployeeId INT 
AS
BEGIN
    DECLARE @RoleCheck NVARCHAR(MAX); 
    DECLARE @OldJobId INT; 

    -- Periksa apakah karyawan yang melakukan edit memiliki peran yang tepat
    SET @RoleCheck = dbo.fn_check_employee_roles(@EditingEmployeeId);
    
    IF CHARINDEX('3', @RoleCheck) = 0
    BEGIN
        -- Jika tidak memiliki peran yang sesuai, munculkan error
        RAISERROR('Anda tidak memiliki izin untuk mengedit data karyawan.', 16, 1);
        RETURN;
    END

    -- Periksa apakah karyawan yang akan diedit ada di dalam tabel
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_employees WHERE employee_id = @EmployeeId)
    BEGIN
        -- Jika karyawan tidak ditemukan, munculkan error
        RAISERROR('Karyawan tidak ditemukan.', 16, 1);
        RETURN;
    END

   
    SELECT @OldJobId = job_id FROM dbo.tbl_employees WHERE employee_id = @EmployeeId;

    -- Update detail karyawan
    UPDATE dbo.tbl_employees
    SET 
        first_name = COALESCE(@FirstName, first_name), 
        last_name = COALESCE(@LastName, last_name), 
        gender = COALESCE(@Gender, gender), 
        email = COALESCE(@Email, email), 
        phone_number = COALESCE(@PhoneNumber, phone_number), 
        hire_date = COALESCE(@HireDate, hire_date), 
        job_id = COALESCE(@JobId, job_id), 
        salary = COALESCE(@Salary, salary),
        manager_id = COALESCE(@ManagerId, manager_id), 
        department_id = COALESCE(@DepartmentId, department_id)
    WHERE 
        employee_id = @EmployeeId; 

    -- Jika ID pekerjaan berubah, masukkan sejarah pekerjaan (trigger akan menangani ini)
    IF @JobId IS NOT NULL AND @JobId <> @OldJobId
    BEGIN
        -- Masukkan sejarah pekerjaan untuk pekerjaan lama dengan status "Hand Over"
        INSERT INTO dbo.tbl_job_histories (employee_id, start_date, end_date, job_id, department_id, status)
        VALUES (@EmployeeId, GETDATE(), GETDATE(), @OldJobId, (SELECT department_id FROM dbo.tbl_employees WHERE employee_id = @EmployeeId), 'Hand Over');

        -- Masukkan sejarah pekerjaan untuk pekerjaan baru dengan status "Active"
        INSERT INTO dbo.tbl_job_histories (employee_id, start_date, end_date, job_id, department_id, status)
        VALUES (@EmployeeId, GETDATE(), NULL, @JobId, @DepartmentId, 'Active');
    END

    -- Berikan pesan bahwa data karyawan berhasil diperbarui
    PRINT 'Data karyawan berhasil diperbarui.';
END;
GO
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE dbo.sp_edit_employee_profile
    @EmployeeId INT,           
    @FirstName NVARCHAR(100) = NULL,    
    @LastName NVARCHAR(100) = NULL,     
    @Gender NVARCHAR(10) = NULL,        
    @Email NVARCHAR(100) = NULL,       
    @PhoneNumber NVARCHAR(20) = NULL, 
    @HireDate DATE = NULL,             
    @JobId INT = NULL,                 
    @Salary DECIMAL(10, 2) = NULL,       
    @ManagerId INT = NULL,              -
    @DepartmentId INT = NULL,         
	@AddingEmployeeId INT
AS
BEGIN
    -- Deklarasi variabel untuk menyimpan hasil pengecekan peran
    DECLARE @RoleCheck NVARCHAR(MAX);
	DECLARE @IsValidUser BIT;

	 SET @IsValidUser = dbo.fn_validate_user_identity(@AddingEmployeeId, @EmployeeId);

		IF @IsValidUser = 0
		BEGIN
			RAISERROR('Anda hanya dapat menambahkan data untuk diri sendiri.', 16, 1);
			RETURN;
		END

    -- Update data karyawan di tabel tbl_employees
    UPDATE dbo.tbl_employees
    SET 
        first_name = COALESCE(@FirstName, first_name), 
        last_name = COALESCE(@LastName, last_name), 
        gender = COALESCE(@Gender, gender), 
        email = COALESCE(@Email, email), 
        phone_number = COALESCE(@PhoneNumber, phone_number), 
        hire_date = COALESCE(@HireDate, hire_date), 
        job_id = COALESCE(@JobId, job_id), 
        salary = COALESCE(@Salary, salary),
        manager_id = COALESCE(@ManagerId, manager_id), 
        department_id = COALESCE(@DepartmentId, department_id)
    WHERE 
        employee_id = @EmployeeId;

    -- Berikan pesan bahwa data karyawan berhasil diupdate
    PRINT 'Data karyawan berhasil diupdate.';
END;
GO


---------------------------------------------------------------------------

CREATE PROCEDURE sp_Change_password
    @username NVARCHAR(100),
    @new_password NVARCHAR(100),
    @confirm_password NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IsValidPassword BIT;
    DECLARE @otp_code NVARCHAR(10);
    DECLARE @expiry_datetime DATETIME;

    -- Validasi password policy
    EXEC @IsValidPassword = dbo.func_password_policy @new_password;

    -- Generate OTP and retrieve OTP code and expiry datetime
    EXEC dbo.sp_generate_otp @username, @otp_length = 6, @otp_code = @otp_code OUTPUT, @expiry_datetime = @expiry_datetime OUTPUT;

    -- Validasi OTP
    DECLARE @IsValidOTP BIT;
    EXEC @IsValidOTP = dbo.func_validate_otp @username, @otp_code;

    -- Check validasi email, password, dan OTP
    IF @IsValidPassword = 1 AND @IsValidOTP = 1
    BEGIN
        -- Update password
        UPDATE tbl_accounts
        SET password = @new_password
        WHERE username = @username;

        SELECT 'Password reset successfully.' AS message;
    END
    ELSE
    BEGIN
        SELECT 'Password reset failed. Please check input data.' AS message;
    END;
END;

------------------------------------------------------------------

CREATE PROCEDURE sp_leave_approval
    @leave_request_id INT,
    @approval_status NVARCHAR(20),  -- Status to set (e.g., 'Approved' or 'Rejected')
    @approver_employee_id INT  
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if the approver has the necessary role (role_id 1 or 2)
    DECLARE @RoleCheck NVARCHAR(MAX);
    SET @RoleCheck = dbo.fn_check_employee_roles(@approver_employee_id);

    IF CHARINDEX('3', @RoleCheck) =0
    BEGIN
        RAISERROR('You do not have permission to approve/reject leave requests.', 16, 1);
        RETURN;
    END

    -- Check if the leave request exists and is pending
    IF NOT EXISTS (SELECT 1 FROM tbl_leave_requests WHERE leave_request_id = @leave_request_id AND status = 'Pending')
    BEGIN
        RAISERROR('Leave request not found or already processed.', 16, 1);
        RETURN;
    END

    -- Update leave request status
    UPDATE tbl_leave_requests
    SET status = @approval_status
    WHERE leave_request_id = @leave_request_id;

    -- Output message
    IF @@ROWCOUNT > 0
    BEGIN
        SELECT 'Leave request ' + CASE WHEN @approval_status = 'Approved' THEN 'approved.' ELSE 'rejected.' END AS message;
    END
    ELSE
    BEGIN
        SELECT 'Leave request approval/rejection failed. Please check input data.' AS message;
    END;
END;

---------------------------------------------------------------------------------------------------------------


