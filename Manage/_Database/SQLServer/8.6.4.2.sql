truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.4.2');
go

ALTER procedure [dbo].[spTemplate_RemoveTemplate]
	@TemplateGuid uniqueidentifier,
	@OnlyChildInfo bit
as
	IF @OnlyChildInfo = 0
	BEGIN
		DELETE	template_Group
		WHERE	template_guid = @TemplateGuid
			OR	layout_guid = @TemplateGuid;

		DELETE	User_Group_Template
		WHERE	TemplateGuid = @TemplateGuid;
	END
	
	DELETE	Template_File
	WHERE	Template_Guid = @TemplateGuid;
	
	DELETE	Template
	WHERE	Template_Guid = @TemplateGuid;
	
	DELETE	Template_File_Version
	WHERE	Template_Guid = @TemplateGuid;
	
	DELETE	Template_Version
	WHERE	Template_Guid = @TemplateGuid;

	DELETE  Xtf_Datasource_Dependency
	WHERE	Template_Guid = @TemplateGuid;

	DELETE  Xtf_ContentLibrary_Dependency
	WHERE	Template_Guid = @TemplateGuid;


GO

ALTER PROCEDURE [dbo].[spProject_UpdateDefinition] (
	@Xtf xml,
	@TemplateGuid uniqueidentifier,
	@EncryptedXtf varbinary(MAX)
)
AS
	DECLARE @FeatureFlags int;
	DECLARE @DataObjectGuid uniqueidentifier;
	DECLARE @XtfVersion nvarchar(10)

	BEGIN TRAN
		-- Feature detection --
		SET @FeatureFlags = 0
		SELECT @XtfVersion = Template.Template_Version FROM Template WHERE Template.Template_Guid = @TemplateGuid

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

			INSERT INTO [dbo].[Xtf_Datasource_Dependency](Template_Guid, Template_Version, Data_Object_Guid)
			SELECT DISTINCT @TemplateGuid,
					@XtfVersion,
					Q.value('@DataObjectGuid', 'uniqueidentifier')
			FROM 
				@Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question)') as QuestionXML(Q)
			WHERE Q.value('@DataObjectGuid', 'uniqueidentifier') is not null
				AND (SELECT  COUNT(*)
				FROM    [Xtf_Datasource_Dependency] 
				WHERE   [Template_Guid] = @TemplateGuid
				AND     [Template_Version] = @XtfVersion 
				AND		[Data_Object_Guid] = Q.value('@DataObjectGuid', 'uniqueidentifier')) = 0
			
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

		BEGIN

		CREATE TABLE #ContentQuestionExisting
		(
			Id int identity(1,1),
			TemplateGuid uniqueidentifier,
			TemplateVersion nvarchar(10),
			ContentObjectGuid uniqueidentifier
		);

		INSERT INTO #ContentQuestionExisting(TemplateGuid, TemplateVersion, ContentObjectGuid)
		SELECT @TemplateGuid,
			   @XtfVersion,
			   C.value('@Id', 'uniqueidentifier')
		FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question/Answer/ContentItem)') as ContentItemXML(C)
			

		INSERT INTO #ContentQuestionExisting(TemplateGuid, TemplateVersion, ContentObjectGuid)
		SELECT @TemplateGuid,
			   @XtfVersion,
			   Q.value('@ContentItemGuid', 'uniqueidentifier')
		FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question)') as QuestionXML(Q)
		WHERE Q.value('@ContentItemGuid', 'uniqueidentifier') is not null
			
		INSERT INTO [dbo].[Xtf_ContentLibrary_Dependency](Template_Guid, Template_Version, Content_Object_Guid)
		SELECT r.TemplateGuid,
				r.TemplateVersion,
				r.ContentObjectGuid
		FROM #ContentQuestionExisting r
		WHERE NOT EXISTS (
			SELECT 1
			FROM [Xtf_ContentLibrary_Dependency]
			WHERE [Xtf_ContentLibrary_Dependency].Content_Object_Guid = r.ContentObjectGuid AND
				  [Xtf_ContentLibrary_Dependency].Template_Guid = r.TemplateGuid AND
				  [Xtf_ContentLibrary_Dependency].Template_Version = r.TemplateVersion
		)
		GROUP BY r.ContentObjectGuid, r.TemplateGuid, r.TemplateVersion

		DROP TABLE #ContentQuestionExisting

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
			
		-- Custom Question
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 22)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 128;
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

ALTER procedure [dbo].[spProject_GetProjectsByContentItem]
	@ContentGuid varchar(40),
	@BusinessUnitGuid uniqueidentifier
as
	SET ARITHABORT ON 

	SELECT 	Template.template_id, 
			Template.[name] as project_name, 
			Template.template_type_id, 
			Template.fax_template_id, 
			Template.template_guid, 
			Template.template_version, 
			Template.import_date,
			Template.Business_Unit_GUID, 
			Template.Supplier_Guid,
			Template.Content_Bookmark,
			Template.Modified_Date,
			Intelledox_User.Username,
			Template.Modified_By,
			Template.FeatureFlags
	FROM	Template
		LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By
		LEFT JOIN Xtf_ContentLibrary_Dependency on Xtf_ContentLibrary_Dependency.Template_Guid = Template.Template_Guid
	WHERE	Template.Business_Unit_GUID = @BusinessUnitGuid
		AND Xtf_ContentLibrary_Dependency.Content_Object_Guid = @ContentGuid 
		AND Xtf_ContentLibrary_Dependency.Template_Version = Template.template_version
	ORDER BY Template.[name];
GO

ALTER procedure [dbo].[spLibrary_ApproveVersion]
	@ContentItemGuid uniqueidentifier,
	@VersionNumber int,
	@UserGuid uniqueidentifier,
	@ExpiryDate datetime
as
	SET NOCOUNT ON
	
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @IsBinary bit
	DECLARE @IsCurrentVersion int
	
	SELECT	@ContentData_Guid = ContentData_Guid, 
			@IsBinary = CASE WHEN ContentType_Id = 2 THEN 0 ELSE 1 END
	FROM	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;
	
	IF (@IsBinary = 1)
	BEGIN
		SELECT	@IsCurrentVersion = COUNT(*)
		FROM	ContentData_Binary
		WHERE	ContentData_Guid = @ContentData_Guid
				AND ContentData_Version = @VersionNumber;
	END
	ELSE
	BEGIN
		SELECT	@IsCurrentVersion = COUNT(*)
		FROM	ContentData_Text
		WHERE	ContentData_Guid = @ContentData_Guid
				AND ContentData_Version = @VersionNumber;
	END
		
	BEGIN TRAN	

	IF (@IsCurrentVersion = 0)
	BEGIN
		IF (@IsBinary = 1)
		BEGIN
			--Archive current version
			INSERT INTO ContentData_Binary_Version 
				(ContentData_Version, 
				ContentData_Guid, 
				ContentData,
				FileType,
				Modified_Date, 
				Modified_By,
				Approved)
			SELECT ContentData_Binary.ContentData_Version,
				ContentData_Binary.ContentData_Guid,
				ContentData_Binary.ContentData,
				ContentData_Binary.FileType,
				ContentData_Binary.Modified_Date,
				ContentData_Binary.Modified_By,
				Content_Item.Approved
			FROM	ContentData_Binary
					INNER JOIN Content_Item ON ContentData_Binary.ContentData_Guid = Content_Item.ContentData_Guid
			WHERE	ContentData_Binary.ContentData_Guid = @ContentData_Guid;
			
			--Copy approved version into current
			UPDATE	ContentData_Binary
			SET		ContentData = ContentData_Binary_Version.ContentData, 
					FileType = ContentData_Binary_Version.FileType,
					ContentData_Version = @VersionNumber,
					Modified_Date = ContentData_Binary_Version.Modified_Date,
					Modified_By = ContentData_Binary_Version.Modified_By
			FROM	ContentData_Binary, 
					ContentData_Binary_Version
			WHERE	ContentData_Binary.ContentData_Guid = @ContentData_Guid
					AND ContentData_Binary_Version.ContentData_Guid = @ContentData_Guid 
					AND	ContentData_Binary_Version.ContentData_Version = @VersionNumber;
			
			--Delete the version as it is now current
			DELETE FROM ContentData_Binary_Version
			WHERE	ContentData_Binary_Version.ContentData_Guid = @ContentData_Guid 
					AND	ContentData_Binary_Version.ContentData_Version = @VersionNumber;
		END
		ELSE
		BEGIN
			--Archive current version
			INSERT INTO ContentData_Text_Version 
				(ContentData_Version, 
				ContentData_Guid, 
				ContentData,
				Modified_Date, 
				Modified_By,
				Approved)
			SELECT ContentData_Text.ContentData_Version,
				ContentData_Text.ContentData_Guid,
				ContentData_Text.ContentData,
				ContentData_Text.Modified_Date,
				ContentData_Text.Modified_By,
				Content_Item.Approved
			FROM	ContentData_Text
					INNER JOIN Content_Item ON ContentData_Text.ContentData_Guid = Content_Item.ContentData_Guid
			WHERE ContentData_Text.ContentData_Guid = @ContentData_Guid;
			
			--Copy approved version into current
			UPDATE	ContentData_Text
			SET		ContentData = ContentData_Text_Version.ContentData, 
					ContentData_Version = @VersionNumber, 
					Modified_Date = ContentData_Text_Version.Modified_Date,
					Modified_By = ContentData_Text_Version.Modified_By
			FROM	ContentData_Text, 
					ContentData_Text_Version
			WHERE	ContentData_Text.ContentData_Guid = @ContentData_Guid
					AND ContentData_Text_Version.ContentData_Guid = @ContentData_Guid 
					AND	ContentData_Text_Version.ContentData_Version = @VersionNumber;
			
			--Delete the version as it is now current
			DELETE FROM ContentData_Text_Version
			WHERE	ContentData_Text_Version.ContentData_Guid = @ContentData_Guid 
					AND	ContentData_Text_Version.ContentData_Version = @VersionNumber;
		END
	END
		
	UPDATE	Content_Item
	SET		Approved = 2,
			IsIndexed = 0,
			ExpiryDate = @ExpiryDate
	WHERE	ContentData_Guid = @ContentData_Guid;
	
	DELETE	Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItemGuid;
	
	IF (SELECT COUNT(*)
		FROM	Template
			INNER JOIN Template_Group ON Template_Group.Layout_Guid = Template.Template_Guid OR Template_Group.Template_Guid = Template.Template_Guid
			INNER JOIN Xtf_ContentLibrary_Dependency on Xtf_ContentLibrary_Dependency.Template_Guid = Template.Template_Guid
		WHERE	Template_Group.MatchProjectVersion = 1
			AND Xtf_ContentLibrary_Dependency.Content_Object_Guid = @ContentItemGuid) = 0
	BEGIN
		EXEC spLibrary_ClearExcessVersions @ContentData_Guid, @IsBinary;
	END
	
	COMMIT
GO
