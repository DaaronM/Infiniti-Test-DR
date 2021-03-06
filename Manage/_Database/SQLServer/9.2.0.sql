truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.2.0');
go
ALTER TABLE User_Group
	ALTER COLUMN Name nvarchar(100) null
GO
ALTER procedure [dbo].[spUsers_updateUserGroup]
    @GroupGuid uniqueidentifier,
    @Name nvarchar(100),
    @IsWindowsGroup bit,
    @BusinessUnitGUID uniqueidentifier,
    @AddressId int
as
    if NOT EXISTS (SELECT * FROM User_Group WHERE Group_Guid = @GroupGuid)
    begin
        INSERT INTO User_Group ([Name], [WinNT_Group], Business_Unit_GUID, Group_Guid, AutoAssignment, SystemGroup, Address_ID)
        VALUES (@Name, @IsWindowsGroup, @BusinessUnitGUID, @GroupGuid, 0, 0, @AddressId);
    end
    else
    begin
        update	User_Group
        SET		[Name] = @Name, 
                [WinNT_Group] = @IsWindowsGroup,
                Address_ID = @AddressId
        where	Group_Guid = @GroupGuid;
    end
GO

-------------------------------------------------------------------------------------
--Create Tables and Stored Procedures for Page Log
CREATE TABLE [dbo].[Template_PageLog](
	[Log_Guid] [uniqueidentifier] NOT NULL,
	[RunId] [uniqueidentifier] NOT NULL,
	[PageTitle] [nvarchar](max) NOT NULL,
	[PageGuid] [uniqueidentifier] NOT NULL,
	[DateTimeUTC] [datetime] NOT NULL,
	[SaveTimeUTC] [datetime] NULL
)

GO

CREATE CLUSTERED INDEX IX_Template_PageLog ON dbo.Template_PageLog
	(
	Log_Guid,
	RunId
	)
GO

CREATE PROCEDURE [dbo].[spLog_InsertTemplatePageLog]
	@LogGuid uniqueIdentifier,
    @RunId uniqueIdentifier,
	@PageTitle nvarchar(max),
	@PageGuid uniqueIdentifier,
	@DateTimeUTC dateTime

AS
    SET NOCOUNT ON;
	INSERT INTO Template_PageLog ([Log_Guid], [RunId], [PageTitle], [PageGuid], [DateTimeUTC])
	VALUES (@LogGuid, @RunID, @PageTitle, @PageGuid, @DateTimeUTC)
GO

CREATE PROCEDURE [dbo].[spLog_InsertTemplateSaveLog]
	@LogGuid uniqueIdentifier,
	@DateTimeUTC DateTime
AS
	UPDATE Template_PageLog
	SET SaveTimeUTC = @DateTimeUTC
	WHERE DateTimeUTC = (SELECT MAX(DateTimeUTC) FROM Template_PageLog WHERE Log_Guid = @LogGuid)
GO

-------------------------------------------------------------------------------------
--Alter Template_Group table to include LogPageTransition flag

ALTER TABLE dbo.Template_Group ADD
	LogPageTransition bit NOT NULL DEFAULT ((0))

GO

-------------------------------------------------------------------------------------
--Alter spProjectGrp Stored procedures to update and return the LogPageTransition flag.

ALTER procedure [dbo].[spProjectGrp_ProjectGroupList]
      @ProjectGroupGuid uniqueidentifier
AS
    SELECT	a.Template_Group_ID, t.[Name] as Template_Name, a.template_group_guid, 
			a.helptext as TemplateGroup_HelpText, a.Template_Guid, a.Layout_Guid,
			a.Template_Version, a.Layout_Version, a.AllowPreview, a.PostGenerateText,
			a.UpdateDocumentFields, a.EnforceValidation, a.WizardFinishText, 
			a.EnforcePublishPeriod, a.PublishStartDate, a.PublishFinishDate,
			a.HideNavigationPane, a.ShowFormActivity, a.MatchProjectVersion,
			a.AllowRestart, a.OfflineDataSources, a.LogPageTransition
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
	@LogPageTransition bit
AS
	IF NOT EXISTS(SELECT * FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid)
	BEGIN
		INSERT INTO Template_Group (template_group_guid, helptext, AllowPreview, PostGenerateText, 
				UpdateDocumentFields, EnforceValidation, WizardFinishText, EnforcePublishPeriod,
				PublishStartDate, PublishFinishDate, HideNavigationPane, Template_Guid, Layout_Guid,
				Template_Version, Layout_Version, Folder_Guid, ShowFormActivity, MatchProjectVersion,
				AllowRestart, OfflineDataSources, LogPageTransition)
		VALUES (@ProjectGroupGuid, @HelpText, @AllowPreview, @PostGenerateText, 
				@UpdateDocumentFields, @EnforceValidation, @WizardFinishText, @EnforcePublishPeriod,
				@PublishStartDate, @PublishFinishDate, @HideNavigationPane, @ProjectGuid, @LayoutGuid,
				@ProjectVersion, @LayoutVersion, @FolderGuid, @ShowFormActivity, @MatchProjectVersion,
				@AllowRestart, @OfflineDataSources,@LogPageTransition);
	END
	ELSE
	BEGIN
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
				LogPageTransition = @LogPageTransition
		WHERE	Template_Group_Guid = @ProjectGroupGuid;
	END

	EXEC spProjectGroup_UpdateFeatureFlags @ProjectGroupGuid=@ProjectGroupGuid;

GO

-------------------------------------------------------------------------------------
--Addition of template_PageLog cleanup to cleanup procedure.

ALTER procedure [dbo].[spCleanup]
AS
    SET NOCOUNT ON
    SET DEADLOCK_PRIORITY LOW;

    DECLARE @DocumentCleanupDate DateTime;
	DECLARE @DownloadableDocNum int;
	DECLARE @GenerationCleanupDate DateTime;
	DECLARE @AuditCleanupDate DateTime;
	DECLARE @WorkflowCleanupDate DateTime;
	DECLARE @LogoutCleanupDate DateTime;

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
																				
    DECLARE @GuidId uniqueidentifier;
    CREATE TABLE #ExpiredItems 
    ( 
        Id uniqueidentifier NOT NULL PRIMARY KEY
    )


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
	-- Expired Page Transition Logs
	TRUNCATE TABLE #ExpiredItems;

	INSERT #ExpiredItems (Id)
	SELECT DISTINCT(Log_Guid)
	FROM Template_PageLog WITH (READUNCOMMITTED)
	WHERE DateTimeUTC < @GenerationCleanupDate

    IF @@ROWCOUNT <> 0 
    BEGIN 
        DECLARE ExpiredItemCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
        FOR SELECT Id FROM #ExpiredItems 

        OPEN ExpiredItemCursor;
        FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;

        WHILE @@FETCH_STATUS = 0 
            BEGIN
                DELETE FROM Template_PageLog WHERE Log_Guid = @GuidId;
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

GO

CREATE TABLE dbo.ReadOnlyAccess
	(
	User_Guid uniqueidentifier NOT NULL,
	Access_Guid uniqueidentifier NOT NULL
	)
GO
CREATE CLUSTERED INDEX IX_ReadOnlyAccess ON dbo.ReadOnlyAccess
	(
	User_Guid,
	Access_Guid
	)
GO

CREATE PROCEDURE dbo.spUsers_CheckReadOnly
	@UserGuid uniqueidentifier,
	@ID uniqueidentifier
AS
BEGIN
	SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END AS HasReadOnlyAccess 
	FROM ReadOnlyAccess
	WHERE @UserGuid = User_Guid
		AND @ID = Access_Guid
END
GO

CREATE VIEW [dbo].[vwPageLog]
AS
SELECT      Template_PageLog.Log_Guid AS LogGuid, 
			Template_PageLog.RunId,
			Template_PageLog.PageTitle,
			Template_PageLog.PageGuid,
			Template.Name AS ProjectName,
			TimeonPage_Sec AS TimeonPageSec,
			Template_Log.DateTime_Start AS ProjectStartTimeUTC,
			Template_Log.DateTime_Finish AS ProjectFinishTimeUTC,
			CASE WHEN Template_Log.DateTime_Finish IS NULL THEN 0 ELSE 1 END AS Finished,
			SaveTimeUTC,
			(SELECT TOP 1 PageTitle
				FROM Template_PageLog CurrentPageLog
				WHERE CurrentPageLog.Log_Guid = Template_PageLog.Log_Guid
				ORDER BY CurrentPageLog.DateTimeUTC DESC) AS LastPage,
			Template.Business_Unit_Guid
FROM        Template_PageLog
		INNER JOIN Template_Log ON Template_PageLog.Log_Guid = Template_Log.Log_Guid
		INNER JOIN Template_Group ON Template_Group.Template_Group_ID = Template_Log.Template_Group_ID
		INNER JOIN Template ON Template.Template_Guid = Template_Group.Template_Guid
		LEFT JOIN (SELECT a.PageGuid,
						a.Log_Guid,
						b.PageGuid AS bGuid,
						DATEDIFF(second, a.DateTimeUTC, b.DateTimeUTC) AS timeOnPage_Sec
					FROM (SELECT FirstLogRow.DateTimeUTC, 
								FirstLogRow.PageGuid,
								FirstLogRow.Log_Guid,
								ROW_NUMBER() OVER (ORDER BY FirstLogRow.Log_Guid, FirstLogRow.DateTimeUTC) AS rowNumber  
							FROM Template_PageLog FirstLogRow) A 
						INNER JOIN (SELECT SecondLogRow.DateTimeUTC, 
								SecondLogRow.PageGuid, 
								SecondLogRow.Log_Guid,
								ROW_NUMBER() OVER (ORDER BY SecondLogRow.Log_Guid, SecondLogRow.DateTimeUTC) AS rowNumber  
							FROM Template_PageLog SecondLogRow) B ON a.rowNumber = b.rowNumber - 1
					WHERE a.Log_Guid = b.Log_Guid) Results
				ON Results.PageGuid = Template_PageLog.PageGuid
					AND Results.Log_Guid = Template_PageLog.Log_Guid
GO
