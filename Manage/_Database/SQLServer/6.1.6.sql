/*
** Database Update package 6.1.6
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.1.6')
go

--1895
ALTER procedure [dbo].[spProject_ProjectList]
	@UserGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ProjectTypeId int,
	@SearchString nvarchar(100)
as
	declare @IsGlobal bit
	declare @BusinessUnitGUID uniqueidentifier

	SELECT	@BusinessUnitGUID = Business_Unit_GUID
	FROM	Intelledox_User
	WHERE	User_Guid = @UserGuid;

	IF EXISTS(SELECT	vwUserPermissions.*
		FROM	vwUserPermissions
		WHERE	vwUserPermissions.CanDesignProjects = 1
				AND vwUserPermissions.GroupGuid IS NULL
				AND vwUserPermissions.UserGuid = @UserGuid)
	BEGIN
		SET @IsGlobal = 1;
	END

	if @GroupGuid IS NULL
	begin
		--all usergroups
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.layout_id, a.template_guid, a.template_version, a.import_date, a.FormatTypeId,
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Content_Bookmark
		FROM	Template a
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		WHERE	(@IsGlobal = 1 or a.template_id in (
				SELECT	User_Group_Template.Template_ID
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.[User_ID] = User_Group_Subscription.[User_ID] 
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.User_Group_Id = User_Group_Template.User_Group_Id 
				WHERE	vwUserPermissions.CanDesignProjects = 1
			AND Intelledox_User.User_Guid = @UserGuid
				))
			AND (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
		ORDER BY a.[name];
	end
	else
	begin
		--specific user group
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.layout_id, a.template_guid, a.template_version, a.import_date, a.FormatTypeId,
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Content_Bookmark
		FROM	Template a
				INNER JOIN User_Group_Template d on a.Template_ID = d.Template_ID
				INNER JOIN User_Group ON d.User_Group_ID = User_Group.User_Group_ID  AND User_Group.Group_Guid = @GroupGuid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		WHERE	(@IsGlobal = 1 or a.template_id in (
				SELECT	User_Group_Template.Template_ID
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.[User_ID] = User_Group_Subscription.[User_ID] 
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.User_Group_Id = User_Group_Template.User_Group_Id 
				WHERE	vwUserPermissions.CanDesignProjects = 1
			))
			and (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
		ORDER BY a.[name];
	end
GO


