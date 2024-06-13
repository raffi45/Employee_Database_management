USE CompanyDB;
GO


---- SP LOGIN
CREATE PROCEDURE sp_login
    @username NVARCHAR(100),
    @password NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @account_id INT;
    DECLARE @employee_id INT;

    -- Memeriksa apakah kombinasi username dan password valid
    SELECT 
        @account_id = account_id,
        @employee_id = employee_id
    FROM tbl_accounts
    WHERE username = @username AND password = @password;

    IF @account_id IS NOT NULL
    BEGIN
        -- Mengembalikan informasi akun jika login berhasil
        SELECT 
            a.account_id,
            a.username,
            e.first_name,
            e.last_name,
            e.email,
            e.phone_number,
            e.department_id,
            d.department_name
        FROM tbl_accounts a
        JOIN tbl_employees e ON a.employee_id = e.employee_id
        JOIN tbl_departments d ON e.department_id = d.department_id
        WHERE a.account_id = @account_id;
    END
    ELSE
    BEGIN
        -- Mengembalikan pesan kesalahan jika login gagal
        SELECT 
            'Invalid username or password' AS ErrorMessage;
    END
END;
GO

EXEC sp_login @username = 'raffi', @password = 'password1';

--------------------------------
CREATE PROCEDURE sp_forgot_password
    @username NVARCHAR(100),
    @new_password NVARCHAR(100),
    @confirm_password NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IsValidEmail BIT;
    DECLARE @IsValidPassword BIT;
    DECLARE @otp_code NVARCHAR(10);
    DECLARE @otp_expiry_minutes INT = 10;  -- Waktu kedaluwarsa OTP dalam menit

    -- Validasi email format
    EXEC @IsValidEmail = dbo.func_email_format @username;

    -- Validasi password policy
    EXEC @IsValidPassword = dbo.func_password_policy @new_password;

    -- Generate OTP
    EXEC dbo.sp_generate_otp @username, @otp_code OUTPUT;

    -- Validasi OTP
    DECLARE @IsValidOTP BIT;
    EXEC @IsValidOTP = dbo.func_validate_otp @username, @otp_code;

    -- Check validasi email, password, dan OTP
    IF @IsValidEmail = 1 AND @IsValidPassword = 1 AND @IsValidOTP = 1
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

--------------------------------------------
CREATE PROCEDURE sp_generate_otp
    @username NVARCHAR(100),
    @otp_length INT = 6,  -- Panjang default OTP adalah 6 digit
    @otp_expiry_minutes INT = 10  -- Waktu kedaluwarsa OTP dalam menit
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @otp_code NVARCHAR(10);  -- Panjang OTP maksimal 10 digit
    DECLARE @current_datetime DATETIME = GETDATE();
    DECLARE @expiry_datetime DATETIME = DATEADD(MINUTE, @otp_expiry_minutes, @current_datetime);

    -- Generate random OTP code
    SET @otp_code = '';
    WHILE LEN(@otp_code) < @otp_length
    BEGIN
        SET @otp_code = @otp_code + CAST(FLOOR(RAND() * 10) AS NVARCHAR(1));
    END;

    -- Insert or update OTP record in tbl_accounts
    IF EXISTS (SELECT 1 FROM tbl_accounts WHERE username = @username)
    BEGIN
        -- Update existing OTP record
        UPDATE tbl_accounts
        SET otp = @otp_code,
            is_expire = 0,  -- OTP belum kedaluwarsa
            is_used_datetime = NULL,  -- Reset is_used_datetime
            otp_expiry_datetime = @expiry_datetime  -- Set waktu kedaluwarsa OTP
        WHERE username = @username;
    END
    ELSE
    BEGIN
        -- Insert new OTP record
        INSERT INTO tbl_accounts (username, otp, is_expire, is_used_datetime, otp_expiry_datetime)
        VALUES (@username, @otp_code, 0, NULL, @expiry_datetime);
    END;

    -- Return OTP code for user
    SELECT @otp_code AS otp_code, @expiry_datetime AS expiry_datetime;
END;

