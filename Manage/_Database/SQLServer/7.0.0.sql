/*
** Database Update package 7.0.0
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.0.0')
go

--1932
DECLARE @CompatibilityLevel int
DECLARE @SQL varchar(200)

SELECT	@CompatibilityLevel = Compatibility_Level
FROM	sys.databases
WHERE	name = DB_NAME();

IF @CompatibilityLevel = 80
BEGIN
	SET @SQL = 'ALTER DATABASE ' + DB_NAME() + ' SET COMPATIBILITY_LEVEL = 90';
	EXECUTE @SQL;
END
GO


--1933
TRUNCATE TABLE ProcessJob
GO
ALTER TABLE ProcessJob
	DROP COLUMN Completed
GO
ALTER TABLE ProcessJob
	ADD UserGuid uniqueidentifier,
	DateStarted datetime,
	ProjectGroupGuid uniqueidentifier,
	CurrentStatus int
GO
ALTER TABLE ProcessJob
	ADD LogGuid uniqueidentifier NULL
GO
CREATE TABLE Job (
	JobId uniqueidentifier primary key,
	Name nvarchar(200),
	NextRunDate datetime null,
	IsEnabled bit,
	OwnerGuid uniqueidentifier,
	DateCreated datetime,
	DateModified datetime,
	JobDefinition xml
	)
GO
CREATE PROCEDURE spJob_CreateJob(
	@JobId uniqueidentifier,
	@Name nvarchar(200),
	@IsEnabled bit,
	@OwnerGuid uniqueidentifier,
	@DateCreated datetime,
	@DateModified datetime,
	@JobDefinition xml
)
AS
	INSERT INTO Job(JobId, Name, NextRunDate, IsEnabled, OwnerGuid, DateCreated, DateModified, JobDefinition)
	VALUES (@JobId, @Name, NULL, @IsEnabled, @OwnerGuid, @DateCreated, @DateModified, @JobDefinition);
GO
ALTER TABLE Template_Log
	ADD Messages XML NULL
GO
CREATE PROCEDURE [dbo].[spLog_CompleteProjectLog]
	@LogGuid uniqueidentifier,
	@MessageXml xml = null
AS
	DECLARE @FinishDate datetime;
	
	SET @FinishDate = GetDate();
	
	UPDATE	Template_Log 
	SET		DateTime_Finish = @FinishDate, 
			Completed = 1,
			Messages = @MessageXml,
			InProgress = 0
	WHERE	Log_Guid = @LogGuid;
GO
ALTER procedure [dbo].[spAudit_AnswerFileList]
	@AnswerFile_ID int = 0,
	@User_Guid uniqueidentifier = null,
	@WebOnly char(1) = 0,
	@InProgress char(1) = '0',
	@TemplateGroupGuid uniqueidentifier = null,
	@ErrorCode int output
AS
	DECLARE @User_Id Int
	
	set nocount on
	
	IF (@User_Guid IS NOT NULL)
	BEGIN
		SELECT	@User_Id = User_Id
		FROM	Intelledox_User
		WHERE	User_Guid = @User_Guid;
	END

	if @AnswerFile_ID = 0 or @AnswerFile_ID is null
    begin
        if @User_ID = 0 or @User_ID is null
            SELECT	Answer_File.*, Template_Group.Template_Group_Guid, Intelledox_User.User_Guid
			FROM	Answer_File
					INNER JOIN Template_Group ON Answer_File.Template_Group_Id = Template_Group.Template_Group_Id
					INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
					INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
					INNER JOIN Intelledox_User ON Answer_File.User_Id = Intelledox_User.User_ID
			WHERE	Answer_File.InProgress = @InProgress
            order by Answer_File.[RunDate] desc;
        else
		begin
			if @TemplateGroupGuid is null
				select ans.*, T.Name as TemplateGroup_Name, Template_Group.Template_Group_Guid,
						Intelledox_User.User_Guid
				from	answer_file ans
						INNER JOIN Template_Group on ans.Template_Group_ID = Template_Group.Template_Group_ID
						INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
						INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
						INNER JOIN Intelledox_User ON ans.User_Id = Intelledox_User.User_ID
				where Ans.[user_ID] = @user_id
					AND Ans.[InProgress] = @InProgress
					AND Ans.template_group_id in(

					-- Get a union of template group and template package.
					SELECT DISTINCT tg.Template_Group_ID
					FROM Folder f
						left join (
							SELECT tg.Template_Group_ID, ft.Folder_ID
							FROM folder_template ft
							LEFT JOIN template_group tg ON ft.FolderItem_ID = tg.Template_Group_ID AND ft.ItemType_ID = 1
							UNION
							SELECT pt.Template_Group_ID, ft.Folder_ID
							FROM folder_template ft
							LEFT JOIN package_template pt ON ft.FolderItem_ID = pt.Package_ID AND ft.ItemType_ID = 2
						) tg on f.Folder_ID = tg.Folder_ID
						left join template_group_item tgi on tg.template_group_id = tgi.template_group_id
						left join template t on tgi.template_id = t.template_id
						inner join folder_group fg on F.Folder_Guid = fg.FolderGuid
					where 	(fg.GroupGuid in
								(select b.Group_Guid
								from intelledox_user a
								left join User_Group_Subscription c on a.[User_ID] = c.[User_ID]
								left join user_group b on c.user_group_id = b.user_group_id
								where c.[user_id] = @user_id)
							)
				)
				order by [RunDate] desc;
			else
				select	ans.*, Template_Group.Name as TemplateGroup_Name, Template_Group.Template_Group_Guid,
						Intelledox_User.User_Guid
				from	answer_file ans
						INNER JOIN Template_Group on ans.Template_Group_ID = Template_Group.Template_Group_ID
						INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
						INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
						INNER JOIN Intelledox_User ON ans.User_Id = Intelledox_User.User_ID
				where Ans.[user_ID] = @user_id
					AND Template_Group.Template_group_Guid = @TemplateGroupGuid
				order by [RunDate] desc;
		end
    end
    else
    begin
        SELECT	Answer_File.*, Template_Group.Template_Group_Guid, Intelledox_User.User_Guid
		FROM	Answer_File
				INNER JOIN Template_Group ON Answer_File.Template_Group_Id = Template_Group.Template_Group_Id
				INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
				INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
				INNER JOIN Intelledox_User ON Answer_File.User_Id = Intelledox_User.User_ID
        WHERE	Answer_File.AnswerFile_Id = @AnswerFile_Id
        ORDER BY Answer_File.[RunDate] desc;
    end
GO
ALTER PROCEDURE [dbo].[spAudit_UpdateAnswerFile]
	@AnswerFile_ID int,
	@User_Guid uniqueidentifier,
	@Template_Group_Guid uniqueidentifier,
	@Description nvarchar(255),
	@RunDate datetime,
	@AnswerString xml,
	@InProgress char(1) = '0',
	@NewID int output,
	@ErrorCode int output
AS
	set nocount on
	
	DECLARE @Template_Group_Id Int
	DECLARE @User_Id Int
	
	SELECT	@Template_Group_Id = Template_Group_Id
	FROM	Template_Group
	WHERE	Template_Group_Guid = @Template_Group_Guid;
	
	SELECT	@User_Id = User_Id
	FROM	Intelledox_User
	WHERE	User_Guid = @User_Guid;

	if @AnswerFile_ID = 0 or @AnswerFile_ID is null
	begin
		insert into Answer_File ([User_ID], [Template_Group_ID], [Description], [RunDate], [AnswerString], [InProgress])
		values (@User_ID, @Template_Group_ID, @Description, @RunDate, @AnswerString, @InProgress);

		select @NewID = @@Identity;
	end
	else
	begin
		update Answer_File
		set [Description] = @Description,
			RunDate = @RunDate,
			AnswerString = @AnswerString
		where AnswerFile_ID = @AnswerFile_ID;
	end

	set @ErrorCode = @@Error;
GO
ALTER PROCEDURE [dbo].[spJob_LodgeJob] (
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier,
	@DateStarted datetime,
	@ProjectGroupGuid uniqueidentifier,
	@LogGuid uniqueidentifier
)
AS
	INSERT INTO ProcessJob(JobId, UserGuid, DateStarted, ProjectGroupGuid, CurrentStatus, LogGuid)
	VALUES (@JobId, @UserGuid, @DateStarted, @ProjectGroupGuid, 1, @LogGuid);
GO
DROP PROCEDURE [dbo].[spJob_IsComplete]
DROP PROCEDURE spJob_JobCompleted
GO
CREATE PROCEDURE [dbo].[spJob_GetStatus] (
	@JobId uniqueidentifier
)
AS
	SELECT	CurrentStatus
	FROM	ProcessJob
	WHERE	JobId = @JobId;
GO
CREATE PROCEDURE [dbo].[spJob_UpdateStatus] (
	@JobId uniqueidentifier,
	@CurrentStatus int
)
AS
	UPDATE	ProcessJob
	SET		CurrentStatus = @CurrentStatus
	WHERE	JobId = @JobId;
GO
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
			MAX(CanManageConsole) as CanManageConsole
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
			CASE WHEN Role_Permission.PermissionGuid = '22A89A6C-C131-4DF1-9A4F-50CFC5E69B58' THEN 1 ELSE 0 END AS CanManageConsole
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
			CASE WHEN Role_Permission.PermissionGuid = '22A89A6C-C131-4DF1-9A4F-50CFC5E69B58' THEN 1 ELSE 0 END AS CanManageConsole
		FROM	Role_Permission
				INNER JOIN User_Group_Role ON Role_Permission.RoleGuid = User_Group_Role.RoleGuid
				INNER JOIN User_Group ON User_Group_Role.GroupGuid = User_Group.Group_Guid
				INNER JOIN User_Group_Subscription ON User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
				INNER JOIN Intelledox_User ON Intelledox_User.User_ID = User_Group_Subscription.User_ID
		) PermissionCombination
		GROUP BY UserGuid, RoleGuid, GroupGuid
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
					MAX(CASE WHEN Role_Permission.PermissionGuid = '22A89A6C-C131-4DF1-9A4F-50CFC5E69B58' THEN 1 ELSE 0 END) AS CanManageConsole
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
					MAX(CASE WHEN Role_Permission.PermissionGuid = '22A89A6C-C131-4DF1-9A4F-50CFC5E69B58' THEN 1 ELSE 0 END) AS CanManageConsole
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
				vwUserPermissions.CanManageConsole
		FROM	Administrator_Level
				LEFT JOIN vwUserPermissions ON Administrator_Level.RoleGuid = vwUserPermissions.RoleGuid
		WHERE	Administrator_Level.Business_Unit_GUID = @BusinessUnitGUID
				AND vwUserPermissions.UserGUID = @UserGUID
				AND vwUserPermissions.GroupGuid IS NULL
		ORDER BY Administrator_Level.AdminLevel_Description;
	END

	set @errorcode = @@error;
GO
INSERT INTO dbo.Permission(PermissionGuid, Name, Description) 
VALUES ('22A89A6C-C131-4DF1-9A4F-50CFC5E69B58', 'Management Console', 'Manage queues and monitor current activity');
GO
CREATE PROCEDURE dbo.spJob_QueueList
	@StartDate DateTime,
	@FinishDate DateTime,
	@CurrentStatus Int
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus,
			Template.Name as ProjectName, Intelledox_User.Username, 
			ProcessJob.LogGuid,
			CASE WHEN template_Log.Messages IS NOT NULL THEN 1 ELSE 0 END AS HasMessages
	FROM	ProcessJob
			INNER JOIN Intelledox_User ON ProcessJob.UserGuid = Intelledox_User.User_Guid
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template_Group_Item ON Template_Group.Template_Group_Guid = Template_Group_Item.Template_Group_Guid
			INNER JOIN Template ON Template_Group_Item.Template_Guid = Template.Template_Guid
			LEFT JOIN Template_Log ON ProcessJob.LogGuid = Template_Log.Log_Guid
	WHERE	ProcessJob.DateStarted BETWEEN @StartDate AND @FinishDate
			AND (@CurrentStatus = 0 OR ProcessJob.CurrentStatus = @CurrentStatus)
	ORDER BY ProcessJob.DateStarted DESC;
GO

