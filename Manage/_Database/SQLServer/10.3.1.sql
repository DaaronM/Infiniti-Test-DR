truncate table dbversion;
GO
insert into dbversion(dbversion) values ('10.3.1');
GO
ALTER TABLE CustomQuestion_Type
	ADD PreviewHtml nvarchar(MAX)
GO
ALTER PROCEDURE [dbo].[spCustomQuestion_RegisterType]
	@Id uniqueidentifier,
	@Description nvarchar(255),
	@Icon16 varbinary(MAX),
	@Icon48 varbinary(MAX),
	@ModuleId nvarchar(4) = NULL,
	@PreviewHtml nvarchar(MAX) = NULL
AS
	IF NOT EXISTS(SELECT * FROM CustomQuestion_Type WHERE CustomQuestionTypeId = @id)
	BEGIN
		INSERT INTO CustomQuestion_Type(CustomQuestionTypeId, Description, Icon, Icon48, ModuleId, PreviewHtml)
		VALUES	(@id, @Description, @Icon16, @Icon48, @ModuleId, @PreviewHtml);
	END
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'zzAddress_Type')
BEGIN
	DROP TABLE zzAddress_Type;
END
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'zzadmin_group')
BEGIN
	DROP TABLE zzadmin_group;
END
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'zzContent_Definition')
BEGIN
	IF NOT EXISTS(SELECT 1 FROM zzContent_Definition)
	BEGIN
		DROP TABLE zzContent_Definition;
	END
END
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'zzContent_Definition_Item')
BEGIN
	IF NOT EXISTS(SELECT 1 FROM zzContent_Definition_Item)
	BEGIN
		DROP TABLE zzContent_Definition_Item;
	END
END
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'zzData_Service_Credential')
BEGIN
	DROP TABLE zzData_Service_Credential;
END
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'zzFormat_Type')
BEGIN
	DROP TABLE zzFormat_Type;
END
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'zzLicenseKey')
BEGIN
	IF NOT EXISTS(SELECT 1 FROM zzLicenseKey)
	BEGIN
		DROP TABLE zzLicenseKey;
	END
END
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'zzPurchaseLineItem')
BEGIN
	DROP TABLE zzPurchaseLineItem;
END
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'zzPurchaseTransaction')
BEGIN
	DROP TABLE zzPurchaseTransaction;
END
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'zzTemplate_Category')
BEGIN
	IF NOT EXISTS(SELECT 1 FROM zzTemplate_Category)
	BEGIN
		DROP TABLE zzTemplate_Category;
	END
END
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'zzTemplate_group_Item')
BEGIN
	IF NOT EXISTS(SELECT 1 FROM zzTemplate_group_Item)
	BEGIN
		DROP TABLE zzTemplate_group_Item;
	END
END
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'zzTemplate_PageLog')
BEGIN
	DROP TABLE zzTemplate_PageLog;
END
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'zzUser_Group_Role')
BEGIN
	IF NOT EXISTS(SELECT 1 FROM zzUser_Group_Role)
	BEGIN
		DROP TABLE zzUser_Group_Role;
	END
END
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'zzUser_Group_Template')
BEGIN
	IF NOT EXISTS(SELECT 1 FROM zzUser_Group_Template)
	BEGIN
		DROP TABLE zzUser_Group_Template;
	END
END
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'zzUser_Signoff')
BEGIN
	IF NOT EXISTS(SELECT 1 FROM zzUser_Signoff)
	BEGIN
		DROP TABLE zzUser_Signoff;
	END
END
GO
UPDATE CustomQuestion_Type
SET PreviewHtml = '<input type="button" value="Get" />'
WHERE CustomQuestionTypeId = '5F6BF73A-DC92-4379-8480-E9FDA5A36B81'
GO
UPDATE CustomQuestion_Type
SET PreviewHtml = '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAZcAAADVBAMAAABpr6DtAAAAElBMVEVGgrSIiIiXl5empqbDw8P////BhydsAAABWklEQVR4XuzRMREAIADEMCz8gBR8MIB/K/h4Uge5jtvT/hkDAwNzktV0ZnZhYGBgYGBgYGBgYGBgYB47dmwCAAgDAdDGAdzMwv1ncQEDUUQQ7vsQju++rFNhTjYAzcBkAwMD8+IDDEwuMDAwMDAwMD1QhgCY0ZpmvsbAwMDAwMDAwMDAwMDAwNgAYGBgYGBgYGBgYGBgYGBgbAAwMDAwMDAw+5eXMDAwMJMdO6YBAAiBIKjhvOFfCwooPqEg+VEAk+3uFbN0AQYGBqaSdYwyMDAwMDAwMDAwMPNvMDAwMMc2AGVgYGBgYGBgYGBgYGBgYGwAysDATKdgYGBgYGBgYGBgYGBubwDKwCzor2NgYGBgYGBgYGBgYGBgKvmgDAwMDAwMDAwMDAwMDAwMTC9EUFBRcHgAB4ZQdCAKpdFBIJQevBoCRj0zIBpGPeOKQ2cIlB6cGqCeGT4gAADWo+oOM1psaAAAAABJRU5ErkJggg==" alt=" " />'
WHERE CustomQuestionTypeId = '4AB68B5A-C5F7-4935-96CC-17AFEC09FBAB'
GO
ALTER TABLE CustomQuestion_InputType
	Add ValueType int NOT NULL DEFAULT 0,
		EnumValues nvarchar(max) NULL
GO
ALTER PROCEDURE [dbo].[spCustomQuestion_RegisterInput]
	@CustomQuestionTypeId uniqueidentifier,
	@InputId uniqueidentifier,
	@Description nvarchar(255),
	@ElementLimit int,
	@Required bit,
	@IsKeyValue bit,
	@ValueType int,
	@EnumValues nvarchar(max)
AS
	IF NOT EXISTS(SELECT * 
					FROM CustomQuestion_InputType 
					WHERE InputTypeId = @InputId AND @CustomQuestionTypeId = @CustomQuestionTypeId)
	BEGIN
		INSERT INTO CustomQuestion_InputType(InputTypeId, CustomQuestionTypeId, InputTypeDescription, ElementLimit, [Required], IsKeyValue, ValueType, EnumValues)
		VALUES	(@InputId, @CustomQuestionTypeId, @Description, @ElementLimit, @Required, @IsKeyValue, @ValueType, @EnumValues);
	END
GO
CREATE PROCEDURE [dbo].[spLog_UpdateProjectLogUserId]
	@LogGuid uniqueidentifier,
	@UserId int
AS
	UPDATE	Template_Log WITH (ROWLOCK, UPDLOCK)
	SET		User_ID = @UserId
	WHERE	Log_Guid = @LogGuid;
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
	DECLARE @RunId uniqueidentifier;

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
	WHERE Expiry_Date < GetUtcDate();

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
	CREATE TABLE #ExpiredTempUsers
    ( 
        Id uniqueidentifier NOT NULL PRIMARY KEY
    )
	
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

				INSERT #ExpiredTempUsers (Id)
				SELECT DISTINCT(ActionListState.AssignedGuid)
				FROM ActionListState 
				INNER JOIN Intelledox_User on Intelledox_User.User_Guid = ActionListState.AssignedGuid
				WHERE Intelledox_User.IsTemporaryUser = 1 AND ActionListState.ActionListId = @GuidId;

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
	-- Expired TemporaryUsers
	
  	INSERT #ExpiredTempUsers (Id)
	SELECT DISTINCT(User_Guid)
	FROM Intelledox_User WITH (READUNCOMMITTED)
	INNER JOIN Template_Log ON Intelledox_User.User_ID = Template_Log.User_ID
	WHERE Intelledox_User.IsTemporaryUser = 1 AND 
		Template_Log.ActionListStateId = '00000000-0000-0000-0000-000000000000' AND
		Template_Log.DateTime_Finish < @TemporaryUsersCleanup;
	
  	INSERT #ExpiredTempUsers (Id)
	SELECT DISTINCT(User_Guid)
	FROM Intelledox_User WITH (READUNCOMMITTED)
	LEFT OUTER JOIN Template_Log ON Intelledox_User.User_ID = Template_Log.User_ID
	LEFT OUTER JOIN ActionListState ON Intelledox_User.User_Guid = ActionListState.AssignedGuid
	WHERE Intelledox_User.IsTemporaryUser = 1 AND 
		Template_Log.Log_Guid IS NULL AND
		ActionListState.AssignedGuid IS NULL;

    IF @@ROWCOUNT <> 0 
    BEGIN 
        DECLARE ExpiredItemCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
        FOR SELECT Id FROM #ExpiredTempUsers 

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

    DROP TABLE #ExpiredTempUsers;

	-- ==================================================
	-- Expired Assets
	CREATE TABLE #ExpiredAssetItems 
	( 
		Id uniqueidentifier NOT NULL,
		RunId uniqueidentifier NOT NULL
	)

	-- Join data that has an AssetRunId entry only
	INSERT #ExpiredAssetItems (Id, RunId)
	SELECT AssetStorage.Id, AssetRunID.RunID
	FROM AssetStorage WITH (READUNCOMMITTED)
	INNER JOIN AssetRunID assetRunId on assetRunId.AssetID = AssetStorage.Id
	WHERE DateCreatedUtc < @GenerationCleanupDate

	IF @@ROWCOUNT <> 0 
	BEGIN 
		DECLARE ExpiredItemCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
		FOR SELECT Id, RunId FROM #ExpiredAssetItems 

		OPEN ExpiredItemCursor;
		FETCH NEXT FROM ExpiredItemCursor INTO @GuidId, @RunId;

		WHILE @@FETCH_STATUS = 0 
			BEGIN
				BEGIN TRANSACTION AL;

				DELETE assetRunId FROM AssetRunID assetRunId
				INNER JOIN AssetStorage asset on assetRunId.AssetID = asset.Id
				WHERE asset.Id = @GuidId AND assetRunID.RunID = @RunId AND @RunId NOT IN 
					(SELECT tl.RunID FROM Template_Log tl WHERE tl.RunID = @RunId
					 UNION
					 SELECT als.RunID FROM ActionListState als WHERE als.RunID = @RunId
					 UNION
					 SELECT af.RunID FROM Answer_File af WHERE af.RunID = @RunId)

				DELETE asset FROM AssetStorage asset
				WHERE asset.Id = @GuidId AND asset.ID NOT IN (SELECT AssetRunID.AssetID FROM AssetRunID)
			
				COMMIT TRANSACTION AL;

				FETCH NEXT FROM ExpiredItemCursor INTO @GuidId, @RunId;
			END

		CLOSE ExpiredItemCursor;
		DEALLOCATE ExpiredItemCursor;

	END 
	
	DROP TABLE #ExpiredAssetItems;

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
	-- Expired sync logs
    CREATE TABLE #ExpiredSync
    ( 
        Id bigint NOT NULL PRIMARY KEY
    )

	INSERT #ExpiredSync (Id)
	SELECT ID
	FROM SyncLog WITH (READUNCOMMITTED)
	WHERE DateTimeReceivedUtc < @AuditCleanupDate;

    IF @@ROWCOUNT <> 0 
    BEGIN 
        DECLARE ExpiredSyncCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
        FOR SELECT Id FROM #ExpiredSync 

        OPEN ExpiredSyncCursor;
        FETCH NEXT FROM ExpiredSyncCursor INTO @BigId;

        WHILE @@FETCH_STATUS = 0 
            BEGIN
                DELETE FROM SyncLog WHERE ID = @BigId;
                FETCH NEXT FROM ExpiredSyncCursor INTO @BigId;
            END

        CLOSE ExpiredSyncCursor;
        DEALLOCATE ExpiredSyncCursor;
    END 
	
    DROP TABLE #ExpiredSync;
	

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
	
	-- ==================================================
	-- Pending transitions
	IF EXISTS(SELECT * FROM PendingWorkflowTransition)
	BEGIN
	
		DECLARE @ActionListStateId uniqueidentifier;
		CREATE TABLE #ExpiredActionListStates
		(
			ActionListStateId uniqueidentifier NOT NULL PRIMARY KEY
		)
		
		INSERT #ExpiredActionListStates (ActionListStateId)
		SELECT DISTINCT ActionListStateId
		FROM ActionListState WITH (READUNCOMMITTED)
		WHERE ActionListState.IsComplete = 1;
		
		INSERT #ExpiredActionListStates (ActionListStateId)
		SELECT DISTINCT(ActionListStateId)
		FROM PendingWorkflowTransition WITH (READUNCOMMITTED)
		WHERE ActionListStateId NOT IN (SELECT ActionListStateId 
										FROM ActionListState)
		
		IF @@ROWCOUNT <> 0 
		BEGIN 
			DECLARE ActionListStateCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
			FOR SELECT ActionListStateId FROM #ExpiredActionListStates 

			OPEN ActionListStateCursor;
			FETCH NEXT FROM ActionListStateCursor INTO @ActionListStateId;

			WHILE @@FETCH_STATUS = 0 
				BEGIN
					EXEC spWorkflow_RemovePending @ActionListStateId;
					FETCH NEXT FROM ActionListStateCursor INTO @ActionListStateId;
				END

			CLOSE ActionListStateCursor;
			DEALLOCATE ActionListStateCursor;
		END 
	
		DROP TABLE #ExpiredActionListStates;

	END
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
	ELSE IF (EXISTS(Select Custom_Field_ID FROM Custom_Field WHERE Custom_Field_ID = @CustomFieldID))
		BEGIN
			UPDATE Custom_Field
			SET Title = @Title,
			Validation_Type = @ValidationType,
			[Location] = @Location
			WHERE Custom_Field_ID = @CustomFieldID
		END
	ELSE
	BEGIN
		SET IDENTITY_INSERT Custom_Field ON
			INSERT INTO Custom_Field (Custom_Field_ID, BusinessUnitGuid, Title, Validation_Type, [Location])
			VALUES (@CustomFieldID, @BusinessUnitGuid, @Title, @ValidationType, @Location)
		SET IDENTITY_INSERT Custom_Field OFF
	END
GO

CREATE PROCEDURE [dbo].[spConnectorSettings_ElementType]
	@BusinessUnitGuid uniqueidentifier,
	@AttributeId uniqueidentifier
AS
BEGIN
	SET NOCOUNT ON

	SELECT	et.ConnectorSettingsElementTypeId,
			et.ConnectorSettingsTypeId,
			et.DescriptionDefault,
			et.Obfuscate,
			et.SortOrder,
			CASE WHEN bet.ElementValue IS NULL AND bet.EncryptedElementValue IS NULL THEN et.ElementValue ELSE bet.ElementValue END AS ElementValue,
			bet.EncryptedElementValue,
			et.Encrypt
	FROM	ConnectorSettings_ElementType et
			LEFT JOIN ConnectorSettings_BusinessUnit bet ON et.ConnectorSettingsElementTypeId = bet.ConnectorSettingsElementTypeId AND bet.BusinessUnitGuid = @BusinessUnitGuid
	WHERE	et.ConnectorSettingsElementTypeId = @AttributeId
END
GO
