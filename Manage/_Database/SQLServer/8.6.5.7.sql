truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.5.7');
go
ALTER PROCEDURE spWorkflowEscalationCleanup(
	@TaskListStateId uniqueidentifier,
	@ClearCompleteOnly bit = 1
	)
AS
BEGIN
	DECLARE @State TABLE
	(
		ActionListStateId uniqueidentifier
	)

	DECLARE @Escalation TABLE
	(
		RecurrenceId uniqueidentifier, 
		EscalationId uniqueidentifier, 
		ActionListStateId uniqueidentifier
	)

	/* Find the taskid so we can fetch all the other states */
	declare @taskID uniqueidentifier 
	set @taskID = (Select ActionListId from actionliststate where actionliststateid = @taskListStateId)

	IF (@ClearCompleteOnly = 1)
		BEGIN
			INSERT INTO @State(ActionListStateId)
			SELECT ActionListStateId 
			FROM ActionListState 
			WHERE actionListId = @taskID 
				and iscomplete=1
		END
	ELSE
		BEGIN
			INSERT INTO @State(ActionListStateId)
			SELECT ActionListStateId 
			FROM ActionListState 
			WHERE actionListId = @taskID
		END

	INSERT INTO @Escalation (RecurrenceId, EscalationId, ActionListStateId)
	SELECT we.RecurrenceId, we.EscalationId, we.ActionListStateId
	FROM Workflow_Escalation we
		JOIN @State tt ON we.ActionListStateId = tt.ActionListStateId

	DELETE rp
	FROM RecurrencePattern rp
		JOIN @Escalation esc ON rp.RecurrencePatternId = esc.RecurrenceId

	DELETE ep
	FROM EscalationProperties ep
		JOIN @Escalation esc ON ep.EscalationId = esc.Escalationid

	DELETE we
	FROM Workflow_Escalation we
		JOIN @Escalation esc ON we.EscalationId = esc.EscalationId
END
