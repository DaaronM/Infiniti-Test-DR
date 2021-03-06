truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.7.0.3');
go

ALTER procedure [dbo].[spProject_GetProjectsByContentItem]
	@ContentGuid varchar(40),
	@BusinessUnitGuid uniqueidentifier
as
	SET ARITHABORT ON 

	SELECT 	Template.template_id, 
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
			Template.FeatureFlags
	FROM	Template
		LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By
		INNER JOIN Xtf_ContentLibrary_Dependency on Xtf_ContentLibrary_Dependency.Template_Guid = Template.Template_Guid  AND
													Xtf_ContentLibrary_Dependency.Template_Version = Template.Template_Version
	WHERE	Template.Business_Unit_GUID = @BusinessUnitGuid
		AND Xtf_ContentLibrary_Dependency.Content_Object_Guid = @ContentGuid 
	ORDER BY Template.[name];

GO
ALTER procedure [dbo].[spLog_CompleteProjectLog]
	@LogGuid uniqueidentifier,
	@FinishDate datetime,
	@MessageXml xml = null,
	@UpdateRecent bit = 0
AS
	DECLARE @UserGuid uniqueidentifier;
	DECLARE @TemplateGroupGuid uniqueidentifier;
	
	SET NOCOUNT ON;

	SET @UserGuid = (SELECT User_Guid 
						FROM Template_Log
						INNER JOIN Intelledox_User ON Template_Log.[User_ID] = Intelledox_User.[User_ID]
						WHERE Log_Guid = @LogGuid);
	SET	@TemplateGroupGuid = (SELECT Template_Group_Guid 
								FROM Template_Log
								INNER JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
								WHERE Log_Guid = @LogGuid);

	UPDATE	Template_Log 
	SET		DateTime_Finish = @FinishDate, 
			Completed = 1,
			Messages = @MessageXml,
			InProgress = 0
	WHERE	Log_Guid = @LogGuid;
	
	
	If @UpdateRecent = 1
	BEGIN
		--update recent completed log
		UPDATE	Template_Recent
		SET		Log_Guid = @LogGuid
		WHERE	User_Guid = @UserGuid 
				AND Template_Group_Guid = @TemplateGroupGuid;
	END
GO
ALTER PROCEDURE [dbo].[spLibrary_GetBinary] (
	@UniqueId as uniqueidentifier,
	@VersionNumber as varchar(50),
	@PublishedBy as datetime
)
AS
	If @VersionNumber = '0'
	BEGIN
		IF @PublishedBy IS NULL
		BEGIN
			SELECT	cd.ContentData as [Binary]
			FROM	ContentData_Binary cd
					INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
			WHERE	ContentItem_Guid = @UniqueId
		END
		ELSE
		BEGIN
			SELECT	cd.ContentData as [Binary]
			FROM	ContentData_Binary cd
					INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
			WHERE	ContentItem_Guid = @UniqueId
				AND cd.Modified_Date <= @PublishedBy
			UNION
			SELECT	cd.ContentData as [Binary]
			FROM	ContentData_Binary_Version cd
					INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
					INNER JOIN ContentData_Binary ON ContentData_Binary.ContentData_Guid = Content_Item.ContentData_Guid
			WHERE	ContentItem_Guid = @UniqueId
					AND ContentData_Binary.Modified_Date > @PublishedBy
					AND cd.Modified_Date = 
						(SELECT MAX(LatestValidVersionBinary.Modified_Date)
						FROM ContentData_Binary_Version LatestValidVersionBinary
							INNER JOIN Content_Item LatestValidVersion ON LatestValidVersion.ContentData_Guid = LatestValidVersionBinary.ContentData_Guid
						WHERE LatestValidVersion.ContentItem_Guid = @UniqueId
							AND LatestValidVersionBinary.Modified_Date <= @PublishedBy);
		END
	END
	ELSE
	BEGIN
		SELECT	cd.ContentData as [Binary]
		FROM	ContentData_Binary cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId
				AND cd.ContentData_Version = @VersionNumber
		UNION ALL
		SELECT	cd.ContentData as [Binary]
		FROM	ContentData_Binary_Version cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId
				AND cd.ContentData_Version = @VersionNumber;
	END

GO
ALTER PROCEDURE [dbo].[spLibrary_GetText] (
	@UniqueId as uniqueidentifier,
	@VersionNumber as varchar(50),
	@PublishedBy As datetime
)
AS
	If @VersionNumber = '0'
	BEGIN
		IF @PublishedBy IS NULL
		BEGIN
			SELECT	cd.ContentData as [Text] 
			FROM	ContentData_Text cd
					INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
			WHERE	ContentItem_Guid = @UniqueId
		END
		ELSE
		BEGIN
			SELECT	cd.ContentData as [Text] 
			FROM	ContentData_Text cd
					INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
			WHERE	ContentItem_Guid = @UniqueId
				AND cd.Modified_Date <= @PublishedBy
			UNION
			SELECT	cd.ContentData as [Text]
			FROM	ContentData_Text_Version cd
					INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
					INNER JOIN ContentData_Text ON ContentData_Text.ContentData_Guid = Content_Item.ContentData_Guid
			WHERE	ContentItem_Guid = @UniqueId
					AND ContentData_Text.Modified_Date > @PublishedBy
					AND cd.Modified_Date = 
						(SELECT MAX(LatestValidVersionText.Modified_Date)
						FROM ContentData_Text_Version LatestValidVersionText
							INNER JOIN Content_Item LatestValidVersion ON LatestValidVersion.ContentData_Guid = LatestValidVersionText.ContentData_Guid
						WHERE LatestValidVersion.ContentItem_Guid = @UniqueId
							AND LatestValidVersionText.Modified_Date <= @PublishedBy);
		END
	END
	ELSE
	BEGIN
		SELECT	cd.ContentData as [Text] 
		FROM	ContentData_Text cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId
				AND cd.ContentData_Version = @VersionNumber
		UNION ALL
		SELECT	cd.ContentData as [Text] 
		FROM	ContentData_Text_Version cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId
				AND cd.ContentData_Version = @VersionNumber;
	END
GO
IF NOT EXISTS(SELECT Username FROM	Intelledox_User GROUP BY Username HAVING COUNT(*) > 1)
	DROP INDEX IX_Intelledox_User_Username ON dbo.Intelledox_User
GO
IF NOT EXISTS(SELECT Username FROM	Intelledox_User GROUP BY Username HAVING COUNT(*) > 1)
BEGIN
	CREATE UNIQUE NONCLUSTERED INDEX IX_Intelledox_User_Username ON dbo.Intelledox_User
		(
		Username
		)
END
GO
DROP PROC dbo.spUsers_UserLogin
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
	@IsGuest bit = 0,
	@ErrorCode int = 0 output
as
	SET NOCOUNT ON

	DECLARE @IdTable TABLE (ID INT);

	if @UserID = 0 OR @UserID IS NULL
	begin
		INSERT INTO Intelledox_User(Username, PwdHash, WinNT_User, Business_Unit_GUID, User_Guid, SelectedTheme, 
				ChangePassword, PwdSalt, PwdFormat, [Disabled], Address_ID, Timezone, Culture, Language, IsGuest, Invalid_Logon_Attempts, Password_Set_Utc, EulaAcceptanceUtc)
		OUTPUT Inserted.User_ID INTO @IdTable
		VALUES (@Username, @Password, @WinNT_User, @BusinessUnitGUID, @User_Guid, @SelectedTheme, 
				@ChangePassword, @PasswordSalt, @PasswordFormat, @Disabled, @Address_Id, @Timezone, @Culture, @Language, @IsGuest, @InvalidLogonAttempts, @PasswordSetUtc, @EulaAcceptedUtc);
		
		SET @NewID = (SELECT ID FROM @IdTable);

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
			Password_Set_Utc = @PasswordSetUtc,
			EulaAcceptanceUtc = @EulaAcceptedUtc
		WHERE [User_ID] = @UserID;
	end

	set @ErrorCode = @@error;

GO
