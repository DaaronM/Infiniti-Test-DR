truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.14');
GO

DROP VIEW [dbo].[vwInProgressFormsByUser] 
GO

CREATE VIEW [dbo].[vwUserAssignedTasks] 
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
	(CASE WHEN adrs.Full_Name <> '' THEN adrs.Full_Name
		  WHEN adrs.First_Name <> '' THEN adrs.First_Name + ' ' + adrs.Last_Name 
		  ELSE assignedByUser.Username
	 END) AS AssignedByName,
taskState.LockedByUserGuid,
taskState.AssignedType,
taskState.AssignedGuid,
CAST(CASE WHEN taskState.AllowReassign = 1 AND taskstate.AssignedType = 0 THEN 1 ELSE 0 END as bit) AS AllowReassign,
taskState.AllowCancellation,
taskState.DateDueUtc,
taskState.StateGuid,
CASE WHEN taskState.RunID IS NOT NULL THEN taskState.RunID ELSE cast(cast(0 as binary) as uniqueidentifier) END AS RunID,
CAST(CASE WHEN DateDueUtc IS NOT NULL THEN 1 ELSE 0 END as bit) AS HasDueDate
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

DROP VIEW [dbo].[vwInProgressByUserGroups]
GO

CREATE VIEW [dbo].[vwUserGroupTasks]
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
	(CASE WHEN adrs.Full_Name <> '' THEN adrs.Full_Name
		  WHEN adrs.First_Name <> '' THEN adrs.First_Name + ' ' + adrs.Last_Name 
		  ELSE usr.Username
	 END) AS AssignedByName,
taskState.LockedByUserGuid  AS LockedByUser, 
taskState.AssignedGuid, 
CAST(CASE WHEN taskState.AllowReassign = 1 AND taskstate.AssignedType = 0 THEN 1 ELSE 0 END as bit) AS AllowReassign, 
taskState.AllowCancellation, 
taskState.DateDueUtc,  
CASE WHEN taskState.RunID IS NOT NULL THEN taskState.RunID ELSE cast(cast(0 as binary) as uniqueidentifier) END AS RunID,  
CAST(CASE WHEN DateDueUtc IS NOT NULL THEN 1 ELSE 0 END as bit) AS HasDueDate  
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

DROP VIEW [dbo].[vwInProgressForms]
GO

CREATE VIEW [dbo].[vwSystemInProgressTasks]
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
(CASE WHEN lockedByUserAdrs.Full_Name <> '' THEN lockedByUserAdrs.Full_Name
	  WHEN lockedByUserAdrs.First_Name <> '' THEN lockedByUserAdrs.First_Name + ' ' + lockedByUserAdrs.Last_Name 
	  ELSE lockedByUser.Username 
 END) AS LockedByName,
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
	(CASE WHEN adrs.Full_Name <> '' THEN adrs.Full_Name
		  WHEN adrs.First_Name <> '' THEN adrs.First_Name + ' ' + adrs.Last_Name 
		  ELSE assignedByUser.Username
	 END) AS AssignedByName
	FROM Intelledox_User assignedByUser 
	LEFT OUTER JOIN Address_Book adrs ON adrs.Address_ID = assignedByUser.Address_ID

	UNION

	SELECT User_Group.Group_Guid AS AssignedByGuid, Name as UserName, Name as AssignedByName
	FROM User_Group  

	) assignedBy ON assignedBy.AssignedByGuid = taskState.AssignedByGuid
LEFT JOIN (
SELECT assignedToUser.User_Guid AS AssignedToGuid, assignedToUser.Username,
    (CASE WHEN adrs.Full_Name <> '' THEN adrs.Full_Name 
	      WHEN adrs.First_Name <> '' THEN adrs.First_Name + ' ' + adrs.Last_Name
          ELSE assignedToUser.Username
	 END) AS AssignedToName
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

DROP VIEW [dbo].[vwFormActivityByUser]
GO

CREATE VIEW [dbo].[vwUserFormActivity]
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
(CASE WHEN lockedByUserAddress.Full_Name <> '' THEN lockedByUserAddress.Full_Name
	  WHEN lockedByUserAddress.First_Name <> '' THEN lockedByUserAddress.First_Name + ' ' + lockedByUserAddress.Last_Name 
	  ELSE lockedByUser.Username 
 END) AS LockedByName,
taskState.AssignedType,
taskState.AllowReassign,
createdByUser.Username As CreatedByUserName,
createdByAddress.First_Name + ' ' + createdByAddress.Last_Name AS CreatedByName,
assignedToUser.Username As AssignedToUserName,
    (CASE WHEN assignedToAddress.Full_Name <> '' THEN assignedToAddress.Full_Name 
	      WHEN assignedToAddress.First_Name <> '' THEN assignedToAddress.First_Name + ' ' + assignedToAddress.Last_Name
          ELSE assignedToUser.Username
	 END) AS AssignedToName,
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

	UNION

	SELECT task.ActionListId, grpSubs.UserGuid
	FROM ActionListState task  
	JOIN User_Group grp ON grp.Group_Guid = task.AssignedGuid AND task.AssignedType = 1 
	JOIN User_Group_Subscription grpSubs on grpSubs.GroupGuid = grp.Group_Guid  
		
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

DROP VIEW vwInProgressAnswersByUser
GO

CREATE VIEW vwUserAssignedAnswers
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

 DROP VIEW vwProjectsByUser
 GO

CREATE VIEW vwUserAvailableForms
AS

SELECT f.Folder_Name AS FolderName, 
f.Business_Unit_Guid, u.User_Guid AS UserGuid, 
   tg.HelpText as ProjectHelpText, t.[Name] as ProjectName,   
   tg.Template_Group_Guid AS ProjectGroupGuid, tg.FeatureFlags, 
   CASE WHEN Log_Guid IS NULL THEN cast(cast(0 as binary) as uniqueidentifier) ELSE l.Log_Guid END AS LogGuid, l.DateTime_Start AS DateTimeStart 
 FROM Folder f  
 LEFT JOIN ( SELECT DISTINCT Folder_Group.FolderGuid, Intelledox_User.User_Guid FROM Folder_Group  
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

DROP VIEW vwAnswerFilesByUser
GO

CREATE VIEW vwUserAnswerFiles
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

DROP VIEW vwDocumentsByUser
GO

CREATE VIEW vwUserDocuments
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

ALTER VIEW vwSubmissions
AS

	SELECT	Template_Log.Log_Guid,
			Template.Template_Id,
			Template.Business_Unit_GUID,
			Template_Log.DateTime_Finish AS _Completion_Time_UTC,
			(SELECT Username FROM Intelledox_User WHERE User_ID = Template_Log.User_ID
				UNION
				SELECT Username FROM Intelledox_UserDeleted WHERE User_ID = Template_Log.User_ID)
			AS _Username,
			CASE WHEN Template_Log.CompletionState = 3 THEN 1 ELSE 0 END AS _Completed,
			CASE WHEN Template_Log.CompletionState = 2 THEN 1 ELSE 0 END AS _WorkflowInProgress,
			(SELECT TOP 1 LatestState.StateName
				FROM ActionListState LatestState
				WHERE LatestState.ActionListId = ActionListState.ActionListId
				ORDER BY LatestState.DateCreatedUtc DESC) AS _CurrentState
	FROM	Template_Log 
			INNER JOIN Template_Group ON Template_Group.Template_Group_Id = Template_Log.Template_Group_Id
			INNER JOIN Template ON Template.Template_Guid = Template_Group.Template_Guid
			LEFT JOIN ActionListState ON Template_Log.ActionListStateId = ActionListState.ActionListStateId
	WHERE Template_Log.CompletionState = 3
		OR (Template_Log.CompletionState = 2
			AND Template_Log.DateTime_Finish IN (SELECT MAX(tl.DateTime_Finish)
				FROM Template_Log tl
					INNER JOIN ActionListState als On tl.ActionListStateId = als.ActionListStateId
						AND als.ActionListId = ActionListState.ActionListId))



GO
