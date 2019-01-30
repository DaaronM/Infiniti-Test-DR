/*
** Database Update package 7.0.0.2
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.0.0.2')
go

--1935
ALTER procedure [dbo].[spLibrary_RestoreVersion]
	@ContentItemGuid uniqueidentifier,
	@VersionNumber int,
	@UserGuid uniqueidentifier
AS
	SET NOCOUNT ON
	
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @IsBinary bit
	
	SELECT	@ContentData_Guid = ContentData_Guid, 
			@IsBinary = CASE WHEN ContentType_Id = 2 THEN 0 ELSE 1 END
	FROM	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;
		
	BEGIN TRAN	
	
	EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, @IsBinary;
	
	IF (@IsBinary = 1)
	BEGIN
		UPDATE	ContentData_Binary
		SET		ContentData = ContentData_Binary_Version.ContentData, 
				FileType = ContentData_Binary_Version.FileType,
				ContentData_Version = ContentData_Binary.ContentData_Version + 1, 
				Modified_Date = GetUTCdate(),
				Modified_By = @UserGuid
		FROM	ContentData_Binary, 
				ContentData_Binary_Version
		WHERE	ContentData_Binary.ContentData_Guid = @ContentData_Guid
				AND ContentData_Binary_Version.ContentData_Guid = @ContentData_Guid 
				AND	ContentData_Binary_Version.ContentData_Version = @VersionNumber;
	END
	ELSE
	BEGIN
		UPDATE	ContentData_Text
		SET		ContentData = ContentData_Text_Version.ContentData, 
				ContentData_Version = ContentData_Text.ContentData_Version + 1, 
				Modified_Date = GetUTCdate(),
				Modified_By = @UserGuid
		FROM	ContentData_Text, 
				ContentData_Text_Version
		WHERE	ContentData_Text.ContentData_Guid = @ContentData_Guid
				AND ContentData_Text_Version.ContentData_Guid = @ContentData_Guid 
				AND	ContentData_Text_Version.ContentData_Version = @VersionNumber;
	END
	
	EXEC spLibrary_ClearExcessVersions @ContentData_Guid, @IsBinary;
		
	COMMIT
GO


--1936
CREATE procedure [dbo].[spContent_ContentItemListBySearch]
	@BusinessUnitGuid uniqueidentifier,
	@SearchString NVarChar(1000),
	@ContentTypeId Int
AS
	SELECT	ci.*, 
			Content.FileType, 
			Content.Modified_Date, 
			Intelledox_User.UserName,
			0 as HasUnapprovedRevision
	FROM	content_item ci
			LEFT JOIN (
				SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
				FROM	ContentData_Binary
				UNION
				SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
				FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
			LEFT JOIN Category ON ci.Category = Category.Category_ID
	WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
			AND ci.Approved = 2
			AND ci.ContentType_Id = @ContentTypeId
			AND (ci.NameIdentity LIKE '%' + @SearchString + '%'
				OR ci.Description LIKE '%' + @SearchString + '%'
				OR Category.Name LIKE '%' + @SearchString + '%'
				)
	ORDER BY ci.NameIdentity;
GO
CREATE procedure [dbo].[spContent_ContentItemListBySearchFullText]
	@BusinessUnitGuid uniqueidentifier,
	@SearchString NVarChar(1000),
	@FullTextSearchString NVarChar(1000),
	@ContentTypeId Int
AS
	SELECT	ci.*, 
			Content.FileType, 
			Content.Modified_Date, 
			Intelledox_User.UserName,
			0 as HasUnapprovedRevision
	FROM	content_item ci
			LEFT JOIN (
				SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
				FROM	ContentData_Binary
				UNION
				SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
				FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
			LEFT JOIN Category ON ci.Category = Category.Category_ID
	WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
			AND ci.Approved = 2
			AND ci.ContentType_Id = @ContentTypeId
			AND (ci.NameIdentity LIKE '%' + @SearchString + '%'
				OR ci.Description LIKE '%' + @SearchString + '%'
				OR Category.Name LIKE '%' + @SearchString + '%'
				AND (ci.ContentData_Guid IN (
						SELECT	ContentData_Guid
						FROM	ContentData_Binary cdb
						WHERE	Contains(*, @FullTextSearchString)
						)
					OR
					ci.ContentData_Guid IN (
						SELECT	ContentData_Guid
						FROM	ContentData_Text cdt
						WHERE	Contains(*, @FullTextSearchString)
						)
					)
				)
	ORDER BY ci.NameIdentity;
GO

--1937
DROP TABLE Job;
GO
DROP PROCEDURE spJob_CreateJob
GO
CREATE TABLE JobDefinition (
	JobDefinitionId uniqueidentifier primary key,
	Name nvarchar(200),
	NextRunDate datetime null,
	IsEnabled bit,
	OwnerGuid uniqueidentifier,
	DateCreated datetime,
	DateModified datetime,
	JobDefinition xml
	)
GO
CREATE PROCEDURE spJob_CreateJobDefinition(
	@JobDefinitionId uniqueidentifier,
	@Name nvarchar(200),
	@IsEnabled bit,
	@OwnerGuid uniqueidentifier,
	@DateCreated datetime,
	@DateModified datetime,
	@JobDefinition xml
)
AS
	INSERT INTO JobDefinition(JobDefinitionId, Name, NextRunDate, IsEnabled, OwnerGuid, DateCreated, DateModified, JobDefinition)
	VALUES (@JobDefinitionId, @Name, NULL, @IsEnabled, @OwnerGuid, @DateCreated, @DateModified, @JobDefinition);
GO
ALTER TABLE ProcessJob
	ADD JobDefinitionGuid uniqueidentifier null
GO
ALTER PROCEDURE [dbo].[spJob_LodgeJob] (
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier,
	@DateStarted datetime,
	@ProjectGroupGuid uniqueidentifier,
	@LogGuid uniqueidentifier,
	@JobDefinitionGuid uniqueidentifier
)
AS
	IF (@ProjectGroupGuid IS NULL AND @JobDefinitionGuid IS NOT NULL)
	BEGIN
		SELECT	@ProjectGroupGuid = JobDefinition.value('data(AnswerFile/HeaderInfo/TemplateInfo/@TemplateGroupGuid)[1]', 'uniqueidentifier')
		FROM	JobDefinition
		WHERE	JobDefinitionId = @JobDefinitionGuid;
	END

	INSERT INTO ProcessJob(JobId, UserGuid, DateStarted, ProjectGroupGuid, CurrentStatus, LogGuid, JobDefinitionGuid)
	VALUES (@JobId, @UserGuid, @DateStarted, @ProjectGroupGuid, 1, @LogGuid, @JobDefinitionGuid);
GO
CREATE PROCEDURE spJob_DeleteJobDefinition(
	@JobDefinitionId uniqueidentifier
)
AS
	DELETE FROM JobDefinition
	WHERE	JobDefinitionId = @JobDefinitionId;
GO
CREATE PROCEDURE [dbo].[spJob_UpdateJobDefinition](
	@JobDefinitionId uniqueidentifier,
	@Name nvarchar(200),
	@IsEnabled bit,
	@OwnerGuid uniqueidentifier,
	@DateModified datetime,
	@JobDefinition xml
)
AS
	UPDATE	JobDefinition
	SET		Name = @Name, 
			IsEnabled = @IsEnabled, 
			OwnerGuid = @OwnerGuid, 
			DateModified = @DateModified, 
			JobDefinition = @JobDefinition
	WHERE	JobDefinitionId = @JobDefinitionId;
GO
CREATE PROCEDURE spJob_JobDefinitionList(
	@JobDefinitionId uniqueidentifier
)
AS
	SELECT	*
	FROM	JobDefinition
	WHERE	JobDefinitionId = @JobDefinitionId;
GO
CREATE PROCEDURE [dbo].[spJob_Queued]
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus,
			ProcessJob.LogGuid, ProcessJob.JobDefinitionGuid
	FROM	ProcessJob
	WHERE	ProcessJob.CurrentStatus = 1
			AND ProcessJob.JobDefinitionGuid IS NOT NULL
	ORDER BY ProcessJob.DateStarted DESC;
GO
CREATE PROCEDURE spJob_DueList
AS
	SELECT	* 
	FROM	JobDefinition
	WHERE	NextRunDate <= GETUTCDATE();
GO
CREATE PROCEDURE spJob_QueuedJobList
	@Jobid uniqueidentifier
AS
	SELECT	*
	FROM	ProcessJob
	WHERE	JobId = @Jobid;
GO
CREATE PROCEDURE spJob_UpdateQueuedJob
	@JobId uniqueidentifier,
	@DateStarted datetime,
	@Status int,
	@LogGuid uniqueidentifier,
	@JobDefinitionGuid uniqueidentifier
AS
	UPDATE	ProcessJob
	SET		DateStarted = @DateStarted,
			CurrentStatus = @Status,
			LogGuid = @LogGuid,
			JobDefinitionGuid = JobDefinitionGuid
	WHERE	JobId = @JobId;
GO

--1938
CREATE TABLE [RecurrencePattern](
	[RecurrencePatternID] uniqueidentifier NOT NULL,
	JobDefinitionId uniqueidentifier NOT NULL,
	[Frequency] [varchar](10) NULL,
	[StartDate] [datetime] NOT NULL,
	[RepeatUntil] [datetime] NULL,
	[RepeatCount] [int] NULL,
	[Interval] [int] NULL,
	[ByDay] [varchar](50) NULL,
	[ByMonthDay] [varchar](50) NULL,
	[ByYearDay] [varchar](50) NULL,
	[ByWeekNo] [varchar](50) NULL,
	[ByMonth] [varchar](50) NULL,
	[BySetPosition] [int] NULL,
	[WeekStart] [varchar](2) NULL
	 CONSTRAINT [PK_RecurrencePattern] PRIMARY KEY CLUSTERED 
	(
		[RecurrencePatternID] ASC
	)
)
GO
CREATE PROCEDURE spJob_UpdateRecurrencePattern (
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
	@WeekStart [varchar](2))
AS
	IF NOT EXISTS(SELECT * FROM RecurrencePattern WHERE RecurrencePatternID = @RecurrencePatternId)
	BEGIN
		INSERT INTO RecurrencePattern (Frequency, JobDefinitionId, StartDate, RepeatUntil, RepeatCount, 
				Interval, ByDay, ByMonthDay, ByYearDay, ByWeekNo, ByMonth, BySetPosition, WeekStart)
		VALUES (@Frequency, @JobDefinitionId, @StartDate, @RepeatUntil, @RepeatCount, 
				@Interval, @ByDay, @ByMonthDay, @ByYearDay, @ByWeekNo, @ByMonth, @BySetPosition, @WeekStart);
	END
	ELSE
	BEGIN
		UPDATE	RecurrencePattern
		SET		Frequency = @Frequency,
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
				WeekStart = @WeekStart
		WHERE	RecurrencePatternID = @RecurrencePatternID;
	END
GO
CREATE PROCEDURE spJob_RecurrencePatternList
	@RecurrencePatternId uniqueidentifier,
	@JobDefinitionId uniqueidentifier
AS
	IF @JobDefinitionId IS NULL
		SELECT	*
		FROM	RecurrencePattern
		WHERE	RecurrencePatternID = @RecurrencePatternId;
	ELSE
		SELECT	*
		FROM	RecurrencePattern
		WHERE	JobDefinitionId = @JobDefinitionId;
GO
CREATE PROCEDURE spJob_UpdateNextRun
	@JobDefinitionId uniqueidentifier,
	@RunDate datetime
AS
	UPDATE	JobDefinition
	SET		NextRunDate = @RunDate
	WHERE	JobDefinitionId = @JobDefinitionId;
GO

--1939
CREATE PROCEDURE spJob_SetQueueStatus
	@NewState int,
	@JobId uniqueidentifier
AS
	IF @JobId IS NULL
		--Update all queued or paused items
		UPDATE	ProcessJob
		SET		CurrentStatus = @NewState
		WHERE	(CurrentStatus = 1
				OR CurrentStatus = 3);
	ELSE
		UPDATE	ProcessJob
		SET		CurrentStatus = @NewState
		WHERE	JobId = @JobId
				AND (CurrentStatus = 1
					OR CurrentStatus = 3);
GO

--1940
ALTER PROCEDURE [dbo].[spJob_JobDefinitionList](
	@JobDefinitionId uniqueidentifier
)
AS
	IF @JobDefinitionId IS NULL
		SELECT	*
		FROM	JobDefinition
		ORDER BY Name;
	ELSE
		SELECT	*
		FROM	JobDefinition
		WHERE	JobDefinitionId = @JobDefinitionId;
GO
ALTER PROCEDURE [dbo].[spJob_UpdateJobDefinition](
	@JobDefinitionId uniqueidentifier,
	@Name nvarchar(200),
	@IsEnabled bit,
	@OwnerGuid uniqueidentifier,
	@DateModified datetime,
	@JobDefinition xml
)
AS
	UPDATE	JobDefinition
	SET		Name = @Name, 
			IsEnabled = @IsEnabled, 
			OwnerGuid = @OwnerGuid, 
			DateModified = @DateModified, 
			JobDefinition = @JobDefinition
	WHERE	JobDefinitionId = @JobDefinitionId;
GO
CREATE PROCEDURE [dbo].[spJob_QueueListByDefinition]
	@JobDefinitionId uniqueidentifier
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus,
			Template.Name as ProjectName, Intelledox_User.Username, 
			ProcessJob.LogGuid,
			CASE WHEN template_Log.Messages IS NOT NULL THEN 1 ELSE 0 END AS HasMessages
	FROM	ProcessJob
			INNER JOIN Intelledox_User ON ProcessJob.UserGuid = Intelledox_User.User_Guid
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template_Group_Item ON Template_Group.Template_Group_Guid = Template_Group_Item.Template_Group_Guid
			INNER JOIN Template ON Template_Group_Item.Template_Guid = Template.Template_Guid
			LEFT JOIN Template_Log ON ProcessJob.LogGuid = Template_Log.Log_Guid
	WHERE	ProcessJob.JobDefinitionGuid = @JobDefinitionId
	ORDER BY ProcessJob.DateStarted DESC;
GO
ALTER PROCEDURE [dbo].[spJob_CreateJobDefinition](
	@JobDefinitionId uniqueidentifier,
	@Name nvarchar(200),
	@IsEnabled bit,
	@OwnerGuid uniqueidentifier,
	@DateCreated datetime,
	@DateModified datetime,
	@JobDefinition xml,
	@NextRunDate datetime
)
AS
	INSERT INTO JobDefinition(JobDefinitionId, Name, NextRunDate, IsEnabled, OwnerGuid, DateCreated, DateModified, JobDefinition)
	VALUES (@JobDefinitionId, @Name, @NextRunDate, @IsEnabled, @OwnerGuid, @DateCreated, @DateModified, @JobDefinition);
GO
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
	@WeekStart [varchar](2))
AS
	IF NOT EXISTS(SELECT * FROM RecurrencePattern WHERE RecurrencePatternID = @RecurrencePatternId)
	BEGIN
		INSERT INTO RecurrencePattern (RecurrencePatternID, JobDefinitionId, Frequency, StartDate, RepeatUntil, RepeatCount, Interval, ByDay, ByMonthDay, ByYearDay, ByWeekNo, ByMonth, BySetPosition, WeekStart)
		VALUES (@RecurrencePatternID, @JobDefinitionId, @Frequency, @StartDate, @RepeatUntil, @RepeatCount, @Interval, @ByDay, @ByMonthDay, @ByYearDay, @ByWeekNo, @ByMonth, @BySetPosition, @WeekStart);
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
				WeekStart = @WeekStart
		WHERE	RecurrencePatternID = @RecurrencePatternID;
	END
GO
CREATE PROCEDURE spJob_RemoveJobDefinition
	@JobDefinitionId uniqueidentifier
AS
	DELETE	FROM RecurrencePattern
	WHERE	JobDefinitionId = @JobDefinitionId;
	
	DELETE	FROM JobDefinition
	WHERE	JobDefinitionId = @JobDefinitionId;
GO

--1941
CREATE TABLE dbo.Content_Folder
	(
	FolderGuid uniqueidentifier NOT NULL,
	FolderName nvarchar(50) NULL,
	BusinessUnitGuid uniqueidentifier NULL
	)
GO
ALTER TABLE dbo.Content_Folder ADD CONSTRAINT
	PK_Content_Folder PRIMARY KEY CLUSTERED 
	(
	FolderGuid
	)

GO

CREATE TABLE [dbo].[Content_Folder_Group](
	[FolderGuid] [uniqueidentifier] NOT NULL,
	[GroupGuid] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_Content_Folder_Group] PRIMARY KEY CLUSTERED 
(
	[FolderGuid] ASC,
	[GroupGuid] ASC
)
)

GO


ALTER TABLE dbo.Content_Item ADD
	FolderGuid uniqueidentifier NULL
GO

--1942
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
	@GroupGuid uniqueidentifier,
	@UserId int
as
	IF @ItemGuid is null 
		IF @ExactMatch = 1
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					1 AS CanEdit
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
					CASE WHEN (@UserId = -1 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
							WHERE User_Group_Subscription.User_ID = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit
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
						
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity LIKE '%' + @Name + '%'
					AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND ci.Description LIKE '%' + @Description + '%'
					AND (@Category = 0 or ci.Category = @Category)
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
					AND (@GroupGuid IS NULL 
						OR EXISTS (SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid
								AND Content_Folder_Group.GroupGuid = @GroupGuid))
			ORDER BY ci.NameIdentity;
	ELSE
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Intelledox_User.UserName,
				CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
				1 AS CanEdit
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
		WHERE	ci.contentitem_guid = @ItemGuid;
	
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
	@GroupGuid uniqueidentifier
as
	IF @ItemGuid is null 
		IF @ExactMatch = 1
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision
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
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision
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
					LEFT JOIN Content_Folder_Group ON ci.FolderGuid = Content_Folder_Group.FolderGuid
					
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
					AND (@GroupGuid IS NULL OR Content_Folder_Group.GroupGuid = @GroupGuid)
			ORDER BY ci.NameIdentity;
	ELSE
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Intelledox_User.UserName,
				CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision
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
		WHERE	ci.contentitem_guid = @ItemGuid;
	
	set @ErrorCode = @@error;
GO
CREATE procedure [dbo].[spContent_ContentItemListByFolder]
	@FolderGuid uniqueidentifier
as
	SELECT	Content_Item.*, 
		ContentData_Binary.FileType, 
		ContentData_Binary.Modified_Date, 
		Intelledox_User.Username,
		0 As HasUnapprovedRevision,
		0 As CanEdit
	FROM	Content_Item
		LEFT JOIN ContentData_Binary ON Content_Item.ContentData_Guid = ContentData_Binary.ContentData_Guid
		LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = ContentData_Binary.Modified_By
	WHERE	FolderGuid = @FolderGuid
	ORDER BY Content_Item.ContentType_Id,
		Content_Item.NameIdentity
GO
CREATE procedure [dbo].[spContent_ContentFolderList]
	@FolderGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier
AS
	IF @FolderGuid IS NULL
	BEGIN
		SELECT	*
		FROM	Content_Folder
		WHERE	BusinessUnitGuid = @BusinessUnitGuid
		ORDER BY FolderName;
	END
	ELSE
	BEGIN
		SELECT	*
		FROM	Content_Folder
		WHERE	FolderGuid = @FolderGuid;
	END
GO
CREATE procedure [dbo].[spContent_FolderGroupList]
	@FolderGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	SELECT	*
	FROM	Content_Folder_Group
	WHERE	FolderGuid = @FolderGuid

	set @errorcode = @@error
GO
CREATE procedure [dbo].[spContent_UpdateContentFolder]
	@FolderGuid uniqueidentifier,
	@Name nvarchar(100),
	@BusinessUnitGUID uniqueidentifier
AS
	IF EXISTS(SELECT * FROM Content_Folder WHERE FolderGuid = @FolderGuid)
	BEGIN
		UPDATE	Content_Folder
		SET		FolderName = @Name
		WHERE	FolderGuid = @FolderGuid;
	END
	ELSE
	BEGIN
		INSERT INTO Content_Folder(FolderName, BusinessUnitGuid, FolderGuid)
		VALUES (@Name, @BusinessUnitGUID, @FolderGuid)
	END
GO
CREATE procedure [dbo].[spContent_RemoveFolderGroup]
	@FolderGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	DELETE FROM Content_Folder_Group
	WHERE	FolderGuid = @FolderGuid
			AND GroupGuid = @GroupGuid
	
	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spContent_UpdateFolderGroup]
	@FolderGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	INSERT INTO Content_Folder_Group (FolderGuid, GroupGuid)
	VALUES (@FolderGuid, @GroupGuid)
	
	set @ErrorCode = @@error
GO
ALTER procedure [dbo].[spContent_RemoveContentFolder]
	@FolderGuid uniqueidentifier
AS

	DELETE Content_Folder
	WHERE FolderGuid = @FolderGuid;
	
	DELETE Content_Folder_Group
	WHERE FolderGuid = @FolderGuid;
	
	UPDATE Content_Item
	SET FolderGuid = NULL
	WHERE FolderGuid = FolderGuid;
	
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
	
	IF NOT EXISTS(SELECT * FROM Content_Item WHERE ContentItem_Guid = @ContentItemGuid)
	begin
		SELECT	@Approvals = OptionValue
		FROM	Global_Options
		WHERE	OptionCode = 'REQUIRE_CONTENT_APPROVAL';
		
		INSERT INTO Content_Item (ContentItem_Guid, [Description], NameIdentity, ContentType_Id, Business_Unit_Guid, ContentData_Guid, SizeScale, Category, Provider_Name, Reference_Id, IsIndexed, Approved, FolderGuid)
		VALUES (@ContentItemGuid, @Description, @Name, @ContentTypeId, @BusinessUnitGuid, @ContentDataGuid, @SizeScale, @Category, @ProviderName, @ReferenceId, 0, CASE WHEN @Approvals = 'true' THEN 0 ELSE 2 END, @FolderGuid);
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
			FolderGuid = @FolderGuid
		WHERE ContentItem_Guid = @ContentItemGuid;
GO

