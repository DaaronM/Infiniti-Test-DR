/*
** Database Update package 8.2.2.1
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.2.1');
go

--2125
CREATE VIEW [dbo].[vwWorkflowHistory]
AS
SELECT      dbo.ActionList.ActionListId, dbo.ActionList.ProjectGroupGuid, dbo.ActionList.CreatorGuid, dbo.ActionList.DateCreatedUtc, dbo.ActionListState.ActionListStateId, 
            dbo.ActionListState.ActionListId AS Expr1, dbo.ActionListState.StateGuid, dbo.ActionListState.StateName, dbo.ActionListState.PreviousActionListStateId, 
            dbo.ActionListState.Comment, dbo.ActionListState.AnswerFileXml, dbo.ActionListState.AssignedGuid, dbo.ActionListState.AssignedType, 
            dbo.ActionListState.DateCreatedUtc AS Expr2, dbo.ActionListState.DateUpdatedUtc, dbo.ActionListState.AssignedByGuid, 
            dbo.ActionListState.LockedByUserGuid, dbo.ActionListState.ExpireOnUtc, dbo.ActionListState.ExpiryEmailBody, dbo.ActionListState.ExpiryEmailSubject, 
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
GO

--2126
DROP PROCEDURE [dbo].[spAudit_UpdateTransactionLineItem]
GO
DROP PROCEDURE [dbo].[spAudit_TransactionList]
GO
DROP PROCEDURE [dbo].[spAudit_TransactionLineItemList]
GO
DROP PROCEDURE [dbo].[spAudit_InsertTransaction]
GO
exec sp_rename 'dbo.PurchaseTransaction', 'zzPurchaseTransaction';
GO
exec sp_rename 'dbo.PurchaseLineItem', 'zzPurchaseLineItem';
GO

