truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.4.0.0');
go
ALTER PROCEDURE [dbo].[spProject_Binary] (
	@TemplateGuid uniqueidentifier,
	@FileGuid uniqueidentifier,
	@VersionNumber nvarchar(10) = '0'
)
AS
	If @VersionNumber = '0'
	BEGIN
		SELECT	File_Guid, FormatTypeId, [Binary]  
		FROM	Template_File
		WHERE	Template_Guid = @TemplateGuid
				AND File_Guid = @FileGuid;
	END
	ELSE
	BEGIN
		SELECT	Template_File.File_Guid, Template_File.FormatTypeId, Template_File.[Binary] 
		FROM	Template_File
				INNER JOIN Template ON Template.Template_Guid = Template_File.Template_Guid
		WHERE	Template.Template_Guid = @TemplateGuid
			AND Template.Template_Version = @VersionNumber
				AND Template_File.File_Guid = @FileGuid
		UNION ALL
		SELECT	File_Guid, FormatTypeId, [Binary]
		FROM	Template_File_Version
		WHERE	Template_Guid = @TemplateGuid
			AND Template_Version = @VersionNumber
				AND File_Guid = @FileGuid;
	END
GO
CREATE TABLE [dbo].ConnectorSettings_BusinessUnit
	(
	BusinessUnitGuid uniqueidentifier NOT NULL,
	ConnectorSettingsElementTypeId uniqueidentifier NOT NULL,
	ElementValue nvarchar(MAX) NULL
	)
GO
ALTER TABLE ConnectorSettings_BusinessUnit ADD CONSTRAINT
	PK_ConnectorSettings_BusinessUnit PRIMARY KEY CLUSTERED 
	(
	BusinessUnitGuid,
	ConnectorSettingsElementTypeId
	) 
GO
INSERT INTO ConnectorSettings_BusinessUnit(BusinessUnitGuid, ConnectorSettingsElementTypeId, ElementValue)
SELECT	bu.Business_Unit_Guid, ConnectorSettingsElementTypeId, ElementValue
FROM	Business_Unit bu,
		ConnectorSettings_ElementType;
GO
ALTER PROCEDURE [dbo].[spConnectorSettings_ElementTypeList] 
	@BusinessUnitGuid uniqueidentifier,
	@ConnectorSettingsTypeId uniqueidentifier
AS
BEGIN
	SET NOCOUNT ON

	IF @BusinessUnitGuid IS NULL
		SET @BusinessUnitGuid = (SELECT TOP 1 Business_Unit_Guid FROM Business_Unit);

	SELECT	et.ConnectorSettingsElementTypeId,
			et.ConnectorSettingsTypeId,
			et.DescriptionDefault,
			et.Encrypt,
			et.SortOrder,
			CASE WHEN bet.ElementValue IS NULL THEN et.ElementValue ELSE bet.ElementValue END AS ElementValue
	FROM	ConnectorSettings_ElementType et
			LEFT JOIN ConnectorSettings_BusinessUnit bet ON et.ConnectorSettingsElementTypeId = bet.ConnectorSettingsElementTypeId
				AND bet.BusinessUnitGuid = @BusinessUnitGuid
	WHERE	et.ConnectorSettingsTypeId = @ConnectorSettingsTypeId
	ORDER BY et.SortOrder, et.DescriptionDefault;
END
GO
ALTER PROCEDURE [dbo].[spConnectorSettings_UpdateElementTypeValue]
	@BusinessUnitGuid uniqueidentifier,
	@ConnectorSettingsElementTypeId uniqueidentifier,
	@ElementValue nvarchar(max)
AS
BEGIN
	SET NOCOUNT ON

	IF @BusinessUnitGuid IS NULL
		SET @BusinessUnitGuid = (SELECT TOP 1 Business_Unit_Guid FROM Business_Unit);

	IF EXISTS(SELECT * 
				FROM	ConnectorSettings_BusinessUnit
				WHERE	BusinessUnitGuid = @BusinessUnitGuid
						AND ConnectorSettingsElementTypeId = @ConnectorSettingsElementTypeId)
	BEGIN
		UPDATE	ConnectorSettings_BusinessUnit
		SET		ElementValue = @ElementValue
		WHERE	BusinessUnitGuid = @BusinessUnitGuid
				AND ConnectorSettingsElementTypeId = @ConnectorSettingsElementTypeId;
	END
	ELSE
	BEGIN
		INSERT INTO ConnectorSettings_BusinessUnit(BusinessUnitGuid, ConnectorSettingsElementTypeId, ElementValue)
		VALUES (@BusinessUnitGuid, @ConnectorSettingsElementTypeId, @ElementValue);
	END
END
GO
CREATE TABLE dbo.Tmp_Category
	(
	Category_ID int NOT NULL IDENTITY (1, 1),
	BusinessUnitGuid uniqueidentifier NOT NULL,
	Name nvarchar(100) NULL
	) 
GO
ALTER TABLE dbo.Tmp_Category ADD CONSTRAINT
	Category_bu_pk PRIMARY KEY CLUSTERED 
	(
	Category_ID,
	BusinessUnitGuid
	) 
GO
SET IDENTITY_INSERT dbo.Tmp_Category ON
GO
IF EXISTS(SELECT * FROM dbo.Category)
	 INSERT INTO dbo.Tmp_Category (Category_ID, BusinessUnitGuid, Name)
	 SELECT cat.Category_ID, bu.Business_Unit_Guid, cat.Name 
	 FROM dbo.Category cat,
		  Business_Unit bu
	 WHERE bu.Name = 'Default'
GO
SET IDENTITY_INSERT dbo.Tmp_Category OFF
GO
DROP TABLE dbo.Category
GO
EXECUTE sp_rename N'dbo.Tmp_Category', N'Category', 'OBJECT' 
GO
ALTER procedure [dbo].[spTemplateGrp_CategoryList]
	@BusinessUnitGuid uniqueidentifier,
	@CategoryID int = 0
as
	SELECT	*
	FROM	Category
	WHERE	(@CategoryID = 0 OR Category_ID = @CategoryID)
			AND BusinessUnitGuid = @BusinessUnitGuid
	ORDER BY Name;
GO
ALTER procedure [dbo].[spTemplateGrp_UpdateCategory]
	@BusinessUnitGuid uniqueidentifier,
	@CategoryID int,
	@Name nvarchar(100),
	@NewID int output
as
	IF @CategoryID = 0
	begin
		INSERT INTO Category (BusinessUnitGuid, [Name]) 
		VALUES (@BusinessUnitGuid, @Name);

		select @NewID = @@identity;
	end
	ELSE
	begin
		UPDATE Category
		SET [Name] = @Name
		WHERE Category_ID = @CategoryID
	end
GO
CREATE procedure [dbo].[spDataSource_HasAccess]
	@DataObjectGuid varchar(40),
	@UserGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier
as
	SET ARITHABORT ON 

	SELECT 	TOP 1
		1
	FROM	Template
		INNER JOIN Template_Group ON Template_Group.Template_Guid = Template.Template_Guid
				OR Template_Group.Layout_Guid = Template.Template_Guid
		INNER JOIN Folder_Group ON Folder_Group.FolderGuid = Template_Group.Folder_Guid
		INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = Folder_Group.GroupGuid
	WHERE	Template.Business_Unit_GUID = @BusinessUnitGuid
		AND User_Group_Subscription.UserGuid = @UserGuid
		AND Project_Definition.exist('/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question[@DataObjectGuid=sql:variable("@DataObjectGuid")]') = 1
	
GO
CREATE TABLE dbo.Tmp_Custom_Field
	(
	BusinessUnitGuid uniqueidentifier NOT NULL,
	Custom_Field_ID int NOT NULL IDENTITY (1, 1),
	Title nvarchar(100) NOT NULL,
	Validation_Type int NOT NULL,
	Field_Length int NOT NULL,
	Location int NULL
	)
GO
ALTER TABLE dbo.Tmp_Custom_Field ADD CONSTRAINT
	PK_Custom_Field_Bu PRIMARY KEY NONCLUSTERED 
	(
	Custom_Field_ID
	)
GO
CREATE CLUSTERED INDEX IX_Custom_Field_BuLocationTitle ON dbo.Tmp_Custom_Field
	(
	BusinessUnitGuid,
	Location,
	Title
	)
GO
SET IDENTITY_INSERT dbo.Tmp_Custom_Field ON
GO
IF EXISTS(SELECT * FROM dbo.Custom_Field)
	 INSERT INTO dbo.Tmp_Custom_Field (BusinessUnitGuid, Custom_Field_ID, Title, Validation_Type, Field_Length, Location)
	 SELECT bu.Business_Unit_Guid, cf.Custom_Field_ID, cf.Title, cf.Validation_Type, cf.Field_Length, cf.Location 
	 FROM Custom_Field cf,
		  Business_Unit bu
	 WHERE bu.Name = 'Default'
GO
SET IDENTITY_INSERT dbo.Tmp_Custom_Field OFF
GO
DROP TABLE dbo.Custom_Field
GO
EXECUTE sp_rename N'dbo.Tmp_Custom_Field', N'Custom_Field', 'OBJECT' 
GO
ALTER procedure [dbo].[spCustomField_CustomFieldList]
	@BusinessUnitGuid uniqueidentifier,
	@CustomFieldID int = 0,
	@Location int = 0
AS
	SELECT *
	FROM Custom_Field
	WHERE (@CustomFieldID IS NULL OR @CustomFieldID = 0	OR Custom_Field_ID = @CustomFieldID)
		AND (@Location = 0 OR Location = @Location)
		AND (BusinessUnitGuid = @BusinessUnitGuid)
	ORDER BY Title;
GO
ALTER procedure [dbo].[spCustomField_UpdateCustomField]
	@BusinessUnitGuid uniqueidentifier,
	@CustomFieldID int = 0,
	@Title nvarchar(100),
	@ValidationType int,
	@FieldLength int,
	@Location int,
	@NewID int = 0 output
AS
	IF (@CustomFieldID IS NULL OR @CustomFieldID = 0)
	begin
		INSERT INTO Custom_Field (BusinessUnitGuid, Title, Validation_Type, Field_Length, Location)
		VALUES (@BusinessUnitGuid, @Title, @ValidationType, @FieldLength, @Location)
	end
	ELSE
	begin
		UPDATE Custom_Field
		SET Title = @Title,
			Validation_Type = @ValidationType,
			Field_Length = @FieldLength,
			Location = @Location
		WHERE Custom_Field_ID = @CustomFieldID
	end
GO
CREATE TABLE dbo.Tmp_Global_Options
	(
	BusinessUnitGuid uniqueidentifier NOT NULL,
	OptionCode nvarchar(255) NOT NULL,
	OptionDescription nvarchar(1000) NULL,
	OptionValue nvarchar(4000) NULL
	)
GO
ALTER TABLE dbo.Tmp_Global_Options ADD CONSTRAINT
	PK_Global_Options_Bu PRIMARY KEY CLUSTERED 
	(
	BusinessUnitGuid,
	OptionCode
	)
GO
IF EXISTS(SELECT * FROM dbo.Global_Options)
	 INSERT INTO dbo.Tmp_Global_Options (BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
	 SELECT DISTINCT bu.Business_Unit_Guid, o.OptionCode, o.OptionDescription, o.OptionValue 
	 FROM dbo.Global_Options o,
		  Business_Unit bu
GO
DROP TABLE dbo.Global_Options
GO
EXECUTE sp_rename N'dbo.Tmp_Global_Options', N'Global_Options', 'OBJECT' 
GO
INSERT INTO Global_Options(BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
SELECT TOP 1 '00000000-0000-0000-0000-000000000000', OptionCode, OptionDescription, OptionValue
FROM	Global_Options
WHERE	OptionCode = 'TEMP_DOC_FOLDER';

DELETE FROM Global_Options
WHERE	OptionCode = 'TEMP_DOC_FOLDER'
		AND BusinessUnitGuid <> '00000000-0000-0000-0000-000000000000';


INSERT INTO Global_Options(BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
SELECT TOP 1 '00000000-0000-0000-0000-000000000000', OptionCode, OptionDescription, OptionValue
FROM	Global_Options
WHERE	OptionCode = 'CLEANUP_HOURS';

DELETE FROM Global_Options
WHERE	OptionCode = 'CLEANUP_HOURS'
		AND BusinessUnitGuid <> '00000000-0000-0000-0000-000000000000';


INSERT INTO Global_Options(BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
SELECT TOP 1 '00000000-0000-0000-0000-000000000000', OptionCode, OptionDescription, OptionValue
FROM	Global_Options
WHERE	OptionCode = 'DOWNLOADABLE_DOC_NUM';

DELETE FROM Global_Options
WHERE	OptionCode = 'DOWNLOADABLE_DOC_NUM'
		AND BusinessUnitGuid <> '00000000-0000-0000-0000-000000000000';
GO
ALTER procedure [dbo].[spOptions_LoadOptions]
	@BusinessUnitGuid uniqueidentifier,
	@Code nvarchar(255)
as
	SELECT	*
	FROM	Global_Options
	where	@Code = optioncode
			AND (BusinessUnitGuid = '00000000-0000-0000-0000-000000000000' OR BusinessUnitGuid = @BusinessUnitGuid);
GO
ALTER procedure [dbo].[spOptions_UpdateOptionValue]
	@BusinessUnitGuid uniqueidentifier,
	@Code nvarchar(255),
	@Value nvarchar(4000)
as
	UPDATE	Global_Options
	SET		optionvalue = @Value
	WHERE	optioncode = @Code
			AND (BusinessUnitGuid = '00000000-0000-0000-0000-000000000000' OR BusinessUnitGuid = @BusinessUnitGuid);
GO
ALTER TABLE ConnectorSettings_Type
	ADD ModuleId nvarchar(4) null
GO
-- TIBCO
UPDATE	ConnectorSettings_Type
SET		ModuleId = '1320'
WHERE	ConnectorSettingsTypeId = '0DD71EA6-B004-4060-A01E-C36C5FEC18B5';

-- TRIM
UPDATE	ConnectorSettings_Type
SET		ModuleId = '4141'
WHERE	ConnectorSettingsTypeId = '2D1AEDFE-CA7C-47F0-9E5D-0C2F4ADF4F42';
GO
ALTER PROCEDURE [dbo].[spConnectorSettings_RegisterSettingsType]
	@Id uniqueidentifier,
	@Description nvarchar(255),
	@ModuleId nvarchar(4) = null
AS
	IF NOT EXISTS(SELECT * FROM  ConnectorSettings_Type WHERE ConnectorSettingsTypeId = @id)
	BEGIN
		INSERT INTO ConnectorSettings_Type(ConnectorSettingsTypeId, ConnectorSettingsDescription, ModuleId)
		VALUES	(@id, @Description, @ModuleId);
	END
GO
ALTER TABLE Routing_Type
	ADD ModuleId nvarchar(4) null
GO
-- TIBCO
UPDATE	Routing_Type
SET		ModuleId = '1320'
WHERE	RoutingTypeId = 'A10A339D-DA11-498F-BE2E-BE3874451E32';

-- Sharepoint
UPDATE	Routing_Type
SET		ModuleId = '6123'
WHERE	RoutingTypeId = 'FC27516C-019E-40D7-8DF8-37144D344269';

-- TRIM
UPDATE	Routing_Type
SET		ModuleId = '4141'
WHERE	RoutingTypeId = '98AC5B4E-B0C6-4D19-A06D-CBAEB904AEC3';
GO
ALTER PROCEDURE [dbo].[spRouting_RegisterType]
	@Id uniqueidentifier,
	@Description nvarchar(255),
	@ProviderType int,
	@RunForAllProjects bit,
	@SupportsRun bit,
	@SupportsUI bit,
	@SupportsRecurring bit,
	@ModuleId nvarchar(4)

AS
	IF NOT EXISTS(SELECT * FROM Routing_Type WHERE RoutingTypeId = @id)
	BEGIN
		INSERT INTO Routing_Type(RoutingTypeId, RoutingTypeDescription, ProviderType, RunForAllProjects, SupportsRun, SupportsUI, SupportsRecurring, ModuleId)
		VALUES	(@id, @Description, @ProviderType, @RunForAllProjects, @SupportsRun, @SupportsUI, @SupportsRecurring, @ModuleId);
	END
GO
ALTER PROCEDURE [dbo].[spJob_QueueList]
	@BusinessUnitGuid uniqueidentifier,
	@StartDate DateTime,
	@FinishDate DateTime,
	@CurrentStatus Int
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus,
			Template.Name as ProjectName, Intelledox_User.Username, 
			ProcessJob.LogGuid,
			CASE WHEN template_Log.Messages IS NOT NULL THEN 1 ELSE 0 END AS HasMessages
	FROM	ProcessJob
			INNER JOIN Intelledox_User ON ProcessJob.UserGuid = Intelledox_User.User_Guid
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
			LEFT JOIN Template_Log ON ProcessJob.LogGuid = Template_Log.Log_Guid
	WHERE	ProcessJob.DateStarted BETWEEN @StartDate AND @FinishDate
			AND ((@CurrentStatus = 0) OR 
				(@CurrentStatus = -1 AND ProcessJob.CurrentStatus <> 7) OR 
				(@CurrentStatus <> -1 AND ProcessJob.CurrentStatus = @CurrentStatus))
			AND Template.Business_Unit_Guid = @BusinessUnitGuid
	ORDER BY ProcessJob.DateStarted DESC;
GO
ALTER PROCEDURE [dbo].[spJob_JobDefinitionSearch]
	@BusinessUnitGuid uniqueidentifier,
	@Name nvarchar(200),
	@DateCreatedFrom datetime,
	@DateCreatedTo datetime,
	@NextRunFrom datetime,
	@NextRunTo datetime
AS
	SELECT	JobDefinition.*
	FROM	JobDefinition
			INNER JOIN Intelledox_User ON JobDefinition.OwnerGuid = Intelledox_User.User_Guid
	WHERE	(Name LIKE @Name + '%' OR @Name = '')
			AND (NextRunDate >= @NextRunFrom OR @NextRunFrom IS NULL)
			AND (NextRunDate < @NextRunTo OR @NextRunTo IS NULL)
			AND (DateCreated >= @DateCreatedFrom OR @DateCreatedFrom IS NULL)
			AND (DateCreated < @DateCreatedTo OR @DateCreatedTo IS NULL)
			AND Intelledox_User.Business_Unit_GUID = @BusinessUnitGuid
	ORDER BY Name;
GO
ALTER TABLE dbo.License_Key
	DROP CONSTRAINT DF_License_Key_IsProductKey
GO
CREATE TABLE dbo.Tmp_License_Key
	(
	BusinessUnitGuid uniqueidentifier NOT NULL,
	LicenseKeyId int NOT NULL IDENTITY (1, 1),
	LicenseKey varchar(1000) NOT NULL,
	IsProductKey bit NOT NULL
	)
GO
ALTER TABLE dbo.Tmp_License_Key ADD CONSTRAINT
	DF_License_Key_IsProductKey DEFAULT (0) FOR IsProductKey
GO
ALTER TABLE dbo.Tmp_License_Key ADD CONSTRAINT
	PK_License_Key_Bu PRIMARY KEY CLUSTERED 
	(
	LicenseKeyId
	)
GO
CREATE NONCLUSTERED INDEX IX_License_Key ON dbo.Tmp_License_Key
	(
	BusinessUnitGuid
	)
GO
SET IDENTITY_INSERT dbo.Tmp_License_Key ON
GO
IF EXISTS(SELECT * FROM dbo.License_Key)
	 INSERT INTO dbo.Tmp_License_Key (BusinessUnitGuid, LicenseKeyId, LicenseKey, IsProductKey)
	 SELECT bu.Business_Unit_GUID, LicenseKeyId, LicenseKey, CASE WHEN IsProductKey ='1' THEN 1 ELSE 0 END
	 FROM dbo.License_Key,
		Business_Unit bu
	WHERE bu.Name = 'Default'
GO
SET IDENTITY_INSERT dbo.Tmp_License_Key OFF
GO
DROP TABLE dbo.License_Key
GO
EXECUTE sp_rename N'dbo.Tmp_License_Key', N'License_Key', 'OBJECT' 
GO
-- Duplicate keys for other tenants with a new id
INSERT INTO dbo.License_Key (BusinessUnitGuid, LicenseKey, IsProductKey)
SELECT bu.Business_Unit_GUID, LicenseKey, CASE WHEN IsProductKey ='1' THEN 1 ELSE 0 END
FROM dbo.License_Key,
	Business_Unit bu
WHERE bu.Name <> 'Default'
GO
ALTER PROCEDURE [dbo].[spLicense_LicenseKeyList] 
	@BusinessUnitGuid uniqueidentifier,
	@LicenseKeyId int = 0
AS
BEGIN
	SET NOCOUNT ON;

	IF @LicenseKeyId = 0
	BEGIN
	    SELECT	* 
		FROM	License_Key
		WHERE	BusinessUnitGuid = @BusinessUnitGuid;
	END
	ELSE
	BEGIN
		SELECT	* 
		FROM	License_Key
		WHERE	LicenseKeyId = @LicenseKeyId;
	END
END
GO
ALTER PROCEDURE [dbo].[spLicense_UpdateLicenseKey] 
	@BusinessUnitGuid uniqueidentifier,
	@LicenseKeyId int output,
	@LicenseKey varchar(1000),
	@IsProductKey bit
AS
BEGIN
	SET NOCOUNT ON;
	
	IF @IsProductKey = 1 AND @LicenseKeyId = 0 AND 
		(select	count(*)
		 from	License_Key 
		 where	IsProductKey = 1
				and BusinessUnitGuid = @BusinessUnitGuid) > 0
	BEGIN
		SELECT	@LicenseKeyId = LicenseKeyId
		FROM	License_Key
		WHERE	IsProductKey = 1
				AND BusinessUnitGuid = @BusinessUnitGuid;
	END

	if @LicenseKeyId = 0
	begin
		if (select count(*) 
			from License_Key 
			where LicenseKey = @LicenseKey
					and BusinessUnitGuid = @BusinessUnitGuid) = 0
		begin
			if @IsProductKey = 1
				UPDATE	License_Key 
				SET		IsProductKey = 0
				WHERE	BusinessUnitGuid = @BusinessUnitGuid;

			insert into dbo.License_Key(BusinessUnitGuid, LicenseKey, IsProductKey)
			values (@BusinessUnitGuid, @LicenseKey, @IsProductKey);

			select @LicenseKeyId = @@IDENTITY;
		end
	end
	else
	begin
		if (select count(*) 
			from License_Key 
			where LicenseKey = @LicenseKey
				and BusinessUnitGuid = @BusinessUnitGuid) = 0
		begin
			if @IsProductKey = 1
				UPDATE	License_Key 
				SET		IsProductKey = 0
				WHERE	BusinessUnitGuid = @BusinessUnitGuid;

			UPDATE	License_Key
			SET		LicenseKey = @LicenseKey, IsProductKey = @IsProductKey
			WHERE	LicenseKeyId = @LicenseKeyId;
		end
	end
END
GO
ALTER procedure [dbo].[spSession_UserSessionList]
	@SessionGuid uniqueidentifier,
	@ErrorCode int output
as
	SELECT	User_Session.*, Intelledox_User.Business_Unit_Guid, Intelledox_User.User_ID
	FROM	User_Session
			INNER JOIN Intelledox_User ON User_Session.User_Guid = Intelledox_User.User_Guid
	WHERE	User_Session.Session_Guid = @SessionGuid
			AND Intelledox_User.Disabled = 0;
	
	set @ErrorCode = @@error;
GO

IF NOT EXISTS(SELECT * FROM Global_Options WHERE OptionCode = 'MINIMUM_PASSWORD_LENGTH')
BEGIN
	INSERT INTO Global_Options (BusinessUnitGuid,OptionCode,OptionDescription,OptionValue)
	SELECT bu.Business_Unit_Guid,'MINIMUM_PASSWORD_LENGTH','Minimum length of a user password','1'
	FROM Business_Unit bu
END

INSERT INTO Global_Options (BusinessUnitGuid,OptionCode,OptionDescription,OptionValue)
SELECT bu.Business_Unit_Guid,'MINIMUM_NUMERIC_CHARACTERS','Minimum number of numeric characters','0'
FROM Business_Unit bu

INSERT INTO Global_Options (BusinessUnitGuid,OptionCode,OptionDescription,OptionValue)
SELECT bu.Business_Unit_Guid,'ENFORCE_PASSWORD_HISTORY','Enforce password history','0'
FROM Business_Unit bu

INSERT INTO Global_Options (BusinessUnitGuid,OptionCode,OptionDescription,OptionValue)
SELECT bu.Business_Unit_GUID,'INVALID_PASSWORD_ATTEMPTS','Invalid password attempts','0'
FROM Business_Unit bu
GO
ALTER procedure [dbo].[spContent_UpdateContentItem]
	@ContentItemGuid uniqueidentifier,
	@Description nvarchar(1000),
	@Name nvarchar(255),
	@ContentTypeId Int,
	@BusinessUnitGuid uniqueidentifier,
	@ContentDataGuid uniqueidentifier,
	@SizeScale int,
	@Category int,
	@ProviderName nvarchar(50),
	@ReferenceId nvarchar(255),
	@IsIndexed bit,
	@FolderGuid uniqueidentifier
as
	DECLARE @Approvals nvarchar(10)
	DECLARE @CheckedFolderGuid uniqueidentifier
	
	SELECT @CheckedFolderGuid = FolderGuid
	FROM Content_Folder
	WHERE FolderGuid = @FolderGuid
	
	IF NOT EXISTS(SELECT * FROM Content_Item WHERE ContentItem_Guid = @ContentItemGuid)
	begin
		SELECT	@Approvals = OptionValue
		FROM	Global_Options
		WHERE	OptionCode = 'REQUIRE_CONTENT_APPROVAL'
				AND BusinessUnitGuid = @BusinessUnitGuid;
		
		INSERT INTO Content_Item (ContentItem_Guid, [Description], NameIdentity, ContentType_Id, Business_Unit_Guid, ContentData_Guid, SizeScale, Category, Provider_Name, Reference_Id, IsIndexed, Approved, FolderGuid)
		VALUES (@ContentItemGuid, @Description, @Name, @ContentTypeId, @BusinessUnitGuid, @ContentDataGuid, @SizeScale, @Category, @ProviderName, @ReferenceId, 0, CASE WHEN @Approvals = 'true' THEN 0 ELSE 2 END, @CheckedFolderGuid);
	end
	ELSE
		UPDATE Content_Item
		SET NameIdentity = @Name,
			[Description] = @Description,
			SizeScale = @SizeScale,
			ContentData_Guid = @ContentDataGuid,
			Category = @Category,
			Provider_Name = @ProviderName,
			Reference_Id = @ReferenceId,
			IsIndexed = @IsIndexed,
			FolderGuid = @CheckedFolderGuid
		WHERE ContentItem_Guid = @ContentItemGuid;
GO
ALTER PROCEDURE [dbo].[spLibrary_ClearExcessVersions]
	@ContentData_Guid uniqueidentifier,
	@IsBinary bit
AS	
	DECLARE @BusinessUnitGuid uniqueidentifier;

	SELECT	TOP 1 @BusinessUnitGuid = Business_Unit_Guid
	FROM	Content_Item
	WHERE	ContentData_Guid = @ContentData_Guid;

	If (@IsBinary = 1)
	BEGIN
		WHILE ((SELECT	COUNT(*) 
				FROM	ContentData_Binary_Version 
				WHERE	ContentData_Guid = @ContentData_Guid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
		BEGIN
			IF (SELECT	COUNT(*) 
				FROM	ContentData_Binary_Version 
				WHERE	ContentData_Guid = @ContentData_Guid
						AND Approved = 1) > 0
			BEGIN
				--Clear unapproved expired first
				DELETE FROM ContentData_Binary_Version
				WHERE ContentData_Version = 
						(SELECT MIN(ContentData_Version) 
						FROM	ContentData_Binary_Version 
						WHERE	ContentData_Guid = @ContentData_Guid
								AND Approved = 1)
					AND ContentData_Guid = @ContentData_Guid;
			END
			ELSE
			BEGIN
				--Clear Oldest
				DELETE FROM ContentData_Binary_Version
				WHERE ContentData_Version = 
						(SELECT MIN(ContentData_Version) 
						FROM	ContentData_Binary_Version 
						WHERE	ContentData_Guid = @ContentData_Guid)
					AND ContentData_Guid = @ContentData_Guid;
			END
		END
	END
	ELSE
	BEGIN
		WHILE ((SELECT	COUNT(*) 
				FROM	ContentData_Text_Version
				WHERE	ContentData_Guid = @ContentData_Guid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
		BEGIN
			IF (SELECT	COUNT(*) 
				FROM	ContentData_Text_Version 
				WHERE	ContentData_Guid = @ContentData_Guid
						AND Approved = 1) > 0
			BEGIN
				--Clear unapproved expired first
				DELETE FROM ContentData_Text_Version
				WHERE ContentData_Version = 
						(SELECT MIN(ContentData_Version) 
						FROM	ContentData_Text_Version 
						WHERE	ContentData_Guid = @ContentData_Guid
								AND Approved = 1)
					AND ContentData_Guid = @ContentData_Guid;
			END
			ELSE
			BEGIN
				--Clear Oldest
				DELETE FROM ContentData_Text_Version
				WHERE ContentData_Version = 
						(SELECT MIN(ContentData_Version) 
						FROM ContentData_Text_Version 
						WHERE ContentData_Guid = @ContentData_Guid)
					AND ContentData_Guid = @ContentData_Guid;
			END
		END
	END
GO
ALTER PROCEDURE [dbo].[spLibrary_UpdateBinary] (
	@UniqueId as uniqueidentifier,
	@ContentData as image,
	@Extension as varchar(5),
	@UserGuid as uniqueidentifier
)
AS
	DECLARE @ContentData_Guid uniqueidentifier;
	DECLARE @ContentItem_Guid uniqueidentifier;
	DECLARE @BusinessUnitGuid uniqueidentifier;
	DECLARE @Approvals nvarchar(10);
	DECLARE @MaxVersion int;
	DECLARE @CIApproved int;

	SET NOCOUNT ON;

	SELECT	@ContentData_Guid = ContentData_Guid, 
			@ContentItem_Guid = ContentItem_Guid,
			@BusinessUnitGuid = Business_Unit_Guid,
			@CIApproved = Approved
	FROM	Content_Item
	WHERE	ContentItem_Guid = @UniqueId;
	
	SELECT	@Approvals = OptionValue
	FROM	Global_Options
	WHERE	OptionCode = 'REQUIRE_CONTENT_APPROVAL'
			AND BusinessUnitGuid = @BusinessUnitGuid;


	IF (@Approvals = 'true')
	BEGIN
		IF @ContentData_Guid IS NULL OR NOT EXISTS(SELECT ContentData_Guid 
												FROM ContentData_Binary 
												WHERE	ContentData_Guid = @ContentData_Guid)
		BEGIN
			SET	@ContentData_Guid = newid();
			
			INSERT INTO ContentData_Binary(ContentData_Guid, ContentData, FileType, ContentData_Version, Modified_Date, Modified_By)
			VALUES (@ContentData_Guid, @ContentData, @Extension, 1, getUTCdate(), @UserGuid);

			UPDATE	Content_Item
			SET		ContentData_Guid = @ContentData_Guid,
					Approved = 0
			WHERE	ContentItem_Guid = @UniqueId;
		END
		ELSE
		BEGIN
			IF (@CIApproved = 0)
			BEGIN
				-- Content item hasnt been approved yet so we can replace it
				EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 1;
				
				UPDATE	ContentData_Binary
				SET		ContentData = @ContentData,
						FileType = @Extension,
						Modified_Date = getUTCdate(),
						Modified_By = @UserGuid,
						ContentData_Version = ContentData_Version + 1
				WHERE	ContentData_Guid = @ContentData_Guid;

				-- Expire old unapproved versions
				UPDATE	ContentData_Binary_Version
				SET		Approved = 1
				WHERE	ContentData_Guid = @ContentData_Guid
						AND Approved = 0;
			END
			ELSE
			BEGIN
				SELECT	@MaxVersion = MAX(ContentData_Version)
				FROM	(SELECT ContentData_Version
						FROM	ContentData_Binary_Version
						WHERE	ContentData_Guid = @ContentData_Guid
						UNION
						SELECT	ContentData_Version
						FROM	ContentData_Binary
						WHERE	ContentData_Guid = @ContentData_Guid) Versions

				-- Expire old unapproved versions
				UPDATE	ContentData_Binary_Version
				SET		Approved = 1
				WHERE	ContentData_Guid = @ContentData_Guid
						AND Approved = 0;
			
				-- Insert new unapproved version
				INSERT INTO ContentData_Binary_Version(ContentData_Guid, ContentData, FileType, ContentData_Version, Modified_Date, Modified_By, Approved)
				VALUES (@ContentData_Guid, @ContentData, @Extension, IsNull(@MaxVersion, 0) + 1, getUTCdate(), @UserGuid, 0);
			END
							
			EXEC spLibrary_ClearExcessVersions @ContentData_Guid, 1;
		END
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT ContentData_Guid FROM ContentData_Binary WHERE ContentData_Guid = @ContentData_Guid)
		BEGIN
			EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 1;
			
			UPDATE	ContentData_Binary
			SET		ContentData = @ContentData,
					FileType = @Extension
			WHERE	ContentData_Guid = @ContentData_Guid;
		END
		ELSE
		BEGIN
			IF @ContentItem_Guid IS NOT NULL
			BEGIN
				SET	@ContentData_Guid = newid();

				INSERT INTO ContentData_Binary(ContentData_Guid, ContentData, FileType, ContentData_Version)
				VALUES (@ContentData_Guid, @ContentData, @Extension, 0);

				UPDATE	Content_Item
				SET		ContentData_Guid = @ContentData_Guid
				WHERE	ContentItem_Guid = @UniqueId;
			END
		END
		
		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE	ContentData_Binary
			SET		Modified_Date = getUTCdate(),
					Modified_By = @UserGuid,
					ContentData_Version = ContentData_Version + 1
			WHERE	ContentData_Guid = @ContentData_Guid;
		END
	END

	DELETE	FROM Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItem_Guid;
	
	UPDATE	Content_Item
	SET		IsIndexed = 0
	WHERE	ContentItem_Guid = @ContentItem_Guid;
GO
ALTER PROCEDURE [dbo].[spLibrary_UpdateText] (
	@UniqueId as uniqueidentifier,
	@ContentData as nvarchar(max),
	@UserGuid as uniqueidentifier
)
AS
	DECLARE @ContentData_Guid uniqueidentifier;
	DECLARE @BusinessUnitGuid uniqueidentifier;
	DECLARE @Approvals nvarchar(10);
	DECLARE @MaxVersion int;

	SELECT	@ContentData_Guid = ContentData_Guid,
			@BusinessUnitGuid = Business_Unit_Guid
	FROM	Content_Item
	WHERE	ContentItem_Guid = @UniqueId
	
	SELECT	@Approvals = OptionValue
	FROM	Global_Options
	WHERE	OptionCode = 'REQUIRE_CONTENT_APPROVAL'
			AND BusinessUnitGuid = @BusinessUnitGuid;


	IF (@Approvals = 'true')
	BEGIN
		IF @ContentData_Guid IS NULL OR NOT EXISTS(SELECT ContentData_Guid 
												FROM ContentData_Text 
												WHERE	ContentData_Guid = @ContentData_Guid)
		BEGIN
			SET	@ContentData_Guid = newid();
			
			INSERT INTO ContentData_Text(ContentData_Guid, ContentData, ContentData_Version, Modified_Date, Modified_By)
			VALUES (@ContentData_Guid, @ContentData, 1, getUTCdate(), @UserGuid)

			UPDATE	Content_Item
			SET		ContentData_Guid = @ContentData_Guid,
					Approved = 0
			WHERE	ContentItem_Guid = @UniqueId;
		END
		ELSE
		BEGIN
			SELECT	@MaxVersion = MAX(ContentData_Version)
			FROM	(SELECT ContentData_Version
					FROM	ContentData_Text_Version
					WHERE	ContentData_Guid = @ContentData_Guid
					UNION
					SELECT	ContentData_Version
					FROM	ContentData_Text
					WHERE	ContentData_Guid = @ContentData_Guid) Versions

			-- Expire old unapproved versions
			UPDATE	ContentData_Text_Version
			SET		Approved = 1
			WHERE	ContentData_Guid = @ContentData_Guid
					AND Approved = 0;
		
			-- Insert new unapproved version
			INSERT INTO ContentData_Text_Version(ContentData_Guid, ContentData, ContentData_Version, Modified_Date, Modified_By, Approved)
			VALUES (@ContentData_Guid, @ContentData, IsNull(@MaxVersion, 0) + 1, getUTCdate(), @UserGuid, 0);
			
			EXEC spLibrary_ClearExcessVersions @ContentData_Guid, 0;
		END
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT ContentData_Guid FROM ContentData_Text WHERE ContentData_Guid = @ContentData_Guid)
		BEGIN
			EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 0;
			
			UPDATE	ContentData_Text
			SET		ContentData = @ContentData
			WHERE	ContentData_Guid = @ContentData_Guid
		END
		ELSE
		BEGIN
			SET	@ContentData_Guid = newid()

			INSERT INTO ContentData_Text(ContentData_Guid, ContentData, ContentData_Version)
			VALUES (@ContentData_Guid, @ContentData, 0)

			UPDATE	Content_Item
			SET		ContentData_Guid = @ContentData_Guid
			WHERE	ContentItem_Guid = @UniqueId
		END
		
		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE	ContentData_Text
			SET		Modified_Date = getUTCdate(),
					Modified_By = @UserGuid,
					ContentData_Version = ContentData_Version + 1
			WHERE	ContentData_Guid = @ContentData_Guid;
		END
	END
GO
DROP procedure [dbo].[spOptions_RemoveOption]
GO
DROP procedure [dbo].[spOptions_UpdateOption]
GO
ALTER procedure [dbo].[spProject_AddNewProjectVersion]
	@ProjectGuid uniqueidentifier,
	@NextVersion nvarchar(10)
AS
	BEGIN TRAN

		SET NOCOUNT ON

		DECLARE @BusinessUnitGuid uniqueidentifier;

		SELECT TOP 1 @BusinessUnitGuid = Business_Unit_Guid 
		FROM Template
		WHERE Template_Guid = @ProjectGuid;

		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Project_Definition,
			Comment,
			IsMajorVersion,
			FeatureFlags)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,
			Template.Modified_By,
			Template.Project_Definition,
			Template.Comment,
			Template.IsMajorVersion,
			Template.FeatureFlags
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File_Version (Template_Guid, File_Guid, Template_Version, [Binary],
				FormatTypeId)
		SELECT	Template.Template_Guid, Template_File.File_Guid, Template.Template_Version, 
				Template_File.[Binary], Template_File.FormatTypeId
		FROM	Template
				INNER JOIN Template_File ON Template.Template_Guid = Template_File.Template_Guid
		WHERE	Template.Template_Guid = @ProjectGuid;
		
		--delete the earliest minor version which does not belong to the next version number
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
						AND (FLOOR(vwTemplateVersion.Template_Version) < FLOOR(@NextVersion))) > 0)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version 
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
						AND (FLOOR(vwTemplateVersion.Template_Version) < FLOOR(@NextVersion))
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END
			
		--otherwise	
		--delete earliest major version, leaving at least one major version untouched			
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 1) > 1)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 1
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END

		--otherwise
		--delete the earliest left minor version
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0) > 0)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END
				
		DELETE FROM Template_File_Version
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	Template_Version
					WHERE	Template_Guid = @ProjectGuid);
	COMMIT
GO
ALTER procedure [dbo].[spProject_RestoreVersion]
	@ProjectGuid uniqueidentifier,
	@VersionNumber nvarchar(10),
	@UserGuid uniqueidentifier,
	@RestoreVersionComment nvarchar(50),
	@NextVersion nvarchar(10)
as
	SET NOCOUNT ON

	BEGIN TRAN	
		DECLARE @BusinessUnitGuid uniqueidentifier;

		SELECT TOP 1 @BusinessUnitGuid = Business_Unit_Guid 
		FROM Template
		WHERE Template_Guid = @ProjectGuid;
	
		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Project_Definition,
			Comment,
			IsMajorVersion,
			FeatureFlags)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,	
			Template.Modified_By,
			Template.Project_Definition,
			Template.Comment,
			Template.IsMajorVersion,
			Template.FeatureFlags
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
			
		INSERT INTO Template_File_Version (Template_Guid, File_Guid, Template_Version, [Binary],
				FormatTypeId)
		SELECT	Template.Template_Guid, Template_File.File_Guid, Template.Template_Version, 
				Template_File.[Binary], Template_File.FormatTypeId
		FROM	Template
				INNER JOIN Template_File ON Template.Template_Guid = Template_File.Template_Guid
		WHERE	Template.Template_Guid = @ProjectGuid;
					
		DECLARE @ProjectDefinition xml,
				@FeatureFlags int

		SELECT	@ProjectDefinition = Project_Definition,
				@FeatureFlags = FeatureFlags
		FROM	Template_Version 
		WHERE	Template_Guid = @ProjectGuid 
				AND Template_Version = @VersionNumber

		UPDATE	Template
		SET		Project_Definition = @ProjectDefinition, 
				Template_Version = @NextVersion, 
				Comment = @RestoreVersionComment,
				Modified_Date = GetUTCdate(),
				Modified_By = @UserGuid,
				IsMajorVersion = 1,
				FeatureFlags = @FeatureFlags
		WHERE	Template_Guid = @ProjectGuid;
		
		DELETE FROM Template_File
		WHERE	Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File(Template_Guid, File_Guid, [Binary], FormatTypeId)
		SELECT	@ProjectGuid, Template_File_Version.File_Guid, Template_File_Version.[Binary],
				Template_File_Version.FormatTypeId
		FROM	Template_File_Version 
		WHERE	Template_Guid = @ProjectGuid 
				AND Template_Version = @VersionNumber; 
				
		--delete the earliest minor version which does not belong to the next version number
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
						AND (FLOOR(vwTemplateVersion.Template_Version) < FLOOR(@NextVersion))) > 0)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version 
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
						AND (FLOOR(vwTemplateVersion.Template_Version) < FLOOR(@NextVersion))
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END
			
		--otherwise	
		--delete earliest major version, leaving at least one major version untouched			
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 1) > 1)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 1
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END

		--otherwise
		--delete the earliest left minor version
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0) > 0)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END
			
		DELETE FROM Template_File_Version
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	Template_Version
					WHERE	Template_Guid = @ProjectGuid);
				
	COMMIT
GO
ALTER procedure [dbo].[spContent_ContentItemList]
	@ItemGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier,
	@ExactMatch bit,
	@ContentTypeId int,
	@Name NVarChar(255),
	@Description NVarChar(1000),
	@Category int,
	@Approved int = 2,
	@ErrorCode int output,
	@FolderGuid uniqueidentifier,
	@UserId uniqueidentifier,
	@NoFolder bit,
	@MinimalGet bit
as
	IF @ItemGuid is null 
	BEGIN
		UPDATE Content_Item
		SET Approved = 1
		WHERE ExpiryDate < GETDATE()
			AND Approved = 0;
		
		IF @ExactMatch = 1
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
								INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit,
					ci.FolderGuid,
					Content_Folder.FolderName
					
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity = @Name
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
			ORDER BY ci.NameIdentity;
		ELSE
			SELECT DISTINCT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
								INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit,
					ci.FolderGuid,
					Content_Folder.FolderName
					
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
						
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity LIKE '%' + @Name + '%'
					AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND ci.Description LIKE '%' + @Description + '%'
					AND (@Category = 0 or ci.Category = @Category)
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
					AND ((@NoFolder = 0 AND (@FolderGuid IS NULL OR ci.FolderGuid = @FolderGuid))
						OR (@NoFolder = 1 AND ci.FolderGuid IS NULL))
			ORDER BY ci.ContentType_Id,
					ci.NameIdentity;
	END
	ELSE
	BEGIN
		UPDATE	Content_Item
		SET		Approved = 1
		WHERE	ExpiryDate < GETDATE()
				AND Approved = 0
				AND contentitem_guid = @ItemGuid;
		
		IF (@MinimalGet = 1)
		BEGIN
			SELECT	ci.*, 
					'' as FileType, 
					NULL as Modified_Date, 
					'' as UserName,
					0 as HasUnapprovedRevision,
					0 as CanEdit,
					Content_Folder.FolderName						
			FROM	content_item ci
				LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
			WHERE	ci.contentitem_guid = @ItemGuid;
		END
		ELSE
		BEGIN
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
								INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit,
					Content_Folder.FolderName
						
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
						
			WHERE	ci.contentitem_guid = @ItemGuid;
		END
	END
	
	set @ErrorCode = @@error;
GO
ALTER procedure [dbo].[spContent_ContentItemListFullText]
	@ItemGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier,
	@ExactMatch bit,
	@ContentTypeId int,
	@Name NVarChar(255),
	@Description NVarChar(1000),
	@Category int,
	@FullText NVarChar(1000),
	@Approved int = 2,
	@ErrorCode int output,
	@FolderGuid uniqueidentifier,
	@UserId uniqueidentifier,
	@NoFolder bit
as

	UPDATE Content_Item
	SET Approved = 1
	WHERE ExpiryDate < GETDATE()
		AND Approved = 0;

	IF @ItemGuid is null 
		IF @ExactMatch = 1
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
								INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit,
					Content_Folder.FolderName
					
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity = @Name
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
			ORDER BY ci.NameIdentity;
		ELSE
			--Full text search
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
								INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit,
					Content_Folder.FolderName
					
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity LIKE '%' + @Name + '%'
					AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND ci.Description LIKE '%' + @Description + '%'
					AND (@Category = 0 or ci.Category = @Category)
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
					AND (ci.ContentData_Guid IN (
							SELECT	ContentData_Guid
							FROM	ContentData_Binary cdb
							WHERE	Contains(*, @FullText)
							)
						OR
						ci.ContentData_Guid IN (
							SELECT	ContentData_Guid
							FROM	ContentData_Text cdt
							WHERE	Contains(*, @FullText)
							)
						)
					AND ((@NoFolder = 0 AND (@FolderGuid IS NULL OR ci.FolderGuid = @FolderGuid))
						OR (@NoFolder = 1 AND ci.FolderGuid IS NULL))
			ORDER BY ci.NameIdentity;
	ELSE
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Intelledox_User.UserName,
				CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
				CASE WHEN (@UserId IS NULL 
					OR ci.FolderGuid IS NULL 
					OR (NOT EXISTS (
						SELECT * 
						FROM Content_Folder_Group 
						WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
					OR EXISTS (
						SELECT * 
						FROM Content_Folder_Group
							INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
							INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
							INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
						WHERE Intelledox_User.User_Guid = @UserId
							AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
				THEN 1 ELSE 0 END
				AS CanEdit,
				Content_Folder.FolderName
					
		FROM	content_item ci
				LEFT JOIN (
					SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
					FROM	ContentData_Binary
					UNION
					SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
					FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
				LEFT JOIN (
					SELECT	ContentData_Guid
					FROM	vwContentItemVersionDetails
					WHERE	Approved = 0
					) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
				LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
		WHERE	ci.contentitem_guid = @ItemGuid;
	
	set @ErrorCode = @@error;
GO
ALTER procedure [dbo].[spUsers_UserData]
	@BusinessUnitGUID uniqueidentifier,
	@Username nvarchar(50) = '',
	@UserGroupID int = 0,
	@ShowActive int = 0,
	@ErrorCode int = 0 output
as
	SET NOCOUNT ON;

	DECLARE @ColNames nvarchar(MAX);
	
	-- Find the Custom_Fields
	-- Will look like "[CustomField1],[CustomField2],[Custom_Field."
	SET @ColNames = '[' + (
		SELECT Title + '],[' 
		FROM Custom_Field 
		WHERE Validation_Type <> 3
			AND BusinessUnitGUID = @BusinessUnitGUID
		FOR XML PATH('')) ;
	-- Cut off the final ",["
	SET @ColNames = SUBSTRING(@ColNames, 1, LEN(@ColNames)-2);
	SET @Username = REPLACE(@Username, '''', '''''');
	
	DECLARE @SQL nvarchar(MAX);
	SET @SQL = 'SELECT Username, 
			First_Name,
			Last_Name,
			SelectedTheme,
			Inactive,
			Full_Name,
			Salutation_Name,
			Title,
			Organisation_Name,
			Phone_Number,
			Fax_Number,
			Email_Address,
			Street_Address_1,
			Street_Address_2,
			Street_Address_Suburb,
			Street_Address_State,
			Street_Address_Postcode,
			Street_Address_Country,
			Postal_Address_1,
			Postal_Address_2,
			Postal_Address_Suburb,
			Postal_Address_State,
			Postal_Address_Postcode,
			Postal_Address_Country 
			' + IsNull(',' + @ColNames, '') + ' 
		FROM (
			SELECT Intelledox_User.Username, 
				Intelledox_User.SelectedTheme,
				Intelledox_User.[Disabled] As Inactive,
				Address_Book.First_Name,
				Address_Book.Last_Name,
				Address_Book.Full_Name,
				Address_Book.Salutation_Name,
				Address_Book.Title,
				Address_Book.Organisation_Name,
				Address_Book.Phone_Number,
				Address_Book.Fax_Number,
				Address_Book.Email_Address,
				Address_Book.Street_Address_1,
				Address_Book.Street_Address_2,
				Address_Book.Street_Address_Suburb,
				Address_Book.Street_Address_State,
				Address_Book.Street_Address_Postcode,
				Address_Book.Street_Address_Country,
				Address_Book.Postal_Address_1,
				Address_Book.Postal_Address_2,
				Address_Book.Postal_Address_Suburb,
				Address_Book.Postal_Address_State,
				Address_Book.Postal_Address_Postcode,
				Address_Book.Postal_Address_Country, 
				Custom_Field.Title As CustomFieldTitle,
				ISNULL(Address_Book_Custom_Field.Custom_Value, '''') AS Custom_Value
			FROM Intelledox_User
				LEFT JOIN User_Group_Subscription ON Intelledox_User.[User_Guid] = User_Group_Subscription.[UserGuid]
				LEFT JOIN User_Group ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
				LEFT JOIN Address_Book ON Intelledox_User.[Address_ID] = Address_Book.[Address_ID] 
				LEFT JOIN Address_Book_Custom_Field ON Address_Book.Address_ID = Address_Book_Custom_Field.Address_ID
				LEFT JOIN Custom_Field ON Address_Book_Custom_Field.Custom_Field_ID = Custom_Field.Custom_Field_ID
					AND Custom_Field.Validation_Type <> 3
			WHERE (''' + @Username + ''' = '''' OR Intelledox_User.Username LIKE ''' + @Username + '%'')
				AND Intelledox_User.Business_Unit_GUID = CONVERT(uniqueidentifier, ''' + CONVERT(nvarchar(50), @BusinessUnitGUID) + ''')
				AND	(' + CONVERT(varchar, @UserGroupID) + ' = 0 
					OR User_Group.User_Group_ID = ' + CONVERT(varchar, @UserGroupID) + '
					OR (' + CONVERT(varchar, @UserGroupID) + ' = -1 AND User_Group.User_Group_ID IS NULL))
				AND (' + CONVERT(varchar, @ShowActive) + ' = 0 
					OR (' + CONVERT(varchar, @ShowActive) + ' = 1 AND Intelledox_User.[Disabled] = 0)
					OR (' + CONVERT(varchar, @ShowActive) + ' = 2 AND Intelledox_User.[Disabled] = 1))
				
			GROUP BY Intelledox_User.Username, 
				Intelledox_User.SelectedTheme,
				Intelledox_User.[Disabled],
				Address_Book.First_Name,
				Address_Book.Last_Name,
				Address_Book.Full_Name,
				Address_Book.Salutation_Name,
				Address_Book.Title,
				Address_Book.Organisation_Name,
				Address_Book.Phone_Number,
				Address_Book.Fax_Number,
				Address_Book.Email_Address,
				Address_Book.Street_Address_1,
				Address_Book.Street_Address_2,
				Address_Book.Street_Address_Suburb,
				Address_Book.Street_Address_State,
				Address_Book.Street_Address_Postcode,
				Address_Book.Street_Address_Country,
				Address_Book.Postal_Address_1,
				Address_Book.Postal_Address_2,
				Address_Book.Postal_Address_Suburb,
				Address_Book.Postal_Address_State,
				Address_Book.Postal_Address_Postcode,
				Address_Book.Postal_Address_Country, 
				Custom_Field.Title,
				ISNULL(Address_Book_Custom_Field.Custom_Value, '''')
			) Data
			' + IsNull('PIVOT (MAX(Custom_Value) FOR CustomFieldTitle IN (' + @ColNames + ')) AS PivotedData', '') + 
			' ORDER BY Username';
		
	EXECUTE sp_executesql @SQL;
 
	SET @ErrorCode = @@error;
GO
ALTER TABLE dbo.Intelledox_User
	ADD IsGuest bit DEFAULT 0 NOT NULL;
GO
ALTER procedure [dbo].[spUsers_UpdateUser]
	@UserID int,
	@Username nvarchar(50),
	@Password nvarchar(1000),
	@NewID int = 0 output,
	@WinNT_User bit,
	@BusinessUnitGUID uniqueidentifier,
	@User_GUID uniqueidentifier,
	@SelectedTheme nvarchar(100),
	@ChangePassword int,
	@PasswordSalt nvarchar(128),
	@PasswordFormat int,
	@Disabled int,
	@Address_Id int,
	@Timezone nvarchar(50),
	@Culture nvarchar(11),
	@Language nvarchar(11),
	@IsGuest bit = 0,
	@ErrorCode int = 0 output
as
	if @UserID = 0 OR @UserID IS NULL
	begin
		INSERT INTO Intelledox_User(Username, PwdHash, WinNT_User, Business_Unit_GUID, User_Guid, SelectedTheme, 
				ChangePassword, PwdSalt, PwdFormat, [Disabled], Address_ID, Timezone, Culture, Language, IsGuest)
		VALUES (@Username, @Password, @WinNT_User, @BusinessUnitGUID, @User_Guid, @SelectedTheme, 
				@ChangePassword, @PasswordSalt, @PasswordFormat, @Disabled, @Address_Id, @Timezone, @Culture, @Language, @IsGuest);
		
		select @NewID = @@identity;

		INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
		SELECT	@User_Guid, User_Group.Group_Guid, 0
		FROM	User_Group
		WHERE	User_Group.AutoAssignment = 1
				AND Business_Unit_Guid = @BusinessUnitGUID;
	end
	else
	begin
		UPDATE Intelledox_User
		SET Username = @Username,  
			PwdHash = @Password, 
			WinNT_User = @WinNT_User,
			SelectedTheme = @SelectedTheme,
			ChangePassword = @ChangePassword,
			PwdSalt = @PasswordSalt,
			PwdFormat = @PasswordFormat,
			[Disabled] = @Disabled,
			Timezone = @Timezone,
			Culture = @Culture,
			Language = @Language,
			Address_ID = @Address_Id
		WHERE [User_ID] = @UserID;
	end

	set @ErrorCode = @@error;
GO
DROP procedure [dbo].[spAddBk_AddressTypeList]
GO
DROP procedure [dbo].[spAddBk_RemoveAddressType]
GO
DROP procedure [dbo].[spAddBk_UpdateAddressType]
GO
EXEC sp_rename 'dbo.Address_Type', 'zzAddress_Type'
GO
DROP procedure [dbo].[spTemplateGrp_UpdateFolder]
GO
DROP procedure [dbo].[spUsers_UserGroupUsers]
GO
DROP procedure [dbo].[spTemplate_TemplateFormatList]
GO
EXEC sp_rename 'dbo.Format_Type', 'zzFormat_Type'
GO

--Changed where clause to 'AND (a.Business_Unit_GUID = @BusinessUnitGUID)'
ALTER PROCEDURE [dbo].[spUsers_UserGroupByUser]
	-- Add the parameters for the stored procedure here
	@UserID int,
	@BusinessUnitGUID uniqueidentifier,
	@Username nvarchar(50) = '',
	@UserGroupID int = 0,
	@UserGuid uniqueidentifier = null,
	@ShowActive int = 0,
	@ErrorCode int = 0 output,
	@Firstname nvarchar(50) = '',
	@Lastname nvarchar(50) = ''
AS
BEGIN
	if @UserGroupID = 0	--all user groups
	begin
		if @UserGuid is null
		begin
			if @UserID is null or @UserID = 0
			begin
				select	a.*, Business_Unit.DefaultLanguage
				from	Intelledox_User a
					left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
					left join Address_Book d on a.Address_ID = d.Address_ID
				where	(@Username = '' OR @Username is null OR a.[Username] like + @Username + '%')
					AND (@Firstname = '' OR @Firstname is null OR d.[First_Name] like + '%' + @Firstname + '%')
					AND (@Lastname = '' or @Lastname is null or d.[Last_Name] like + '%' + @Lastname + '%')
					AND (a.Business_Unit_GUID = @BusinessUnitGUID)
					AND (@ShowActive = 0 
						OR (@ShowActive = 1 AND a.[Disabled] = 0)
						OR (@ShowActive = 2 AND a.[Disabled] = 1))
				ORDER BY a.[Username]
			end
			else
			begin
				select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
				from	Intelledox_User a
					left join User_Group_Subscription c on a.User_Guid = c.UserGuid
					left join User_Group b on c.GroupGuid = b.Group_Guid
					left join Address_Book d on a.Address_Id = d.Address_id
					left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
				where	(a.[User_ID] = @UserID)
					AND (@ShowActive = 0 
						OR (@ShowActive = 1 AND a.[Disabled] = 0)
						OR (@ShowActive = 2 AND a.[Disabled] = 1))
				ORDER BY a.[Username]
			end
		end
		else
		begin
			select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
			from	Intelledox_User a
				left join User_Group_Subscription c on a.User_Guid = c.UserGuid
				left join User_Group b on c.GroupGuid = b.Group_Guid
				left join Address_Book d on a.Address_Id = d.Address_id
				left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			where	(User_Guid = @UserGuid)
				AND (@ShowActive = 0 
					OR (@ShowActive = 1 AND a.[Disabled] = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1))
			ORDER BY a.[Username]
		end
	end
	else
	begin
		if @UserGroupID = -1	--users with no user groups
		begin
			select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
			from	Intelledox_User a
				left join User_Group_Subscription c on a.User_Guid = c.UserGuid
				left join User_Group b on c.GroupGuid = b.Group_Guid
				left join Address_Book d on a.Address_Id = d.Address_id
				left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			where	(@UserID = 0 OR @UserID IS NULL OR a.[User_ID] = @UserID)
				AND	(@Username = '' OR @Username is null OR a.[Username] like + @Username + '%')
				AND (@Firstname = '' OR @Firstname is null OR d.[First_Name] like + '%' + @Firstname + '%')
				AND (@Lastname = '' or @Lastname is null or d.[Last_Name] like + '%' + @Lastname + '%')
				AND	a.User_Guid not in (
						select a.userGuid
						from user_group_subscription a 
						inner join user_Group b on a.GroupGuid = b.Group_Guid
					)
				AND (a.Business_Unit_GUID = @BusinessUnitGUID)
				AND (@ShowActive = 0 
					OR (@ShowActive = 1 AND a.[Disabled] = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1))
			ORDER BY a.[Username]
		end
		else			--users in specified user group
		begin
			select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
			from	Intelledox_User a
				left join User_Group_Subscription c on a.User_Guid = c.UserGuid
				left join User_Group b on c.GroupGuid = b.Group_Guid
				left join Address_Book d on a.Address_Id = d.Address_id
				left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			where	(@UserID = 0 OR @UserID IS NULL OR a.[User_ID] = @UserID)
				AND	(@Username = '' OR @Username is null OR a.[Username] like + @Username + '%')
				AND (@Firstname = '' OR @Firstname is null OR d.[First_Name] like + '%' + @Firstname + '%')
				AND (@Lastname = '' or @Lastname is null or d.[Last_Name] like + '%' + @Lastname + '%')
				AND	c.GroupGuid = (SELECT Group_Guid FROM User_Group WHERE User_Group_id = @UserGroupID)
				AND (a.Business_Unit_GUID = @BusinessUnitGUID)
				AND (@ShowActive = 0 
					OR (@ShowActive = 1 AND a.[Disabled] = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1))
			ORDER BY a.[Username]
		end
	end

	set @ErrorCode = @@error;

END
GO

--Remove TemplateGuid = null as default and removed a whole segment catering to a null TemplateGuid
ALTER procedure [dbo].[spTemplate_TemplateList]
	@TemplateGuid uniqueidentifier,
	@ErrorCode int output
AS
	SET NOCOUNT ON
	
	SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, 
			a.template_guid, b.Category_ID, 
			b.[Name] as Category_Name, a.Supplier_Guid, a.Business_Unit_Guid,
			a.Content_Bookmark, a.HelpText, a.Modified_Date, Intelledox_User.Username,
			a.[name] as Project_Name, a.Modified_By, lockedByUser.Username AS LockedBy, a.Comment, 
			a.Template_Version, a.FeatureFlags
	FROM	Template a
			left join Template_Category c on a.Template_ID = c.Template_ID
			left join Category b on c.Category_ID = b.Category_ID
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
			LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
	WHERE	a.Template_Guid = @TemplateGuid
	ORDER BY a.[Name];

	set @ErrorCode = @@error;

GO

--Removed select * from user_signoff
ALTER procedure [dbo].[spSignoff_SignoffList]
	@SignoffID int = 0,
	@UserID int = 0,
	@ErrorCode int output
as
	IF @SignoffID = 0 OR @SignoffID IS NULL 
		SELECT * FROM user_signoff WHERE [user_id] = @UserID
	ELSE
		SELECT * FROM user_signoff WHERE signoff_id = @SignoffID

	set @ErrorCode = @@error
GO
ALTER procedure [dbo].[spProject_GetInUseProjectLicenseCount]
	@BusinessUnitGuid uniqueidentifier,
	@Anonymous bit,
	@ErrorCode int = 0 output
AS

BEGIN

	SELECT COUNT(DISTINCT Template_Guid) 
	FROM Template_Group
	INNER JOIN Folder_Group ON Template_Group.Folder_Guid = Folder_Group.FolderGuid 
	INNER JOIN User_Group_Subscription ON Folder_Group.GroupGuid = User_Group_Subscription.GroupGuid
	INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
	WHERE Intelledox_User.IsGuest = @Anonymous
		AND [Disabled] = 0 AND Business_Unit_GUID = @BusinessUnitGuid;

	SET @ErrorCode = @@ERROR;
	
END
GO

UPDATE dbo.Intelledox_User
SET IsGuest=1
WHERE [user_id] = -1
GO

ALTER procedure [dbo].[spProject_GetProjectCount]
	@FolderGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@Anonymous bit,
	@ErrorCode int = 0 output
AS

	DECLARE @ProjectAllCount int,
			@ProjectCount int
	
BEGIN

	SELECT @ProjectAllCount = COUNT(DISTINCT Template_Guid)
	FROM Template_Group
	LEFT JOIN Folder_Group ON Template_Group.Folder_Guid = Folder_Group.FolderGuid 
	WHERE (Folder_Guid = @FolderGuid OR @FolderGuid IS NULL) 
		AND (GroupGuid = @GroupGuid OR @GroupGuid IS NULL);

	SELECT @ProjectCount = COUNT(DISTINCT Template_Guid)
	FROM Template_Group
	INNER JOIN Folder_Group ON Template_Group.Folder_Guid = Folder_Group.FolderGuid 
	INNER JOIN User_Group_Subscription ON Folder_Group.GroupGuid = User_Group_Subscription.GroupGuid
	INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
	WHERE Template_Guid IN 
		(SELECT Template_Guid 
			FROM Template_Group
			LEFT JOIN Folder_Group ON Template_Group.Folder_Guid = Folder_Group.FolderGuid 
			WHERE (Folder_Guid = @FolderGuid OR @FolderGuid IS NULL) 
				AND (GroupGuid = @GroupGuid OR @GroupGuid IS NULL)) 
	AND Intelledox_User.IsGuest = @Anonymous
	AND [Disabled] = 0;
		
	SELECT @ProjectAllCount - @ProjectCount;

	SET @ErrorCode = @@ERROR;
	
END
GO
ALTER PROCEDURE [dbo].[spUsers_UserCountByFolder]
	@FolderGuid uniqueidentifier = null,
	@Anonymous bit,
	@ErrorCode int = 0 output
	
AS

BEGIN

	SELECT COUNT(Intelledox_User.User_Guid) 
	FROM Folder_Group
	INNER JOIN User_Group_Subscription ON Folder_Group.GroupGuid = User_Group_Subscription.GroupGuid
	INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
	WHERE FolderGuid = @FolderGuid
	AND Intelledox_User.IsGuest = @Anonymous
	AND [Disabled] = 0;

	SET @ErrorCode = @@ERROR;
	
END
GO
ALTER PROCEDURE [dbo].[spUsers_UserCountByGroup]
	@GroupGuid uniqueidentifier = null,
	@Anonymous bit,
	@ErrorCode int = 0 output
	
AS

BEGIN

	SELECT COUNT(Intelledox_User.User_Guid)
	FROM User_Group_Subscription
	INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
	WHERE GroupGuid = @GroupGuid
	AND Intelledox_User.IsGuest = @Anonymous
	AND [Disabled] = 0;

	SET @ErrorCode = @@ERROR;
	
END
GO
ALTER PROCEDURE [dbo].[spUsers_UserCountByProject]
	@ProjectGuid uniqueidentifier = null,
	@Anonymous bit,
	@ErrorCode int = 0 output
	
AS

BEGIN

	SELECT COUNT(Intelledox_User.User_Guid) 
	FROM Template_Group
	INNER JOIN Folder_Group ON Template_Group.Folder_Guid = Folder_Group.FolderGuid 
	INNER JOIN User_Group_Subscription ON Folder_Group.GroupGuid = User_Group_Subscription.GroupGuid
	INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
	WHERE Template_Guid = @ProjectGuid
	AND Intelledox_User.IsGuest = @Anonymous
	AND [Disabled] = 0;

	SET @ErrorCode = @@ERROR;
	
END
GO
DROP PROC spTemplateGrp_SubscribeCategory
GO
DROP PROC spTemplateGrp_UnsubscribeCategory
GO
DROP PROC spProjectGrp_ProjectCategoryList
GO
ALTER procedure [dbo].[spTemplate_RemoveTemplate]
	@TemplateGuid uniqueidentifier,
	@OnlyChildInfo bit
as
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
	
	DELETE	Template_Version
	WHERE	Template_Guid = @TemplateGuid;
GO
ALTER procedure [dbo].[spTemplate_TemplateList]
	@TemplateGuid uniqueidentifier,
	@ErrorCode int output
AS
	SET NOCOUNT ON
	
	SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, 
			a.template_guid, a.Supplier_Guid, a.Business_Unit_Guid,
			a.Content_Bookmark, a.HelpText, a.Modified_Date, Intelledox_User.Username,
			a.[name] as Project_Name, a.Modified_By, lockedByUser.Username AS LockedBy, a.Comment, 
			a.Template_Version, a.FeatureFlags
	FROM	Template a
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
			LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
	WHERE	a.Template_Guid = @TemplateGuid;

	set @ErrorCode = @@error;

GO
EXECUTE sp_rename N'dbo.Template_Category', N'zzTemplate_Category', 'OBJECT'
GO
CREATE TABLE [dbo].[AuditLog](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[DateCreatedUtc] [datetime] NULL,
	[IPAddress] [nvarchar](50) NULL,
	[Event] [nvarchar](max) NULL,
	[UserGuid] [uniqueidentifier] NULL,
	[UserName] [nvarchar](50) NULL,
	[ExtraDetails] [nvarchar](max) NULL
)
GO
ALTER TABLE dbo.AuditLog ADD CONSTRAINT
	PK_AuditLog PRIMARY KEY CLUSTERED 
	(
	ID
	) 
GO
INSERT INTO Global_Options (BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
VALUES ('00000000-0000-0000-0000-000000000000', 'ENABLE_AUDITING', 'Enable Auditing', 'false');
GO



