truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.5');
go

CREATE VIEW vwProjectsByUser 
AS

SELECT f.Folder_Name AS FolderName, 
f.Business_Unit_Guid, u.User_Guid AS UserGuid, 
   tg.HelpText as ProjectHelpText, t.[Name] as ProjectName,   
   tg.Template_Group_Guid AS ProjectGroupGuid, tg.FeatureFlags, 
   CASE WHEN Log_Guid IS NULL THEN cast(cast(0 as binary) as uniqueidentifier) ELSE l.Log_Guid END AS LogGuid, l.DateTime_Start AS DateTimeStart 
 FROM Folder f  
 LEFT JOIN ( SELECT Folder_Group.FolderGuid, Intelledox_User.User_Guid,  Folder_Group.GroupGuid FROM Folder_Group  
      INNER JOIN User_Group ON Folder_Group.GroupGuid = User_Group.Group_Guid  
      INNER JOIN User_Group_Subscription ON User_Group.Group_Guid = User_Group_Subscription.GroupGuid  
      INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid  ) u
	   ON u.FolderGuid = f.Folder_Guid
   INNER JOIN Template_Group tg on f.folder_Guid = tg.Folder_Guid  
   INNER JOIN Template t on tg.Template_Guid =t.Template_Guid  
   LEFT JOIN Template_Recent l on tg.Template_Group_Guid = l.Template_Group_Guid  AND l.User_Guid = u.User_Guid
 WHERE (tg.EnforcePublishPeriod = 0   
    OR ((tg.PublishStartDate IS NULL OR tg.PublishStartDate < getdate())  
    AND (tg.PublishFinishDate IS NULL OR tg.PublishFinishDate > getdate()))) 
GO

CREATE VIEW vwAnswerFilesByUser
AS  

SELECT ans.AnswerFile_Id AS AnswerFileId, ans.User_Guid AS UserGuid, ans.Description,   
    ans.RunDate, ans.InProgress, ans.AnswerFile_Guid AS AnswerFileGuid, ans.RunID,  
    Template.Name AS ProjectName, Template_Group.Template_Group_Guid as ProjectGroupGuid,  
    ans.FirstLaunchTimeUtc, Template_Group.MatchProjectVersion, Template.Business_Unit_Guid
FROM answer_file ans
    INNER JOIN Template_Group ON ans.Template_Group_Guid = Template_Group.Template_Group_Guid  
    INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid  
	INNER JOIN Folder f ON f.Folder_Guid = Template_Group.Folder_Guid 
WHERE Ans.InProgress = 0   
AND (Template_Group.EnforcePublishPeriod = 0   
	OR ((Template_Group.PublishStartDate IS NULL OR Template_Group.PublishStartDate < getdate())  
		AND (Template_Group.PublishFinishDate IS NULL OR Template_Group.PublishFinishDate > getdate())))  
AND f.Folder_Guid IN (SELECT fg.FolderGuid 
	FROM folder_group fg 
	WHERE F.Folder_Guid = fg.FolderGuid  
		 AND fg.GroupGuid IN (SELECT b.group_guid
			FROM User_Group_Subscription c 
		    INNER JOIN user_group b ON c.groupguid = b.group_guid
			WHERE c.UserGuid = ans.User_Guid))  
    
GO

CREATE VIEW vwInProgressFormsByUser 
AS

SELECT taskState.ActionListStateId AS TaskListStateId,
taskUsers.User_Guid AS UserGuid,
form.Business_Unit_Guid,
taskState.DateCreatedUtc,
projectGroup.Template_Group_Guid AS ProjectGroupGuid,
taskState.Comment, 
form.Name AS ProjectName,
taskState.StateName,
CASE WHEN assignedByUser.Username IS NULL THEN '' ELSE assignedByUser.Username END AS AssignedBy,
CASE WHEN adrs.First_Name IS NULL THEN '' ELSE adrs.First_Name + ' ' + adrs.Last_Name END AS AssignedByName,
taskState.LockedByUserGuid,
taskState.AssignedType,
taskState.AssignedGuid,
CASE WHEN taskState.AllowReassign = 1 AND taskstate.AssignedType = 0 THEN 1 ELSE 0 END AS AllowReassign,
taskState.AllowCancellation,
taskState.DateDueUtc,
taskState.StateGuid,
CASE WHEN taskState.RunID IS NOT NULL THEN taskState.RunID ELSE cast(cast(0 as binary) as uniqueidentifier) END AS RunID,
CASE WHEN DateDueUtc IS NOT NULL THEN 1 ELSE 0 END AS HasDueDate
FROM (SELECT ActionListStateId, AssignedGuid as User_Guid
 FROM ActionListState   
 WHERE AssignedType = 0 --User=0  
  
 UNION  
  
 SELECT task.ActionListStateId, task.LockedByUserGuid AS User_Guid
 FROM ActionListState task  
	 JOIN User_Group grp ON grp.Group_Guid = task.AssignedGuid  
	 INNER JOIN User_Group_Subscription grpSubs ON grpSubs.GroupGuid = grp.Group_Guid  
	 WHERE  task.AssignedType = 1 AND task.LockedByUserGuid = grpSubs.UserGuid -- Group=1 
	) taskUsers
JOIN ActionListState taskState ON taskUsers.ActionListStateId = taskState.ActionListStateId
JOIN ActionList taskList ON taskList.ActionListId = taskState.ActionListId
JOIN Template_Group projectGroup ON projectGroup.Template_Group_Guid = taskList.ProjectGroupGuid
JOIN Template form ON form.Template_Guid = projectGroup.Template_Guid
LEFT OUTER JOIN Intelledox_User assignedByUser ON assignedByUser.User_Guid = taskState.AssignedByGuid
LEFT OUTER JOIN Address_Book adrs ON adrs.Address_ID = assignedByUser.Address_ID

WHERE taskState.IsComplete = 0 AND taskState.IsAborted = 0

GO

CREATE VIEW vwInProgressByUserGroups
AS  
  
SELECT taskState.ActionListStateId AS TaskListStateId,  
taskUsers.UserGuid,
form.Business_Unit_Guid,
taskState.DateCreatedUtc,  
projectGroup.Template_Group_Guid AS ProjectGroupGuid,  
taskState.Comment,   
form.Name AS ProjectName,  
taskState.StateName,  
taskState.StateGuid,
CASE WHEN usr.Username IS NULL THEN '' ELSE usr.Username END AS AssignedBy,  
CASE WHEN adrs.First_Name IS NULL THEN '' ELSE adrs.First_Name + ' ' + adrs.Last_Name END AS AssignedByName,  
taskState.LockedByUserGuid  AS LockedByUser,  
CASE WHEN taskState.AllowReassign = 1 AND taskstate.AssignedType = 0 THEN 1 ELSE 0 END AS AllowReassign, 
taskState.AllowCancellation, 
taskState.DateDueUtc,  
CASE WHEN taskState.RunID IS NOT NULL THEN taskState.RunID ELSE cast(cast(0 as binary) as uniqueidentifier) END AS RunID,  
CASE WHEN DateDueUtc IS NOT NULL THEN 1 ELSE 0 END AS HasDueDate  
FROM  
(SELECT ActionListStateId, grpSubs.UserGuid, task.LockedByUserGuid
	 FROM ActionListState task  
	 JOIN User_Group grp ON grp.Group_Guid = task.AssignedGuid  
	 JOIN User_Group_Subscription grpSubs on grpSubs.GroupGuid = grp.Group_Guid  
	 WHERE  task.AssignedType = 1 -- Group=1  
 ) taskUsers
JOIN ActionListState taskState ON taskUsers.ActionListStateId = taskState.ActionListStateId  
JOIN ActionList taskList ON taskList.ActionListId = taskState.ActionListId  
JOIN Template_Group projectGroup ON projectGroup.Template_Group_Guid = taskList.ProjectGroupGuid  
JOIN Template form ON form.Template_Guid = projectGroup.Template_Guid  
LEFT OUTER JOIN Intelledox_User usr ON usr.User_Guid = taskState.AssignedByGuid  
LEFT OUTER JOIN Address_Book adrs ON adrs.Address_ID = usr.Address_ID  
  
WHERE taskState.IsComplete = 0 AND taskState.IsAborted = 0  
AND (taskUsers.LockedByUserGuid != taskUsers.UserGuid OR taskUsers.LockedByUserGuid = cast(cast(0 as binary) as uniqueidentifier))

GO

CREATE VIEW vwFormActivityByUser
AS 

SELECT taskState.ActionListStateId AS TaskListStateId,
taskState.ActionListId AS TaskListId,
projectGroup.Template_Group_Guid As ProjectGroupGuid,
project.Name AS ProjectName,
taskState.StateName,
assignedByUser.Username AS AssignedByUserName,
assignedByAddress.First_Name + ' ' + assignedByAddress.Last_Name AS AssignedByName,
taskState.LockedByUserGuid,
lockedByUser.Username AS LockedByUserName,
lockedByUserAddress.First_Name + ' ' + lockedByUserAddress.Last_Name AS LockedByName,
taskState.AssignedType,
taskState.AllowReassign,
createdByUser.Username As CreatedByUserName,
createdByAddress.First_Name + ' ' + createdByAddress.Last_Name AS CreatedByName,
assignedToUser.Username As AssignedToUserName,
assignedToAddress.First_Name + ' ' + assignedToAddress.Last_Name AS AssignedToName,
assignedToGroup.Name AS AssignedToGroupName,
taskState.AssignedGuid,
CASE WHEN taskState.DateUpdatedUtc IS NULL THEN taskState.DateCreatedUtc ELSE taskState.DateUpdatedUtc END LastUpdatedUtc,
accessibleBy.UserGuid AS UserGuid,
project.Business_Unit_Guid
FROM ActionListState taskState 
JOIN ActionList list on list.ActionListId = taskState.ActionListId
JOIN (SELECT task.ActionListId, task.AssignedGuid AS UserGuid
	FROM ActionListState task

	UNION

	SELECT task.ActionListId, task.LockedByUserGuid As UserGuid
	FROM ActionListState task

	UNION

	SELECT task.ActionListId, task.AssignedByGuid As UserGuid
	FROM ActionListState task
		
	) accessibleBy ON accessibleBy.ActionListId = taskState.ActionListId
JOIN Template_Group  projectGroup ON projectGroup.Template_Group_Guid = list.ProjectGroupGuid
JOIN Template project ON project.Template_Guid = projectGroup.Template_Guid
JOIN Intelledox_User as createdByUser ON createdByUser.User_Guid = list.CreatorGuid
JOIN Address_Book AS createdByAddress ON createdByAddress.Address_ID = createdByUser.Address_ID
LEFT JOIN Intelledox_User assignedByUser ON assignedByUser.User_Guid = taskState.AssignedByGuid
LEFT JOIN Address_Book assignedByAddress ON assignedByAddress.Address_ID = assignedByUser.Address_ID
LEFT JOIN Intelledox_User assignedToUser ON assignedToUser.User_Guid = taskState.AssignedGuid
LEFT JOIN Address_Book assignedToAddress ON assignedToAddress.Address_ID = assignedToUser.Address_ID
LEFT JOIN User_Group assignedToGroup ON assignedToGroup.Group_Guid = taskState.AssignedGuid
LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = taskState.LockedByUserGuid
LEFT JOIN Address_Book lockedByUserAddress ON lockedByUserAddress.Address_ID = lockedByUser.Address_ID
WHERE taskState.IsAborted = 0 AND taskState.IsComplete = 0
AND projectgroup.ShowFormActivity = 1

GO

CREATE VIEW vwInProgressAnswersByUser
AS
SELECT ans.AnswerFile_Id AS AnswerFileId, ans.User_Guid AS UserGuid, template.Business_Unit_Guid, ans.Template_Group_Guid AS ProjectGroupGuid, ans.Description,   
    ans.RunDate, ans.InProgress, ans.AnswerFile_Guid AS AnswerFileGuid, ans.RunID,  
    Template.Name AS ProjectName,
    ans.FirstLaunchTimeUtc, Template_Group.MatchProjectVersion
FROM answer_file ans  
	JOIN Intelledox_User usr ON usr.User_Guid = ans.User_Guid
	INNER JOIN Template_Group ON ans.Template_Group_Guid = Template_Group.Template_Group_Guid  
	INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid 
	INNER JOIN Folder f ON  f.Folder_Guid = Template_Group.Folder_Guid   
WHERE Usr.IsGuest = 0 AND Ans.InProgress = 1 
AND (Template_Group.EnforcePublishPeriod = 0   
		OR ((Template_Group.PublishStartDate IS NULL OR Template_Group.PublishStartDate < getdate())  
			AND (Template_Group.PublishFinishDate IS NULL OR Template_Group.PublishFinishDate > getdate())))  
AND f.Folder_Guid IN (SELECT fg.FolderGuid 
	FROM folder_group fg 
	WHERE F.Folder_Guid = fg.FolderGuid  
		 AND fg.GroupGuid IN (SELECT b.group_guid
			FROM User_Group_Subscription c 
		    INNER JOIN user_group b ON c.groupguid = b.group_guid
			WHERE c.UserGuid = ans.User_Guid))  
 GO

CREATE VIEW vwDocumentsByUser
AS

SELECT Document.DocumentId,   
    Document.Extension,    
    Document.DisplayName,    
    Document.ProjectDocumentGuid,    
    Document.DateCreated,    
    Document.JobId,  
    Document.ActionOnly,  
    Document.RepeatIndices,  
    Template.Name As ProjectName,
	Document.UserGuid,
	Template.Business_Unit_Guid
FROM Document WITH (NOLOCK)  
    INNER JOIN ProcessJob ON Document.JobId = ProcessJob.JobId  
    INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid  
    INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid  
WHERE Document.ActionOnly = 0  AND Document.DocumentLength <> -1
GO

CREATE PROCEDURE spUsers_GroupIdToGuid  
 @id int  
AS  
 SELECT Group_Guid  
 FROM User_Group  
 WHERE User_Group_ID = @id
GO

CREATE VIEW vwInProgressForms 
AS

SELECT taskState.ActionListStateId AS TaskListStateId,
form.Business_Unit_Guid, 
taskState.DateCreatedUtc,
projectGroup.Template_Group_Guid AS ProjectGroupGuid,
taskState.Comment, 
form.Name AS ProjectName,
form.Template_Guid AS ProjectGuid,
taskState.StateName,
taskState.AssignedByGuid,
assignedBy.Username AS AssignedBy,
assignedBy.AssignedByName,
taskState.LockedByUserGuid,
CASE WHEN lockedByUser.Username IS NULL THEN '' ELSE lockedByUser.Username END AS LockedBy,
CASE WHEN lockedByUserAdrs.First_Name IS NULL THEN '' ELSE lockedByUserAdrs.First_Name + ' ' + lockedByUserAdrs.Last_Name END AS LockedByName,
taskState.AssignedType,
taskState.AssignedGuid,
assignedTo.Username AS AssignedTo,
assignedTo.AssignedToName,
CASE WHEN taskState.AllowReassign = 1 AND taskstate.AssignedType = 0 THEN 1 ELSE 0 END AS AllowReassign,
taskState.AllowCancellation,
taskState.DateDueUtc,
taskState.StateGuid,
CASE WHEN taskState.RunID IS NOT NULL THEN taskState.RunID ELSE cast(cast(0 as binary) as uniqueidentifier) END AS RunID,
CASE WHEN DateDueUtc IS NOT NULL THEN 1 ELSE 0 END AS HasDueDate
FROM ActionListState taskState
JOIN ActionList taskList ON taskList.ActionListId = taskState.ActionListId
JOIN Template_Group projectGroup ON projectGroup.Template_Group_Guid = taskList.ProjectGroupGuid
JOIN Template form ON form.Template_Guid = projectGroup.Template_Guid
LEFT JOIN (
	SELECT assignedByUser.User_Guid AS AssignedByGuid, assignedByUser.Username,
	CASE WHEN adrs.First_Name IS NULL THEN '' ELSE adrs.First_Name + ' ' + adrs.Last_Name END AS AssignedByName
	FROM Intelledox_User assignedByUser 
	LEFT OUTER JOIN Address_Book adrs ON adrs.Address_ID = assignedByUser.Address_ID

	UNION

	SELECT User_Group.Group_Guid AS AssignedByGuid, Name as UserName, Name as AssignedByName
	FROM User_Group  

	) assignedBy ON assignedBy.AssignedByGuid = taskState.AssignedByGuid
LEFT JOIN (
SELECT assignedToUser.User_Guid AS AssignedToGuid, assignedToUser.Username,
	CASE WHEN adrs.First_Name IS NULL THEN '' ELSE adrs.First_Name + ' ' + adrs.Last_Name END AS AssignedToName
	FROM Intelledox_User assignedToUser 
	LEFT OUTER JOIN Address_Book adrs ON adrs.Address_ID = assignedToUser.Address_ID

	UNION

	SELECT User_Group.Group_Guid AS AssignedToGuid, Name as UserName, Name as AssignedByName
	FROM User_Group  
) assignedTo ON assignedTo.AssignedToGuid = taskState.AssignedGuid
LEFT OUTER JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = taskState.LockedByUserGuid
LEFT OUTER JOIN Address_Book lockedByUserAdrs ON lockedByUserAdrs.Address_ID = lockedByUser.Address_ID

WHERE taskState.IsComplete = 0 AND taskState.IsAborted = 0

GO
ALTER procedure [dbo].[spUsers_updateUser]
	@UserID int,
	@Username nvarchar(256),
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
	@Timezone nvarchar(50),
	@Culture nvarchar(11),
	@Language nvarchar(11),
	@InvalidLogonAttempts int,
	@PasswordSetUtc datetime,
	@EulaAcceptedUtc datetime,
	@IsGuest bit,
	@TwoFactorSecret nvarchar(100),
	@IsAnonymousUser bit
as
	SET NOCOUNT ON

	DECLARE @IdTable TABLE (ID INT);

	if @UserID = 0 OR @UserID IS NULL
	begin
		INSERT INTO Intelledox_User(Username, PwdHash, WinNT_User, Business_Unit_GUID, User_Guid, SelectedTheme, 
				ChangePassword, PwdSalt, PwdFormat, [Disabled], Address_ID, Timezone, Culture, Language, IsGuest, 
				Invalid_Logon_Attempts, Password_Set_Utc, EulaAcceptanceUtc, TwoFactorSecret, IsAnonymousUser)
		OUTPUT Inserted.User_ID INTO @IdTable
		VALUES (@Username, @Password, @WinNT_User, @BusinessUnitGUID, @User_Guid, @SelectedTheme, 
				@ChangePassword, @PasswordSalt, @PasswordFormat, @Disabled, @Address_Id, @Timezone, @Culture, @Language, @IsGuest, 
				@InvalidLogonAttempts, @PasswordSetUtc, @EulaAcceptedUtc, @TwoFactorSecret, @IsAnonymousUser);
		
		SET @NewID = (SELECT ID FROM @IdTable);

		INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
		SELECT	@User_Guid, User_Group.Group_Guid, 0
		FROM	User_Group
		WHERE	User_Group.AutoAssignment = 1
				AND Business_Unit_Guid = @BusinessUnitGUID;
	end
	else
	begin
		IF NOT EXISTS(SELECT *
			FROM Intelledox_User
			WHERE	[User_ID] = @UserID
				AND [Disabled] = @Disabled
				AND PwdHash = @Password)
		BEGIN
			-- Clear any sessions if our user account state changes
			DELETE User_Session
			FROM User_Session
				INNER JOIN Intelledox_User ON User_Session.User_Guid = Intelledox_User.User_Guid
			WHERE Intelledox_User.[User_ID] = @UserID;
		END

		UPDATE Intelledox_User
		SET Username = @Username,  
			PwdHash = @Password, 
			WinNT_User = @WinNT_User,
			SelectedTheme = @SelectedTheme,
			ChangePassword = @ChangePassword,
			PwdSalt = @PasswordSalt,
			PwdFormat = @PasswordFormat,
			[Disabled] = @Disabled,
			Timezone = @Timezone,
			Culture = @Culture,
			Language = @Language,
			Address_ID = @Address_Id,
			Invalid_Logon_Attempts = @InvalidLogonAttempts,
			Password_Set_Utc = @PasswordSetUtc,
			EulaAcceptanceUtc = @EulaAcceptedUtc,
			TwoFactorSecret = @TwoFactorSecret,
			IsAnonymousUser = @IsAnonymousUser
		WHERE [User_ID] = @UserID;
	end
GO
