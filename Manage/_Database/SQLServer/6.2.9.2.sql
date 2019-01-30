/*
** Database Update package 6.2.9.2
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.2.9.2')
go

--1925

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
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'D0416D36-5C3C-4CB7-8686-74432261A87A' THEN 1 ELSE 0 END) AS CanChangeSettings
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
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'D0416D36-5C3C-4CB7-8686-74432261A87A' THEN 1 ELSE 0 END) AS CanChangeSettings
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
				vwUserPermissions.CanMaintainLicensing, vwUserPermissions.CanChangeSettings
		FROM	Administrator_Level
				LEFT JOIN vwUserPermissions ON Administrator_Level.RoleGuid = vwUserPermissions.RoleGuid
		WHERE	Administrator_Level.Business_Unit_GUID = @BusinessUnitGUID
				AND vwUserPermissions.UserGUID = @UserGUID
				AND vwUserPermissions.GroupGuid IS NULL
		ORDER BY Administrator_Level.AdminLevel_Description;
	END

	set @errorcode = @@error;
GO

