truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.0.0');
go
DROP PROC spSignoff_RemoveSignoff
GO
DROP PROC spSignoff_SignoffList
GO
DROP PROC spSignoff_UpdateSignoff
GO
ALTER procedure [dbo].[spUsers_RemoveUser]
	@UserGuid uniqueidentifier
AS
	DECLARE @UserId int;
	DECLARE @AddressId int;
	
	SELECT	@UserId = [User_Id], @AddressId = Address_ID
	FROM	Intelledox_User
	WHERE	User_Guid = @UserGuid;
	
	DELETE	Address_Book WHERE Address_ID = @AddressId;
	DELETE	User_Address_Book WHERE [User_Id] = @UserId;
	DELETE	User_Group_Subscription WHERE UserGuid = @UserGuid;
	DELETE	Intelledox_User WHERE User_Guid = @UserGuid;
GO
exec sp_rename 'dbo.User_Signoff', 'zzUser_Signoff'
GO
ALTER PROCEDURE [dbo].[spProject_UpdateDefinition] (
	@Xtf xml,
	@TemplateGuid uniqueidentifier,
	@EncryptedXtf varbinary(MAX)
)
AS
	DECLARE @FeatureFlags int;

	BEGIN TRAN
		-- Feature detection --
		SET @FeatureFlags = 0

		-- Workflow
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/Workflow/State/Transition)') as ProjectXML(P))
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 1;
		END

		-- Data source
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 2		-- Data field
						OR Q.value('@TypeId', 'int') = 9	-- Data table
						OR Q.value('@TypeId', 'int') = 12	-- Data list
						OR Q.value('@TypeId', 'int') = 14)	-- Data source
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 2;
		END

		-- Content library
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 11
						AND Q.value('@DisplayType', 'int') = 8) -- Existing content item
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 4;
		END
		
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 11
						AND Q.value('@DisplayType', 'int') = 4) -- Search
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 8;
		END

		-- Address
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 1)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 16;
		END

		-- Rich text
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 19)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 64;
		END
					
		IF @EncryptedXtf IS NULL
		BEGIN
			UPDATE	Template 
			SET		Project_Definition = @XTF,
					FeatureFlags = @FeatureFlags,
					EncryptedProjectDefinition = NULL
			WHERE	Template_Guid = @TemplateGuid;
		END
		ELSE
		BEGIN
			UPDATE	Template 
			SET		EncryptedProjectDefinition = @EncryptedXtf,
					FeatureFlags = @FeatureFlags,
					Project_Definition = NULL
			WHERE	Template_Guid = @TemplateGuid;
		END
	COMMIT
GO
UPDATE	Template
SET		FeatureFlags = FeatureFlags ^ 32
WHERE	FeatureFlags & 32 = 32;
GO
UPDATE	Template_Version
SET		FeatureFlags = FeatureFlags ^ 32
WHERE	FeatureFlags & 32 = 32;
GO
ALTER TABLE Template_Group
	ADD FeatureFlags Int not null default (0)
GO
ALTER PROCEDURE [dbo].[spProjectGroup_FolderListAll]
	@UserGuid uniqueidentifier,
	@FolderSearch nvarchar(50),
	@ProjectSearch nvarchar(100)
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid;

	SELECT	f.Folder_Name, tg.Template_Group_ID,
			tg.HelpText as TemplateGroup_HelpText, t.[Name] as Template_Name, 
			tg.Template_Group_Guid, tg.FeatureFlags
	FROM	Folder f
			INNER JOIN Template_Group tg on f.Folder_Guid = tg.Folder_Guid
			INNER JOIN Template t on tg.Template_Guid = t.Template_Guid
	WHERE	f.Business_Unit_GUID = @BusinessUnitGUID
			AND f.Folder_Guid IN (
				SELECT	Folder_Group.FolderGuid
				FROM	Folder_Group
						INNER JOIN User_Group_Subscription ON Folder_Group.GroupGuid = User_Group_Subscription.GroupGuid
				WHERE	User_Group_Subscription.UserGuid = @UserGuid
				)
			AND f.Folder_Name LIKE @FolderSearch + '%'
			AND t.Name LIKE @ProjectSearch + '%'
			AND (tg.EnforcePublishPeriod = 0 
				OR ((tg.PublishStartDate IS NULL OR tg.PublishStartDate < getdate())
					AND (tg.PublishFinishDate IS NULL OR tg.PublishFinishDate > getdate())))
GO
-- Update existing project groups
UPDATE	Template_Group
SET		Template_Group.FeatureFlags = t.NewFeatureFlags
FROM	(SELECT Content.Template_Group_Guid, 
				CASE WHEN Layout.FeatureFlags IS NULL THEN Content.FeatureFlags ELSE Content.FeatureFlags | Layout.FeatureFlags END NewFeatureFlags
			FROM (
				SELECT	Template_Group.Template_Group_Guid, 
						Template.Template_Guid,
						Template.FeatureFlags
				FROM	Template_Group
						INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid 
								AND (Template_Group.Template_Version IS NULL
									OR Template_Group.Template_Version = Template.Template_Version)
				UNION ALL
				SELECT	Template_Group.Template_Group_Guid, 
						Template_Version.Template_Guid, 
						Template_Version.FeatureFlags
				FROM	Template_Group
						INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
						INNER JOIN Template_Version ON (Template_Group.Template_Guid = Template_Version.Template_Guid 
								AND Template_Group.Template_Version = Template_Version.Template_Version)
				) Content
			LEFT JOIN (
				SELECT	Template_Group.Template_Group_Guid, 
						Template.Template_Guid,
						Template.FeatureFlags
				FROM	Template_Group
						INNER JOIN Template ON Template_Group.Layout_Guid = Template.Template_Guid
								AND (Template_Group.Layout_Version IS NULL
									OR Template_Group.Layout_Version = Template.Template_Version)
				UNION ALL
				SELECT	Template_Group.Template_Group_Guid,  
						Template_Version.Template_Guid,
						Template_Version.FeatureFlags
				FROM	Template_Group
						INNER JOIN Template_Version ON Template_Group.Layout_Guid = Template_Version.Template_Guid
								AND Template_Group.Layout_Version = Template_Version.Template_Version
			) Layout ON Content.Template_Group_Guid = Layout.Template_Group_Guid
) as t
WHERE	t.Template_Group_Guid = Template_Group.Template_Group_Guid
GO
CREATE PROCEDURE dbo.spProjectGroup_UpdateFeatureFlags
	@ProjectGroupGuid uniqueidentifier = null,
	@ProjectGuid uniqueidentifier = null
AS
	IF (@ProjectGuid is NULL)
	BEGIN
		-- Update a single group
		UPDATE	Template_Group
		SET		Template_Group.FeatureFlags = t.NewFeatureFlags
		FROM	(SELECT Content.Template_Group_Guid, 
						CASE WHEN Layout.FeatureFlags IS NULL THEN Content.FeatureFlags ELSE Content.FeatureFlags | Layout.FeatureFlags END NewFeatureFlags
					FROM (
						SELECT	Template_Group.Template_Group_Guid, 
								Template.Template_Guid,
								Template.FeatureFlags
						FROM	Template_Group
								INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid 
										AND (Template_Group.Template_Version IS NULL
											OR Template_Group.Template_Version = Template.Template_Version)
						UNION ALL
						SELECT	Template_Group.Template_Group_Guid, 
								Template_Version.Template_Guid, 
								Template_Version.FeatureFlags
						FROM	Template_Group
								INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
								INNER JOIN Template_Version ON (Template_Group.Template_Guid = Template_Version.Template_Guid 
										AND Template_Group.Template_Version = Template_Version.Template_Version)
						) Content
					LEFT JOIN (
						SELECT	Template_Group.Template_Group_Guid, 
								Template.Template_Guid,
								Template.FeatureFlags
						FROM	Template_Group
								INNER JOIN Template ON Template_Group.Layout_Guid = Template.Template_Guid
										AND (Template_Group.Layout_Version IS NULL
											OR Template_Group.Layout_Version = Template.Template_Version)
						UNION ALL
						SELECT	Template_Group.Template_Group_Guid,  
								Template_Version.Template_Guid,
								Template_Version.FeatureFlags
						FROM	Template_Group
								INNER JOIN Template_Version ON Template_Group.Layout_Guid = Template_Version.Template_Guid
										AND Template_Group.Layout_Version = Template_Version.Template_Version
					) Layout ON Content.Template_Group_Guid = Layout.Template_Group_Guid
		) as t
		WHERE	t.Template_Group_Guid = Template_Group.Template_Group_Guid
				AND Template_Group.Template_Group_Guid = @ProjectGroupGuid
	END
	ELSE
	BEGIN
		-- Update groups using a project
		UPDATE	Template_Group
		SET		Template_Group.FeatureFlags = t.NewFeatureFlags
		FROM	(	
					SELECT Content.Template_Group_Guid, Content.Template_Guid as ContentGuid, Layout.Template_Guid as LayoutGuid,
						CASE WHEN Layout.FeatureFlags IS NULL THEN Content.FeatureFlags ELSE Content.FeatureFlags | Layout.FeatureFlags END NewFeatureFlags
					FROM (
						SELECT	Template_Group.Template_Group_Guid, 
								Template.Template_Guid,
								Template.FeatureFlags
						FROM	Template_Group
								INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid 
										AND (Template_Group.Template_Version IS NULL
											OR Template_Group.Template_Version = Template.Template_Version)
						UNION ALL
						SELECT	Template_Group.Template_Group_Guid, 
								Template_Version.Template_Guid, 
								Template_Version.FeatureFlags
						FROM	Template_Group
								INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
								INNER JOIN Template_Version ON (Template_Group.Template_Guid = Template_Version.Template_Guid 
										AND Template_Group.Template_Version = Template_Version.Template_Version)
						) Content
					LEFT JOIN (
						SELECT	Template_Group.Template_Group_Guid, 
								Template.Template_Guid,
								Template.FeatureFlags
						FROM	Template_Group
								INNER JOIN Template ON Template_Group.Layout_Guid = Template.Template_Guid
										AND (Template_Group.Layout_Version IS NULL
											OR Template_Group.Layout_Version = Template.Template_Version)
						UNION ALL
						SELECT	Template_Group.Template_Group_Guid,  
								Template_Version.Template_Guid,
								Template_Version.FeatureFlags
						FROM	Template_Group
								INNER JOIN Template_Version ON Template_Group.Layout_Guid = Template_Version.Template_Guid
										AND Template_Group.Layout_Version = Template_Version.Template_Version
					) Layout ON Content.Template_Group_Guid = Layout.Template_Group_Guid
		) as t
		WHERE	t.Template_Group_Guid = Template_Group.Template_Group_Guid
				AND (Template_Group.Template_Guid = @ProjectGuid
					OR Template_Group.Layout_Guid = @ProjectGuid)
	END
GO
ALTER procedure [dbo].[spProject_RestoreVersion]
	@ProjectGuid uniqueidentifier,
	@VersionNumber nvarchar(10),
	@UserGuid uniqueidentifier,
	@RestoreVersionComment nvarchar(50),
	@NextVersion nvarchar(10)
as
	SET NOCOUNT ON

	BEGIN TRAN	
		DECLARE @BusinessUnitGuid uniqueidentifier;

		SELECT TOP 1 @BusinessUnitGuid = Business_Unit_Guid 
		FROM Template
		WHERE Template_Guid = @ProjectGuid;
	
		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Project_Definition,
			Comment,
			IsMajorVersion,
			FeatureFlags)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,	
			Template.Modified_By,
			Template.Project_Definition,
			Template.Comment,
			Template.IsMajorVersion,
			Template.FeatureFlags
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
			
		INSERT INTO Template_File_Version (Template_Guid, File_Guid, Template_Version, [Binary],
				FormatTypeId)
		SELECT	Template.Template_Guid, Template_File.File_Guid, Template.Template_Version, 
				Template_File.[Binary], Template_File.FormatTypeId
		FROM	Template
				INNER JOIN Template_File ON Template.Template_Guid = Template_File.Template_Guid
		WHERE	Template.Template_Guid = @ProjectGuid;
					
		DECLARE @ProjectDefinition xml,
				@FeatureFlags int

		SELECT	@ProjectDefinition = Project_Definition,
				@FeatureFlags = FeatureFlags
		FROM	Template_Version 
		WHERE	Template_Guid = @ProjectGuid 
				AND Template_Version = @VersionNumber

		UPDATE	Template
		SET		Project_Definition = @ProjectDefinition, 
				Template_Version = @NextVersion, 
				Comment = @RestoreVersionComment,
				Modified_Date = GetUTCdate(),
				Modified_By = @UserGuid,
				IsMajorVersion = 1,
				FeatureFlags = @FeatureFlags
		WHERE	Template_Guid = @ProjectGuid;
		
		DELETE FROM Template_File
		WHERE	Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File(Template_Guid, File_Guid, [Binary], FormatTypeId)
		SELECT	@ProjectGuid, Template_File_Version.File_Guid, Template_File_Version.[Binary],
				Template_File_Version.FormatTypeId
		FROM	Template_File_Version 
		WHERE	Template_Guid = @ProjectGuid 
				AND Template_Version = @VersionNumber; 
				
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
			
		DELETE FROM Template_File_Version
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	Template_Version
					WHERE	Template_Guid = @ProjectGuid);

		EXEC spProjectGroup_UpdateFeatureFlags @ProjectGuid=@ProjectGuid;
	COMMIT
GO
ALTER PROCEDURE [dbo].[spProject_UpdateDefinition] (
	@Xtf xml,
	@TemplateGuid uniqueidentifier,
	@EncryptedXtf varbinary(MAX)
)
AS
	DECLARE @FeatureFlags int;

	BEGIN TRAN
		-- Feature detection --
		SET @FeatureFlags = 0

		-- Workflow
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/Workflow/State/Transition)') as ProjectXML(P))
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 1;
		END

		-- Data source
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 2		-- Data field
						OR Q.value('@TypeId', 'int') = 9	-- Data table
						OR Q.value('@TypeId', 'int') = 12	-- Data list
						OR Q.value('@TypeId', 'int') = 14)	-- Data source
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 2;
		END

		-- Content library
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 11
						AND Q.value('@DisplayType', 'int') = 8) -- Existing content item
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 4;
		END
		
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 11
						AND Q.value('@DisplayType', 'int') = 4) -- Search
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 8;
		END

		-- Address
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 1)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 16;
		END

		-- Rich text
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 19)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 64;
		END
					
		IF @EncryptedXtf IS NULL
		BEGIN
			UPDATE	Template 
			SET		Project_Definition = @XTF,
					FeatureFlags = @FeatureFlags,
					EncryptedProjectDefinition = NULL
			WHERE	Template_Guid = @TemplateGuid;
		END
		ELSE
		BEGIN
			UPDATE	Template 
			SET		EncryptedProjectDefinition = @EncryptedXtf,
					FeatureFlags = @FeatureFlags,
					Project_Definition = NULL
			WHERE	Template_Guid = @TemplateGuid;
		END

		EXEC spProjectGroup_UpdateFeatureFlags @ProjectGuid=@TemplateGuid;
	COMMIT
GO
ALTER PROCEDURE [dbo].[spProjectGrp_UpdateProjectGroup]
	@ProjectGroupGuid uniqueidentifier,
	@HelpText nvarchar(4000),
	@AllowPreview bit,
	@WizardFinishText nvarchar(max),
	@PostGenerateText nvarchar(4000),
	@UpdateDocumentFields bit,
	@EnforceValidation bit,
	@HideNavigationPane bit,
	@EnforcePublishPeriod bit,
	@PublishStartDate datetime,
	@PublishFinishDate datetime,
	@ProjectGuid uniqueidentifier,
	@LayoutGuid uniqueidentifier,
	@ProjectVersion nvarchar(10),
	@LayoutVersion nvarchar(10),
	@FolderGuid uniqueidentifier
AS
	IF NOT EXISTS(SELECT * FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid)
	BEGIN
		INSERT INTO Template_Group (template_group_guid, helptext, AllowPreview, PostGenerateText, 
				UpdateDocumentFields, EnforceValidation, WizardFinishText, EnforcePublishPeriod,
				PublishStartDate, PublishFinishDate, HideNavigationPane, Template_Guid, Layout_Guid,
				Template_Version, Layout_Version, Folder_Guid)
		VALUES (@ProjectGroupGuid, @HelpText, @AllowPreview, @PostGenerateText, 
				@UpdateDocumentFields, @EnforceValidation, @WizardFinishText, @EnforcePublishPeriod,
				@PublishStartDate, @PublishFinishDate, @HideNavigationPane, @ProjectGuid, @LayoutGuid,
				@ProjectVersion, @LayoutVersion, @FolderGuid);
	END
	ELSE
	BEGIN
		UPDATE	Template_Group
		SET		HelpText = @HelpText,
				AllowPreview = @AllowPreview,
				PostGenerateText = @PostGenerateText,
				UpdateDocumentFields = @UpdateDocumentFields,
				EnforceValidation = @EnforceValidation,
				WizardFinishText = @WizardFinishText,
				EnforcePublishPeriod = @EnforcePublishPeriod,
				PublishStartDate = @PublishStartDate,
				PublishFinishDate = @PublishFinishDate,
				HideNavigationPane = @HideNavigationPane,
				Template_Guid = @ProjectGuid,
				Layout_Guid = @LayoutGuid,
				Template_Version = @ProjectVersion,
				Layout_Version = @LayoutVersion,
				Folder_Guid = @FolderGuid
		WHERE	Template_Group_Guid = @ProjectGroupGuid;
	END

	EXEC spProjectGroup_UpdateFeatureFlags @ProjectGroupGuid=@ProjectGroupGuid;
GO
CREATE PROCEDURE [dbo].[spUsers_UserByUsernameOrEmail]
	@UsernameOrEmail nvarchar(256),
	@ErrorCode int = 0 output

AS

BEGIN

	SELECT Intelledox_User.*, Email_Address
	FROM Intelledox_User
	LEFT JOIN Address_Book ON Intelledox_User.Address_ID = Address_Book.Address_ID
	WHERE Username = @UsernameOrEmail OR Email_Address = @UsernameOrEmail
	AND Disabled = 0;

	SET @ErrorCode = @@ERROR;	
END
GO
CREATE PROCEDURE [dbo].[spUser_UpdatePassword]
	@UserGuid uniqueidentifier,
	@PasswordHash varchar(1000),
	@PasswordSalt nvarchar(128),
	@ErrorCode int = 0 output
	
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE Intelledox_User
	SET pwdhash = @PasswordHash,
		ChangePassword = 1,
		PwdFormat = 2,
		PwdSalt = @PasswordSalt
	WHERE User_Guid = @UserGuid;
END
GO




