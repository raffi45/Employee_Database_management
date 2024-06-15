CREATE PROCEDURE sp_register_employee
    @first_name NVARCHAR(100),
    @last_name NVARCHAR(100),
    @gender NVARCHAR(10),
    @email NVARCHAR(100),
    @phone_number NVARCHAR(20),
    @hire_date DATE,
    @job_id INT,
    @salary DECIMAL(10, 2),
    @manager_id INT,
    @department_id INT,
    @password NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IsValidEmail BIT;
    DECLARE @IsValidPhone BIT;
    DECLARE @IsValidPassword BIT;
    DECLARE @IsMatchPassword BIT;
    DECLARE @IsValidGender BIT;
    DECLARE @IsValidSalary BIT;

    -- Validasi email
    EXEC @IsValidEmail = dbo.func_email_format @email;

    -- Validasi nomor telepon
    EXEC @IsValidPhone = dbo.func_phone_number @phone_number;

    -- Validasi password
    EXEC @IsValidPassword = dbo.func_password_policy @password;

    -- Validasi gender
    SET @IsValidGender = CASE WHEN @gender IN ('Male', 'Female') THEN 1 ELSE 0 END;

    -- Validasi salary
    EXEC @IsValidSalary = dbo.func_salary @job_id, @salary;


    -- Insert data jika semua validasi berhasil
    IF @IsValidEmail = 1 AND @IsValidPhone = 1 AND @IsValidPassword = 1 AND @IsValidGender = 1 AND @IsValidSalary = 1 AND @IsMatchPassword = 1
    BEGIN
        INSERT INTO tbl_employees (first_name, last_name, gender, email, phone_number, hire_date, job_id, salary, manager_id, department_id)
        VALUES (@first_name, @last_name, @gender, @email, @phone_number, @hire_date, @job_id, @salary, @manager_id, @department_id);

        -- Additional operations as needed
        
        SELECT 'Employee registered successfully.' AS message;
    END
    ELSE
    BEGIN
        SELECT 'Employee registration failed. Please check input data.' AS message;
    END;
END;


----------------------------------------------

CREATE PROCEDURE dbo.sp_edit_employee
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
    DECLARE @RoleCheck NVARCHAR(MAX); -- Variabel untuk menyimpan hasil pengecekan peran
    DECLARE @OldJobId INT; -- Variabel untuk menyimpan ID pekerjaan lama

    -- Periksa apakah karyawan yang melakukan edit memiliki peran yang tepat
    SET @RoleCheck = dbo.fn_check_employee_roles(@EditingEmployeeId);
    
    IF CHARINDEX('1', @RoleCheck) = 0 AND CHARINDEX('2', @RoleCheck) = 0
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

    -- Ambil ID pekerjaan lama sebelum melakukan update (trigger akan menangani ini)
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
        employee_id = @EmployeeId; -- Tentukan karyawan berdasarkan EmployeeId

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
---------------------------------------------------------------------------------------------------

CREATE PROCEDURE dbo.sp_delete_employee
    @EmployeeId INT, -- ID karyawan yang akan dihapus
    @DeletingEmployeeId INT -- ID karyawan yang melakukan penghapusan
AS
BEGIN
    -- Deklarasi variabel untuk menyimpan hasil pengecekan peran
    DECLARE @RoleCheck NVARCHAR(MAX);
    
    -- Periksa apakah karyawan yang melakukan penghapusan memiliki peran yang tepat
    SET @RoleCheck = dbo.fn_check_employee_roles(@DeletingEmployeeId);
    
    -- Jika peran tidak sesuai, munculkan pesan error dan berhenti
    IF CHARINDEX('1', @RoleCheck) = 0 AND CHARINDEX('2', @RoleCheck) = 0
    BEGIN
        RAISERROR('Anda tidak memiliki izin untuk menghapus data karyawan.', 16, 1);
        RETURN;
    END

    -- Periksa apakah karyawan yang akan dihapus ada dalam tabel
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_employees WHERE employee_id = @EmployeeId)
    BEGIN
        RAISERROR('Karyawan tidak ditemukan.', 16, 1);
        RETURN;
    END

    -- Hapus karyawan dari tabel tbl_employees
    DELETE FROM dbo.tbl_employees
    WHERE employee_id = @EmployeeId;

    -- Berikan pesan bahwa data karyawan berhasil dihapus
    PRINT 'Data karyawan berhasil dihapus.';
END;
GO
--------------------------------------------------------------------------
CREATE PROCEDURE dbo.sp_add_department
	@departmentid INT,
    @DepartmentName NVARCHAR(100), -- Nama departemen baru
    @LocationId INT, -- ID lokasi untuk departemen baru
    @AddingEmployeeId INT -- ID karyawan yang melakukan penambahan
AS
BEGIN
    -- Deklarasi variabel untuk menyimpan hasil pengecekan peran
    DECLARE @RoleCheck NVARCHAR(MAX);

    -- Periksa apakah karyawan yang melakukan penambahan memiliki peran yang tepat
    SET @RoleCheck = dbo.fn_check_employee_roles(@AddingEmployeeId);
    
    -- Jika peran tidak sesuai, munculkan pesan error dan berhenti
    IF CHARINDEX('1', @RoleCheck) = 0 AND CHARINDEX('2', @RoleCheck) = 0
    BEGIN
        RAISERROR('Anda tidak memiliki izin untuk menambahkan departemen.', 16, 1);
        RETURN;
    END

    -- Periksa apakah lokasi yang diberikan ada dalam tabel tbl_locations
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_locations WHERE location_id = @LocationId)
    BEGIN
        RAISERROR('Lokasi tidak ditemukan.', 16, 1);
        RETURN;
    END

    -- Tambahkan departemen baru ke tabel tbl_departments
    INSERT INTO dbo.tbl_departments (department_id,department_id, location_id)
    VALUES ( @departmentid,@DepartmentName, @LocationId);

    -- Berikan pesan bahwa departemen berhasil ditambahkan
    PRINT 'Departemen baru berhasil ditambahkan.';
END;
GO


DROP PROCEDURE dbo.sp_add_department;
GO

EXEC dbo.sp_add_department 
    @DepartmentName = 'IT Department on', -- Nama departemen baru
    @LocationId = 1, -- ID lokasi untuk departemen baru
    @AddingEmployeeId = 2; -- ID karyawan yang melakukan penambahan
GO



