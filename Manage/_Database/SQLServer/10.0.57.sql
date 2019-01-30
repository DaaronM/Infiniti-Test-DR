truncate table dbversion;
GO
insert into dbversion(dbversion) values ('10.0.57');
GO

ALTER procedure [dbo].[spUsers_updateUser]
	@UserID int,
	@Username nvarchar(256),
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
	@EulaAcceptedUtc datetime,
	@IsGuest bit,
	@TwoFactorSecret nvarchar(100),
	@IsTemporaryUser bit
as
	SET NOCOUNT ON

	DECLARE @IdTable TABLE (ID INT);

	if @UserID = 0 OR @UserID IS NULL
	begin
		INSERT INTO Intelledox_User(Username, PwdHash, WinNT_User, Business_Unit_GUID, User_Guid, SelectedTheme, 
				ChangePassword, PwdSalt, PwdFormat, [Disabled], Address_ID, Timezone, Culture, Language, IsGuest, 
				Invalid_Logon_Attempts, Password_Set_Utc, EulaAcceptanceUtc, TwoFactorSecret, IsTemporaryUser)
		OUTPUT Inserted.User_ID INTO @IdTable
		VALUES (@Username, @Password, @WinNT_User, @BusinessUnitGUID, @User_Guid, @SelectedTheme, 
				@ChangePassword, @PasswordSalt, @PasswordFormat, @Disabled, @Address_Id, @Timezone, @Culture, @Language, @IsGuest, 
				@InvalidLogonAttempts, @PasswordSetUtc, @EulaAcceptedUtc, @TwoFactorSecret, @IsTemporaryUser);
		
		SET @NewID = (SELECT ID FROM @IdTable);

		INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
		SELECT	@User_Guid, User_Group.Group_Guid, 0
		FROM	User_Group
		WHERE	User_Group.AutoAssignment = 1
				AND Business_Unit_Guid = @BusinessUnitGUID;

		--If a temporary user is being created, user must be additionally subscribed to the user groups been subscribed by the Guest user
		IF @IsTemporaryUser = 1
		BEGIN
			INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
			SELECT @User_Guid, User_Group_Subscription.GroupGuid, User_Group_Subscription.IsDefaultGroup
			FROM User_Group_Subscription
			JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
			WHERE Business_Unit_GUID = @BusinessUnitGUID AND IsGuest = 1
		END
	end
	else
	begin
		IF NOT EXISTS(SELECT *
			FROM Intelledox_User
			WHERE	[User_ID] = @UserID
				AND [Disabled] = @Disabled
				AND PwdHash = @Password)
		BEGIN
			-- Clear any sessions if our user account state changes
			DELETE User_Session
			FROM User_Session
				INNER JOIN Intelledox_User ON User_Session.User_Guid = Intelledox_User.User_Guid
			WHERE Intelledox_User.[User_ID] = @UserID;
		END

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
			Password_Set_Utc = @PasswordSetUtc,
			EulaAcceptanceUtc = @EulaAcceptedUtc,
			TwoFactorSecret = @TwoFactorSecret,
			IsTemporaryUser = @IsTemporaryUser
		WHERE [User_ID] = @UserID;
	end

GO
