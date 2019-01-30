/*
** Database Update package 5.1.4
*/

--set version
truncate table dbversion
go
insert into dbversion values ('5.1.4')
go

--1847
ALTER procedure [dbo].[spTemplateGrp_RemoveFolder]
	@FolderID int,
	@ErrorCode int output
as
	DELETE Template_Group_Item
	WHERE Template_Group_Id IN (
		SELECT	Template_Group_Id
		FROM	Template_Group
		WHERE	Template_Group_Id IN (
			SELECT	FolderItem_Id
			FROM	Folder_Template
			WHERE	Folder_ID = @FolderID)
		);
		
	DELETE Template_Group 
	WHERE Template_Group_Id IN (
		SELECT	FolderItem_id
		FROM	Folder_Template
		WHERE	Folder_ID = @FolderID);
		
	DELETE Folder_Template WHERE Folder_ID = @FolderID;
	
	DELETE Folder WHERE Folder_ID = @FolderID;
	
	set @ErrorCode = @@error;
GO
ALTER procedure [dbo].[spTemplateGrp_TemplateGroupList]
	@TemplateGroupID int = 0,
	@UserID int = 0,
	@ErrorCode int output
as
/*
Vers	Date		Developer	Description
-------------------------------------------------------------------------------------------------------------
3.1.2	24/07/2004	Chrisg		modified to support guids for import/export
3.3.0	17/01/2005	Chrisg		added userid parameter to load only template groups the user is allowed to see
---INTELLEDOX---
1.1.0	03/08/2005	Chrisg		support for helptext
-------------------------------------------------------------------------------------------------------------
*/
	declare @IsGlobal bit

	if @UserID = 0
	begin
		SELECT 	a.Template_Group_ID, a.[Name] as Template_Group_Name, a.fax_template_group_id, a.template_group_guid, 
			a.fax_template_group_guid, a.helptext as TemplateGroup_HelpText, c.template_id, c.[name] as template_name, c.Template_Guid, b.Layout_ID
		FROM Template_Group a
		left join Template_Group_Item b on a.template_group_id = b.template_group_id
		left join Template c on b.template_id = c.template_id
		WHERE @TemplateGroupID = 0
		OR a.Template_Group_ID = @TemplateGroupID
	end
	else
	begin
		IF EXISTS(SELECT	Administrator_Level.*
			FROM	Administrator_Level
					INNER JOIN Role_Permission ON Administrator_Level.RoleGuid = Role_Permission.RoleGuid
					INNER JOIN User_Role ON Administrator_Level.RoleGuid = User_Role.RoleGuid
					INNER JOIN Intelledox_User ON User_Role.UserGuid = Intelledox_User.User_Guid
			WHERE	Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' --Manage Templates
					AND User_Role.GroupGuid IS NULL
					AND Intelledox_User.[User_ID] = @UserID)
		BEGIN
			SET @IsGlobal = 1
		END

		if @IsGlobal = 1
		begin
			SELECT 	a.Template_Group_ID, a.[Name] as Template_Group_Name, a.fax_template_group_id, 
				a.template_group_guid, a.fax_template_group_guid, a.helptext as TemplateGroup_HelpText, 
				c.template_id, c.[name] as template_name, c.Template_Guid, b.Layout_ID
			FROM Template_Group a
			left join Template_Group_Item b on a.template_group_id = b.template_group_id
			left join Template c on b.template_id = c.template_id
			WHERE @TemplateGroupID = 0
			OR a.Template_Group_ID = @TemplateGroupID
		end
		else
		begin
			SELECT 	a.Template_Group_ID, a.[Name] as Template_Group_Name, a.fax_template_group_id, 
				a.template_group_guid, a.fax_template_group_guid, a.helptext as TemplateGroup_HelpText,
				c.template_id, c.[name] as template_name, c.Template_Guid, b.Layout_ID
			FROM Template_Group a
			left join Template_Group_Item b on a.template_group_id = b.template_group_id
			left join Template c on b.template_id = c.template_id
			WHERE (@TemplateGroupID = 0 OR a.Template_Group_ID = @TemplateGroupID)
			AND (a.Template_Group_ID in (
				select template_group_id
				from template_group_item
				where template_id in (
					SELECT	User_Group_Template.Template_ID
					FROM	Role_Permission
							INNER JOIN User_Role ON Role_Permission.RoleGuid = User_Role.RoleGuid
							INNER JOIN Intelledox_User ON User_Role.UserGuid = Intelledox_User.User_Guid
							INNER JOIN User_Group_Subscription ON Intelledox_User.[User_ID] = User_Group_Subscription.[User_ID] 
							INNER JOIN User_Group ON User_Role.GroupGuid = User_Group.Group_Guid
							INNER JOIN User_Group_Template ON User_Group_Subscription.User_Group_Id = User_Group_Template.User_Group_Id 
					WHERE	Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' --Manage Templates
							AND Intelledox_User.[User_ID] = @UserID
				) and layout_id in (
					SELECT	User_Group_Template.Template_ID
					FROM	Role_Permission
							INNER JOIN User_Role ON Role_Permission.RoleGuid = User_Role.RoleGuid
							INNER JOIN Intelledox_User ON User_Role.UserGuid = Intelledox_User.User_Guid
							INNER JOIN User_Group_Subscription ON Intelledox_User.[User_ID] = User_Group_Subscription.[User_ID] 
							INNER JOIN User_Group ON User_Role.GroupGuid = User_Group.Group_Guid
							INNER JOIN User_Group_Template ON User_Group_Subscription.User_Group_Id = User_Group_Template.User_Group_Id 
					WHERE	Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' --Manage Templates
							AND Intelledox_User.[User_ID] = @UserID
				)
			)
			OR a.Template_Group_ID not in (
				select template_group_id
				from template_group_item
			))
		end
	end
	
	set @ErrorCode = @@error
GO
