truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.7');
go

ALTER PROCEDURE [dbo].[spUsers_UserCount]
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN
	SELECT SUM(CASE WHEN IsGuest = 0 AND Disabled = 0 THEN 1 ELSE 0 END) 
	FROM Intelledox_User
	WHERE Business_Unit_GUID = @BusinessUnitGuid;
END
GO

ALTER VIEW [dbo].[vwInProgressByUserGroups]
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

ALTER VIEW [dbo].[vwInProgressFormsByUser] 
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

ALTER VIEW [dbo].[vwInProgressForms] 
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
CAST(CASE WHEN taskState.AllowReassign = 1 AND taskstate.AssignedType = 0 THEN 1 ELSE 0 END as bit) AS AllowReassign,
taskState.AllowCancellation,
taskState.DateDueUtc,
taskState.StateGuid,
CASE WHEN taskState.RunID IS NOT NULL THEN taskState.RunID ELSE cast(cast(0 as binary) as uniqueidentifier) END AS RunID,
CAST(CASE WHEN DateDueUtc IS NOT NULL THEN 1 ELSE 0 END as bit) AS HasDueDate
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
