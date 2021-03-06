truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.6.8');
go

ALTER PROCEDURE [dbo].[spLog_GetSubmissionLog]
	@StartDateUTC datetime, 
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN
	SELECT Template_Group.Template_Group_ID,
		Template_Log.DateTime_Finish,
		Template_Log.Log_Guid,
		Template_Log.CompletionState,
		Template.Template_Guid
	FROM Template_Log
		LEFT JOIN Intelledox_User ON Template_Log.User_ID = Intelledox_User.User_ID
		LEFT JOIN Intelledox_UserDeleted ON Template_Log.User_ID = Intelledox_UserDeleted.User_ID
		LEFT JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
		LEFT JOIN Template ON Template.Template_Guid = Template_Group.Template_Guid
	WHERE DateTime_Finish > @StartDateUTC
		AND (Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
			OR Intelledox_UserDeleted.BusinessUnitGuid = @BusinessUnitGuid)
		AND (CompletionState = 2 -- Workflow State Completed
			OR CompletionState = 3); -- Completed
END

GO

ALTER PROCEDURE [dbo].[spLog_GetActionLog]
	-- Add the parameters for the stored procedure here
	@StartDateUTC datetime, 
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN
	SELECT Action_Log.ActionGuid,
		Action_Log.Log_Guid,
		Action_Log.DateTimeUTC,
		Template_Group.Template_Guid
	FROM Action_Log
		LEFT JOIN Template_Log ON Action_Log.Log_Guid = Template_Log.Log_Guid
		LEFT JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
	WHERE DateTimeUTC > @StartDateUTC
		AND BusinessUnitGuid = @BusinessUnitGuid
END

GO

ALTER PROCEDURE [dbo].[spLog_GetDocumentLog]
	@StartDateUTC datetime, 
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN
	SELECT Document.DocumentId,
		Document.DateCreated,
		Document.Extension,
		Template_Group.Template_Guid
	FROM Document
		LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Document.UserGuid
		LEFT JOIN Intelledox_UserDeleted ON Intelledox_UserDeleted.UserGuid = Document.UserGuid
		LEFT JOIN ProcessJob ON Document.JobId = ProcessJob.JobId
		LEFT JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
	WHERE DateCreated > @StartDateUTC
		AND (Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
			OR Intelledox_UserDeleted.BusinessUnitGuid = @BusinessUnitGuid)
		AND Document.Attachment <> 1;
END

GO

ALTER TABLE [dbo].Escalation_Log
ADD ProjectGuid uniqueidentifier
GO

ALTER PROCEDURE [dbo].[spLog_InsertEscalationLog]
	@EscalationTypeId uniqueIdentifier,
	@CurrentStateGuid uniqueIdentifier,
	@ProcessingMS int,
	@EncryptedChecksum varbinary(MAX),
	@BusinessUnitGuid uniqueidentifier,
	@ProjectGuid uniqueidentifier
AS
    SET NOCOUNT ON;
	BEGIN TRAN;

	DECLARE @PreviousChecksum varbinary(MAX)
	DECLARE @CurrentTime datetime

	SET @CurrentTime = GETUTCDATE();
	SET @PreviousChecksum = (SELECT Data
		FROM LogData
		WHERE [Type] = 3
			AND BusinessUnitGuid = @BusinessUnitGuid);
			
	UPDATE LogData 
	SET Data = @EncryptedChecksum
	WHERE [Type] = 3
		AND BusinessUnitGuid = @BusinessUnitGuid;

	IF @@ROWCOUNT = 0
	BEGIN
		INSERT INTO LogData ([Type], BusinessUnitGuid, Data)
		VALUES (3, @BusinessUnitGuid, @EncryptedChecksum)
	END

    INSERT INTO Escalation_Log (EscalationTypeId, [DateTimeUTC], [CurrentStateGuid], [ProcessingMS], 
			[EncryptedChecksum], [BusinessUnitGuid], ProjectGuid)
    VALUES (@EscalationTypeId, @CurrentTime, @CurrentStateGuid, @ProcessingMS, @PreviousChecksum, 
		@BusinessUnitGuid, @ProjectGuid);

	COMMIT;
	
GO

ALTER TABLE [dbo].Email_Log
ADD ProjectGuid uniqueidentifier;
GO

ALTER PROCEDURE [dbo].[spLog_InsertEmailLog]
	@EmailType varchar(100),
	@Id uniqueIdentifier,
	@NumAddressees int,
	@EncryptedChecksum varbinary(MAX),
	@BusinessUnitGuid uniqueidentifier,
	@ProjectGuid uniqueidentifier
AS
    SET NOCOUNT ON;
	BEGIN TRAN;

	DECLARE @PreviousChecksum varbinary(MAX)
	DECLARE @CurrentTime datetime

	SET @CurrentTime = GETUTCDATE();
	SET @PreviousChecksum = (SELECT Data
		FROM LogData
		WHERE [Type] = 4
			AND BusinessUnitGuid = @BusinessUnitGuid);

	UPDATE LogData 
	SET Data = @EncryptedChecksum
	WHERE [Type] = 4
		AND BusinessUnitGuid = @BusinessUnitGuid;

	IF @@ROWCOUNT = 0
	BEGIN
		INSERT INTO LogData ([Type], BusinessUnitGuid, Data)
		VALUES (4, @BusinessUnitGuid, @EncryptedChecksum)
	END

    INSERT INTO Email_Log (EmailType, [DateTimeUTC], [Id], NumAddressees, 
			[EncryptedChecksum], [BusinessUnitGuid], ProjectGuid)
    VALUES (@EmailType, @CurrentTime, @Id, @NumAddressees, @PreviousChecksum, 
		@BusinessUnitGuid, @ProjectGuid);

	COMMIT;
GO

ALTER procedure [dbo].[spTemplate_RemoveTemplate]
	@TemplateGuid uniqueidentifier,
	@OnlyChildInfo bit
AS
	IF @OnlyChildInfo = 0
	BEGIN
		DELETE	template_Group
		WHERE	template_guid = @TemplateGuid
			OR	layout_guid = @TemplateGuid;

		DELETE	User_Group_Template
		WHERE	TemplateGuid = @TemplateGuid;
	END
	
	DELETE	Template_File
	WHERE	Template_Guid = @TemplateGuid;
	
	DELETE	Template
	WHERE	Template_Guid = @TemplateGuid;
	
	DELETE	Template_File_Version
	WHERE	Template_Guid = @TemplateGuid;
	
	DELETE	Template_Translation
	WHERE	Template_Guid = @TemplateGuid;

	DELETE	Template_Version
	WHERE	Template_Guid = @TemplateGuid;

	DELETE  Xtf_Datasource_Dependency
	WHERE	Template_Guid = @TemplateGuid;

	DELETE  Xtf_ContentLibrary_Dependency
	WHERE	Template_Guid = @TemplateGuid;

	DELETE FROM Xtf_Fragment_Dependency
	WHERE	Template_Guid = @TemplateGuid;
GO
