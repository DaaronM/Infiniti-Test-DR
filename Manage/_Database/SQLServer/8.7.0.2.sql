truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.7.0.2');
go
CREATE PROCEDURE [dbo].[spUser_GetUser]
	@UserID int,
	@UserGuid uniqueidentifier = null
AS
BEGIN
	if @UserGuid is null
	begin
		select	Intelledox_User.*, Address_Book.Full_Name
		from	Intelledox_User
			left join Address_Book on Intelledox_User.Address_Id = Address_Book.Address_id
		where	Intelledox_User.[User_ID] = @UserID;
	end
	else
	begin
		select	Intelledox_User.*, Address_Book.Full_Name
		from	Intelledox_User
			left join Address_Book on Intelledox_User.Address_Id = Address_Book.Address_id
		where	Intelledox_User.User_Guid = @UserGuid;
	end
END
GO

ALTER procedure [dbo].[spContent_RemoveContentItem]
	@ContentItemGuid uniqueidentifier
AS
	DECLARE @ContentDataGuid uniqueidentifier;
	
	SET		@ContentDataGuid = (SELECT ContentData_Guid FROM Content_Item WHERE ContentItem_Guid = @ContentItemGuid);

	DELETE	Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItemGuid;
	
	DELETE	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;

	DELETE	Xtf_ContentLibrary_Dependency
	WHERE	Content_Object_Guid = @ContentItemGuid;
	
	DELETE	ContentData_Binary
	WHERE	ContentData_Guid = @ContentDataGuid;
	
	DELETE	ContentData_Binary_Version
	WHERE	ContentData_Guid = @ContentDataGuid;

	DELETE	ContentData_Text
	WHERE	ContentData_Guid = @ContentDataGuid;
	
	DELETE	ContentData_Text_Version
	WHERE	ContentData_Guid = @ContentDataGuid;

GO

DELETE FROM Xtf_ContentLibrary_Dependency
  WHERE Xtf_ContentLibrary_Dependency.Content_Object_Guid
  NOT IN (SELECT Content_Item.ContentItem_Guid FROM Content_Item)

GO

ALTER procedure [dbo].[spDataSource_HasAccess]
	@DataObjectGuid varchar(40),
	@UserGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier
as
	SET ARITHABORT ON 

	;WITH dataDependency (Template_Guid)
	AS
	(
		--Select all data source dependencies for the data object
		SELECT	dsDependency.Template_Guid
		FROM	Xtf_Datasource_Dependency dsDependency
		WHERE dsDependency.Data_Object_Guid = @DataObjectGuid
		UNION ALL
		--Select all related fragments
		SELECT fDependency.Template_Guid
		FROM Xtf_Fragment_Dependency fDependency
			INNER JOIN dataDependency AS dd ON fDependency.Fragment_Guid = dd.Template_Guid
	) 

	SELECT 	TOP 1
	1
	FROM	Template
		INNER JOIN dataDependency on dataDependency.Template_Guid = Template.Template_Guid
		INNER JOIN Template_Group ON Template_Group.Template_Guid = Template.Template_Guid
				OR Template_Group.Layout_Guid = Template.Template_Guid
				OR dataDependency.Template_Guid = Template.Template_Guid
		INNER JOIN Folder_Group ON Folder_Group.FolderGuid = Template_Group.Folder_Guid
		INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = Folder_Group.GroupGuid
		INNER JOIN Xtf_Datasource_Dependency ON Xtf_Datasource_Dependency.Template_Guid = Template.Template_Guid
	WHERE	
		Template.Business_Unit_GUID = @BusinessUnitGuid
		AND User_Group_Subscription.UserGuid = @UserGuid
		AND Xtf_Datasource_Dependency.Data_Object_Guid = @DataObjectGuid

GO
