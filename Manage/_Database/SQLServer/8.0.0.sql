/*
** Database Update package 8.0.0
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.0.0');
go

--2012
UPDATE	Answer_File
SET		InProgress = 0
WHERE	InProgress IS NULL;
GO
ALTER TABLE Answer_File
    ALTER COLUMN InProgress bit not null
GO
ALTER TABLE Answer_File ADD CONSTRAINT
    DF_Answer_File_InProgress DEFAULT 0 FOR InProgress
GO



ALTER TABLE User_Group_Template
    ADD GroupGuid uniqueidentifier null
GO
ALTER TABLE User_Group_Template
    ADD TemplateGuid uniqueidentifier null
GO
UPDATE	User_Group_Template
SET		GroupGuid = ug.Group_Guid
FROM	User_Group_Template
        INNER JOIN User_Group ug ON User_Group_Template.User_Group_ID = ug.User_Group_ID
GO
UPDATE	User_Group_Template
SET		TemplateGuid = t.Template_Guid
FROM	User_Group_Template
        INNER JOIN Template t ON User_Group_Template.Template_ID = t.Template_ID
GO
DELETE FROM User_Group_Template
WHERE	TemplateGuid IS NULL
        OR GroupGuid IS NULL
GO
ALTER TABLE User_Group_Template
    DROP COLUMN User_Group_Id
GO
ALTER TABLE User_Group_Template
    DROP COLUMN Template_Group_Id
GO
ALTER TABLE User_Group_Template
    DROP COLUMN Template_Id
GO
ALTER TABLE USer_Group_Template
    DROP CONSTRAINT User_Group_Template_pk
GO
ALTER TABLE User_Group_Template
    DROP COLUMN User_Group_Template_Id
GO
ALTER TABLE User_Group_Template
    ALTER COLUMN GroupGuid uniqueidentifier not null
GO
ALTER TABLE User_Group_Template
    ALTER COLUMN TemplateGuid uniqueidentifier not null
GO
ALTER TABLE dbo.User_Group_Template ADD CONSTRAINT
    PK_User_Group_Template PRIMARY KEY CLUSTERED 
    (
    TemplateGuid,
    GroupGuid
    ) 
GO



UPDATE	Intelledox_User
SET		ChangePassword = 0
WHERE	ChangePassword IS NULL
GO
UPDATE	Intelledox_User
SET		WinNT_User = 0
WHERE	WinNT_User <> '1'
        OR WinNT_User IS NULL
GO
UPDATE	Intelledox_User
SET		[Disabled] = 0
WHERE	[Disabled] IS NULL
GO
ALTER TABLE Intelledox_User
    DROP COLUMN Deleted
GO
ALTER TABLE Intelledox_User
    ALTER COLUMN WinNT_User bit not null
GO
ALTER TABLE Intelledox_User
    ALTER COLUMN [Disabled] bit not null
GO
ALTER TABLE Intelledox_User
    ALTER COLUMN ChangePassword bit not null
GO
ALTER TABLE Intelledox_User ADD CONSTRAINT
    DF_Intelledox_User_ChangePassword DEFAULT 0 FOR ChangePassword
GO
ALTER TABLE Intelledox_User ADD CONSTRAINT
    DF_Intelledox_User_WinNT_User DEFAULT 0 FOR WinNT_User
GO
if (exists(SELECT *  
    FROM sys.default_constraints
    WHERE name ='DF_Intelledox_User_Disabled'))
BEGIN
    ALTER TABLE Intelledox_User 
    DROP CONSTRAINT DF_Intelledox_User_Disabled;
END
GO
ALTER TABLE Intelledox_User ADD CONSTRAINT
    DF_Intelledox_User_Disabled DEFAULT 0 FOR [Disabled]
GO



ALTER TABLE Intelledox_User
    ADD Address_ID int null
GO
ALTER TABLE User_Group
    ADD Address_ID int null
GO
UPDATE	Intelledox_User
SET		Address_ID = a.Address_ID
FROM	Intelledox_User
        INNER JOIN Address_Book a ON Intelledox_User.User_ID = a.User_Id
GO
UPDATE	User_Group
SET		Address_ID = a.Address_ID
FROM	User_Group
        INNER JOIN Address_Book a ON User_Group.User_Group_ID = a.UserGroup_Id
GO
DROP INDEX IX_Address_Book_User_ID ON Address_Book;
GO
DROP INDEX IX_Address_Book_User_Group ON Address_Book;
GO
ALTER TABLE Address_Book
    DROP COLUMN User_ID, UserGroup_ID
GO



ALTER TABLE User_Group_Subscription
    ADD UserGuid uniqueidentifier null,
        GroupGuid uniqueidentifier null,
        IsDefaultGroup bit null
GO
UPDATE	User_Group_Subscription
SET		UserGuid = u.User_Guid
FROM	Intelledox_User u
        INNER JOIN User_Group_Subscription ON u.User_ID = User_Group_Subscription.User_ID;
GO
UPDATE	User_Group_Subscription
SET		GroupGuid = g.Group_Guid
FROM	User_Group g
        INNER JOIN User_Group_Subscription ON g.User_Group_ID = User_Group_Subscription.User_Group_ID;
GO
UPDATE	User_Group_Subscription
SET		IsDefaultGroup = 0;

UPDATE	User_Group_Subscription
SET		IsDefaultGroup = 1
WHERE	Default_Group = '1';
GO
DELETE FROM User_Group_Subscription
WHERE	UserGuid IS NULL
        OR GroupGuid IS NULL;
GO
DELETE FROM User_Group_Subscription
WHERE User_Group_Subscription_ID NOT IN (
    SELECT	MIN(User_Group_Subscription_ID) as MinId
    FROM User_Group_Subscription ugs
    GROUP BY UserGuid, GroupGuid
    );
GO
DROP INDEX IX_User_Group_Subscription ON User_Group_Subscription;
GO
ALTER TABLE User_Group_Subscription
    DROP COLUMN User_ID, User_Group_Id, Default_Group
GO
ALTER TABLE User_Group_Subscription
    DROP COLUMN Group_Administrator
GO
ALTER TABLE User_Group_Subscription
    ALTER COLUMN UserGuid uniqueidentifier not null
GO
ALTER TABLE User_Group_Subscription
    ALTER COLUMN GroupGuid uniqueidentifier not null
GO
ALTER TABLE User_Group_Subscription
    ALTER COLUMN IsDefaultGroup bit not null
GO
ALTER TABLE User_Group_Subscription ADD CONSTRAINT
    DF_User_Group_Subscription_IsDefaultGroup DEFAULT 0 FOR IsDefaultGroup
GO
ALTER TABLE User_Group_Subscription
    DROP CONSTRAINT User_Group_Subscription_pk
GO
ALTER TABLE User_Group_Subscription
    DROP COLUMN User_Group_Subscription_ID
GO
ALTER TABLE dbo.User_Group_Subscription ADD CONSTRAINT
    PK_User_Group_Subscription PRIMARY KEY CLUSTERED 
    (
    UserGuid,
    GroupGuid
    ) 
GO



ALTER TABLE Template_Group_Item
    DROP COLUMN Template_Id, Layout_Id, Template_Group_Id
GO



ALTER TABLE Administrator_Level
    DROP COLUMN AdminLevel_User
GO
ALTER TABLE Administrator_Level
    DROP COLUMN AdminLevel_Template
GO
ALTER TABLE Administrator_Level
    DROP COLUMN AdminLevel_IT 
GO
ALTER TABLE Administrator_Level
    DROP COLUMN GlobalTemplate 
GO



UPDATE	User_Group
SET		WinNT_Group = 0
WHERE	WinNT_Group <> 1
        OR WinNT_Group IS NULL
GO
UPDATE	User_Group
SET		AutoAssignment = 0
WHERE	AutoAssignment <> 1
        OR AutoAssignment IS NULL
GO
UPDATE	User_Group
SET		SystemGroup = 0
WHERE	SystemGroup <> 1
        OR SystemGroup IS NULL
GO
ALTER TABLE User_Group
    DROP CONSTRAINT DF_User_Group_WinNT_Sync
GO
ALTER TABLE User_Group
    DROP CONSTRAINT DF_User_Group_WinNT_Group
GO
ALTER TABLE User_Group
    DROP COLUMN WinNT_Sync
GO
ALTER TABLE User_Group
    DROP COLUMN Deleted
GO
ALTER TABLE User_Group
    ALTER COLUMN WinNT_Group bit not null
GO
ALTER TABLE User_Group
    ALTER COLUMN AutoAssignment bit not null
GO
ALTER TABLE User_Group
    ALTER COLUMN SystemGroup bit not null
GO
ALTER TABLE User_Group ADD CONSTRAINT
    DF_User_Group_WinNT_Group DEFAULT 0 FOR WinNT_Group
GO
ALTER TABLE User_Group ADD CONSTRAINT
    DF_User_Group_AutoAssignment DEFAULT 0 FOR AutoAssignment
GO
ALTER TABLE User_Group ADD CONSTRAINT
    DF_User_Group_SystemGroup DEFAULT 0 FOR SystemGroup
GO

--2013

ALTER VIEW [dbo].[vwStatsDailyLoginReport]
as
    select u.Username, ab.first_name as firstname, ab.last_name as lastname, ab.organisation_name, tblLog.GenDate as LoginDate, tblLog.Startcount, tblLog.Finishcount from (
        select logstart.User_Id, cast(floor(cast(logstart.DateTime_Start as float)) as datetime) as GenDate, count(logstart.log_guid) as StartCount, logfinish.FinishCount
        from template_log logStart
        left join (
            select User_Id, cast(floor(cast(DateTime_Finish as float)) as datetime) as FinishDate, count(log_guid) as FinishCount
            from template_log
            where datetime_finish is not null
            group by User_ID, cast(floor(cast(DateTime_Finish as float)) as datetime)
        ) logFinish on logStart.user_id = logfinish.user_id and logfinish.Finishdate = cast(floor(cast(logstart.DateTime_Start as float)) as datetime)
        where logstart.DateTime_Start is not null
        group by logstart.User_ID, cast(floor(cast(logstart.DateTime_Start as float)) as datetime), logfinish.FinishCount
    ) tblLog
    left join intelledox_user u on u.user_id = tblLog.user_id
    left join address_book ab on u.Address_Id = ab.Address_ID
GO
ALTER VIEW [dbo].[vwStatsDailyLoginReportSummary]
as
    select LoginDate, sum(StartCount) as StartTotal, sum(FinishCount) as FinishTotal
    from (
        select u.Username, ab.first_name as firstname, ab.last_name as lastname, ab.organisation_name, tblLog.GenDate as LoginDate, tblLog.Startcount, tblLog.Finishcount from (
            select logstart.User_Id, cast(floor(cast(logstart.DateTime_Start as float)) as datetime) as GenDate, count(logstart.log_guid) as StartCount, logfinish.FinishCount
            from template_log logStart
            left join (
                select User_Id, cast(floor(cast(DateTime_Finish as float)) as datetime) as FinishDate, count(log_guid) as FinishCount
                from template_log
                where datetime_finish is not null
                group by User_ID, cast(floor(cast(DateTime_Finish as float)) as datetime)
            ) logFinish on logStart.user_id = logfinish.user_id and logfinish.Finishdate = cast(floor(cast(logstart.DateTime_Start as float)) as datetime)
            where logstart.DateTime_Start is not null
            group by logstart.User_ID, cast(floor(cast(logstart.DateTime_Start as float)) as datetime), logfinish.FinishCount
        ) tblLog
        left join intelledox_user u on u.user_id = tblLog.user_id
        left join address_book ab on u.Address_ID = ab.Address_ID
        ) a
    group by LoginDate

GO
ALTER PROCEDURE [dbo].[spProjectGroup_Recent]
    @UserGuid uniqueidentifier,
    @ProjectSearch nvarchar(100)
AS
    DECLARE @BusinessUnitGuid uniqueidentifier
    
    SELECT	@BusinessUnitGuid = Business_Unit_Guid
    FROM	Intelledox_User
    WHERE	Intelledox_User.User_Guid = @UserGuid;
    
    SELECT	DISTINCT d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
            d.HelpText as TemplateGroup_HelpText, b.Template_ID, b.[Name] as Template_Name, 
            b.Template_Type_ID, d.Template_Group_Guid, l.DateTime_Start
    FROM	Folder a
            INNER JOIN Folder_Template c on a.Folder_ID = c.Folder_ID
            INNER JOIN Template_Group d on c.folderitem_ID = d.Template_Group_ID and itemtype_id = 1
            INNER JOIN Template_Group_Item e on d.Template_Group_Guid = e.Template_Group_Guid
            INNER JOIN Template b on e.Template_Guid = b.Template_Guid
            INNER JOIN Template_Recent l on d.Template_Group_Guid = l.Template_Group_Guid
    WHERE	a.Business_Unit_GUID = @BusinessUnitGUID
            AND a.Folder_Guid IN (
                SELECT	Folder_Group.FolderGuid
                FROM	Folder_Group
                        INNER JOIN User_Group ON Folder_Group.GroupGuid = User_Group.Group_Guid
                        INNER JOIN User_Group_Subscription ON User_Group.Group_Guid = User_Group_Subscription.GroupGuid
                        INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
                WHERE	Intelledox_User.User_Guid = @UserGuid
                )
            AND CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END LIKE @ProjectSearch + '%'
            AND l.[User_Guid] = @UserGuid
            AND (d.EnforcePublishPeriod = 0 
                OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getutcdate())
                    AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getutcdate())))
    ORDER BY l.DateTime_Start DESC;
GO
ALTER procedure [dbo].[spAudit_AnswerFileList]
    @AnswerFile_ID int = 0,
    @User_Guid uniqueidentifier = null,
    @InProgress bit = 0,
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
        if @TemplateGroupGuid is null
            select	ans.AnswerFile_Id, ans.User_Id, ans.Template_Group_Id, ans.Description, 
                    ans.RunDate, ans.InProgress, 
                    T.Name as TemplateGroup_Name, Template_Group.Template_Group_Guid,
                    Intelledox_User.User_Guid
            from	answer_file ans
                    INNER JOIN Template_Group on ans.Template_Group_ID = Template_Group.Template_Group_ID
                    INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_Guid = TGI.Template_Group_Guid
                    INNER JOIN Template AS T ON TGI.Template_Guid = T.Template_Guid
                    INNER JOIN Intelledox_User ON ans.User_Id = Intelledox_User.User_ID
            where Ans.[user_ID] = @user_id
                AND Ans.[InProgress] = @InProgress
                AND Ans.template_group_id in(

                -- Get a union of template group.
                SELECT DISTINCT tg.Template_Group_ID
                FROM Folder f
                    left join (
                        SELECT tg.Template_Group_ID, ft.Folder_ID, tg.Template_Group_Guid
                        FROM folder_template ft
                        LEFT JOIN template_group tg ON ft.FolderItem_ID = tg.Template_Group_ID 
                            AND ft.ItemType_ID = 1
                            AND (tg.EnforcePublishPeriod = 0 
                                OR ((tg.PublishStartDate IS NULL OR tg.PublishStartDate < getutcdate())
                                    AND (tg.PublishFinishDate IS NULL OR tg.PublishFinishDate > getutcdate())))
                    ) tg on f.Folder_ID = tg.Folder_ID
                    left join template_group_item tgi on tg.template_group_Guid = tgi.Template_Group_Guid
                    left join template t on tgi.template_Guid = t.Template_Guid
                    inner join folder_group fg on F.Folder_Guid = fg.FolderGuid
                where 	(fg.GroupGuid in
                            (select b.Group_Guid
                            from intelledox_user a
                            left join User_Group_Subscription c on a.User_Guid = c.UserGuid
                            left join user_group b on c.groupguid = b.group_guid
                            where c.UserGuid = @user_guid)
                        )
            )
            order by [RunDate] desc;
        else
            select	ans.AnswerFile_Id, ans.User_Id, ans.Template_Group_Id, ans.Description, 
                    ans.RunDate, ans.InProgress, 
                    Template_Group.Name as TemplateGroup_Name, Template_Group.Template_Group_Guid,
                    Intelledox_User.User_Guid
            from	answer_file ans
                    INNER JOIN Template_Group on ans.Template_Group_ID = Template_Group.Template_Group_ID
                    INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_Guid = TGI.Template_Group_Guid
                    INNER JOIN Template AS T ON TGI.Template_Guid = T.Template_Guid
                    INNER JOIN Intelledox_User ON ans.User_Id = Intelledox_User.User_ID
            where Ans.[user_ID] = @user_id
                AND Template_Group.Template_group_Guid = @TemplateGroupGuid
            order by [RunDate] desc;
    end
    else
    begin
        SELECT	Answer_File.*, Template_Group.Template_Group_Guid, Intelledox_User.User_Guid
        FROM	Answer_File
                INNER JOIN Template_Group ON Answer_File.Template_Group_Id = Template_Group.Template_Group_Id
                INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_Guid = TGI.Template_Group_Guid
                INNER JOIN Template AS T ON TGI.Template_Guid = T.Template_Guid
                INNER JOIN Intelledox_User ON Answer_File.User_Id = Intelledox_User.User_ID
        WHERE	Answer_File.AnswerFile_Id = @AnswerFile_Id
        ORDER BY Answer_File.[RunDate] desc;
    end
GO
ALTER procedure [dbo].[spUsers_UserGroupByUser]
    @UserID int,
    @BusinessUnitGUID uniqueidentifier,
    @Username nvarchar(50) = '',
    @UserGroupID int = 0,
    @UserGuid uniqueidentifier = null,
    @ErrorCode int = 0 output
as
    if @UserGroupID = 0	--all user groups
    begin
        if @UserGuid is null
        begin
            if @UserID is null or @UserID = 0
            begin
                select	a.*, Business_Unit.DefaultLanguage
                from	Intelledox_User a
                    left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
                where	(@Username = '' OR @Username is null OR a.[Username] like @Username + '%')
                    AND (a.Business_Unit_GUID = @BusinessUnitGUID)
                ORDER BY a.[Username]
            end
            else
            begin
                select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
                from	Intelledox_User a
                    left join User_Group_Subscription c on a.User_Guid = c.UserGuid
                    left join User_Group b on c.GroupGuid = b.Group_Guid
                    left join Address_Book d on a.Address_Id = d.Address_id
                    left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
                where	(a.[User_ID] = @UserID)
                ORDER BY a.[Username]
            end
        end
        else
        begin
            select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
            from	Intelledox_User a
                left join User_Group_Subscription c on a.User_Guid = c.UserGuid
                left join User_Group b on c.GroupGuid = b.Group_Guid
                left join Address_Book d on a.Address_Id = d.Address_id
                left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
            where	(User_Guid = @UserGuid)
            ORDER BY a.[Username]
        end
    end
    else
    begin
        if @UserGroupID = -1	--users with no user groups
        begin
            select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
            from	Intelledox_User a
                left join User_Group_Subscription c on a.User_Guid = c.UserGuid
                left join User_Group b on c.GroupGuid = b.Group_Guid
                left join Address_Book d on a.Address_Id = d.Address_id
                left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
            where	(@UserID = 0 OR @UserID IS NULL OR a.[User_ID] = @UserID)
                AND	(@Username = '' OR @Username is null OR a.[Username] like @Username + '%')
                AND	a.User_Guid not in (
                        select a.userGuid
                        from user_group_subscription a 
                        inner join user_Group b on a.GroupGuid = b.Group_Guid
                    )
                AND (@UserID <> 0 OR a.Business_Unit_GUID = @BusinessUnitGUID)
            ORDER BY a.[Username]
        end
        else			--users in specified user group
        begin
            select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
            from	Intelledox_User a
                left join User_Group_Subscription c on a.User_Guid = c.UserGuid
                left join User_Group b on c.GroupGuid = b.Group_Guid
                left join Address_Book d on a.Address_Id = d.Address_id
                left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
            where	(@UserID = 0 OR @UserID IS NULL OR a.[User_ID] = @UserID)
                AND	(@Username = '' OR @Username is null OR a.[Username] like @Username + '%')
                AND	c.GroupGuid = (SELECT Group_Guid FROM User_Group WHERE User_Group_id = @UserGroupID)
                AND (@UserID <> 0 OR a.Business_Unit_GUID = @BusinessUnitGUID)
            ORDER BY a.[Username]
        end
    end

    set @ErrorCode = @@error
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
            MAX(CanManageConsole) as CanManageConsole,
            MAX(CanApproveContent) as CanApproveContent
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
            CASE WHEN Role_Permission.PermissionGuid = 'F9A676FF-93F8-4D15-9F24-B95DD8C01762' THEN 1 ELSE 0 END AS CanApproveContent
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
            CASE WHEN Role_Permission.PermissionGuid = 'F9A676FF-93F8-4D15-9F24-B95DD8C01762' THEN 1 ELSE 0 END AS CanApproveContent
        FROM	Role_Permission
                INNER JOIN User_Group_Role ON Role_Permission.RoleGuid = User_Group_Role.RoleGuid
                INNER JOIN User_Group ON User_Group_Role.GroupGuid = User_Group.Group_Guid
                INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
                INNER JOIN Intelledox_User ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
        ) PermissionCombination
        GROUP BY UserGuid, RoleGuid, GroupGuid
GO
ALTER PROCEDURE [dbo].[spProjectGroup_FolderListAll]
    @UserGuid uniqueidentifier,
    @FolderSearch nvarchar(50),
    @ProjectSearch nvarchar(100)
AS
    DECLARE @BusinessUnitGuid uniqueidentifier
    
    SELECT	@BusinessUnitGuid = Business_Unit_Guid
    FROM	Intelledox_User
    WHERE	Intelledox_User.User_Guid = @UserGuid;
    
    SELECT	DISTINCT a.*, d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
            d.HelpText as TemplateGroup_HelpText, b.Template_ID, b.[Name] as Template_Name, 
            b.Template_Type_ID, d.Template_Group_Guid
    FROM	Folder a
            INNER JOIN Folder_Template c on a.Folder_ID = c.Folder_ID
            INNER JOIN Template_Group d on c.folderitem_ID = d.Template_Group_ID and itemtype_id = 1
            INNER JOIN Template_Group_Item e on d.Template_Group_Guid = e.Template_Group_Guid
            INNER JOIN Template b on e.Template_Guid = b.Template_Guid
    WHERE	a.Business_Unit_GUID = @BusinessUnitGUID
            AND a.Folder_Guid IN (
                SELECT	Folder_Group.FolderGuid
                FROM	Folder_Group
                        INNER JOIN User_Group ON Folder_Group.GroupGuid = User_Group.Group_Guid
                        INNER JOIN User_Group_Subscription ON User_Group.Group_Guid = User_Group_Subscription.GroupGuid
                        INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
                WHERE	Intelledox_User.User_Guid = @UserGuid
                )
            AND a.Folder_Name LIKE @FolderSearch + '%'
            AND CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END LIKE @ProjectSearch + '%'
            AND (d.EnforcePublishPeriod = 0 
                OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getutcdate())
                    AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getutcdate())))
    ORDER BY a.Folder_Name, a.Folder_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END;
GO
ALTER procedure [dbo].[spAddBk_UserAddress]
    @UserID int,
    @ErrorCode int = 0 output
AS
    SELECT	Address_Book.*
    FROM	Address_Book
            INNER JOIN Intelledox_User ON Address_Book.Address_Id = Intelledox_User.Address_Id
    WHERE	Intelledox_User.[User_ID] = @UserID

    set @ErrorCode = @@error
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
        WHERE ExpiryDate < GETUTCDATE();
        
        IF @ExactMatch = 1
            SELECT	ci.*, 
                    Content.FileType, 
                    Content.Modified_Date, 
                    Intelledox_User.UserName,
                    CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
                    CASE WHEN (@UserId IS NULL 
                        OR ci.FolderGuid IS NULL 
                        OR (NOT EXISTS (
                            SELECT * 
                            FROM Content_Folder_Group 
                            WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
                        OR EXISTS (
                            SELECT * 
                            FROM Content_Folder_Group
                                INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
                                INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
                                INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
                            WHERE Intelledox_User.User_Guid = @UserId
                                AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
                    THEN 1 ELSE 0 END
                    AS CanEdit,
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
            SELECT DISTINCT	ci.*, 
                    Content.FileType, 
                    Content.Modified_Date, 
                    Intelledox_User.UserName,
                    CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
                    CASE WHEN (@UserId IS NULL 
                        OR ci.FolderGuid IS NULL 
                        OR (NOT EXISTS (
                            SELECT * 
                            FROM Content_Folder_Group 
                            WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
                        OR EXISTS (
                            SELECT * 
                            FROM Content_Folder_Group
                                INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
                                INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
                                INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
                            WHERE Intelledox_User.User_Guid = @UserId
                                AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
                    THEN 1 ELSE 0 END
                    AS CanEdit,
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
                    AND ci.NameIdentity LIKE '%' + @Name + '%'
                    AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
                    AND ci.Description LIKE '%' + @Description + '%'
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
        WHERE	ExpiryDate < GETUTCDATE()
                AND contentitem_guid = @ItemGuid;
        
        IF (@MinimalGet = 1)
        BEGIN
            SELECT	ci.*, 
                    '' as FileType, 
                    NULL as Modified_Date, 
                    '' as UserName,
                    0 as HasUnapprovedRevision,
                    0 as CanEdit,
                    Content_Folder.FolderName						
            FROM	content_item ci
                LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
            WHERE	ci.contentitem_guid = @ItemGuid;
        END
        ELSE
        BEGIN
            SELECT	ci.*, 
                    Content.FileType, 
                    Content.Modified_Date, 
                    Intelledox_User.UserName,
                    CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
                    CASE WHEN (@UserId IS NULL 
                        OR ci.FolderGuid IS NULL 
                        OR (NOT EXISTS (
                            SELECT * 
                            FROM Content_Folder_Group 
                            WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
                        OR EXISTS (
                            SELECT * 
                            FROM Content_Folder_Group
                                INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
                                INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
                                INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
                            WHERE Intelledox_User.User_Guid = @UserId
                                AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
                    THEN 1 ELSE 0 END
                    AS CanEdit,
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
    
    set @ErrorCode = @@error;
GO
ALTER procedure [dbo].[spContent_ContentItemListByFolder]
    @FolderGuid uniqueidentifier,
    @UserId uniqueidentifier
as
    SELECT	Content_Item.*, 
        ContentData_Binary.FileType, 
        ContentData_Binary.Modified_Date, 
        Intelledox_User.Username,
        0 As HasUnapprovedRevision,
        CASE WHEN (@UserId IS NULL 
            OR Content_Item.FolderGuid IS NULL 
            OR (NOT EXISTS (
                SELECT * 
                FROM Content_Folder_Group 
                WHERE Content_Item.FolderGuid = Content_Folder_Group.FolderGuid))
            OR EXISTS (
                SELECT * 
                FROM Content_Folder_Group
                    INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
                    INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
                    INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
                WHERE Intelledox_User.User_Guid = @UserId
                    AND Content_Item.FolderGuid = Content_Folder_Group.FolderGuid))
        THEN 1 ELSE 0 END
        AS CanEdit
    FROM	Content_Item
        LEFT JOIN ContentData_Binary ON Content_Item.ContentData_Guid = ContentData_Binary.ContentData_Guid
        LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = ContentData_Binary.Modified_By
    WHERE	FolderGuid = @FolderGuid
        OR (FolderGuid IS NULL AND @FolderGuid IS NULL)
    ORDER BY Content_Item.ContentType_Id,
        Content_Item.NameIdentity
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
    WHERE ExpiryDate < GETUTCDATE();

    IF @ItemGuid is null 
        IF @ExactMatch = 1
            SELECT	ci.*, 
                    Content.FileType, 
                    Content.Modified_Date, 
                    Intelledox_User.UserName,
                    CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
                    CASE WHEN (@UserId IS NULL 
                        OR ci.FolderGuid IS NULL 
                        OR (NOT EXISTS (
                            SELECT * 
                            FROM Content_Folder_Group 
                            WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
                        OR EXISTS (
                            SELECT * 
                            FROM Content_Folder_Group
                                INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
                                INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
                                INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
                            WHERE Intelledox_User.User_Guid = @UserId
                                AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
                    THEN 1 ELSE 0 END
                    AS CanEdit,
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
                    Intelledox_User.UserName,
                    CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
                    CASE WHEN (@UserId IS NULL 
                        OR ci.FolderGuid IS NULL 
                        OR (NOT EXISTS (
                            SELECT * 
                            FROM Content_Folder_Group 
                            WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
                        OR EXISTS (
                            SELECT * 
                            FROM Content_Folder_Group
                                INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
                                INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
                                INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
                            WHERE Intelledox_User.User_Guid = @UserId
                                AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
                    THEN 1 ELSE 0 END
                    AS CanEdit,
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
                    AND ci.NameIdentity LIKE '%' + @Name + '%'
                    AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
                    AND ci.Description LIKE '%' + @Description + '%'
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
                Intelledox_User.UserName,
                CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
                CASE WHEN (@UserId IS NULL 
                    OR ci.FolderGuid IS NULL 
                    OR (NOT EXISTS (
                        SELECT * 
                        FROM Content_Folder_Group 
                        WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
                    OR EXISTS (
                        SELECT * 
                        FROM Content_Folder_Group
                            INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
                            INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
                            INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
                        WHERE Intelledox_User.User_Guid = @UserId
                            AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
                THEN 1 ELSE 0 END
                AS CanEdit,
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
    
    set @ErrorCode = @@error;
GO
ALTER procedure [dbo].[spContent_UserHasAccess]
    @FolderGuid uniqueidentifier,
    @UserId uniqueidentifier
as
    SELECT	
        CASE WHEN (@FolderGuid IS NULL 
            OR (NOT EXISTS (
                SELECT * 
                FROM Content_Folder_Group 
                WHERE @FolderGuid = Content_Folder_Group.FolderGuid))
            OR EXISTS (
                SELECT * 
                FROM Content_Folder_Group
                    INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
                    INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
                    INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
                WHERE Intelledox_User.User_Guid = @UserId
                    AND @FolderGuid = Content_Folder_Group.FolderGuid))
        THEN 1 ELSE 0 END
        AS HasAccess
    FROM	Content_Folder
    WHERE	FolderGuid = @FolderGuid OR @FolderGuid IS NULL
GO
ALTER procedure [dbo].[spFolder_PublishedProjectList]
    @UserGuid uniqueidentifier,
    @ErrorCode int output
as
    declare @BusinessUnitGuid uniqueidentifier
    select @BusinessUnitGuid = business_unit_guid from Intelledox_User where User_Guid = @UserGuid

    SELECT	a.Folder_ID, a.Folder_Guid, a.Folder_Name, d.Template_Group_Id, b.[Name] as Project_Name,
            d.Template_Group_Guid
    FROM	Folder a
        left join Folder_Template c on a.Folder_ID = c.Folder_ID
        left join Template_Group d on c.FolderItem_Id = d.Template_Group_ID 
            and c.ItemType_Id = 1
            AND (d.EnforcePublishPeriod = 0 
                OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getutcdate())
                    AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getutcdate())))
        left join Template_Group_Item e on d.Template_Group_Guid = e.Template_Group_Guid
        left join Template b on e.Template_Guid = b.Template_Guid
    WHERE	((c.ItemType_ID = 1 and d.Template_Group_Guid in (
                    select	a.Template_Group_Guid
                    from	template_group_item a
                            inner join template b on a.template_Guid = b.template_Guid or a.layout_Guid = b.template_Guid
                            inner join template_group c on a.template_group_Guid = c.template_group_Guid
                    group by a.Template_Group_Guid
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
                        left join User_Group_Subscription c on a.User_Guid = c.UserGuid
                        left join User_Group b on c.GroupGuid = b.Group_Guid
                where	b.Group_Guid is not null
                and		a.User_Guid = @UserGuid
            )
        )
    ORDER BY a.Folder_Name, a.Folder_ID, c.folderitem_id
    
    set @ErrorCode = @@error
GO
ALTER procedure [dbo].[spProject_ProjectList]
    @UserGuid uniqueidentifier,
    @GroupGuid uniqueidentifier,
    @ProjectTypeId int,
    @SearchString nvarchar(100),
    @Purpose nvarchar(10)
as
    declare @IsGlobal bit
    declare @BusinessUnitGUID uniqueidentifier

    SELECT	@BusinessUnitGUID = Business_Unit_GUID
    FROM	Intelledox_User
    WHERE	User_Guid = @UserGuid;

    IF EXISTS(SELECT	vwUserPermissions.*
        FROM	vwUserPermissions
        WHERE	((@Purpose = 'Design' AND vwUserPermissions.CanDesignProjects = 1)
                    OR (@Purpose = 'Publish' AND vwUserPermissions.CanPublishProjects = 1))
                AND vwUserPermissions.GroupGuid IS NULL
                AND vwUserPermissions.UserGuid = @UserGuid)
    BEGIN
        SET @IsGlobal = 1;
    END

    if @GroupGuid IS NULL
    begin
        --all usergroups
        SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
                a.template_guid, a.template_version, a.import_date, 
                a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
                a.Content_Bookmark
        FROM	Template a
            LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
        WHERE	(@IsGlobal = 1 or a.Template_Guid in (
                SELECT	User_Group_Template.TemplateGuid
                FROM	vwUserPermissions
                        INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
                        INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
                        INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
                        INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid
                WHERE	((@Purpose = 'Design' AND vwUserPermissions.CanDesignProjects = 1)
                    OR (@Purpose = 'Publish' AND vwUserPermissions.CanPublishProjects = 1))
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
                a.template_guid, a.template_version, a.import_date, 
                a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
                a.Content_Bookmark
        FROM	Template a
                INNER JOIN User_Group_Template d on a.Template_Guid = d.TemplateGuid
                INNER JOIN User_Group ON d.GroupGuid = User_Group.Group_Guid AND User_Group.Group_Guid = @GroupGuid
                LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
        WHERE	(@IsGlobal = 1 or a.template_Guid in (
                SELECT	User_Group_Template.TemplateGuid
                FROM	vwUserPermissions
                        INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
                        INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
                        INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
                        INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid
                WHERE	((@Purpose = 'Design' AND vwUserPermissions.CanDesignProjects = 1)
                    OR (@Purpose = 'Publish' AND vwUserPermissions.CanPublishProjects = 1))
            ))
            and (a.Business_Unit_GUID = @BusinessUnitGUID) 
            AND a.Name LIKE @SearchString + '%'
            AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
        ORDER BY a.[name];
    end
GO
ALTER procedure [dbo].[spProject_ProjectListFullText]
    @UserGuid uniqueidentifier,
    @GroupGuid uniqueidentifier,
    @ProjectTypeId int,
    @SearchString nvarchar(100),
    @FullText NVarChar(1000)
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
                a.template_guid, a.template_version, a.import_date, 
                a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
                a.Content_Bookmark
        FROM	Template a
                LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
        WHERE	(@IsGlobal = 1 or a.template_Guid in (
                SELECT	User_Group_Template.TemplateGuid
                FROM	vwUserPermissions
                        INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
                        INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
                        INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
                        INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid 
                WHERE	vwUserPermissions.CanDesignProjects = 1
            AND Intelledox_User.User_Guid = @UserGuid
                ))
            AND (a.Business_Unit_GUID = @BusinessUnitGUID) 
            AND a.Name LIKE @SearchString + '%'
            AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
            AND (a.Template_Guid IN (
                    SELECT	Template_Guid
                    FROM	Template_File tf
                    WHERE	Contains(*, @FullText)
                ))
        ORDER BY a.[name];
    end
    else
    begin
        --specific user group
        SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
                a.template_guid, a.template_version, a.import_date, 
                a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
                a.Content_Bookmark
        FROM	Template a
                INNER JOIN User_Group_Template d on a.Template_Guid = d.TemplateGuid
                INNER JOIN User_Group ON d.GroupGuid = User_Group.Group_Guid  AND User_Group.Group_Guid = @GroupGuid
                LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
        WHERE	(@IsGlobal = 1 or a.template_Guid in (
                SELECT	User_Group_Template.TemplateGuid
                FROM	vwUserPermissions
                        INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
                        INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
                        INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
                        INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid 
                WHERE	vwUserPermissions.CanDesignProjects = 1
            ))
            and (a.Business_Unit_GUID = @BusinessUnitGUID) 
            AND a.Name LIKE @SearchString + '%'
            AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
            AND (a.Template_Guid IN (
                    SELECT	Template_Guid
                    FROM	Template_File tf
                    WHERE	Contains(*, @FullText)
                ))
        ORDER BY a.[name];
    end
GO
DROP procedure [dbo].[spTemplate_TemplateListByFilter]
GO
ALTER PROCEDURE [dbo].[spTemplate_TemplateSubscribeGroup]
    @TemplateGuid uniqueidentifier,
    @UserGroupGuid uniqueidentifier
AS
    DECLARE @Subscribed int
    
    SELECT	@Subscribed = COUNT(*)
    FROM	User_group_template
    WHERE	TemplateGuid = @TemplateGuid
        AND GroupGuid = @UserGroupGuid
    
    IF @Subscribed = 0
    BEGIN
        INSERT INTO user_Group_template (GroupGuid, TemplateGuid)
        VALUES (@UserGroupGuid, @TemplateGuid);
    END
GO

--2014
ALTER PROCEDURE [dbo].[spTemplate_TemplateUnsubscribeGroup]
    @TemplateGuid uniqueidentifier,
    @UserGroupGuid uniqueidentifier,
    @UnsubscribeAll bit
AS	
    IF @UnsubscribeAll = 1
    BEGIN
        DELETE	User_group_template
        WHERE	TemplateGuid = @TemplateGuid;
    END
    ELSE
    BEGIN
        DELETE	User_Group_template
        WHERE	TemplateGuid = @TemplateGuid
                AND GroupGuid = @UserGroupGuid;
    END
GO
ALTER PROCEDURE [dbo].[spTemplate_TemplateUserGroups]
    @TemplateID int,
    @ErrorCode int output
AS
    select	b.* 
    from	user_group_template a
            inner join user_group b on a.GroupGuid = b.Group_Guid
            inner join Template t on a.TemplateGuid = t.Template_Guid
    where	t.Template_Id = @TemplateID
    order by b.[name];
GO
DROP PROCEDURE spTemplateGrp_SubscribeUserGroupTemplate
GO
DROP PROCEDURE spTemplateGrp_TemplateGroupList
GO
DROP procedure [dbo].[spTemplateGrp_TemplateGroupUserGroups]
GO
DROP PROCEDURE spTemplateGrp_UnsubscribeUserGroupTemplate
GO
ALTER PROCEDURE [dbo].[spTenant_ProvisionTenant] (
    @BusinessUnitGuid uniqueidentifier,
    @TenantName nvarchar(200),
    @FirstName nvarchar(200),
    @LastName nvarchar(200),
    @UserName nvarchar(50),
    @UserPasswordHash varchar(100),
    @SubscriptionType int,
    @ExpiryDate datetime,
    @TenantFee money,
    @DefaultLanguage nvarchar(10),
    @UserFee money
)
AS
    DECLARE @UserGuid uniqueidentifier
    DECLARE @TemplateBusinessUnit uniqueidentifier
    DECLARE @TemplateUser uniqueidentifier

    SET @UserGuid = NewID()

    SELECT	@TemplateBusinessUnit = Business_Unit_Guid
    FROM	Business_Unit
    WHERE	Name = 'SaaSTemplate'

    SELECT	@TemplateUser = User_Guid
    FROM	Intelledox_User
    WHERE	UserName = 'SaaSTemplate'

    --New business unit (Company in SaaS)
    INSERT INTO Business_Unit(Business_Unit_Guid, Name, SubscriptionType, ExpiryDate, TenantFee, DefaultLanguage, UserFee)
    VALUES (@BusinessUnitGuid, @TenantName, @SubscriptionType, @ExpiryDate, @TenantFee, @DefaultLanguage, @UserFee)

    --Roles
    INSERT INTO Administrator_Level(AdminLevel_Description, RoleGuid, Business_Unit_Guid)
    SELECT	AdminLevel_Description, newid(), @BusinessUnitGuid
    FROM	Administrator_Level
    WHERE	Business_Unit_Guid = @TemplateBusinessUnit

    --Role Permissions
    INSERT INTO Role_Permission(PermissionGuid, RoleGuid)
    SELECT	Role_Permission.PermissionGuid, NewRole.RoleGuid
    FROM	Role_Permission
            INNER JOIN Administrator_Level ON Administrator_Level.RoleGuid = Role_Permission.RoleGuid
            INNER JOIN Administrator_Level NewRole ON Administrator_Level.AdminLevel_Description = NewRole.AdminLevel_Description
    WHERE	Administrator_Level.Business_Unit_Guid = @TemplateBusinessUnit
            AND NewRole.Business_Unit_Guid = @BusinessUnitGuid

    --Groups
    INSERT INTO User_Group(Name, WinNT_Group, Business_Unit_Guid, Group_Guid, AutoAssignment, SystemGroup)
    SELECT	Name, WinNT_Group, @BusinessUnitGuid, NewID(), AutoAssignment, SystemGroup
    FROM	User_Group
    WHERE	Business_Unit_Guid = @TemplateBusinessUnit

    --User Address
    INSERT INTO address_book (full_name, first_name, last_name, email_address)
    VALUES (@FirstName + ' ' + @LastName, @FirstName, @LastName, @UserName)
    
    --User
    INSERT INTO Intelledox_User(Username, Pwdhash, WinNT_User, Business_Unit_Guid, User_Guid, Address_ID)
    VALUES (@UserName, @UserPasswordHash, 0, @BusinessUnitGuid, @UserGuid, @@IDENTITY)

    --User Permissions
    INSERT INTO User_Role(UserGuid, RoleGuid, GroupGuid)
    SELECT	@UserGuid, NewRole.RoleGuid, NULL
    FROM	User_Role
            INNER JOIN Administrator_Level ON Administrator_Level.RoleGuid = User_Role.RoleGuid
            INNER JOIN Administrator_Level NewRole ON Administrator_Level.AdminLevel_Description = NewRole.AdminLevel_Description
    WHERE	Administrator_Level.Business_Unit_Guid = @TemplateBusinessUnit
            AND NewRole.Business_Unit_Guid = @BusinessUnitGuid
            AND User_Role.UserGuid = @TemplateUser

    --User Groups
    INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
    SELECT	NewUser.User_Guid, NewGroup.Group_Guid, User_Group_Subscription.IsDefaultGroup
    FROM	User_Group_Subscription
            INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
            INNER JOIN User_Group ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
            INNER JOIN User_Group NewGroup ON User_Group.Name = NewGroup.Name
            , Intelledox_User NewUser
    WHERE	Intelledox_User.User_Guid = @TemplateUser
            AND NewUser.User_Guid = @UserGuid
            AND NewGroup.Business_Unit_Guid = @BusinessUnitGuid
GO
ALTER procedure [dbo].[spUsers_DefaultUserGroup]
    @UserGuid uniqueidentifier = null
AS
    SELECT	b.User_Group_Id, b.Group_Guid
    FROM	Intelledox_User IxUser
            INNER JOIN	User_Group_Subscription c on IxUser.User_Guid = c.UserGuid
            INNER JOIN	User_Group b on c.GroupGuid = b.Group_Guid
    WHERE	c.IsDefaultGroup = 1
            AND (IxUser.User_Guid = @UserGuid);
GO
ALTER procedure [dbo].[spUsers_SubscribeUserGroup]
    @UserGroupID int,
    @UserID int,
    @Default bit,
    @ErrorCode int = 0 output
as
    declare @SubscriptionCount int
    DECLARE @UserGuid uniqueidentifier
    DECLARE @GroupGuid uniqueidentifier
    
    SET NOCOUNT ON
    
    SELECT	@UserGuid = User_Guid
    FROM	Intelledox_User
    WHERE	[User_ID] = @UserID;
    
    SELECT	@GroupGuid = Group_Guid
    FROM	User_Group
    WHERE	User_Group_ID = @UserGroupID;
    
    select	@SubscriptionCount = COUNT(*)
    from	User_Group_Subscription
    where	GroupGuid = @GroupGuid
            AND UserGuid = @UserGuid;

    --Enforce single default group
    if @Default <> 0
    begin
        update	user_group_subscription
        SET		IsDefaultGroup = 0
        where	UserGuid = @UserGuid
    end
    else
    begin
        if (select count(*) from user_group_subscription where IsDefaultGroup = 1 and UserGuid = @UserGuid) = 0
            set @Default = 1;
    end

    if @SubscriptionCount = 0
    begin
        INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
        VALUES (@UserGuid, @GroupGuid, @Default);
    end

    set @ErrorCode = @@error;
GO
DROP PROCEDURE spUsers_UnsubscribeAll
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
            
    -- Remove any roles we have in this group
    DELETE FROM	User_Role
    WHERE	UserGuid = @UserGuid
            AND GroupGuid = @GroupGuid;

    -- Remove group from user
    DELETE FROM User_Group_Subscription
    WHERE	GroupGuid = @GroupGuid
            AND UserGuid = @UserGuid;

    IF @Default <> 0
    begin
        update	user_group_subscription
        SET		IsDefaultGroup = 1
        from	user_group_subscription
                inner join (
                    select top 1 GroupGuid from user_group_subscription where UserGuid = @UserGuid
                ) ugs on user_group_subscription.GroupGuid = ugs.GroupGuid and user_group_subscription.UserGuid = @UserGuid;
    end

    set @ErrorCode = @@error;
GO
ALTER procedure [dbo].[spUsers_updateUser]
    @UserID int,
    @Username nvarchar(50),
    @Password nvarchar(1000),
    @NewID int = 0 output,
    @WinNT_User bit,
    @BusinessUnitGUID uniqueidentifier,
    @User_GUID uniqueidentifier,
    @SelectedTheme nvarchar(100),
    @ChangePassword int,
    @PasswordSalt nvarchar(128),
    @PasswordFormat int,
    @Disabled int,
    @Address_Id int,
    @ErrorCode int = 0 output
as
    if @UserID = 0 OR @UserID IS NULL
    begin
        INSERT INTO Intelledox_User(Username, PwdHash, WinNT_User, Business_Unit_GUID, User_Guid, SelectedTheme, 
                ChangePassword, PwdSalt, PwdFormat, [Disabled], Address_ID)
        VALUES (@Username, @Password, @WinNT_User, @BusinessUnitGUID, @User_Guid, @SelectedTheme, 
                @ChangePassword, @PasswordSalt, @PasswordFormat, @Disabled, @Address_Id);
        
        select @NewID = @@identity;

        INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
        SELECT	@User_Guid, User_Group.Group_Guid, 0
        FROM	User_Group
        WHERE	User_Group.AutoAssignment = 1;
    end
    else
    begin
        UPDATE Intelledox_User
        SET Username = @Username,  
            PwdHash = @Password, 
            WinNT_User = @WinNT_User,
            SelectedTheme = @SelectedTheme,
            ChangePassword = @ChangePassword,
            PwdSalt = @PasswordSalt,
            PwdFormat = @PasswordFormat,
            [Disabled] = @Disabled
        WHERE [User_ID] = @UserID;
    end

    set @ErrorCode = @@error;
GO
ALTER procedure [dbo].[spUsers_UserGroupUsers]
    @UserGroupID int,
    @ErrorCode int = 0 output
as
    if @UserGroupID = 0
    begin
        --all users without active user groups

        select	a.*,
            b.Full_Name,
            0 as IsDefaultGroup
        from	Intelledox_User a
            left join Address_Book b on a.Address_ID = b.Address_ID
        where	a.User_Guid not in (
                select a.UserGuid
                from user_group_subscription a 
                    inner join user_Group b on a.GroupGuid = b.Group_Guid
            )
    end
    else
    begin
        select	a.*,
            b.Full_Name,
            c.IsDefaultGroup
        from	Intelledox_User a
            left join Address_Book b on a.Address_ID = b.Address_ID
            inner join User_Group_Subscription c on a.User_Guid = c.UserGuid
            inner join user_Group d on c.GroupGuid = d.Group_Guid
        where	d.User_Group_ID = @UserGroupID
    end

    set @ErrorCode = @@error
GO
ALTER procedure [dbo].[spUsers_UserLogin]
    @Username nvarchar(50),
    @Password nvarchar(1000),
    @Secured bit = 1,
    @SingleUser bit = 0, 
    @Authenticated int = 0 output,
    @ErrorCode int = 0 output
as
    declare @ValidateCount int,
        @UserID int,
        @Business_Unit_GUID uniqueidentifier
    
    if @Secured = 0
    begin
        select @ValidateCount = COUNT(*)
        from Intelledox_User
        where lower(Username) = lower(@Username)

        set @Authenticated = 1
    end
    else
    begin
        select @ValidateCount = COUNT(*)
        from Intelledox_User
        where lower(Username) = lower(@Username)
        AND pwdhash = @Password
        set @Authenticated = 2
    end

    if @ValidateCount = 0
    begin
        set @Authenticated = -1
        select a.*, b.*, '' as DefaultLanguage
        from Intelledox_User a, Address_Book b
        where a.[User_ID] is null
    end
    else
    begin
        select @ValidateCount = COUNT(*)
        from Intelledox_User a, Address_Book b
        where lower(a.Username) = lower(@Username)
            AND a.Address_ID = b.Address_ID

        if @ValidateCount = 0	--if address record doesn't exist, create one
        begin
            select @UserID = [user_id] from Intelledox_User where lower(username) = lower(@Username)

            INSERT INTO address_book (full_name)
            VALUES (@Username)
            
            UPDATE	Intelledox_User
            SET		Address_ID = @@IDENTITY
            WHERE	USER_ID = @UserID;
        end

        select a.*, b.*, Business_Unit.DefaultLanguage
        from Intelledox_User a
            left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
            , Address_Book b
        where lower(a.Username) = lower(@Username)
            AND a.Address_ID = b.Address_ID
    end

    set @ErrorCode = @@error
GO
ALTER procedure [dbo].[spUsers_RemoveUser]
    @UserGuid uniqueidentifier
AS
    DECLARE @UserId int;
    DECLARE @AddressId int;
    
    SELECT	@UserId = [User_Id], @AddressId = Address_ID
    FROM	Intelledox_User
    WHERE	User_Guid = @UserGuid;
    
    DELETE	Address_Book WHERE Address_ID = @AddressId;
    DELETE	User_Address_Book WHERE [User_Id] = @UserId;
    DELETE	User_Group_Subscription WHERE UserGuid = @UserGuid;
    DELETE	User_Signoff WHERE [User_Id] = @UserId;
    DELETE	Intelledox_User WHERE User_Guid = @UserGuid;
GO
ALTER PROCEDURE [dbo].[spReport_UsageDataTopUsers] (
    @StartDate datetime,
    @FinishDate datetime,
    @BusinessUnitGuid uniqueidentifier
)
AS
    
    SELECT TOP 10 Intelledox_User.Username,
        COUNT(*) AS NumRuns,
        Address_Book.Full_Name
    FROM Template_Log 
        INNER JOIN Intelledox_User ON Intelledox_User.User_ID = Template_Log.User_ID
        LEFT JOIN Address_Book ON Address_Book.Address_id = Intelledox_User.Address_Id
    WHERE Template_Log.DateTime_Finish IS NOT NULL
        AND Template_Log.DateTime_Finish >= @StartDate
        AND Template_Log.DateTime_Finish <= @FinishDate + 1
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
    GROUP BY Template_Log.User_ID,
        Intelledox_User.Username,
        Address_Book.Full_Name
    ORDER BY NumRuns DESC;
GO
ALTER procedure [dbo].[spAddBk_UserGroupAddress]
    @UserGroupID int,
    @ErrorCode int = 0 output
AS
    SELECT	Address_Book.*
    FROM	Address_Book
            INNER JOIN User_Group ug ON Address_Book.Address_Id = ug.Address_Id
    WHERE	ug.User_Group_ID = @UserGroupID;

    set @errorcode = @@error;
GO
ALTER procedure [dbo].[spAddBk_UserAddressList]
    @UserID int,
    @ErrorCode int = 0 output
AS
    SELECT	a.*
    FROM	Address_Book a,
            User_Address_Book b
    WHERE	b.[User_ID] = @UserID
            AND	a.Address_ID = b.Address_ID
    order by a.Last_Name, a.First_Name, a.Prefix, a.Organisation_Name;

    set @errorcode = @@error;
GO
ALTER procedure [dbo].[spAddBk_UserAddress]
    @UserID int,
    @ErrorCode int = 0 output
AS
    SELECT	Address_Book.*
    FROM	Address_Book
            INNER JOIN Intelledox_User u ON Address_Book.Address_Id = u.Address_Id
    WHERE	u.[User_ID] = @UserID;

    set @ErrorCode = @@error;
GO
DROP PROCEDURE spAddBk_UpdateUserAddress
GO
ALTER procedure [dbo].[spAddBk_UpdateAddress]
    @AddressID int,
    @AddressTypeID int,
    @Reference nvarchar(50),
    @Prefix nvarchar(50),
    @Title nvarchar(50),
    @FullName nvarchar(100),
    @FirstName nvarchar(50),
    @LastName nvarchar(50),
    @Salutation nvarchar(50),
    @Organisation nvarchar(100),
    @EmailAddress nvarchar(50),
    @FaxNumber nvarchar(50),
    @PhoneNumber nvarchar(50),
    @StreetAddress1 nvarchar(50),
    @StreetAddress2 nvarchar(50),
    @StreetSuburb nvarchar(50),
    @StreetState nvarchar(50),
    @StreetPostcode nvarchar(50),
    @StreetCountry nvarchar(50),
    @PostalAddress1 nvarchar(50),
    @PostalAddress2 nvarchar(50),
    @PostalSuburb nvarchar(50),
    @PostalState nvarchar(50),
    @PostalPostcode nvarchar(50),
    @PostalCountry nvarchar(50),
    @SubscribeUser int,
    @NewID int = 0 output,
    @ErrorCode int = 0 output
AS
    --This may be an insert or an update, depending on AddressID.
    IF @AddressID = 0
    begin
        INSERT INTO Address_Book (addresstype_id, address_reference,
            prefix, first_name, last_name, full_name, salutation_name, title,
            organisation_name, phone_number, fax_number, email_address,
            street_address_1, street_address_2, street_address_suburb, street_address_state,
            street_address_postcode, street_address_country, postal_address_1, postal_address_2,
            postal_address_suburb, postal_address_state, postal_address_postcode, postal_address_country)
        VALUES (@AddressTypeID, @Reference,
            @Prefix, @FirstName, @LastName, @FullName, @Salutation, @Title,
            @Organisation, @PhoneNumber, @FaxNumber, @EmailAddress,
            @StreetAddress1, @StreetAddress2, @StreetSuburb, @StreetState,
            @StreetPostcode, @StreetCountry, @PostalAddress1, @PostalAddress2,
            @PostalSuburb, @PostalState, @PostalPostcode, @PostalCountry);

        SELECT @NewID = @@Identity;
        SET @AddressID = @NewID;
    end
    ELSE
    begin
        UPDATE Address_Book
        SET Addresstype_ID = @AddressTypeID,
            Address_Reference = @Reference, Prefix = @Prefix, First_Name = @FirstName,
            Last_Name = @LastName, Full_Name = @FullName, Salutation_Name = @Salutation,
            Title = @Title, Organisation_Name = @Organisation, Phone_number = @PhoneNumber,
            Fax_number = @FaxNumber, Email_Address = @EmailAddress,
            Street_Address_1 = @StreetAddress1, Street_Address_2 = @StreetAddress2,
            Street_Address_Suburb = @StreetSuburb, Street_Address_State = @StreetState,
            Street_Address_Postcode = @StreetPostcode, Street_Address_Country = @StreetCountry,
            Postal_Address_1 = @PostalAddress1, Postal_Address_2 = @PostalAddress2,
            Postal_Address_Suburb = @PostalSuburb, Postal_Address_State = @PostalState,
            Postal_Address_Postcode = @PostalPostcode, Postal_Address_Country = @PostalCountry
        WHERE Address_ID = @AddressID;
    end
        
    IF (@SubscribeUser > 0) AND (@SubscribeUser IS NOT NULL)
        exec spAddBk_SubscribeUserAddress @SubscribeUser, @AddressID, @ErrorCode output;

    set @errorcode = @@error;
GO
DROP PROCEDURE spAddBk_UnsubscribeUserAddress
GO
DROP PROCEDURE spAddBk_UnsubscribeAllUserAddresses
GO
ALTER procedure [dbo].[spAddBk_AddressList]
    @AddressID int = 0,
    @ErrorCode int = 0 output
AS
    SELECT *
    FROM Address_Book
    WHERE (@AddressID = 0
        OR @AddressID IS NULL
        OR Address_ID = @AddressID);

    set @errorcode = @@error;
GO
ALTER procedure [dbo].[spBU_ProvisionTenant] (
    @BusinessUnitGuid uniqueidentifier,
    @TenantName nvarchar(200),
    @UserType int, -- 0 = normal user, 1 = admin, 2 = global admin (site owner)
    @FirstName nvarchar(200),
    @LastName nvarchar(200),
    @UserName nvarchar(50),
    @UserPasswordHash varchar(100),
    @UserPasswordSalt nvarchar(128),
    @SubscriptionType int = 1,
    @ExpiryDate datetime = null, --ExpiryDate is required if SubscriptionType is "1".
    @DefaultLanguage nvarchar(10) = null, --Leave null for default.
    @UserEmail nvarchar(200) = null
)
AS
    DECLARE @UserGuid uniqueidentifier
    DECLARE @TemplateBusinessUnit uniqueidentifier

    SET @UserGuid = NewID()

    SELECT	@TemplateBusinessUnit = Business_Unit_Guid
    FROM	Business_Unit
    WHERE	Name = 'Default'

    IF (select count(*) from business_unit where Business_Unit_Guid = @BusinessUnitGuid) = 0
    begin

        IF (@DefaultLanguage is null or @DefaultLanguage = '')
        begin
            if (select count(*) from Business_Unit where name = 'Default') = 1
                select top 1 @DefaultLanguage = DefaultLanguage from Business_Unit where Name = 'Default';
            else
                set @DefaultLanguage = 'en-AU';
        end

        --New business unit
        INSERT INTO Business_Unit(Business_Unit_Guid, Name, SubscriptionType, ExpiryDate, TenantFee, DefaultLanguage, UserFee)
        VALUES (@BusinessUnitGuid, @TenantName, @SubscriptionType, @ExpiryDate, 0, @DefaultLanguage, 0);
    end
    

    declare @FullAdminRoleGuid uniqueidentifier,
            @AdminRoleGuid uniqueidentifier,
            @UserRoleGuid uniqueidentifier
    
    --Roles
    IF (select count(*) from Administrator_Level where Business_Unit_Guid = @BusinessUnitGuid) = 0
    begin
        set @FullAdminRoleGuid = newid();
        set @AdminRoleGuid = newid();
        set @UserRoleGuid = newid();
        
        insert into Administrator_Level (AdminLevel_Description, RoleGuid, Business_Unit_Guid)
        values (substring(@TenantName, 0, 36) + ' Global Admin', @FullAdminRoleGuid, @BusinessUnitGuid);
        
        insert into Administrator_Level (AdminLevel_Description, RoleGuid, Business_Unit_Guid)
        values (substring(@TenantName, 0, 36) + ' Administrator', @AdminRoleGuid, @BusinessUnitGuid);
        
        insert into Administrator_Level (AdminLevel_Description, RoleGuid, Business_Unit_Guid)
        values (substring(@TenantName, 0, 36) + ' User', @UserRoleGuid, @BusinessUnitGuid);
        
        --Role Permissions
        
        --full admin
        insert into Role_Permission (PermissionGuid, RoleGuid)
        select Permission.PermissionGuid, @FullAdminRoleGuid
        from Permission;
        --admin
        insert into Role_Permission (PermissionGuid, RoleGuid) values (cast('CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' as uniqueidentifier), @AdminRoleGuid);
        insert into Role_Permission (PermissionGuid, RoleGuid) values (cast('6B96BAF3-8A76-4F42-B1E7-DF87142444E0' as uniqueidentifier), @AdminRoleGuid);
        insert into Role_Permission (PermissionGuid, RoleGuid) values (cast('FA2C7769-6D15-442E-9F7F-E8CE82590D8D' as uniqueidentifier), @AdminRoleGuid);
    end
    else
    begin
        select @FullAdminRoleGuid = RoleGuid from Administrator_Level where AdminLevel_Description like '%Global Admin' and Business_Unit_Guid = @BusinessUnitGuid;
        select @AdminRoleGuid = RoleGuid from Administrator_Level where AdminLevel_Description like '%Administrator' and Business_Unit_Guid = @BusinessUnitGuid;
        select @UserRoleGuid = RoleGuid from Administrator_Level where AdminLevel_Description like '%User' and Business_Unit_Guid = @BusinessUnitGuid;
    end
    
    --Groups
    IF (select count(*) from User_Group where Business_Unit_Guid = @BusinessUnitGuid) = 0
    begin
        declare @UG uniqueidentifier
        set @UG = newid()
        
        INSERT INTO User_Group(Name, WinNT_Group, Business_Unit_Guid, Group_Guid, AutoAssignment, SystemGroup)
        SELECT	@TenantName + ' Users', WinNT_Group, @BusinessUnitGuid, @UG, AutoAssignment, SystemGroup
        FROM	User_Group
        WHERE	Name = 'Intelledox Users' and SystemGroup = 1;
    end
    
    --User Address
    INSERT INTO address_book (full_name, first_name, last_name, email_address)
    VALUES (@FirstName + ' ' + @LastName, @FirstName, @LastName, @UserEmail)
    
    --User
    INSERT INTO Intelledox_User(Username, Pwdhash, WinNT_User, Business_Unit_Guid, User_Guid, PwdFormat, PwdSalt, Address_ID)
    VALUES (@UserName, @UserPasswordHash, 0, @BusinessUnitGuid, @UserGuid, 2, @UserPasswordSalt, @@IDENTITY)


    --User Permissions
    declare @UserRole uniqueidentifier;
    if @UserType = 0
        set @UserRole = @UserRoleGuid;
    else
        if @UserType = 1
            set @UserRole = @AdminRoleGuid;
        else
            set @UserRole = @FullAdminRoleGuid;
    
    insert into user_role (UserGuid, RoleGuid, GroupGuid)
    values (@UserGuid, @UserRole, NULL);
    
    --User Group subscription
    declare @GroupGuid uniqueidentifier
            
    select @GroupGuid = Group_Guid from user_group where business_unit_guid = @BusinessUnitGuid;
    
    INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
    values (@UserGuid, @GroupGuid, 1);
GO
ALTER procedure [dbo].[spTemplate_RemoveTemplate]
    @TemplateGuid uniqueidentifier,
    @OnlyChildInfo bit
as
    DECLARE @TemplateId Int

    SELECT	@TemplateId = Template_Id
    FROM	Template
    WHERE	Template_Guid = @TemplateGuid;

    IF @OnlyChildInfo = 0
    BEGIN
        DELETE	template_Group_item
        WHERE	template_guid = @TemplateGuid
            OR	layout_guid = @TemplateGuid;

        DELETE	template_Group
        WHERE	Template_Group_Guid NOT IN (
            SELECT	Template_Group_Guid
            FROM	Template_Group_Item
        );

        DELETE	Template_Category
        WHERE	Template_ID = @TemplateID;

        DELETE	User_Group_Template
        WHERE	TemplateGuid = @TemplateGuid;
    END
    
    DELETE	Template_File
    WHERE	Template_Guid = @TemplateGuid;
    
    DELETE	Template
    WHERE	Template_Guid = @TemplateGuid;
    
    DELETE	Template_File_Version
    WHERE	Template_Guid = @TemplateGuid;
    
    DELETE	Template_Version
    WHERE	Template_Guid = @TemplateGuid;
GO
ALTER procedure [dbo].[spGetBilling]
AS
    DECLARE @CurrentDate DateTime
    DECLARE @LicenseHolder NVarchar(1000)
    
    SET NOCOUNT ON
    
    SET @CurrentDate = CAST(CONVERT(Varchar(10), GETDATE(), 102) AS DateTime)
    
    SELECT	@LicenseHolder = OptionValue 
    FROM	Global_Options
    WHERE	OptionCode = 'LICENSE_HOLDER'

    SELECT	@LicenseHolder as LicenseHolder, CONVERT(Varchar(10), Template_Log.DateTime_Finish, 102) as ActivityDate, 
            IsNull(Template.Name, '') as ProjectName, COUNT(*) AS DocumentCount
    FROM	Template_Log
            LEFT JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
            LEFT JOIN Template_Group_Item ON Template_Group.Template_Group_Guid = Template_Group_Item.Template_Group_Guid
            LEFT JOIN Template ON Template_Group_Item.Template_Guid = Template.Template_Guid
    WHERE	Template_Log.Completed = 1
            AND Template_Log.DateTime_Finish BETWEEN DATEADD(d, -30, @CurrentDate) AND @CurrentDate
    GROUP BY CONVERT(Varchar(10), Template_Log.DateTime_Finish, 102), IsNull(Template.Name, '')
GO
ALTER procedure [dbo].[spProject_GetFoldersByProject]
    @ProjectGuid uniqueidentifier
AS
    SELECT	Folder.Folder_Name, Folder.Folder_Guid, Template_Group.Template_Group_Guid,
            Template.Template_Type_ID
    FROM	Folder
            INNER JOIN Folder_Template on Folder.Folder_ID = Folder_Template.Folder_ID
            INNER JOIN Template_Group on Folder_Template.FolderItem_ID = Template_Group.Template_Group_ID
            INNER JOIN Template_Group_Item on Template_Group.Template_Group_Guid = Template_Group_Item.Template_Group_Guid
            INNER JOIN Template on Template_Group_Item.Template_Guid = Template.Template_Guid
    WHERE	Template.Template_Guid = @ProjectGuid
    ORDER BY Folder.Folder_Name;
GO
ALTER procedure [dbo].[spProjectGrp_ProjectGroupListByFolder]
    @FolderGuid uniqueidentifier,
    @IncludeRestricted bit
AS
    SELECT	d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
            d.HelpText as TemplateGroup_HelpText, d.Template_Group_Guid,
            b.Template_Guid, e.Layout_Guid
    FROM	Folder a
            INNER JOIN Folder_Template c on a.Folder_ID = c.Folder_ID
            INNER JOIN Template_Group d on c.folderitem_ID = d.Template_Group_ID and itemtype_id = 1
            INNER JOIN Template_Group_Item e on d.Template_Group_Guid = e.Template_Group_Guid
            INNER JOIN Template b on e.Template_Guid = b.Template_Guid
    WHERE	a.Folder_Guid = @FolderGuid
            AND ((d.EnforcePublishPeriod = 0 OR @IncludeRestricted = 1)
                OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getutcdate())
                    AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getutcdate())))
    ORDER BY d.[Name], b.[Name], c.folderitem_id;
GO
ALTER procedure [dbo].[spProjectGrp_SubscribeProjectGroup]
    @ProjectGroupGuid uniqueidentifier,
    @ProjectGuid uniqueidentifier,
    @LayoutGuid uniqueidentifier,
    @ProjectVersion int,
    @LayoutVersion int
AS
    DECLARE @SubscriptionCount int
    
    SELECT	@SubscriptionCount = COUNT(*)
    FROM	Template_Group_Item
    WHERE	Template_Group_Guid = @ProjectGroupGuid
            AND Template_Guid = @ProjectGuid;
    
    IF @SubscriptionCount = 0
    BEGIN
        INSERT INTO Template_Group_Item (template_Group_guid, template_guid, layout_guid, Template_Version, Layout_Version)
        VALUES (@ProjectGroupGuid, @ProjectGuid, @LayoutGuid, @ProjectVersion, @LayoutVersion);
    END
GO
ALTER procedure [dbo].[spTemplateGrp_FolderTemplateList]
    @FolderID int = 0,
    @ErrorCode int output
as
    SELECT	a.*, d.*, b.Template_ID, b.[Name], b.Template_Type_ID
    FROM	Folder a
        inner join Folder_Template c on a.Folder_ID = c.Folder_ID
        inner join Template_Group d on c.folderitem_ID = d.Template_Group_ID and c.itemtype_id = 1
        inner join Template_Group_Item e on d.Template_Group_Guid = e.Template_Group_Guid
        inner join Template b on b.Template_Guid = e.Template_Guid
    WHERE	(@FolderID = 0 OR a.Folder_ID = @FolderID)
    ORDER BY c.Folder_ID, c.folderitem_id
    
    set @ErrorCode = @@error
GO
DROP PROCEDURE spTemplateGrp_GroupTemplateList
GO
DROP PROCEDURE spTemplateGrp_SubscribeTemplateGroup
GO
DROP PROCEDURE spTemplateGrp_TemplateGroupList_Full
GO
DROP PROCEDURE spTemplateGrp_UnsubscribeTemplateGroup
GO
DROP PROCEDURE spTemplateGrp_CategoryTemplateList
GO
DROP PROCEDURE spTemplateGrp_TemplateList
GO
ALTER procedure [dbo].[spUsers_updateUserGroup]
    @GroupGuid uniqueidentifier,
    @Name nvarchar(50),
    @IsWindowsGroup bit,
    @BusinessUnitGUID uniqueidentifier,
    @AddressId int
as
    if NOT EXISTS (SELECT * FROM User_Group WHERE Group_Guid = @GroupGuid)
    begin
        INSERT INTO User_Group ([Name], [WinNT_Group], Business_Unit_GUID, Group_Guid, AutoAssignment, SystemGroup, Address_ID)
        VALUES (@Name, @IsWindowsGroup, @BusinessUnitGUID, @GroupGuid, 0, 0, @AddressId);
    end
    else
    begin
        update	User_Group
        SET		[Name] = @Name, 
                [WinNT_Group] = @IsWindowsGroup,
                Address_ID = @AddressId
        where	Group_Guid = @GroupGuid;
    end
GO
DROP PROCEDURE spTemplateGrp_UpdateTemplateGroup
GO
ALTER procedure [dbo].[spAudit_UpdateAnswerFile]
    @AnswerFile_ID int,
    @User_Guid uniqueidentifier,
    @Template_Group_Guid uniqueidentifier,
    @Description nvarchar(255),
    @RunDate datetime,
    @AnswerString xml,
    @InProgress bit = 0,
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
ALTER procedure [dbo].[spProjectGrp_ProjectGroupList]
      @ProjectGroupGuid uniqueidentifier
AS
    SELECT	a.Template_Group_ID, a.[Name] as Template_Group_Name, a.template_group_guid, 
            a.helptext as TemplateGroup_HelpText, b.template_guid, b.Layout_Guid,
            b.Template_Version, b.Layout_Version, a.AllowPreview, a.PostGenerateText,
            a.UpdateDocumentFields, a.EnforceValidation, a.WizardFinishText, 
            a.EnforcePublishPeriod, a.PublishStartDate, a.PublishFinishDate
    FROM	Template_Group a
            LEFT JOIN Template_Group_Item b on a.template_group_guid = b.template_group_guid
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;
GO
ALTER procedure [dbo].[spProjectGrp_RemoveFolder]
    @FolderGuid uniqueidentifier
AS
    DECLARE @FolderID INT
    
    SET NOCOUNT ON
    
    SELECT	@FolderID = Folder_Id
    FROM	Folder
    WHERE	Folder_Guid = @FolderGuid;
    
    DELETE Template_Group_Item
    WHERE Template_Group_Guid IN (
        SELECT	Template_Group_Guid
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
GO
ALTER procedure [dbo].[spProjectGrp_RemoveProjectGroup]
    @ProjectGroupGuid uniqueidentifier
AS
    -- Remove the group records
    DELETE Folder_Template WHERE ItemType_id = 1 AND FolderItem_ID IN (SELECT Template_Group_Id FROM Template_Group WHERE Template_Group_Guid = @ProjectGroupGuid);
    DELETE Template_Group_Item WHERE Template_Group_Guid = @ProjectGroupGuid;
    DELETE Template_Group WHERE Template_Group_Guid = @ProjectGroupGuid;
GO
ALTER procedure [dbo].[spProjectGrp_Unpublish]
    @ProjectGroupGuid uniqueidentifier,
    @FolderGuid uniqueidentifier
AS
    DELETE Folder_Template 
    WHERE ItemType_id = 1 
        AND FolderItem_ID IN (SELECT Template_Group_Id FROM Template_Group WHERE Template_Group_Guid = @ProjectGroupGuid)
        AND Folder_Id IN (SELECT Folder_Id FROM Folder WHERE Folder_Guid = @FolderGuid);
GO
ALTER procedure [dbo].[spReport_UsageDataMostRunTemplates] (
    @StartDate datetime,
    @FinishDate datetime,
    @BusinessUnitGuid uniqueidentifier
)
AS
    SELECT TOP 10 Template.Template_Guid,
        Template.Name AS TemplateName,
        COUNT(*) AS NumRuns
    FROM Template_Log 
        INNER JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
        INNER JOIN Template_Group_Item ON Template_Group.Template_Group_Guid = Template_Group_Item.Template_Group_Guid
        INNER JOIN Template ON Template.Template_Guid = Template_Group_Item.Template_Guid
        INNER JOIN Intelledox_User ON Intelledox_User.User_ID = Template_Log.User_ID
    WHERE Template_Log.DateTime_Finish IS NOT NULL
        AND Template_Log.DateTime_Finish >= @StartDate
        AND Template_Log.DateTime_Finish <= @FinishDate + 1
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
    GROUP BY Template.Template_Guid,
        Template.Name
    ORDER BY NumRuns DESC;
GO
ALTER procedure [dbo].[spReport_UsageDataTimeTaken] (
    @StartDate datetime,
    @FinishDate datetime,
    @BusinessUnitGuid uniqueidentifier
)
AS
    SELECT TOP 10 Template.Name AS TemplateName,
        AVG(DateDiff(second, Template_Log.DateTime_Start, Template_Log.DateTime_Finish)) AS AvgTimeTaken
    FROM Template_Log 
        INNER JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
        INNER JOIN Template_Group_Item ON Template_Group.Template_Group_Guid = Template_Group_Item.Template_Group_Guid
        INNER JOIN Template ON Template.Template_Guid = Template_Group_Item.Template_Guid
        INNER JOIN Intelledox_User ON Intelledox_User.User_ID = Template_Log.User_ID
    WHERE Template_Log.DateTime_Finish IS NOT NULL
        AND Template_Log.DateTime_Finish >= @StartDate
        AND Template_Log.DateTime_Finish <= @FinishDate + 1
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
    GROUP BY Template.Template_Guid,
        Template.Name
    ORDER BY AVG(DateDiff(second, Template_Log.DateTime_Start, Template_Log.DateTime_Finish)) DESC;
GO
ALTER procedure [dbo].[spTemplateGrp_RemoveFolder]
    @FolderID int,
    @ErrorCode int output
as
    DELETE Template_Group_Item
    WHERE Template_Group_Guid IN (
        SELECT	Template_Group_Guid
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
ALTER procedure [dbo].[spTemplateGrp_RemoveTemplateGroup]
    @TemplateGroupID int,
    @ErrorCode int output
as
    -- Remove the group records
    DELETE Template_Group_Item WHERE Template_Group_Guid = (SELECT Template_Group_Guid FROM Template_Group WHERE Template_Group_ID = @TemplateGroupID);
    DELETE Template_Group WHERE Template_Group_ID = @TemplateGroupID;
    
    set @ErrorCode = @@error;
GO

--2017
ALTER procedure [dbo].[spUsers_UserGroupByUser]
    @UserID int,
    @BusinessUnitGUID uniqueidentifier,
    @Username nvarchar(50) = '',
    @UserGroupID int = 0,
    @UserGuid uniqueidentifier = null,
    @ShowActive int = 0,
    @ErrorCode int = 0 output
as
    if @UserGroupID = 0	--all user groups
    begin
        if @UserGuid is null
        begin
            if @UserID is null or @UserID = 0
            begin
                select	a.*, Business_Unit.DefaultLanguage
                from	Intelledox_User a
                    left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
                where	(@Username = '' OR @Username is null OR a.[Username] like @Username + '%')
                    AND (a.Business_Unit_GUID = @BusinessUnitGUID)
                    AND (@ShowActive = 0 
                        OR (@ShowActive = 1 AND a.[Disabled] = 0)
                        OR (@ShowActive = 2 AND a.[Disabled] = 1))
                ORDER BY a.[Username]
            end
            else
            begin
                select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
                from	Intelledox_User a
                    left join User_Group_Subscription c on a.User_Guid = c.UserGuid
                    left join User_Group b on c.GroupGuid = b.Group_Guid
                    left join Address_Book d on a.Address_Id = d.Address_id
                    left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
                where	(a.[User_ID] = @UserID)
                    AND (@ShowActive = 0 
                        OR (@ShowActive = 1 AND a.[Disabled] = 0)
                        OR (@ShowActive = 2 AND a.[Disabled] = 1))
                ORDER BY a.[Username]
            end
        end
        else
        begin
            select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
            from	Intelledox_User a
                left join User_Group_Subscription c on a.User_Guid = c.UserGuid
                left join User_Group b on c.GroupGuid = b.Group_Guid
                left join Address_Book d on a.Address_Id = d.Address_id
                left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
            where	(User_Guid = @UserGuid)
                AND (@ShowActive = 0 
                    OR (@ShowActive = 1 AND a.[Disabled] = 0)
                    OR (@ShowActive = 2 AND a.[Disabled] = 1))
            ORDER BY a.[Username]
        end
    end
    else
    begin
        if @UserGroupID = -1	--users with no user groups
        begin
            select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
            from	Intelledox_User a
                left join User_Group_Subscription c on a.User_Guid = c.UserGuid
                left join User_Group b on c.GroupGuid = b.Group_Guid
                left join Address_Book d on a.Address_Id = d.Address_id
                left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
            where	(@UserID = 0 OR @UserID IS NULL OR a.[User_ID] = @UserID)
                AND	(@Username = '' OR @Username is null OR a.[Username] like @Username + '%')
                AND	a.User_Guid not in (
                        select a.userGuid
                        from user_group_subscription a 
                        inner join user_Group b on a.GroupGuid = b.Group_Guid
                    )
                AND (@UserID <> 0 OR a.Business_Unit_GUID = @BusinessUnitGUID)
                AND (@ShowActive = 0 
                    OR (@ShowActive = 1 AND a.[Disabled] = 0)
                    OR (@ShowActive = 2 AND a.[Disabled] = 1))
            ORDER BY a.[Username]
        end
        else			--users in specified user group
        begin
            select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
            from	Intelledox_User a
                left join User_Group_Subscription c on a.User_Guid = c.UserGuid
                left join User_Group b on c.GroupGuid = b.Group_Guid
                left join Address_Book d on a.Address_Id = d.Address_id
                left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
            where	(@UserID = 0 OR @UserID IS NULL OR a.[User_ID] = @UserID)
                AND	(@Username = '' OR @Username is null OR a.[Username] like @Username + '%')
                AND	c.GroupGuid = (SELECT Group_Guid FROM User_Group WHERE User_Group_id = @UserGroupID)
                AND (@UserID <> 0 OR a.Business_Unit_GUID = @BusinessUnitGUID)
                AND (@ShowActive = 0 
                    OR (@ShowActive = 1 AND a.[Disabled] = 0)
                    OR (@ShowActive = 2 AND a.[Disabled] = 1))
            ORDER BY a.[Username]
        end
    end

    set @ErrorCode = @@error;
GO

--2018
ALTER TABLE dbo.Template_Group ADD
    HideNavigationPane bit NULL
GO
ALTER TABLE dbo.Template_Group ADD CONSTRAINT
    DF_Template_Group_HideNavigationPane DEFAULT ((0)) FOR HideNavigationPane
GO
UPDATE dbo.Template_Group SET HideNavigationPane = 0 WHERE HideNavigationPane IS NULL
GO
ALTER procedure [dbo].[spProjectGrp_ProjectGroupList]
      @ProjectGroupGuid uniqueidentifier
AS
    SELECT	a.Template_Group_ID, a.[Name] as Template_Group_Name, a.template_group_guid, 
            a.helptext as TemplateGroup_HelpText, b.template_guid, b.Layout_Guid,
            b.Template_Version, b.Layout_Version, a.AllowPreview, a.PostGenerateText,
            a.UpdateDocumentFields, a.EnforceValidation, a.WizardFinishText, 
            a.EnforcePublishPeriod, a.PublishStartDate, a.PublishFinishDate,
            a.HideNavigationPane
    FROM	Template_Group a
            LEFT JOIN Template_Group_Item b on a.template_group_guid = b.template_group_guid
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;
GO
ALTER PROCEDURE [dbo].[spProjectGrp_UpdateProjectGroup]
    @ProjectGroupGuid uniqueidentifier,
    @Name nvarchar(100),
    @HelpText nvarchar(4000),
    @AllowPreview bit,
    @WizardFinishText nvarchar(max),
    @PostGenerateText nvarchar(4000),
    @UpdateDocumentFields bit,
    @EnforceValidation bit,
    @HideNavigationPane bit,
    @EnforcePublishPeriod bit,
    @PublishStartDate datetime,
    @PublishFinishDate datetime
AS
    IF NOT EXISTS(SELECT * FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid)
    BEGIN
        INSERT INTO Template_Group ([name], template_group_guid, helptext, AllowPreview, PostGenerateText, 
                UpdateDocumentFields, EnforceValidation, WizardFinishText, EnforcePublishPeriod,
                PublishStartDate, PublishFinishDate, HideNavigationPane)
        VALUES (@Name, @ProjectGroupGuid, @HelpText, @AllowPreview, @PostGenerateText, 
                @UpdateDocumentFields, @EnforceValidation, @WizardFinishText, @EnforcePublishPeriod,
                @PublishStartDate, @PublishFinishDate, @HideNavigationPane);
    END
    ELSE
    BEGIN
        UPDATE	Template_Group
        SET		[Name] = @Name,
                HelpText = @HelpText,
                AllowPreview = @AllowPreview,
                PostGenerateText = @PostGenerateText,
                UpdateDocumentFields = @UpdateDocumentFields,
                EnforceValidation = @EnforceValidation,
                WizardFinishText = @WizardFinishText,
                EnforcePublishPeriod = @EnforcePublishPeriod,
                PublishStartDate = @PublishStartDate,
                PublishFinishDate = @PublishFinishDate,
                HideNavigationPane = @HideNavigationPane
        WHERE	Template_Group_Guid = @ProjectGroupGuid;
    END
GO

--2019
ALTER procedure [dbo].[spProjectGrp_ProjectGroupList]
      @ProjectGroupGuid uniqueidentifier
AS
    SELECT	a.Template_Group_ID, t.[Name] as Template_Group_Name, a.template_group_guid, 
            a.helptext as TemplateGroup_HelpText, b.template_guid, b.Layout_Guid,
            b.Template_Version, b.Layout_Version, a.AllowPreview, a.PostGenerateText,
            a.UpdateDocumentFields, a.EnforceValidation, a.WizardFinishText, 
            a.EnforcePublishPeriod, a.PublishStartDate, a.PublishFinishDate,
            a.HideNavigationPane
    FROM	Template_Group a
            INNER JOIN Template_Group_Item b on a.template_group_guid = b.template_group_guid
            INNER JOIN Template t on b.Template_Guid = t.Template_Guid
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;
GO


--2021
CREATE TABLE dbo.ActionList
    (
    ActionListId uniqueidentifier NOT NULL,
    ProjectGroupGuid uniqueidentifier NOT NULL,
    CreatorGuid uniqueidentifier NOT NULL,
    DateCreatedUtc datetime NOT NULL
    )
GO
ALTER TABLE dbo.ActionList ADD CONSTRAINT
    PK_ActionList PRIMARY KEY CLUSTERED 
    (
    ActionListId
    )
GO
CREATE TABLE dbo.ActionListState
    (
    ActionListStateId uniqueidentifier NOT NULL,
    ActionListId uniqueidentifier NOT NULL,
    StateGuid uniqueidentifier NOT NULL,
    StateName nvarchar(200) NOT NULL,
    PreviousActionListStateId uniqueidentifier NULL,
    Comment ntext NULL,
    AnswerFileXml xml NULL,
    AssignedGuid uniqueidentifier NOT NULL,
    AssignedType int NOT NULL,
    DateCreatedUtc datetime NOT NULL,
    DateUpdatedUtc datetime NULL
    )
GO
CREATE INDEX FK_WorkflowState_AssignedGuid
ON dbo.ActionListState(AssignedGuid)
GO

--2022
ALTER TABLE ActionListState
    ALTER COLUMN Comment nvarchar(max) null;
GO
ALTER TABLE ActionListState
    Add AssignedByGuid uniqueidentifier null;
GO
-- Share_Resources
ALTER TABLE [dbo].[Template_Group] 
    DROP CONSTRAINT DF__Template___Share__37A5467C;
GO
-- Fixed_Subscription
ALTER TABLE [dbo].[Template_Group] 
    DROP CONSTRAINT DF__Template___Fixed__36B12243
GO
ALTER TABLE [Template_Group]
    DROP COLUMN Share_Resources;
GO
ALTER TABLE [Template_Group]
    DROP COLUMN Fixed_Subscription;
GO
ALTER TABLE [Template_Group]
    DROP COLUMN Rating_ID;
GO
DROP INDEX IX_Template_Group_Fax ON dbo.Template_Group;
GO
ALTER TABLE [Template_Group]
    DROP COLUMN Fax_Template_Group_ID;
GO
ALTER TABLE [Template_Group]
    DROP COLUMN Fax_Template_Group_Guid;
GO
ALTER TABLE [Template_Group]
    ALTER COLUMN HelpText nvarchar(max) NULL;
GO
ALTER TABLE [Template_Group]
    ALTER COLUMN [PostGenerateText] nvarchar(max) NULL;
GO

UPDATE	[Template_Group]
SET		[AllowPreview] = 0
WHERE	[AllowPreview] IS NULL;
GO
UPDATE	[Template_Group]
SET		UpdateDocumentFields = 0
WHERE	UpdateDocumentFields IS NULL;
GO
UPDATE	[Template_Group]
SET		EnforceValidation = 0
WHERE	EnforceValidation IS NULL;
GO
UPDATE	[Template_Group]
SET		EnforcePublishPeriod = 0
WHERE	EnforcePublishPeriod IS NULL;
GO
UPDATE	[Template_Group]
SET		HideNavigationPane = 0
WHERE	HideNavigationPane IS NULL;
GO
UPDATE	[Template_Group]
SET		Template_Group_Guid = newid()
WHERE	Template_Group_Guid IS NULL;
GO
ALTER TABLE [dbo].[Template_Group] 
    ADD  CONSTRAINT [DF_Template_Group_EnforcePublishPeriod]  DEFAULT ((0)) FOR [EnforcePublishPeriod]
GO
DROP INDEX IX_Template_Group_Guid ON dbo.Template_Group;
GO
ALTER TABLE [Template_Group]
    ALTER COLUMN Template_Group_Guid uniqueidentifier NOT NULL;
GO
ALTER TABLE dbo.Template_Group 
    DROP CONSTRAINT Template_Group_pk
GO
ALTER TABLE dbo.Template_Group ADD CONSTRAINT
    PK_Template_Group PRIMARY KEY CLUSTERED 
    (
    Template_Group_Guid
    ) 
GO
CREATE NONCLUSTERED INDEX IX_Template_Group_Template_Group_ID ON dbo.Template_Group
    (
    Template_Group_ID
    ) 
GO

--2023
ALTER TABLE ActionListState
    ADD LockedByUserGuid uniqueidentifier NULL;
GO

