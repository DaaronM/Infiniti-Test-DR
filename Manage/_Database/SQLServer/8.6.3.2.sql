truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.3.2');
go
UPDATE Folder
SET	Folder_Name = ''
WHERE Folder_Name IS NULL
GO
UPDATE Folder
SET	Folder_Guid = newid()
WHERE Folder_Guid IS NULL
GO
UPDATE Folder
SET	Business_Unit_GUID = newid()
WHERE Business_Unit_GUID IS NULL
GO
CREATE TABLE dbo.Tmp_Folder
	(
	Folder_ID int NOT NULL IDENTITY (1, 1),
	Folder_Name nvarchar(50) NOT NULL,
	Business_Unit_GUID uniqueidentifier NOT NULL,
	Folder_Guid uniqueidentifier NOT NULL
	)
GO
ALTER TABLE dbo.Tmp_Folder ADD CONSTRAINT
	pk_Folder PRIMARY KEY CLUSTERED 
	(
	Folder_Guid
	)
GO
CREATE NONCLUSTERED INDEX IX_Folder_FolderId ON dbo.Tmp_Folder
	(
	Folder_ID
	)
GO
CREATE NONCLUSTERED INDEX IX_Folder_FolderName ON dbo.Tmp_Folder
	(
	Business_Unit_GUID,
	Folder_Name
	)
GO
SET IDENTITY_INSERT dbo.Tmp_Folder ON
GO
IF EXISTS(SELECT * FROM dbo.Folder)
	 EXEC('INSERT INTO dbo.Tmp_Folder (Folder_ID, Folder_Name, Business_Unit_GUID, Folder_Guid)
		SELECT Folder_ID, Folder_Name, Business_Unit_GUID, Folder_Guid FROM dbo.Folder')
GO
SET IDENTITY_INSERT dbo.Tmp_Folder OFF
GO
DROP TABLE dbo.Folder
GO
EXECUTE sp_rename N'dbo.Tmp_Folder', N'Folder', 'OBJECT' 
GO
ALTER procedure [dbo].[spProjectGrp_RemoveFolder]
	@FolderGuid uniqueidentifier
AS
	SET NOCOUNT ON
	
	DELETE Template_Group WHERE Folder_Guid = @FolderGuid;
	DELETE Folder WHERE Folder_Guid = @FolderGuid;
GO

UPDATE Content_Folder
SET	FolderName = ''
WHERE FolderName IS NULL
GO
UPDATE Content_Folder
SET	BusinessUnitGuid = newid()
WHERE BusinessUnitGuid IS NULL
GO
ALTER TABLE dbo.Content_Folder
	ALTER COLUMN FolderName nvarchar(50) NOT NULL
GO
ALTER TABLE dbo.Content_Folder
	ALTER COLUMN BusinessUnitGuid uniqueidentifier NOT NULL
GO
CREATE NONCLUSTERED INDEX IX_Content_Folder ON dbo.Content_Folder
	(
	BusinessUnitGuid,
	FolderName
	)
GO

ALTER procedure [dbo].[spContent_ContentItemListBySearch]
	@BusinessUnitGuid uniqueidentifier,
	@SearchString NVarChar(1000),
	@ContentTypeId Int,
	@FolderGuid uniqueidentifier
	
AS
	IF @SearchString IS NULL OR @SearchString = ''
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Intelledox_User.UserName,
				0 as HasUnapprovedRevision,
				0 AS CanEdit,
				Content_Folder.FolderName
		FROM	content_item ci
				LEFT JOIN (
					SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
					FROM	ContentData_Binary
					UNION
					SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
					FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
				LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
		WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
				AND ci.Approved = 2
				AND ci.ContentType_Id = @ContentTypeId
					--Search all folders/none folder/specific folder
				AND (
					@FolderGuid = '00000000-0000-0000-0000-000000000000' --all
					OR (@FolderGuid = '99999999-9999-9999-9999-999999999999'  AND ci.FolderGuid IS NULL) --none
					OR ci.FolderGuid = @FolderGuid --a specific folder
					)
		ORDER BY ci.NameIdentity;
ELSE
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Intelledox_User.UserName,
				0 as HasUnapprovedRevision,
				0 AS CanEdit,
				Content_Folder.FolderName
		FROM	content_item ci
				LEFT JOIN (
					SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
					FROM	ContentData_Binary
					UNION
					SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
					FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
				LEFT JOIN Category ON ci.Category = Category.Category_ID
				LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
		WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
				AND ci.Approved = 2
				AND ci.ContentType_Id = @ContentTypeId
				AND (ci.NameIdentity LIKE '%' + @SearchString + '%'
					OR ci.Description LIKE '%' + @SearchString + '%'
					OR Category.Name LIKE '%' + @SearchString + '%'
					)
					--Search all folders/none folder/specific folder
				AND (
					@FolderGuid = '00000000-0000-0000-0000-000000000000' --all
					OR (@FolderGuid = '99999999-9999-9999-9999-999999999999'  AND ci.FolderGuid IS NULL) --none
					OR ci.FolderGuid = @FolderGuid --a specific folder
					)
		ORDER BY ci.NameIdentity;
GO
