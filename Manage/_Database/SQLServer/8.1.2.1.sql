/*
** Database Update package 8.1.2.1
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.1.2.1');
go

--2067
ALTER procedure [dbo].[spProjectGrp_ProjectGroupListByFolder]
	@FolderGuid uniqueidentifier,
	@IncludeRestricted bit
AS
	SELECT	d.Template_Group_ID, b.Name as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, d.Template_Group_Guid,
			b.Template_Guid, e.Layout_Guid
	FROM	Folder a
			INNER JOIN Folder_Template c on a.Folder_ID = c.Folder_ID
			INNER JOIN Template_Group d on c.folderitem_ID = d.Template_Group_ID and itemtype_id = 1
			INNER JOIN Template_Group_Item e on d.Template_Group_Guid = e.Template_Group_Guid
			INNER JOIN Template b on e.Template_Guid = b.Template_Guid
	WHERE	a.Folder_Guid = @FolderGuid
			AND ((d.EnforcePublishPeriod = 0 OR @IncludeRestricted = 1)
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getdate())))
	ORDER BY b.[Name], c.folderitem_id;
GO

