/*
** Database Update package 6.0.4
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.0.4')
go

--1868
ALTER TABLE dbo.Custom_Field
	DROP CONSTRAINT PK_Custom_Field
GO
ALTER TABLE dbo.Custom_Field ADD CONSTRAINT
	PK_Custom_Field PRIMARY KEY NONCLUSTERED 
	(
	Custom_Field_ID
	) 

GO
CREATE CLUSTERED INDEX IX_Custom_Field_LocationTitle ON dbo.Custom_Field
	(
	Location,
	Title
	) 
GO
ALTER TABLE dbo.Folder_Template
	DROP CONSTRAINT Folder_Template_pk
GO
ALTER TABLE dbo.Folder_Template ADD CONSTRAINT
	Folder_Template_pk PRIMARY KEY NONCLUSTERED 
	(
	Folder_Template_ID
	)

GO
CREATE CLUSTERED INDEX IX_Folder_Template_FolderItem ON dbo.Folder_Template
	(
	Folder_ID,
	FolderItem_Id
	)
GO
DROP INDEX IX_Template_Group_Item_Group_Guid ON dbo.Template_Group_Item
GO
ALTER TABLE dbo.Template_Group_Item
	DROP CONSTRAINT Template_Group_Item_pk
GO
ALTER TABLE dbo.Template_Group_Item ADD CONSTRAINT
	Template_Group_Item_pk PRIMARY KEY NONCLUSTERED 
	(
	Template_Group_Item_ID
	) 

GO
CREATE CLUSTERED INDEX IX_Template_Group_Item_Group_Guid ON dbo.Template_Group_Item
	(
	Template_Group_Guid,
	Template_Guid
	)
GOALTER TABLE dbo.Package_Template
	DROP CONSTRAINT PK_Package_Template
GO
ALTER TABLE dbo.Package_Template ADD CONSTRAINT
	PK_Package_Template PRIMARY KEY NONCLUSTERED 
	(
	Package_Template_Id
	)

GO
CREATE CLUSTERED INDEX IX_Package_Template ON dbo.Package_Template
	(
	Package_Id,
	Template_Group_Id
	)
GO
ALTER TABLE dbo.User_Group
	DROP CONSTRAINT User_Group_pk
GO
ALTER TABLE dbo.User_Group ADD CONSTRAINT
	User_Group_pk PRIMARY KEY NONCLUSTERED 
	(
	User_Group_ID
	) 

GO
CREATE CLUSTERED INDEX IX_User_Group_GroupGuid ON dbo.User_Group
	(
	Group_Guid
	)
GO

--1869
CREATE TABLE dbo.Content_Item_Placeholder
	(
	ContentItemGuid uniqueidentifier NOT NULL,
	PlaceholderName varchar(50) NOT NULL
	)  ON [PRIMARY]
GO
CREATE CLUSTERED INDEX IX_Content_Item_Placeholder ON dbo.Content_Item_Placeholder
	(
	ContentItemGuid
	)
GO
ALTER TABLE dbo.Content_Item
	ADD IsIndexed bit NULL;
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
	IF NOT EXISTS(SELECT * FROM Content_Item WHERE ContentItem_Guid = @ContentItemGuid)
	begin
		INSERT INTO Content_Item (ContentItem_Guid, [Description], NameIdentity, ContentType_Id, Business_Unit_Guid, ContentData_Guid, SizeScale, Category, Provider_Name, Reference_Id, IsIndexed)
		VALUES (@ContentItemGuid, @Description, @Name, @ContentTypeId, @BusinessUnitGuid, @ContentDataGuid, @SizeScale, @Category, @ProviderName, @ReferenceId, 0)
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
		WHERE ContentItem_Guid = @ContentItemGuid
GO
ALTER PROCEDURE [dbo].[spLibrary_UpdateBinary] (
	@UniqueId as uniqueidentifier,
	@ContentData as image,
	@Extension as varchar(5)
)
AS
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @ContentItem_Guid uniqueidentifier

	SELECT	@ContentData_Guid = ContentData_Guid, @ContentItem_Guid = ContentItem_Guid
	FROM	Content_Item
	WHERE	ContentItem_Guid = @UniqueId;

	IF EXISTS(SELECT ContentData_Guid FROM ContentData_Binary WHERE ContentData_Guid = @ContentData_Guid)
	BEGIN
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

			INSERT INTO ContentData_Binary(ContentData_Guid, ContentData, FileType)
			VALUES (@ContentData_Guid, @ContentData, @Extension);

			UPDATE	Content_Item
			SET		ContentData_Guid = @ContentData_Guid
			WHERE	ContentItem_Guid = @UniqueId;
		END
	END
		
	DELETE	FROM Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItem_Guid;
	
	UPDATE	Content_Item
	SET		IsIndexed = 0
	WHERE	ContentItem_Guid = @ContentItem_Guid;
GO
ALTER PROCEDURE [dbo].[spLibrary_UpdateBinaryByDataGuid] (
	@DataGuid as uniqueidentifier,
	@ContentData as image,
	@Extension as varchar(5)
)
AS
	DECLARE @ContentItem_Guid uniqueidentifier

	SELECT	@ContentItem_Guid = ContentItem_Guid
	FROM	Content_Item
	WHERE	ContentData_Guid = @DataGuid;
	
	IF EXISTS(SELECT ContentData_Guid FROM ContentData_Binary WHERE ContentData_Guid = @DataGuid)
	BEGIN
		UPDATE	ContentData_Binary
		SET		ContentData = @ContentData,
				FileType = @Extension
		WHERE	ContentData_Guid = @DataGuid;
	END
	ELSE
	BEGIN
		INSERT INTO ContentData_Binary(ContentData_Guid, ContentData, FileType)
		VALUES (@DataGuid, @ContentData, @Extension);
	END
		
	DELETE	FROM Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItem_Guid;
	
	UPDATE	Content_Item
	SET		IsIndexed = 0
	WHERE	ContentItem_Guid = @ContentItem_Guid;
GO
CREATE PROCEDURE dbo.spContent_ContentItemPlaceholderList
	@ContentItemGuid uniqueidentifier
AS
	SET NOCOUNT ON;
	
	SELECT	*
	FROM	Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItemGuid;
	
	IF @@RowCount = 0
	BEGIN
		IF EXISTS(SELECT * FROM Content_Item WHERE ContentItem_Guid = @ContentItemGuid AND IsIndexed = 1)
			RETURN 1;
		ELSE
			RETURN 0;
	END
	ELSE
	BEGIN
		RETURN 1;
	END
GO
CREATE PROCEDURE dbo.spContent_UpdatePlaceholder
	@ContentItemGuid uniqueidentifier,
	@Placeholder varchar(50)
AS
	INSERT INTO Content_Item_Placeholder(ContentItemGuid, PlaceholderName)
	VALUES (@ContentItemGuid, @Placeholder);
GO

