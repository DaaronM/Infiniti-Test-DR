/*
** Database Update package 7.0.4
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.0.4')
go

--1963
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


