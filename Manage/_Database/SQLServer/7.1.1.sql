/*
** Database Update package 7.1.1
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.1.1')
go

--1959
DROP PROCEDURE spUsers_SetPassword
GO


--1960
ALTER TABLE JobDefinition
	ADD WatchFolder nvarchar(300) null,
		DataSourceGuid uniqueidentifier null
GO
ALTER PROCEDURE [dbo].[spJob_CreateJobDefinition](
	@JobDefinitionId uniqueidentifier,
	@Name nvarchar(200),
	@IsEnabled bit,
	@OwnerGuid uniqueidentifier,
	@DateCreated datetime,
	@DateModified datetime,
	@JobDefinition xml,
	@NextRunDate datetime,
	@WatchFolder nvarchar(300),
	@DataSourceGuid uniqueidentifier
)
AS
	INSERT INTO JobDefinition(JobDefinitionId, Name, NextRunDate, IsEnabled, OwnerGuid, DateCreated, 
		DateModified, JobDefinition, WatchFolder, DataSourceGuid)
	VALUES (@JobDefinitionId, @Name, @NextRunDate, @IsEnabled, @OwnerGuid, @DateCreated, 
		@DateModified, @JobDefinition, @WatchFolder, @DataSourceGuid);
GO
ALTER PROCEDURE [dbo].[spJob_LodgeJob] (
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier,
	@DateStarted datetime,
	@ProjectGroupGuid uniqueidentifier,
	@LogGuid uniqueidentifier,
	@JobDefinitionGuid uniqueidentifier,
	@InitialStatus int
)
AS
	IF (@ProjectGroupGuid IS NULL AND @JobDefinitionGuid IS NOT NULL)
	BEGIN
		SELECT	@ProjectGroupGuid = JobDefinition.value('data(AnswerFile/HeaderInfo/TemplateInfo/@TemplateGroupGuid)[1]', 'uniqueidentifier')
		FROM	JobDefinition
		WHERE	JobDefinitionId = @JobDefinitionGuid;
	END

	INSERT INTO ProcessJob(JobId, UserGuid, DateStarted, ProjectGroupGuid, CurrentStatus, LogGuid, JobDefinitionGuid)
	VALUES (@JobId, @UserGuid, @DateStarted, @ProjectGroupGuid, @InitialStatus, @LogGuid, @JobDefinitionGuid);
GO
ALTER PROCEDURE [dbo].[spJob_Queued]
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus,
			ProcessJob.LogGuid, ProcessJob.JobDefinitionGuid
	FROM	ProcessJob
	WHERE	ProcessJob.CurrentStatus = 1
	ORDER BY ProcessJob.DateStarted DESC;
GO

--1961
ALTER TABLE dbo.Content_Item ADD
	ExpiryDate datetime NULL;
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
	
	COMMIT

GO

ALTER procedure [dbo].[spContent_ContentItemList]
	@ItemGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier,
	@ExactMatch bit,
	@ContentTypeId int,
	@Name NVarChar(255),
	@Description NVarChar(1000),
	@Category int,
	@Approved int = 2,
	@ErrorCode int output,
	@FolderGuid uniqueidentifier,
	@UserId uniqueidentifier,
	@NoFolder bit
as
	UPDATE Content_Item
	SET Approved = 1
	WHERE ExpiryDate < GETUTCDATE();

	IF @ItemGuid is null 
		IF @ExactMatch = 1
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
								INNER JOIN Intelledox_User ON User_Group_Subscription.User_ID = Intelledox_User.User_ID
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit,
					ci.FolderGuid,
					Content_Folder.FolderName
					
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity = @Name
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
			ORDER BY ci.NameIdentity;
		ELSE
			SELECT DISTINCT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
								INNER JOIN Intelledox_User ON User_Group_Subscription.User_ID = Intelledox_User.User_ID
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit,
					ci.FolderGuid,
					Content_Folder.FolderName
					
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
						
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity LIKE '%' + @Name + '%'
					AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND ci.Description LIKE '%' + @Description + '%'
					AND (@Category = 0 or ci.Category = @Category)
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
					AND ((@NoFolder = 0 AND (@FolderGuid IS NULL OR ci.FolderGuid = @FolderGuid))
						OR (@NoFolder = 1 AND ci.FolderGuid IS NULL))
			ORDER BY ci.ContentType_Id,
					ci.NameIdentity;
	ELSE
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Intelledox_User.UserName,
				CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
				CASE WHEN (@UserId IS NULL 
					OR ci.FolderGuid IS NULL 
					OR (NOT EXISTS (
						SELECT * 
						FROM Content_Folder_Group 
						WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
					OR EXISTS (
						SELECT * 
						FROM Content_Folder_Group
							INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
							INNER JOIN User_Group_Subscription ON User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
							INNER JOIN Intelledox_User ON User_Group_Subscription.User_ID = Intelledox_User.User_ID
						WHERE Intelledox_User.User_Guid = @UserId
							AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
				THEN 1 ELSE 0 END
				AS CanEdit,
				ci.FolderGuid,
				Content_Folder.FolderName
					
		FROM	content_item ci
				LEFT JOIN (
					SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
					FROM	ContentData_Binary
					UNION
					SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
					FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
				LEFT JOIN (
					SELECT	ContentData_Guid
					FROM	vwContentItemVersionDetails
					WHERE	Approved = 0
					) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
				LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
		WHERE	ci.contentitem_guid = @ItemGuid;
	
	set @ErrorCode = @@error;

GO


ALTER procedure [dbo].[spContent_ContentItemListFullText]
	@ItemGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier,
	@ExactMatch bit,
	@ContentTypeId int,
	@Name NVarChar(255),
	@Description NVarChar(1000),
	@Category int,
	@FullText NVarChar(1000),
	@Approved int = 2,
	@ErrorCode int output,
	@FolderGuid uniqueidentifier,
	@UserId uniqueidentifier,
	@NoFolder bit
as

	UPDATE Content_Item
	SET Approved = 1
	WHERE ExpiryDate < GETUTCDATE();

	IF @ItemGuid is null 
		IF @ExactMatch = 1
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
								INNER JOIN Intelledox_User ON User_Group_Subscription.User_ID = Intelledox_User.User_ID
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit,
					Content_Folder.FolderName
					
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity = @Name
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
			ORDER BY ci.NameIdentity;
		ELSE
			--Full text search
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
								INNER JOIN Intelledox_User ON User_Group_Subscription.User_ID = Intelledox_User.User_ID
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit,
					Content_Folder.FolderName
					
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity LIKE '%' + @Name + '%'
					AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND ci.Description LIKE '%' + @Description + '%'
					AND (@Category = 0 or ci.Category = @Category)
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
					AND (ci.ContentData_Guid IN (
							SELECT	ContentData_Guid
							FROM	ContentData_Binary cdb
							WHERE	Contains(*, @FullText)
							)
						OR
						ci.ContentData_Guid IN (
							SELECT	ContentData_Guid
							FROM	ContentData_Text cdt
							WHERE	Contains(*, @FullText)
							)
						)
					AND ((@NoFolder = 0 AND (@FolderGuid IS NULL OR ci.FolderGuid = @FolderGuid))
						OR (@NoFolder = 1 AND ci.FolderGuid IS NULL))
			ORDER BY ci.NameIdentity;
	ELSE
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Intelledox_User.UserName,
				CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
				CASE WHEN (@UserId IS NULL 
					OR ci.FolderGuid IS NULL 
					OR (NOT EXISTS (
						SELECT * 
						FROM Content_Folder_Group 
						WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
					OR EXISTS (
						SELECT * 
						FROM Content_Folder_Group
							INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
							INNER JOIN User_Group_Subscription ON User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
							INNER JOIN Intelledox_User ON User_Group_Subscription.User_ID = Intelledox_User.User_ID
						WHERE Intelledox_User.User_Guid = @UserId
							AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
				THEN 1 ELSE 0 END
				AS CanEdit,
				Content_Folder.FolderName
					
		FROM	content_item ci
				LEFT JOIN (
					SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
					FROM	ContentData_Binary
					UNION
					SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
					FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
				LEFT JOIN (
					SELECT	ContentData_Guid
					FROM	vwContentItemVersionDetails
					WHERE	Approved = 0
					) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
				LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
		WHERE	ci.contentitem_guid = @ItemGuid;
	
	set @ErrorCode = @@error;

GO

ALTER procedure [dbo].[spLibrary_GetContentVersions]
	@ContentItemGuid uniqueidentifier
as
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @Approved Int
	DECLARE @ExpiryDate datetime
	
	UPDATE Content_Item
	SET Approved = 1
	WHERE ExpiryDate < GETUTCDATE()
		And ContentItem_Guid = @ContentItemGuid;

	SELECT	@ContentData_Guid = ContentData_Guid, @Approved = Approved, @ExpiryDate = ExpiryDate
	FROM	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;

	SELECT	ContentData_Version, Modified_Date, Intelledox_User.Username,
			Approved, ExpiryDate
	FROM	(SELECT	ContentData_Guid, 
				Modified_Date, 
				Modified_By, 
				ContentData_Version, 
				@Approved as Approved, 
				@ExpiryDate AS ExpiryDate
			FROM	ContentData_Binary
			UNION
			SELECT	ContentData_Guid, 
				Modified_Date, 
				Modified_By, 
				ContentData_Version, 
				Approved, 
				NULL AS ExpiryDate
			FROM	ContentData_Binary_Version
			UNION
			SELECT	ContentData_Guid, 
				Modified_Date, 
				Modified_By, 
				ContentData_Version, 
				@Approved as Approved, 
				@ExpiryDate AS ExpiryDate
			FROM	ContentData_Text
			UNION
			SELECT	ContentData_Guid, 
				Modified_Date, 
				Modified_By, 
				ContentData_Version, 
				Approved, 
				NULL AS ExpiryDate
			FROM	ContentData_Text_Version) Versions
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Versions.Modified_By
	WHERE	ContentData_Guid = @ContentData_Guid
	ORDER BY ContentData_Version DESC;

GO

--1962
ALTER PROCEDURE [dbo].[spLibrary_UpdateText] (
	@UniqueId as uniqueidentifier,
	@ContentData as nvarchar(max),
	@UserGuid as uniqueidentifier
)
AS
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @Approvals nvarchar(10)
	DECLARE @MaxVersion int

	SELECT	@ContentData_Guid = ContentData_Guid
	FROM	Content_Item
	WHERE	ContentItem_Guid = @UniqueId
	
	SELECT	@Approvals = OptionValue
	FROM	Global_Options
	WHERE	OptionCode = 'REQUIRE_CONTENT_APPROVAL';


	IF (@Approvals = 'true')
	BEGIN
		IF @ContentData_Guid IS NULL OR NOT EXISTS(SELECT ContentData_Guid 
												FROM ContentData_Text 
												WHERE	ContentData_Guid = @ContentData_Guid)
		BEGIN
			SET	@ContentData_Guid = newid();
			
			INSERT INTO ContentData_Text(ContentData_Guid, ContentData, ContentData_Version, Modified_Date, Modified_By)
			VALUES (@ContentData_Guid, @ContentData, 1, getUTCdate(), @UserGuid)

			UPDATE	Content_Item
			SET		ContentData_Guid = @ContentData_Guid,
					Approved = 0
			WHERE	ContentItem_Guid = @UniqueId;
		END
		ELSE
		BEGIN
			SELECT	@MaxVersion = MAX(ContentData_Version)
			FROM	(SELECT ContentData_Version
					FROM	ContentData_Text_Version
					WHERE	ContentData_Guid = @ContentData_Guid
					UNION
					SELECT	ContentData_Version
					FROM	ContentData_Text
					WHERE	ContentData_Guid = @ContentData_Guid) Versions

			-- Expire old unapproved versions
			UPDATE	ContentData_Text_Version
			SET		Approved = 1
			WHERE	ContentData_Guid = @ContentData_Guid
					AND Approved = 0;
		
			-- Insert new unapproved version
			INSERT INTO ContentData_Text_Version(ContentData_Guid, ContentData, ContentData_Version, Modified_Date, Modified_By, Approved)
			VALUES (@ContentData_Guid, @ContentData, IsNull(@MaxVersion, 0) + 1, getUTCdate(), @UserGuid, 0);
			
			EXEC spLibrary_ClearExcessVersions @ContentData_Guid, 0;
		END
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT ContentData_Guid FROM ContentData_Text WHERE ContentData_Guid = @ContentData_Guid)
		BEGIN
			EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 0;
			
			UPDATE	ContentData_Text
			SET		ContentData = @ContentData
			WHERE	ContentData_Guid = @ContentData_Guid
		END
		ELSE
		BEGIN
			SET	@ContentData_Guid = newid()

			INSERT INTO ContentData_Text(ContentData_Guid, ContentData, ContentData_Version)
			VALUES (@ContentData_Guid, @ContentData, 0)

			UPDATE	Content_Item
			SET		ContentData_Guid = @ContentData_Guid
			WHERE	ContentItem_Guid = @UniqueId
		END
		
		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE	ContentData_Text
			SET		Modified_Date = getUTCdate(),
					Modified_By = @UserGuid,
					ContentData_Version = ContentData_Version + 1
			WHERE	ContentData_Guid = @ContentData_Guid;
		END
	END
GO


--1964
ALTER TABLE dbo.Template_Group ADD
	EnforcePublishPeriod bit NULL,
	PublishStartDate datetime NULL,
	PublishFinishDate datetime NULL
GO

ALTER PROCEDURE [dbo].[spProjectGrp_UpdateProjectGroup]
	@ProjectGroupGuid uniqueidentifier,
	@Name nvarchar(100),
	@HelpText nvarchar(4000),
	@AllowPreview bit,
	@WizardFinishText nvarchar(max),
	@PostGenerateText nvarchar(4000),
	@UpdateDocumentFields bit,
	@EnforceValidation bit,
	@EnforcePublishPeriod bit,
	@PublishStartDate datetime,
	@PublishFinishDate datetime
AS
	IF NOT EXISTS(SELECT * FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid)
	BEGIN
		INSERT INTO Template_Group ([name], template_group_guid, helptext, AllowPreview, PostGenerateText, 
				UpdateDocumentFields, EnforceValidation, WizardFinishText, EnforcePublishPeriod,
				PublishStartDate, PublishFinishDate)
		VALUES (@Name, @ProjectGroupGuid, @HelpText, @AllowPreview, @PostGenerateText, 
				@UpdateDocumentFields, @EnforceValidation, @WizardFinishText, @EnforcePublishPeriod,
				@PublishStartDate, @PublishFinishDate);
	END
	ELSE
	BEGIN
		UPDATE	Template_Group
		SET		[Name] = @Name,
				HelpText = @HelpText,
				AllowPreview = @AllowPreview,
				PostGenerateText = @PostGenerateText,
				UpdateDocumentFields = @UpdateDocumentFields,
				EnforceValidation = @EnforceValidation,
				WizardFinishText = @WizardFinishText,
				EnforcePublishPeriod = @EnforcePublishPeriod,
				PublishStartDate = @PublishStartDate,
				PublishFinishDate = @PublishFinishDate
		WHERE	Template_Group_Guid = @ProjectGroupGuid;
	END
GO

ALTER PROCEDURE [dbo].[spProjectGrp_ProjectGroupList]
      @ProjectGroupGuid uniqueidentifier
AS
    SELECT	a.Template_Group_ID, a.[Name] as Template_Group_Name, a.template_group_guid, 
			a.helptext as TemplateGroup_HelpText, b.template_guid, b.Layout_Guid,
			b.Template_Version, b.Layout_Version, a.AllowPreview, a.PostGenerateText,
			a.UpdateDocumentFields, a.EnforceValidation, a.WizardFinishText, 
			a.EnforcePublishPeriod, a.PublishStartDate, a.PublishFinishDate
    FROM	Template_Group a
			LEFT JOIN Template_Group_Item b on a.template_group_id = b.template_group_id
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;
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
	
	SELECT	DISTINCT a.*, d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, b.Template_ID, b.[Name] as Template_Name, 
			b.Template_Type_ID, d.Template_Group_Guid
	FROM	Folder a
			INNER JOIN Folder_Template c on a.Folder_ID = c.Folder_ID
			INNER JOIN Template_Group d on c.folderitem_ID = d.Template_Group_ID and itemtype_id = 1
			INNER JOIN Template_Group_Item e on d.Template_Group_ID = e.Template_Group_ID
			INNER JOIN Template b on e.Template_ID = b.Template_ID
	WHERE	a.Business_Unit_GUID = @BusinessUnitGUID
			AND a.Folder_Guid IN (
				SELECT	Folder_Group.FolderGuid
				FROM	Folder_Group
						INNER JOIN User_Group ON Folder_Group.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Subscription ON User_Group.User_Group_Id = 

User_Group_Subscription.User_Group_Id
						INNER JOIN Intelledox_User ON User_Group_Subscription.User_Id = Intelledox_User.User_Id
				WHERE	Intelledox_User.User_Guid = @UserGuid
				)
			AND a.Folder_Name LIKE @FolderSearch + '%'
			AND CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END LIKE @ProjectSearch + '%'
			AND (d.EnforcePublishPeriod = 0 
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getutcdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getutcdate())))
	ORDER BY a.Folder_Name, a.Folder_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END;
GO

ALTER PROCEDURE [dbo].[spProjectGrp_ProjectGroupListByFolder]
	@FolderGuid uniqueidentifier,
	@IncludeRestricted bit
AS
	SELECT	d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, d.Template_Group_Guid,
			b.Template_Guid, e.Layout_Guid
	FROM	Folder a
			INNER JOIN Folder_Template c on a.Folder_ID = c.Folder_ID
			INNER JOIN Template_Group d on c.folderitem_ID = d.Template_Group_ID and itemtype_id = 1
			INNER JOIN Template_Group_Item e on d.Template_Group_ID = e.Template_Group_ID
			INNER JOIN Template b on e.Template_ID = b.Template_ID
	WHERE	a.Folder_Guid = @FolderGuid
			AND ((d.EnforcePublishPeriod = 0 OR @IncludeRestricted = 1)
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getutcdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getutcdate())))
	ORDER BY d.[Name], b.[Name], c.folderitem_id;
GO

ALTER PROCEDURE [dbo].[spProjectGroup_Recent]
	@UserGuid uniqueidentifier,
	@ProjectSearch nvarchar(100)
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid;
	
	SELECT	DISTINCT d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, b.Template_ID, b.[Name] as Template_Name, 
			b.Template_Type_ID, d.Template_Group_Guid, l.DateTime_Start
	FROM	Folder a
			INNER JOIN Folder_Template c on a.Folder_ID = c.Folder_ID
			INNER JOIN Template_Group d on c.folderitem_ID = d.Template_Group_ID and itemtype_id = 1
			INNER JOIN Template_Group_Item e on d.Template_Group_Guid = e.Template_Group_Guid
			INNER JOIN Template b on e.Template_Guid = b.Template_Guid
			INNER JOIN Template_Recent l on d.Template_Group_Guid = l.Template_Group_Guid
	WHERE	a.Business_Unit_GUID = @BusinessUnitGUID
			AND a.Folder_Guid IN (
				SELECT	Folder_Group.FolderGuid
				FROM	Folder_Group
						INNER JOIN User_Group ON Folder_Group.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Subscription ON User_Group.User_Group_Id = 

User_Group_Subscription.User_Group_Id
						INNER JOIN Intelledox_User ON User_Group_Subscription.User_Id = Intelledox_User.User_Id
				WHERE	Intelledox_User.User_Guid = @UserGuid
				)
			AND CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END LIKE @ProjectSearch + '%'
			AND l.[User_Guid] = @UserGuid
			AND (d.EnforcePublishPeriod = 0 
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getutcdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getutcdate())))
	ORDER BY l.DateTime_Start DESC;
GO

ALTER procedure [dbo].[spAudit_AnswerFileList]
	@AnswerFile_ID int = 0,
	@User_Guid uniqueidentifier = null,
	@InProgress char(1) = '0',
	@TemplateGroupGuid uniqueidentifier = null,
	@ErrorCode int output
AS
	DECLARE @User_Id Int
	
	set nocount on
	
	IF (@User_Guid IS NOT NULL)
	BEGIN
		SELECT	@User_Id = User_Id
		FROM	Intelledox_User
		WHERE	User_Guid = @User_Guid;
	END

	if @AnswerFile_ID = 0 or @AnswerFile_ID is null
    begin
		if @TemplateGroupGuid is null
			select	ans.AnswerFile_Id, ans.User_Id, ans.Template_Group_Id, ans.Description, 
					ans.RunDate, ans.InProgress, 
					T.Name as TemplateGroup_Name, Template_Group.Template_Group_Guid,
					Intelledox_User.User_Guid
			from	answer_file ans
					INNER JOIN Template_Group on ans.Template_Group_ID = Template_Group.Template_Group_ID
					INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
					INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
					INNER JOIN Intelledox_User ON ans.User_Id = Intelledox_User.User_ID
			where Ans.[user_ID] = @user_id
				AND Ans.[InProgress] = @InProgress
				AND Ans.template_group_id in(

				-- Get a union of template group.
				SELECT DISTINCT tg.Template_Group_ID
				FROM Folder f
					left join (
						SELECT tg.Template_Group_ID, ft.Folder_ID
						FROM folder_template ft
						LEFT JOIN template_group tg ON ft.FolderItem_ID = tg.Template_Group_ID 
							AND ft.ItemType_ID = 1
							AND (tg.EnforcePublishPeriod = 0 
								OR ((tg.PublishStartDate IS NULL OR tg.PublishStartDate < getutcdate())
									AND (tg.PublishFinishDate IS NULL OR tg.PublishFinishDate > getutcdate())))
					) tg on f.Folder_ID = tg.Folder_ID
					left join template_group_item tgi on tg.template_group_id = tgi.template_group_id
					left join template t on tgi.template_id = t.template_id
					inner join folder_group fg on F.Folder_Guid = fg.FolderGuid
				where 	(fg.GroupGuid in
							(select b.Group_Guid
							from intelledox_user a
							left join User_Group_Subscription c on a.[User_ID] = c.[User_ID]
							left join user_group b on c.user_group_id = b.user_group_id
							where c.[user_id] = @user_id)
						)
			)
			order by [RunDate] desc;
		else
			select	ans.AnswerFile_Id, ans.User_Id, ans.Template_Group_Id, ans.Description, 
					ans.RunDate, ans.InProgress, 
					Template_Group.Name as TemplateGroup_Name, Template_Group.Template_Group_Guid,
					Intelledox_User.User_Guid
			from	answer_file ans
					INNER JOIN Template_Group on ans.Template_Group_ID = Template_Group.Template_Group_ID
					INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
					INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
					INNER JOIN Intelledox_User ON ans.User_Id = Intelledox_User.User_ID
			where Ans.[user_ID] = @user_id
				AND Template_Group.Template_group_Guid = @TemplateGroupGuid
			order by [RunDate] desc;
    end
    else
    begin
        SELECT	Answer_File.*, Template_Group.Template_Group_Guid, Intelledox_User.User_Guid
		FROM	Answer_File
				INNER JOIN Template_Group ON Answer_File.Template_Group_Id = Template_Group.Template_Group_Id
				INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
				INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
				INNER JOIN Intelledox_User ON Answer_File.User_Id = Intelledox_User.User_ID
        WHERE	Answer_File.AnswerFile_Id = @AnswerFile_Id
        ORDER BY Answer_File.[RunDate] desc;
    end
GO

ALTER procedure [dbo].[spFolder_PublishedProjectList]
	@UserGuid uniqueidentifier,
	@ErrorCode int output
as
/*
Date		Version		Author		Description
--------------------------------------------------------------------------------------------
10-Apr-08	5.0.21		Chrisg		Return list of published projects in folders for a user.
--------------------------------------------------------------------------------------------
*/
	declare @BusinessUnitGuid uniqueidentifier
	select @BusinessUnitGuid = business_unit_guid from Intelledox_User where User_Guid = @UserGuid

	SELECT	a.Folder_ID, a.Folder_Guid, a.Folder_Name, d.Template_Group_Id, b.[Name] as Project_Name,
			d.Template_Group_Guid
	FROM	Folder a
		left join Folder_Template c on a.Folder_ID = c.Folder_ID
		left join Template_Group d on c.FolderItem_Id = d.Template_Group_ID 
			and c.ItemType_Id = 1
			AND (d.EnforcePublishPeriod = 0 
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getutcdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getutcdate())))
		left join Template_Group_Item e on d.Template_Group_ID = e.Template_Group_ID
		left join Template b on e.Template_ID = b.Template_ID
	WHERE	((c.ItemType_ID = 1 and d.Template_Group_ID in (
					select	a.template_group_id
					from	template_group_item a
							inner join template b on a.template_id = b.template_id or a.layout_id = b.template_id
							inner join template_group c on a.template_group_id = c.template_group_id
							left join template_group_item d on c.fax_template_group_id = d.template_group_id
							left join template e on d.template_id = e.template_id or d.layout_id = e.template_id
					group by a.template_group_id
					--having min(b.web_template) = 1 and (min(e.web_template) = 1 or min(e.web_template) is null)
				)
			))
		and a.Business_Unit_GUID = @BusinessUnitGuid
		and a.Folder_Guid in (
			SELECT	FolderGuid
			FROM	Folder_Group
			WHERE	GroupGuid in (
				select	distinct b.Group_Guid
				from	Intelledox_User a
						left join User_Group_Subscription c on a.[User_ID] = c.[User_ID]
						left join User_Group b on c.User_Group_ID = b.User_Group_ID
				where	b.Group_Guid is not null
				and		a.User_Guid = @UserGuid
			)
		)
	ORDER BY a.Folder_Name, a.Folder_ID, c.folderitem_id
	
	set @ErrorCode = @@error
GO

