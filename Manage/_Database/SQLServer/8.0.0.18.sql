/*
** Database Update package 8.0.0.18
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.0.0.18');
go

--2045
ALTER TABLE dbo.ActionListState  ADD CONSTRAINT
    PK_ActionListState PRIMARY KEY CLUSTERED 
    (
    ActionListStateId
    )
GO
CREATE INDEX FK_WorkflowState_ActionListGuid
ON dbo.ActionListState(ActionListId)
GO

