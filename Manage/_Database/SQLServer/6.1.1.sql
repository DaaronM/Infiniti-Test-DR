/*
** Database Update package 6.1.1
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.1.1')
go

--1875
ALTER procedure [dbo].[spProjectGrp_PublishPackage]
	@TemplatePackageId int,
	@FolderGuid uniqueidentifier
AS
	DECLARE @SubscriptionCount int
	DECLARE @FolderId Int
	
	SELECT	@FolderId = Folder_Id
	FROM	Folder
	WHERE	Folder_Guid = @FolderGuid;
	
	SELECT	@SubscriptionCount = COUNT(*)
	FROM	Folder_Template
	WHERE	Folderitem_ID = @TemplatePackageId
		AND Folder_ID = @FolderId
		AND itemtype_id = 2;
		
	IF @SubscriptionCount = 0
	BEGIN
		INSERT INTO Folder_Template(Folder_ID, FolderItem_Id, ItemType_Id)
		VALUES (@FolderID, @TemplatePackageId, 2);
	END
GO


--1876
sp_updatestats
GO


