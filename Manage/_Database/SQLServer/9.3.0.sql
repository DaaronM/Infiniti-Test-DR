truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.3.0');
go


ALTER PROC [dbo].[spProject_GetFragmentDependencies]
	@ProjectGuid uniqueidentifier,
	@VersionNumber nvarchar(10) = '0'
AS
	IF (@VersionNumber = '0')
	BEGIN
		SET @VersionNumber = (SELECT Template_Version FROM Template WHERE Template_Guid = @ProjectGuid)
	END

	SELECT	dependency.Fragment_Guid, t.Name
	FROM	Xtf_Fragment_Dependency dependency
	JOIN    Template t ON dependency.Fragment_Guid = t.Template_Guid
	WHERE	dependency.Template_Guid = @ProjectGuid
			AND dependency.Template_Version  = @VersionNumber;

GO

CREATE TABLE [dbo].[Action_Log](
	[ActionGuid] [uniqueidentifier] NOT NULL,
	[DateTimeUTC] [datetime] NOT NULL,
	[Log_Guid] [uniqueidentifier] NOT NULL,
	[User_Guid] [uniqueidentifier] NOT NULL,
	[ProcessingMS] [float] NOT NULL,
	[Result] [int] NOT NULL,
	[EncryptedChecksum] [varbinary](max) NULL,
	[BusinessUnitGuid] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_Action_Log] PRIMARY KEY NONCLUSTERED 
(
	[DateTimeUTC] ASC
)
) 

GO

CREATE TABLE [dbo].[LogData](
	[BusinessUnitGuid] [uniqueidentifier] NOT NULL,
	[Type] [int] NOT NULL,
	[Data] [varbinary](max) NOT NULL,
 CONSTRAINT [PK_LogData] PRIMARY KEY CLUSTERED 
(
	[BusinessUnitGuid] ASC,
	[Type] ASC
)
) 

GO

CREATE PROCEDURE [dbo].[spLog_GetActionLog]
	@StartDateUTC datetime, 
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN
	SELECT *
	FROM Action_Log
	WHERE DateTimeUTC > @StartDateUTC
		AND BusinessUnitGuid = @BusinessUnitGuid
END

GO

CREATE PROCEDURE [dbo].[spLog_GetTransactionLog] (
	@BusinessUnitGuid uniqueidentifier
)

AS
	SELECT	Data
	FROM	LogData
	WHERE	BusinessUnitGuid = @BusinessUnitGuid
		AND [Type] = 2;

GO

CREATE PROCEDURE [dbo].[spLog_SaveTransactionLog]
	@BusinessUnitGuid uniqueidentifier, 
	@TransactionLog varbinary(MAX)
AS
	DELETE FROM LogData
	WHERE BusinessUnitGuid = @BusinessUnitGuid
		AND [Type] = 2;

	INSERT INTO LogData (BusinessUnitGuid, [Type], Data)
	VALUES (@BusinessUnitGuid, 2, @TransactionLog);

GO

CREATE PROCEDURE [dbo].[spLog_InsertActionLog]
	@ActionGuid uniqueIdentifier,
	@Log_Guid uniqueIdentifier,
	@User_Guid uniqueIdentifier,
	@ProcessingMS float,
	@Result int,
	@EncryptedChecksum varbinary(MAX),
	@BusinessUnitGuid uniqueidentifier
AS
    SET NOCOUNT ON;
	BEGIN TRAN;

	DECLARE @PreviousChecksum varbinary(MAX)
	DECLARE @CurrentTime datetime

	SET @CurrentTime = GETUTCDATE();
	SET @PreviousChecksum = (SELECT Data
		FROM LogData
		WHERE [Type] = 1
			AND BusinessUnitGuid = @BusinessUnitGuid);

	-- Manipulate @PreviousChecksum?

	UPDATE LogData 
	SET Data = @EncryptedChecksum
	WHERE [Type] = 1
		AND BusinessUnitGuid = @BusinessUnitGuid;

	IF @@ROWCOUNT = 0
	BEGIN
		INSERT INTO LogData ([Type], BusinessUnitGuid, Data)
		VALUES (1, @BusinessUnitGuid, @EncryptedChecksum)
	END

    INSERT INTO Action_Log ([ActionGuid], [DateTimeUTC], [Log_Guid], [User_Guid], [ProcessingMS], [Result], [EncryptedChecksum], [BusinessUnitGuid])
    VALUES (@ActionGuid, @CurrentTime, @Log_Guid, @User_Guid, @ProcessingMS, @Result, @PreviousChecksum, @BusinessUnitGuid);

	COMMIT;

GO

INSERT INTO Global_Options (BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
VALUES ('00000000-0000-0000-0000-000000000000', 'LAST_LOG_EMAIL_DATE_UTC', 'The last time an email was send to Intelledox with the transaction log', '2016-01-01T00:00:00.00Z');
GO

INSERT INTO Global_Options (BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
VALUES ('00000000-0000-0000-0000-000000000000', 'INSTANCE_NAME', 'The name of this Infiniti instance (whole server)', '');
GO

INSERT INTO Global_Options (BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
VALUES ('00000000-0000-0000-0000-000000000000', 'INSTANCE_FROM_ADDRESS', 'The email address that should be used when emails are sent from this server (ignoring BUs)', '');
GO
