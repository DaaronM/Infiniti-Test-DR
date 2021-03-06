truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.5.4');
go
ALTER PROCEDURE [dbo].[spMultiTenantAdmin_UpdateUser]
	@Username nvarchar(50),
	@Password nvarchar(1000),
	@PasswordSalt nvarchar(128),
	@PwdFormat int,
	@ChangePassword int,
	@ErrorCode int = 0 output
AS

	BEGIN
		UPDATE MultiTenantPortal_Admin
		SET PwdHash = @Password, 
			PwdSalt = @PasswordSalt,
			PwdFormat = @PwdFormat,
			ChangePassword = @ChangePassword
		WHERE [Username] = @Username;
	END

	SET @ErrorCode = @@error;
GO





