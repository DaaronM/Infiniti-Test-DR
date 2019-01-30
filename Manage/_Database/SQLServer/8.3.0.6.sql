truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.3.0.6');
go
CREATE TABLE dbo.StoredWizard
	(
	JobGuid uniqueidentifier NOT NULL,
	Wizard varbinary(MAX) NOT NULL
	)
GO
ALTER TABLE dbo.StoredWizard ADD CONSTRAINT
	PK_StoredWizard PRIMARY KEY CLUSTERED 
	(
	JobGuid
	)
GO
CREATE proc spStoredWizard_StoredWizardList
	@JobGuid uniqueidentifier
AS
	SELECT	Wizard
	FROM	StoredWizard
	WHERE	JobGuid = @JobGuid;
GO
CREATE proc spStoredWizard_RemoveStoredWizard
	@JobGuid uniqueidentifier
AS
	DELETE FROM	StoredWizard
	WHERE	JobGuid = @JobGuid;
GO
CREATE proc spStoredWizard_UpdateStoredWizard
	@JobGuid uniqueidentifier,
	@Wizard varbinary(max)
AS
	INSERT INTO	StoredWizard(JobGuid, Wizard)
	VALUES (@JobGuid, @Wizard);
GO
