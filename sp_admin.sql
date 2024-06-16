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
    DECLARE @RoleCheck NVARCHAR(MAX); 
    DECLARE @OldJobId INT; 

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
    @DepartmentName NVARCHAR(100), 
    @LocationId INT, 
    @AddingEmployeeId INT 
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
    INSERT INTO dbo.tbl_departments (department_name, location_id)
    VALUES (@DepartmentName, @LocationId);


    PRINT 'Departemen baru berhasil ditambahkan.';
END;
GO

------------------------------------------------------------------------------------

CREATE PROCEDURE dbo.sp_edit_department
    @DepartmentId INT, -- ID departemen yang akan diedit
    @NewDepartmentName NVARCHAR(100), -- Nama baru departemen
    @NewLocationId INT, -- ID lokasi baru untuk departemen
    @EditingEmployeeId INT -- ID karyawan yang melakukan perubahan
AS
BEGIN
    -- Deklarasi variabel untuk menyimpan hasil pengecekan peran
    DECLARE @RoleCheck NVARCHAR(MAX);

    -- Periksa apakah karyawan yang melakukan perubahan memiliki peran yang tepat
    SET @RoleCheck = dbo.fn_check_employee_roles(@EditingEmployeeId);

    -- Jika peran tidak sesuai, munculkan pesan error dan berhenti
    IF CHARINDEX('1', @RoleCheck) = 0 AND CHARINDEX('2', @RoleCheck) = 0
    BEGIN
        RAISERROR('Anda tidak memiliki izin untuk mengedit departemen.', 16, 1);
        RETURN;
    END

    -- Periksa apakah departemen yang diberikan ada dalam tabel tbl_departments
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_departments WHERE department_id = @DepartmentId)
    BEGIN
        RAISERROR('Departemen tidak ditemukan.', 16, 1);
        RETURN;
    END

    -- Periksa apakah lokasi yang diberikan ada dalam tabel tbl_locations
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_locations WHERE location_id = @NewLocationId)
    BEGIN
        RAISERROR('Lokasi tidak ditemukan.', 16, 1);
        RETURN;
    END

    -- Update data departemen di tabel tbl_departments
    UPDATE dbo.tbl_departments
    SET department_name = @NewDepartmentName, location_id = @NewLocationId
    WHERE department_id = @DepartmentId;

    -- Berikan pesan bahwa departemen berhasil diedit
    PRINT 'Departemen berhasil diedit.';
END;
GO

---------------------------------------------------------------------------


CREATE PROCEDURE dbo.sp_delete_department
    @DepartmentId INT, 
    @DeletingEmployeeId INT 
AS
BEGIN
    -- Deklarasi variabel untuk menyimpan hasil pengecekan peran
    DECLARE @RoleCheck NVARCHAR(MAX);

    -- Periksa apakah karyawan yang melakukan penghapusan memiliki peran yang tepat
    SET @RoleCheck = dbo.fn_check_employee_roles(@DeletingEmployeeId);

    -- Jika peran tidak sesuai, munculkan pesan error dan berhenti
    IF CHARINDEX('1', @RoleCheck) = 0 AND CHARINDEX('2', @RoleCheck) = 0
    BEGIN
        RAISERROR('Anda tidak memiliki izin untuk menghapus departemen.', 16, 1);
        RETURN;
    END

    -- Periksa apakah departemen yang diberikan ada dalam tabel tbl_departments
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_departments WHERE department_id = @DepartmentId)
    BEGIN
        RAISERROR('Departemen tidak ditemukan.', 16, 1);
        RETURN;
    END


    DELETE FROM dbo.tbl_departments
    WHERE department_id = @DepartmentId;

    
    PRINT 'Departemen berhasil dihapus.';
END;
GO

------------------------------------------------------------------------------

CREATE PROCEDURE dbo.sp_add_job
    @JobTitle NVARCHAR(100), -- Judul pekerjaan baru
    @MinSalary DECIMAL(10, 2), -- Gaji minimum untuk pekerjaan baru
    @MaxSalary DECIMAL(10, 2), -- Gaji maksimum untuk pekerjaan baru
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
        RAISERROR('Anda tidak memiliki izin untuk menambahkan pekerjaan.', 16, 1);
        RETURN;
    END

    -- Tambahkan pekerjaan baru ke tabel tbl_jobs
    INSERT INTO dbo.tbl_jobs (job_title, min_salary, max_salary)
    VALUES (@JobTitle, @MinSalary, @MaxSalary);

    -- Berikan pesan bahwa pekerjaan baru berhasil ditambahkan
    PRINT 'Pekerjaan baru berhasil ditambahkan.';
END;
GO
------------------------------------------------------------------------------------------

CREATE PROCEDURE dbo.sp_edit_job
    @JobId INT,     
    @JobTitle NVARCHAR(100), 
    @MinSalary DECIMAL(10, 2), 
    @MaxSalary DECIMAL(10, 2), 
    @EditingEmployeeId INT 
AS
BEGIN
    -- Deklarasi variabel untuk menyimpan hasil pengecekan peran
    DECLARE @RoleCheck NVARCHAR(MAX);

    -- Periksa apakah karyawan yang melakukan pengeditan memiliki peran yang tepat
    SET @RoleCheck = dbo.fn_check_employee_roles(@EditingEmployeeId);
    
    -- Jika peran tidak sesuai, munculkan pesan error dan berhenti
    IF CHARINDEX('1', @RoleCheck) = 0 AND CHARINDEX('2', @RoleCheck) = 0
    BEGIN
        RAISERROR('Anda tidak memiliki izin untuk mengedit pekerjaan.', 16, 1);
        RETURN;
    END

    -- Periksa apakah pekerjaan dengan @JobId ada dalam tabel tbl_jobs
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_jobs WHERE job_id = @JobId)
    BEGIN
        RAISERROR('Pekerjaan tidak ditemukan.', 16, 1);
        RETURN;
    END


    UPDATE dbo.tbl_jobs
    SET job_title = @JobTitle,
        min_salary = @MinSalary,
        max_salary = @MaxSalary
    WHERE job_id = @JobId;

  
    PRINT 'Pekerjaan berhasil diubah.';
END;
GO

---------------------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE dbo.sp_delete_job
    @JobId INT,
    @DeletingEmployeeId INT
AS
BEGIN
    DECLARE @RoleCheck NVARCHAR(MAX);

    -- Memeriksa peran karyawan yang melakukan penghapusan
    SET @RoleCheck = dbo.fn_check_employee_roles(@DeletingEmployeeId);
    
    -- Jika karyawan tidak memiliki peran yang sesuai, hentikan proses
    IF CHARINDEX('1', @RoleCheck) = 0 AND CHARINDEX('2', @RoleCheck) = 0
    BEGIN
        RAISERROR('Anda tidak memiliki izin untuk menghapus pekerjaan.', 16, 1);
        RETURN;
    END

    -- Memeriksa apakah pekerjaan yang akan dihapus ada dalam tabel tbl_jobs
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_jobs WHERE job_id = @JobId)
    BEGIN
        RAISERROR('Pekerjaan tidak ditemukan.', 16, 1);
        RETURN;
    END

    -- Menghapus pekerjaan dari tabel tbl_jobs
    DELETE FROM dbo.tbl_jobs
    WHERE job_id = @JobId;

    PRINT 'Pekerjaan berhasil dihapus.';
END;
GO


-----------------------------------------------------------------------------------
CREATE PROCEDURE dbo.sp_add_country
    @CountryName NVARCHAR(100), 
    @RegionId INT, 
    @AddingEmployeeId INT 
AS
BEGIN
    -- Deklarasi variabel untuk menyimpan hasil pengecekan peran
    DECLARE @RoleCheck NVARCHAR(MAX);

    -- Periksa apakah karyawan yang melakukan penambahan memiliki peran yang sesuai
    SET @RoleCheck = dbo.fn_check_employee_roles(@AddingEmployeeId);
    
    -- Jika peran tidak sesuai, munculkan pesan error dan berhenti
    IF CHARINDEX('1', @RoleCheck) = 0 AND CHARINDEX('2', @RoleCheck) = 0
    BEGIN
        RAISERROR('Anda tidak memiliki izin untuk menambahkan negara.', 16, 1);
        RETURN;
    END

    -- Periksa apakah region yang diberikan ada dalam tabel tbl_regions
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_regions WHERE region_id = @RegionId)
    BEGIN
        RAISERROR('Region tidak ditemukan.', 16, 1);
        RETURN;
    END

    -- Tambahkan negara baru ke dalam tabel tbl_countries
    INSERT INTO dbo.tbl_countries (country_name, region_id)
    VALUES (@CountryName, @RegionId);

    -- Berikan pesan bahwa negara berhasil ditambahkan
    PRINT 'Negara baru berhasil ditambahkan.';
END;
GO

--------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE dbo.sp_edit_country
    @CountryId INT, 
    @CountryName NVARCHAR(100), 
    @RegionId INT, 
    @EditingEmployeeId INT 
AS
BEGIN
    -- Deklarasi variabel untuk menyimpan hasil pengecekan peran
    DECLARE @RoleCheck NVARCHAR(MAX);

    -- Periksa apakah karyawan yang melakukan pengeditan memiliki peran yang sesuai
    SET @RoleCheck = dbo.fn_check_employee_roles(@EditingEmployeeId);
    
    -- Jika peran tidak sesuai, munculkan pesan error dan berhenti
    IF CHARINDEX('1', @RoleCheck) = 0 AND CHARINDEX('2', @RoleCheck) = 0
    BEGIN
        RAISERROR('Anda tidak memiliki izin untuk mengedit negara.', 16, 1);
        RETURN;
    END

    -- Periksa apakah negara yang akan diedit ada dalam tabel tbl_countries
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_countries WHERE country_id = @CountryId)
    BEGIN
        RAISERROR('Negara tidak ditemukan.', 16, 1);
        RETURN;
    END

    -- Periksa apakah region yang diberikan ada dalam tabel tbl_regions
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_regions WHERE region_id = @RegionId)
    BEGIN
        RAISERROR('Region tidak ditemukan.', 16, 1);
        RETURN;
    END

    -- Update data negara di tabel tbl_countries
    UPDATE dbo.tbl_countries
    SET country_name = @CountryName,
        region_id = @RegionId
    WHERE country_id = @CountryId;

    -- Berikan pesan bahwa negara berhasil diubah
    PRINT 'Negara berhasil diubah.';
END;
GO

-----------------------------------------------------------------------------

CREATE PROCEDURE dbo.sp_add_region
    @RegionName NVARCHAR(100), 
    @AddingEmployeeId INT 
AS
BEGIN
    -- Deklarasi variabel untuk menyimpan hasil pengecekan peran
    DECLARE @RoleCheck NVARCHAR(MAX);

    -- Periksa apakah karyawan yang melakukan penambahan memiliki peran yang sesuai
    SET @RoleCheck = dbo.fn_check_employee_roles(@AddingEmployeeId);
    
    -- Jika peran tidak sesuai, munculkan pesan error dan berhenti
    IF CHARINDEX('1', @RoleCheck) = 0 AND CHARINDEX('2', @RoleCheck) = 0
    BEGIN
        RAISERROR('Anda tidak memiliki izin untuk menambahkan region.', 16, 1);
        RETURN;
    END

    INSERT INTO dbo.tbl_regions (region_name)
    VALUES (@RegionName);

  
    PRINT 'Region baru berhasil ditambahkan.';
END;
GO
 -------------------------------------------------------------------------------
 CREATE PROCEDURE dbo.sp_edit_region
    @RegionId INT, -- ID region yang akan diedit
    @RegionName NVARCHAR(100), -- Nama region baru
    @EditingEmployeeId INT -- ID karyawan yang melakukan pengeditan
AS
BEGIN
    -- Deklarasi variabel untuk menyimpan hasil pengecekan peran
    DECLARE @RoleCheck NVARCHAR(MAX);

    -- Periksa apakah karyawan yang melakukan pengeditan memiliki peran yang sesuai
    SET @RoleCheck = dbo.fn_check_employee_roles(@EditingEmployeeId);
    
    -- Jika peran tidak sesuai, munculkan pesan error dan berhenti
    IF CHARINDEX('1', @RoleCheck) = 0 AND CHARINDEX('2', @RoleCheck) = 0
    BEGIN
        RAISERROR('Anda tidak memiliki izin untuk mengedit region.', 16, 1);
        RETURN;
    END

    -- Periksa apakah region yang akan diedit ada dalam tabel tbl_regions
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_regions WHERE region_id = @RegionId)
    BEGIN
        RAISERROR('Region tidak ditemukan.', 16, 1);
        RETURN;
    END

    -- Update data region di tabel tbl_regions
    UPDATE dbo.tbl_regions
    SET region_name = @RegionName
    WHERE region_id = @RegionId;

    -- Berikan pesan bahwa region berhasil diubah
    PRINT 'Region berhasil diubah.';
END;
GO


----------------------------------------------------------------------------------------------------------
CREATE PROCEDURE dbo.sp_add_role
    @RoleName NVARCHAR(100),
	@AddingEmployeeId INT 
AS
BEGIN
    -- Deklarasi variabel untuk menyimpan hasil pengecekan peran
    DECLARE @RoleCheck NVARCHAR(MAX);

    -- Periksa apakah karyawan yang akan menambahkan role memiliki peran yang sesuai
    SET @RoleCheck = dbo.fn_check_employee_roles(@AddingEmployeeId);
    
    -- Jika peran tidak sesuai, munculkan pesan error dan berhenti
    IF CHARINDEX('1', @RoleCheck) = 0 AND CHARINDEX('2', @RoleCheck) = 0
    BEGIN
        RAISERROR('Anda tidak memiliki izin untuk menambahkan role.', 16, 1);
        RETURN;
    END

    
    INSERT INTO dbo.tbl_roles (role_name)
    VALUES (@RoleName);


    PRINT 'Role baru berhasil ditambahkan.';
END;
GO

-------------------------------------------------------------------------------------------------------
CREATE PROCEDURE dbo.sp_edit_role
    @RoleId INT, 
    @NewRoleName NVARCHAR(100),
    @EditingEmployeeId INT 
AS
BEGIN
    -- Deklarasi variabel untuk menyimpan hasil pengecekan peran
    DECLARE @RoleCheck NVARCHAR(MAX);

    -- Periksa apakah karyawan yang melakukan pengubahan memiliki peran yang sesuai
    SET @RoleCheck = dbo.fn_check_employee_roles(@EditingEmployeeId);
    
    -- Jika peran tidak sesuai, munculkan pesan error dan berhenti
    IF CHARINDEX('1', @RoleCheck) = 0 AND CHARINDEX('2', @RoleCheck) = 0
    BEGIN
        RAISERROR('Anda tidak memiliki izin untuk mengubah nama role.', 16, 1);
        RETURN;
    END

    -- Periksa apakah role yang akan diubah namanya ada dalam tabel tbl_roles
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_roles WHERE role_id = @RoleId)
    BEGIN
        RAISERROR('Role tidak ditemukan.', 16, 1);
        RETURN;
    END

   
    UPDATE dbo.tbl_roles
    SET role_name = @NewRoleName
    WHERE role_id = @RoleId;

    PRINT 'Nama role berhasil diubah.';
END;
GO
------------------------------------------------------------
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
---------------------------------------------------------------------------------------------
CREATE PROCEDURE dbo.sp_edit_attendance
    @AttendanceId INT, 
    @EmployeeId INT, 
    @AttendanceDate DATE, 
    @CheckInTime TIME, 
    @CheckOutTime TIME, 
    @EditingEmployeeId INT 
AS
BEGIN

    DECLARE @RoleCheck NVARCHAR(MAX);
    

    IF CHARINDEX('1', @RoleCheck) = 0 AND CHARINDEX('2', @RoleCheck) = 0
    BEGIN
        RAISERROR('Anda tidak memiliki izin untuk mengedit data attendance.', 16, 1);
        RETURN;
    END

    -- Update data di tabel tbl_attendance
    UPDATE dbo.tbl_attendance
    SET attendance_date = @AttendanceDate, 
        check_in_time = @CheckInTime, 
        check_out_time = @CheckOutTime
    WHERE attendance_id = @AttendanceId AND employee_id = @EmployeeId;


    PRINT 'Data attendance berhasil diubah.';
END;
GO
------------------------------------------------------------------
CREATE PROCEDURE dbo.sp_delete_attendance
    @AttendanceId INT, 
    @EmployeeId INT, 
    @DeletingEmployeeId INT 
AS
BEGIN
    
    DECLARE @RoleCheck NVARCHAR(MAX);


    SET @RoleCheck = dbo.fn_check_employee_roles(@DeletingEmployeeId);
    

    IF CHARINDEX('1', @RoleCheck) = 0 AND CHARINDEX('2', @RoleCheck) = 0
    BEGIN
        RAISERROR('Anda tidak memiliki izin untuk menghapus data attendance.', 16, 1);
        RETURN;
    END

    DELETE FROM dbo.tbl_attendance
    WHERE attendance_id = @AttendanceId AND employee_id = @EmployeeId;

 
    PRINT 'Data attendance berhasil dihapus.';
END;
GO

---------------------------------------------
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

---------------------------------------------------------

CREATE PROCEDURE dbo.sp_edit_leave_request
    @LeaveRequestId INT= NULL, 
    @EmployeeId INT= NULL, 
    @LeaveType NVARCHAR(50)= NULL, 
    @StartDate DATE= NULL,
    @EndDate DATE= NULL, 
    @Status NVARCHAR(20)= NULL,
    @EditingEmployeeId INT 
AS
BEGIN
    -- Deklarasi variabel untuk menyimpan hasil pengecekan peran
    DECLARE @RoleCheck NVARCHAR(MAX);

    -- Periksa apakah karyawan yang melakukan pengeditan memiliki peran yang sesuai
    SET @RoleCheck = dbo.fn_check_employee_roles(@EditingEmployeeId);
    
    -- Jika peran tidak sesuai, munculkan pesan error dan berhenti
    IF CHARINDEX('1', @RoleCheck) = 0 AND CHARINDEX('2', @RoleCheck) = 0
    BEGIN
        RAISERROR('Anda tidak memiliki izin untuk mengedit pengajuan cuti.', 16, 1);
        RETURN;
    END

    -- Periksa apakah pengajuan cuti yang akan diedit ada dalam tabel tbl_leave_requests
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_leave_requests WHERE leave_request_id = @LeaveRequestId)
    BEGIN
        RAISERROR('Pengajuan cuti tidak ditemukan.', 16, 1);
        RETURN;
    END

    -- Update pengajuan cuti di tabel tbl_leave_requests
    UPDATE dbo.tbl_leave_requests
    SET 
        employee_id = COALESCE(@EmployeeId, employee_id), 
        leave_type = COALESCE(@LeaveType, leave_type), 
        start_date = COALESCE(@StartDate, start_date), 
        end_date = COALESCE(@EndDate, end_date), 
        status = COALESCE(@Status, status)
    WHERE leave_request_id = @LeaveRequestId;

    -- Berikan pesan bahwa pengajuan cuti berhasil diedit
    PRINT 'Pengajuan cuti berhasil diedit.';
END;
GO

-------------------------------------------------------------------------------------------

CREATE PROCEDURE dbo.sp_delete_leave_request
    @LeaveRequestId INT, 
    @DeletingEmployeeId INT 
AS
BEGIN
  
    DECLARE @RoleCheck NVARCHAR(MAX);


    SET @RoleCheck = dbo.fn_check_employee_roles(@DeletingEmployeeId);
    
    -- Jika peran tidak sesuai, munculkan pesan error dan berhenti
    IF CHARINDEX('1', @RoleCheck) = 0 AND CHARINDEX('2', @RoleCheck) = 0
    BEGIN
        RAISERROR('Anda tidak memiliki izin untuk menghapus pengajuan cuti.', 16, 1);
        RETURN;
    END

    
    IF NOT EXISTS (SELECT 1 FROM dbo.tbl_leave_requests WHERE leave_request_id = @LeaveRequestId)
    BEGIN
        RAISERROR('Pengajuan cuti tidak ditemukan.', 16, 1);
        RETURN;
    END

  
    DELETE FROM dbo.tbl_leave_requests
    WHERE leave_request_id = @LeaveRequestId;

  
    PRINT 'Pengajuan cuti berhasil dihapus.';
END;
GO


---------------------------------------------------------------------------





