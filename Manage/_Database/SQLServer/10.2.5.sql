TRUNCATE TABLE dbversion;
GO

INSERT INTO dbversion(dbversion) VALUES ('10.2.5');
GO

ALTER TABLE [Address_Book_Custom_Field] ALTER COLUMN [Custom_Value] nvarchar(max)
GO

ALTER TABLE [Custom_Field] ALTER COLUMN [Field_Length] INT NULL
GO

ALTER PROCEDURE [dbo].[spCustomField_UpdateCustomField]
	@BusinessUnitGuid uniqueidentifier,
	@CustomFieldID int = 0,
	@Title nvarchar(100),
	@ValidationType int,
	@Location int
AS
	IF (@CustomFieldID IS NULL OR @CustomFieldID = 0)
	BEGIN
		INSERT INTO Custom_Field (BusinessUnitGuid, Title, Validation_Type, [Location])
		VALUES (@BusinessUnitGuid, @Title, @ValidationType, @Location)
	END
	ELSE
	BEGIN
		UPDATE Custom_Field
		SET Title = @Title,
			Validation_Type = @ValidationType,
			[Location] = @Location
		WHERE Custom_Field_ID = @CustomFieldID
	END
GO

CREATE procedure [dbo].[spTenant_BusinessUnitTenancyInfo]  
 @BusinessUnitGuid uniqueidentifier
AS  
  SELECT Business_Unit_Guid, Name, IdentifyBusinessUnit, Disabled, TenantKey, TenantType, TenancyKeyDateUtc
  FROM Business_Unit  
  WHERE Business_Unit_Guid = @BusinessUnitGuid;  
 GO

ALTER TABLE Template_Group ADD
	AutoCreateInProgressForms bit NOT NULL DEFAULT (0)
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
	@AutoCreateInProgressForms bit,
	@IsHomePage bit = 0,
	@TroubleshootingMode int = 0,
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
				AllowRestart, OfflineDataSources, LogPageTransition, SkinXml, AllowSave, AutoCreateInProgressForms,
				SkinLastUpdated, IsHomePage, TroubleshootingMode)
		VALUES (@ProjectGroupGuid, @HelpText, @AllowPreview, @PostGenerateText, 
				@UpdateDocumentFields, @EnforceValidation, @WizardFinishText, @EnforcePublishPeriod,
				@PublishStartDate, @PublishFinishDate, @HideNavigationPane, @ProjectGuid, @LayoutGuid,
				@ProjectVersion, @LayoutVersion, @FolderGuid, @ShowFormActivity, @MatchProjectVersion,
				@AllowRestart, @OfflineDataSources,@LogPageTransition, @SkinXml, @AllowSave, @AutoCreateInProgressForms,
				@SkinDate, @IsHomePage, @TroubleshootingMode);
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
				AutoCreateInProgressForms = @AutoCreateInProgressForms,
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
			a.AllowSave, a.AutoCreateInProgressForms, a.Folder_Guid, a.IsHomePage, 
			a.TroubleshootingMode
    FROM	Template_Group a
			INNER JOIN Template t on a.Template_Guid = t.Template_Guid
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;
GO
UPDATE Routing_ElementType SET [Required] = 0 WHERE RoutingElementTypeId = '697294b4-c9bb-498a-8e58-c872f34cf910'
UPDATE Routing_ElementType SET [Required] = 0 WHERE RoutingElementTypeId = '4e265ccf-f00e-4aed-9b74-d58380f58582'
GO
DELETE FROM Routing_Type WHERE RoutingTypeId = 'AEA1E1F5-9886-41A3-BD21-D14AAED6A175'
UPDATE Routing_ElementType SET RoutingTypeId='9D0D80ED-BAF0-4C3B-AD95-6C7D680BEF9B' WHERE RoutingElementTypeId = 'D9EC8B5A-966F-45AD-8FA1-9D070AAE661C'
UPDATE Routing_ElementType SET RoutingTypeId='9D0D80ED-BAF0-4C3B-AD95-6C7D680BEF9B' WHERE RoutingElementTypeId = '1ACEB090-EC6E-4AD3-95C4-191B45D4C776'
UPDATE Routing_ElementType SET RoutingTypeId='9D0D80ED-BAF0-4C3B-AD95-6C7D680BEF9B' WHERE RoutingElementTypeId = '9E7BEB7D-7296-4236-A837-38BBFB8CE605'
UPDATE ActionDocument SET ActionTypeId='9D0D80ED-BAF0-4C3B-AD95-6C7D680BEF9B' WHERE ActionDocumentGuid='BCB0E86E-FEFB-4996-AA15-FAB870F19050'
GO
