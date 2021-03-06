truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.32');
go

ALTER TABLE [dbo].[Analytics_InteractionLog]
ADD PageTitle nvarchar(100) NULL;
GO

ALTER PROCEDURE [dbo].[spLog_InsertAnalyticsInteractionLog]
	@LogGuid uniqueIdentifier,
	@ControlID nvarchar(100),
	@EventType nvarchar(100),
	@FocusTimeUTC dateTime,
	@BlurTimeUTC dateTime,
	@PageTitle nvarchar(100)
AS
    SET NOCOUNT ON;
	INSERT INTO Analytics_InteractionLog ([Log_Guid], [ControlID], [EventType], [FocusTimeUTC], [BlurTimeUTC], [PageTitle])
	VALUES (@LogGuid, @ControlID, @EventType, @FocusTimeUTC, @BlurTimeUTC, @PageTitle)
GO

CREATE VIEW vwInteractionLog
AS
SELECT T.Business_Unit_GUID, I.Log_Guid, T.Name As Form, I.PageTitle As Page, I.ControlID, I.EventType, I.FocusTimeUTC, I.BlurTimeUTC
FROM dbo.Analytics_InteractionLog I 
     JOIN dbo.Template_Log L ON  L.Log_Guid = I.Log_Guid
	 JOIN dbo.Template_Group G ON G.Template_Group_ID = l.Template_Group_ID
	 JOIN dbo.Template T ON G.Template_Guid = T.Template_Guid
GO

CREATE VIEW vwInteractionLog_DropOff
AS
SELECT DropOffPage.*, DropOffQuestion.Question, DropOffQuestion.QuestionFocusTimeUTC
FROM (SELECT il.Business_Unit_GUID, il.Log_Guid, il.Form, il.[Page], FocusTimeUTC AS PageFocusTimeUTC
      FROM dbo.vwInteractionLog il
	  JOIN (SELECT Log_Guid, MAX(FocusTimeUTC) AS LastPageInteractionTimeUTC
            FROM dbo.Analytics_InteractionLog
            WHERE Log_Guid NOT IN (SELECT Log_Guid FROM dbo.Analytics_InteractionLog WHERE ControlID = '(Submit)' OR ControlID = '(Save)' OR EventType = 'tileGoToProject' OR EventType = 'reassign')
                  AND EventType = 'pageOpen'
            GROUP BY Log_Guid) lp ON il.FocusTimeUTC = lp.LastPageInteractionTimeUTC AND il.Log_Guid = lp.Log_Guid) DropOffPage
      LEFT JOIN (SELECT  il.Log_Guid, il.ControlID As Question, FocusTimeUTC AS QuestionFocusTimeUTC
                 FROM dbo.Analytics_InteractionLog il 
				 JOIN (SELECT Log_Guid, MAX(FocusTimeUTC) AS LastQuestionInteractionTimeUtc
                       FROM dbo.Analytics_InteractionLog
                       WHERE EventType IS NULL
                       AND ControlID <> 'goToHome'
                       GROUP BY Log_Guid) lq 
				 ON il.FocusTimeUTC = lq.LastQuestionInteractionTimeUtc AND il.Log_Guid = lq.Log_Guid) DropOffQuestion 
      ON DropOffPage.Log_Guid = DropOffQuestion.Log_Guid AND DropOffQuestion.QuestionFocusTimeUTC > DropOffPage.PageFocusTimeUTC
GO

CREATE VIEW vwInteractionLog_Save
AS
SELECT il.Business_Unit_GUID, s.Log_Guid, s.LastSaveTimeUTC, il.Form, il.Page AS LastSavePage, s.SaveCount
FROM dbo.vwInteractionLog il JOIN
  (SELECT Log_Guid, COUNT(LOG_GUID) As SaveCount, MAX(FocusTimeUTC) AS LastSaveTimeUTC
   FROM dbo.Analytics_InteractionLog
   WHERE ControlID = '(Save)'
   GROUP BY Log_Guid) s ON il.Log_Guid = s.Log_Guid AND il.FocusTimeUTC = s.LastSaveTimeUTC
GO

CREATE VIEW vwInteractionLog_Page
AS
SELECT il.Business_Unit_GUID, il.Form, il.Page, il.FocusTimeUTC, p.SecondsOnPage
FROM vwInteractionLog il JOIN
      (SELECT a.FocusTimeUTC,
       a.Log_Guid,
	   DATEDIFF(second, a.FocusTimeUTC, b.FocusTimeUTC) AS secondsOnPage
	   FROM (SELECT FirstLogRow.FocusTimeUTC,
	                FirstLogRow.Log_Guid,
					ROW_NUMBER() OVER(ORDER BY FirstLogRow.Log_Guid, FirstLogRow.FocusTimeUTC) AS rowNumber
			 FROM Analytics_InteractionLog FirstLogRow
			 WHERE FirstLogRow.EventType = 'pageOpen' OR ControlID = '(Submit)' OR EventType = 'tileGoToProject' OR EventType = 'reassign') A
	   INNER JOIN (SELECT SecondLogRow.FocusTimeUTC,
	                SecondLogRow.Log_Guid,
					ROW_NUMBER() OVER(ORDER BY SecondLogRow.Log_Guid, SecondLogRow.FocusTimeUTC) AS rowNumber
			 FROM Analytics_InteractionLog SecondLogRow
			 WHERE SecondLogRow.EventType = 'pageOpen' OR ControlID = '(Submit)' OR EventType = 'tileGoToProject' OR EventType = 'reassign') B ON A.rowNumber = b.rowNumber - 1
			 WHERE a.Log_Guid = b.Log_Guid) p ON il.Log_Guid = p.Log_Guid AND il.FocusTimeUTC = p.FocusTimeUTC
GO

CREATE VIEW vwInteractionLog_InteractionTime
AS
SELECT il.Business_Unit_GUID, il.Log_Guid, il.Form, il.[Page], il.ControlID, il.EventType, il.FocusTimeUTC, q.InteractionSeconds
FROM vwInteractionLog il JOIN
      (SELECT a.FocusTimeUTC,
       a.Log_Guid,
	   DATEDIFF(second, a.FocusTimeUTC, b.FocusTimeUTC) AS InteractionSeconds
	   FROM (SELECT FirstLogRow.FocusTimeUTC,
	                FirstLogRow.Log_Guid,
					ROW_NUMBER() OVER(ORDER BY FirstLogRow.Log_Guid, FirstLogRow.FocusTimeUTC) AS rowNumber
			 FROM Analytics_InteractionLog FirstLogRow) A
	   INNER JOIN (SELECT SecondLogRow.FocusTimeUTC,
	                SecondLogRow.Log_Guid,
                    ROW_NUMBER() OVER(ORDER BY SecondLogRow.Log_Guid, SecondLogRow.FocusTimeUTC) AS rowNumber
			 FROM Analytics_InteractionLog SecondLogRow) B ON A.rowNumber = b.rowNumber - 1
			 WHERE a.Log_Guid = b.Log_Guid) Q ON  il.Log_Guid = q.Log_Guid AND il.FocusTimeUTC = q.FocusTimeUTC
GO

DROP VIEW vwPageLog
GO
CREATE TABLE dbo.TemplateEdit
	(
	Id uniqueidentifier NOT NULL,
	UserGuid uniqueidentifier NOT NULL,
	DateModified datetime NOT NULL,
	DateCreated datetime NOT NULL,
	TemplateFormatType int NOT NULL,
	TemplateContent varbinary(MAX) NULL
	)
GO
ALTER TABLE dbo.TemplateEdit ADD CONSTRAINT
	PK_TemplateEdit PRIMARY KEY CLUSTERED 
	(
	Id
	)
GO
CREATE PROC dbo.spTemplateEdit_Get (
	@Id uniqueidentifier
	)
AS
	SELECT 	Id,
			UserGuid,
			DateModified,
			DateCreated,
			TemplateFormatType
	FROM TemplateEdit
	WHERE	Id = @Id;
GO
CREATE PROC dbo.spTemplateEdit_Delete (
	@Id uniqueidentifier
	)
AS
	DELETE FROM TemplateEdit
	WHERE	Id = @Id;
GO
CREATE PROC dbo.spTemplateEdit_Edit (
	@Id uniqueidentifier,
	@UserGuid uniqueidentifier,
	@DateModified datetime,
	@DateCreated datetime,
	@TemplateFormatType int
	)
AS
	IF EXISTS(SELECT 1 FROM TemplateEdit WHERE Id = @Id)
	BEGIN
		UPDATE TemplateEdit
		SET 	DateModified = @DateModified,
				TemplateFormatType = @TemplateFormatType
		WHERE	Id = @Id;
	END
	ELSE
	BEGIN
			INSERT INTO TemplateEdit(Id, UserGuid, DateModified, DateCreated, TemplateFormatType)
			VALUES (@Id, @UserGuid, @DateModified, @DateCreated, @TemplateFormatType);
	END
GO
CREATE PROC dbo.spTemplateEdit_EditBinary (
	@Id uniqueidentifier,
	@TemplateContent varbinary(MAX)
	)
AS
	UPDATE TemplateEdit
	SET 	TemplateContent = @TemplateContent
	WHERE	Id = @Id;
GO
CREATE PROC dbo.spTemplateEdit_Binary (
	@Id uniqueidentifier
	)
AS
	SELECT 	TemplateContent
	FROM TemplateEdit
	WHERE	Id = @Id;
GO
ALTER PROCEDURE [dbo].[spProject_UpdateBinary] (
	@Bytes varbinary(max),
	@TemplateGuid uniqueidentifier,
	@FileGuid uniqueidentifier,
	@FormatType varchar(6),
	@TemplateEditGuid uniqueidentifier
)
AS
	SET NOCOUNT ON

	IF (@TemplateEditGuid IS NOT NULL)
	BEGIN
		SET @Bytes = (SELECT TemplateContent FROM TemplateEdit WHERE Id = @TemplateEditGuid);
	END

	IF EXISTS(SELECT File_Guid FROM Template_File WHERE Template_Guid = @TemplateGuid AND File_Guid = @FileGuid)
	BEGIN
		UPDATE	Template_File
		SET		[Binary] = @Bytes,
				FormatTypeId = @FormatType
		WHERE	Template_Guid = @TemplateGuid
				AND File_Guid = @FileGuid;
	END
	ELSE
	BEGIN
		INSERT INTO Template_File(Template_Guid, File_Guid, [Binary], FormatTypeId)
		VALUES (@TemplateGuid, @FileGuid, @Bytes, @FormatType);
	END
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
	DECLARE @TemporaryUsersCleanup DateTime;

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

	SET @TemporaryUsersCleanup = DATEADD(HOUR, -2, GetUtcDate());
										
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
	-- Expired TemporaryUsers
	TRUNCATE TABLE #ExpiredItems;

  	INSERT #ExpiredItems (Id)
	SELECT DISTINCT(UserGuid)
	FROM TemporaryUser WITH (READUNCOMMITTED)
	INNER JOIN Intelledox_User ON TemporaryUser.UserGuid = Intelledox_User.User_Guid
	INNER JOIN Template_Log ON Intelledox_User.User_ID = Template_Log.User_ID
	WHERE Intelledox_User.IsTemporaryUser = 1 AND 
		Template_Log.ActionListStateId = '00000000-0000-0000-0000-000000000000' AND
		Template_Log.DateTime_Finish < @TemporaryUsersCleanup;

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
	
	-- Template Edit
	DELETE FROM TemplateEdit
	WHERE DateModified < DATEADD(d, -30, GETUTCDATE());
GO


--10150
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'PK_Action_Log' AND object_id = OBJECT_ID('dbo.Action_Log'))
BEGIN

	CREATE TABLE dbo.Tmp_Action_Log
		(
		[ActionGuid] [uniqueidentifier] NOT NULL,
		[DateTimeUTC] [datetime] NOT NULL,
		[Log_Guid] [uniqueidentifier] NOT NULL,
		[User_Guid] [uniqueidentifier] NOT NULL,
		[ProcessingMS] [int] NOT NULL,
		[Result] [int] NOT NULL,
		[EncryptedChecksum] [varbinary](max) NULL,
		[BusinessUnitGuid] [uniqueidentifier] NOT NULL
		);

	CREATE CLUSTERED INDEX IX_Action_Log ON dbo.Tmp_Action_Log
		(
		[DateTimeUTC]
		);

	INSERT INTO dbo.Tmp_Action_Log ([ActionGuid], [DateTimeUTC], [Log_Guid], [User_Guid], [ProcessingMS], 
			[Result], [EncryptedChecksum], [BusinessUnitGuid])
	SELECT	[ActionGuid], [DateTimeUTC], [Log_Guid], [User_Guid], [ProcessingMS],
			[Result], [EncryptedChecksum], [BusinessUnitGuid]
	FROM	Action_Log;

	DROP TABLE dbo.Action_Log;
	EXECUTE sp_rename N'dbo.Tmp_Action_Log', N'Action_Log', 'OBJECT';
END
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'PK_Email_Log' AND object_id = OBJECT_ID('dbo.Email_Log'))
BEGIN

	CREATE TABLE dbo.Tmp_Email_Log
		(
			[EmailType] [nvarchar](100) NOT NULL,
			[DateTimeUTC] [datetime] NOT NULL,
			[Id] [uniqueidentifier] NOT NULL,
			[NumAddressees] [int] NOT NULL,
			[EncryptedChecksum] [varbinary](max) NULL,
			[BusinessUnitGuid] [uniqueidentifier] NOT NULL,
			[ProjectGuid] [uniqueidentifier] NULL
		);

	CREATE CLUSTERED INDEX IX_Email_Log ON dbo.Tmp_Email_Log
		(
		[DateTimeUTC]
		);

	INSERT INTO dbo.Tmp_Email_Log ([EmailType], [DateTimeUTC], [Id], [NumAddressees], [EncryptedChecksum], 
			[BusinessUnitGuid], [ProjectGuid])
	SELECT	[EmailType], [DateTimeUTC], [Id], [NumAddressees], [EncryptedChecksum],
			[BusinessUnitGuid], [ProjectGuid]
	FROM	Email_Log;

	DROP TABLE dbo.Email_Log;
	EXECUTE sp_rename N'dbo.Tmp_Email_Log', N'Email_Log', 'OBJECT';
END
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'PK_Escalation_Log' AND object_id = OBJECT_ID('dbo.Escalation_Log'))
BEGIN

	CREATE TABLE dbo.Tmp_Escalation_Log
		(
			[EscalationTypeId] [uniqueidentifier] NOT NULL,
			[DateTimeUTC] [datetime] NOT NULL,
			[CurrentStateGuid] [uniqueidentifier] NOT NULL,
			[ProcessingMS] [float] NOT NULL,
			[EncryptedChecksum] [varbinary](max) NULL,
			[BusinessUnitGuid] [uniqueidentifier] NOT NULL,
			[ProjectGuid] [uniqueidentifier] NULL
		);

	CREATE CLUSTERED INDEX IX_Escalation_Log ON dbo.Tmp_Escalation_Log
		(
		[DateTimeUTC]
		);

	INSERT INTO dbo.Tmp_Escalation_Log ([EscalationTypeId], [DateTimeUTC], [CurrentStateGuid], [ProcessingMS], [EncryptedChecksum], 
			[BusinessUnitGuid], [ProjectGuid])
	SELECT	[EscalationTypeId], [DateTimeUTC], [CurrentStateGuid], [ProcessingMS], [EncryptedChecksum],
			[BusinessUnitGuid], [ProjectGuid]
	FROM	Escalation_Log;

	DROP TABLE dbo.Escalation_Log;
	EXECUTE sp_rename N'dbo.Tmp_Escalation_Log', N'Escalation_Log', 'OBJECT';
END
GO
CREATE PROC dbo.spTemplateEdit_Prepare (
	@ProjectGuid uniqueidentifier,
	@FileGuid uniqueidentifier,
	@TemplateEditGuid uniqueidentifier,
	@UserGuid uniqueidentifier,
	@DateCreated datetime,
	@FormatType int
	)
AS
	INSERT INTO TemplateEdit(Id, UserGuid, DateModified, DateCreated, TemplateFormatType, TemplateContent)
	SELECT @TemplateEditGuid, @UserGuid, @DateCreated, @DateCreated, @FormatType, Template_File.Binary
	FROM Template_File
	WHERE Template_File.Template_Guid = @ProjectGuid
		AND Template_File.File_Guid = @FileGuid
GO
CREATE PROC dbo.spTemplateEdit_ModifiedDates (
	@Id uniqueidentifier
	)
AS
	SELECT 	DateCreated, DateModified
	FROM TemplateEdit
	WHERE	Id = @Id;
GO
