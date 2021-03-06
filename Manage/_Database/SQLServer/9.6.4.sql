truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.6.4');
go

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
		DECLARE @SkinDate DateTime = null
		IF @SkinXml <> ''
		BEGIN
			SET @SkinDate = GETUTCDATE()
		END

		INSERT INTO Template_Group (template_group_guid, helptext, AllowPreview, PostGenerateText, 
				UpdateDocumentFields, EnforceValidation, WizardFinishText, EnforcePublishPeriod,
				PublishStartDate, PublishFinishDate, HideNavigationPane, Template_Guid, Layout_Guid,
				Template_Version, Layout_Version, Folder_Guid, ShowFormActivity, MatchProjectVersion,
				AllowRestart, OfflineDataSources, LogPageTransition, SkinXml, AllowSave, SkinLastUpdated)
		VALUES (@ProjectGroupGuid, @HelpText, @AllowPreview, @PostGenerateText, 
				@UpdateDocumentFields, @EnforceValidation, @WizardFinishText, @EnforcePublishPeriod,
				@PublishStartDate, @PublishFinishDate, @HideNavigationPane, @ProjectGuid, @LayoutGuid,
				@ProjectVersion, @LayoutVersion, @FolderGuid, @ShowFormActivity, @MatchProjectVersion,
				@AllowRestart, @OfflineDataSources,@LogPageTransition, @SkinXml, @AllowSave, @SkinDate);
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

update [Template_Group]  set SkinLastUpdated = GETUTCDATE()
  where SkinLastUpdated is null
  and REPLACE(REPLACE(Replace('<Skin Published="-62135596800000"><Header><BackgroundCol /><FontCol /><FontLinkCol /><FontHoverCol /></Header><ColorScheme><PrimaryCol /><SecondaryCol /><LinkCol /></ColorScheme></Skin>',' ',''), CHAR(13), ''), CHAR(10), '')
<> REPLACE(REPLACE(Replace( CAST(SkinXml as nvarchar(max)),' ',''), CHAR(13), ''), CHAR(10), '')
and  CAST(SkinXml as nvarchar(max)) <> ''
GO

ALTER PROCEDURE [spProjectGrp_UpdateProjectGroupSkin]
	@ProjectGroupGuid uniqueidentifier,
	@SkinXml nvarchar(max)
AS	
		DECLARE @SkinDate DateTime = null
		IF @SkinXml <> ''
		BEGIN
			SET @SkinDate = GETUTCDATE()
		END
		UPDATE	Template_Group
		SET		SkinXml = @SkinXml, SkinLastUpdated = @SkinDate
		WHERE	Template_Group_Guid = @ProjectGroupGuid;

GO

ALTER TABLE dbo.Routing_ElementType ADD
	AllowTranslation BIT NOT NULL DEFAULT 0
GO

ALTER PROCEDURE [dbo].[spRouting_RegisterTypeAttribute]
	@RoutingTypeId uniqueidentifier,
	@Id uniqueidentifier,
	@Description nvarchar(255),
	@ElementLimit int,
	@Required bit,
	@AllowTranslation bit
AS
	IF NOT EXISTS(SELECT * FROM Routing_ElementType WHERE RoutingElementTypeId = @Id AND RoutingTypeId = @RoutingTypeId)
	  BEGIN
		INSERT INTO Routing_ElementType(RoutingElementTypeId, RoutingTypeId, ElementTypeDescription, ElementLimit, [Required], AllowTranslation)
		VALUES	(@Id, @RoutingTypeId, @Description, @ElementLimit, @Required, @AllowTranslation);
	  END
GO

UPDATE Routing_ElementType
SET AllowTranslation = 1
WHERE RoutingTypeId = '9B92350D-1673-473E-BAEF-219780CBB4BC' AND RoutingElementTypeId = 'bf1973a6-3ad2-4fb2-ab6f-23474843f921'
GO

UPDATE Routing_ElementType
SET AllowTranslation = 1
WHERE RoutingTypeId = '9B92350D-1673-473E-BAEF-219780CBB4BC' AND RoutingElementTypeId = '78587050-bc9d-4f5d-a92a-039ddf3f6b77'
GO

ALTER TABLE dbo.EscalationProperties ADD
[Language] NVARCHAR(11) DEFAULT NULL
GO

ALTER PROCEDURE [dbo].[spRouting_InsertEscalationProperty]
	@EscalationId uniqueidentifier,
	@EscalationTypeId uniqueidentifier,
	@EscalationInputValue nvarchar(max),
	@Language NVARCHAR(11) = NULL
AS
	INSERT INTO EscalationProperties(Id, EscalationId, EscalationTypeId, EscalationInputValue, [Language])
	VALUES	(NewID(), @EscalationId, @EscalationTypeId, @EscalationInputValue, @Language);
GO

ALTER PROCEDURE [dbo].[spRouting_UpdateEscalationProperty]
	@EscalationId uniqueidentifier,
	@EscalationTypeId uniqueidentifier,
	@EscalationInputValue nvarchar(max),
	@Language NVARCHAR(11) = NULL
AS
	UPDATE EscalationProperties
	SET	   EscalationInputValue = @EscalationInputValue
	WHERE  EscalationId = @EscalationId 
	       AND EscalationTypeId = @EscalationTypeId
		   AND [Language] = @Language
GO

UPDATE Routing_ElementType
SET AllowTranslation = 1
WHERE RoutingTypeId = 'AF6B7A2C-7DED-449B-B706-13B60DE5BE86' AND RoutingElementTypeId = 'B8BC1B2B-50C4-4DD4-B902-E6C18EB53318'
GO

UPDATE Routing_ElementType
SET AllowTranslation = 1
WHERE RoutingTypeId = 'AF6B7A2C-7DED-449B-B706-13B60DE5BE86' AND RoutingElementTypeId = 'D0873C6F-1FED-4CAD-8F36-46871B88E01A'
GO

CREATE TABLE [dbo].[Template_Translation](
	[Template_Guid] [uniqueidentifier] NOT NULL,
	[Language] [nvarchar](11) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[Version] [nvarchar](10) NOT NULL,
 CONSTRAINT [PK_Template_Translation] PRIMARY KEY CLUSTERED 
(
	[Template_Guid] ASC,
	[Language] ASC,
	[Version] ASC
) ON [PRIMARY]
)
GO

CREATE PROCEDURE [dbo].[spProject_UpdateTranslation]
	@ProjectGuid uniqueidentifier,
	@NextVersion nvarchar(10),
	@Language nvarchar(11),
	@Name nvarchar(100)
AS
BEGIN
  INSERT INTO Template_Translation(Template_Guid, [Version], [Language], [Name])
  VALUES (@ProjectGuid, @NextVersion, @Language, @Name)
END
GO

CREATE PROCEDURE [dbo].[spProject_Translations] (
	@ProjectGuid uniqueidentifier,
	@Version nvarchar(10) = '0',
	@Language nvarchar(11) 
)
AS
BEGIN
   IF @Version = '0'
   BEGIN
     SET @Version = (SELECT Template_Version FROM Template WHERE Template_Guid = @ProjectGuid)
   END

	IF (SELECT COUNT(Template_Guid) FROM Template_Translation WHERE Template_Guid = @ProjectGuid AND [Version] = @Version AND [Language] = @Language) > 0
	  BEGIN
		SELECT  *
		FROM	Template_Translation 
		WHERE	Template_Guid = @ProjectGuid
			    AND [Version] = @Version
				AND [Language] = @Language
	  END
	ELSE
	  BEGIN
	  IF CHARINDEX('-',@Language) > 0
	   BEGIN 
	     SET @Language = SUBSTRING(@Language, 0, CHARINDEX('-',@Language))
	     SELECT  *
		 FROM	Template_Translation 
		 WHERE	Template_Guid = @ProjectGuid
			    AND [Version] = @Version
				AND [Language] = @Language
	   END
	 END
 END
 GO

 ALTER PROCEDURE [dbo].[spProject_DeleteOldProjectVersion]
	@ProjectGuid uniqueidentifier,
	@NextVersion nvarchar(10),
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN

	IF (SELECT COUNT(*) 
		FROM Template_Group 
		WHERE (Template_Group.Layout_Guid = @ProjectGuid OR Template_Group.Template_Guid = @ProjectGuid)
			AND Template_Group.MatchProjectVersion = 1) = 0
	BEGIN
	
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

		DELETE FROM Xtf_Datasource_Dependency
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	vwTemplateVersion
					WHERE	Template_Guid = @ProjectGuid);

		DELETE FROM Xtf_ContentLibrary_Dependency
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	vwTemplateVersion
					WHERE	Template_Guid = @ProjectGuid);

		DELETE FROM Xtf_Fragment_Dependency
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	vwTemplateVersion
					WHERE	Template_Guid = @ProjectGuid);
				
		DELETE FROM Template_File_Version
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	vwTemplateVersion
					WHERE	Template_Guid = @ProjectGuid);

		DELETE FROM Template_Translation
		WHERE	Template_Guid = @ProjectGuid
				AND [Version] NOT IN (
					SELECT	Template_Version
					FROM	vwTemplateVersion
					WHERE	Template_Guid = @ProjectGuid);
	END
END
GO
