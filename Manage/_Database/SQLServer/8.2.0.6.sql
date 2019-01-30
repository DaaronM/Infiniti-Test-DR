/*
** Database Update package 8.2.0.6
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.0.6');
go

--2106
ALTER procedure [dbo].[spCustomField_AddressBookCustomFieldList]
	@AddressBookCustomFieldID int = 0,
	@AddressID int = 0,
	@ErrorCode int = 0 output
AS
	IF (@AddressID = 0 OR @AddressID IS NULL)
		SELECT	Address_Book_Custom_Field.*, Custom_Field.Validation_Type
		FROM	Address_Book_Custom_Field
				INNER JOIN Custom_Field ON Address_Book_Custom_Field.Custom_Field_Id = Custom_Field.Custom_Field_Id
		WHERE	@AddressBookCustomFieldID IS NULL
				OR Address_Book_Custom_Field_ID = @AddressBookCustomFieldID;
	ELSE
		SELECT	Address_Book_Custom_Field.*, Custom_Field.Validation_Type
		FROM	Address_Book_Custom_Field
				INNER JOIN Custom_Field ON Address_Book_Custom_Field.Custom_Field_Id = Custom_Field.Custom_Field_Id
		WHERE	Address_ID = @AddressID;
	
	set @errorcode = @@error;
GO


--2107
INSERT INTO dbo.Permission(PermissionGuid, Name, Description) 
VALUES ('73843C3F-21D0-4861-8886-7071E174DA04', 'Manage Workflow Tasks', 'Manage workflow tasks');
GO

--2108
ALTER procedure [dbo].[spSecurity_PermissionList]
	@PermissionGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	IF (@PermissionGuid IS NULL)
	BEGIN
		SELECT	*
		FROM	Permission
		ORDER BY NAME
	END
	ELSE
	BEGIN
		SELECT	*
		FROM	Permission
		WHERE	PermissionGuid = @PermissionGuid
	END

	set @errorcode = @@error

GO

--2109
ALTER VIEW [dbo].[vwUserPermissions]
AS
	SELECT	UserGuid,
			RoleGuid, 
			GroupGuid,
			MAX(CanDesignProjects) as CanDesignProjects, 
			MAX(CanPublishProjects) as CanPublishProjects, 
			MAX(CanManageContent) as CanManageContent, 
			MAX(CanManageUsers) as CanManageUsers, 
			MAX(CanManageGroups) as CanManageGroups, 
			MAX(CanManageSecurity) as CanManageSecurity, 
			MAX(CanManageDataSources) as CanManageDataSources,
			MIN(IsInherited) as IsInherited,
			MAX(CanMaintainLicensing) as CanMaintainLicensing,
			MAX(CanChangeSettings) as CanChangeSettings,
			MAX(CanManageConsole) as CanManageConsole,
			MAX(CanApproveContent) as CanApproveContent,
			MAX(CanManageWorkflowTasks) as CanManageWorkflowTasks
	FROM (
		SELECT User_Role.UserGuid,
			User_Role.RoleGuid,
			User_Role.GroupGuid,
			--Design projects
			CASE WHEN Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' THEN 1 ELSE 0 END AS CanDesignProjects,
			--Publish projects
			CASE WHEN Role_Permission.PermissionGuid = '6B96BAF3-8A76-4F42-B1E7-DF87142444E0' THEN 1 ELSE 0 END AS CanPublishProjects,
			--Manage content
			CASE WHEN Role_Permission.PermissionGuid = 'FA2C7769-6D15-442E-9F7F-E8CE82590D8D' THEN 1 ELSE 0 END AS CanManageContent,
			--Manage users
			CASE WHEN Role_Permission.PermissionGuid = '7D98327C-B4CB-48DC-9FF7-E613C26FA918' THEN 1 ELSE 0 END AS CanManageUsers,
			--Manage groups
			CASE WHEN Role_Permission.PermissionGuid = '33FC4FFE-9108-4D56-9A08-DD128255D87C' THEN 1 ELSE 0 END AS CanManageGroups,
			--Manage security
			CASE WHEN Role_Permission.PermissionGuid = '09B7187E-E432-4B03-BDC9-C7FC2C82B9F1' THEN 1 ELSE 0 END AS CanManageSecurity,
			--Manage data sources
			CASE WHEN Role_Permission.PermissionGuid = 'B0761CDD-BE11-45EE-8133-BF1D6AA65D6D' THEN 1 ELSE 0 END AS CanManageDataSources,
			0 as IsInherited,
			--Maintain Licensing
			CASE WHEN Role_Permission.PermissionGuid = 'BB4F1768-DBC7-46C7-9A52-09159DB15A02' THEN 1 ELSE 0 END AS CanMaintainLicensing,
			--Change Settings
			CASE WHEN Role_Permission.PermissionGuid = 'D0416D36-5C3C-4CB7-8686-74432261A87A' THEN 1 ELSE 0 END AS CanChangeSettings,
			--Management Console
			CASE WHEN Role_Permission.PermissionGuid = '22A89A6C-C131-4DF1-9A4F-50CFC5E69B58' THEN 1 ELSE 0 END AS CanManageConsole,
			--Content Approver
			CASE WHEN Role_Permission.PermissionGuid = 'F9A676FF-93F8-4D15-9F24-B95DD8C01762' THEN 1 ELSE 0 END AS CanApproveContent,
			--Workflow Tasks
			CASE WHEN Role_Permission.PermissionGuid = '73843C3F-21D0-4861-8886-7071E174DA04' THEN 1 ELSE 0 END AS CanManageWorkflowTasks
		FROM	User_Role
				LEFT JOIN Role_Permission ON Role_Permission.RoleGuid = User_Role.RoleGuid
		UNION
		SELECT Intelledox_User.User_Guid as UserGuid,
			Role_Permission.RoleGuid,
			NULL as GroupGuid,
			--Design projects
			CASE WHEN Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' THEN 1 ELSE 0 END AS CanDesignProjects,
			--Publish projects
			CASE WHEN Role_Permission.PermissionGuid = '6B96BAF3-8A76-4F42-B1E7-DF87142444E0' THEN 1 ELSE 0 END AS CanPublishProjects,
			--Manage content
			CASE WHEN Role_Permission.PermissionGuid = 'FA2C7769-6D15-442E-9F7F-E8CE82590D8D' THEN 1 ELSE 0 END AS CanManageContent,
			--Manage users
			CASE WHEN Role_Permission.PermissionGuid = '7D98327C-B4CB-48DC-9FF7-E613C26FA918' THEN 1 ELSE 0 END AS CanManageUsers,
			--Manage groups
			CASE WHEN Role_Permission.PermissionGuid = '33FC4FFE-9108-4D56-9A08-DD128255D87C' THEN 1 ELSE 0 END AS CanManageGroups,
			--Manage security
			CASE WHEN Role_Permission.PermissionGuid = '09B7187E-E432-4B03-BDC9-C7FC2C82B9F1' THEN 1 ELSE 0 END AS CanManageSecurity,
			--Manage data sources
			CASE WHEN Role_Permission.PermissionGuid = 'B0761CDD-BE11-45EE-8133-BF1D6AA65D6D' THEN 1 ELSE 0 END AS CanManageDataSources,
			1 as IsInherited,
			--Maintain Licensing
			CASE WHEN Role_Permission.PermissionGuid = 'BB4F1768-DBC7-46C7-9A52-09159DB15A02' THEN 1 ELSE 0 END AS CanMaintainLicensing,
			--Change Settings
			CASE WHEN Role_Permission.PermissionGuid = 'D0416D36-5C3C-4CB7-8686-74432261A87A' THEN 1 ELSE 0 END AS CanChangeSettings,
			--Management Console
			CASE WHEN Role_Permission.PermissionGuid = '22A89A6C-C131-4DF1-9A4F-50CFC5E69B58' THEN 1 ELSE 0 END AS CanManageConsole,
			--Content Approver
			CASE WHEN Role_Permission.PermissionGuid = 'F9A676FF-93F8-4D15-9F24-B95DD8C01762' THEN 1 ELSE 0 END AS CanApproveContent,
			--Workflow Tasks
			CASE WHEN Role_Permission.PermissionGuid = '73843C3F-21D0-4861-8886-7071E174DA04' THEN 1 ELSE 0 END AS CanManageWorkflowTasks
		FROM	Role_Permission
				INNER JOIN User_Group_Role ON Role_Permission.RoleGuid = User_Group_Role.RoleGuid
				INNER JOIN User_Group ON User_Group_Role.GroupGuid = User_Group.Group_Guid
				INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
				INNER JOIN Intelledox_User ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
		) PermissionCombination
		GROUP BY UserGuid, RoleGuid, GroupGuid

GO

--2110
ALTER procedure [dbo].[spUsers_AdminLevelList]
	@RoleGuid uniqueidentifier,
	@BusinessUnitGUID uniqueidentifier,
	@UserGUID uniqueidentifier,
	@ErrorCode int = 0 output
AS
	IF (@UserGUID IS NULL)
	BEGIN
		IF (@RoleGuid IS NULL)
		BEGIN
			SELECT	Administrator_Level.AdminLevel_ID, Administrator_Level.AdminLevel_Description, 
					Administrator_Level.RoleGuid, Administrator_Level.Business_Unit_Guid,
					--Design projects
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' THEN 1 ELSE 0 END) AS CanDesignProjects,
					--Publish projects
					MAX(CASE WHEN Role_Permission.PermissionGuid = '6B96BAF3-8A76-4F42-B1E7-DF87142444E0' THEN 1 ELSE 0 END) AS CanPublishProjects,
					--Manage content
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'FA2C7769-6D15-442E-9F7F-E8CE82590D8D' THEN 1 ELSE 0 END) AS CanManageContent,
					--Manage users
					MAX(CASE WHEN Role_Permission.PermissionGuid = '7D98327C-B4CB-48DC-9FF7-E613C26FA918' THEN 1 ELSE 0 END) AS CanManageUsers,
					--Manage groups
					MAX(CASE WHEN Role_Permission.PermissionGuid = '33FC4FFE-9108-4D56-9A08-DD128255D87C' THEN 1 ELSE 0 END) AS CanManageGroups,
					--Manage security
					MAX(CASE WHEN Role_Permission.PermissionGuid = '09B7187E-E432-4B03-BDC9-C7FC2C82B9F1' THEN 1 ELSE 0 END) AS CanManageSecurity,
					--Manage data sources
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'B0761CDD-BE11-45EE-8133-BF1D6AA65D6D' THEN 1 ELSE 0 END) AS CanManageDataSources,
					0 as IsInherited,
					--Maintain Licensing
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'BB4F1768-DBC7-46C7-9A52-09159DB15A02' THEN 1 ELSE 0 END) AS CanMaintainLicensing,
					--Change Settings
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'D0416D36-5C3C-4CB7-8686-74432261A87A' THEN 1 ELSE 0 END) AS CanChangeSettings,
					--Management Console
					MAX(CASE WHEN Role_Permission.PermissionGuid = '22A89A6C-C131-4DF1-9A4F-50CFC5E69B58' THEN 1 ELSE 0 END) AS CanManageConsole,
					--Content Approver
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'F9A676FF-93F8-4D15-9F24-B95DD8C01762' THEN 1 ELSE 0 END) AS CanApproveContent,
					--Workflow Tasks
					MAX(CASE WHEN Role_Permission.PermissionGuid = '73843C3F-21D0-4861-8886-7071E174DA04' THEN 1 ELSE 0 END) AS CanManageWorkflowTasks
			FROM	Administrator_Level
					LEFT JOIN Role_Permission ON Administrator_Level.RoleGuid = Role_Permission.RoleGuid
			WHERE	Administrator_Level.Business_Unit_GUID = @BusinessUnitGUID
			GROUP BY Administrator_Level.AdminLevel_ID, Administrator_Level.AdminLevel_Description, 
					Administrator_Level.RoleGuid, Administrator_Level.Business_Unit_Guid
			ORDER BY Administrator_Level.AdminLevel_Description;
		END
		ELSE
		BEGIN
			SELECT	Administrator_Level.AdminLevel_ID, Administrator_Level.AdminLevel_Description, 
					Administrator_Level.RoleGuid, Administrator_Level.Business_Unit_Guid,
					--Design projects
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' THEN 1 ELSE 0 END) AS CanDesignProjects,
					--Publish projects
					MAX(CASE WHEN Role_Permission.PermissionGuid = '6B96BAF3-8A76-4F42-B1E7-DF87142444E0' THEN 1 ELSE 0 END) AS CanPublishProjects,
					--Manage content
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'FA2C7769-6D15-442E-9F7F-E8CE82590D8D' THEN 1 ELSE 0 END) AS CanManageContent,
					--Manage users
					MAX(CASE WHEN Role_Permission.PermissionGuid = '7D98327C-B4CB-48DC-9FF7-E613C26FA918' THEN 1 ELSE 0 END) AS CanManageUsers,
					--Manage groups
					MAX(CASE WHEN Role_Permission.PermissionGuid = '33FC4FFE-9108-4D56-9A08-DD128255D87C' THEN 1 ELSE 0 END) AS CanManageGroups,
					--Manage security
					MAX(CASE WHEN Role_Permission.PermissionGuid = '09B7187E-E432-4B03-BDC9-C7FC2C82B9F1' THEN 1 ELSE 0 END) AS CanManageSecurity,
					--Manage data sources
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'B0761CDD-BE11-45EE-8133-BF1D6AA65D6D' THEN 1 ELSE 0 END) AS CanManageDataSources,
					0 as IsInherited,
					--Maintain Licensing
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'BB4F1768-DBC7-46C7-9A52-09159DB15A02' THEN 1 ELSE 0 END) AS CanMaintainLicensing,
					--Change Settings
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'D0416D36-5C3C-4CB7-8686-74432261A87A' THEN 1 ELSE 0 END) AS CanChangeSettings,
					--Management Console
					MAX(CASE WHEN Role_Permission.PermissionGuid = '22A89A6C-C131-4DF1-9A4F-50CFC5E69B58' THEN 1 ELSE 0 END) AS CanManageConsole,
					--Content Approver
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'F9A676FF-93F8-4D15-9F24-B95DD8C01762' THEN 1 ELSE 0 END) AS CanApproveContent,
					--Workflow Tasks
					MAX(CASE WHEN Role_Permission.PermissionGuid = '73843C3F-21D0-4861-8886-7071E174DA04' THEN 1 ELSE 0 END) AS CanManageWorkflowTasks
			FROM	Administrator_Level
					LEFT JOIN Role_Permission ON Administrator_Level.RoleGuid = Role_Permission.RoleGuid
			WHERE	Administrator_Level.RoleGuid = @RoleGuid
			GROUP BY Administrator_Level.AdminLevel_ID, Administrator_Level.AdminLevel_Description, 
					Administrator_Level.RoleGuid, Administrator_Level.Business_Unit_Guid
			ORDER BY Administrator_Level.AdminLevel_Description;
		END
	END
	ELSE
	BEGIN
		SELECT	Administrator_Level.AdminLevel_ID, Administrator_Level.AdminLevel_Description, 
				Administrator_Level.RoleGuid, Administrator_Level.Business_Unit_Guid,
				vwUserPermissions.CanDesignProjects, vwUserPermissions.CanPublishProjects,
				vwUserPermissions.CanManageContent, vwUserPermissions.CanManageUsers,
				vwUserPermissions.CanManageGroups, vwUserPermissions.CanManageSecurity,
				vwUserPermissions.CanManageDataSources, vwUserPermissions.IsInherited,
				vwUserPermissions.CanMaintainLicensing, vwUserPermissions.CanChangeSettings,
				vwUserPermissions.CanManageConsole, vwUserPermissions.CanApproveContent,
				vwUserPermissions.CanManageWorkflowTasks
		FROM	Administrator_Level
				LEFT JOIN vwUserPermissions ON Administrator_Level.RoleGuid = vwUserPermissions.RoleGuid
		WHERE	Administrator_Level.Business_Unit_GUID = @BusinessUnitGUID
				AND vwUserPermissions.UserGUID = @UserGUID
				AND vwUserPermissions.GroupGuid IS NULL
		ORDER BY Administrator_Level.AdminLevel_Description;
	END

	set @errorcode = @@error;

GO

