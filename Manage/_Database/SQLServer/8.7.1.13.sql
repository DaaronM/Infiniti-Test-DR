truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.7.1.13');
go
DROP PROCEDURE [spAudit_FullAnswerFileList]
GO
DROP PROCEDURE dbo.[spAudit_FullAnswerFileList]
GO
DROP PROCEDURE [spProject_GetAllProjectDefinitionsByBusinessUnit]
GO
DROP PROCEDURE dbo.[spProject_GetAllProjectDefinitionsByBusinessUnit]
GO
DROP PROCEDURE [spProject_GetAllProjectVersions]
GO
DROP PROCEDURE dbo.[spProject_GetAllProjectVersions]
GO
DROP PROCEDURE [spProject_GetVersionModifiedDate]
GO
DROP PROCEDURE dbo.[spProject_GetVersionModifiedDate]
GO
DROP PROCEDURE [spStoredWizard_RemoveStoredWizard]
GO
DROP PROCEDURE [spStoredWizard_StoredWizardList]
GO
DROP PROCEDURE [spStoredWizard_UpdateStoredWizard]
GO
DROP PROCEDURE [spUser_AddToPasswordHistory]
GO
DROP PROCEDURE dbo.[spUser_AddToPasswordHistory]
GO
DROP PROCEDURE [spUser_ClearInvalidLogonAttempts]
GO
DROP PROCEDURE dbo.[spUser_ClearInvalidLogonAttempts]
GO
DROP PROCEDURE [spUser_HasUsedPassword]
GO
DROP PROCEDURE dbo.[spUser_HasUsedPassword]
GO
DROP PROCEDURE [spUser_InvalidLogonAttempt]
GO
DROP PROCEDURE dbo.[spUser_InvalidLogonAttempt]
GO
DROP PROCEDURE [spUser_IsLockedOut]
GO
DROP PROCEDURE dbo.[spUser_IsLockedOut]
GO
DROP PROCEDURE [spWorkflowEscalationCleanup]
GO
DROP PROCEDURE dbo.[spWorkflowEscalationCleanup]
GO
CREATE PROCEDURE dbo.spAudit_FullAnswerFileList
	@BusinessUnit_Guid uniqueidentifier
AS
BEGIN

        SELECT	Answer_File.AnswerFile_Guid
		FROM	Answer_File
			INNER JOIN Intelledox_User ON Answer_File.User_Guid = Intelledox_User.User_Guid
		WHERE	Intelledox_User.Business_Unit_Guid = @BusinessUnit_Guid
END
GO
CREATE PROCEDURE [dbo].spProject_GetAllProjectDefinitionsByBusinessUnit
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN
	SELECT Template_Guid
	FROM Template
	WHERE Template.Business_Unit_GUID = @BusinessUnitGuid
END
GO
CREATE PROCEDURE [dbo].spProject_GetAllProjectVersions
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN
	SELECT Template_Version.Template_Guid, Template_Version.Template_Version
	FROM Template_Version
		INNER JOIN Template ON Template.Template_Guid = Template_Version.Template_Guid
	WHERE Template.Business_Unit_GUID = @BusinessUnitGuid
END
GO
CREATE PROCEDURE dbo.spProject_GetVersionModifiedDate
	@ProjectGuid uniqueidentifier,
	@Version varchar(10)
AS
BEGIN
		SELECT Template.Modified_Date
		FROM Template
		WHERE Template.Template_Version = @Version
			AND Template.Template_Guid = @ProjectGuid
	UNION
		SELECT Template_Version.Modified_Date
		FROM Template_Version
		WHERE Template_Version.Template_Version = @Version
			AND Template_Version.Template_Guid = @ProjectGuid
END
GO
CREATE proc spStoredWizard_RemoveStoredWizard
	@JobGuid uniqueidentifier
AS
	DELETE FROM	StoredWizard
	WHERE	JobGuid = @JobGuid;
GO
CREATE proc spStoredWizard_StoredWizardList
	@JobGuid uniqueidentifier
AS
	SELECT	Wizard
	FROM	StoredWizard
	WHERE	JobGuid = @JobGuid;
GO
CREATE proc spStoredWizard_UpdateStoredWizard
	@JobGuid uniqueidentifier,
	@Wizard varbinary(max)
AS
	INSERT INTO	StoredWizard(JobGuid, Wizard)
	VALUES (@JobGuid, @Wizard);
GO
CREATE PROCEDURE spWorkflowEscalationCleanup(
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
GO
ALTER SCHEMA dbo
	TRANSFER ConnectorSettings_BusinessUnit
GO
ALTER PROCEDURE [dbo].[spDocument_DeleteDocument]
	@UserGuid uniqueidentifier,
	@DocumentId uniqueidentifier
as
	DELETE FROM	Document
	WHERE	UserGuid = @UserGuid
			AND DocumentId = @DocumentId;

GO
