truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.2.1');
GO
ALTER TABLE Routing_Type
	ADD UsesDocuments int NOT NULL DEFAULT 2
GO
ALTER PROCEDURE [dbo].[spRouting_RegisterType]
	@Id uniqueidentifier,
	@Description nvarchar(255),
	@ProviderType int,
	@RunForAllProjects bit,
	@SupportsRun bit,
	@SupportsUI bit,
	@SupportsRecurring bit,
	@ModuleId nvarchar(4),
	@UsesDocuments int
AS
	IF NOT EXISTS(SELECT * FROM Routing_Type WHERE RoutingTypeId = @id)
	BEGIN
		INSERT INTO Routing_Type(RoutingTypeId, RoutingTypeDescription, ProviderType, RunForAllProjects, SupportsRun, SupportsUI, SupportsRecurring, ModuleId, UsesDocuments)
		VALUES	(@id, @Description, @ProviderType, @RunForAllProjects, @SupportsRun, @SupportsUI, @SupportsRecurring, @ModuleId, @UsesDocuments);
	END
GO
UPDATE Routing_Type SET UsesDocuments = 0 WHERE RoutingTypeId = 'AF6B7A2C-7DED-449B-B706-13B60DE5BE86'
UPDATE Routing_Type SET UsesDocuments = 0 WHERE RoutingTypeId = '442632fa-2710-4bac-affb-73bc5e77cb17'
UPDATE Routing_Type SET UsesDocuments = 0 WHERE RoutingTypeId = '6C8F8992-D770-4309-9BDD-1911014565F2'
UPDATE Routing_Type SET UsesDocuments = 0 WHERE RoutingTypeId = '2f59f7b6-3647-495b-8398-a825709ed96c'
UPDATE Routing_Type SET UsesDocuments = 0 WHERE RoutingTypeId = 'AFCAF706-F65A-4808-8F1F-4AA11257EFE0'
UPDATE Routing_Type SET UsesDocuments = 0 WHERE RoutingTypeId = 'BE2021EB-8A4A-4C9E-B9B3-AD4B1CA4D6BE'
UPDATE Routing_Type SET UsesDocuments = 0 WHERE RoutingTypeId = '0E792312-BAFE-444A-A789-C7B0B4111938'
UPDATE Routing_Type SET UsesDocuments = 0 WHERE RoutingTypeId = '4280DE2E-BE04-4ED4-9C42-285C258396E2'
UPDATE Routing_Type SET UsesDocuments = 0 WHERE RoutingTypeId = '085D87A5-14F1-4F78-BC79-54D06B924F8D'
UPDATE Routing_Type SET UsesDocuments = 1 WHERE RoutingTypeId = '230DD56C-0018-4D49-945E-5B6E5B08EAF6'
UPDATE Routing_Type SET UsesDocuments = 1 WHERE RoutingTypeId = '739B7667-B8ED-42D5-8A49-3A9A890FBE88'
GO

IF EXISTS(SELECT * FROM sys.procedures 
          WHERE Name = 'spLog_TemplateLogListByRunId')
BEGIN
	SET NOEXEC ON;
END
GO

CREATE procedure [dbo].[spLog_TemplateLogListByRunId]
	@RunId varchar(50) = '',
	@ErrorCode int output
as
	SELECT	Template_Log.Log_Guid, Template_Log.Answer_File, Template_Log.EncryptedAnswerFile, 
	Template_Log.Last_Bookmark_Group_Guid, Template_Log.ActionListStateId
	FROM	Template_Log
	WHERE	Template_Log.RunID = @RunId
	
	set @ErrorCode = @@error;

GO
	
DROP procedure [dbo].[spLog_TemplateLogListByTaskListId];
GO

SET NOEXEC OFF
GO
ALTER PROCEDURE [dbo].[spProject_UnlockProject]
	@ProjectGuid uniqueidentifier,
	@VersionComment nvarchar(max) = '',
	@UserGuid uniqueidentifier,
	@ForceUnlock bit
AS
	BEGIN TRAN
		--Allows unlock either by any user if its a force unlock OR by the same user who has currently locked the project if general unlock
		IF @ForceUnlock = 1 OR (@ForceUnlock = 0 AND EXISTS(SELECT LockedByUserGuid FROM Template WHERE Template_Guid = @ProjectGuid AND LockedByUserGuid = @UserGuid))
		BEGIN
			DECLARE @FinalComment AS NVARCHAR(MAX) = ISNULL((SELECT Comment FROM Template WHERE Template_Guid = @ProjectGuid),'')
			
			IF LEN(@FinalComment) = 0
			BEGIN
				SET @FinalComment = @VersionComment
			END
			ELSE IF LEN(@VersionComment) > 0
			BEGIN
				SET @FinalComment = @VersionComment + CHAR(13) + @FinalComment
			END

			UPDATE	Template
			SET		LockedByUserGuid = NULL,
					Comment = @FinalComment,
					IsMajorVersion = 1
			WHERE	Template_Guid = @ProjectGuid;
		END
	COMMIT
GO
IF EXISTS(SELECT * FROM sys.procedures WHERE Name = 'spLibrary_GetCustomFieldBinary')
BEGIN
	DROP PROCEDURE spLibrary_GetCustomFieldBinary;
END
GO
CREATE PROCEDURE [dbo].[spLibrary_GetCustomFieldBinary] (
	@UserGuid as uniqueidentifier,
	@DataGuid as uniqueidentifier
)
AS
	DECLARE @DataGuidString NVARCHAR(36)

	SET @DataGuidString = CAST(@DataGuid as NVARCHAR(36));

	IF EXISTS(
		-- Profile
		SELECT	Intelledox_User.User_Guid
		FROM	Intelledox_User
				INNER JOIN Address_Book_Custom_Field ON Intelledox_User.Address_ID = Address_Book_Custom_Field.Address_ID
		WHERE	Intelledox_User.User_Guid = @UserGuid
				AND Address_Book_Custom_Field.Custom_Value = @DataGuidString) OR
		EXISTS(
		-- Contact
		SELECT	Intelledox_User.User_Guid
		FROM	Intelledox_User
				INNER JOIN User_Address_Book ON Intelledox_User.User_ID = User_Address_Book.User_ID
				INNER JOIN Address_Book_Custom_Field ON User_Address_Book.Address_ID = Address_Book_Custom_Field.Address_ID
		WHERE	Intelledox_User.User_Guid = @UserGuid
				AND Address_Book_Custom_Field.Custom_Value = @DataGuidString)
	BEGIN
		SELECT	cd.ContentData as [Binary]
		FROM	ContentData_Binary cd
		WHERE	ContentData_Guid = @DataGuid;
	END
GO

ALTER TABLE [dbo].[Template_Group] DROP  CONSTRAINT [DF_Template_Group_TroubleshootingMode] 
GO
ALTER TABLE Template_Group
ALTER COLUMN TroubleshootingMode INT
GO
ALTER TABLE [dbo].[Template_Group] ADD  CONSTRAINT [DF_Template_Group_TroubleshootingMode]  DEFAULT ((0)) FOR [TroubleshootingMode]
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

ALTER TABLE ProcessJob
	ADD Scheduled bit NULL
GO

ALTER PROCEDURE [dbo].[spJob_LodgeJob] (
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier,
	@DateStarted datetime,
	@ProjectGroupGuid uniqueidentifier,
	@LogGuid uniqueidentifier,
	@JobDefinitionGuid uniqueidentifier,
	@InitialStatus int,
	@QueueUntil datetime,
	@Scheduled bit
)
AS
	IF (@ProjectGroupGuid IS NULL AND @JobDefinitionGuid IS NOT NULL)
	BEGIN
		SELECT	@ProjectGroupGuid = JobDefinition.value('data(AnswerFile/HeaderInfo/TemplateInfo/@TemplateGroupGuid)[1]', 'uniqueidentifier')
		FROM	JobDefinition
		WHERE	JobDefinitionId = @JobDefinitionGuid;
	END

	INSERT INTO ProcessJob(JobId, UserGuid, DateStarted, ProjectGroupGuid, CurrentStatus, LogGuid, JobDefinitionGuid, QueueUntil, Scheduled)
	VALUES (@JobId, @UserGuid, @DateStarted, @ProjectGroupGuid, @InitialStatus, @LogGuid, @JobDefinitionGuid, @QueueUntil, @Scheduled);
GO

ALTER PROCEDURE [dbo].[spJob_QueueList]
	@BusinessUnitGuid uniqueidentifier,
	@StartDate DateTime,
	@FinishDate DateTime,
	@CurrentStatus Int,
	@Scheduled Bit
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus, ProcessJob.Scheduled,
			Template.Name as ProjectName, Intelledox_User.Username, ProcessJob.UserGuid,
			ProcessJob.LogGuid, ProcessJob.QueueUntil,
			CASE WHEN template_Log.Messages IS NOT NULL THEN 1 ELSE 0 END AS HasMessages
	FROM	ProcessJob
			LEFT JOIN Intelledox_User ON ProcessJob.UserGuid = Intelledox_User.User_Guid
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
			LEFT JOIN Template_Log ON ProcessJob.LogGuid = Template_Log.Log_Guid
	WHERE	ProcessJob.DateStarted BETWEEN @StartDate AND @FinishDate
			AND ((@CurrentStatus = 0) OR 
				(@CurrentStatus = -1 AND ProcessJob.CurrentStatus <> 7) OR 
				(@CurrentStatus <> -1 AND ProcessJob.CurrentStatus = @CurrentStatus))
			AND Template.Business_Unit_Guid = @BusinessUnitGuid
			AND (ISNULL(ProcessJob.Scheduled, 0) = 0 OR ProcessJob.Scheduled = @Scheduled)
	ORDER BY ProcessJob.DateStarted DESC;
GO
