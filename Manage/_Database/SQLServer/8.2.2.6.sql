/*
** Database Update package 8.2.2.6
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.2.6');
go

/* EscalateEmailBody, EscalateEmailSubject and EscalateOnUtc were dropped in the last update */
ALTER VIEW [dbo].[vwWorkflowHistory]
AS
SELECT      dbo.ActionList.ActionListId, dbo.ActionList.ProjectGroupGuid, dbo.ActionList.CreatorGuid, dbo.ActionListState.ActionListStateId, 
            dbo.ActionListState.StateGuid, dbo.ActionListState.StateName, dbo.ActionListState.PreviousActionListStateId, 
            dbo.ActionListState.Comment, dbo.ActionListState.AnswerFileXml, dbo.ActionListState.AssignedGuid, dbo.ActionListState.AssignedType, 
            dbo.ActionListState.DateCreatedUtc, dbo.ActionListState.DateUpdatedUtc, dbo.ActionListState.AssignedByGuid, 
            dbo.ActionListState.LockedByUserGuid, we.EscalateOnUtc, we.EscalateEmailBody, we.EscalateEmailSubject, we.EscalateEmailCC, we.SendToAssignee,
            dbo.ActionListState.IsComplete, dbo.ActionListState.AllowReassign, dbo.ActionListState.RestrictToGroupGuid, dbo.ActionListState.IsAborted,
			u.UserName as AssignedBy, ab.Full_Name as AssignedByFullName,
			u2.UserName as AssignedTo, ab2.Full_Name as AssignedToFullName,
			ug.Name as AssignedGroupName,
			u.Business_Unit_GUID,
			case when dbo.ActionListState.AssignedType = 0 then dbo.ActionListState.AssignedGuid
			end as AssignedToUserGuid,
			case when dbo.ActionListState.AssignedType = 1 then dbo.ActionListState.AssignedGuid
			end as AssignedToGroupGuid
FROM        dbo.ActionList INNER JOIN
            dbo.ActionListState ON dbo.ActionList.ActionListId = dbo.ActionListState.ActionListId
LEFT JOIN	Intelledox_User u on u.User_Guid = AssignedByGuid
LEFT JOIN	Address_Book ab on ab.Address_ID = u.Address_ID
LEFT JOIN	Intelledox_User u2 on u2.User_Guid = AssignedGuid
LEFT JOIN	Address_Book ab2 on ab2.Address_ID = u2.Address_ID
LEFT JOIN   User_Group ug on ug.Group_Guid = AssignedGuid
LEFT JOIN   Workflow_Escalation we on we.ActionListStateId = ActionListState.ActionListStateId

GO

