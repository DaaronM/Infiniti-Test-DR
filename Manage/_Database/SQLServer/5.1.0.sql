/*
** Database Update package 5.1.0
*/

--set version
truncate table dbversion
go
insert into dbversion values ('5.1.0')
go

--1821
CREATE PROCEDURE dbo.spProject_UpdateBinary (
	@TemplateLength int,
	@Bytes image,
	@TemplateGuid uniqueidentifier
)
AS
	UPDATE	Template 
	SET		FILE_LENGTH = @TemplateLength, 
			[BINARY] = @Bytes 
	WHERE	Template_Guid = @TemplateGuid
GO
CREATE PROCEDURE dbo.spProject_UpdateDefinition (
	@Xtf NTEXT,
	@TemplateGuid uniqueidentifier
)
AS
	UPDATE	Template 
	SET		Project_Definition = @XTF 
	WHERE	Template_Guid = @TemplateGuid
GO
CREATE PROCEDURE dbo.spProject_Definition (
	@TemplateGuid uniqueidentifier
)
AS
	SELECT	Project_Definition 
	FROM	Template 
	WHERE	Template_Guid = @TemplateGuid
GO
CREATE PROCEDURE dbo.spProject_Binary (
	@TemplateGuid uniqueidentifier
)
AS
	SELECT	[Binary] 
	FROM	Template 
	WHERE	Template_Guid = @TemplateGuid
GO
CREATE PROCEDURE dbo.spProject_DefinitionsByGroup (
	@TemplateGroupGuid uniqueidentifier
)
AS
	SELECT	Template.Template_Guid, Template.Project_Definition 
	FROM	Template_Group
			INNER JOIN Template_Group_Item ON Template_Group.Template_Group_Guid = Template_Group_Item.Template_Group_Guid
			INNER JOIN Template ON Template_Group_Item.Template_Guid = Template.Template_Guid OR Template_Group_Item.Layout_Guid = Template.Template_Guid
	WHERE	Template_Group.Template_Group_Guid = @TemplateGroupGuid
GO
ALTER PROCEDURE [dbo].[spDataSource_DataKeyList]
	@DataObjectKeyGuid uniqueidentifier = null,
	@DataObjectGuid uniqueidentifier = null	
AS
	IF @DataObjectKeyGuid IS NULL
		SELECT	dk.data_object_key_guid, dk.field_name, dk.required, dk.display_name, dk.data_object_guid,
				dk.Data_Object_Key_Id
		FROM	data_object_key dk
		WHERE	dk.data_object_guid = @DataObjectGuid
		ORDER BY dk.field_name
	ELSE
		SELECT	dk.data_object_key_guid, dk.field_name, dk.required, dk.display_name, dk.data_object_guid,
				dk.Data_Object_Key_Id
		FROM	data_object_key dk
		WHERE	dk.data_object_key_guid = @DataObjectKeyGuid
		ORDER BY dk.field_name
GO
CREATE procedure [dbo].[spProject_UpdateProject]
	@BusinessUnitGuid uniqueidentifier,
	@FormatTypeId int,
	@Name nvarchar(100),
	@ProjectGuid uniqueidentifier,
	@ProjectTypeID int,
	@SupplierGuid uniqueidentifier
as

	IF NOT EXISTS(SELECT Template_Guid FROM Template WHERE Template_Guid = @ProjectGuid)
	BEGIN
		INSERT INTO Template(Business_Unit_Guid, FormatTypeId, Name, Template_Guid, Template_Type_Id, Supplier_Guid)
		VALUES (@BusinessUnitGuid, @FormatTypeId, @Name, @ProjectGuid, @ProjectTypeId, @SupplierGuid)
	END
	ELSE
	BEGIN
		UPDATE	Template
		SET		[name] = @Name, 
				Template_type_id = @ProjectTypeID, 
				FormatTypeId = @FormatTypeID, 
				Supplier_GUID = @SupplierGuid
		WHERE	Template_Guid = @ProjectGuid
	END
GO
DROP procedure [dbo].[spContent_ContentDefinitionListByTemplate]
GO
DROP procedure [dbo].[spContent_ContentItemListByTemplate]
GO
DROP procedure [dbo].[spProject_ProjectObjectList2]
GO
DROP procedure [dbo].[spTemplate_DynamicParentsList] 
GO
DROP procedure [dbo].[spTemplate_QuestionList]
GO
DROP procedure [dbo].[spTemplate_RemoveBookmarkGroup]
GO
DROP procedure [dbo].[spTemplate_RemoveDynamicParent]
GO
DROP procedure [dbo].[spTemplate_RemoveDynamicParentByQuestionID]
GO
DROP procedure [dbo].[spTemplate_RemoveQuestion]
GO
DROP procedure [dbo].[spTemplate_RemoveQuestionFromBookmarkGroup]
GO
DROP procedure [dbo].[spTemplate_TemplateObjectList]
GO
DROP procedure [dbo].[spTemplate_TemplateObjectList2]
GO
DROP procedure [dbo].[spTemplate_UpdateAnswer]
GO
DROP procedure [dbo].[spTemplate_UpdateDynamicParent]
GO
DROP procedure [dbo].[spTemplate_UpdateGroupQuestion]
GO
DROP procedure [dbo].[spTemplate_UpdateQuestion]
GO
DROP procedure [dbo].[spContent_ContentDefinitionListByAnswer]
GO
DROP procedure [dbo].[spContent_ContentItemListByAnswer]
GO
DROP procedure [dbo].[spContent_SubscribeContentAnswer]
GO
DROP procedure [dbo].[spTemplate_RemoveAnswer]
GO
DROP procedure [dbo].[spTemplate_UpdateMetadata]
GO
DROP procedure [dbo].[spTemplate_UpdateRoutingOption]
GO
DROP procedure [dbo].[spTemplate_BookmarkGroupListByTemplateID]
GO
DROP procedure [dbo].[spTemplate_RemoveBookmark]
GO
DROP procedure [dbo].[spTemplate_UpdateBookmark]
GO
DROP procedure [dbo].[spTemplate_UpdateBookmarkGroup]
GO
DROP procedure [dbo].[spImage_ImageList]
GO
DROP procedure [dbo].[spImage_ImageListByGuid]
GO
DROP procedure [dbo].[spImage_ImageTypeList]
GO
DROP procedure [dbo].[spImage_InsertImage]
GO
DROP procedure [dbo].[spImage_RemoveImage]
GO
DROP procedure [dbo].[spImage_SubscribeImageType]
GO
DROP procedure [dbo].[spImage_UpdateImage]
GO
DROP procedure [dbo].[spTemplate_RemoveRoutingOption]
GO
DROP procedure [dbo].[spTemplate_RoutingOptionsListByTemplate]
GO
DROP procedure [dbo].[spTemplate_MetadataList]
GO
DROP procedure [dbo].[spTemplate_MetadataListByTemplate]
GO
DROP procedure [dbo].[spTemplate_RemoveMetadata]
GO
DROP procedure [dbo].[spSite_UpdateSiteStyle]
GO
DROP PROCEDURE [dbo].[spSite_SiteStyleList]
GO
ALTER procedure [dbo].[spTemplate_RemoveTemplate]
	@TemplateID int,
	@OnlyChildInfo bit,
	@ErrorCode int output
as
/*
MODIFICATION HISTORY

3.2.1	chrisg	remove questions that are not in use by any other templates.
---INTELLEDOX----
1.1.4	chrisg	remove any references to it from content templates
1.3.4	chrisg	alter answer removal so it is still removed even if no bookmarks are assigned to the answer
*/
	DECLARE @TemplateGuid uniqueidentifier

	SELECT	@TemplateGuid = Template_Guid
	FROM	Template
	WHERE	Template_id = @TemplateID

	DELETE	template_macro
	WHERE	template_id = @TemplateID

	IF @OnlyChildInfo = 0
	BEGIN
		DELETE	template_Group_item
		WHERE	template_id = @TemplateID
			OR	layout_id = @TemplateID

		DELETE	template_Group
		WHERE	Template_Group_id NOT IN (
			SELECT	Template_Group_id
			FROM	Template_Group_Item
		)

		DELETE	Package_Template
		WHERE	Template_Group_id NOT IN (
			SELECT	Template_Group_id
			FROM	template_Group
		)

		DELETE	Market
		WHERE	TemplateGuid = @TemplateGuid

		DELETE	Template_Category
		WHERE	Template_ID = @TemplateID

		DELETE	User_Group_Template
		WHERE	Template_ID = @TemplateID

		UPDATE	template 
		SET		layout_id = 0 
		WHERE	layout_id = @TemplateID
	END
	
	DELETE template
	WHERE template_id = @TemplateID

	set @ErrorCode = @@error

GO
exec sp_rename 'dbo.Answer', 'zzAnswer'
GO
exec sp_rename 'dbo.Bookmark', 'zzBookmark'
GO
exec sp_rename 'dbo.Bookmark_Group', 'zzBookmark_Group'
GO
exec sp_rename 'dbo.Bookmark_Group_Question', 'zzBookmark_Group_Question'
GO
exec sp_rename 'dbo.ContentLibrary_Answer', 'zzContentLibrary_Answer'
GO
exec sp_rename 'dbo.Dynamic_Question', 'zzDynamic_Question'
GO
exec sp_rename 'dbo.Image_Type', 'zzImage_Type'
GO
exec sp_rename 'dbo.ImageType_Image', 'zzImageType_Image'
GO
exec sp_rename 'dbo.Question', 'zzQuestion'
GO
exec sp_rename 'dbo.Routing_Options', 'zzRouting_Options'
GO
exec sp_rename 'dbo.Metadata', 'zzMetadata'
GO
exec sp_rename 'dbo.Site_Style', 'zzSite_Style'
GO
ALTER procedure [dbo].[spTemplate_TemplateList]
	@TemplateID int = 0,
	@TemplateGuid uniqueidentifier = null,
	@ErrorCode int output
as
/*
Vers	Date		Developer	Description
-------------------------------------------------------------------------------------------------------------
3.1.2	24/07/2004	Chrisg		modified to support guids for import/export
4.0.0	14/06/2005	Chrisg		returns Store_Xml field to support web
4.6.0	18/12/2006	Chrisg		store_xml changed to web_template, added support for formattypeid
-------------------------------------------------------------------------------------------------------------
*/
	If @TemplateGuid IS NOT NULL
	BEGIN
		SELECT	@TemplateId = Template_Id
		FROM	Template
		WHERE	Template_Guid = @TemplateGuid
	END

	IF @TemplateID = 0 
		SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.file_length, a.fax_template_id, 
				a.layout_id, a.xlmodel_file, a.template_guid, a.web_template,  b.Category_ID, 
				b.[Name] as Category_Name, a.FormatTypeId, a.Supplier_Guid, a.Business_Unit_Guid,
				a.Content_Bookmark, a.HelpText
		FROM	Template a
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
		ORDER BY a.[Name]
	ELSE
		SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.file_length, a.fax_template_id, 
				a.layout_id, a.xlmodel_file, a.template_guid, a.web_template, b.Category_ID, 
				b.[Name] as Category_Name, a.FormatTypeId, a.Supplier_Guid, a.Business_Unit_Guid,
				a.Content_Bookmark, a.HelpText
		FROM	Template a
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
		WHERE	a.template_id = @TemplateID
		ORDER BY a.[Name]

	set @ErrorCode = @@error
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
/*
Vers	Date		Developer	Description
-------------------------------------------------------------------------------------------------------------
5.0.2	23/05/2007	Chrisg		SP created.
-------------------------------------------------------------------------------------------------------------
*/
	IF @ItemGuid is null 
		IF @ExactMatch = 1
			SELECT	*
			FROM	content_item
			WHERE	Business_Unit_GUID = @BusinessUnitGuid
					AND NameIdentity = @Name
			ORDER BY NameIdentity
		ELSE
			SELECT	*
			FROM	content_item
			WHERE	Business_Unit_GUID = @BusinessUnitGuid
					AND NameIdentity LIKE @Name + '%'
					AND (ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND Description LIKE '%' + @Description + '%'
					AND (@Category = 0 or Category = @Category)
			ORDER BY NameIdentity
	ELSE
		SELECT	*
		FROM	content_item
		WHERE	contentitem_guid = @ItemGuid
	
	set @ErrorCode = @@error
GO

