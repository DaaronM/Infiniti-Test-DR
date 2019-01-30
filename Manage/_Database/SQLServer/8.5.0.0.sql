truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.5.0.0');
go

CREATE TABLE [dbo].[Password_History](
	[id] [integer] IDENTITY(1,1),
	[User_Guid] [uniqueidentifier] NOT NULL,
	[pwdhash] [varchar](1000) NOT NULL,
	[DateCreatedUtc] [datetime] NOT NULL default GETUTCDATE(),
 CONSTRAINT [PK_Password_History] PRIMARY KEY (id)

 )
GO

CREATE PROCEDURE [dbo].spUser_HasUsedPassword
	@UserGuid uniqueidentifier,
	@PwdHash varchar(1000)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT COUNT(*)
	FROM Password_History ph
	INNER JOIN Intelledox_User u on u.User_Guid = ph.User_Guid
	WHERE ph.User_Guid = @UserGuid AND
	((ph.pwdhash = @PwdHash) OR (u.pwdhash = @PwdHash))
END
GO


CREATE PROCEDURE [dbo].spUser_AddToPasswordHistory
	@UserGuid uniqueidentifier,
	@PwdHash varchar(1000)
AS
BEGIN
	INSERT INTO [Password_History] (User_Guid, pwdhash)
	VALUES(@UserGuid, @PwdHash)

	DECLARE @HistoryLimit integer
	DECLARE @BusinessUnitGuid uniqueidentifier

	SET @HistoryLimit = (SELECT Global_Options.OptionValue FROM Global_Options 
						INNER JOIN Intelledox_User on Intelledox_User.User_Guid = @UserGuid
						WHERE Global_Options.BusinessUnitGuid = Intelledox_User.Business_Unit_GUID AND OptionCode = 'PASSWORD_HISTORY_COUNT')

	DELETE FROM Password_History
	WHERE id NOT IN (SELECT TOP (@HistoryLimit) id FROM Password_History ORDER BY DateCreatedUtc DESC)
END
GO

INSERT INTO Global_Options (BusinessUnitGuid,OptionCode,OptionDescription,OptionValue)
SELECT bu.Business_Unit_GUID,'PASSWORD_HISTORY_COUNT','Number of old passwords to store','0'
FROM Business_Unit bu
GO

INSERT INTO Global_Options (BusinessUnitGuid,OptionCode,OptionDescription,OptionValue)
SELECT bu.Business_Unit_GUID,'MAXIMUM_PASSWORD_AGE','Number of days until password expires','0'
FROM Business_Unit bu
GO

INSERT INTO Global_Options (BusinessUnitGuid,OptionCode,OptionDescription,OptionValue)
SELECT bu.Business_Unit_GUID,'COMPLEX_PASSWORDS','Enable or disable complex passwords','false'
FROM Business_Unit bu
GO

DELETE FROM Global_Options
WHERE OptionCode = 'MINIMUM_NUMERIC_CHARACTERS'
GO

ALTER TABLE Intelledox_User
ADD [Invalid_Logon_Attempts] [Integer] NOT NULL DEFAULT 0,
	[Password_Set_Utc] [DateTime] NOT NULL DEFAULT GETUTCDATE(),
    [Locked_Until_Utc] [DateTime] NULL
GO

CREATE PROCEDURE [dbo].spUser_IsLockedOut
	@Username varchar(50)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT COUNT(*)
	FROM Intelledox_User
	WHERE Intelledox_User.Username = @Username AND
		Intelledox_User.Locked_Until_Utc IS NOT NULL AND
		Intelledox_User.Locked_Until_Utc > GETUTCDATE()
END
GO

CREATE PROCEDURE [dbo].spUser_InvalidLogonAttempt
	@Username varchar(50)
AS
BEGIN
	UPDATE Intelledox_User
	SET [Invalid_Logon_Attempts] = [Invalid_Logon_Attempts] + 1
	WHERE Username = @Username
END
GO

CREATE PROCEDURE [dbo].spUser_ClearInvalidLogonAttempts
	@Username varchar(50)
AS
BEGIN
	UPDATE Intelledox_User
	SET [Invalid_Logon_Attempts] = 0
	WHERE Username = @Username
END
GO

CREATE PROCEDURE [dbo].[spUser_SetLockedOutUtc]
	@Username nvarchar(50),
	@LockedOutUtc DateTime
AS
	UPDATE Intelledox_User
	SET [Locked_Until_Utc] = @LockedOutUtc
	WHERE Username = @Username
GO

ALTER procedure [dbo].[spUsers_updateUser]
	@UserID int,
	@Username nvarchar(50),
	@Password nvarchar(1000),
	@NewID int = 0 output,
	@WinNT_User bit,
	@BusinessUnitGUID uniqueidentifier,
	@User_GUID uniqueidentifier,
	@SelectedTheme nvarchar(100),
	@ChangePassword int,
	@PasswordSalt nvarchar(128),
	@PasswordFormat int,
	@Disabled int,
	@Address_Id int,
	@Timezone nvarchar(50),
	@Culture nvarchar(11),
	@Language nvarchar(11),
	@InvalidLogonAttempts int,
	@PasswordSetUtc datetime,
	@IsGuest bit = 0,
	@ErrorCode int = 0 output
as
	if @UserID = 0 OR @UserID IS NULL
	begin
		INSERT INTO Intelledox_User(Username, PwdHash, WinNT_User, Business_Unit_GUID, User_Guid, SelectedTheme, 
				ChangePassword, PwdSalt, PwdFormat, [Disabled], Address_ID, Timezone, Culture, Language, IsGuest, Invalid_Logon_Attempts, Password_Set_Utc)
		VALUES (@Username, @Password, @WinNT_User, @BusinessUnitGUID, @User_Guid, @SelectedTheme, 
				@ChangePassword, @PasswordSalt, @PasswordFormat, @Disabled, @Address_Id, @Timezone, @Culture, @Language, @IsGuest, @InvalidLogonAttempts, @PasswordSetUtc);
		
		select @NewID = @@identity;

		INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
		SELECT	@User_Guid, User_Group.Group_Guid, 0
		FROM	User_Group
		WHERE	User_Group.AutoAssignment = 1
				AND Business_Unit_Guid = @BusinessUnitGUID;
	end
	else
	begin
		UPDATE Intelledox_User
		SET Username = @Username,  
			PwdHash = @Password, 
			WinNT_User = @WinNT_User,
			SelectedTheme = @SelectedTheme,
			ChangePassword = @ChangePassword,
			PwdSalt = @PasswordSalt,
			PwdFormat = @PasswordFormat,
			[Disabled] = @Disabled,
			Timezone = @Timezone,
			Culture = @Culture,
			Language = @Language,
			Address_ID = @Address_Id,
			Invalid_Logon_Attempts = @InvalidLogonAttempts,
			Password_Set_Utc = @PasswordSetUtc
		WHERE [User_ID] = @UserID;
	end

	set @ErrorCode = @@error;
GO
