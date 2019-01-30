truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.5.0.2');
go
ALTER TABLE dbo.Template ADD
	EncryptedProjectDefinition varbinary(MAX) NULL
GO

ALTER TABLE dbo.Template_Version ADD
	EncryptedProjectDefinition varbinary(MAX) NULL
GO

ALTER PROCEDURE [dbo].[spProject_Definition] (
	@TemplateGuid uniqueidentifier,
	@VersionNumber nvarchar(10) = '0'
)
AS
	If @VersionNumber = '0'
	BEGIN
		SELECT	Project_Definition,
				EncryptedProjectDefinition 
		FROM	Template 
		WHERE	Template_Guid = @TemplateGuid;
	END
	ELSE
	BEGIN
		SELECT Project_Definition,
				EncryptedProjectDefinition
		FROM	Template 
		WHERE	Template_Guid = @TemplateGuid
			AND Template_Version = @VersionNumber
		UNION ALL
		SELECT	Project_Definition,
				EncryptedProjectDefinition
		FROM	Template_Version
		WHERE	Template_Guid = @TemplateGuid
			AND Template_Version = @VersionNumber;
	END
GO

ALTER PROCEDURE [dbo].[spProject_UpdateDefinition] (
	@Xtf xml,
	@TemplateGuid uniqueidentifier,
	@EncryptedXtf varbinary(MAX)
)
AS
	DECLARE @FeatureFlags int;

	BEGIN TRAN	
		-- Feature detection --
		SET @FeatureFlags = 0

		-- Workflow
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/Workflow/State/Transition)') as ProjectXML(P))
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 1;
		END

		-- Data source
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 2		-- Data field
						OR Q.value('@TypeId', 'int') = 9	-- Data table
						OR Q.value('@TypeId', 'int') = 12	-- Data list
						OR Q.value('@TypeId', 'int') = 14)	-- Data source
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 2;
		END

		-- Content library
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 11
						AND Q.value('@DisplayType', 'int') = 8) -- Existing content item
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 4;
		END
		
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 11
						AND Q.value('@DisplayType', 'int') = 4) -- Search
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 8;
		END

		-- Address
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 1)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 16;
		END

		-- Sign off
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 5)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 32;
		END

		-- Rich text
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 19)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 64;
		END
				
		IF @EncryptedXtf IS NULL
		BEGIN
			UPDATE	Template 
			SET		Project_Definition = @XTF,
					FeatureFlags = @FeatureFlags,
					EncryptedProjectDefinition = NULL
			WHERE	Template_Guid = @TemplateGuid;
		END
		ELSE
		BEGIN
			UPDATE	Template 
			SET		EncryptedProjectDefinition = @EncryptedXtf,
					FeatureFlags = @FeatureFlags,
					Project_Definition = NULL
			WHERE	Template_Guid = @TemplateGuid;
		END
	COMMIT
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

CREATE PROCEDURE [dbo].[spProject_UpdateVersionDefinition] (
	@Xtf xml,
	@TemplateGuid uniqueidentifier,
	@EncryptedXtf varbinary(MAX),
	@Version varchar(10)
)
AS
-- Note: Doesn't update feature flags
		UPDATE	Template_Version
		SET		Project_Definition = @XTF,
				EncryptedProjectDefinition = @EncryptedXtf
		WHERE	Template_Guid = @TemplateGuid
			AND Template_Version = @Version;
GO

ALTER PROCEDURE [dbo].[spProject_DefinitionsByGroup] (
	@TemplateGroupGuid uniqueidentifier
)
AS
		SELECT	Template.Template_Guid, 
			Template.Template_Type_ID,
			Template.Template_Version, 
			CASE WHEN Template.EncryptedProjectDefinition IS NULL THEN 0 ELSE 1 END AS Encrypted,
			Template.EncryptedProjectDefinition,
			Template.Project_Definition
		FROM	Template_Group
				INNER JOIN Template ON (Template_Group.Template_Guid = Template.Template_Guid 
						AND (Template_Group.Template_Version IS NULL
							OR Template_Group.Template_Version = Template.Template_Version))
					OR (Template_Group.Layout_Guid = Template.Template_Guid
						AND (Template_Group.Layout_Version IS NULL
							OR Template_Group.Layout_Version = Template.Template_Version))
		WHERE	Template_Group.Template_Group_Guid = @TemplateGroupGuid
	UNION ALL
		SELECT	Template_Version.Template_Guid, 
			Template.Template_Type_ID,
			Template_Version.Template_Version, 
			CASE WHEN Template_Version.EncryptedProjectDefinition IS NULL THEN 0 ELSE 1 END AS Encrypted,
			Template_Version.EncryptedProjectDefinition,
			Template_Version.Project_Definition
		FROM	Template_Group
				INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
				INNER JOIN Template_Version ON (Template_Group.Template_Guid = Template_Version.Template_Guid 
						AND Template_Group.Template_Version = Template_Version.Template_Version)
					OR (Template_Group.Layout_Guid = Template_Version.Template_Guid
						AND Template_Group.Layout_Version = Template_Version.Template_Version)
		WHERE	Template_Group.Template_Group_Guid = @TemplateGroupGuid
	ORDER BY Template_Type_ID;
GO

IF NOT EXISTS(SELECT * FROM Global_Options WHERE OptionCode = 'WAIT_TIME_BETWEEN_LOGON_ATTEMPTS')
BEGIN
INSERT INTO Global_Options (BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
VALUES ('00000000-0000-0000-0000-000000000000', 'WAIT_TIME_BETWEEN_LOGON_ATTEMPTS', 'Wait Time Between Logon Attempts', '1');
END
GO

IF NOT EXISTS(SELECT * FROM Global_Options WHERE OptionCode = 'NUMBER_OF_FAILED_IP_LOGON_ATTEMPTS')
BEGIN
INSERT INTO Global_Options (BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
VALUES ('00000000-0000-0000-0000-000000000000', 'NUMBER_OF_FAILED_IP_LOGON_ATTEMPTS', 'Number Of Failed Logon Attempts From An IP Address', '5');
END
GO

IF NOT EXISTS(SELECT * FROM Global_Options WHERE OptionCode = 'IP_ADDRESS_LOCKOUT_TIME')
BEGIN
INSERT INTO Global_Options (BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
VALUES ('00000000-0000-0000-0000-000000000000', 'IP_ADDRESS_LOCKOUT_TIME', 'Length Of Time In Seconds After An IP Address Lock Out', '60');
END
GO

CREATE TABLE [dbo].[MultiTenantPortal_Admin](
	[UserGuid] [uniqueidentifier] NOT NULL,
	[Username] [nvarchar](50) NULL,
	[PwdHash] [varchar](1000) NULL,
	[PwdSalt] [nvarchar](128) NULL,
	[PwdFormat] [int] NOT NULL,
	[ChangePassword] [bit] NOT NULL,
	[Disabled] [bit] NOT NULL
)
GO

ALTER TABLE dbo.MultiTenantPortal_Admin ADD CONSTRAINT
PK_MultiTenantPortal_Admin PRIMARY KEY CLUSTERED 
(
UserGuid
) 
GO

ALTER TABLE dbo.MultiTenantPortal_Admin ADD CONSTRAINT
DF_MultiTenantPortal_Admin_Disabled DEFAULT ((0)) FOR Disabled
GO

ALTER TABLE dbo.MultiTenantPortal_Admin ADD CONSTRAINT
DF_MultiTenantPortal_Admin_ChangePassword DEFAULT ((0)) FOR ChangePassword
GO

ALTER TABLE dbo.MultiTenantPortal_Admin ADD CONSTRAINT
DF_MultiTenantPortal_Admin_PwdFormat DEFAULT ((1)) FOR PwdFormat
GO

INSERT INTO dbo.MultiTenantPortal_Admin
SELECT * FROM dbo.FX_PortalAdmin
GO

DROP TABLE dbo.FX_PortalAdmin
GO

CREATE PROCEDURE [dbo].[spMultiTenantAdmin_UpdateUser]
	@Username nvarchar(50),
	@Password nvarchar(1000),
	@PasswordSalt nvarchar(128),
	@ChangePassword int,
	@ErrorCode int = 0 output
AS

	BEGIN
		UPDATE MultiTenantPortal_Admin
		SET PwdHash = @Password, 
			PwdSalt = @PasswordSalt,
			ChangePassword = @ChangePassword
		WHERE [Username] = @Username;
	END

	SET @ErrorCode = @@error;

GO

DROP PROCEDURE [dbo].[FX_spUsers_UpdateUser]
GO

CREATE PROCEDURE [dbo].[spMultiTenantAdmin_UserByUsername]
	@Username nvarchar(50)
AS
	SELECT	MultiTenantPortal_Admin.*
	FROM	MultiTenantPortal_Admin
	WHERE	Username = @Username;

GO

DROP PROCEDURE [dbo].[FX_spUsers_UserByUsername]
GO



