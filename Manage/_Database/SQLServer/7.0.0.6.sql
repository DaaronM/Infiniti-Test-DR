/*
** Database Update package 7.0.0.6
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.0.0.6')
go

--1953
ALTER procedure [dbo].[spContent_RemoveContentItem]
	@ContentItemGuid uniqueidentifier
AS
	DELETE	Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItemGuid;
	
	DELETE	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;
GO
ALTER procedure [dbo].[spLibrary_ApproveVersion]
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
	SET		Approved = 2,
			IsIndexed = 0
	WHERE	ContentData_Guid = @ContentData_Guid;
	
	DELETE	Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItemGuid;
	
	COMMIT
GO
ALTER procedure [dbo].[spLibrary_RestoreVersion]
	@ContentItemGuid uniqueidentifier,
	@VersionNumber int,
	@UserGuid uniqueidentifier
AS
	SET NOCOUNT ON
	
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @IsBinary bit
	
	SELECT	@ContentData_Guid = ContentData_Guid, 
			@IsBinary = CASE WHEN ContentType_Id = 2 THEN 0 ELSE 1 END
	FROM	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;
		
	BEGIN TRAN	
	
	EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, @IsBinary;
	
	IF (@IsBinary = 1)
	BEGIN
		UPDATE	ContentData_Binary
		SET		ContentData = ContentData_Binary_Version.ContentData, 
				FileType = ContentData_Binary_Version.FileType,
				ContentData_Version = ContentData_Binary.ContentData_Version + 1, 
				Modified_Date = GetUTCdate(),
				Modified_By = @UserGuid
		FROM	ContentData_Binary, 
				ContentData_Binary_Version
		WHERE	ContentData_Binary.ContentData_Guid = @ContentData_Guid
				AND ContentData_Binary_Version.ContentData_Guid = @ContentData_Guid 
				AND	ContentData_Binary_Version.ContentData_Version = @VersionNumber;
	END
	ELSE
	BEGIN
		UPDATE	ContentData_Text
		SET		ContentData = ContentData_Text_Version.ContentData, 
				ContentData_Version = ContentData_Text.ContentData_Version + 1, 
				Modified_Date = GetUTCdate(),
				Modified_By = @UserGuid
		FROM	ContentData_Text, 
				ContentData_Text_Version
		WHERE	ContentData_Text.ContentData_Guid = @ContentData_Guid
				AND ContentData_Text_Version.ContentData_Guid = @ContentData_Guid 
				AND	ContentData_Text_Version.ContentData_Version = @VersionNumber;
	END
	
	EXEC spLibrary_ClearExcessVersions @ContentData_Guid, @IsBinary;
	
	UPDATE	Content_Item
	SET		IsIndexed = 0
	WHERE	ContentItem_Guid = @ContentItemGuid;
	
	DELETE	Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItemGuid;
		
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
	DECLARE @CIApproved int

	SET NOCOUNT ON;

	SELECT	@ContentData_Guid = ContentData_Guid, 
			@ContentItem_Guid = ContentItem_Guid,
			@CIApproved = Approved
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
			IF (@CIApproved = 0)
			BEGIN
				-- Content item hasnt been approved yet so we can replace it
				EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 1;
				
				UPDATE	ContentData_Binary
				SET		ContentData = @ContentData,
						FileType = @Extension,
						Modified_Date = getUTCdate(),
						Modified_By = @UserGuid,
						ContentData_Version = ContentData_Version + 1
				WHERE	ContentData_Guid = @ContentData_Guid;

				-- Expire old unapproved versions
				UPDATE	ContentData_Binary_Version
				SET		Approved = 1
				WHERE	ContentData_Guid = @ContentData_Guid
						AND Approved = 0;
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
			END
							
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
		
		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE	ContentData_Binary
			SET		Modified_Date = getUTCdate(),
					Modified_By = @UserGuid,
					ContentData_Version = ContentData_Version + 1
			WHERE	ContentData_Guid = @ContentData_Guid;
		END
	END

	DELETE	FROM Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItem_Guid;
	
	UPDATE	Content_Item
	SET		IsIndexed = 0
	WHERE	ContentItem_Guid = @ContentItem_Guid;
GO

--1954
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
	DECLARE @CIApproved int

	SET NOCOUNT ON;

	SELECT	@ContentData_Guid = ContentData_Guid, 
			@ContentItem_Guid = ContentItem_Guid,
			@CIApproved = Approved
	FROM	Content_Item
	WHERE	ContentItem_Guid = @UniqueId;
	
	SELECT	@Approvals = OptionValue
	FROM	Global_Options
	WHERE	OptionCode = 'REQUIRE_CONTENT_APPROVAL';


	IF (@Approvals = 'true')
	BEGIN
		IF @ContentData_Guid IS NULL OR NOT EXISTS(SELECT ContentData_Guid 
												FROM ContentData_Binary 
												WHERE	ContentData_Guid = @ContentData_Guid)
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
			IF (@CIApproved = 0)
			BEGIN
				-- Content item hasnt been approved yet so we can replace it
				EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 1;
				
				UPDATE	ContentData_Binary
				SET		ContentData = @ContentData,
						FileType = @Extension,
						Modified_Date = getUTCdate(),
						Modified_By = @UserGuid,
						ContentData_Version = ContentData_Version + 1
				WHERE	ContentData_Guid = @ContentData_Guid;

				-- Expire old unapproved versions
				UPDATE	ContentData_Binary_Version
				SET		Approved = 1
				WHERE	ContentData_Guid = @ContentData_Guid
						AND Approved = 0;
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
			END
							
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
		
		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE	ContentData_Binary
			SET		Modified_Date = getUTCdate(),
					Modified_By = @UserGuid,
					ContentData_Version = ContentData_Version + 1
			WHERE	ContentData_Guid = @ContentData_Guid;
		END
	END

	DELETE	FROM Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItem_Guid;
	
	UPDATE	Content_Item
	SET		IsIndexed = 0
	WHERE	ContentItem_Guid = @ContentItem_Guid;
GO


--1955
ALTER procedure [dbo].[spContent_ContentItemListBySearchFullText]
	@BusinessUnitGuid uniqueidentifier,
	@SearchString NVarChar(1000),
	@FullTextSearchString NVarChar(1000),
	@ContentTypeId Int
AS
	SELECT	ci.*, 
			Content.FileType, 
			Content.Modified_Date, 
			Intelledox_User.UserName,
			0 as HasUnapprovedRevision,
			0 AS CanEdit
	FROM	content_item ci
			LEFT JOIN (
				SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
				FROM	ContentData_Binary
				UNION
				SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
				FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
			LEFT JOIN Category ON ci.Category = Category.Category_ID
	WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
			AND ci.Approved = 2
			AND ci.ContentType_Id = @ContentTypeId
			AND (ci.NameIdentity LIKE '%' + @SearchString + '%'
				OR ci.Description LIKE '%' + @SearchString + '%'
				OR Category.Name LIKE '%' + @SearchString + '%'
				OR (ci.ContentData_Guid IN (
						SELECT	ContentData_Guid
						FROM	ContentData_Binary cdb
						WHERE	Contains(*, @FullTextSearchString)
						)
					OR
					ci.ContentData_Guid IN (
						SELECT	ContentData_Guid
						FROM	ContentData_Text cdt
						WHERE	Contains(*, @FullTextSearchString)
						)
					)
				)
	ORDER BY ci.NameIdentity;
GO


