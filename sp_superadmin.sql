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
