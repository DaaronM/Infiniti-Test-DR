truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.7.1.0');
go
ALTER procedure [dbo].[spLog_CompleteProjectLog]
	@LogGuid uniqueidentifier,
	@FinishDate datetime,
	@MessageXml xml = null,
	@UpdateRecent bit = 0
AS
	DECLARE @UserGuid uniqueidentifier;
	DECLARE @TemplateGroupGuid uniqueidentifier;
	
	SET NOCOUNT ON;

	UPDATE	Template_Log 
	SET		DateTime_Finish = @FinishDate, 
			Completed = 1,
			Messages = @MessageXml,
			InProgress = 0
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
ALTER TABLE	Template_Log
	DROP COLUMN Package_Run_Id
GO
ALTER TABLE	Template_Log
	DROP COLUMN Answer_File_Used
GO
ALTER TABLE Template_Log
	ADD CompletionState TinyInt NOT NULL CONSTRAINT DF_Template_Log_CompletionState DEFAULT (0)
GO
-- completions and in-progresses
UPDATE	Template_Log
SET		CompletionState = CASE WHEN Completed = 1 THEN 3
								WHEN Completed = 0 AND InProgress = 0 THEN 1
								ELSE 0 END
WHERE	(Completed = 1 AND (ActionListStateId IS NULL OR ActionListStateId = '00000000-0000-0000-0000-000000000000')) OR 
		(Completed = 0 AND InProgress = 0)
GO
-- Workflow completed with no kept action list data (everything is a full complete)
UPDATE	Template_Log
SET		CompletionState = 3
WHERE	CompletionState = 0
		AND ActionListStateId NOT IN (SELECT ActionListStateId FROM ActionListState)
		AND ActionListStateId <> '00000000-0000-0000-0000-000000000000'
GO
-- Workflow completed with action list data (last item is a full complete)
UPDATE	Template_Log
SET		CompletionState = 3
FROM	Template_Log
		INNER JOIN ActionListState ON Template_Log.ActionListStateId = ActionListState.ActionListStateId
		INNER JOIN (
			SELECT	Completed.ActionListId 
			FROM	ActionListState Completed
			WHERE	Completed.StateGuid = '99999999-9999-9999-9999-999999999999'
			) CompletedWorkflow ON ActionListState.ActionListId = CompletedWorkflow.ActionListId
WHERE CompletionState = 0
	AND ActionListState.DateCreatedUtc = (SELECT MAX(MaxState.DateCreatedUtc)
									FROM ActionListState MaxState
									WHERE MaxState.ActionListId = CompletedWorkflow.ActionListId
										AND MaxState.StateGuid <> '99999999-9999-9999-9999-999999999999')
GO
-- Everything else for a known workflow is a workflow complete
UPDATE	Template_Log
SET		CompletionState = 2
WHERE	CompletionState = 0
		AND ActionListStateId IN (SELECT ActionListStateId FROM ActionListState)
		AND InProgress = 0
GO
DROP INDEX IX_Template_Log_UserId ON dbo.Template_Log
GO
CREATE NONCLUSTERED INDEX IX_Template_Log_UserId ON dbo.Template_Log
	(
	User_ID,
	DateTime_Start,
	CompletionState
	)
GO
ALTER TABLE	Template_Log
	DROP COLUMN InProgress, Completed
GO
ALTER PROCEDURE [dbo].[spLog_ClearUnfinished]
	@UserGuid uniqueidentifier
AS
	DECLARE @UserId INT;
	
	SET NOCOUNT ON;
	
	SET @UserId = (SELECT User_Id FROM Intelledox_User WHERE User_Guid = @UserGuid);
	
	UPDATE	Template_Log
	SET		CompletionState = 1
	WHERE	User_Id = @UserId
		AND CompletionState = 0;
GO
ALTER PROCEDURE [dbo].[spLog_LastUnfinished]
	@UserGuid uniqueidentifier
AS
	DECLARE @UserId INT;
	
	SET NOCOUNT ON;
	
	SET @UserId = (SELECT User_Id FROM Intelledox_User WHERE User_Guid = @UserGuid);
	
	SELECT	Log_Guid
	FROM	Template_Log
	WHERE	DateTime_Start = (
		SELECT	MAX(DateTime_Start)
		FROM	Template_Log
		WHERE	User_Id = @UserId
				AND CompletionState = 0
				AND Answer_File IS NOT NULL)
		AND User_Id = @UserId;
GO
ALTER procedure [dbo].[spLog_InsertTemplateLog]
	@LogGuid uniqueidentifier,
	@UserGuid uniqueidentifier,	
	@TemplateGroupGuid uniqueidentifier,
	@StartTime datetime,
	@AnswerFile xml,
	@UpdateRecent bit = 0,
	@ActionListStateId uniqueidentifier = '00000000-0000-0000-0000-000000000000'
AS
	DECLARE @UserId INT;
	DECLARE @TemplateGroupId INT;
	
	SET NOCOUNT ON;
	
	SET @UserId = (SELECT User_Id FROM Intelledox_User WITH (NOLOCK) WHERE User_Guid = @UserGuid);
	SET	@TemplateGroupId = (SELECT Template_Group_Id FROM Template_Group WITH (NOLOCK) WHERE Template_Group_Guid = @TemplateGroupGuid);
	
	IF @LogGuid IS NULL
		SET @LogGuid = newid();

	--Add to log
	INSERT INTO Template_Log WITH (ROWLOCK) (Log_Guid, [User_ID], Template_Group_ID, DateTime_Start, CompletionState, Answer_File, ActionListStateId)
	VALUES (@LogGuid, @UserID, @TemplateGroupID, @StartTime, 0, @AnswerFile, @ActionListStateId);

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
ALTER procedure [dbo].[spLog_CompleteProjectLog]
	@LogGuid uniqueidentifier,
	@FinishDate datetime,
	@MessageXml xml = null,
	@UpdateRecent bit = 0,
	@IsWorkflowState bit = 0
AS
	DECLARE @UserGuid uniqueidentifier;
	DECLARE @TemplateGroupGuid uniqueidentifier;
	
	SET NOCOUNT ON;

	UPDATE	Template_Log 
	SET		DateTime_Finish = @FinishDate, 
			Completionstate = CASE WHEN @IsWorkflowState = 1 THEN 2 ELSE 3 END,
			Messages = @MessageXml
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
ALTER procedure [dbo].[spReport_LogicResponses]
	@TemplateId Int,
	@StartDate datetime,
	@FinishDate datetime,
	@DisplayText bit = 0
AS
	SET ARITHABORT ON 
	CREATE TABLE #Answers
	(
		Id int identity(1,1),
		AnswerGuid uniqueidentifier,
		QuestionGuid uniqueidentifier,
		AnswerName nvarchar(1000),
		Label nvarchar(100),
		QuestionName nvarchar(1000),
		PageGuid nvarchar(36),
		PageName nvarchar(1000),
		QuestionTypeId int
	);

	CREATE TABLE #Responses
	(
		LogGuid uniqueidentifier,
		AnswerGuid uniqueidentifier,
		Value nvarchar(1000)
	);
	
	-- Finish date inclusive
	SET @FinishDate = DateAdd(d, 1, @FinishDate);

	INSERT INTO #Answers(QuestionGuid, AnswerGuid, AnswerName, Label, QuestionName, QuestionTypeId, PageName, PageGuid)
	SELECT	Q.value('@Guid', 'uniqueidentifier'),
			A.value('@Guid', 'uniqueidentifier'), 
			A.value('@Name', 'nvarchar(1000)'),
			A.value('@AnswerFileLabel', 'nvarchar(100)'),
			Q.value('@Text', 'nvarchar(1000)'),
			Q.value('@TypeId', 'int'),
			P.value('@Name', 'nvarchar(1000)'),
			P.value('@Guid', 'nvarchar(36)')
	FROM	Template
			CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
			CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
			CROSS APPLY Q.nodes('(Answer)') as AnswerXml(A)
	WHERE	Template.Template_Id = @TemplateId;

	INSERT INTO #Responses(LogGuid, AnswerGuid, Value)
	SELECT	Template_Log.Log_Guid,
			#Answers.AnswerGuid, 
			C.value('@v', 'nvarchar(1000)')
	FROM	Template_Log 
			CROSS APPLY Answer_File.nodes('(/AnswerFile/ps/p//qs/q/as/a)') as ID(C)
			, #Answers
	WHERE	C.value('@aid', 'uniqueidentifier') = #Answers.AnswerGuid
			AND Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
			AND Template_Log.CompletionState = 3
			AND (#Answers.QuestionTypeId = 3	-- Group logic
				OR #Answers.QuestionTypeId = 6	-- Simple logic
				OR (#Answers.QuestionTypeId = 7 AND @DisplayText = 1))	-- User prompt
			AND Template_Log.Template_Group_Id IN
			(
				SELECT	tg.Template_Group_Id
				FROM	Template_Group tg
						INNER JOIN Template t ON tg.Template_Guid = t.Template_Guid
				WHERE	t.Template_Id = @TemplateId
			)
	UNION ALL
	SELECT	Template_Log.Log_Guid,
			#Answers.AnswerGuid, 
			C.value('@name', 'nvarchar(1000)')
	FROM	Template_Log 
			CROSS APPLY Answer_File.nodes('(/AnswerFile/AnswerLabels/Label)') as Label(C)
			, #Answers
	WHERE	C.value('@name', 'nvarchar(100)') = #Answers.Label
			AND Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
			AND Template_Log.CompletionState = 3
			AND (#Answers.QuestionTypeId = 3	-- Group logic
				OR #Answers.QuestionTypeId = 6	-- Simple logic
				OR (#Answers.QuestionTypeId = 7 AND @DisplayText = 1))	-- User prompt
			AND Template_Log.Template_Group_Id IN
			(
				SELECT	tg.Template_Group_Id
				FROM	Template_Group tg
						INNER JOIN Template t ON tg.Template_Guid = t.Template_Guid
				WHERE	t.Template_Id = @TemplateId
			);

	SELECT	#Answers.PageGuid,
			#Answers.PageName,
			#Answers.QuestionTypeId,
			#Answers.QuestionName,
			#Answers.AnswerName,
			COUNT(CASE #Answers.QuestionTypeId 
				WHEN 3	-- Group Logic
				THEN CASE #Responses.Value WHEN '1' THEN '1' ELSE NULL END
				WHEN 6	-- Simple
				THEN CASE #Responses.Value WHEN '1' THEN '1' ELSE NULL END
				ELSE #Responses.Value
				END) as AnswerCount,
			(SELECT COUNT(DISTINCT #Responses.LogGuid) 
				FROM #Answers
				INNER JOIN #Answers ByQuestion ON #Answers.QuestionGuid = ByQuestion.QuestionGuid
				INNER JOIN #Responses ON ByQuestion.AnswerGuid = #Responses.AnswerGuid) as TotalQuestionResponses,
			(SELECT COUNT(DISTINCT #Responses.LogGuid) FROM #Responses) as TotalResponses,
			CASE WHEN #Answers.QuestionTypeId = 7 THEN #Responses.Value ELSE '' END as TextResponse
	FROM	#Answers
			LEFT JOIN #Responses ON #Answers.AnswerGuid = #Responses.AnswerGuid
	WHERE (#Answers.QuestionTypeId = 3	-- Group logic
			OR #Answers.QuestionTypeId = 6	-- Simple logic
			OR (#Answers.QuestionTypeId = 7 AND @DisplayText = 1))	-- User prompt
	GROUP BY #Answers.PageGuid,
			#Answers.Id,
			#Answers.PageName,
			#Answers.QuestionTypeId,
			#Answers.QuestionName,
			#Answers.AnswerName,
			CASE WHEN #Answers.QuestionTypeId = 7 THEN #Responses.Value ELSE '' END
	ORDER BY #Answers.Id;

	DROP TABLE #Answers;
	DROP TABLE #Responses;
GO
ALTER procedure [dbo].[spReport_LogicResponses]
	@TemplateId Int,
	@StartDate datetime,
	@FinishDate datetime,
	@DisplayText bit = 0
AS
	SET ARITHABORT ON 
	DECLARE @Answers TABLE 
	(
		Id int identity(1,1),
		AnswerGuid uniqueidentifier,
		QuestionGuid uniqueidentifier,
		AnswerName nvarchar(1000),
		Label nvarchar(100),
		QuestionName nvarchar(1000),
		PageGuid nvarchar(36),
		PageName nvarchar(1000),
		QuestionTypeId int
	);

	DECLARE @Responses TABLE 
	(
		LogGuid uniqueidentifier,
		InRepeat bit,
		AnswerGuid uniqueidentifier,
		Value nvarchar(1000)
	);
	
	-- Finish date inclusive
	SET @FinishDate = DateAdd(d, 1, @FinishDate);

	INSERT INTO @Answers(QuestionGuid, AnswerGuid, AnswerName, Label, QuestionName, QuestionTypeId, PageName, PageGuid)
	SELECT	Q.value('@Guid', 'uniqueidentifier'),
			A.value('@Guid', 'uniqueidentifier'), 
			A.value('@Name', 'nvarchar(1000)'),
			A.value('@AnswerFileLabel', 'nvarchar(100)'),
			Q.value('@Text', 'nvarchar(1000)'),
			Q.value('@TypeId', 'int'),
			P.value('@Name', 'nvarchar(1000)'),
			P.value('@Guid', 'nvarchar(36)')
	FROM	Template
			CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
			CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
			CROSS APPLY Q.nodes('(Answer)') as AnswerXml(A)
	WHERE	Template.Template_Id = @TemplateId;

	INSERT INTO @Responses(LogGuid, InRepeat, AnswerGuid, Value)
	SELECT	Template_Log.Log_Guid,
			CASE C.value('../../../@guid', 'nvarchar(36)') WHEN NULL THEN 0 ELSE 1 END as InRepeat,
			ans.AnswerGuid, 
			C.value('@v', 'nvarchar(1000)')
	FROM	Template_Log 
			CROSS APPLY Answer_File.nodes('(/AnswerFile/ps/p//qs/q/as/a)') as ID(C)
			, @Answers ans
	WHERE	C.value('@aid', 'uniqueidentifier') = ans.AnswerGuid
			AND Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
			AND Template_Log.CompletionState = 3
			AND (ans.QuestionTypeId = 3	-- Group logic
				OR ans.QuestionTypeId = 6	-- Simple logic
				OR (ans.QuestionTypeId = 7 AND @DisplayText = 1))	-- User prompt
			AND Template_Log.Template_Group_Id IN
			(
				SELECT	tg.Template_Group_Id
				FROM	Template_Group tg
						INNER JOIN Template t ON tg.Template_Guid = t.Template_Guid
				WHERE	t.Template_Id = @TemplateId
			)
	UNION ALL
	SELECT	Template_Log.Log_Guid,
			0,
			ans.AnswerGuid, 
			C.value('@name', 'nvarchar(1000)')
	FROM	Template_Log 
			CROSS APPLY Answer_File.nodes('(/AnswerFile/AnswerLabels/Label)') as Label(C)
			, @Answers ans
	WHERE	C.value('@name', 'nvarchar(100)') = ans.Label
			AND Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
			AND Template_Log.CompletionState = 3
			AND (ans.QuestionTypeId = 3	-- Group logic
				OR ans.QuestionTypeId = 6	-- Simple logic
				OR (ans.QuestionTypeId = 7 AND @DisplayText = 1))	-- User prompt
			AND Template_Log.Template_Group_Id IN
			(
				SELECT	tg.Template_Group_Id
				FROM	Template_Group tg
						INNER JOIN Template t ON tg.Template_Guid = t.Template_Guid
				WHERE	t.Template_Id = @TemplateId
			);

	SELECT	ans.PageGuid,
			ans.PageName,
			ans.QuestionTypeId,
			ans.QuestionName,
			ans.AnswerName,
			COUNT(CASE ans.QuestionTypeId 
				WHEN 3	-- Group Logic
				THEN CASE resp.Value WHEN '1' THEN '1' ELSE NULL END
				WHEN 6	-- Simple
				THEN CASE resp.Value WHEN '1' THEN '1' ELSE NULL END
				ELSE resp.Value
				END) as AnswerCount,
			(SELECT COUNT(DISTINCT resp.LogGuid) 
				FROM @Answers ans
				INNER JOIN @Answers ByQuestion ON ans.QuestionGuid = ByQuestion.QuestionGuid
				INNER JOIN @Responses resp ON ByQuestion.AnswerGuid = resp.AnswerGuid) as TotalQuestionResponses,
			(SELECT COUNT(DISTINCT resp.LogGuid) FROM @Responses resp) as TotalResponses,
			CASE WHEN ans.QuestionTypeId = 7 THEN resp.Value ELSE '' END as TextResponse,
			resp.InRepeat
	FROM	@Answers ans
			LEFT JOIN @Responses resp ON ans.AnswerGuid = resp.AnswerGuid
	WHERE (ans.QuestionTypeId = 3	-- Group logic
			OR ans.QuestionTypeId = 6	-- Simple logic
			OR (ans.QuestionTypeId = 7 AND @DisplayText = 1))	-- User prompt
	GROUP BY ans.PageGuid,
			ans.Id,
			ans.PageName,
			ans.QuestionTypeId,
			ans.QuestionName,
			ans.AnswerName,
			CASE WHEN ans.QuestionTypeId = 7 THEN resp.Value ELSE '' END,
			resp.InRepeat
	ORDER BY ans.Id;
GO
ALTER procedure [dbo].[spReport_UsageDataMostRunTemplates] (
	@StartDate datetime,
	@FinishDate datetime,
	@BusinessUnitGuid uniqueidentifier
)
AS
	SELECT TOP 10 Template.Template_Guid,
		Template.Name AS TemplateName,
		COUNT(*) AS NumRuns
	FROM Template_Log 
		INNER JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
		INNER JOIN Template ON Template.Template_Guid = Template_Group.Template_Guid
		INNER JOIN Intelledox_User ON Intelledox_User.User_ID = Template_Log.User_ID
    WHERE Template_Log.DateTime_Finish >= @StartDate
        AND Template_Log.DateTime_Finish <= @FinishDate + 1
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
		AND Template_Log.CompletionState = 3
    GROUP BY Template.Template_Guid,
		Template.Name
	ORDER BY NumRuns DESC;
GO
ALTER procedure [dbo].[spReport_UsageDataTimeTaken] (
	@StartDate datetime,
	@FinishDate datetime,
	@BusinessUnitGuid uniqueidentifier
)
AS
	SELECT TOP 10 Template.Name AS TemplateName,
		AVG(CASE WHEN Totals.SumTime IS NULL 
			THEN DateDiff(second, Template_Log.DateTime_Start, Template_Log.DateTime_Finish)
			ELSE Totals.SumTime END) AS AvgTimeTaken
	FROM Template_Log 
		INNER JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
		INNER JOIN Template ON Template.Template_Guid = Template_Group.Template_Guid
		INNER JOIN Intelledox_User ON Intelledox_User.User_ID = Template_Log.User_ID
		LEFT JOIN ActionListState ON Template_Log.ActionListStateId = ActionListState.ActionListStateId
		LEFT JOIN (SELECT WorkflowTotalState.ActionListId, 
						SUM(DateDiff(second, WorkflowLog.DateTime_Start, WorkflowLog.DateTime_Finish)) as SumTime
					FROM ActionListState WorkflowTotalState
						INNER JOIN Template_Log WorkflowLog ON WorkflowTotalState.ActionListStateId = WorkflowLog.ActionListStateId
					WHERE WorkflowLog.DateTime_Finish IS NOT NULL
					GROUP BY WorkflowTotalState.ActionListId) as Totals ON ActionListState.ActionListId = Totals.ActionListId
    WHERE Template_Log.DateTime_Finish >= @StartDate
        AND Template_Log.DateTime_Finish <= @FinishDate + 1
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
		AND Template_Log.CompletionState = 3
    GROUP BY Template.Template_Guid,
		Template.Name
	ORDER BY AVG(CASE WHEN Totals.SumTime IS NULL 
			THEN DateDiff(second, Template_Log.DateTime_Start, Template_Log.DateTime_Finish)
			ELSE Totals.SumTime END) DESC;
GO
ALTER PROCEDURE [dbo].[spReport_UsageDataTopUsers] (
    @StartDate datetime,
    @FinishDate datetime,
    @BusinessUnitGuid uniqueidentifier
)
AS
    
    SELECT TOP 10 Intelledox_User.Username,
        COUNT(*) AS NumRuns,
        Address_Book.Full_Name
    FROM Template_Log 
        INNER JOIN Intelledox_User ON Intelledox_User.User_ID = Template_Log.User_ID
        LEFT JOIN Address_Book ON Address_Book.Address_id = Intelledox_User.Address_Id
    WHERE Template_Log.DateTime_Finish >= @StartDate
        AND Template_Log.DateTime_Finish <= @FinishDate + 1
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
		AND (Template_Log.CompletionState = 2 OR Template_Log.CompletionState = 3)
    GROUP BY Template_Log.User_ID,
        Intelledox_User.Username,
        Address_Book.Full_Name
    ORDER BY NumRuns DESC;
GO
ALTER TABLE Template_Group
	ADD AllowRestart bit not null CONSTRAINT DF_Template_Group_AllowRestart DEFAULT (0)
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
	@MatchProjectVersion bit
AS
	IF NOT EXISTS(SELECT * FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid)
	BEGIN
		INSERT INTO Template_Group (template_group_guid, helptext, AllowPreview, PostGenerateText, 
				UpdateDocumentFields, EnforceValidation, WizardFinishText, EnforcePublishPeriod,
				PublishStartDate, PublishFinishDate, HideNavigationPane, Template_Guid, Layout_Guid,
				Template_Version, Layout_Version, Folder_Guid, ShowFormActivity, MatchProjectVersion,
				AllowRestart)
		VALUES (@ProjectGroupGuid, @HelpText, @AllowPreview, @PostGenerateText, 
				@UpdateDocumentFields, @EnforceValidation, @WizardFinishText, @EnforcePublishPeriod,
				@PublishStartDate, @PublishFinishDate, @HideNavigationPane, @ProjectGuid, @LayoutGuid,
				@ProjectVersion, @LayoutVersion, @FolderGuid, @ShowFormActivity, @MatchProjectVersion,
				@AllowRestart);
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
				AllowRestart = @AllowRestart
		WHERE	Template_Group_Guid = @ProjectGroupGuid;
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
			a.AllowRestart
    FROM	Template_Group a
			INNER JOIN Template t on a.Template_Guid = t.Template_Guid
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;
GO
INSERT INTO Global_Options (BusinessUnitGuid,OptionCode,OptionDescription,OptionValue)
SELECT bu.Business_Unit_GUID,'SHOW_OPTIONAL','Show non-mandatory fields as optional','false'
FROM Business_Unit bu
GO
-- Space is not reclaimed even for new rows until a rebuild
ALTER INDEX PK_Template_Log ON Template_Log REBUILD
GO
