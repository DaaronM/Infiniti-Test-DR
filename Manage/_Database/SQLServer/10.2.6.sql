TRUNCATE TABLE dbversion;
GO
INSERT INTO dbversion(dbversion) VALUES ('10.2.6');
GO
ALTER procedure [dbo].[spOptions_UpdateOptionValue]
	@BusinessUnitGuid uniqueidentifier,
	@Code nvarchar(255),
	@Value nvarchar(max)
as
	UPDATE	Global_Options
	SET		optionvalue = @Value
	WHERE	optioncode = @Code
			AND BusinessUnitGuid = @BusinessUnitGuid;
GO

ALTER TABLE ProcessJob
ADD [Messages] [xml] NULL
GO

UPDATE ProcessJob
SET [Messages] = tl.[Messages]
FROM Template_Log tl
INNER JOIN ProcessJob pj ON pj.LogGuid = tl.Log_Guid
GO

ALTER TABLE Template_log
	DROP COLUMN [Messages]
GO

ALTER procedure [dbo].[spLog_CompleteProjectLog]
	@LogGuid uniqueidentifier,
	@FinishDate datetime,
	@UpdateRecent bit = 0,
	@IsWorkflowState bit = 0,
	@RunId uniqueidentifier = null,
	@Latitude decimal(9,6) = NULL,
	@Longitude decimal(9,6) = NULL
AS
	DECLARE @UserGuid uniqueidentifier;
	DECLARE @TemplateGroupGuid uniqueidentifier;
	
	SET NOCOUNT ON;

	UPDATE	Template_Log 
	SET		DateTime_Finish = @FinishDate, 
			Completionstate = CASE WHEN @IsWorkflowState = 1 THEN 2 ELSE 3 END,
			RunId = ISNULL(@RunId, RunId),
			Latitude = ISNULL(@Latitude, Latitude),
			Longitude = ISNULL(@Longitude, Longitude)
	WHERE	Log_Guid = @LogGuid;
	
	
	If @UpdateRecent = 1
	BEGIN
		SET @UserGuid = (SELECT User_Guid 
							FROM Template_Log
							INNER JOIN Intelledox_User ON Template_Log.[User_ID] = Intelledox_User.[User_ID]
							WHERE Log_Guid = @LogGuid);

		SET	@TemplateGroupGuid = (SELECT Template_Group_Guid 
								FROM Template_Log
								INNER JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
								WHERE Log_Guid = @LogGuid);

		--update recent completed log
		UPDATE	Template_Recent
		SET		Log_Guid = @LogGuid
		WHERE	User_Guid = @UserGuid 
				AND Template_Group_Guid = @TemplateGroupGuid;
	END
GO

ALTER PROCEDURE [dbo].[spJob_UpdateStatus] (
	@JobId uniqueidentifier,
	@CurrentStatus int,
	@MessageXml xml = null
)
AS
	UPDATE	ProcessJob
	SET		CurrentStatus = @CurrentStatus,
			[Messages] = IsNull(@MessageXml, [Messages])
	WHERE	JobId = @JobId;
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
			CASE WHEN ProcessJob.[Messages] IS NOT NULL THEN 1 ELSE 0 END AS HasMessages
	FROM	ProcessJob
			LEFT JOIN Intelledox_User ON ProcessJob.UserGuid = Intelledox_User.User_Guid
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
	WHERE	ProcessJob.DateStarted BETWEEN @StartDate AND @FinishDate
			AND ((@CurrentStatus = 0) OR 
				(@CurrentStatus = -1 AND ProcessJob.CurrentStatus <> 7) OR 
				(@CurrentStatus <> -1 AND ProcessJob.CurrentStatus = @CurrentStatus))
			AND Template.Business_Unit_Guid = @BusinessUnitGuid
			AND (ISNULL(ProcessJob.Scheduled, 0) = 0 OR ProcessJob.Scheduled = @Scheduled)
	ORDER BY ProcessJob.DateStarted DESC;
GO

ALTER PROCEDURE [dbo].[spJob_QueueListByDefinition]
	@JobDefinitionId uniqueidentifier
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus,
			Template.Name as ProjectName, Intelledox_User.Username, 
			ProcessJob.LogGuid, ProcessJob.QueueUntil,
			CASE WHEN ProcessJob.[Messages] IS NOT NULL THEN 1 ELSE 0 END AS HasMessages
	FROM	ProcessJob
			INNER JOIN Intelledox_User ON ProcessJob.UserGuid = Intelledox_User.User_Guid
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
	WHERE	ProcessJob.JobDefinitionGuid = @JobDefinitionId
	ORDER BY ProcessJob.DateStarted DESC;
GO

create PROCEDURE spTenant_ResetTenancyKeyDateTime  
 @BusinessUnitGuid uniqueidentifier,  
  @TenancyKeyDateUtc datetime
AS  
 UPDATE Business_Unit  
 SET  TenancyKeyDateUtc = @TenancyKeyDateUtc  
 WHERE Business_Unit_Guid = @BusinessUnitGuid;  
 GO
