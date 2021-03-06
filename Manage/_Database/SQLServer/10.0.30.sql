truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.30');
go

ALTER TABLE ConnectorSettings_ElementType
	ADD Obfuscate bit NOT NULL CONSTRAINT DF_ConnectorSettings_ElementType_Obfuscate DEFAULT 0
GO
ALTER TABLE ConnectorSettings_BusinessUnit
	ADD EncryptedElementValue varbinary(MAX) NULL
GO
UPDATE ConnectorSettings_ElementType
SET Obfuscate = ISNULL(Encrypt, 0)
GO
UPDATE ConnectorSettings_ElementType
SET Encrypt = 0
GO
UPDATE ConnectorSettings_ElementType
SET Encrypt = 1
WHERE ConnectorSettingsElementTypeId = '854E3346-2B9C-4C23-9C92-BBA089DAF6FA'
	OR ConnectorSettingsElementTypeId = '1ADAC843-D5C6-4843-B2FB-AFA7B23ACEDC'
	OR ConnectorSettingsElementTypeId = '307FD009-6329-4A8A-BD4B-DAF223C9B383';
GO
ALTER TABLE ConnectorSettings_ElementType
	ALTER COLUMN Encrypt bit NOT NULL
GO
ALTER TABLE ConnectorSettings_ElementType ADD CONSTRAINT
	DF_ConnectorSettings_ElementType_Encrypt DEFAULT 0 FOR Encrypt
GO
ALTER PROCEDURE [dbo].[spConnectorSettings_UpdateElementTypeValue]
	@BusinessUnitGuid uniqueidentifier,
	@ConnectorSettingsElementTypeId uniqueidentifier,
	@ElementValue nvarchar(max),
	@EncryptedElementValue varbinary(MAX)
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
		SET		ElementValue = @ElementValue,
				EncryptedElementValue = @EncryptedElementValue
		WHERE	BusinessUnitGuid = @BusinessUnitGuid
				AND ConnectorSettingsElementTypeId = @ConnectorSettingsElementTypeId;
	END
	ELSE
	BEGIN
		INSERT INTO ConnectorSettings_BusinessUnit(BusinessUnitGuid, ConnectorSettingsElementTypeId, ElementValue, EncryptedElementValue)
		VALUES (@BusinessUnitGuid, @ConnectorSettingsElementTypeId, @ElementValue, @EncryptedElementValue);
	END
END
GO
ALTER PROCEDURE [dbo].[spConnectorSettings_RegisterElementType]
	@ConnectorSettingsElementTypeId uniqueidentifier,
	@ConnectorSettingsTypeId uniqueidentifier,
	@Description nvarchar(255),
	@Obfuscate bit,
	@SortOrder int,
	@ElementValue nvarchar(max) = '',
	@Encrypt bit
AS
	IF NOT EXISTS(SELECT * FROM ConnectorSettings_ElementType WHERE ConnectorSettingsElementTypeId = @ConnectorSettingsElementTypeId AND ConnectorSettingsTypeId = @ConnectorSettingsTypeId)
	BEGIN
		INSERT INTO ConnectorSettings_ElementType(ConnectorSettingsElementTypeId,ConnectorSettingsTypeId,DescriptionDefault,Obfuscate,SortOrder,ElementValue,Encrypt)
		VALUES (@ConnectorSettingsElementTypeId,@ConnectorSettingsTypeId,@Description,@Obfuscate,@SortOrder,@ElementValue,@Encrypt);
	END
GO
ALTER PROCEDURE [dbo].[spConnectorSettings_ElementTypeListByAttribute]
	@BusinessUnitGuid uniqueidentifier,
	@AttributeId uniqueidentifier
AS
BEGIN
	SET NOCOUNT ON

	SELECT	et.ConnectorSettingsElementTypeId,
			et.ConnectorSettingsTypeId,
			et.DescriptionDefault,
			et.Obfuscate,
			et.SortOrder,
			CASE WHEN bet.ElementValue IS NULL AND bet.EncryptedElementValue IS NULL THEN et.ElementValue ELSE bet.ElementValue END AS ElementValue,
			bet.EncryptedElementValue,
			et.Encrypt
	FROM	ConnectorSettings_ElementType et
			LEFT JOIN ConnectorSettings_BusinessUnit bet ON et.ConnectorSettingsElementTypeId = bet.ConnectorSettingsElementTypeId
				AND bet.BusinessUnitGuid = @BusinessUnitGuid
	WHERE	et.ConnectorSettingsTypeId = 
		(SELECT ConnectorSettings_ElementType.ConnectorSettingsTypeId
		FROM ConnectorSettings_ElementType
		WHERE ConnectorSettings_ElementType.ConnectorSettingsElementTypeId = @AttributeId)
	ORDER BY et.SortOrder, et.DescriptionDefault;
END
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
			et.Obfuscate,
			et.SortOrder,
			CASE WHEN bet.ElementValue IS NULL AND bet.EncryptedElementValue IS NULL THEN et.ElementValue ELSE bet.ElementValue END AS ElementValue,
			bet.EncryptedElementValue,
			et.Encrypt
	FROM	ConnectorSettings_ElementType et
			LEFT JOIN ConnectorSettings_BusinessUnit bet ON et.ConnectorSettingsElementTypeId = bet.ConnectorSettingsElementTypeId
				AND bet.BusinessUnitGuid = @BusinessUnitGuid
	WHERE	et.ConnectorSettingsTypeId = @ConnectorSettingsTypeId
	ORDER BY et.SortOrder, et.DescriptionDefault;
END
GO

ALTER TABLE dbo.Template_Group ADD
	TroubleshootingMode bit NOT NULL CONSTRAINT DF_Template_Group_TroubleshootingMode DEFAULT 0;
GO

ALTER procedure [dbo].[spProjectGrp_ProjectGroupList]
	@ProjectGroupGuid uniqueidentifier
AS
    SELECT	a.Template_Group_ID, t.[Name] as Template_Name, a.template_group_guid, 
			a.helptext as TemplateGroup_HelpText, a.Template_Guid, a.Layout_Guid,
			a.Template_Version, a.Layout_Version, a.AllowPreview, a.PostGenerateText,
			a.UpdateDocumentFields, a.EnforceValidation, a.WizardFinishText, 
			a.EnforcePublishPeriod, a.PublishStartDate, a.PublishFinishDate,
			a.HideNavigationPane, a.ShowFormActivity, a.MatchProjectVersion,
			a.AllowRestart, a.OfflineDataSources, a.LogPageTransition,
			a.AllowSave, a.Folder_Guid, a.IsHomePage, a.TroubleshootingMode
    FROM	Template_Group a
			INNER JOIN Template t on a.Template_Guid = t.Template_Guid
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;


GO

ALTER PROCEDURE [dbo].[spProjectGrp_UpdateProjectGroup]
	@ProjectGroupGuid uniqueidentifier,
	@HelpText nvarchar(4000),
	@AllowPreview bit,
	@AllowRestart bit,
	@WizardFinishText nvarchar(max),
	@PostGenerateText nvarchar(4000),
	@UpdateDocumentFields bit,
	@EnforceValidation bit,
	@HideNavigationPane bit,
	@EnforcePublishPeriod bit,
	@PublishStartDate datetime,
	@PublishFinishDate datetime,
	@ProjectGuid uniqueidentifier,
	@LayoutGuid uniqueidentifier,
	@ProjectVersion nvarchar(10),
	@LayoutVersion nvarchar(10),
	@FolderGuid uniqueidentifier,
	@ShowFormActivity bit,
	@MatchProjectVersion bit,
	@OfflineDataSources bit,
	@LogPageTransition bit,
	@AllowSave bit,
	@IsHomePage bit = 0,
	@TroubleshootingMode bit = 0,
	@SkinXml nvarchar(max) = ''
AS
	IF NOT EXISTS(SELECT * FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid)
	BEGIN
		DECLARE @SkinDate DateTime = null
		IF @SkinXml <> ''
		BEGIN
			SET @SkinDate = GETUTCDATE()
		END

		INSERT INTO Template_Group (template_group_guid, helptext, AllowPreview, PostGenerateText, 
				UpdateDocumentFields, EnforceValidation, WizardFinishText, EnforcePublishPeriod,
				PublishStartDate, PublishFinishDate, HideNavigationPane, Template_Guid, Layout_Guid,
				Template_Version, Layout_Version, Folder_Guid, ShowFormActivity, MatchProjectVersion,
				AllowRestart, OfflineDataSources, LogPageTransition, SkinXml, AllowSave, SkinLastUpdated,
				IsHomePage, TroubleshootingMode)
		VALUES (@ProjectGroupGuid, @HelpText, @AllowPreview, @PostGenerateText, 
				@UpdateDocumentFields, @EnforceValidation, @WizardFinishText, @EnforcePublishPeriod,
				@PublishStartDate, @PublishFinishDate, @HideNavigationPane, @ProjectGuid, @LayoutGuid,
				@ProjectVersion, @LayoutVersion, @FolderGuid, @ShowFormActivity, @MatchProjectVersion,
				@AllowRestart, @OfflineDataSources,@LogPageTransition, @SkinXml, @AllowSave, @SkinDate,
				@IsHomePage, @TroubleshootingMode);
	END
	ELSE
	BEGIN
		DECLARE @ExistingSkin nvarchar(max)
		SELECT @ExistingSkin = CAST(SkinXml as nvarchar(max)) FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid
		UPDATE	Template_Group
		SET		HelpText = @HelpText,
				AllowPreview = @AllowPreview,
				PostGenerateText = @PostGenerateText,
				UpdateDocumentFields = @UpdateDocumentFields,
				EnforceValidation = @EnforceValidation,
				WizardFinishText = @WizardFinishText,
				EnforcePublishPeriod = @EnforcePublishPeriod,
				PublishStartDate = @PublishStartDate,
				PublishFinishDate = @PublishFinishDate,
				HideNavigationPane = @HideNavigationPane,
				Template_Guid = @ProjectGuid,
				Layout_Guid = @LayoutGuid,
				Template_Version = @ProjectVersion,
				Layout_Version = @LayoutVersion,
				Folder_Guid = @FolderGuid,
				ShowFormActivity = @ShowFormActivity,
				MatchProjectVersion = @MatchProjectVersion,
				AllowRestart = @AllowRestart,
				OfflineDataSources = @OfflineDataSources,
				LogPageTransition = @LogPageTransition,
				SkinXml = @SkinXml,
				AllowSave = @AllowSave,
				IsHomePage = @IsHomePage,
				TroubleshootingMode = @TroubleshootingMode
		WHERE	Template_Group_Guid = @ProjectGroupGuid;
		DECLARE @StoredSkin nvarchar(max)
		SELECT @StoredSkin = CAST(SkinXml as nvarchar(max)) FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid
		IF @SkinXml = ''
			BEGIN
				UPDATE Template_Group SET SkinLastUpdated = NULL WHERE Template_Group_Guid = @ProjectGroupGuid;
			END
		ELSE 
		BEGIN
			IF REPLACE(REPLACE(Replace(@ExistingSkin,' ',''), CHAR(13), ''), CHAR(10), '') <> REPLACE(REPLACE(Replace(@StoredSkin,' ',''), CHAR(13), ''), CHAR(10), '')
			BEGIN
				UPDATE Template_Group SET SkinLastUpdated = GETUTCDATE() WHERE Template_Group_Guid = @ProjectGroupGuid;
			END
		END
	END

	EXEC spProjectGroup_UpdateFeatureFlags @ProjectGroupGuid=@ProjectGroupGuid;
GO

ALTER PROCEDURE [dbo].[spAudit_AnswerFileList]
	@AnswerFile_ID int = 0,
	@AnswerFile_Guid uniqueidentifier = null,
	@User_Guid uniqueidentifier = null,
	@InProgress bit = 0,
	@TemplateGroupGuid uniqueidentifier = null,
	@ReturnXml bit = 1
AS
	set nocount on
	
	IF (@AnswerFile_Guid IS NOT NULL)
	BEGIN
		SELECT	@AnswerFile_ID = AnswerFile_ID
		FROM	Answer_File
		WHERE	AnswerFile_Guid = @AnswerFile_Guid;
	END

	if @AnswerFile_ID = 0 or @AnswerFile_ID is null
    begin
		if @TemplateGroupGuid is null
			select	ans.AnswerFile_Id, ans.User_Guid, ans.Template_Group_Guid, ans.Description, 
					ans.RunDate, ans.InProgress, ans.AnswerFile_Guid, ans.RunID,
					Template.Name as Template_Name, Template_Group.Template_Group_Guid,
					ans.FirstLaunchTimeUtc, Template_Group.MatchProjectVersion, Template.Business_Unit_GUID
			from	answer_file ans
					inner join Template_Group on ans.Template_Group_Guid = Template_Group.Template_Group_Guid
					inner join Template on Template_Group.Template_Guid = Template.Template_Guid
			where	Ans.[User_Guid] = @user_Guid
					AND Ans.[InProgress] = @InProgress
					AND Ans.template_group_Guid in (

				-- Get a union of template group.
				SELECT DISTINCT tg.Template_Group_Guid
				FROM Folder f
					left join (
						SELECT tg.Template_Group_ID, tg.Folder_Guid, tg.Template_Group_Guid, tg.Template_Guid
						FROM template_group tg 
						WHERE (tg.EnforcePublishPeriod = 0 
								OR ((tg.PublishStartDate IS NULL OR tg.PublishStartDate < getdate())
									AND (tg.PublishFinishDate IS NULL OR tg.PublishFinishDate > getdate())))
					) tg on f.Folder_Guid = tg.Folder_Guid
					left join template t on tg.Template_Guid = t.Template_Guid
					inner join folder_group fg on F.Folder_Guid = fg.FolderGuid
				where 	(fg.GroupGuid in
							(select b.Group_Guid
							from intelledox_user a
							left join User_Group_Subscription c on a.User_Guid = c.UserGuid
							left join user_group b on c.groupguid = b.group_guid
							where c.UserGuid = @user_guid)
						)
			)
			order by [RunDate] desc;
		else
			select	ans.AnswerFile_Id, ans.User_Guid, ans.Template_Group_Guid, ans.Description, 
					ans.RunDate, ans.InProgress, ans.AnswerFile_Guid, ans.RunID,
					T.Name as Template_Name,
					ans.FirstLaunchTimeUtc, Template_Group.MatchProjectVersion, T.Business_Unit_GUID
			from	answer_file ans					
					INNER JOIN Template_Group on ans.Template_Group_Guid = Template_Group.Template_Group_Guid
					INNER JOIN Template AS T ON Template_Group.Template_Guid = T.Template_Guid
			where	Ans.[user_Guid] = @user_Guid
					AND Ans.Template_group_Guid = @TemplateGroupGuid
			order by [RunDate] desc;
    end
    else if (@ReturnXml = 1)
    begin
        SELECT	Answer_File.*, Template_Group.MatchProjectVersion, T.Business_Unit_GUID
		FROM	Answer_File
			INNER JOIN Template_Group ON Answer_File.Template_Group_Guid = Template_Group.Template_Group_Guid
			INNER JOIN Template AS T ON Template_Group.Template_Guid = T.Template_Guid
        WHERE	Answer_File.AnswerFile_Id = @AnswerFile_Id;
    end
	else
	begin
        SELECT	Answer_File.AnswerFile_ID, Answer_File.AnswerFile_Guid, Answer_File.Description, Answer_File.InProgress,
				Answer_File.RunDate, Answer_File.User_Guid, Answer_File.Template_Group_Guid, Answer_File.FirstLaunchTimeUtc,
				Answer_File.RunID, Template_Group.MatchProjectVersion, T.Business_Unit_GUID
		FROM	Answer_File
			INNER JOIN Template_Group ON Answer_File.Template_Group_Guid = Template_Group.Template_Group_Guid
			INNER JOIN Template AS T ON Template_Group.Template_Guid = T.Template_Guid
        WHERE	Answer_File.AnswerFile_Id = @AnswerFile_Id;
	end
GO

ALTER TABLE Business_Unit
ADD SamlLog BIT NOT NULL DEFAULT(0)
GO

ALTER PROCEDURE [spTenant_UpdateBusinessUnit]
	@BusinessUnitGuid uniqueidentifier,
	@Name nvarchar(200),
	@SubscriptionType int,
	@ExpiryDate datetime,
	@TenantFee money,
	@DefaultCulture nvarchar(11),
	@DefaultLanguage nvarchar(11),
	@DefaultTimezone nvarchar(50),
	@UserFee money,
	@SamlEnabled bit, 
	@SamlCertificate nvarchar(max), 
	@SamlCertificateType int, 
	@SamlCreateUsers bit, 
	@SamlIssuer nvarchar(255), 
	@SamlLoginUrl nvarchar(1500), 
	@SamlLogoutUrl nvarchar(1500),
	@SamlManageEntityId nvarchar(1500),
	@SamlProduceEntityId nvarchar(1500),
	@SamlLog bit,
	@SamlLastLoginFail nvarchar(max),
	@TenantKey varbinary(50),
	@Eula nvarchar(max),
	@EnforceEula bit,
	@TenancyKeyDateUtc datetime = NULL
AS
	UPDATE	Business_Unit
	SET		Name = @Name,
			SubscriptionType = @SubscriptionType,
			ExpiryDate = @ExpiryDate,
			TenantFee = @TenantFee,
			DefaultCulture = @DefaultCulture,
			DefaultLanguage = @DefaultLanguage,
			DefaultTimezone = @DefaultTimezone,
			UserFee = @UserFee,
			SamlEnabled = @SamlEnabled,
			SamlCertificate = @SamlCertificate,
			SamlCertificateType = @SamlCertificateType, 
			SamlCreateUsers = @SamlCreateUsers, 
			SamlIssuer = @SamlIssuer, 
			SamlLoginUrl = @SamlLoginUrl, 
			SamlLogoutUrl = @SamlLogoutUrl,
			SamlManageEntityId = @SamlManageEntityId,
			SamlProduceEntityId = @SamlProduceEntityId,
			SamlLog = @SamlLog,
			SamlLastLoginFail = @SamlLastLoginFail,
			TenantKey = @TenantKey,
			Eula = @Eula,
			EnforceEula = @EnforceEula,
			TenancyKeyDateUtc = @TenancyKeyDateUtc
	WHERE	Business_Unit_Guid = @BusinessUnitGuid;
GO

CREATE TABLE [dbo].[Analytics_DeviceLog](
	[IPAddress] [nvarchar](50) NULL,
	[OS] [nvarchar](50) NULL,
	[OSVersionMajor] int NULL,
	[OSVersionMinor] [decimal](18, 2) NULL,
	[City] [nvarchar](50) NULL,
	[Country] [nvarchar](50) NULL,
	[CountryCode] [nvarchar](50) NULL,
	[Region] [nvarchar](50) NULL,
	[RegionCode] [nvarchar](50) NULL,
	[PostalCode] [nvarchar](50) NULL,
	[TimeZone] [nvarchar](50) NULL,
	[Browser] [nvarchar](50) NULL,
	[BrowserVersionMajor] [int] NULL,
	[BrowserVersionMinor] [decimal](18, 2) NULL,
	[Device] [nvarchar](50) NULL,
	[Model] [nvarchar](50) NULL,
	[Platform] [nvarchar](50) NULL,
	[Latitude] [decimal](9, 6) NULL,
	[Longitude] [decimal](9,6) NULL,
	[Languages] [nvarchar](50) NULL,
	[UserGuid] [uniqueidentifier] NULL,
	[LoginTimeUtc] [datetime] NULL,
	[LocationAccuracy] [nvarchar] (4) NULL
	)
GO

 CREATE CLUSTERED INDEX IX_Analytics_DeviceLog_LoginTimeUtc ON Analytics_DeviceLog (LoginTimeUtc); 
 GO

CREATE procedure [dbo].[spAnalytics_DeviceLog_Insert]
	@ipAddress nvarchar(50),
	@os nvarchar(50),
	@osVersionMajor int = NULL,
	@osVersionMinor decimal (18,2) = NULL,
	@city nvarchar(50),
	@country nvarchar(50),
	@countryCode nvarchar(50),
	@region nvarchar(50),
	@regionCode nvarchar(50),
	@postalCode nvarchar(50),
	@timeZone nvarchar(50),
	@browser nvarchar(50),
	@browserVersionMajor int = NULL,
	@browserVersionMinor decimal(18, 2) = NULL,
	@device nvarchar(50),
	@model nvarchar(50),
	@platform nvarchar(50),
	@latitude decimal(9,6) = NULL,
	@longitude decimal(9,6) = NULL,
	@languages nvarchar(50),
	@userGuid uniqueidentifier,
	@loginTimeUtc datetime,
	@locationAccuracy nvarchar(4)
AS
	INSERT INTO Analytics_DeviceLog (IPAddress,OS, OSVersionMajor, OSVersionMinor, City,
	Country, CountryCode, Region, RegionCode, PostalCode, TimeZone, Browser,
	BrowserVersionMajor, BrowserVersionMinor, Device, Model, [Platform], Latitude, Longitude,
	Languages, UserGuid, LoginTimeUtc, LocationAccuracy)
    VALUES (@ipAddress, @os, @osVersionMajor, @osVersionMinor, @city, @country,
	@countryCode, @region, @regionCode, @postalCode, @timeZone, @browser,
	@browserVersionMajor, @browserVersionMinor, @device, @model, @platform, @latitude, @longitude,
	@languages, @userGuid, @loginTimeUtc, @locationAccuracy)
GO

ALTER TABLE [Template_Log]
ADD LoginTimeUtc datetime NULL,
Latitude [decimal](9, 6) NULL,
Longitude [decimal](9,6) NULL
GO

ALTER procedure [spLog_InsertTemplateLog]
	@LogGuid uniqueidentifier,
	@UserGuid uniqueidentifier,	
	@TemplateGroupGuid uniqueidentifier,
	@StartTime datetime,
	@AnswerFile xml,
	@RunID uniqueidentifier,
	@UpdateRecent bit = 0,
	@ActionListStateId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
	@LoginTimeUtc datetime = NULL,
	@Latitude decimal (9,6) = NULL,
	@Longitude decimal (9,6) = NULL
AS
	DECLARE @UserId INT;
	DECLARE @TemplateGroupId INT;
	
	SET NOCOUNT ON;
	
	SET @UserId = (SELECT User_Id FROM Intelledox_User WITH (NOLOCK) WHERE User_Guid = @UserGuid);
	SET	@TemplateGroupId = (SELECT Template_Group_Id FROM Template_Group WITH (NOLOCK) WHERE Template_Group_Guid = @TemplateGroupGuid);
	
	IF @LogGuid IS NULL
		SET @LogGuid = newid();

	--Add to log
	INSERT INTO Template_Log WITH (ROWLOCK) (Log_Guid, [User_ID], Template_Group_ID, DateTime_Start, CompletionState, Answer_File, ActionListStateId, RunID, LoginTimeUtc, Latitude, Longitude)
	VALUES (@LogGuid, @UserID, @TemplateGroupID, @StartTime, 0, @AnswerFile, @ActionListStateId, @RunID, @LoginTimeUtc, @Latitude, @Longitude);

	--Add to recent
	If @UpdateRecent = 1
	BEGIN
		IF EXISTS (SELECT * FROM Template_Recent WHERE User_Guid = @UserGuid AND Template_Group_Guid = @TemplateGroupGuid)
		BEGIN
			--Update time ran
			UPDATE	Template_Recent
			SET		DateTime_Start = @StartTime
			WHERE	User_Guid = @UserGuid 
					AND Template_Group_Guid = @TemplateGroupGuid;
		END
		ELSE
		BEGIN
			IF ((SELECT COUNT(*) FROM Template_Recent WHERE User_Guid = @UserGuid) = 5)
			BEGIN
				--Remove oldest recent record
				DELETE Template_Recent
				WHERE DateTime_Start = (SELECT MIN(DateTime_Start)
					FROM	Template_Recent
					WHERE	User_Guid = @UserGuid)
					AND User_Guid = @UserGuid;
			END
			
			INSERT INTO Template_Recent(User_Guid, DateTime_Start, Template_Group_Guid, Log_Guid)
			VALUES (@UserGuid, @StartTime, @TemplateGroupGuid, @LogGuid);
		END
	END

GO

ALTER TABLE [Answer_File]
ADD LoginTimeUtc datetime NULL,
Latitude [decimal](9, 6) NULL,
Longitude [decimal](9,6) NULL
GO

ALTER procedure [spAudit_UpdateAnswerFile]
	@AnswerFile_ID int,
	@AnswerFile_Guid uniqueidentifier,
	@User_Guid uniqueidentifier,
	@Template_Group_Guid uniqueidentifier,
	@Description nvarchar(255),
	@RunDate datetime,
	@UnencryptedAnswerString xml,
	@EncryptedAnswerString varbinary(MAX),
	@FirstLaunchTimeUtc datetime,
	@RunID uniqueidentifier,
	@InProgress bit = 0,
	@NewID int output,
	@ErrorCode int output,
	@LoginTimeUtc datetime = NULL,
	@Latitude decimal (9,6) = NULL,
	@Longitude decimal (9,6) = NULL
AS
	set nocount on
	
	if ((@AnswerFile_ID = 0 OR @AnswerFile_ID IS NULL) AND @AnswerFile_Guid IS NOT NULL)
	begin
		 SELECT	@AnswerFile_ID = AnswerFile_ID 
		 FROM	Answer_File 
		 WHERE	AnswerFile_Guid = @AnswerFile_Guid
	end

	if (@AnswerFile_ID > 0)
	begin
		update Answer_File
		set [Description] = @Description,
			RunDate = @RunDate,
			AnswerString = @UnencryptedAnswerString,
			EncryptedAnswerString = @EncryptedAnswerString,
			LoginTimeUtc = @LoginTimeUtc,
			Latitude = @Latitude,
			Longitude = @Longitude
		where AnswerFile_ID = @AnswerFile_ID;
	end
	else
	begin
		insert into Answer_File (AnswerFile_Guid, [User_Guid], [Template_Group_Guid], [Description], [RunDate], [AnswerString], [InProgress], [EncryptedAnswerString], FirstLaunchTimeUtc, RunID, LoginTimeUtc, Latitude, Longitude)
		values (@AnswerFile_Guid, @User_Guid, @Template_Group_Guid, @Description, @RunDate, @UnencryptedAnswerString, @InProgress, @EncryptedAnswerString, @FirstLaunchTimeUtc, @RunID, @LoginTimeUtc, @Latitude, @Longitude);

		select @NewID = @@Identity;
	end

	set @ErrorCode = @@Error;

GO

ALTER PROCEDURE [spAudit_AnswerFileList]
	@AnswerFile_ID int = 0,
	@AnswerFile_Guid uniqueidentifier = null,
	@User_Guid uniqueidentifier = null,
	@InProgress bit = 0,
	@TemplateGroupGuid uniqueidentifier = null,
	@ReturnXml bit = 1
AS
	set nocount on
	
	IF (@AnswerFile_Guid IS NOT NULL)
	BEGIN
		SELECT	@AnswerFile_ID = AnswerFile_ID
		FROM	Answer_File
		WHERE	AnswerFile_Guid = @AnswerFile_Guid;
	END

	if @AnswerFile_ID = 0 or @AnswerFile_ID is null
    begin
		if @TemplateGroupGuid is null
			select	ans.AnswerFile_Id, ans.User_Guid, ans.Template_Group_Guid, ans.Description, 
					ans.RunDate, ans.InProgress, ans.AnswerFile_Guid, ans.RunID,
					Template.Name as Template_Name, Template_Group.Template_Group_Guid,
					ans.FirstLaunchTimeUtc, Template_Group.MatchProjectVersion, Template.Business_Unit_GUID,
					ans.LoginTimeUtc, ans.Latitude, ans.Longitude
			from	answer_file ans
					inner join Template_Group on ans.Template_Group_Guid = Template_Group.Template_Group_Guid
					inner join Template on Template_Group.Template_Guid = Template.Template_Guid
			where	Ans.[User_Guid] = @user_Guid
					AND Ans.[InProgress] = @InProgress
					AND Ans.template_group_Guid in (

				-- Get a union of template group.
				SELECT DISTINCT tg.Template_Group_Guid
				FROM Folder f
					left join (
						SELECT tg.Template_Group_ID, tg.Folder_Guid, tg.Template_Group_Guid, tg.Template_Guid
						FROM template_group tg 
						WHERE (tg.EnforcePublishPeriod = 0 
								OR ((tg.PublishStartDate IS NULL OR tg.PublishStartDate < getdate())
									AND (tg.PublishFinishDate IS NULL OR tg.PublishFinishDate > getdate())))
					) tg on f.Folder_Guid = tg.Folder_Guid
					left join template t on tg.Template_Guid = t.Template_Guid
					inner join folder_group fg on F.Folder_Guid = fg.FolderGuid
				where 	(fg.GroupGuid in
							(select b.Group_Guid
							from intelledox_user a
							left join User_Group_Subscription c on a.User_Guid = c.UserGuid
							left join user_group b on c.groupguid = b.group_guid
							where c.UserGuid = @user_guid)
						)
			)
			order by [RunDate] desc;
		else
			select	ans.AnswerFile_Id, ans.User_Guid, ans.Template_Group_Guid, ans.Description, 
					ans.RunDate, ans.InProgress, ans.AnswerFile_Guid, ans.RunID,
					T.Name as Template_Name,
					ans.FirstLaunchTimeUtc, Template_Group.MatchProjectVersion, T.Business_Unit_GUID,
					ans.LoginTimeUtc, ans.Latitude, ans.Longitude
			from	answer_file ans					
					INNER JOIN Template_Group on ans.Template_Group_Guid = Template_Group.Template_Group_Guid
					INNER JOIN Template AS T ON Template_Group.Template_Guid = T.Template_Guid
			where	Ans.[user_Guid] = @user_Guid
					AND Ans.Template_group_Guid = @TemplateGroupGuid
			order by [RunDate] desc;
    end
    else if (@ReturnXml = 1)
    begin
        SELECT	Answer_File.*, Template_Group.MatchProjectVersion, T.Business_Unit_GUID
		FROM	Answer_File
			INNER JOIN Template_Group ON Answer_File.Template_Group_Guid = Template_Group.Template_Group_Guid
			INNER JOIN Template AS T ON Template_Group.Template_Guid = T.Template_Guid
        WHERE	Answer_File.AnswerFile_Id = @AnswerFile_Id;
    end
	else
	begin
        SELECT	Answer_File.AnswerFile_ID, Answer_File.AnswerFile_Guid, Answer_File.Description, Answer_File.InProgress,
				Answer_File.RunDate, Answer_File.User_Guid, Answer_File.Template_Group_Guid, Answer_File.FirstLaunchTimeUtc,
				Answer_File.RunID, Template_Group.MatchProjectVersion, T.Business_Unit_GUID,
				Answer_File.LoginTimeUtc, Answer_File.Latitude, Answer_File.Longitude
		FROM	Answer_File
			INNER JOIN Template_Group ON Answer_File.Template_Group_Guid = Template_Group.Template_Group_Guid
			INNER JOIN Template AS T ON Template_Group.Template_Guid = T.Template_Guid
        WHERE	Answer_File.AnswerFile_Id = @AnswerFile_Id;
	end

GO

CREATE procedure [dbo].[spAnalytics_DeviceLog_Update]
	@ipAddress nvarchar(50),
	@os nvarchar(50),
	@osVersionMajor int = NULL,
	@osVersionMinor decimal (18,2) = NULL,
	@city nvarchar(50),
	@country nvarchar(50),
	@countryCode nvarchar(50),
	@region nvarchar(50),
	@regionCode nvarchar(50),
	@postalCode nvarchar(50),
	@timeZone nvarchar(50),
	@browser nvarchar(50),
	@browserVersionMajor int = NULL,
	@browserVersionMinor decimal(18, 2) = NULL,
	@device nvarchar(50),
	@model nvarchar(50),
	@platform nvarchar(50),
	@latitude decimal(9,6) = NULL,
	@longitude decimal(9,6) = NULL,
	@languages nvarchar(50),
	@userGuid uniqueidentifier,
	@loginTimeUtc datetime,
	@locationAccuracy nvarchar(4)
AS
	UPDATE [Analytics_DeviceLog]
   SET [IPAddress] = @ipAddress,
      [OS] = @os, 
      [OSVersionMajor] = @osVersionMajor, 
      [OSVersionMinor] = @osVersionMinor, 
      [City] = @city, 
      [Country] = @country, 
      [CountryCode] = @countryCode, 
      [Region] = @region, 
      [RegionCode] = @regionCode, 
      [PostalCode] = @postalCode, 
      [TimeZone] = @timeZone, 
      [Browser] = @browser, 
      [BrowserVersionMajor] = @browserVersionMajor, 
      [BrowserVersionMinor] = @browserVersionMinor, 
      [Device] = @device, 
      [Model] = @model, 
      [Platform] = @platform, 
      [Latitude] = @latitude, 
      [Longitude] = @longitude, 
      [Languages] = @languages, 
      [LocationAccuracy] = @locationAccuracy
 WHERE UserGuid = @userGuid AND LoginTimeUtc = @loginTimeUtc
GO

CREATE procedure [dbo].[spAnalytics_DeviceLog_Get]
	@userGuid uniqueidentifier,
	@loginTimeUtc datetime
AS
	SELECT [IPAddress]
      ,[OS]
      ,[OSVersionMajor]
      ,[OSVersionMinor]
      ,[City]
      ,[Country]
      ,[CountryCode]
      ,[Region]
      ,[RegionCode]
      ,[PostalCode]
      ,[TimeZone]
      ,[Browser]
      ,[BrowserVersionMajor]
      ,[BrowserVersionMinor]
      ,[Device]
      ,[Model]
      ,[Platform]
      ,[Latitude]
      ,[Longitude]
      ,[Languages]
      ,[UserGuid]
      ,[LoginTimeUtc]
      ,[LocationAccuracy]
  FROM [Analytics_DeviceLog]
 WHERE UserGuid = @userGuid AND LoginTimeUtc = @loginTimeUtc
GO

CREATE TABLE [dbo].[Analytics_InteractionLog](
	[Log_Guid] [uniqueidentifier] NOT NULL,
	[ControlID] [nvarchar](100) NOT NULL,
	[FocusTimeUTC] [datetime] NOT NULL,
	[BlurTimeUTC] [datetime] NULL
)
GO
CREATE CLUSTERED INDEX [IX_Analytics_InteractionLog] ON [dbo].[Analytics_InteractionLog]
(
	[Log_Guid] ASC,
	[ControlID] ASC,
	[FocusTimeUTC]
)
GO

CREATE PROCEDURE [dbo].[spLog_InsertAnalyticsInteractionLog]
	@LogGuid uniqueIdentifier,
	@ControlID nvarchar(100),
	@FocusTimeUTC dateTime,
	@BlurTimeUTC dateTime
AS
    SET NOCOUNT ON;
	INSERT INTO Analytics_InteractionLog ([Log_Guid], [ControlID], [FocusTimeUTC], [BlurTimeUTC])
	VALUES (@LogGuid, @ControlID, @FocusTimeUTC, @BlurTimeUTC)
GO

ALTER procedure [dbo].[spCleanup]
	@HasAnyTransactionalLicense bit
AS
    SET NOCOUNT ON
    SET DEADLOCK_PRIORITY LOW;

    DECLARE @DocumentCleanupDate DateTime;
	DECLARE @DocumentBinaryCleanupDate DateTime;
	DECLARE @SeparateDateForBinaries bit;
	DECLARE @DownloadableDocNum int;
	DECLARE @GenerationCleanupDate DateTime;
	DECLARE @AuditCleanupDate DateTime;
	DECLARE @WorkflowCleanupDate DateTime;
	DECLARE @LogoutCleanupDate DateTime;
	DECLARE @TransactionLogCleanupDate DateTime;
	DECLARE @AnonymousUsersCleanup DateTime;

    SET @DocumentCleanupDate = DATEADD(hour, -CAST((SELECT OptionValue 
                                        FROM Global_Options 
                                        WHERE OptionCode = 'CLEANUP_HOURS') AS float), GetUtcDate());

	SET @DownloadableDocNum = (SELECT OptionValue 
								FROM Global_Options 
								WHERE OptionCode = 'DOWNLOADABLE_DOC_NUM');

    SET @GenerationCleanupDate = DATEADD(day, -CAST((SELECT OptionValue 
                                        FROM Global_Options 
                                        WHERE OptionCode = 'GENERATION_RETENTION') AS float), GetUtcDate());

    SET @AuditCleanupDate = DATEADD(day, -CAST((SELECT OptionValue 
                                        FROM Global_Options 
                                        WHERE OptionCode = 'AUDIT_RETENTION') AS float), GetUtcDate());

    SET @WorkflowCleanupDate = DATEADD(day, -CAST((SELECT OptionValue 
                                        FROM Global_Options 
                                        WHERE OptionCode = 'WORKFLOW_RETENTION') AS float), GetUtcDate());
												
    SET @LogoutCleanupDate = DATEADD(day, -1, GetUtcDate());
											
    SET @TransactionLogCleanupDate = DATEADD(year, -2, GetUtcDate());

	SET @AnonymousUsersCleanup = DATEADD(HOUR, -2, GetUtcDate());
										
    DECLARE @GuidId uniqueidentifier;
    CREATE TABLE #ExpiredItems 
    ( 
        Id uniqueidentifier NOT NULL PRIMARY KEY
    )
	
	IF (@HasAnyTransactionalLicense = 1 AND (SELECT OptionValue 
                                        FROM Global_Options 
                                        WHERE OptionCode = 'CLEANUP_HOURS') < (90 * 24))
										
	BEGIN
		SET @DocumentBinaryCleanupDate = @DocumentCleanupDate;
		SET @DocumentCleanupDate = DATEADD(hour, -(90 * 24), GetUtcDate());
		SET @SeparateDateForBinaries = 1;
	END
	ELSE
	BEGIN
		SET @SeparateDateForBinaries = 0;
	END


	-- ==================================================
	-- Expired documents
	IF (@DownloadableDocNum = 0)
	BEGIN
		INSERT #ExpiredItems (Id)
		SELECT DISTINCT JobId
		FROM Document WITH (READUNCOMMITTED)
		WHERE DateCreated < @DocumentCleanupDate;
	END
	ELSE
	BEGIN
		-- Get the last N jobs grouped by user
		WITH GroupedDocuments AS (
			SELECT JobId, ROW_NUMBER()
			OVER (PARTITION BY UserGuid ORDER BY DateCreated DESC) AS RN
			FROM (
				SELECT	JobId, UserGuid, DateCreated
				FROM	Document WITH (READUNCOMMITTED)
				GROUP BY JobId, UserGuid, DateCreated
				) ds
			)
		INSERT #ExpiredItems (Id)
		SELECT DISTINCT JobId
		FROM Document WITH (READUNCOMMITTED)
		WHERE DateCreated < @DocumentCleanupDate
			AND JobId NOT IN (
				SELECT	JobId
				FROM	GroupedDocuments WITH (READUNCOMMITTED)
				WHERE	RN <= @DownloadableDocNum
			);
	END

    IF @@ROWCOUNT <> 0 
    BEGIN 
        DECLARE ExpiredItemCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
        FOR SELECT Id FROM #ExpiredItems 
		
        OPEN ExpiredItemCursor;
        FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;

        WHILE @@FETCH_STATUS = 0 
            BEGIN
				DELETE FROM Document WHERE JobId = @GuidId;
                FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;
            END

        CLOSE ExpiredItemCursor;
        DEALLOCATE ExpiredItemCursor;
    END
	
	-- ==================================================
	-- Remove binaries from Document table, if required
	IF (@SeparateDateForBinaries = 1)
	BEGIN	
		IF (@DownloadableDocNum = 0)
		BEGIN
			INSERT #ExpiredItems (Id)
			SELECT DISTINCT JobId
			FROM Document WITH (READUNCOMMITTED)
			WHERE DateCreated < @DocumentBinaryCleanupDate;
		END
		ELSE
		BEGIN
			-- Get the last N jobs grouped by user
			WITH GroupedDocuments AS (
				SELECT JobId, ROW_NUMBER()
				OVER (PARTITION BY UserGuid ORDER BY DateCreated DESC) AS RN
				FROM (
					SELECT	JobId, UserGuid, DateCreated
					FROM	Document WITH (READUNCOMMITTED)
					GROUP BY JobId, UserGuid, DateCreated
					) ds
				)
			INSERT #ExpiredItems (Id)
			SELECT DISTINCT JobId
			FROM Document WITH (READUNCOMMITTED)
			WHERE DateCreated < @DocumentBinaryCleanupDate
				AND JobId NOT IN (
					SELECT	JobId
					FROM	GroupedDocuments WITH (READUNCOMMITTED)
					WHERE	RN <= @DownloadableDocNum
				);
		END

		IF @@ROWCOUNT <> 0 
		BEGIN 
			DECLARE ExpiredItemCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
			FOR SELECT Id FROM #ExpiredItems 
		
			OPEN ExpiredItemCursor;
			FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;

			WHILE @@FETCH_STATUS = 0 
				BEGIN
			
					UPDATE Document 
					SET DocumentBinary = 0x,
						DocumentLength = -1
					WHERE JobId = @GuidId;

					FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;
				END

			CLOSE ExpiredItemCursor;
			DEALLOCATE ExpiredItemCursor;
		END
	END

	-- ==================================================
	-- Expired generation logs
	TRUNCATE TABLE #ExpiredItems;

	INSERT #ExpiredItems (Id)
	SELECT Log_Guid
	FROM Template_Log WITH (READUNCOMMITTED)
	WHERE DateTime_Start < @GenerationCleanupDate
		AND CompletionState <> 0;

    IF @@ROWCOUNT <> 0 
    BEGIN 
        DECLARE ExpiredItemCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
        FOR SELECT Id FROM #ExpiredItems 

        OPEN ExpiredItemCursor;
        FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;

        WHILE @@FETCH_STATUS = 0 
            BEGIN
                DELETE FROM Template_Log WHERE Log_Guid = @GuidId;
                FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;
            END

        CLOSE ExpiredItemCursor;
        DEALLOCATE ExpiredItemCursor;
    END 

	-- ==================================================
	-- Expired Data Focus Transition Logs
	TRUNCATE TABLE #ExpiredItems;

	INSERT #ExpiredItems (Id)
	SELECT DISTINCT(Log_Guid)
	FROM Analytics_InteractionLog WITH (READUNCOMMITTED)
	WHERE FocusTimeUTC < @GenerationCleanupDate

    IF @@ROWCOUNT <> 0 
    BEGIN 
        DECLARE ExpiredItemCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
        FOR SELECT Id FROM #ExpiredItems 

        OPEN ExpiredItemCursor;
        FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;

        WHILE @@FETCH_STATUS = 0 
            BEGIN
                DELETE FROM Analytics_InteractionLog WHERE Log_Guid = @GuidId;
                FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;
            END

        CLOSE ExpiredItemCursor;
        DEALLOCATE ExpiredItemCursor;
    END

	-- ==================================================
	-- Expired process job logs
	TRUNCATE TABLE #ExpiredItems;

	INSERT #ExpiredItems (Id)
	SELECT JobId
	FROM ProcessJob WITH (READUNCOMMITTED)
	WHERE DateStarted < @GenerationCleanupDate
		AND CurrentStatus >= 4;

    IF @@ROWCOUNT <> 0 
    BEGIN 
        DECLARE ExpiredItemCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
        FOR SELECT Id FROM #ExpiredItems 

        OPEN ExpiredItemCursor;
        FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;

        WHILE @@FETCH_STATUS = 0 
            BEGIN
                DELETE FROM ProcessJob WHERE JobId = @GuidId;
                FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;
            END

        CLOSE ExpiredItemCursor;
        DEALLOCATE ExpiredItemCursor;
    END 


	-- ==================================================
	-- Expired sessions
	TRUNCATE TABLE #ExpiredItems;

	INSERT #ExpiredItems (Id)
	SELECT Session_Guid
	FROM User_Session WITH (READUNCOMMITTED)
	WHERE Modified_Date < DateAdd(year, -1, GetUtcDate());

    IF @@ROWCOUNT <> 0 
    BEGIN 
        DECLARE ExpiredItemCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
        FOR SELECT Id FROM #ExpiredItems 

        OPEN ExpiredItemCursor;
        FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;

        WHILE @@FETCH_STATUS = 0 
            BEGIN
                DELETE FROM User_Session WHERE Session_Guid = @GuidId;
                FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;
            END

        CLOSE ExpiredItemCursor;
        DEALLOCATE ExpiredItemCursor;
    END 


	-- ==================================================
	-- Expired workflow history
	TRUNCATE TABLE #ExpiredItems;

	INSERT #ExpiredItems (Id)
	SELECT ActionListId
	FROM ActionList WITH (READUNCOMMITTED)
	WHERE DateCreatedUtc < @WorkflowCleanupDate;

    IF @@ROWCOUNT <> 0 
    BEGIN 
        DECLARE ExpiredItemCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
        FOR SELECT Id FROM #ExpiredItems 

        OPEN ExpiredItemCursor;
        FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;

        WHILE @@FETCH_STATUS = 0 
            BEGIN
				BEGIN TRANSACTION AL;

                DELETE FROM ActionListState 
				WHERE ActionListId = @GuidId
					AND ActionListId NOT IN (
						SELECT	ActionListId
						FROM	ActionListState
						WHERE	ActionListId = @GuidId
								AND IsComplete = 0
					);

				DELETE FROM ActionList 
				WHERE ActionListId = @GuidId
					AND ActionListId NOT IN (
						SELECT	ActionListId
						FROM	ActionListState
						WHERE	ActionListId = @GuidId
								AND IsComplete = 0
					);

				COMMIT TRANSACTION AL;

                FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;
            END

        CLOSE ExpiredItemCursor;
        DEALLOCATE ExpiredItemCursor;
    END 

	-- ==================================================
	-- Expired AnonymousUsers
	TRUNCATE TABLE #ExpiredItems;

  	INSERT #ExpiredItems (Id)
	SELECT DISTINCT(UserGuid)
	FROM AnonymousUser WITH (READUNCOMMITTED)
	INNER JOIN Intelledox_User ON AnonymousUser.UserGuid = Intelledox_User.User_Guid
	INNER JOIN Template_Log ON Intelledox_User.User_ID = Template_Log.User_ID
	WHERE Intelledox_User.IsAnonymousUser = 1 AND 
		Template_Log.ActionListStateId = '00000000-0000-0000-0000-000000000000' AND
		Template_Log.DateTime_Finish < @AnonymousUsersCleanup;

    IF @@ROWCOUNT <> 0 
    BEGIN 
        DECLARE ExpiredItemCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
        FOR SELECT Id FROM #ExpiredItems 

        OPEN ExpiredItemCursor;
        FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;

        WHILE @@FETCH_STATUS = 0 
            BEGIN
                EXEC spUsers_RemoveUser @GuidId;
                FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;
            END

        CLOSE ExpiredItemCursor;
        DEALLOCATE ExpiredItemCursor;
    END
	
    DROP TABLE #ExpiredItems;


	-- ==================================================
	-- Expired audit logs
	DECLARE @BigId bigint;
    CREATE TABLE #ExpiredAudit
    ( 
        Id bigint NOT NULL PRIMARY KEY
    )

	INSERT #ExpiredAudit (Id)
	SELECT ID
	FROM AuditLog WITH (READUNCOMMITTED)
	WHERE DateCreatedUtc < @AuditCleanupDate;

    IF @@ROWCOUNT <> 0 
    BEGIN 
        DECLARE ExpiredAuditCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
        FOR SELECT Id FROM #ExpiredAudit 

        OPEN ExpiredAuditCursor;
        FETCH NEXT FROM ExpiredAuditCursor INTO @BigId;

        WHILE @@FETCH_STATUS = 0 
            BEGIN
                DELETE FROM AuditLog WHERE ID = @BigId;
                FETCH NEXT FROM ExpiredAuditCursor INTO @BigId;
            END

        CLOSE ExpiredAuditCursor;
        DEALLOCATE ExpiredAuditCursor;
    END 
	
    DROP TABLE #ExpiredAudit;
	

	-- ==================================================
	-- Expired event logs
	DECLARE @IntId int;
    CREATE TABLE #ExpiredEvent
    ( 
        Id int NOT NULL PRIMARY KEY
    )

	INSERT #ExpiredEvent (Id)
	SELECT LogEventID
	FROM EventLog WITH (READUNCOMMITTED)
	WHERE [DateTime] < @AuditCleanupDate;

    IF @@ROWCOUNT <> 0 
    BEGIN 
        DECLARE ExpiredEventCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
        FOR SELECT Id FROM #ExpiredEvent 

        OPEN ExpiredEventCursor;
        FETCH NEXT FROM ExpiredEventCursor INTO @IntId;

        WHILE @@FETCH_STATUS = 0 
            BEGIN
                DELETE FROM EventLog WHERE LogEventID = @IntId;
                FETCH NEXT FROM ExpiredEventCursor INTO @IntId;
            END

        CLOSE ExpiredEventCursor;
        DEALLOCATE ExpiredEventCursor;
    END 
	
    DROP TABLE #ExpiredEvent;

	-- ==================================================
	-- Expired logouts
	DECLARE @CookieValue varchar(200);
    CREATE TABLE #ExpiredLogout
    ( 
        AuthCookieValue varchar(200) NOT NULL PRIMARY KEY
    )

	INSERT #ExpiredLogout (AuthCookieValue)
	SELECT DISTINCT AuthCookieValue
	FROM LoggedOutSessions WITH (READUNCOMMITTED)
	WHERE [TimeLoggedOut] < @LogoutCleanupDate;

    IF @@ROWCOUNT <> 0 
    BEGIN 
        DECLARE LogoutEventCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
        FOR SELECT AuthCookieValue FROM #ExpiredLogout 

        OPEN LogoutEventCursor;
        FETCH NEXT FROM LogoutEventCursor INTO @CookieValue;

        WHILE @@FETCH_STATUS = 0 
            BEGIN
                DELETE FROM LoggedOutSessions WHERE AuthCookieValue = @CookieValue;
                FETCH NEXT FROM LogoutEventCursor INTO @CookieValue;
            END

        CLOSE LogoutEventCursor;
        DEALLOCATE LogoutEventCursor;
    END 
	
    DROP TABLE #ExpiredLogout;
	
	-- ==================================================
	-- Expired transaction logs
	-- Actions
	DECLARE @Date datetime;
    CREATE TABLE #ExpiredActionLog
    ( 
        DateTimeUTC datetime NOT NULL PRIMARY KEY
    )

	INSERT #ExpiredActionLog (DateTimeUTC)
	SELECT DISTINCT DateTimeUTC
	FROM Action_Log WITH (READUNCOMMITTED)
	WHERE [DateTimeUTC] < @TransactionLogCleanupDate;

    IF @@ROWCOUNT <> 0 
    BEGIN 
        DECLARE ActionLogCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
        FOR SELECT DateTimeUTC FROM #ExpiredActionLog 

        OPEN ActionLogCursor;
        FETCH NEXT FROM ActionLogCursor INTO @Date;

        WHILE @@FETCH_STATUS = 0 
            BEGIN
                DELETE FROM Action_Log WHERE DateTimeUTC = @Date;
                FETCH NEXT FROM ActionLogCursor INTO @Date;
            END

        CLOSE ActionLogCursor;
        DEALLOCATE ActionLogCursor;
    END 
	
    DROP TABLE #ExpiredActionLog;

	-- Escalations
    CREATE TABLE #ExpiredEscalationLog
    ( 
        DateTimeUTC datetime NOT NULL PRIMARY KEY
    )

	INSERT #ExpiredEscalationLog (DateTimeUTC)
	SELECT DISTINCT DateTimeUTC
	FROM Escalation_Log WITH (READUNCOMMITTED)
	WHERE [DateTimeUTC] < @TransactionLogCleanupDate;

    IF @@ROWCOUNT <> 0 
    BEGIN 
        DECLARE EscalationLogCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
        FOR SELECT DateTimeUTC FROM #ExpiredEscalationLog 

        OPEN EscalationLogCursor;
        FETCH NEXT FROM EscalationLogCursor INTO @Date;

        WHILE @@FETCH_STATUS = 0 
            BEGIN
                DELETE FROM Escalation_Log WHERE DateTimeUTC = @Date;
                FETCH NEXT FROM EscalationLogCursor INTO @Date;
            END

        CLOSE EscalationLogCursor;
        DEALLOCATE EscalationLogCursor;
    END 
	
    DROP TABLE #ExpiredEscalationLog;
	
	-- Emails
    CREATE TABLE #ExpiredEmailLog
    ( 
        DateTimeUTC datetime NOT NULL PRIMARY KEY
    )

	INSERT #ExpiredEmailLog (DateTimeUTC)
	SELECT DISTINCT DateTimeUTC
	FROM Email_Log WITH (READUNCOMMITTED)
	WHERE [DateTimeUTC] < @TransactionLogCleanupDate;

    IF @@ROWCOUNT <> 0 
    BEGIN 
        DECLARE EmailLogCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
        FOR SELECT DateTimeUTC FROM #ExpiredEmailLog 

        OPEN EmailLogCursor;
        FETCH NEXT FROM EmailLogCursor INTO @Date;

        WHILE @@FETCH_STATUS = 0 
            BEGIN
                DELETE FROM Email_Log WHERE DateTimeUTC = @Date;
                FETCH NEXT FROM EmailLogCursor INTO @Date;
            END

        CLOSE EmailLogCursor;
        DEALLOCATE EmailLogCursor;
    END 
	
    DROP TABLE #ExpiredEmailLog;
	
GO
