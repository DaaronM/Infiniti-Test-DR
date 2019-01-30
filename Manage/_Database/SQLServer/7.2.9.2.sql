/*
** Database Update package 7.2.9.2
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('7.2.9.2');
go

--2007
ALTER procedure [dbo].[spProject_GetFoldersByProject]
	@ProjectGuid uniqueidentifier
AS
	SELECT	Folder.Folder_Name, Folder.Folder_Guid, Template_Group.Template_Group_Guid,
			Template.Template_Type_ID
	FROM	Folder
			INNER JOIN Folder_Template on Folder.Folder_ID = Folder_Template.Folder_ID
			INNER JOIN Template_Group on Folder_Template.FolderItem_ID = Template_Group.Template_Group_ID
			INNER JOIN Template_Group_Item on Template_Group.Template_Group_ID = Template_Group_Item.Template_Group_ID
			INNER JOIN Template on Template_Group_Item.Template_ID = Template.Template_ID
	WHERE	Template.Template_Guid = @ProjectGuid
	ORDER BY Folder.Folder_Name;
GO


