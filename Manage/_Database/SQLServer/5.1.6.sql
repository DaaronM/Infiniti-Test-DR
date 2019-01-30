/*
** Database Update package 5.1.6
*/

--set version
truncate table dbversion
go
insert into dbversion values ('5.1.6')
go

--1848
CREATE PROCEDURE [dbo].[spProjectGrp_ProjectGroupList]
      @ProjectGroupGuid uniqueidentifier
as
    SELECT	a.Template_Group_ID, a.[Name] as Template_Group_Name, a.template_group_guid, 
			a.helptext as TemplateGroup_HelpText, b.template_guid, b.Layout_Guid
    FROM	Template_Group a
			LEFT JOIN Template_Group_Item b on a.template_group_id = b.template_group_id
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;
GO
CREATE PROCEDURE [dbo].[spProjectGrp_RemoveProjectGroup]
	@ProjectGroupGuid uniqueidentifier
AS
	-- Remove the group records
	DELETE Package_Template WHERE Template_Group_Id IN (SELECT Template_Group_Id FROM Template_Group_Item WHERE Template_Group_Guid = @ProjectGroupGuid);
	DELETE Template_Group_Item WHERE Template_Group_Guid = @ProjectGroupGuid;
	DELETE Template_Group WHERE Template_Group_Guid = @ProjectGroupGuid;
GO
CREATE PROCEDURE [dbo].[spProjectGrp_UpdateProjectGroup]
	@ProjectGroupGuid uniqueidentifier,
	@Name nvarchar(100),
	@HelpText nvarchar(4000)
as
	IF NOT EXISTS(SELECT * FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid)
	BEGIN
		INSERT INTO Template_Group ([name], fixed_subscription, share_resources, template_group_guid, helptext)
		VALUES (@Name, '0', '0', @ProjectGroupGuid, @HelpText);
	END
	ELSE
	BEGIN
		UPDATE	Template_Group
		SET		[Name] = @Name,
				HelpText = @HelpText
		WHERE	Template_Group_Guid = @ProjectGroupGuid;
	END
GO
CREATE PROCEDURE [dbo].[spProjectGrp_UnsubscribeProjectGroup]
	@ProjectGuid uniqueidentifier,
	@ProjectGroupGuid uniqueidentifier
AS
	DELETE	Template_Group_Item
	WHERE	Template_Group_Guid = @ProjectGroupGuid
			AND Template_Guid = @ProjectGuid;
GO
CREATE PROCEDURE [dbo].[spProjectGrp_SubscribeProjectGroup]
	@ProjectGroupGuid uniqueidentifier,
	@ProjectGuid uniqueidentifier,
	@LayoutGuid uniqueidentifier
AS
	DECLARE @SubscriptionCount int,
		@TemplateId int,
		@LayoutId int,
		@TemplateGroupId int
	
	SELECT	@SubscriptionCount = COUNT(*)
	FROM	Template_Group_Item
	WHERE	Template_Group_Guid = @ProjectGroupGuid
			AND Template_Guid = @ProjectGuid;
	
	IF @SubscriptionCount = 0
	BEGIN
		SELECT	@TemplateId = Template_Id FROM template WHERE template_guid = @ProjectGuid;
		SELECT	@LayoutId = Template_Id FROM template WHERE template_guid = @LayoutGuid;
		SELECT	@TemplateGroupId = Template_Group_Id FROM template_group WHERE template_Group_Guid = @ProjectGroupGuid;

		INSERT INTO Template_Group_Item (template_group_id, template_id, layout_id, template_Group_guid, template_guid, layout_guid)
		VALUES (@TemplateGroupID, @TemplateID, @LayoutID, @ProjectGroupGuid, @ProjectGuid, @LayoutGuid);
	END
GO
ALTER PROCEDURE [dbo].[spTemplateGrp_SubscribeFolder]
	@TemplateGroupGuid uniqueidentifier,
	@FolderID int,
	@ErrorCode int output
as
	DECLARE @SubscriptionCount int
	DECLARE @TemplateGroupID int
	
	SELECT	@TemplateGroupID = Template_Group_Id
	FROM	Template_Group
	WHERE	Template_Group_Guid = @TemplateGroupGuid;
	
	SELECT	@SubscriptionCount = COUNT(*)
	FROM	Folder_Template
	WHERE	folderitem_ID = @TemplateGroupID
			AND Folder_ID = @FolderID
			AND itemtype_id = 1;
	
	IF @SubscriptionCount = 0
	begin
		INSERT INTO Folder_Template
		VALUES (@FolderID, @TemplateGroupID, 1);
	end
	
	set @ErrorCode = @@error
GO
ALTER procedure [dbo].[spTemplateGrp_SubscribePackageTemplate]
	@PackageId int,
	@TemplateGroupGuid uniqueidentifier,
	@OrderId int,
	@Unsubscribe char(1) = '0',
	@Reorder int = 0,
	@ErrorCode int output
as
/*
Vers	Date		Developer	Description
-------------------------------------------------------------------------------------------------------------
1.2.5	24/04/2006	Chrisg		Procedure created
-------------------------------------------------------------------------------------------------------------
*/
	declare @count int,
			@swapOrder int,
			@TemplateGroupId int
			
	SELECT	@TemplateGroupId = Template_Group_Id
	FROM	Template_Group
	WHERE	Template_Group_Guid = @TemplateGroupGuid;

	if @Reorder = 0
	begin
		if @Unsubscribe = '0'
		begin
			select @count = count(*)
			from package_template
			where package_id = @PackageId 
			and Template_Group_Id = @TemplateGroupId;

			if @count = 0
				insert into package_template (Package_Id, Template_Group_Id, Order_Id)
				values (@PackageId, @TemplateGroupId, @OrderId);
			else --just update the orderid
				update package_template
				set Order_Id = @OrderId
				where package_id = @PackageId
				and Template_Group_Id = @TemplateGroupId;
		end
		else
		begin
			delete package_template
			where package_id = @PackageId
			and template_group_id = @TemplateGroupId;
		end
	end
	else
	begin
		update package_template
		set order_id = @OrderId
		where package_id = @PackageId
		and order_id = @OrderId + @Reorder;

		update package_template
		set order_id = @OrderId + @Reorder
		where package_id = @PackageId
		and template_group_id = @TemplateGroupId;
	end
GO

--1849
CREATE PROCEDURE dbo.spProjectGp_IdToGuid
	@id int
AS
	SELECT	Template_Group_Guid
	FROM	Template_Group
	WHERE	Template_Group_Id = @id;
GO
CREATE PROCEDURE [dbo].[spProjectGrp_ProjectGroupListByFolder]
	@FolderId int
AS
	SELECT	d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, b.FormatTypeId, d.Template_Group_Guid,
			b.Template_Guid, e.Layout_Guid
	FROM	Folder a
			INNER JOIN Folder_Template c on a.Folder_ID = c.Folder_ID
			INNER JOIN Template_Group d on c.folderitem_ID = d.Template_Group_ID and itemtype_id = 1
			INNER JOIN Template_Group_Item e on d.Template_Group_ID = e.Template_Group_ID
			INNER JOIN Template b on e.Template_ID = b.Template_ID
	WHERE	a.Folder_Id = @FolderId
	ORDER BY d.[Name], b.[Name], c.folderitem_id;
GO
CREATE PROCEDURE [dbo].[spProjectGrp_ProjectCategoryList]
	@ProjectGuid uniqueidentifier
AS
	SELECT	Category.*
	FROM	Template a 
			INNER JOIN Template_Category b on a.Template_ID = b.Template_ID
			INNER JOIN Category ON b.Category_Id = Category.Category_Id
	WHERE	a.Template_Guid = @ProjectGuid;
GO
ALTER PROCEDURE [dbo].[spTemplateGrp_UnsubscribeCategory]
	@TemplateGuid uniqueidentifier,
	@CategoryID int
as
	DECLARE @TemplateId int
	
	SELECT	@TemplateId = Template_Id
	FROM	Template
	WHERE	Template_Guid = @TemplateGuid;

	DELETE	template_category
	WHERE	template_id = @TemplateID
			AND category_id = @CategoryID;
GO
ALTER PROCEDURE [dbo].[spTemplateGrp_SubscribeCategory]
	@TemplateGuid uniqueidentifier,
	@CategoryID int
as
	DECLARE @TemplateId int
	
	SELECT	@TemplateId = Template_Id
	FROM	Template
	WHERE	Template_Guid = @TemplateGuid;
	
	DELETE	Template_category 
	WHERE	template_id = @TemplateID 
			and category_id = @CategoryID;

	INSERT INTO Template_category(Template_Id, Category_id)
	VALUES (@TemplateID, @CategoryID);
GO

--1850
ALTER PROCEDURE [dbo].[spTemplate_TemplateUnsubscribeGroup]
	@TemplateGuid uniqueidentifier,
	@UserGroupGuid uniqueidentifier,
	@UnsubscribeAll bit
AS
	DECLARE @TemplateId Int
	DECLARE @UserGroupId Int
	
	SELECT	@TemplateId = Template_Id
	FROM	Template
	WHERE	Template_Guid = @TemplateGuid;
	
	SELECT	@UserGroupId = User_Group_Id
	FROM	User_Group
	WHERE	Group_Guid = @UserGroupGuid;
	
	IF @UnsubscribeAll = 1
	BEGIN
		DELETE	User_group_template
		WHERE	Template_id = @TemplateId;
	END
	ELSE
	BEGIN
		DELETE	User_Group_template
		WHERE	Template_Id = @TemplateID
				AND User_Group_id = @UserGroupID;
	END
GO
ALTER PROCEDURE [dbo].[spTemplate_TemplateSubscribeGroup]
	@TemplateGuid uniqueidentifier,
	@UserGroupGuid uniqueidentifier
AS
	DECLARE @Subscribed int
	DECLARE @TemplateId Int
	DECLARE @UserGroupId Int
	
	SELECT	@TemplateId = Template_Id
	FROM	Template
	WHERE	Template_Guid = @TemplateGuid;
	
	SELECT	@UserGroupId = User_Group_Id
	FROM	User_Group
	WHERE	Group_Guid = @UserGroupGuid;

	SELECT	@Subscribed = COUNT(*)
	FROM	User_group_template
	WHERE	Template_id = @TemplateID
		AND user_Group_id = @UserGroupID
		AND (template_group_id = 0 or template_group_id is null);
	
	IF @Subscribed = 0
	BEGIN
		INSERT INTO user_Group_template (User_Group_Id, Template_Group_Id, Template_Id)
		VALUES (@UserGroupID, 0, @TemplateID);
	END
GO
ALTER procedure [dbo].[spTemplate_RemoveTemplate]
	@TemplateGuid uniqueidentifier,
	@OnlyChildInfo bit
as
/*
MODIFICATION HISTORY

3.2.1	chrisg	remove questions that are not in use by any other templates.
---INTELLEDOX----
1.1.4	chrisg	remove any references to it from content templates
1.3.4	chrisg	alter answer removal so it is still removed even if no bookmarks are assigned to the answer
*/
	DECLARE @TemplateId Int

	SELECT	@TemplateId = Template_Id
	FROM	Template
	WHERE	Template_Guid = @TemplateGuid;

	DELETE	template_macro
	WHERE	template_id = @TemplateID;

	IF @OnlyChildInfo = 0
	BEGIN
		DELETE	template_Group_item
		WHERE	template_id = @TemplateID
			OR	layout_id = @TemplateID;

		DELETE	template_Group
		WHERE	Template_Group_id NOT IN (
			SELECT	Template_Group_id
			FROM	Template_Group_Item
		);

		DELETE	Package_Template
		WHERE	Template_Group_id NOT IN (
			SELECT	Template_Group_id
			FROM	template_Group
		);

		DELETE	Market
		WHERE	TemplateGuid = @TemplateGuid;

		DELETE	Template_Category
		WHERE	Template_ID = @TemplateID;

		DELETE	User_Group_Template
		WHERE	Template_ID = @TemplateID;

		UPDATE	template 
		SET		layout_id = 0 
		WHERE	layout_id = @TemplateID;
	END
	
	DELETE template
	WHERE template_id = @TemplateID;
GO
ALTER procedure [dbo].[spTemplateGrp_SubscribePackageTemplate]
	@PackageId int,
	@TemplateGroupGuid uniqueidentifier,
	@OrderId int,
	@Unsubscribe char(1) = '0',
	@Reorder int = 0,
	@ErrorCode int output
as
/*
Vers	Date		Developer	Description
-------------------------------------------------------------------------------------------------------------
1.2.5	24/04/2006	Chrisg		Procedure created
-------------------------------------------------------------------------------------------------------------
*/
	declare @count int,
			@swapOrder int,
			@TemplateGroupId int
			
	SET NOCOUNT ON
			
	SELECT	@TemplateGroupId = Template_Group_Id
	FROM	Template_Group
	WHERE	Template_Group_Guid = @TemplateGroupGuid;

	if @Reorder = 0
	begin
		if @Unsubscribe = '0'
		begin
			select @count = count(*)
			from package_template
			where package_id = @PackageId 
			and Template_Group_Id = @TemplateGroupId;

			if @count = 0
				insert into package_template (Package_Id, Template_Group_Id, Order_Id)
				values (@PackageId, @TemplateGroupId, @OrderId);
			else --just update the orderid
				update package_template
				set Order_Id = @OrderId
				where package_id = @PackageId
				and Template_Group_Id = @TemplateGroupId;
		end
		else
		begin
			delete package_template
			where package_id = @PackageId
			and template_group_id = @TemplateGroupId;
		end
	end
	else
	begin
		update package_template
		set order_id = @OrderId
		where package_id = @PackageId
		and order_id = @OrderId + @Reorder;

		update package_template
		set order_id = @OrderId + @Reorder
		where package_id = @PackageId
		and template_group_id = @TemplateGroupId;
	end
GO

--1851
ALTER TABLE dbo.ContentData_Binary
	ADD FileType varchar(5) null,
		tStamp timestamp;
GO
UPDATE	ContentData_Binary
SET		FileType = '.doc'
FROM	ContentData_Binary
		INNER JOIN Content_Item ON ContentData_Binary.ContentData_Guid = Content_Item.ContentData_Guid
WHERE	Content_Item.ContentType_Id = 3;
GO
exec sp_fulltext_database 'enable';
GO
CREATE FULLTEXT CATALOG Intelledox AS DEFAULT;
GO
CREATE FULLTEXT INDEX ON dbo.ContentData_Binary(ContentData TYPE COLUMN FileType) 
   KEY INDEX PK_Content_Binary;
GO
CREATE FULLTEXT INDEX ON dbo.ContentData_Text(ContentData) 
   KEY INDEX PK_ContentData_Text;
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
GO
ALTER PROCEDURE [dbo].[spLibrary_UpdateBinaryByDataGuid] (
	@DataGuid as uniqueidentifier,
	@ContentData as image,
	@Extension as varchar(5)
)
AS
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
			SELECT	ci.*, cib.FileType
			FROM	content_item ci
					LEFT JOIN ContentData_Binary cib ON ci.ContentData_Guid = cib.ContentData_Guid
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity = @Name
			ORDER BY ci.NameIdentity;
		ELSE
			SELECT	ci.*, cib.FileType
			FROM	content_item ci
					LEFT JOIN ContentData_Binary cib ON ci.ContentData_Guid = cib.ContentData_Guid
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity LIKE '%' + @Name + '%'
					AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND ci.Description LIKE '%' + @Description + '%'
					AND (@Category = 0 or ci.Category = @Category)
			ORDER BY ci.NameIdentity;
	ELSE
		SELECT	ci.*, cib.FileType
		FROM	content_item ci
					LEFT JOIN ContentData_Binary cib ON ci.ContentData_Guid = cib.ContentData_Guid
		WHERE	ci.contentitem_guid = @ItemGuid;
	
	set @ErrorCode = @@error;
GO
CREATE procedure [dbo].[spContent_ContentItemListFullText]
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
/*
Vers	Date		Developer	Description
-------------------------------------------------------------------------------------------------------------
5.0.2	23/05/2007	Chrisg		SP created.
-------------------------------------------------------------------------------------------------------------
*/
	IF @ItemGuid is null 
		IF @ExactMatch = 1
			SELECT	ci.*, cib.FileType
			FROM	content_item ci
					LEFT JOIN ContentData_Binary cib ON ci.ContentData_Guid = cib.ContentData_Guid
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity = @Name
			ORDER BY ci.NameIdentity;
		ELSE
			--Full text search
			SELECT	ci.*, cib.FileType
			FROM	content_item ci
					LEFT JOIN ContentData_Binary cib ON ci.ContentData_Guid = cib.ContentData_Guid
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
		SELECT	ci.*, cib.FileType
		FROM	content_item ci
					LEFT JOIN ContentData_Binary cib ON ci.ContentData_Guid = cib.ContentData_Guid
		WHERE	ci.contentitem_guid = @ItemGuid;
	
	set @ErrorCode = @@error;
GO
ALTER procedure [dbo].[spContent_ContentItemListByDefinition]
	@ContentDefinitionGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier,
	@ErrorCode int output
as
/*
Vers	Date		Developer	Description
-------------------------------------------------------------------------------------------------------------
5.0.2	6/06/2007	Chrisg		SP created.
-------------------------------------------------------------------------------------------------------------
*/

	SELECT	ci.*, cdi.SortIndex, cib.FileType
	FROM	content_item ci
			INNER JOIN content_definition_item cdi ON ci.ContentItem_Guid = cdi.ContentItem_Guid
				AND cdi.ContentDefinition_Guid = @ContentDefinitionGuid
			LEFT JOIN ContentData_Binary cib ON ci.ContentData_Guid = cib.ContentData_Guid
	WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
	ORDER BY cdi.SortIndex;
	
	set @ErrorCode = @@error;
GO
CREATE procedure dbo.spContent_IsFullTextEnabled
AS
	SELECT IsNull(INDEXPROPERTY( OBJECT_ID('dbo.ContentData_Binary'), 'PK_Content_Binary',  'IsFulltextKey' ), 0);
GO

