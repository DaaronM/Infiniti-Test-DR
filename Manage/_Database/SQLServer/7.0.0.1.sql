/*
** Database Update package 7.0.0.1
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.0.0.1')
go

--1934
INSERT INTO dbo.Permission(PermissionGuid, Name, Description) 
VALUES ('F9A676FF-93F8-4D15-9F24-B95DD8C01762', 'Content Approver', 'Can approve new content and projects');
GO
ALTER TABLE Content_Item
	ADD Approved INT NULL
GO
ALTER TABLE ContentData_Binary_Version
	ADD Approved INT NULL
GO
ALTER TABLE ContentData_Text_Version
	ADD Approved INT NULL
GO
UPDATE	Content_Item
SET		Approved = 2
WHERE	Approved IS NULL;
GO
UPDATE	ContentData_Binary_Version
SET		Approved = 2
WHERE	Approved IS NULL;
GO
UPDATE	ContentData_Text_Version
SET		Approved = 2
WHERE	Approved IS NULL;
GO
ALTER TABLE Content_Item
	ALTER COLUMN Approved INT NOT NULL
GO
ALTER TABLE ContentData_Binary_Version
	ALTER COLUMN Approved INT NOT NULL
GO
ALTER TABLE ContentData_Text_Version
	ALTER COLUMN Approved INT NOT NULL
GO
ALTER procedure [dbo].[spLibrary_GetContentVersions]
	@ContentItemGuid uniqueidentifier
as
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @Approved Int
	
	SELECT	@ContentData_Guid = ContentData_Guid, @Approved = Approved
	FROM	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;

	SELECT	ContentData_Version, Modified_Date, Intelledox_User.Username,
			Approved
	FROM	(SELECT	ContentData_Guid, Modified_Date, Modified_By, ContentData_Version, @Approved as Approved
			FROM	ContentData_Binary
			UNION
			SELECT	ContentData_Guid, Modified_Date, Modified_By, ContentData_Version, Approved
			FROM	ContentData_Binary_Version
			UNION
			SELECT	ContentData_Guid, Modified_Date, Modified_By, ContentData_Version, @Approved as Approved
			FROM	ContentData_Text
			UNION
			SELECT	ContentData_Guid, Modified_Date, Modified_By, ContentData_Version, Approved
			FROM	ContentData_Text_Version) Versions
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Versions.Modified_By
	WHERE	ContentData_Guid = @ContentData_Guid
	ORDER BY ContentData_Version DESC;
GO
INSERT INTO Global_Options (OptionCode, OptionDescription, OptionValue)
VALUES ('REQUIRE_CONTENT_APPROVAL', 'Require content approval', 'false');
GO
CREATE PROCEDURE dbo.spLibrary_ClearExcessVersions
	@ContentData_Guid uniqueidentifier,
	@IsBinary bit
AS	
	If (@IsBinary = 1)
	BEGIN
		WHILE ((SELECT	COUNT(*) 
				FROM	ContentData_Binary_Version 
				WHERE	ContentData_Guid = @ContentData_Guid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
		BEGIN
			IF (SELECT	COUNT(*) 
				FROM	ContentData_Binary_Version 
				WHERE	ContentData_Guid = @ContentData_Guid
						AND Approved = 1) > 0
			BEGIN
				--Clear unapproved expired first
				DELETE FROM ContentData_Binary_Version
				WHERE ContentData_Version = 
						(SELECT MIN(ContentData_Version) 
						FROM	ContentData_Binary_Version 
						WHERE	ContentData_Guid = @ContentData_Guid
								AND Approved = 1)
					AND ContentData_Guid = @ContentData_Guid;
			END
			ELSE
			BEGIN
				--Clear Oldest
				DELETE FROM ContentData_Binary_Version
				WHERE ContentData_Version = 
						(SELECT MIN(ContentData_Version) 
						FROM	ContentData_Binary_Version 
						WHERE	ContentData_Guid = @ContentData_Guid)
					AND ContentData_Guid = @ContentData_Guid;
			END
		END
	END
	ELSE
	BEGIN
		WHILE ((SELECT	COUNT(*) 
				FROM	ContentData_Text_Version
				WHERE	ContentData_Guid = @ContentData_Guid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
		BEGIN
			IF (SELECT	COUNT(*) 
				FROM	ContentData_Text_Version 
				WHERE	ContentData_Guid = @ContentData_Guid
						AND Approved = 1) > 0
			BEGIN
				--Clear unapproved expired first
				DELETE FROM ContentData_Text_Version
				WHERE ContentData_Version = 
						(SELECT MIN(ContentData_Version) 
						FROM	ContentData_Text_Version 
						WHERE	ContentData_Guid = @ContentData_Guid
								AND Approved = 1)
					AND ContentData_Guid = @ContentData_Guid;
			END
			ELSE
			BEGIN
				--Clear Oldest
				DELETE FROM ContentData_Text_Version
				WHERE ContentData_Version = 
						(SELECT MIN(ContentData_Version) 
						FROM ContentData_Text_Version 
						WHERE ContentData_Guid = @ContentData_Guid)
					AND ContentData_Guid = @ContentData_Guid;
			END
		END
	END
GO
ALTER PROCEDURE [dbo].[spLibrary_AddNewLibraryVersion]
	@ContentData_Guid uniqueidentifier,
	@IsBinary bit
AS
	BEGIN TRAN

	If (@IsBinary = 1)
	BEGIN
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
			CASE Content_Item.Approved WHEN 0 THEN 1 ELSE Content_Item.Approved END AS Approved
		FROM ContentData_Binary	
			INNER JOIN Content_Item ON ContentData_Binary.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE ContentData_Binary.ContentData_Guid = @ContentData_Guid;
	END
	ELSE
	BEGIN
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
			CASE Content_Item.Approved WHEN 0 THEN 1 ELSE Content_Item.Approved END AS Approved
		FROM ContentData_Text
			INNER JOIN Content_Item ON ContentData_Text.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE ContentData_Text.ContentData_Guid = @ContentData_Guid;
	END
	
	EXEC spLibrary_ClearExcessVersions @ContentData_Guid, @IsBinary;
	
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
	DECLARE @Approvals nvarchar(10)
	DECLARE @MaxVersion int

	SET NOCOUNT ON;

	SELECT	@ContentData_Guid = ContentData_Guid, @ContentItem_Guid = ContentItem_Guid
	FROM	Content_Item
	WHERE	ContentItem_Guid = @UniqueId;
	
	SELECT	@Approvals = OptionValue
	FROM	Global_Options
	WHERE	OptionCode = 'REQUIRE_CONTENT_APPROVAL';


	IF (@Approvals = 'true')
	BEGIN
		IF @ContentData_Guid IS NULL
		BEGIN
			SET	@ContentData_Guid = newid();
			
			INSERT INTO ContentData_Binary(ContentData_Guid, ContentData, FileType, ContentData_Version, Modified_Date, Modified_By)
			VALUES (@ContentData_Guid, @ContentData, @Extension, 1, getUTCdate(), @UserGuid);

			UPDATE	Content_Item
			SET		ContentData_Guid = @ContentData_Guid,
					Approved = 0
			WHERE	ContentItem_Guid = @UniqueId;
		END
		ELSE
		BEGIN
			SELECT	@MaxVersion = MAX(ContentData_Version)
			FROM	(SELECT ContentData_Version
					FROM	ContentData_Binary_Version
					WHERE	ContentData_Guid = @ContentData_Guid
					UNION
					SELECT	ContentData_Version
					FROM	ContentData_Binary
					WHERE	ContentData_Guid = @ContentData_Guid) Versions

			-- Expire old unapproved versions
			UPDATE	ContentData_Binary_Version
			SET		Approved = 1
			WHERE	ContentData_Guid = @ContentData_Guid
					AND Approved = 0;
		
			-- Insert new unapproved version
			INSERT INTO ContentData_Binary_Version(ContentData_Guid, ContentData, FileType, ContentData_Version, Modified_Date, Modified_By, Approved)
			VALUES (@ContentData_Guid, @ContentData, @Extension, IsNull(@MaxVersion, 0) + 1, getUTCdate(), @UserGuid, 0);
			
			EXEC spLibrary_ClearExcessVersions @ContentData_Guid, 1;
		END
	END
	ELSE
	BEGIN
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
	END
GO
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
		IF @ContentData_Guid IS NULL
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
CREATE procedure [dbo].[spLibrary_ApproveVersion]
	@ContentItemGuid uniqueidentifier,
	@VersionNumber int,
	@UserGuid uniqueidentifier
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
	SET		Approved = 2
	WHERE	ContentData_Guid = @ContentData_Guid;
	
	COMMIT
GO
ALTER procedure [dbo].[spContent_UpdateContentItem]
	@ContentItemGuid uniqueidentifier,
	@Description nvarchar(1000),
	@Name nvarchar(255),
	@ContentTypeId Int,
	@BusinessUnitGuid uniqueidentifier,
	@ContentDataGuid uniqueidentifier,
	@SizeScale int,
	@Category int,
	@ProviderName nvarchar(50),
	@ReferenceId nvarchar(255),
	@IsIndexed bit
as
	DECLARE @Approvals nvarchar(10)
	
	IF NOT EXISTS(SELECT * FROM Content_Item WHERE ContentItem_Guid = @ContentItemGuid)
	begin
		SELECT	@Approvals = OptionValue
		FROM	Global_Options
		WHERE	OptionCode = 'REQUIRE_CONTENT_APPROVAL';
		
		INSERT INTO Content_Item (ContentItem_Guid, [Description], NameIdentity, ContentType_Id, Business_Unit_Guid, ContentData_Guid, SizeScale, Category, Provider_Name, Reference_Id, IsIndexed, Approved)
		VALUES (@ContentItemGuid, @Description, @Name, @ContentTypeId, @BusinessUnitGuid, @ContentDataGuid, @SizeScale, @Category, @ProviderName, @ReferenceId, 0, CASE WHEN @Approvals = 'true' THEN 0 ELSE 2 END);
	end
	ELSE
		UPDATE Content_Item
		SET NameIdentity = @Name,
			[Description] = @Description,
			SizeScale = @SizeScale,
			ContentData_Guid = @ContentDataGuid,
			Category = @Category,
			Provider_Name = @ProviderName,
			Reference_Id = @ReferenceId,
			IsIndexed = @IsIndexed
		WHERE ContentItem_Guid = @ContentItemGuid;
GO
CREATE VIEW dbo.vwContentItemVersionDetails
AS
	SELECT	ContentData_Version, ContentData_Guid, Modified_Date, Modified_By, Approved
	FROM	ContentData_Binary_Version
	UNION
	SELECT	ContentData_Version, ContentData_Guid, Modified_Date, Modified_By, Approved
	FROM	ContentData_Text_Version
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
	@ErrorCode int output
as
	IF @ItemGuid is null 
		IF @ExactMatch = 1
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision
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
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity = @Name
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
			ORDER BY ci.NameIdentity;
		ELSE
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision
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
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity LIKE '%' + @Name + '%'
					AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND ci.Description LIKE '%' + @Description + '%'
					AND (@Category = 0 or ci.Category = @Category)
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
			ORDER BY ci.NameIdentity;
	ELSE
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Intelledox_User.UserName,
				CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision
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
	@ErrorCode int output
as
	IF @ItemGuid is null 
		IF @ExactMatch = 1
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision
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
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision
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
			ORDER BY ci.NameIdentity;
	ELSE
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Intelledox_User.UserName,
				CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision
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
		WHERE	ci.contentitem_guid = @ItemGuid;
	
	set @ErrorCode = @@error;
GO
ALTER VIEW [dbo].[vwUserPermissions]
AS
	SELECT	UserGuid,
			RoleGuid, 
			GroupGuid,
			MAX(CanDesignProjects) as CanDesignProjects, 
			MAX(CanPublishProjects) as CanPublishProjects, 
			MAX(CanManageContent) as CanManageContent, 
			MAX(CanManageUsers) as CanManageUsers, 
			MAX(CanManageGroups) as CanManageGroups, 
			MAX(CanManageSecurity) as CanManageSecurity, 
			MAX(CanManageDataSources) as CanManageDataSources,
			MIN(IsInherited) as IsInherited,
			MAX(CanMaintainLicensing) as CanMaintainLicensing,
			MAX(CanChangeSettings) as CanChangeSettings,
			MAX(CanManageConsole) as CanManageConsole,
			MAX(CanApproveContent) as CanApproveContent
	FROM (
		SELECT User_Role.UserGuid,
			User_Role.RoleGuid,
			User_Role.GroupGuid,
			--Design projects
			CASE WHEN Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' THEN 1 ELSE 0 END AS CanDesignProjects,
			--Publish projects
			CASE WHEN Role_Permission.PermissionGuid = '6B96BAF3-8A76-4F42-B1E7-DF87142444E0' THEN 1 ELSE 0 END AS CanPublishProjects,
			--Manage content
			CASE WHEN Role_Permission.PermissionGuid = 'FA2C7769-6D15-442E-9F7F-E8CE82590D8D' THEN 1 ELSE 0 END AS CanManageContent,
			--Manage users
			CASE WHEN Role_Permission.PermissionGuid = '7D98327C-B4CB-48DC-9FF7-E613C26FA918' THEN 1 ELSE 0 END AS CanManageUsers,
			--Manage groups
			CASE WHEN Role_Permission.PermissionGuid = '33FC4FFE-9108-4D56-9A08-DD128255D87C' THEN 1 ELSE 0 END AS CanManageGroups,
			--Manage security
			CASE WHEN Role_Permission.PermissionGuid = '09B7187E-E432-4B03-BDC9-C7FC2C82B9F1' THEN 1 ELSE 0 END AS CanManageSecurity,
			--Manage data sources
			CASE WHEN Role_Permission.PermissionGuid = 'B0761CDD-BE11-45EE-8133-BF1D6AA65D6D' THEN 1 ELSE 0 END AS CanManageDataSources,
			0 as IsInherited,
			--Maintain Licensing
			CASE WHEN Role_Permission.PermissionGuid = 'BB4F1768-DBC7-46C7-9A52-09159DB15A02' THEN 1 ELSE 0 END AS CanMaintainLicensing,
			--Change Settings
			CASE WHEN Role_Permission.PermissionGuid = 'D0416D36-5C3C-4CB7-8686-74432261A87A' THEN 1 ELSE 0 END AS CanChangeSettings,
			--Management Console
			CASE WHEN Role_Permission.PermissionGuid = '22A89A6C-C131-4DF1-9A4F-50CFC5E69B58' THEN 1 ELSE 0 END AS CanManageConsole,
			--Content Approver
			CASE WHEN Role_Permission.PermissionGuid = 'F9A676FF-93F8-4D15-9F24-B95DD8C01762' THEN 1 ELSE 0 END AS CanApproveContent
		FROM	User_Role
				LEFT JOIN Role_Permission ON Role_Permission.RoleGuid = User_Role.RoleGuid
		UNION
		SELECT Intelledox_User.User_Guid as UserGuid,
			Role_Permission.RoleGuid,
			NULL as GroupGuid,
			--Design projects
			CASE WHEN Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' THEN 1 ELSE 0 END AS CanDesignProjects,
			--Publish projects
			CASE WHEN Role_Permission.PermissionGuid = '6B96BAF3-8A76-4F42-B1E7-DF87142444E0' THEN 1 ELSE 0 END AS CanPublishProjects,
			--Manage content
			CASE WHEN Role_Permission.PermissionGuid = 'FA2C7769-6D15-442E-9F7F-E8CE82590D8D' THEN 1 ELSE 0 END AS CanManageContent,
			--Manage users
			CASE WHEN Role_Permission.PermissionGuid = '7D98327C-B4CB-48DC-9FF7-E613C26FA918' THEN 1 ELSE 0 END AS CanManageUsers,
			--Manage groups
			CASE WHEN Role_Permission.PermissionGuid = '33FC4FFE-9108-4D56-9A08-DD128255D87C' THEN 1 ELSE 0 END AS CanManageGroups,
			--Manage security
			CASE WHEN Role_Permission.PermissionGuid = '09B7187E-E432-4B03-BDC9-C7FC2C82B9F1' THEN 1 ELSE 0 END AS CanManageSecurity,
			--Manage data sources
			CASE WHEN Role_Permission.PermissionGuid = 'B0761CDD-BE11-45EE-8133-BF1D6AA65D6D' THEN 1 ELSE 0 END AS CanManageDataSources,
			1 as IsInherited,
			--Maintain Licensing
			CASE WHEN Role_Permission.PermissionGuid = 'BB4F1768-DBC7-46C7-9A52-09159DB15A02' THEN 1 ELSE 0 END AS CanMaintainLicensing,
			--Change Settings
			CASE WHEN Role_Permission.PermissionGuid = 'D0416D36-5C3C-4CB7-8686-74432261A87A' THEN 1 ELSE 0 END AS CanChangeSettings,
			--Management Console
			CASE WHEN Role_Permission.PermissionGuid = '22A89A6C-C131-4DF1-9A4F-50CFC5E69B58' THEN 1 ELSE 0 END AS CanManageConsole,
			--Content Approver
			CASE WHEN Role_Permission.PermissionGuid = 'F9A676FF-93F8-4D15-9F24-B95DD8C01762' THEN 1 ELSE 0 END AS CanApproveContent
		FROM	Role_Permission
				INNER JOIN User_Group_Role ON Role_Permission.RoleGuid = User_Group_Role.RoleGuid
				INNER JOIN User_Group ON User_Group_Role.GroupGuid = User_Group.Group_Guid
				INNER JOIN User_Group_Subscription ON User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
				INNER JOIN Intelledox_User ON Intelledox_User.User_ID = User_Group_Subscription.User_ID
		) PermissionCombination
		GROUP BY UserGuid, RoleGuid, GroupGuid
GO
ALTER procedure [dbo].[spUsers_AdminLevelList]
	@RoleGuid uniqueidentifier,
	@BusinessUnitGUID uniqueidentifier,
	@UserGUID uniqueidentifier,
	@ErrorCode int = 0 output
AS
	IF (@UserGUID IS NULL)
	BEGIN
		IF (@RoleGuid IS NULL)
		BEGIN
			SELECT	Administrator_Level.AdminLevel_ID, Administrator_Level.AdminLevel_Description, 
					Administrator_Level.RoleGuid, Administrator_Level.Business_Unit_Guid,
					--Design projects
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' THEN 1 ELSE 0 END) AS CanDesignProjects,
					--Publish projects
					MAX(CASE WHEN Role_Permission.PermissionGuid = '6B96BAF3-8A76-4F42-B1E7-DF87142444E0' THEN 1 ELSE 0 END) AS CanPublishProjects,
					--Manage content
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'FA2C7769-6D15-442E-9F7F-E8CE82590D8D' THEN 1 ELSE 0 END) AS CanManageContent,
					--Manage users
					MAX(CASE WHEN Role_Permission.PermissionGuid = '7D98327C-B4CB-48DC-9FF7-E613C26FA918' THEN 1 ELSE 0 END) AS CanManageUsers,
					--Manage groups
					MAX(CASE WHEN Role_Permission.PermissionGuid = '33FC4FFE-9108-4D56-9A08-DD128255D87C' THEN 1 ELSE 0 END) AS CanManageGroups,
					--Manage security
					MAX(CASE WHEN Role_Permission.PermissionGuid = '09B7187E-E432-4B03-BDC9-C7FC2C82B9F1' THEN 1 ELSE 0 END) AS CanManageSecurity,
					--Manage data sources
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'B0761CDD-BE11-45EE-8133-BF1D6AA65D6D' THEN 1 ELSE 0 END) AS CanManageDataSources,
					0 as IsInherited,
					--Maintain Licensing
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'BB4F1768-DBC7-46C7-9A52-09159DB15A02' THEN 1 ELSE 0 END) AS CanMaintainLicensing,
					--Change Settings
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'D0416D36-5C3C-4CB7-8686-74432261A87A' THEN 1 ELSE 0 END) AS CanChangeSettings,
					--Management Console
					MAX(CASE WHEN Role_Permission.PermissionGuid = '22A89A6C-C131-4DF1-9A4F-50CFC5E69B58' THEN 1 ELSE 0 END) AS CanManageConsole,
					--Content Approver
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'F9A676FF-93F8-4D15-9F24-B95DD8C01762' THEN 1 ELSE 0 END) AS CanApproveContent
			FROM	Administrator_Level
					LEFT JOIN Role_Permission ON Administrator_Level.RoleGuid = Role_Permission.RoleGuid
			WHERE	Administrator_Level.Business_Unit_GUID = @BusinessUnitGUID
			GROUP BY Administrator_Level.AdminLevel_ID, Administrator_Level.AdminLevel_Description, 
					Administrator_Level.RoleGuid, Administrator_Level.Business_Unit_Guid
			ORDER BY Administrator_Level.AdminLevel_Description;
		END
		ELSE
		BEGIN
			SELECT	Administrator_Level.AdminLevel_ID, Administrator_Level.AdminLevel_Description, 
					Administrator_Level.RoleGuid, Administrator_Level.Business_Unit_Guid,
					--Design projects
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' THEN 1 ELSE 0 END) AS CanDesignProjects,
					--Publish projects
					MAX(CASE WHEN Role_Permission.PermissionGuid = '6B96BAF3-8A76-4F42-B1E7-DF87142444E0' THEN 1 ELSE 0 END) AS CanPublishProjects,
					--Manage content
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'FA2C7769-6D15-442E-9F7F-E8CE82590D8D' THEN 1 ELSE 0 END) AS CanManageContent,
					--Manage users
					MAX(CASE WHEN Role_Permission.PermissionGuid = '7D98327C-B4CB-48DC-9FF7-E613C26FA918' THEN 1 ELSE 0 END) AS CanManageUsers,
					--Manage groups
					MAX(CASE WHEN Role_Permission.PermissionGuid = '33FC4FFE-9108-4D56-9A08-DD128255D87C' THEN 1 ELSE 0 END) AS CanManageGroups,
					--Manage security
					MAX(CASE WHEN Role_Permission.PermissionGuid = '09B7187E-E432-4B03-BDC9-C7FC2C82B9F1' THEN 1 ELSE 0 END) AS CanManageSecurity,
					--Manage data sources
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'B0761CDD-BE11-45EE-8133-BF1D6AA65D6D' THEN 1 ELSE 0 END) AS CanManageDataSources,
					0 as IsInherited,
					--Maintain Licensing
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'BB4F1768-DBC7-46C7-9A52-09159DB15A02' THEN 1 ELSE 0 END) AS CanMaintainLicensing,
					--Change Settings
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'D0416D36-5C3C-4CB7-8686-74432261A87A' THEN 1 ELSE 0 END) AS CanChangeSettings,
					--Management Console
					MAX(CASE WHEN Role_Permission.PermissionGuid = '22A89A6C-C131-4DF1-9A4F-50CFC5E69B58' THEN 1 ELSE 0 END) AS CanManageConsole,
					--Content Approver
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'F9A676FF-93F8-4D15-9F24-B95DD8C01762' THEN 1 ELSE 0 END) AS CanApproveContent
			FROM	Administrator_Level
					LEFT JOIN Role_Permission ON Administrator_Level.RoleGuid = Role_Permission.RoleGuid
			WHERE	Administrator_Level.RoleGuid = @RoleGuid
			GROUP BY Administrator_Level.AdminLevel_ID, Administrator_Level.AdminLevel_Description, 
					Administrator_Level.RoleGuid, Administrator_Level.Business_Unit_Guid
			ORDER BY Administrator_Level.AdminLevel_Description;
		END
	END
	ELSE
	BEGIN
		SELECT	Administrator_Level.AdminLevel_ID, Administrator_Level.AdminLevel_Description, 
				Administrator_Level.RoleGuid, Administrator_Level.Business_Unit_Guid,
				vwUserPermissions.CanDesignProjects, vwUserPermissions.CanPublishProjects,
				vwUserPermissions.CanManageContent, vwUserPermissions.CanManageUsers,
				vwUserPermissions.CanManageGroups, vwUserPermissions.CanManageSecurity,
				vwUserPermissions.CanManageDataSources, vwUserPermissions.IsInherited,
				vwUserPermissions.CanMaintainLicensing, vwUserPermissions.CanChangeSettings,
				vwUserPermissions.CanManageConsole, vwUserPermissions.CanApproveContent
		FROM	Administrator_Level
				LEFT JOIN vwUserPermissions ON Administrator_Level.RoleGuid = vwUserPermissions.RoleGuid
		WHERE	Administrator_Level.Business_Unit_GUID = @BusinessUnitGUID
				AND vwUserPermissions.UserGUID = @UserGUID
				AND vwUserPermissions.GroupGuid IS NULL
		ORDER BY Administrator_Level.AdminLevel_Description;
	END

	set @errorcode = @@error;
GO
ALTER procedure [dbo].[spContent_ContentItemListByDefinition]
	@ContentDefinitionGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier,
	@ErrorCode int output
as
	SELECT	ci.*, cdi.SortIndex, cib.FileType, cib.Modified_Date, Intelledox_User.Username,
			0 as HasUnapprovedRevision
	FROM	content_item ci
			INNER JOIN content_definition_item cdi ON ci.ContentItem_Guid = cdi.ContentItem_Guid
				AND cdi.ContentDefinition_Guid = @ContentDefinitionGuid
			LEFT JOIN ContentData_Binary cib ON ci.ContentData_Guid = cib.ContentData_Guid
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = cib.Modified_By
	WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
	ORDER BY cdi.SortIndex;
	
	set @ErrorCode = @@error;
GO

