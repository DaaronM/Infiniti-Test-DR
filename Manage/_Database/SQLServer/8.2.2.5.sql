/*
** Database Update package 8.2.2.5
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.2.5');
go


ALTER TABLE dbo.RecurrencePattern
ADD Timezone nvarchar(50) NULL DEFAULT NULL
GO

CREATE PROCEDURE [dbo].[sp_DeleteRecurrenceById] (
	@RecurrencePatternId uniqueidentifier)
AS
	DELETE FROM RecurrencePattern 
	WHERE RecurrencePatternID = @RecurrencePatternId
GO


/* Add timezone to update recurrence pattern stored procedure */
ALTER PROCEDURE [dbo].[spJob_UpdateRecurrencePattern] (
	@RecurrencePatternID uniqueidentifier,
	@JobDefinitionId uniqueidentifier,
	@Frequency [varchar](10),
	@StartDate [datetime],
	@RepeatUntil [datetime],
	@RepeatCount [int],
	@Interval [int],
	@ByDay [varchar](50),
	@ByMonthDay [varchar](50),
	@ByYearDay [varchar](50),
	@ByWeekNo [varchar](50),
	@ByMonth [varchar](50),
	@BySetPosition [int],
	@WeekStart [varchar](2),
	@Timezone [varchar](50))
AS
	IF NOT EXISTS(SELECT * FROM RecurrencePattern WHERE RecurrencePatternID = @RecurrencePatternId)
	BEGIN
		INSERT INTO RecurrencePattern (RecurrencePatternID, JobDefinitionId, Frequency, StartDate, RepeatUntil, RepeatCount, Interval, ByDay, ByMonthDay, ByYearDay, ByWeekNo, ByMonth, BySetPosition, WeekStart, Timezone)
		VALUES (@RecurrencePatternID, @JobDefinitionId, @Frequency, @StartDate, @RepeatUntil, @RepeatCount, @Interval, @ByDay, @ByMonthDay, @ByYearDay, @ByWeekNo, @ByMonth, @BySetPosition, @WeekStart, @Timezone);
	END
	ELSE
	BEGIN
		UPDATE	RecurrencePattern
		SET		JobDefinitionId = @JobDefinitionId,
				Frequency = @Frequency,
				StartDate = @StartDate,
				RepeatUntil = @RepeatUntil,
				RepeatCount = @RepeatCount,
				Interval = @Interval,
				ByDay = @ByDay,
				ByMonthDay = @ByMonthDay,
				ByYearDay = @ByYearDay,
				ByWeekNo = @ByWeekNo,
				ByMonth = @ByMonth,
				BySetPosition = @BySetPosition,
				WeekStart = @WeekStart,
				Timezone = @Timezone
		WHERE	RecurrencePatternID = @RecurrencePatternID;
	END
GO

CREATE TABLE [dbo].[Workflow_Escalation](
	[EscalationId] [uniqueidentifier] NOT NULL,
	[RecurrenceId] [uniqueidentifier] NOT NULL,
	[ActionListStateId] [uniqueidentifier] NOT NULL,
	[EscalateOnUtc] [datetime] NULL,
	[EscalateEmailBody] [nvarchar](max) NULL,
	[EscalateEmailSubject] [nvarchar](400) NULL,
	[EscalateEmailCC] [nvarchar](400) NULL,
	[SendToAssignee] [bit] NOT NULL,
 CONSTRAINT [PK_Workflow_Escalation] PRIMARY KEY CLUSTERED 
(
	[EscalationId] ASC
)
)

GO

/* Migrate data from ActionListState to workflow escalation and recurrence pattern */
INSERT INTO RecurrencePattern([RecurrencePatternID]
      ,[JobDefinitionId]
      ,[Frequency]
      ,[StartDate]
      ,[RepeatUntil]
      ,[RepeatCount]
      ,[Interval]
      ,[ByDay]
      ,[ByMonthDay]
      ,[ByYearDay]
      ,[ByWeekNo]
      ,[ByMonth]
      ,[BySetPosition]
      ,[WeekStart]
      ,[Timezone])
SELECT   ActionListStateId
		,'00000000-0000-0000-0000-000000000000'
		,'Daily'
		,DateCreatedUtc,null,100,1,'','','','','',0	,'MO'
		,NULL

FROM ActionListState
WHERE StateGuid <> '11111111-1111-1111-1111-111111111111' 
	AND ExpireOnUtc IS NOT NULL

INSERT INTO Workflow_Escalation ([EscalationId]
      ,[RecurrenceId]
      ,[ActionListStateId]
      ,[EscalateOnUtc]
      ,[EscalateEmailBody]
      ,[EscalateEmailSubject]
      ,[EscalateEmailCC]
      ,[SendToAssignee])
SELECT	NewID()
		,ActionListStateId
		,ActionListStateId
		,ExpireOnUtc
		,ExpiryEmailBody
		,ExpiryEmailSubject
		,''
		,'1'
FROM ActionListState
WHERE StateGuid <> '11111111-1111-1111-1111-111111111111' 
	AND ExpireOnUtc IS NOT NULL
GO


ALTER TABLE ActionListState
DROP COLUMN ExpireOnUtc, ExpiryEmailBody, ExpiryEmailSubject
GO

/* Update FinishDate to GetUtcDate() */
ALTER procedure [dbo].[spLog_CompleteProjectLog]
	@LogGuid uniqueidentifier,
	@MessageXml xml = null
AS
	DECLARE @FinishDate datetime;
	
	SET @FinishDate = GetUtcDate();
	
	UPDATE	Template_Log 
	SET		DateTime_Finish = @FinishDate, 
			Completed = 1,
			Messages = @MessageXml,
			InProgress = 0
	WHERE	Log_Guid = @LogGuid;
GO

