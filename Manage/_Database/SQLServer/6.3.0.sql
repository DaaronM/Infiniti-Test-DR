/*
** Database Update package 6.3.0
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.3.0')
go

--1927
ALTER PROCEDURE [dbo].[spLog_InsertTemplateLog]
	@LogGuid uniqueidentifier,
	@UserGuid uniqueidentifier,	
	@TemplateGroupGuid uniqueidentifier,
	@StartTime datetime,
	@AnswerFileUsed bit,
	@PackageRunId int,
	@AnswerFile xml,
	@UpdateRecent bit = 0
AS
	DECLARE @UserId INT;
	DECLARE @TemplateGroupId INT;
	
	SET NOCOUNT ON;
	
	SET @UserId = (SELECT User_Id FROM Intelledox_User WITH (NOLOCK) WHERE User_Guid = @UserGuid);
	SET	@TemplateGroupId = (SELECT Template_Group_Id FROM Template_Group WITH (NOLOCK) WHERE Template_Group_Guid = @TemplateGroupGuid);
	
	IF @LogGuid IS NULL
		SET @LogGuid = newid();

	--Add to log
	INSERT INTO Template_Log WITH (ROWLOCK) (Log_Guid, [User_ID], Template_Group_ID, DateTime_Start, Completed, Answer_File_Used, Package_Run_Id, InProgress, Answer_File)
	VALUES (@LogGuid, @UserID, @TemplateGroupID, @StartTime, 0, @AnswerFileUsed, @PackageRunId, 1, @AnswerFile);

	--Add to recent
	If @UpdateRecent = 1
	BEGIN
		IF EXISTS (SELECT * FROM Template_Recent WHERE User_Guid = @UserGuid AND Template_Group_Guid = @TemplateGroupGuid)
		BEGIN
			--Update time ran
			UPDATE	Template_Recent
			SET		DateTime_Start = @StartTime
			WHERE	User_Guid = @UserGuid 
					AND Template_Group_Guid = @TemplateGroupGuid;
		END
		ELSE
		BEGIN
			IF ((SELECT COUNT(*) FROM Template_Recent WHERE User_Guid = @UserGuid) = 5)
			BEGIN
				--Remove oldest recent record
				DELETE Template_Recent
				WHERE DateTime_Start = (SELECT MIN(DateTime_Start)
					FROM	Template_Recent
					WHERE	User_Guid = @UserGuid)
					AND User_Guid = @UserGuid;
			END
			
			INSERT INTO Template_Recent(User_Guid, DateTime_Start, Template_Group_Guid)
			VALUES (@UserGuid, @StartTime, @TemplateGroupGuid);
		END
	END
GO
ALTER PROCEDURE [dbo].[spLog_UpdateTemplateLog]
	@LogGuid uniqueidentifier,
	@LastGroupGuid uniqueidentifier,
	@AnswerFile xml
AS
	UPDATE	Template_Log WITH (ROWLOCK UPDLOCK)
	SET		Answer_File = @AnswerFile,
			Last_Bookmark_Group_Guid = @LastGroupGuid
	WHERE	Log_Guid = @LogGuid;
GO


--1928
ALTER TABLE ContentData_Binary
	ADD	
	[ContentData_Version] [int] NULL,
	[Modified_Date] [datetime] NULL,
	[Modified_By] [uniqueidentifier] NULL
GO
ALTER TABLE ContentData_Text
	ADD	
	[ContentData_Version] [int] NULL,
	[Modified_Date] [datetime] NULL,
	[Modified_By] [uniqueidentifier] NULL
GO
CREATE TABLE [dbo].[ContentData_Binary_Version](
	[ContentData_Version] [int] NOT NULL,
	[ContentData_Guid] [uniqueidentifier] NOT NULL,
	[ContentData] [varbinary](max) NULL,
	[FileType] [varchar](5) NULL,
	[Modified_Date] [datetime] NULL,
	[Modified_By] [uniqueidentifier] NULL,
	CONSTRAINT [PK_Content_Binary_Version] PRIMARY KEY CLUSTERED 
	(
		[ContentData_Guid] ASC,
		[ContentData_Version] ASC
	)
)
GO
CREATE TABLE [dbo].[ContentData_Text_Version](
	[ContentData_Version] [int] NOT NULL,
	[ContentData_Guid] [uniqueidentifier] NOT NULL,
	[ContentData] [nvarchar](max) NULL,
	[Modified_Date] [datetime] NULL,
	[Modified_By] [uniqueidentifier] NULL,
	CONSTRAINT [PK_Content_Text_Version] PRIMARY KEY CLUSTERED 
	(
		[ContentData_Guid] ASC,
		[ContentData_Version] ASC
	)
)
GO
CREATE procedure [dbo].[spLibrary_AddNewLibraryVersion]
	@ContentData_Guid uniqueidentifier,
	@IsBinary bit
as
	BEGIN TRAN

	If (@IsBinary = 1)
	BEGIN
		INSERT INTO ContentData_Binary_Version 
			(ContentData_Version, 
			ContentData_Guid, 
			ContentData,
			FileType,
			Modified_Date, 
			Modified_By)
		SELECT ContentData_Binary.ContentData_Version,
			ContentData_Binary.ContentData_Guid,
			ContentData_Binary.ContentData,
			ContentData_Binary.FileType,
			ContentData_Binary.Modified_Date,
			ContentData_Binary.Modified_By
		FROM ContentData_Binary
		WHERE ContentData_Binary.ContentData_Guid = @ContentData_Guid;
				
		WHILE ((SELECT COUNT(*) FROM ContentData_Binary_Version WHERE ContentData_Guid = @ContentData_Guid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
		BEGIN
			DELETE FROM ContentData_Binary_Version
			WHERE ContentData_Version = 
					(SELECT MIN(ContentData_Version) 
					FROM ContentData_Binary_Version 
					WHERE ContentData_Guid = @ContentData_Guid)
				AND ContentData_Guid = @ContentData_Guid;
		END
	END
	ELSE
	BEGIN
		INSERT INTO ContentData_Text_Version 
			(ContentData_Version, 
			ContentData_Guid, 
			ContentData,
			Modified_Date, 
			Modified_By)
		SELECT ContentData_Text.ContentData_Version,
			ContentData_Text.ContentData_Guid,
			ContentData_Text.ContentData,
			ContentData_Text.Modified_Date,
			ContentData_Text.Modified_By
		FROM ContentData_Text
		WHERE ContentData_Text.ContentData_Guid = @ContentData_Guid;
				
		WHILE ((SELECT COUNT(*) FROM ContentData_Text_Version WHERE ContentData_Guid = @ContentData_Guid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
		BEGIN
			DELETE FROM ContentData_Text_Version
			WHERE ContentData_Version = 
					(SELECT MIN(ContentData_Version) 
					FROM ContentData_Text_Version 
					WHERE ContentData_Guid = @ContentData_Guid)
				AND ContentData_Guid = @ContentData_Guid;
		END
	END
	
	COMMIT
GO
ALTER PROCEDURE [dbo].[spLibrary_UpdateBinary] (
	@UniqueId as uniqueidentifier,
	@ContentData as image,
	@Extension as varchar(5),
	@UserGuid as uniqueidentifier
)
AS
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @ContentItem_Guid uniqueidentifier

	SELECT	@ContentData_Guid = ContentData_Guid, @ContentItem_Guid = ContentItem_Guid
	FROM	Content_Item
	WHERE	ContentItem_Guid = @UniqueId;

	IF EXISTS(SELECT ContentData_Guid FROM ContentData_Binary WHERE ContentData_Guid = @ContentData_Guid)
	BEGIN
		EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 1;
		
		UPDATE	ContentData_Binary
		SET		ContentData = @ContentData,
				FileType = @Extension
		WHERE	ContentData_Guid = @ContentData_Guid;
	END
	ELSE
	BEGIN
		IF @ContentItem_Guid IS NOT NULL
		BEGIN
			SET	@ContentData_Guid = newid();

			INSERT INTO ContentData_Binary(ContentData_Guid, ContentData, FileType, ContentData_Version)
			VALUES (@ContentData_Guid, @ContentData, @Extension, 0);

			UPDATE	Content_Item
			SET		ContentData_Guid = @ContentData_Guid
			WHERE	ContentItem_Guid = @UniqueId;
		END
	END
		
	DELETE	FROM Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItem_Guid;
	
	IF @UserGuid IS NOT NULL
	BEGIN
		UPDATE	ContentData_Binary
		SET		Modified_Date = getUTCdate(),
				Modified_By = @UserGuid,
				ContentData_Version = ContentData_Version + 1
		WHERE	ContentData_Guid = @ContentData_Guid;
	END
	
	UPDATE	Content_Item
	SET		IsIndexed = 0
	WHERE	ContentItem_Guid = @ContentItem_Guid;
GO
ALTER PROCEDURE [dbo].[spLibrary_UpdateText] (
	@UniqueId as uniqueidentifier,
	@ContentData as nvarchar(max),
	@UserGuid as uniqueidentifier
)
AS
	DECLARE @ContentData_Guid uniqueidentifier

	SELECT	@ContentData_Guid = ContentData_Guid
	FROM	Content_Item
	WHERE	ContentItem_Guid = @UniqueId

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
GO
ALTER procedure [dbo].[spContent_ContentItemList]
	@ItemGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier,
	@ExactMatch bit,
	@ContentTypeId int,
	@Name NVarChar(255),
	@Description NVarChar(1000),
	@Category int,
	@ErrorCode int output
as
	IF @ItemGuid is null 
		IF @ExactMatch = 1
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity = @Name
			ORDER BY ci.NameIdentity;
		ELSE
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity LIKE '%' + @Name + '%'
					AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND ci.Description LIKE '%' + @Description + '%'
					AND (@Category = 0 or ci.Category = @Category)
			ORDER BY ci.NameIdentity;
	ELSE
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Intelledox_User.UserName
		FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
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
	@ErrorCode int output
as
	IF @ItemGuid is null 
		IF @ExactMatch = 1
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity = @Name
			ORDER BY ci.NameIdentity;
		ELSE
			--Full text search
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity LIKE '%' + @Name + '%'
					AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND ci.Description LIKE '%' + @Description + '%'
					AND (@Category = 0 or ci.Category = @Category)
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
			ORDER BY ci.NameIdentity;
	ELSE
		SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName
		FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
		WHERE	ci.contentitem_guid = @ItemGuid;
	
	set @ErrorCode = @@error;

GO

UPDATE ContentData_Binary 
SET ContentData_Version = '1';
GO
UPDATE ContentData_Text
SET ContentData_Version = '1';
GO

CREATE procedure [dbo].[spLibrary_RestoreVersion]
	@ContentItemGuid uniqueidentifier,
	@VersionNumber int,
	@UserGuid uniqueidentifier
as
	SET NOCOUNT ON
	
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @IsBinary bit
	
	SELECT	@ContentData_Guid = ContentData_Guid, @IsBinary = CASE WHEN ContentType_Id = 2 THEN 0 ELSE 1 END
	FROM	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;
		
	BEGIN TRAN	
	
	IF (@IsBinary = 1)
	BEGIN		
		INSERT INTO ContentData_Binary_Version 
			(ContentData_Version, 
			ContentData_Guid, 
			ContentData,
			FileType,
			Modified_Date, 
			Modified_By)
		SELECT ContentData_Binary.ContentData_Version,
			ContentData_Binary.ContentData_Guid,
			ContentData_Binary.ContentData,
			ContentData_Binary.FileType,
			ContentData_Binary.Modified_Date,
			ContentData_Binary.Modified_By
		FROM ContentData_Binary
		WHERE ContentData_Binary.ContentData_Guid = @ContentData_Guid;
			
		UPDATE	ContentData_Binary
		SET	ContentData = (SELECT ContentData
				FROM	ContentData_Binary_Version 
				WHERE	ContentData_Guid = @ContentData_Guid 
					AND ContentData_Version = @VersionNumber), 
			FileType = (SELECT FileType
				FROM	ContentData_Binary_Version 
				WHERE	ContentData_Guid = @ContentData_Guid 
					AND ContentData_Version = @VersionNumber),
			ContentData_Version = ContentData_Version + 1, 
			Modified_Date = GetUTCdate(),
			Modified_By = @UserGuid
		WHERE	ContentData_Guid = @ContentData_Guid;
						
		WHILE ((SELECT COUNT(*) FROM ContentData_Binary_Version WHERE ContentData_Guid = @ContentData_Guid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
		BEGIN
			DELETE FROM ContentData_Binary_Version
			WHERE ContentData_Version = 
					(SELECT MIN(ContentData_Version) 
					FROM ContentData_Binary_Version 
					WHERE ContentData_Guid = @ContentData_Guid)
				AND ContentData_Guid = @ContentData_Guid;
		END
	END
	ELSE
	BEGIN		
		INSERT INTO ContentData_Text_Version 
			(ContentData_Version, 
			ContentData_Guid, 
			ContentData,
			Modified_Date, 
			Modified_By)
		SELECT ContentData_Text.ContentData_Version,
			ContentData_Text.ContentData_Guid,
			ContentData_Text.ContentData,
			ContentData_Text.Modified_Date,
			ContentData_Text.Modified_By
		FROM ContentData_Text
		WHERE ContentData_Text.ContentData_Guid = @ContentData_Guid;
			
		UPDATE	ContentData_Text
		SET	ContentData = (SELECT ContentData
				FROM	ContentData_Text_Version 
				WHERE	ContentData_Guid = @ContentData_Guid 
					AND ContentData_Version = @VersionNumber), 
			ContentData_Version = ContentData_Version + 1, 
			Modified_Date = GetUTCdate(),
			Modified_By = @UserGuid
		WHERE	ContentData_Guid = @ContentData_Guid;
						
		WHILE ((SELECT COUNT(*) FROM ContentData_Text_Version WHERE ContentData_Guid = @ContentData_Guid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
		BEGIN
			DELETE FROM ContentData_Text_Version
			WHERE ContentData_Version = 
					(SELECT MIN(ContentData_Version) 
					FROM ContentData_Text_Version 
					WHERE ContentData_Guid = @ContentData_Guid)
				AND ContentData_Guid = @ContentData_Guid;
		END
	END
		
	COMMIT
GO
CREATE procedure [dbo].[spLibrary_GetContentVersions]
	@ContentItemGuid uniqueidentifier
as
	DECLARE @ContentData_Guid uniqueidentifier
	
	SELECT	@ContentData_Guid = ContentData_Guid
	FROM	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;

	SELECT	ContentData_Version, 
			Modified_Date,
			Intelledox_User.Username
	FROM	(SELECT	ContentData_Guid, Modified_Date, Modified_By, ContentData_Version
			FROM	ContentData_Binary
			UNION
			SELECT	ContentData_Guid, Modified_Date, Modified_By, ContentData_Version
			FROM	ContentData_Binary_Version
			UNION
			SELECT	ContentData_Guid, Modified_Date, Modified_By, ContentData_Version
			FROM	ContentData_Text
			UNION
			SELECT	ContentData_Guid, Modified_Date, Modified_By, ContentData_Version
			FROM	ContentData_Text_Version) Versions
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Versions.Modified_By
	WHERE	ContentData_Guid = @ContentData_Guid
	ORDER BY ContentData_Version DESC;
GO

--1929
ALTER TABLE dbo.Template_File ADD
	TemplateFileId uniqueidentifier NULL,
	tStamp timestamp NOT NULL
GO
ALTER TABLE dbo.Template_File ADD CONSTRAINT
	DF_Template_File_TemplateFileId DEFAULT newid() FOR TemplateFileId
GO
UPDATE	Template_File
SET		TemplateFileId = newid()
WHERE	TemplateFileId IS NULL;
GO
ALTER TABLE dbo.Template_File ALTER COLUMN
	TemplateFileId uniqueidentifier NOT NULL
GO
CREATE UNIQUE NONCLUSTERED INDEX IX_TemplateFileId ON dbo.Template_File
	(
	TemplateFileId
	)
GO
CREATE FULLTEXT INDEX ON dbo.Template_File([Binary] TYPE COLUMN FormatTypeId) 
   KEY INDEX IX_TemplateFileId;
GO
CREATE procedure [dbo].[spProject_ProjectListFullText]
	@UserGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ProjectTypeId int,
	@SearchString nvarchar(100),
	@FullText NVarChar(1000)
as
	declare @IsGlobal bit
	declare @BusinessUnitGUID uniqueidentifier

	SELECT	@BusinessUnitGUID = Business_Unit_GUID
	FROM	Intelledox_User
	WHERE	User_Guid = @UserGuid;

	IF EXISTS(SELECT	vwUserPermissions.*
		FROM	vwUserPermissions
		WHERE	vwUserPermissions.CanDesignProjects = 1
				AND vwUserPermissions.GroupGuid IS NULL
				AND vwUserPermissions.UserGuid = @UserGuid)
	BEGIN
		SET @IsGlobal = 1;
	END

	if @GroupGuid IS NULL
	begin
		--all usergroups
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, a.template_version, a.import_date, 
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Content_Bookmark
		FROM	Template a
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		WHERE	(@IsGlobal = 1 or a.template_id in (
				SELECT	User_Group_Template.Template_ID
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.[User_ID] = User_Group_Subscription.[User_ID] 
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.User_Group_Id = User_Group_Template.User_Group_Id 
				WHERE	vwUserPermissions.CanDesignProjects = 1
			AND Intelledox_User.User_Guid = @UserGuid
				))
			AND (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
			AND (a.Template_Guid IN (
					SELECT	Template_Guid
					FROM	Template_File tf
					WHERE	Contains(*, @FullText)
				))
		ORDER BY a.[name];
	end
	else
	begin
		--specific user group
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, a.template_version, a.import_date, 
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Content_Bookmark
		FROM	Template a
				INNER JOIN User_Group_Template d on a.Template_ID = d.Template_ID
				INNER JOIN User_Group ON d.User_Group_ID = User_Group.User_Group_ID  AND User_Group.Group_Guid = @GroupGuid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		WHERE	(@IsGlobal = 1 or a.template_id in (
				SELECT	User_Group_Template.Template_ID
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.[User_ID] = User_Group_Subscription.[User_ID] 
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.User_Group_Id = User_Group_Template.User_Group_Id 
				WHERE	vwUserPermissions.CanDesignProjects = 1
			))
			and (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
			AND (a.Template_Guid IN (
					SELECT	Template_Guid
					FROM	Template_File tf
					WHERE	Contains(*, @FullText)
				))
		ORDER BY a.[name];
	end
GO

--1930
ALTER PROCEDURE [dbo].[spLibrary_GetText] (
	@UniqueId as uniqueidentifier,
	@VersionNumber as varchar(50)
)
AS
	If @VersionNumber = '0'
	BEGIN
		SELECT	cd.ContentData as [Text] 
		FROM	ContentData_Text cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId;
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
ALTER PROCEDURE [dbo].[spLibrary_GetBinary] (
	@UniqueId as uniqueidentifier,
	@VersionNumber as varchar(50)
)
AS
	If @VersionNumber = '0'
	BEGIN
		SELECT	cd.ContentData as [Binary]
		FROM	ContentData_Binary cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId;
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

