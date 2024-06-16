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

---------------------------------------------------------------

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
-----------------------------------------------------------------------
CREATE PROCEDURE dbo.sp_add_attendance
    @EmployeeId INT, 
    @AttendanceDate DATE, 
    @CheckInTime TIME,
    @CheckOutTime TIME, 
    @AddingEmployeeId INT
AS
BEGIN
    -- Deklarasi variabel untuk menyimpan hasil pengecekan peran dan validasi
    DECLARE @IsValidUser BIT;

 
    -- Validasi bahwa pengguna yang menambahkan adalah pengguna yang sama dengan yang ingin ditambahkan
    SET @IsValidUser = dbo.fn_validate_user_identity(@AddingEmployeeId, @EmployeeId);

    IF @IsValidUser = 0
    BEGIN
        RAISERROR('Anda hanya dapat menambahkan data untuk diri sendiri.', 16, 1);
        RETURN;
    END


    INSERT INTO dbo.tbl_attendance (employee_id, attendance_date, check_in_time, check_out_time)
    VALUES (@EmployeeId, @AttendanceDate, @CheckInTime, @CheckOutTime);


    PRINT 'Data attendance berhasil ditambahkan.';
END;
GO
---------------------------------------------------------------------------------
CREATE PROCEDURE dbo.sp_add_leave_request
    @EmployeeId INT,
    @LeaveType NVARCHAR(50), 
    @StartDate DATE, 
    @EndDate DATE, 
    @Status NVARCHAR(20), 
    @AddingEmployeeId INT 
AS
BEGIN
    -- Deklarasi variabel untuk menyimpan hasil pengecekan peran
   DECLARE @IsValidUser BIT;

 
    -- Validasi bahwa pengguna yang menambahkan adalah pengguna yang sama dengan yang ingin ditambahkan
    SET @IsValidUser = dbo.fn_validate_user_identity(@AddingEmployeeId, @EmployeeId);

    IF @IsValidUser = 0
    BEGIN
        RAISERROR('Anda hanya dapat menambahkan data untuk diri sendiri.', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.tbl_leave_requests (employee_id, leave_type, start_date, end_date, status)
    VALUES (@EmployeeId, @LeaveType, @StartDate, @EndDate, @Status);


    PRINT 'Pengajuan cuti baru berhasil ditambahkan.';
END;
GO
