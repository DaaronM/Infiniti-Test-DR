/*
** Database Update package 7.2.3
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.2.3')
go

--1987
ALTER TABLE dbo.Routing_Type
ADD ProviderType INT NULL
GO

--1988
ALTER PROCEDURE [dbo].[spRouting_RegisterType]
	@Id uniqueidentifier,
	@Description nvarchar(255),
	@ProviderType INT
AS
	IF NOT EXISTS(SELECT * FROM Routing_Type WHERE RoutingTypeId = @id)
	BEGIN
		INSERT INTO Routing_Type(RoutingTypeId, RoutingTypeDescription, ProviderType)
		VALUES	(@id, @Description, @ProviderType);
	END
GO

--1989
ALTER procedure [dbo].[spTemplate_RoutingTypeList]
	@ProviderType INT,
	@ErrorCode int = 0 output	
AS
	IF @ProviderType > 0 
		BEGIN 
			SELECT *
			FROM Routing_Type
			WHERE ProviderType=@ProviderType
		END 
	ELSE
		BEGIN 
			SELECT *
			FROM Routing_Type
		END 
	
	SET @errorcode = @@error
GO

--1991
ALTER procedure [dbo].[spContent_ContentItemListBySearch]
	@BusinessUnitGuid uniqueidentifier,
	@SearchString NVarChar(1000),
	@ContentTypeId Int,
	@FolderGuid uniqueidentifier
	
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
				)
				--Search all folders/none folder/specific folder
			AND (
				@FolderGuid = '00000000-0000-0000-0000-000000000000' --all
				OR @FolderGuid = '99999999-9999-9999-9999-999999999999'  AND ci.FolderGuid IS NULL --none
				OR ci.FolderGuid = @FolderGuid --a specific folder
				)
						
	ORDER BY ci.NameIdentity;
GO

--1992
ALTER procedure [dbo].[spContent_ContentItemListBySearchFullText]
	@BusinessUnitGuid uniqueidentifier,
	@SearchString NVarChar(1000),
	@FullTextSearchString NVarChar(1000),
	@ContentTypeId Int,
	@FolderGuid uniqueidentifier
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
				--Search all folders/none folder/specific folder
			AND (
				@FolderGuid = '00000000-0000-0000-0000-000000000000' --all
				OR @FolderGuid = '99999999-9999-9999-9999-999999999999'  AND ci.FolderGuid IS NULL --none
				OR ci.FolderGuid = @FolderGuid --a specific folder
				)
	ORDER BY ci.NameIdentity;
GO

--1993
DELETE FROM User_Session WHERE Modified_Date < DateAdd(wk, -1, GetDate());
GO
ALTER INDEX ALL ON User_Session REORGANIZE;
GO
ALTER INDEX ALL ON Template REORGANIZE;
GO
ALTER INDEX ALL ON Template_Version REORGANIZE;
GO
ALTER INDEX ALL ON Intelledox_User REORGANIZE;
GO
ALTER INDEX ALL ON Template_Log REORGANIZE;
GO
ALTER INDEX ALL ON Answer_File REORGANIZE;
GO
ALTER INDEX ALL ON Content_Item REORGANIZE;
GO
ALTER INDEX ALL ON Content_Item_Placeholder REORGANIZE;
GO
ALTER INDEX ALL ON ContentData_Binary REORGANIZE;
GO
ALTER INDEX ALL ON ContentData_Binary_Version REORGANIZE;
GO
ALTER FULLTEXT CATALOG Intelledox REORGANIZE;
GO


