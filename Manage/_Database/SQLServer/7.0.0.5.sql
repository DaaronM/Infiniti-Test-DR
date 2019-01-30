/*
** Database Update package 7.0.0.5
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.0.0.5')
go

--1952
ALTER procedure [dbo].[spContent_ContentItemListByFolder]
	@FolderGuid uniqueidentifier,
	@UserId uniqueidentifier
as
	SELECT	Content_Item.*, 
		ContentData_Binary.FileType, 
		ContentData_Binary.Modified_Date, 
		Intelledox_User.Username,
		0 As HasUnapprovedRevision,
		CASE WHEN (@UserId IS NULL 
			OR Content_Item.FolderGuid IS NULL 
			OR (NOT EXISTS (
				SELECT * 
				FROM Content_Folder_Group 
				WHERE Content_Item.FolderGuid = Content_Folder_Group.FolderGuid))
			OR EXISTS (
				SELECT * 
				FROM Content_Folder_Group
					INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
					INNER JOIN User_Group_Subscription ON User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
					INNER JOIN Intelledox_User ON User_Group_Subscription.User_ID = Intelledox_User.User_ID
				WHERE Intelledox_User.User_Guid = @UserId
					AND Content_Item.FolderGuid = Content_Folder_Group.FolderGuid))
		THEN 1 ELSE 0 END
		AS CanEdit
	FROM	Content_Item
		LEFT JOIN ContentData_Binary ON Content_Item.ContentData_Guid = ContentData_Binary.ContentData_Guid
		LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = ContentData_Binary.Modified_By
	WHERE	FolderGuid = @FolderGuid
		OR (FolderGuid IS NULL AND @FolderGuid IS NULL)
	ORDER BY Content_Item.ContentType_Id,
		Content_Item.NameIdentity
GO


