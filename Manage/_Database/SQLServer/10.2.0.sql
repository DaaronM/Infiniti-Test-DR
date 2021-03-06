truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.2.0');
GO
drop proc spSync_LibraryText;
GO
drop proc spSync_LibraryVersionText;
GO
drop proc spSync_LibraryBinary;
GO
drop proc spSync_LibraryVersionBinary;
GO
drop proc spSynchronise_GetDataSourceDependencies;
GO
drop proc spSynchronise_UpdateDataSourceDependency;
GO
drop proc spSynchronise_GetContentLibraryDependencies;
GO
drop proc spSynchronise_UpdateContentLibraryDependency;
GO
drop proc spSync_TemplateGrpCategory;
GO
drop proc spSync_Project;
GO
drop proc spSync_ProjectVersion;
GO
drop proc spSync_ProjectTemplateFileVersion;
GO
drop proc spSync_UserIntoDeletedUser;
GO
drop proc spSync_ProjectGroup
GO
ALTER TABLE Routing_ElementType
	Add ValueType int NOT NULL DEFAULT 0,
		EnumValues nvarchar(max) NULL,
		ParentRoutingElementTypeId uniqueidentifier NULL
GO
ALTER PROCEDURE [dbo].[spRouting_RegisterTypeAttribute]
	@RoutingTypeId uniqueidentifier,
	@ParentRoutingElementTypeId uniqueidentifier,
	@Id uniqueidentifier,
	@Description nvarchar(255),
	@ElementLimit int,
	@Required bit,
	@AllowTranslation bit,
	@IsKeyValue bit,
	@ValueType int,
	@EnumValues nvarchar(max)
AS
	IF NOT EXISTS(SELECT * FROM Routing_ElementType WHERE RoutingElementTypeId = @Id AND RoutingTypeId = @RoutingTypeId)
	  BEGIN
		INSERT INTO Routing_ElementType(
			RoutingElementTypeId, 
			RoutingTypeId, 
			ElementTypeDescription, 
			ElementLimit, 
			[Required], 
			AllowTranslation, 
			IsKeyValue,
			ValueType,
			EnumValues,
			ParentRoutingElementTypeId)
		VALUES	(
			@Id, 
			@RoutingTypeId, 
			@Description, 
			@ElementLimit, 
			@Required, 
			@AllowTranslation, 
			@IsKeyValue,
			@ValueType,
			@EnumValues,
			@ParentRoutingElementTypeId);
	  END
GO
update Routing_ElementType set ValueType = 1 where RoutingElementTypeId = '1C110C99-ABEF-488A-9D60-F90FCD369B98';
update Routing_ElementType set ValueType = 1 where RoutingElementTypeId = '2EA53BDA-1695-40A3-88F6-7D5C3C4763C6';
update Routing_ElementType set ValueType = 1 where RoutingElementTypeId = '2820BB4A-327A-403A-BDFF-DB51ADCFE767';
update Routing_ElementType set ValueType = 1 where RoutingElementTypeId = '2910C9D8-97F6-4D3A-886F-3CCC0F5F243A';
update Routing_ElementType set ValueType = 2, EnumValues = 'Info|Warning|Error', ElementTypeDescription = 'Level' where RoutingElementTypeId = '0a25a299-12d5-4e20-ba8f-7526e38bddd6';
update Routing_ElementType set ValueType = 1 where RoutingElementTypeId = 'FBAE04A8-2E86-497C-B58C-66F58E717CD1';
update Routing_ElementType set ValueType = 1 where RoutingElementTypeId = '4437BAEC-69CA-454C-8B32-E67593C1AB78';
update Routing_ElementType set ValueType = 1 where RoutingElementTypeId = 'A705B049-7B3A-4D8A-B101-14EE7336F610';
update Routing_ElementType set ValueType = 1, ElementTypeDescription = 'Display Info Messages in Manage' where RoutingElementTypeId = '89DC706C-6AB0-450E-9070-C56EBC1AE188';
update Routing_ElementType set ValueType = 1, ElementTypeDescription = 'Update Existing User' where RoutingElementTypeId = '09DE6B7F-B5BB-4083-862A-F0F228A8471E';
update Routing_ElementType set ValueType = 1, ElementTypeDescription = 'Reset Password' where RoutingElementTypeId = '72142D8B-A0E1-4C67-AD64-379D606890B3';
update Routing_ElementType set ValueType = 1 where RoutingElementTypeId = 'D9F4677B-5FE2-4AF8-9C03-5B68B85830C5';
update Routing_ElementType set ValueType = 1 where RoutingElementTypeId = '87052541-D510-432B-9479-648E0B0B7F63';
GO

CREATE TABLE [dbo].[SyncLog](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[DateTimeReceivedUtc] [datetime] NOT NULL,
	[ReceivedGuid] [uniqueidentifier] NOT NULL,
	[ReceivedType] [int] NOT NULL,
	[UserGuid] [uniqueidentifier] NOT NULL,
	[Messages] [nvarchar](max) NULL,
	[RunID] [uniqueidentifier] NULL,
 CONSTRAINT [PK_SyncLog] PRIMARY KEY CLUSTERED 
(
	[ID] DESC
))
GO

CREATE PROCEDURE [dbo].[spLog_InsertSyncLog]
	@DateTimeUtc DateTime,
	@ReceivedGuid uniqueidentifier,
	@ReceivedType int,
	@UserGuid uniqueidentifier,
	@Messages nvarchar(max),
	@RunID uniqueidentifier
AS
	INSERT INTO SyncLog (DateTimeReceivedUtc, ReceivedGuid, ReceivedType, UserGuid, [Messages], RunID)
	VALUES (@DateTimeUtc, @ReceivedGuid, @ReceivedType, @UserGuid, @Messages, @RunID)
GO

ALTER TABLE User_Session
	ADD Expiry_Date datetime NULL
GO
UPDATE User_Session
SET Expiry_Date = DateAdd(yy, 1, Modified_Date)
WHERE Expiry_Date IS NULL
GO
ALTER TABLE User_Session
	ALTER COLUMN Expiry_Date datetime NOT NULL
GO
ALTER procedure [dbo].[spSession_UserSessionList]
	@SessionGuid uniqueidentifier
as
	SELECT	User_Session.*, Intelledox_User.Business_Unit_Guid, Intelledox_User.User_ID
	FROM	User_Session
			INNER JOIN Intelledox_User ON User_Session.User_Guid = Intelledox_User.User_Guid
	WHERE	User_Session.Session_Guid = @SessionGuid
			AND Intelledox_User.Disabled = 0
			AND User_Session.Expiry_Date >= GETUTCDATE();
GO
ALTER procedure [dbo].[spSession_UpdateUserSession]
	@SessionGuid uniqueidentifier,
	@UserGuid uniqueidentifier,
	@ModifiedDate datetime,
	@AnswerFileID int,
	@LogGuid uniqueidentifier,
	@ExpiryDate datetime
as
	IF EXISTS(SELECT * FROM User_Session WHERE Session_Guid = @SessionGuid)
		UPDATE	User_Session
		SET		AnswerFile_ID = @AnswerFileID,
				Log_Guid = @LogGuid
		WHERE	Session_Guid = @SessionGuid;
	ELSE
		INSERT INTO User_Session (Session_Guid, User_Guid, Modified_Date, AnswerFile_ID, Log_Guid, Expiry_Date)
		VALUES (@SessionGuid, @UserGuid, @ModifiedDate, @AnswerFileID, @LogGuid, @ExpiryDate);
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
update Routing_ElementType set ValueType = 3 where RoutingElementTypeId = '6A6B97F6-8EAA-4CEE-AA82-48A9BA6FDFAA';
GO
update Routing_ElementType set ParentRoutingElementTypeId = 'B8BC1B2B-50C4-4DD4-B902-E6C18EB53318' where RoutingElementTypeId = 'C9DEB5A7-B4C6-452F-9A29-219726B59E32';
update Routing_ElementType set ParentRoutingElementTypeId = 'B8BC1B2B-50C4-4DD4-B902-E6C18EB53318' where RoutingElementTypeId = 'E3697D97-560F-4C7A-B9F9-C5574DD97131';
update Routing_ElementType set ParentRoutingElementTypeId = 'B8BC1B2B-50C4-4DD4-B902-E6C18EB53318' where RoutingElementTypeId = 'FEF0DC97-6284-4FDB-B207-7814B5794FAD';
update Routing_ElementType set ParentRoutingElementTypeId = 'B8BC1B2B-50C4-4DD4-B902-E6C18EB53318' where RoutingElementTypeId = '1C110C99-ABEF-488A-9D60-F90FCD369B98';
update Routing_ElementType set ParentRoutingElementTypeId = 'B8BC1B2B-50C4-4DD4-B902-E6C18EB53318' where RoutingElementTypeId = '2EA53BDA-1695-40A3-88F6-7D5C3C4763C6';
GO
ALTER PROCEDURE [dbo].[spWorkflow_WorkflowUserByTaskListStateGuid]
	@taskListStateGuid uniqueidentifier,
	@assignedType int
AS
BEGIN
	SELECT	AssignedGuid
	FROM	ActionListState
	WHERE	ActionListStateId = @taskListStateGuid AND AssignedType = @assignedType
END
GO
ALTER TABLE [dbo].[Business_Unit]
	ADD [SamlSpCertificateType] [int] NOT NULL DEFAULT 0,
	[SamlSpCertificate] [nvarchar](max) NULL
GO
ALTER PROCEDURE [spTenant_UpdateBusinessUnit]
	@BusinessUnitGuid uniqueidentifier,
	@Name nvarchar(200),
	@SubscriptionType int,
	@ExpiryDate datetime,
	@TenantFee money,
	@DefaultCulture nvarchar(11),
	@DefaultLanguage nvarchar(11),
	@DefaultTimezone nvarchar(50),
	@UserFee money,
	@SamlEnabled bit, 
	@SamlCertificate nvarchar(max), 
	@SamlCertificateType int, 
	@SamlCreateUsers bit, 
	@SamlIssuer nvarchar(255), 
	@SamlLoginUrl nvarchar(1500), 
	@SamlLogoutUrl nvarchar(1500),
	@SamlManageEntityId nvarchar(1500),
	@SamlProduceEntityId nvarchar(1500),
	@SamlLog bit,
	@SamlLastLoginFail nvarchar(max),
	@TenantKey varbinary(50),
	@Eula nvarchar(max),
	@EnforceEula bit,
	@TenancyKeyDateUtc datetime = NULL, 
	@SamlSpCertificate nvarchar(max), 
	@SamlSpCertificateType int
AS
	UPDATE	Business_Unit
	SET		Name = @Name,
			SubscriptionType = @SubscriptionType,
			ExpiryDate = @ExpiryDate,
			TenantFee = @TenantFee,
			DefaultCulture = @DefaultCulture,
			DefaultLanguage = @DefaultLanguage,
			DefaultTimezone = @DefaultTimezone,
			UserFee = @UserFee,
			SamlEnabled = @SamlEnabled,
			SamlCertificate = @SamlCertificate,
			SamlCertificateType = @SamlCertificateType,
			SamlCreateUsers = @SamlCreateUsers,
			SamlIssuer = @SamlIssuer,
			SamlLoginUrl = @SamlLoginUrl,
			SamlLogoutUrl = @SamlLogoutUrl,
			SamlManageEntityId = @SamlManageEntityId,
			SamlProduceEntityId = @SamlProduceEntityId,
			SamlLog = @SamlLog,
			SamlLastLoginFail = @SamlLastLoginFail,
			TenantKey = @TenantKey,
			Eula = @Eula,
			EnforceEula = @EnforceEula,
			TenancyKeyDateUtc = @TenancyKeyDateUtc,
			SamlSpCertificate = @SamlSpCertificate,
			SamlSpCertificateType = @SamlSpCertificateType
	WHERE	Business_Unit_Guid = @BusinessUnitGuid;
GO

INSERT INTO Global_Options (BusinessUnitGuid,OptionCode,OptionDescription,OptionValue)
SELECT bu.Business_Unit_GUID,'SHOW_PROFILE_PAGE','Show profile page in produce','true'
FROM Business_Unit bu
GO
ALTER TABLE PendingWorkflowTransition
	ADD UserGuid uniqueidentifier NULL
GO
ALTER PROCEDURE [dbo].[spWorkflow_UpdatePending] (
	@PendingWorkflowTransitionId uniqueidentifier,
	@ActionListStateId uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier,
	@StateId uniqueidentifier,
	@AllowCommenting bit,
	@UserGuid uniqueidentifier
)
AS
	INSERT INTO PendingWorkflowTransition(
		PendingWorkflowTransitionId,
		ActionListStateId,
		BusinessUnitGuid,
		StateId,
		AllowCommenting,
		UserGuid)
	VALUES (@PendingWorkflowTransitionId,
		@ActionListStateId,
		@BusinessUnitGuid,
		@StateId,
		@AllowCommenting,
		@UserGuid)
		
GO

ALTER PROCEDURE [dbo].[spGetCached_DataSourceDependencies] (    
 @ProjectGuid as uniqueidentifier , @ProjectVersion as nvarchar(10)  
)    
AS    
 SELECT DISTINCT Data_Object.Data_Object_Guid,    
  Data_Object.Data_Object_ID,    
  Data_Object.Data_Service_Guid,    
  Data_Object.Data_Service_ID,    
  Data_Object.Display_Name,    
  Data_Object.Merge_Source,    
  Data_Object.[Object_Name],    
  Data_Object.Object_Type,    
  Data_Object.Allow_Cache,    
  Data_Object.Cache_Duration,    
  Data_Object.Cache_Warning,    
  Data_Object.Cache_Warning_Message,    
  Data_Object.Cache_Expiry,    
  Data_Object.UseAnswerFileData    
 FROM [Data_Object]    
 inner join Xtf_Datasource_Dependency ON Xtf_Datasource_Dependency.Data_Object_Guid = [Data_Object].Data_Object_Guid    
 AND Xtf_Datasource_Dependency.Template_Guid = @ProjectGuid  AND Xtf_Datasource_Dependency.Template_Version = @ProjectVersion  
 WHERE Data_Object.Allow_Cache = 1 OR Data_Object.UseAnswerFileData = 1 
 GO
ALTER PROCEDURE [dbo].[spProject_GetProjectVersionByPublishedByAndGroupGuid] (
	@ProjectGroupGuid uniqueidentifier,
	@ProjectGuid uniqueidentifier,
	@PublishedBy datetime
)
AS
	SELECT	Template.Template_Version, Template.Modified_Date
		FROM	Template_Group,
				Template 
		WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid
			AND Template.Template_Guid = @ProjectGuid
			AND (Template_Group.MatchProjectVersion = 0 
				OR Template.Modified_Date <= @PublishedBy)
	UNION ALL
		SELECT	Template_Version.Template_Version, Template_Version.Modified_Date
		FROM	Template_Group,
				Template_Version
		WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid
				AND Template_Version.Template_Guid = @ProjectGuid
				AND (Template_Group.MatchProjectVersion = 1 
							AND Template_Version.Modified_Date = (SELECT TOP 1 VersionDate.Modified_Date
								FROM Template_Version VersionDate
								WHERE VersionDate.Template_Guid = Template_Version.Template_Guid
									AND VersionDate.Modified_Date <= @PublishedBy
								ORDER BY VersionDate.Modified_Date DESC))
GO

ALTER PROCEDURE [dbo].[spProject_DefinitionByDate] (
	@ProjectGroupGuid uniqueidentifier,
	@ProjectGuid uniqueidentifier,
	@PublishedBy datetime
)
AS
SELECT TOP 1 * FROM(
	SELECT	Template.Template_Version, 
			CASE WHEN Template.EncryptedProjectDefinition IS NULL THEN 0 ELSE 1 END AS Encrypted,
			Template.EncryptedProjectDefinition,
			Template.Project_Definition
		FROM	Template_Group,
				Template 
		WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid
			AND Template.Template_Guid = @ProjectGuid
			AND (Template_Group.MatchProjectVersion = 0 
				OR Template.Modified_Date <= @PublishedBy)
	UNION ALL
		SELECT	Template_Version.Template_Version, 
			CASE WHEN Template_Version.EncryptedProjectDefinition IS NULL THEN 0 ELSE 1 END AS Encrypted,
			Template_Version.EncryptedProjectDefinition,
			Template_Version.Project_Definition
		FROM	Template_Group,
				Template_Version
		WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid
				AND Template_Version.Template_Guid = @ProjectGuid
				AND (Template_Group.MatchProjectVersion = 1 
							AND Template_Version.Modified_Date = (SELECT TOP 1 VersionDate.Modified_Date
								FROM Template_Version VersionDate
								WHERE VersionDate.Template_Guid = Template_Version.Template_Guid
									AND VersionDate.Modified_Date <= @PublishedBy
								ORDER BY VersionDate.Modified_Date DESC))
	) as T
GO
CREATE TABLE dbo.ActionDocument
    (
	ActionTypeId uniqueidentifier NOT NULL,
	ActionDocumentGuid uniqueidentifier NOT NULL,
	Name nvarchar(255) NOT NULL,
	OutputType int NOT NULL
	)
GO
ALTER TABLE dbo.ActionDocument ADD CONSTRAINT
	PK_ActionDocument PRIMARY KEY CLUSTERED 
	(
	ActionDocumentGuid
	)
GO
CREATE PROC spRouting_RegisterActionAvailableDocument
	@ActionTypeId uniqueidentifier,
	@ActionDocumentGuid uniqueidentifier,
	@Name nvarchar(255),
	@OutputType int
AS
	IF NOT EXISTS(SELECT * 
		FROM ActionDocument 
		WHERE ActionTypeId = @ActionTypeId 
			AND ActionDocumentGuid = @ActionDocumentGuid)
	BEGIN
		INSERT INTO ActionDocument(ActionTypeId, ActionDocumentGuid, Name, OutputType)
		VALUES	(@ActionTypeId, @ActionDocumentGuid, @Name, @OutputType);
	END
GO
CREATE PROCEDURE [dbo].[spRouting_ActionAvailableDocumentList]
	@ActionTypeId uniqueidentifier
AS
	SELECT	*
	FROM	ActionDocument
	WHERE	ActionTypeId = @ActionTypeId
	ORDER BY Name;
GO

INSERT INTO Global_Options (BusinessUnitGuid,OptionCode,OptionDescription,OptionValue)
SELECT bu.Business_Unit_GUID,'GEN_DOC_STAMP','Stamp that appears on generated documents for Standard/Transactional licenses',''
FROM Business_Unit bu
GO
ALTER PROCEDURE [dbo].[spProject_DefinitionsByGroup] (
	@TemplateGroupGuid uniqueidentifier,
	@PublishedBy datetime
)
AS
	DECLARE @MatchProjectVersion bit;
	DECLARE @LayoutGuid uniqueidentifier;
	DECLARE @LayoutVersion nvarchar(10);
	DECLARE @TemplateGuid uniqueidentifier;
	DECLARE @TemplateVersion nvarchar(10);

	SELECT	@MatchProjectVersion = Template_Group.MatchProjectVersion,
			@LayoutGuid = Template_Group.Layout_Guid,
			@LayoutVersion = Template_Group.Layout_Version,
			@TemplateGuid = Template_Group.Template_Guid,
			@TemplateVersion = Template_Group.Template_Version
	FROM	Template_Group
	WHERE	Template_Group.Template_Group_Guid = @TemplateGroupGuid

	IF (@MatchProjectVersion = 0 OR @PublishedBy >= '9999-12-31')
	BEGIN
		-- New launches
		SELECT	Template.Template_Guid, 
				Template.Template_Type_ID,
				Template.Template_Version, 
				CASE WHEN Template.EncryptedProjectDefinition IS NULL THEN 0 ELSE 1 END AS Encrypted,
				Template.EncryptedProjectDefinition,
				Template.Project_Definition
		FROM	Template
		WHERE	(Template.Template_Guid = @TemplateGuid AND (@TemplateVersion IS NULL OR Template.Template_Version = @TemplateVersion))
					OR (Template.Template_Guid = @LayoutGuid AND (@LayoutVersion IS NULL OR Template.Template_Version = @LayoutVersion))
		UNION ALL
		SELECT	Template_Version.Template_Guid, 
				Template.Template_Type_ID,
				Template_Version.Template_Version, 
				CASE WHEN Template_Version.EncryptedProjectDefinition IS NULL THEN 0 ELSE 1 END AS Encrypted,
				Template_Version.EncryptedProjectDefinition,
				Template_Version.Project_Definition
		FROM	Template
				INNER JOIN Template_Version ON Template.Template_Guid = Template_Version.Template_Guid
					AND ((Template_Version.Template_Guid = @TemplateGuid AND Template_Version.Template_Version = @TemplateVersion)
					   OR (Template_Version.Template_Guid = @LayoutGuid AND Template_Version.Template_Version = @LayoutVersion))
		ORDER BY Template_Type_ID;
	END
	ELSE
	BEGIN
		-- Resume launches of match project version
		SELECT	Template.Template_Guid, 
				Template.Template_Type_ID,
				Template.Template_Version, 
				CASE WHEN Template.EncryptedProjectDefinition IS NULL THEN 0 ELSE 1 END AS Encrypted,
				Template.EncryptedProjectDefinition,
				Template.Project_Definition
		FROM	Template
		WHERE	(Template.Template_Guid = @TemplateGuid OR Template.Template_Guid = @LayoutGuid)
				AND Template.Modified_Date <= @PublishedBy
		UNION ALL
		SELECT	Template_Version.Template_Guid, 
				Template.Template_Type_ID,
				Template_Version.Template_Version, 
				CASE WHEN Template_Version.EncryptedProjectDefinition IS NULL THEN 0 ELSE 1 END AS Encrypted,
				Template_Version.EncryptedProjectDefinition,
				Template_Version.Project_Definition
		FROM	Template
				INNER JOIN Template_Version ON Template.Template_Guid = Template_Version.Template_Guid
		WHERE	(Template_Version.Template_Guid = @TemplateGuid AND Template_Version.Template_Guid = @LayoutGuid)
				AND Template.Modified_Date > @PublishedBy
				AND Template_Version.Modified_Date = (SELECT TOP 1 VersionDate.Modified_Date
								FROM Template_Version VersionDate
								WHERE VersionDate.Template_Guid = Template_Version.Template_Guid
									AND VersionDate.Modified_Date <= @PublishedBy
								ORDER BY VersionDate.Modified_Date DESC)
		ORDER BY Template_Type_ID;
	END
GO

ALTER TABLE ActionListState ADD StartPageGuid uniqueidentifier
GO
