/*
** Database Update package 6.0.8
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.0.8')
go

--1871
ALTER procedure [dbo].[spCustomField_AddressBookCustomFieldList]
	@AddressBookCustomFieldID int = 0,
	@AddressID int = 0,
	@ErrorCode int = 0 output
AS
	IF (@AddressID = 0 OR @AddressID IS NULL)
		SELECT	Address_Book_Custom_Field.*, Custom_Field.Validation_Type
		FROM	Address_Book_Custom_Field
				INNER JOIN Custom_Field ON Address_Book_Custom_Field.Custom_Field_Id = Custom_Field.Custom_Field_Id
		WHERE	@AddressBookCustomFieldID IS NULL
				OR Address_Book_Custom_Field_ID = @AddressBookCustomFieldID;
	ELSE
		SELECT	Address_Book_Custom_Field.*, Custom_Field.Validation_Type
		FROM	Address_Book_Custom_Field
				INNER JOIN Custom_Field ON Address_Book_Custom_Field.Custom_Field_Id = Custom_Field.Custom_Field_Id
		WHERE	@AddressID IS NULL
				OR Address_ID = @AddressID;
	
	set @errorcode = @@error;
GO


--1872
ALTER TABLE dbo.Intelledox_User ADD
	PwdFormat int NULL,
	PwdSalt nvarchar(128) NULL
GO
ALTER TABLE dbo.Intelledox_User ADD CONSTRAINT
	DF_Intelledox_User_PwdFormat DEFAULT 1 FOR PwdFormat
GO
UPDATE	Intelledox_User
SET		PwdFormat = 1
WHERE	PwdFormat IS NULL;
GO
ALTER procedure [dbo].[spUsers_UpdateUser]
	@UserID int,
	@Username nvarchar(50),
	@Password nvarchar(1000),
	@NewID int = 0 output,
	@WinNT_User char(1),
	@BusinessUnitGUID uniqueidentifier,
	@User_GUID uniqueidentifier,
	@SelectedTheme nvarchar(100),
	@ChangePassword int,
	@PasswordSalt nvarchar(128),
	@PasswordFormat int,
	@ErrorCode int = 0 output
as
	if @UserID = 0 OR @UserID IS NULL
	begin
		INSERT INTO Intelledox_User(Username, PwdHash, WinNT_User, Business_Unit_GUID, User_Guid, SelectedTheme, 
				ChangePassword, PwdSalt, PwdFormat)
		VALUES (@Username, @Password, @WinNT_User, @BusinessUnitGUID, @User_Guid, @SelectedTheme, 
				@ChangePassword, @PasswordSalt, @PasswordFormat);
		
		select @NewID = @@identity;

		INSERT INTO User_Group_Subscription(User_ID, User_Group_ID, Default_Group)
		SELECT	@NewID, User_Group.User_Group_ID, 0
		FROM	User_Group
		WHERE	User_Group.AutoAssignment = '1';
	end
	else
	begin
		update Intelledox_User
		SET Username = @Username,  
			PwdHash = @Password, 
			WinNT_User = @WinNT_User,
			SelectedTheme = @SelectedTheme,
			ChangePassword = @ChangePassword,
			PwdSalt = @PasswordSalt,
			PwdFormat = @PasswordFormat
		where [User_ID] = @UserID;
	end

	set @ErrorCode = @@error;
GO

