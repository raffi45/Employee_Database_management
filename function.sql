CREATE FUNCTION func_email_format (@email NVARCHAR(50))
RETURNS BIT
AS
BEGIN
    DECLARE @isValid BIT = 0;

    IF @email LIKE '%_@__%.__%'
        AND @email NOT LIKE '%[^a-zA-Z0-9@._-]%'
        AND CHARINDEX('..', @email) = 0
        AND CHARINDEX('@', @email) = CHARINDEX('@', REVERSE(@email))
        AND CHARINDEX('.', @email) > CHARINDEX('@', @email) + 1
        AND LEN(@email) - LEN(REPLACE(@email, '.', '')) >= 1
        AND LEN(@email) - LEN(REPLACE(@email, '@', '')) = 1
    BEGIN
        SET @isValid = 1;
    END

    RETURN @isValid;
END;
GO

SELECT 
    email,
    dbo.func_email_format(email) AS IsValidEmail
FROM 
    tbl_employees;


------------------------------------------------------

CREATE FUNCTION func_password_policy (@password NVARCHAR(255))
RETURNS BIT
AS
BEGIN
    DECLARE @isValid BIT = 0;

    -- Memeriksa apakah panjang kata sandi minimal 8 karakter
    IF LEN(@password) >= 8
       -- Memeriksa apakah mengandung setidaknya satu huruf besar
       AND @password LIKE '%[A-Z]%'
       -- Memeriksa apakah mengandung setidaknya satu huruf kecil
       AND @password LIKE '%[a-z]%'
       -- Memeriksa apakah mengandung setidaknya satu angka
       AND @password LIKE '%[0-9]%'
       -- Memeriksa apakah mengandung setidaknya satu simbol
       AND @password LIKE '%[!@#$%^&*()_+|~=`{}\[\]:";\<>?,.\/]%'
    BEGIN
        SET @isValid = 1;
    END

    RETURN @isValid;
END;
GO

SELECT 
    password,
    dbo.func_password_policy(password) AS IsValidPassword
FROM 
    tbl_accounts;

-----------------------------------------------------------------------------------------

CREATE FUNCTION func_gender (@gender NVARCHAR(10))
RETURNS BIT
AS
BEGIN
    DECLARE @isValid BIT = 0;

    IF @gender IN ('Male', 'Female')
    BEGIN
        SET @isValid = 1;
    END

    RETURN @isValid;
END;
GO

------------------------------------------
CREATE FUNCTION func_phone_number (@phone_number NVARCHAR(20))
RETURNS BIT
AS
BEGIN
    DECLARE @isValid BIT = 0;

    -- Memeriksa apakah phone_number hanya mengandung angka
    IF @phone_number NOT LIKE '%[^0-9]%'
    BEGIN
        SET @isValid = 1;
    END

    RETURN @isValid;
END;
GO

------------------------------------------------
CREATE FUNCTION dbo.func_password_match (
    @NewPassword NVARCHAR(100),
    @ConfirmPassword NVARCHAR(100)
)
RETURNS BIT
AS
BEGIN
    DECLARE @IsMatch BIT;

    IF @NewPassword = @ConfirmPassword
        SET @IsMatch = 1; -- True
    ELSE
        SET @IsMatch = 0; -- False

    RETURN @IsMatch;
END;
GO
-----------------------------------------------------------------
CREATE FUNCTION dbo.func_salary (
    @JobId INT,
    @Salary DECIMAL(10, 2)
)
RETURNS BIT
AS
BEGIN
    DECLARE @IsValidSalary BIT;

    DECLARE @MinSalary DECIMAL(10, 2);
    DECLARE @MaxSalary DECIMAL(10, 2);

    -- Mengambil nilai minimum dan maksimum gaji dari tabel tbl_jobs berdasarkan Job Id
    SELECT @MinSalary = min_salary, @MaxSalary = max_salary
    FROM tbl_jobs
    WHERE job_id = @JobId;

    -- Memeriksa apakah gaji berada dalam rentang yang valid
    IF @Salary >= @MinSalary AND @Salary <= @MaxSalary
        SET @IsValidSalary = 1; -- True
    ELSE
        SET @IsValidSalary = 0; -- False

    RETURN @IsValidSalary;
END;
GO
--------------------------------
CREATE FUNCTION func_validate_otp
(
    @username NVARCHAR(100),
    @otp_code NVARCHAR(10)
)
RETURNS BIT
AS
BEGIN
    DECLARE @IsValid BIT = 0;
    DECLARE @current_datetime DATETIME = GETDATE();

    -- Cek apakah ada record dengan username dan OTP yang sesuai
    IF EXISTS (
        SELECT 1
        FROM tbl_accounts
        WHERE username = @username
          AND otp = @otp_code
          AND is_expire = 0  -- OTP belum kedaluwarsa
          AND otp_expiry_datetime > @current_datetime  -- Waktu kedaluwarsa belum tercapai
    )
    BEGIN
        SET @IsValid = 1;
    END

    RETURN @IsValid;
END;
