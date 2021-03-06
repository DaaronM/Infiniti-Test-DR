truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.9');
go
ALTER VIEW vwProjectsByUser
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

ALTER VIEW vwFormActivityByUser
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
