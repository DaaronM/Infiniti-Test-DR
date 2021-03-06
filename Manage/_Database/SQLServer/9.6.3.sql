truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.6.3');
go


ALTER TABLE [Template_Group]
ADD SkinLastUpdated DateTime
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
	@SkinXml nvarchar(max) = ''
AS
	IF NOT EXISTS(SELECT * FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid)
	BEGIN
		INSERT INTO Template_Group (template_group_guid, helptext, AllowPreview, PostGenerateText, 
				UpdateDocumentFields, EnforceValidation, WizardFinishText, EnforcePublishPeriod,
				PublishStartDate, PublishFinishDate, HideNavigationPane, Template_Guid, Layout_Guid,
				Template_Version, Layout_Version, Folder_Guid, ShowFormActivity, MatchProjectVersion,
				AllowRestart, OfflineDataSources, LogPageTransition, SkinXml, AllowSave, SkinLastUpdated)
		VALUES (@ProjectGroupGuid, @HelpText, @AllowPreview, @PostGenerateText, 
				@UpdateDocumentFields, @EnforceValidation, @WizardFinishText, @EnforcePublishPeriod,
				@PublishStartDate, @PublishFinishDate, @HideNavigationPane, @ProjectGuid, @LayoutGuid,
				@ProjectVersion, @LayoutVersion, @FolderGuid, @ShowFormActivity, @MatchProjectVersion,
				@AllowRestart, @OfflineDataSources,@LogPageTransition, @SkinXml, @AllowSave, GETUTCDATE());
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
				AllowSave = @AllowSave
		WHERE	Template_Group_Guid = @ProjectGroupGuid;
		DECLARE @StoredSkin nvarchar(max)
		SELECT @StoredSkin = CAST(SkinXml as nvarchar(max)) FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid
		IF REPLACE(REPLACE(Replace(@ExistingSkin,' ',''), CHAR(13), ''), CHAR(10), '') <> REPLACE(REPLACE(Replace(@StoredSkin,' ',''), CHAR(13), ''), CHAR(10), '')
			BEGIN
				UPDATE Template_Group SET SkinLastUpdated = GETUTCDATE() WHERE Template_Group_Guid = @ProjectGroupGuid;
			END
	END

	EXEC spProjectGroup_UpdateFeatureFlags @ProjectGroupGuid=@ProjectGroupGuid;
GO

update [Template_Group]  set SkinLastUpdated = GETUTCDATE()
  where SkinLastUpdated is null
  and REPLACE(REPLACE(Replace('<Skin Published="-62135596800000"><Header><BackgroundCol /><FontCol /><FontLinkCol /><FontHoverCol /></Header><ColorScheme><PrimaryCol /><SecondaryCol /><LinkCol /></ColorScheme></Skin>',' ',''), CHAR(13), ''), CHAR(10), '')
<> REPLACE(REPLACE(Replace( CAST(SkinXml as nvarchar(max)),' ',''), CHAR(13), ''), CHAR(10), '')
and  CAST(SkinXml as nvarchar(max)) <> ''
GO
