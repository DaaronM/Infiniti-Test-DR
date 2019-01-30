/*
** Database Update package 5.1.1.3
*/

--set version
truncate table dbversion
go
insert into dbversion values ('5.1.1.3')
go

--1841

ALTER procedure [dbo].[spFolder_PublishedProjectList]
	@UserGuid uniqueidentifier,
	@ErrorCode int output
as
/*
Date		Version		Author		Description
--------------------------------------------------------------------------------------------
10-Apr-08	5.0.21		Chrisg		Return list of published projects in folders for a user.
--------------------------------------------------------------------------------------------
*/
	declare @BusinessUnitGuid uniqueidentifier
	select @BusinessUnitGuid = business_unit_guid from Intelledox_User where User_Guid = @UserGuid

	SELECT	a.Folder_ID, a.Folder_Guid, a.Folder_Name, d.Template_Group_Id, b.[Name] as Project_Name,
			d.Template_Group_Guid
	FROM	Folder a
		left join Folder_Template c on a.Folder_ID = c.Folder_ID
		left join Template_Group d on c.FolderItem_Id = d.Template_Group_ID and c.ItemType_Id = 1
		left join Template_Group_Item e on d.Template_Group_ID = e.Template_Group_ID
		left join Template b on e.Template_ID = b.Template_ID
	WHERE	((c.ItemType_ID = 1 and d.Template_Group_ID in (
					select	a.template_group_id
					from	template_group_item a
							inner join template b on a.template_id = b.template_id or a.layout_id = b.template_id
							inner join template_group c on a.template_group_id = c.template_group_id
							left join template_group_item d on c.fax_template_group_id = d.template_group_id
							left join template e on d.template_id = e.template_id or d.layout_id = e.template_id
					group by a.template_group_id
					--having min(b.web_template) = 1 and (min(e.web_template) = 1 or min(e.web_template) is null)
				)
			))
		and a.Business_Unit_GUID = @BusinessUnitGuid
		and a.Folder_Guid in (
			SELECT	FolderGuid
			FROM	Folder_Group
			WHERE	GroupGuid in (
				select	distinct b.Group_Guid
				from	Intelledox_User a
						left join User_Group_Subscription c on a.[User_ID] = c.[User_ID]
						left join User_Group b on c.User_Group_ID = b.User_Group_ID
				where	b.Group_Guid is not null
				and		a.User_Guid = @UserGuid
			)
		)
	ORDER BY a.Folder_Name, a.Folder_ID, c.folderitem_id
	
	set @ErrorCode = @@error
GO

