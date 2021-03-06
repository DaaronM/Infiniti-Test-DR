truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.6');
go

DROP PROCEDURE [dbo].[spLicense_RemoveLicenseKey]
GO

DROP PROCEDURE [dbo].[spLicense_LicenseKeyList]
GO

DROP PROCEDURE [dbo].[spLicense_UpdateLicenseKey]
GO

DROP PROCEDURE [dbo].[spLicense_GetUsage]
GO

ALTER TABLE Business_Unit
	DROP COLUMN LicenseFile
GO

ALTER TABLE dbo.Business_Unit ADD
	EncryptedLicenseFile varbinary(MAX) NULL
GO

ALTER PROCEDURE [dbo].[spLicense_UpdateLicenseFile]
	@BusinessUnitGuid uniqueidentifier, 
	@LicenseFile varbinary(MAX)
AS
BEGIN
	UPDATE Business_Unit
	SET EncryptedLicenseFile = @LicenseFile
	WHERE Business_Unit_GUID = @BusinessUnitGuid;
END
GO

ALTER PROCEDURE [dbo].[spLicense_GetLicenseFile]
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN

	SELECT EncryptedLicenseFile
	FROM Business_Unit
	WHERE Business_Unit_GUID = @BusinessUnitGuid;
END

GO
ALTER PROCEDURE [dbo].[spUsers_UserByUsernameOrEmail]
	@UsernameOrEmail nvarchar(256),
	@ErrorCode int = 0 output
AS
BEGIN

	SELECT Intelledox_User.*, Email_Address
	FROM Intelledox_User
		LEFT JOIN Address_Book ON Intelledox_User.Address_ID = Address_Book.Address_ID
	WHERE (Email_Address = @UsernameOrEmail OR Username = @UsernameOrEmail)
		AND Disabled = 0;

	SET @ErrorCode = @@ERROR;	
END
GO

/*Project Content Folders*/
ALTER TABLE [dbo].[Template]
  ADD FolderGuid UNIQUEIDENTIFIER NULL
GO

CREATE TABLE [dbo].[zzUser_Group_Role](
	[UserGuid] [uniqueidentifier] NOT NULL,
	[RoleGuid] [uniqueidentifier] NOT NULL,
	[GroupGuid] [uniqueidentifier] NULL
)
GO
CREATE UNIQUE CLUSTERED INDEX [IX_User_Group_Role] ON [dbo].[zzUser_Group_Role]
(
	[UserGuid] ASC,
	[RoleGuid] ASC,
	[GroupGuid] ASC
)
GO

INSERT INTO zzUSER_GROUP_ROLE (UserGuid,RoleGuid,GroupGuid)
SELECT UserGuid, RoleGuid, GroupGuid
FROM User_Role
WHERE GroupGuid IS NOT NULL
GO

CREATE TABLE [dbo].[zzUser_Role](
	[UserGuid] [uniqueidentifier] NOT NULL,
	[RoleGuid] [uniqueidentifier] NOT NULL
)
GO
CREATE UNIQUE CLUSTERED INDEX [IX_User_Role] ON [dbo].[zzUser_Role]
(
	[UserGuid] ASC,
	[RoleGuid] ASC
)
GO

INSERT INTO zzUser_Role (UserGuid, RoleGuid)
SELECT UserGuid, RoleGuid
FROM User_Role
WHERE GroupGuid IS NULL
GO

DROP TABLE User_Role
GO

SP_RENAME 'zzUser_Role', 'User_Role';
GO

SP_RENAME 'User_Group_Template', 'zzUser_Group_Template';
GO

DROP PROCEDURE spTemplate_TemplateSubscribeGroup
GO

DROP PROCEDURE spTemplate_TemplateUnsubscribeGroup
GO

ALTER VIEW [dbo].[vwUserPermissions]
AS
	SELECT	UserGuid,
			RoleGuid, 
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
		GROUP BY UserGuid, RoleGuid
GO

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
		ORDER BY Administrator_Level.AdminLevel_Description;
	END

	SET @errorcode = @@error;
GO

ALTER procedure [dbo].[spUser_UserRoleList]
	@UserGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	SELECT	*
	FROM	User_Role
	WHERE	UserGuid = @UserGuid

	set @errorcode = @@error
GO

ALTER PROCEDURE [dbo].[spUser_UserRoleText]
	@UserGuid uniqueidentifier
AS
	SELECT	AdminLevel_Description
	FROM	Administrator_Level
			INNER JOIN vwUserPermissions ON Administrator_Level.RoleGuid = vwUserPermissions.RoleGuid
	WHERE	vwUserPermissions.UserGuid = @UserGuid
GO

ALTER PROCEDURE [dbo].[spProject_ProjectList]
	@UserGuid uniqueidentifier,
	@ProjectTypeId int,
	@SearchString nvarchar(100),
	@Purpose nvarchar(10)
AS

DECLARE @HasRole bit
DECLARE @BusinessUnitGUID uniqueidentifier = (SELECT Business_Unit_GUID
                                              FROM Intelledox_User
                                              WHERE User_Guid = @UserGuid)
IF EXISTS(SELECT vwUserPermissions.*
		  FROM   vwUserPermissions
		  WHERE  ((@Purpose = 'Design' AND vwUserPermissions.CanDesignProjects = 1)
				   OR (@Purpose = 'Publish' AND vwUserPermissions.CanPublishProjects = 1))
				   AND vwUserPermissions.UserGuid = @UserGuid)
	BEGIN
		SET @HasRole = 1;
	END

SELECT T.template_id, T.[name] as project_name, T.template_type_id, 
				T.template_guid, T.template_version, T.import_date, 
				T.Business_Unit_GUID, T.Supplier_Guid, T.Modified_Date, Intelledox_User.Username,
				T.FeatureFlags, T.FolderGuid, T.Modified_By, 
				lockedByUser.Username AS LockedBy
FROM Template T
	 LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = T.Modified_By
	 LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = T.LockedByUserGuid
WHERE @HasRole = 1
      AND T.Business_Unit_GUID = @BusinessUnitGUID
	  AND T.Name COLLATE Latin1_General_CI_AI LIKE (@SearchString + '%') COLLATE Latin1_General_CI_AI
	  AND (T.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
ORDER BY T.[name]
GO

CREATE PROCEDURE [dbo].[spProject_ProjectListByFolder]
	@UserGuid uniqueidentifier,
	@ProjectTypeId int,
	@SearchString nvarchar(100),
	@Purpose nvarchar(10),
	@FolderGuid uniqueidentifier
AS

DECLARE @HasRole bit
DECLARE @BusinessUnitGUID uniqueidentifier = (SELECT Business_Unit_GUID
                                              FROM Intelledox_User
                                              WHERE User_Guid = @UserGuid)
IF EXISTS(SELECT vwUserPermissions.*
		  FROM   vwUserPermissions
		  WHERE  ((@Purpose = 'Design' AND vwUserPermissions.CanDesignProjects = 1)
				   OR (@Purpose = 'Publish' AND vwUserPermissions.CanPublishProjects = 1))
				   AND vwUserPermissions.UserGuid = @UserGuid)
	BEGIN
		SET @HasRole = 1;
	END

SELECT T.template_id, T.[name] as project_name, T.template_type_id, 
				T.template_guid, T.template_version, T.import_date, 
				T.Business_Unit_GUID, T.Supplier_Guid, T.Modified_Date, Intelledox_User.Username,
				T.FeatureFlags, T.FolderGuid, T.Modified_By, 
				lockedByUser.Username AS LockedBy
FROM Template T
	 LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = T.Modified_By
	 LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = T.LockedByUserGuid
WHERE @HasRole = 1
      AND T.Business_Unit_GUID = @BusinessUnitGUID
	  AND (T.FolderGuid = @FolderGuid OR (@FolderGuid IS NULL AND T.FolderGuid IS NULL))
	  AND T.Name COLLATE Latin1_General_CI_AI LIKE (@SearchString + '%') COLLATE Latin1_General_CI_AI
	  AND (T.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
ORDER BY T.[name]
GO

ALTER PROCEDURE [dbo].[spProject_ProjectListFullText]
	@UserGuid uniqueidentifier,
	@ProjectTypeId int,
	@SearchString nvarchar(100),
	@FullText NVarChar(1000)
AS
	declare @HasRole bit
	declare @BusinessUnitGUID uniqueidentifier

	SELECT	@BusinessUnitGUID = Business_Unit_GUID
	FROM	Intelledox_User
	WHERE	User_Guid = @UserGuid;

	IF EXISTS(SELECT	vwUserPermissions.*
		FROM	vwUserPermissions
		WHERE	vwUserPermissions.CanDesignProjects = 1
				AND vwUserPermissions.UserGuid = @UserGuid)
	BEGIN
		SET @HasRole = 1;
	END

	BEGIN
		SELECT 	T.template_id, T.[name] as project_name, T.template_type_id,
				T.template_guid, T.template_version, T.import_date, 
				T.Business_Unit_GUID, T.Supplier_Guid, T.Modified_Date, Intelledox_User.Username,
				T.Modified_By, lockedByUser.Username AS LockedBy,
				T.FeatureFlags, T.FolderGuid
		FROM	Template T
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = T.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = T.LockedByUserGuid
		WHERE	@HasRole = 1
			AND T.Business_Unit_GUID = @BusinessUnitGUID
			AND T.Name COLLATE Latin1_General_CI_AI LIKE (@SearchString + '%') COLLATE Latin1_General_CI_AI
			AND T.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0
			AND (T.Template_Guid IN (
					SELECT	Template_Guid
					FROM	Template_File tf
					WHERE	Contains(*, @FullText)
				))
		ORDER BY T.Name
	END
GO

CREATE PROCEDURE [dbo].[spProject_ProjectListFullTextByFolder]
	@UserGuid uniqueidentifier,
	@ProjectTypeId int,
	@SearchString nvarchar(100),
	@FullText nvarChar(1000),
	@FolderGuid uniqueidentifier
AS
	declare @HasRole bit
	declare @BusinessUnitGUID uniqueidentifier

	SELECT	@BusinessUnitGUID = Business_Unit_GUID
	FROM	Intelledox_User
	WHERE	User_Guid = @UserGuid;

	IF EXISTS(SELECT	vwUserPermissions.*
		FROM	vwUserPermissions
		WHERE	vwUserPermissions.CanDesignProjects = 1
				AND vwUserPermissions.UserGuid = @UserGuid)
	BEGIN
		SET @HasRole = 1;
	END

	BEGIN
		SELECT 	T.template_id, T.[name] as project_name, T.template_type_id,
				T.template_guid, T.template_version, T.import_date, 
				T.Business_Unit_GUID, T.Supplier_Guid, T.Modified_Date, Intelledox_User.Username,
				T.Modified_By, lockedByUser.Username AS LockedBy,
				T.FeatureFlags
		FROM	Template T
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = T.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = T.LockedByUserGuid
		WHERE	@HasRole = 1
			AND T.Business_Unit_GUID = @BusinessUnitGUID
			AND (T.FolderGuid = @FolderGuid OR (@FolderGuid IS NULL AND T.FolderGuid IS NULL))
			AND T.Name COLLATE Latin1_General_CI_AI LIKE (@SearchString + '%') COLLATE Latin1_General_CI_AI
			AND T.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0
			AND (T.Template_Guid IN (
					SELECT	Template_Guid
					FROM	Template_File tf
					WHERE	Contains(*, @FullText)
				))
		ORDER BY T.Name
	END
GO

ALTER procedure [dbo].[spTemplate_TemplateList]
	@TemplateGuid uniqueidentifier,
	@ErrorCode int output
AS
	SET NOCOUNT ON
	
	SELECT	a.template_id, a.[name] as template_name, a.template_type_id,
			a.template_guid, a.Supplier_Guid, a.Business_Unit_Guid,
			a.HelpText, a.Modified_Date, Intelledox_User.Username,
			a.[name] as Project_Name, a.Modified_By, lockedByUser.Username AS LockedBy, a.Comment, 
			a.Template_Version, a.FeatureFlags, a.IsMajorVersion, a.FolderGuid
	FROM	Template a
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
			LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
	WHERE	a.Template_Guid = @TemplateGuid;

	SET @ErrorCode = @@error;
GO

ALTER procedure [dbo].[spContent_ContentItemList]
	@ItemGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier,
	@ExactMatch bit,
	@ContentTypeId int,
	@Name NVarChar(255),
	@Description NVarChar(1000),
	@Category int,
	@Approved int = 2,
	@ErrorCode int output,
	@FolderGuid uniqueidentifier,
	@UserId uniqueidentifier,
	@NoFolder bit,
	@MinimalGet bit
as
	IF @ItemGuid is null 
	BEGIN
		UPDATE Content_Item
		SET Approved = 1
		WHERE ExpiryDate < GETDATE()
			AND Approved = 0;
		
		IF @ExactMatch = 1
			WITH ContentFolderGroupCte (FolderGuid)
			AS
			( 
				SELECT Content_Folder_Group.FolderGuid
				FROM Content_Folder_Group
					INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
					INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
					INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
				WHERE Intelledox_User.User_Guid = @UserId
				UNION ALL
				SELECT Content_Folder.FolderGuid
				FROM Content_Folder
					INNER JOIN ContentFolderGroupCte ON Content_Folder.ParentFolderGuid = ContentFolderGroupCte.FolderGuid
			)
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Content.Modified_By,
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					ci.FolderGuid,
					Content_Folder.FolderName
					
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity = @Name
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
			ORDER BY ci.NameIdentity;
		ELSE
			WITH ContentFolderGroupCte (FolderGuid)
			AS
			( 
				SELECT Content_Folder_Group.FolderGuid
				FROM Content_Folder_Group
					INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
					INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
					INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
				WHERE Intelledox_User.User_Guid = @UserId
				UNION ALL
				SELECT Content_Folder.FolderGuid
				FROM Content_Folder
					INNER JOIN ContentFolderGroupCte ON Content_Folder.ParentFolderGuid = ContentFolderGroupCte.FolderGuid
			)
			SELECT DISTINCT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Content.Modified_By,
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					ci.FolderGuid,
					Content_Folder.FolderName
					
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
						
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity COLLATE Latin1_General_CI_AI LIKE ('%' + @Name + '%') COLLATE Latin1_General_CI_AI
					AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND ci.Description COLLATE Latin1_General_CI_AI LIKE ('%' + @Description + '%') COLLATE Latin1_General_CI_AI
					AND (@Category = 0 or ci.Category = @Category)
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
					AND ((@NoFolder = 0 AND (@FolderGuid IS NULL OR ci.FolderGuid = @FolderGuid))
						OR (@NoFolder = 1 AND ci.FolderGuid IS NULL))
			ORDER BY ci.ContentType_Id,
					ci.NameIdentity;
	END
	ELSE
	BEGIN
		UPDATE	Content_Item
		SET		Approved = 1
		WHERE	ExpiryDate < GETDATE()
				AND Approved = 0
				AND contentitem_guid = @ItemGuid;
		
		IF (@MinimalGet = 1)
		BEGIN
			SELECT	ci.*, 
					'' as FileType, 
					NULL as Modified_Date, 
					NULL as Modified_By,
					'' as UserName,
					0 as HasUnapprovedRevision,
					Content_Folder.FolderName						
			FROM	content_item ci
				LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
			WHERE	ci.contentitem_guid = @ItemGuid;
		END
		ELSE
		BEGIN
			WITH ContentFolderGroupCte (FolderGuid)
			AS
			( 
				SELECT Content_Folder_Group.FolderGuid
				FROM Content_Folder_Group
					INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
					INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
					INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
				WHERE Intelledox_User.User_Guid = @UserId
				UNION ALL
				SELECT Content_Folder.FolderGuid
				FROM Content_Folder
					INNER JOIN ContentFolderGroupCte ON Content_Folder.ParentFolderGuid = ContentFolderGroupCte.FolderGuid
			)
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Content.Modified_By,
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					Content_Folder.FolderName
						
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
						
			WHERE	ci.contentitem_guid = @ItemGuid;
		END
	END
	
	SET @ErrorCode = @@error;
GO

ALTER procedure [dbo].[spContent_ContentItemListByFolder]
    @FolderGuid uniqueidentifier,
    @UserId uniqueidentifier
AS
    SELECT	Content_Item.*, 
        ContentData_Binary.FileType, 
        ContentData_Binary.Modified_Date, 
        Intelledox_User.Username,
        0 As HasUnapprovedRevision
    FROM	Content_Item
        LEFT JOIN ContentData_Binary ON Content_Item.ContentData_Guid = ContentData_Binary.ContentData_Guid
        LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = ContentData_Binary.Modified_By
    WHERE	FolderGuid = @FolderGuid
        OR (FolderGuid IS NULL AND @FolderGuid IS NULL)
    ORDER BY Content_Item.ContentType_Id,
        Content_Item.NameIdentity
GO

ALTER PROCEDURE [dbo].[spProject_UpdateProject]
	@BusinessUnitGuid uniqueidentifier,
	@Name nvarchar(100),
	@ProjectGuid uniqueidentifier,
	@ProjectTypeID int,
	@FolderGuid uniqueidentifier,
	@SupplierGuid uniqueidentifier,
	@NextVersion nvarchar(10) = '0',
	@UserGuid uniqueidentifier = NULL,
	@Comment nvarchar(MAX) = NULL
AS
	IF @UserGuid IS NULL
	BEGIN
		UPDATE	Template
		SET		[name] = @Name, 
				Template_type_id = @ProjectTypeID, 
				Supplier_GUID = @SupplierGuid,
				FolderGuid = @FolderGuid
		WHERE	Template_Guid = @ProjectGuid;
	END
	ELSE
	BEGIN
		IF NOT EXISTS(SELECT Template_Guid FROM Template WHERE Template_Guid = @ProjectGuid)
		BEGIN
			INSERT INTO Template(Business_Unit_Guid, Name, Template_Guid, 
				Template_Type_Id, FolderGuid, Supplier_Guid, Template_Version, IsMajorVersion, Comment,
				Modified_Date, Modified_By)
			VALUES (@BusinessUnitGuid, @Name, @ProjectGuid, 
				@ProjectTypeId, @FolderGuid, @SupplierGuid, '0.0', 0, @Comment,
				GetUtcDate(), @UserGuid);
		END
		ELSE
		BEGIN
			BEGIN TRAN
				EXEC spProject_AddNewProjectVersion @ProjectGuid, @BusinessUnitGuid;
		
				UPDATE	Template
				SET		[name] = @Name, 
						Template_type_id = @ProjectTypeID, 
						FolderGuid = @FolderGuid,
						Supplier_GUID = @SupplierGuid,
						Modified_Date = GetUtcDate(),
						Modified_By = @UserGuid,
						Template_Version = @NextVersion,
						Comment = @Comment,
						IsMajorVersion = 0
				WHERE	Template_Guid = @ProjectGuid;
			COMMIT
		
			EXEC spProject_DeleteOldProjectVersion @ProjectGuid=@ProjectGuid, 
				@NextVersion=@NextVersion,
				@BusinessUnitGuid=@BusinessUnitGuid;
		END
	END
GO

ALTER procedure [dbo].[spContent_ContentItemListFullText]
	@ItemGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier,
	@ExactMatch bit,
	@ContentTypeId int,
	@Name NVarChar(255),
	@Description NVarChar(1000),
	@Category int,
	@FullText NVarChar(1000),
	@Approved int = 2,
	@ErrorCode int output,
	@FolderGuid uniqueidentifier,
	@UserId uniqueidentifier,
	@NoFolder bit
as

	UPDATE Content_Item
	SET Approved = 1
	WHERE ExpiryDate < GETDATE()
		AND Approved = 0;

	IF @ItemGuid is null 
		IF @ExactMatch = 1
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Content.Modified_By,
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					Content_Folder.FolderName
					
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity = @Name
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
			ORDER BY ci.NameIdentity;
		ELSE
			--Full text search
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Content.Modified_By,
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					Content_Folder.FolderName
					
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity COLLATE Latin1_General_CI_AI LIKE ('%' + @Name + '%') COLLATE Latin1_General_CI_AI
					AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND ci.Description COLLATE Latin1_General_CI_AI LIKE ('%' + @Description + '%') COLLATE Latin1_General_CI_AI
					AND (@Category = 0 or ci.Category = @Category)
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
					AND (ci.ContentData_Guid IN (
							SELECT	ContentData_Guid
							FROM	ContentData_Binary cdb
							WHERE	Contains(*, @FullText)
							)
						OR
						ci.ContentData_Guid IN (
							SELECT	ContentData_Guid
							FROM	ContentData_Text cdt
							WHERE	Contains(*, @FullText)
							)
						)
					AND ((@NoFolder = 0 AND (@FolderGuid IS NULL OR ci.FolderGuid = @FolderGuid))
						OR (@NoFolder = 1 AND ci.FolderGuid IS NULL))
			ORDER BY ci.NameIdentity;
	ELSE
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Content.Modified_By,
				Intelledox_User.UserName,
				CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
				Content_Folder.FolderName
					
		FROM	content_item ci
				LEFT JOIN (
					SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
					FROM	ContentData_Binary
					UNION
					SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
					FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
				LEFT JOIN (
					SELECT	ContentData_Guid
					FROM	vwContentItemVersionDetails
					WHERE	Approved = 0
					) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
				LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
		WHERE	ci.contentitem_guid = @ItemGuid;
	
SET @ErrorCode = @@error;
GO

ALTER procedure [dbo].[spContent_ContentItemListBySearch]
	@BusinessUnitGuid uniqueidentifier,
	@SearchString NVarChar(1000),
	@ContentTypeId Int,
	@FolderGuid uniqueidentifier
AS
	IF @SearchString IS NULL OR @SearchString = ''
		WITH ContentFolderCte (FolderGuid)
		AS
		( 
			SELECT @FolderGuid
			UNION ALL
			SELECT Content_Folder.FolderGuid
			FROM Content_Folder
				INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid
		)
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Content.Modified_By,
				Intelledox_User.UserName,
				0 as HasUnapprovedRevision,
				Content_Folder.FolderName
		FROM	content_item ci
				LEFT JOIN (
					SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
					FROM	ContentData_Binary
					UNION
					SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
					FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
				LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
		WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
				AND ci.Approved = 2
				AND ci.ContentType_Id = @ContentTypeId
					--Search all folders/none folder/specific folder
				AND (
					@FolderGuid = '00000000-0000-0000-0000-000000000000' --all
					OR (@FolderGuid = '99999999-9999-9999-9999-999999999999'  AND ci.FolderGuid IS NULL) --none
					OR ci.FolderGuid in (SELECT FolderGuid FROM ContentFolderCte) --a specific folder
					)
		ORDER BY ci.NameIdentity;
ELSE
		WITH ContentFolderCte (FolderGuid)
		AS
		( 
			SELECT @FolderGuid
			UNION ALL
			SELECT Content_Folder.FolderGuid
			FROM Content_Folder
				INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid
		)
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Content.Modified_By,
				Intelledox_User.UserName,
				0 as HasUnapprovedRevision,
				Content_Folder.FolderName
		FROM	content_item ci
				LEFT JOIN (
					SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
					FROM	ContentData_Binary
					UNION
					SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
					FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
				LEFT JOIN Category ON ci.Category = Category.Category_ID
				LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
		WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
				AND ci.Approved = 2
				AND ci.ContentType_Id = @ContentTypeId
				AND (ci.NameIdentity COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchString + '%') COLLATE Latin1_General_CI_AI
					OR ci.Description COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchString + '%') COLLATE Latin1_General_CI_AI
					OR Category.Name COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchString + '%') COLLATE Latin1_General_CI_AI
					)
					--Search all folders/none folder/specific folder
				AND (
					@FolderGuid = '00000000-0000-0000-0000-000000000000' --all
					OR (@FolderGuid = '99999999-9999-9999-9999-999999999999'  AND ci.FolderGuid IS NULL) --none
					OR ci.FolderGuid in (SELECT FolderGuid FROM ContentFolderCte) --a specific folder
					)
		ORDER BY ci.NameIdentity;
GO

ALTER procedure [dbo].[spContent_ContentItemListBySearchFullText]
	@BusinessUnitGuid uniqueidentifier,
	@SearchString NVarChar(1000),
	@FullTextSearchString NVarChar(1000),
	@ContentTypeId Int,
	@FolderGuid uniqueidentifier
AS
	WITH ContentFolderCte (FolderGuid)
	AS
	( 
		SELECT @FolderGuid
		UNION ALL
		SELECT Content_Folder.FolderGuid
		FROM Content_Folder
			INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid
	)
	SELECT	ci.*, 
			Content.FileType, 
			Content.Modified_Date, 
			Content.Modified_By,
			Intelledox_User.UserName,
			0 as HasUnapprovedRevision,
			Content_Folder.FolderName
	FROM	content_item ci
			LEFT JOIN (
				SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
				FROM	ContentData_Binary
				UNION
				SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
				FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
			LEFT JOIN Category ON ci.Category = Category.Category_ID
			LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
			LEFT JOIN FREETEXTTABLE(ContentData_Binary, *, @FullTextSearchString) as Ftt
				ON ci.ContentData_Guid = Ftt.[Key]
	WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
			AND ci.Approved = 2
			AND ci.ContentType_Id = @ContentTypeId
			AND (ci.NameIdentity COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchString + '%') COLLATE Latin1_General_CI_AI
				OR ci.Description COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchString + '%') COLLATE Latin1_General_CI_AI
				OR Category.Name COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchString + '%') COLLATE Latin1_General_CI_AI
				OR (ci.ContentData_Guid IN (
						SELECT	ContentData_Guid
						FROM	ContentData_Binary cdb
						WHERE	Contains(*, @FullTextSearchString)
						)
					OR
					ci.ContentData_Guid IN (
						SELECT	ContentData_Guid
						FROM	ContentData_Text cdt
						WHERE	Contains(*, @FullTextSearchString)
						)
					)
				)
				--Search all folders/none folder/specific folder
			AND (
				@FolderGuid = '00000000-0000-0000-0000-000000000000' --all
				OR @FolderGuid = '99999999-9999-9999-9999-999999999999'  AND ci.FolderGuid IS NULL --none
				OR ci.FolderGuid in (SELECT FolderGuid FROM ContentFolderCte) --a specific folder
				)
	ORDER BY Ftt.Rank DESC, ci.NameIdentity;
GO

ALTER PROCEDURE [dbo].[spTemplate_RemoveTemplate]
	@TemplateGuid uniqueidentifier,
	@OnlyChildInfo bit
AS
	IF @OnlyChildInfo = 0
	BEGIN
		DELETE	template_Group
		WHERE	template_guid = @TemplateGuid
			OR	layout_guid = @TemplateGuid;
	END
	
	DELETE	Template_File
	WHERE	Template_Guid = @TemplateGuid;
		
	DELETE	Template_File_Version
	WHERE	Template_Guid = @TemplateGuid;
	
	DELETE	Template_Translation
	WHERE	Template_Guid = @TemplateGuid;

	DELETE	Template_Version
	WHERE	Template_Guid = @TemplateGuid;

	DELETE  Xtf_Datasource_Dependency
	WHERE	Template_Guid = @TemplateGuid;

	DELETE  Xtf_ContentLibrary_Dependency
	WHERE	Template_Guid = @TemplateGuid;

	DELETE FROM Xtf_Fragment_Dependency
	WHERE	Template_Guid = @TemplateGuid;

	DELETE	Template
	WHERE	Template_Guid = @TemplateGuid;
GO

ALTER PROCEDURE [dbo].[spContent_ContentFolderList]
	@FolderGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier
AS
	IF @FolderGuid IS NULL
	BEGIN
		SELECT	*
		FROM	Content_Folder
		WHERE	BusinessUnitGuid = @BusinessUnitGuid
		ORDER BY FolderName;
	END
	ELSE
	BEGIN
		SELECT	*
		FROM	Content_Folder
		WHERE	FolderGuid = @FolderGuid 
	END
GO

ALTER PROCEDURE [dbo].[spContent_RemoveContentFolder]
	@FolderGuid uniqueidentifier
AS

    DECLARE @GuidId uniqueidentifier;
	--CONTENT ITEMS
	DECLARE @DeletedContentItem AS TABLE (ContentItem_Guid UNIQUEIDENTIFIER)
	BEGIN
	--Use a CTE Table to retrive the child folders (recursive)
	WITH ContentFolderCte (FolderGuid)
		AS
		( 
			SELECT @FolderGuid
			UNION ALL
			SELECT Content_Folder.FolderGuid
			FROM Content_Folder
				INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid
		)
		--Store the ID's of the content items to be deleted into a temp table vairable.
		INSERT INTO @DeletedContentItem
		SELECT ContentItem_Guid
		FROM Content_Item
		WHERE Content_Item.FolderGuid IN (SELECT FolderGuid FROM ContentFolderCte)

		IF ((SELECT COUNT(ContentItem_Guid) FROM  @DeletedContentItem) <> 0)
		  BEGIN
		    DECLARE ExpiredItemCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
			FOR SELECT ContentItem_Guid FROM @DeletedContentItem
		
			OPEN ExpiredItemCursor;
			FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;

			WHILE @@FETCH_STATUS = 0 
				BEGIN
					EXEC spContent_RemoveContentItem @GuidId
					FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;
				END

			CLOSE ExpiredItemCursor;
			DEALLOCATE ExpiredItemCursor;
		  END
	END

	--PROJECTS (Repeat above approach)
	DECLARE @DeletedProject AS TABLE (Template_Guid UNIQUEIDENTIFIER)
	BEGIN
	WITH ContentFolderCte (FolderGuid)
		AS
		( 
			SELECT @FolderGuid
			UNION ALL
			SELECT Content_Folder.FolderGuid
			FROM Content_Folder
				INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid
		)
		
		INSERT INTO @DeletedProject
		SELECT Template_Guid
		FROM Template
		WHERE Template.FolderGuid IN (SELECT FolderGuid FROM ContentFolderCte)

		IF ((SELECT COUNT(Template_Guid) FROM  @DeletedProject) <> 0)
		  BEGIN
		    DECLARE ExpiredItemCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
			FOR SELECT ContentItem_Guid FROM @DeletedContentItem
		
			OPEN ExpiredItemCursor;
			FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;

			WHILE @@FETCH_STATUS = 0 
				BEGIN
					EXEC spTemplate_RemoveTemplate @GuidId, 0
					FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;
				END

			CLOSE ExpiredItemCursor;
			DEALLOCATE ExpiredItemCursor;
		  END
	END

	--FOLDER GROUPS (Edit Permissions)
	BEGIN
	WITH ContentFolderCte (FolderGuid)
	AS
	( 
		SELECT @FolderGuid
		UNION ALL
		SELECT Content_Folder.FolderGuid
		FROM Content_Folder
			INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid
	)
	DELETE Content_Folder_Group
	FROM ContentFolderCte
	WHERE ContentFolderCte.FolderGuid = Content_Folder_Group.FolderGuid
	END

	--CONTENT FOLDERS
	BEGIN
	WITH ContentFolderCte (FolderGuid)
	AS
	( 
		SELECT @FolderGuid
		UNION ALL
		SELECT Content_Folder.FolderGuid
		FROM Content_Folder
			INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid
	)
	DELETE Content_Folder
	FROM ContentFolderCte
	WHERE ContentFolderCte.FolderGuid = Content_Folder.FolderGuid
	END
GO


CREATE PROCEDURE spContent_ContentFolderProjectCount
@FolderGuid uniqueidentifier
AS
	WITH ContentFolderCte (FolderGuid)
		AS
		( 
			SELECT @FolderGuid
			UNION ALL
			SELECT Content_Folder.FolderGuid
			FROM Content_Folder
				INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid
		)
		
		SELECT COUNT(Template_Guid) AS [Count]
		FROM Template
		WHERE Template.FolderGuid IN (SELECT FolderGuid FROM ContentFolderCte)
GO

CREATE PROCEDURE [dbo].[spContent_ContentFolderContentItemCount]
@FolderGuid uniqueidentifier
AS
	WITH ContentFolderCte (FolderGuid)
		AS
		( 
			SELECT @FolderGuid
			UNION ALL
			SELECT Content_Folder.FolderGuid
			FROM Content_Folder
				INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid
		)
		
		SELECT COUNT(ContentItem_Guid) AS [Count]
		FROM Content_Item
		WHERE Content_Item.FolderGuid IN (SELECT FolderGuid FROM ContentFolderCte)
GO

CREATE PROCEDURE spContent_ContentFolderByName
    @FolderName NVARCHAR(50),
	@BusinessUnitGuid uniqueidentifier
AS
	BEGIN
		SELECT	*
		FROM	Content_Folder
		WHERE	BusinessUnitGuid = @BusinessUnitGuid
		AND FolderName = @FolderName	
	END
GO

ALTER procedure [dbo].[spUsers_UnsubscribeUserGroup]
    @UserGroupID int,
    @UserID int,
    @ErrorCode int = 0 output
AS
    DECLARE @Default bit,
            @NewDefaultID int
    DECLARE @UserGuid uniqueidentifier
    DECLARE @GroupGuid uniqueidentifier
            
    SELECT	@UserGuid = User_Guid
    FROM	Intelledox_User
    WHERE	[User_ID] = @UserID;
    
    SELECT	@GroupGuid = Group_Guid
    FROM	User_Group
    WHERE	User_Group_ID = @UserGroupID;

    SELECT	@Default = IsDefaultGroup
    FROM	User_Group_Subscription
    WHERE	GroupGuid = @GroupGuid
            AND UserGuid = @UserGuid;
            
    -- Remove group from user
    DELETE FROM User_Group_Subscription
    WHERE	GroupGuid = @GroupGuid
            AND UserGuid = @UserGuid;

    IF @Default <> 0
    BEGIN
        UPDATE	user_group_subscription
        SET		IsDefaultGroup = 1
        FROM	user_group_subscription
                INNER JOIN (
                    SELECT TOP 1 GroupGuid from user_group_subscription WHERE UserGuid = @UserGuid
                ) ugs ON user_group_subscription.GroupGuid = ugs.GroupGuid AND user_group_subscription.UserGuid = @UserGuid;
    END

    SET @ErrorCode = @@error;
GO

ALTER Procedure [dbo].[spUser_UpdateUserRole]
	@UserGuid uniqueidentifier,
	@RoleGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	INSERT INTO User_Role (UserGuid, RoleGuid)
	VALUES (@UserGuid, @RoleGuid)
	
	SET @ErrorCode = @@error
GO

ALTER procedure [dbo].[spUser_RemoveUserRole]
	@UserGuid uniqueidentifier,
	@RoleGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	DELETE FROM User_Role
	WHERE	userGuid = @userGuid
			AND RoleGuid = @RoleGuid
	
	SET @ErrorCode = @@error
GO

ALTER TABLE dbo.Template_Group ADD
	IsHomePage bit NOT NULL CONSTRAINT DF_Template_Group_IsHomePage DEFAULT 0
GO

ALTER PROCEDURE [dbo].[spProjectGrp_UpdateProjectGroup]
	@ProjectGroupGuid uniqueidentifier,
	@HelpText nvarchar(4000),
	@AllowPreview bit,
	@AllowRestart bit,
	@WizardFinishText nvarchar(max),
	@PostGenerateText nvarchar(4000),
	@UpdateDocumentFields bit,
	@EnforceValidation bit,
	@HideNavigationPane bit,
	@EnforcePublishPeriod bit,
	@PublishStartDate datetime,
	@PublishFinishDate datetime,
	@ProjectGuid uniqueidentifier,
	@LayoutGuid uniqueidentifier,
	@ProjectVersion nvarchar(10),
	@LayoutVersion nvarchar(10),
	@FolderGuid uniqueidentifier,
	@ShowFormActivity bit,
	@MatchProjectVersion bit,
	@OfflineDataSources bit,
	@LogPageTransition bit,
	@AllowSave bit,
	@IsHomePage bit,
	@SkinXml nvarchar(max) = ''
AS
	IF NOT EXISTS(SELECT * FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid)
	BEGIN
		DECLARE @SkinDate DateTime = null
		IF @SkinXml <> ''
		BEGIN
			SET @SkinDate = GETUTCDATE()
		END

		INSERT INTO Template_Group (template_group_guid, helptext, AllowPreview, PostGenerateText, 
				UpdateDocumentFields, EnforceValidation, WizardFinishText, EnforcePublishPeriod,
				PublishStartDate, PublishFinishDate, HideNavigationPane, Template_Guid, Layout_Guid,
				Template_Version, Layout_Version, Folder_Guid, ShowFormActivity, MatchProjectVersion,
				AllowRestart, OfflineDataSources, LogPageTransition, SkinXml, AllowSave, SkinLastUpdated,
				IsHomePage)
		VALUES (@ProjectGroupGuid, @HelpText, @AllowPreview, @PostGenerateText, 
				@UpdateDocumentFields, @EnforceValidation, @WizardFinishText, @EnforcePublishPeriod,
				@PublishStartDate, @PublishFinishDate, @HideNavigationPane, @ProjectGuid, @LayoutGuid,
				@ProjectVersion, @LayoutVersion, @FolderGuid, @ShowFormActivity, @MatchProjectVersion,
				@AllowRestart, @OfflineDataSources,@LogPageTransition, @SkinXml, @AllowSave, @SkinDate,
				@IsHomePage);
	END
	ELSE
	BEGIN
		DECLARE @ExistingSkin nvarchar(max)
		SELECT @ExistingSkin = CAST(SkinXml as nvarchar(max)) FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid
		UPDATE	Template_Group
		SET		HelpText = @HelpText,
				AllowPreview = @AllowPreview,
				PostGenerateText = @PostGenerateText,
				UpdateDocumentFields = @UpdateDocumentFields,
				EnforceValidation = @EnforceValidation,
				WizardFinishText = @WizardFinishText,
				EnforcePublishPeriod = @EnforcePublishPeriod,
				PublishStartDate = @PublishStartDate,
				PublishFinishDate = @PublishFinishDate,
				HideNavigationPane = @HideNavigationPane,
				Template_Guid = @ProjectGuid,
				Layout_Guid = @LayoutGuid,
				Template_Version = @ProjectVersion,
				Layout_Version = @LayoutVersion,
				Folder_Guid = @FolderGuid,
				ShowFormActivity = @ShowFormActivity,
				MatchProjectVersion = @MatchProjectVersion,
				AllowRestart = @AllowRestart,
				OfflineDataSources = @OfflineDataSources,
				LogPageTransition = @LogPageTransition,
				SkinXml = @SkinXml,
				AllowSave = @AllowSave,
				IsHomePage = @IsHomePage
		WHERE	Template_Group_Guid = @ProjectGroupGuid;
		DECLARE @StoredSkin nvarchar(max)
		SELECT @StoredSkin = CAST(SkinXml as nvarchar(max)) FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid
		IF @SkinXml = ''
			BEGIN
				UPDATE Template_Group SET SkinLastUpdated = NULL WHERE Template_Group_Guid = @ProjectGroupGuid;
			END
		ELSE 
		BEGIN
			IF REPLACE(REPLACE(Replace(@ExistingSkin,' ',''), CHAR(13), ''), CHAR(10), '') <> REPLACE(REPLACE(Replace(@StoredSkin,' ',''), CHAR(13), ''), CHAR(10), '')
			BEGIN
				UPDATE Template_Group SET SkinLastUpdated = GETUTCDATE() WHERE Template_Group_Guid = @ProjectGroupGuid;
			END
		END
	END

	EXEC spProjectGroup_UpdateFeatureFlags @ProjectGroupGuid=@ProjectGroupGuid;

GO

ALTER PROCEDURE [dbo].[spProjectGroup_FolderListSearch]
	@UserGuid uniqueidentifier,
	@SearchTerm nvarchar(50),
	@HomePageOnly bit
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid;

	SELECT	f.Folder_Name, tg.Template_Group_ID,
			tg.HelpText as TemplateGroup_HelpText, t.[Name] as Template_Name, 
			tg.Template_Group_Guid, tg.FeatureFlags
	FROM	Folder f
			INNER JOIN Template_Group tg on f.Folder_Guid = tg.Folder_Guid
			INNER JOIN Template t on tg.Template_Guid = t.Template_Guid
	WHERE	f.Business_Unit_GUID = @BusinessUnitGUID
			AND f.Folder_Guid IN (
				SELECT	Folder_Group.FolderGuid
				FROM	Folder_Group
						INNER JOIN User_Group_Subscription ON Folder_Group.GroupGuid = User_Group_Subscription.GroupGuid
				WHERE	User_Group_Subscription.UserGuid = @UserGuid
				)
			AND (f.Folder_Name COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchTerm + '%') COLLATE Latin1_General_CI_AI
			     OR t.Name COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchTerm + '%') COLLATE Latin1_General_CI_AI)
			AND (tg.EnforcePublishPeriod = 0 
				OR ((tg.PublishStartDate IS NULL OR tg.PublishStartDate < getdate())
					AND (tg.PublishFinishDate IS NULL OR tg.PublishFinishDate > getdate())))
			AND (@HomePageOnly = 0
				OR (@HomePageOnly = 1 AND tg.IsHomePage = 1))
	ORDER BY f.Folder_Name, t.[Name]

GO

ALTER procedure [dbo].[spProjectGrp_ProjectGroupList]
	@ProjectGroupGuid uniqueidentifier
AS
    SELECT	a.Template_Group_ID, t.[Name] as Template_Name, a.template_group_guid, 
			a.helptext as TemplateGroup_HelpText, a.Template_Guid, a.Layout_Guid,
			a.Template_Version, a.Layout_Version, a.AllowPreview, a.PostGenerateText,
			a.UpdateDocumentFields, a.EnforceValidation, a.WizardFinishText, 
			a.EnforcePublishPeriod, a.PublishStartDate, a.PublishFinishDate,
			a.HideNavigationPane, a.ShowFormActivity, a.MatchProjectVersion,
			a.AllowRestart, a.OfflineDataSources, a.LogPageTransition,
			a.AllowSave, a.Folder_Guid, a.IsHomePage
    FROM	Template_Group a
			INNER JOIN Template t on a.Template_Guid = t.Template_Guid
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;

GO

ALTER procedure [dbo].[spProject_GetProjectsByContentItem]
	@ContentGuid varchar(40),
	@BusinessUnitGuid uniqueidentifier
as
	SET ARITHABORT ON 

	SELECT 	Template.template_id, 
			Template.[name] as project_name, 
			Template.template_type_id, 
			Template.template_guid, 
			Template.template_version, 
			Template.import_date,
			Template.Business_Unit_GUID, 
			Template.Supplier_Guid,
			Template.Modified_Date,
			Intelledox_User.Username,
			Template.Modified_By,
			Template.FeatureFlags,
			Template.FolderGuid
	FROM	Template
		LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By
		LEFT JOIN Xtf_ContentLibrary_Dependency on Xtf_ContentLibrary_Dependency.Template_Guid = Template.Template_Guid
	WHERE	Template.Business_Unit_GUID = @BusinessUnitGuid
		AND Xtf_ContentLibrary_Dependency.Content_Object_Guid = @ContentGuid 
	ORDER BY Template.[name];

GO
