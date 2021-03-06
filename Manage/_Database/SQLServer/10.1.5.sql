truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.1.5');
GO

ALTER PROCEDURE [dbo].[spProject_GetProjectsByContentItem]
	@ContentGuid varchar(40),
	@BusinessUnitGuid uniqueidentifier
AS
	SET ARITHABORT ON 

	SELECT DISTINCT	Template.template_id, 
			Template.[name] as project_name, 
			Template.template_type_id, 
			Template.template_guid, 
			Template.template_version, 
			Template.import_date,
			Template.Business_Unit_GUID, 
			Template.Supplier_Guid,
			Template.Modified_Date,
			Intelledox_User.Username,
			Template.Modified_By,
			Template.FeatureFlags,
			Template.FolderGuid,
			Template.Template_Version,
			Template.IsMajorVersion
	FROM	Template
		LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By
		INNER JOIN Xtf_ContentLibrary_Dependency on Xtf_ContentLibrary_Dependency.Template_Guid = Template.Template_Guid  AND
													Xtf_ContentLibrary_Dependency.Template_Version = Template.Template_Version
	WHERE	Template.Business_Unit_GUID = @BusinessUnitGuid
		AND Xtf_ContentLibrary_Dependency.Content_Object_Guid = @ContentGuid 
	ORDER BY Template.[name];

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

		--If a temporary user is being created, user must be additionally subscribed to the user groups been subscribed by the Guest user
		IF @IsTemporaryUser = 1 
		BEGIN
			INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
			SELECT @User_Guid, User_Group_Subscription.GroupGuid, User_Group_Subscription.IsDefaultGroup
			FROM User_Group_Subscription
			JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
			WHERE Business_Unit_GUID = @BusinessUnitGUID AND IsGuest = 1
		END
		ELSE
		BEGIN
			INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
			SELECT	@User_Guid, User_Group.Group_Guid, 0
			FROM	User_Group
			WHERE	User_Group.AutoAssignment = 1
					AND Business_Unit_Guid = @BusinessUnitGUID;
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

CREATE PROCEDURE [dbo].[spDataSource_DeleteSchema]
	@DataServiceGuid uniqueidentifier
AS
	UPDATE Data_Service
	SET [Schema] = NULL
	WHERE Data_Service_Guid = @DataServiceGuid
GO

CREATE PROCEDURE [dbo].[spDataSource_DeleteDefaultData]
	@DataServiceGuid uniqueidentifier
AS
	UPDATE Data_Service
	SET DefaultData = NULL,
		EncryptedDefaultData = NULL
	WHERE Data_Service_Guid = @DataServiceGuid
GO
ALTER PROCEDURE [dbo].[spProject_DeleteOldProjectVersion]
	@ProjectGuid uniqueidentifier,
	@NextVersion nvarchar(10),
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN
	
	DECLARE @HasMatchProjectVersionDependency int
	SET @HasMatchProjectVersionDependency = 0

	IF EXISTS (SELECT Template.Template_Type_ID FROM Template WHERE Template.Template_Guid = @ProjectGuid AND (Template_Type_ID = 5 or Template_Type_ID = 4)) 
	BEGIN
		WITH ParentFragments (Template_Guid)
		AS
		(
			-- Anchor member definition
			SELECT	p.Template_Guid
			FROM	Xtf_Fragment_Dependency fd
					INNER JOIN Template p ON fd.Template_Guid = p.Template_Guid AND fd.Template_Version = p.Template_Version
			WHERE	fd.Fragment_Guid = @ProjectGuid
			UNION ALL
			-- Recursive member definition
			SELECT fd2.Template_Guid
			FROM Xtf_Fragment_Dependency fd2
				INNER JOIN Template p2 ON fd2.Template_Guid = p2.Template_Guid AND fd2.Template_Version = p2.Template_Version
				INNER JOIN ParentFragments AS fp ON fd2.Fragment_Guid = fp.Template_Guid
		)
		SELECT @HasMatchProjectVersionDependency = COUNT (*) 
		FROM ParentFragments
			INNER JOIN Template_Group ON ParentFragments.Template_Guid = Template_Group.Template_Guid
				OR ParentFragments.Template_Guid = Template_Group.Layout_Guid
				WHERE Template_Group.MatchProjectVersion = 1
	END
	ELSE
	BEGIN
		SET @HasMatchProjectVersionDependency = (SELECT COUNT(*) 
		FROM Template_Group 
		WHERE (Template_Group.Layout_Guid = @ProjectGuid OR Template_Group.Template_Guid = @ProjectGuid) 
				AND 
				Template_Group.MatchProjectVersion = 1)
	END

	IF @HasMatchProjectVersionDependency = 0
	BEGIN
		--delete the earliest minor version which does not belong to the next version number
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
						AND (FLOOR(vwTemplateVersion.Template_Version) < FLOOR(@NextVersion))) > 0)
		BEGIN

			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version 
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
						AND (FLOOR(vwTemplateVersion.Template_Version) < FLOOR(@NextVersion))
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END
			
		--otherwise	
		--delete earliest major version, leaving at least one major version untouched			
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 1) > 1)
		BEGIN

			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 1
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END

		--otherwise
		--delete the earliest left minor version
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0) > 0)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END

		DELETE FROM Xtf_Datasource_Dependency
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	vwTemplateVersion
					WHERE	Template_Guid = @ProjectGuid);

		DELETE FROM Xtf_ContentLibrary_Dependency
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	vwTemplateVersion
					WHERE	Template_Guid = @ProjectGuid);

		DELETE FROM Xtf_Fragment_Dependency
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	vwTemplateVersion
					WHERE	Template_Guid = @ProjectGuid);
				
		DELETE FROM Template_File_Version
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	vwTemplateVersion
					WHERE	Template_Guid = @ProjectGuid);

		DELETE FROM Template_Translation
		WHERE	Template_Guid = @ProjectGuid
				AND [Version] NOT IN (
					SELECT	Template_Version
					FROM	vwTemplateVersion
					WHERE	Template_Guid = @ProjectGuid);
	END

END
GO

ALTER PROCEDURE [dbo].[spProject_DefinitionByDate] (
	@ProjectGroupGuid uniqueidentifier,
	@ProjectGuid uniqueidentifier,
	@PublishedBy datetime
)
AS
SELECT TOP 1 * FROM(
	SELECT	Template.Template_Version, 
			CASE WHEN Template.EncryptedProjectDefinition IS NULL THEN 0 ELSE 1 END AS Encrypted,
			Template.EncryptedProjectDefinition,
			Template.Project_Definition
		FROM	Template_Group,
				Template 
		WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid
			AND Template.Template_Guid = @ProjectGuid
			AND (Template_Group.MatchProjectVersion = 0 
				OR Template.Modified_Date <= @PublishedBy)
	UNION ALL
		SELECT	Template_Version.Template_Version, 
			CASE WHEN Template_Version.EncryptedProjectDefinition IS NULL THEN 0 ELSE 1 END AS Encrypted,
			Template_Version.EncryptedProjectDefinition,
			Template_Version.Project_Definition
		FROM	Template_Group,
				Template_Version
		WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid
				AND Template_Version.Template_Guid = @ProjectGuid
				AND (Template_Group.MatchProjectVersion = 1 
							AND Template_Version.Modified_Date = (SELECT TOP 1 VersionDate.Modified_Date
								FROM Template_Version VersionDate
								WHERE VersionDate.Template_Guid = Template_Version.Template_Guid
									AND VersionDate.Modified_Date <= @PublishedBy
								ORDER BY VersionDate.Modified_Date DESC))
	) as T
GO
