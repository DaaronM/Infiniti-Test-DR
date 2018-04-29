truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.1.4');
GO

CREATE NONCLUSTERED INDEX [FK_WorkflowState_LockedByUserGuid] ON [dbo].[ActionListState]
(
	[LockedByUserGuid] ASC
)
GO
DROP PROCEDURE [dbo].[spTenant_GetTenantLogoBinary]
GO
