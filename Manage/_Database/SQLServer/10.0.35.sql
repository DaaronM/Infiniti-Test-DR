truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.35');
GO

ALTER TABLE dbo.PendingWorkflowTransition 
	ADD AllowCommenting bit not null DEFAULT 0
GO

ALTER PROCEDURE [dbo].[spWorkflow_UpdatePending] (
	@PendingWorkflowTransitionId uniqueidentifier,
	@ActionListStateId uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier,
	@StateId uniqueidentifier,
	@AllowCommenting bit
)
AS
	INSERT INTO PendingWorkflowTransition(
		PendingWorkflowTransitionId,
		ActionListStateId,
		BusinessUnitGuid,
		StateId,
		AllowCommenting)
	VALUES (@PendingWorkflowTransitionId,
		@ActionListStateId,
		@BusinessUnitGuid,
		@StateId,
		@AllowCommenting)
		
GO
