truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.0');
go

ALTER TABLE ProcessJob
	ADD QueueUntil datetime null
GO
ALTER PROCEDURE [dbo].[spJob_QueueList]
	@BusinessUnitGuid uniqueidentifier,
	@StartDate DateTime,
	@FinishDate DateTime,
	@CurrentStatus Int
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus,
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
	ORDER BY ProcessJob.DateStarted DESC;
GO
ALTER PROCEDURE [dbo].[spJob_QueueListByDefinition]
	@JobDefinitionId uniqueidentifier
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus,
			Template.Name as ProjectName, Intelledox_User.Username, 
			ProcessJob.LogGuid, ProcessJob.QueueUntil,
			CASE WHEN template_Log.Messages IS NOT NULL THEN 1 ELSE 0 END AS HasMessages
	FROM	ProcessJob
			INNER JOIN Intelledox_User ON ProcessJob.UserGuid = Intelledox_User.User_Guid
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
			LEFT JOIN Template_Log ON ProcessJob.LogGuid = Template_Log.Log_Guid
	WHERE	ProcessJob.JobDefinitionGuid = @JobDefinitionId
	ORDER BY ProcessJob.DateStarted DESC;
GO
ALTER PROCEDURE [dbo].[spJob_Queued]
	@UtcNow DateTime
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus,
			ProcessJob.LogGuid, ProcessJob.JobDefinitionGuid, ProcessJob.QueueUntil
	FROM	ProcessJob
	WHERE	ProcessJob.CurrentStatus = 1
			AND (ProcessJob.QueueUntil IS NULL OR ProcessJob.QueueUntil <= @UtcNow)
	ORDER BY ProcessJob.DateStarted;
GO
ALTER PROCEDURE [dbo].[spJob_LodgeJob] (
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier,
	@DateStarted datetime,
	@ProjectGroupGuid uniqueidentifier,
	@LogGuid uniqueidentifier,
	@JobDefinitionGuid uniqueidentifier,
	@InitialStatus int,
	@QueueUntil datetime
)
AS
	IF (@ProjectGroupGuid IS NULL AND @JobDefinitionGuid IS NOT NULL)
	BEGIN
		SELECT	@ProjectGroupGuid = JobDefinition.value('data(AnswerFile/HeaderInfo/TemplateInfo/@TemplateGroupGuid)[1]', 'uniqueidentifier')
		FROM	JobDefinition
		WHERE	JobDefinitionId = @JobDefinitionGuid;
	END

	INSERT INTO ProcessJob(JobId, UserGuid, DateStarted, ProjectGroupGuid, CurrentStatus, LogGuid, JobDefinitionGuid, QueueUntil)
	VALUES (@JobId, @UserGuid, @DateStarted, @ProjectGroupGuid, @InitialStatus, @LogGuid, @JobDefinitionGuid, @QueueUntil);
GO
ALTER procedure [dbo].[spProject_GetProjectCount]
	@FolderGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@Anonymous bit,
	@ErrorCode int = 0 output
AS
BEGIN
	DECLARE @ProjectAllCount int,
			@ProjectCount int;

	IF @FolderGuid IS NOT NULL
	BEGIN
		SELECT @ProjectAllCount = COUNT(DISTINCT Template_Guid)
		FROM Template_Group
		WHERE Folder_Guid = @FolderGuid;

		SELECT @ProjectCount = COUNT(DISTINCT Template_Guid)
		FROM Template_Group
			INNER JOIN Folder_Group ON Template_Group.Folder_Guid = Folder_Group.FolderGuid 
		WHERE Template_Group.Folder_Guid = @FolderGuid
			AND Folder_Group.GroupGuid IN 
				(SELECT GroupGuid
				FROM User_Group_Subscription 
					INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
				WHERE Intelledox_User.IsGuest = @Anonymous
					AND Intelledox_User.[Disabled] = 0);
	END
	ELSE
	BEGIN
		SELECT @ProjectAllCount = COUNT(DISTINCT Template_Guid)
		FROM Template_Group
			INNER JOIN Folder_Group ON Template_Group.Folder_Guid = Folder_Group.FolderGuid 
		WHERE Folder_Group.GroupGuid = @GroupGuid;

		SELECT @ProjectCount = COUNT(DISTINCT Template_Guid)
		FROM Template_Group
		INNER JOIN Folder_Group ON Template_Group.Folder_Guid = Folder_Group.FolderGuid 
		WHERE Template_Guid IN 
			(SELECT Template_Guid 
				FROM Template_Group
					INNER JOIN Folder_Group ON Template_Group.Folder_Guid = Folder_Group.FolderGuid 
				WHERE Folder_Group.GroupGuid = @GroupGuid)
			AND Folder_Group.GroupGuid IN 
				(SELECT GroupGuid
				FROM User_Group_Subscription 
					INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
				WHERE Intelledox_User.IsGuest = @Anonymous
					AND Intelledox_User.[Disabled] = 0);
	END
		
	SELECT @ProjectAllCount - @ProjectCount;
	
	SET @ErrorCode = @@ERROR;

END
GO

UPDATE Template
SET Template_Type_ID = 1
WHERE Template_Type_ID = 3;
GO
CREATE PROCEDURE [dbo].[spConnectorSettings_ElementTypeListByAttribute]
	@BusinessUnitGuid uniqueidentifier,
	@AttributeId uniqueidentifier
AS
BEGIN
	SET NOCOUNT ON

	SELECT	et.ConnectorSettingsElementTypeId,
			et.ConnectorSettingsTypeId,
			et.DescriptionDefault,
			et.Encrypt,
			et.SortOrder,
			CASE WHEN bet.ElementValue IS NULL THEN et.ElementValue ELSE bet.ElementValue END AS ElementValue
	FROM	ConnectorSettings_ElementType et
			LEFT JOIN ConnectorSettings_BusinessUnit bet ON et.ConnectorSettingsElementTypeId = bet.ConnectorSettingsElementTypeId
				AND bet.BusinessUnitGuid = @BusinessUnitGuid
	WHERE	et.ConnectorSettingsTypeId = 
		(SELECT ConnectorSettings_ElementType.ConnectorSettingsTypeId
		FROM ConnectorSettings_ElementType
		WHERE ConnectorSettings_ElementType.ConnectorSettingsElementTypeId = @AttributeId)
	ORDER BY et.SortOrder, et.DescriptionDefault;
END
GO
CREATE procedure [dbo].[spTemplate_RoutingElementType]
	@RoutingElementTypeId uniqueidentifier
AS
	SELECT	*
	FROM	Routing_ElementType
	WHERE	RoutingElementTypeId = @RoutingElementTypeId;
GO
ALTER TABLE Routing_ElementType
	ADD IsKeyValue bit NOT NULL default 0
GO
ALTER PROCEDURE [dbo].[spRouting_RegisterTypeAttribute]
	@RoutingTypeId uniqueidentifier,
	@Id uniqueidentifier,
	@Description nvarchar(255),
	@ElementLimit int,
	@Required bit,
	@AllowTranslation bit,
	@IsKeyValue bit
AS
	IF NOT EXISTS(SELECT * FROM Routing_ElementType WHERE RoutingElementTypeId = @Id AND RoutingTypeId = @RoutingTypeId)
	  BEGIN
		INSERT INTO Routing_ElementType(RoutingElementTypeId, RoutingTypeId, ElementTypeDescription, ElementLimit, [Required], AllowTranslation, IsKeyValue)
		VALUES	(@Id, @RoutingTypeId, @Description, @ElementLimit, @Required, @AllowTranslation, @IsKeyValue);
	  END
GO
UPDATE Routing_ElementType
SET	ElementTypeDescription = 'Stored Procedure Parameter',
	ElementLimit = 0,
	IsKeyValue = 1
WHERE RoutingElementTypeId = 'DF33399F-F148-450E-AC23-004634AAF41A'
GO
ALTER TABLE CustomQuestion_InputType
	ADD IsKeyValue bit NOT NULL default 0
GO
ALTER PROCEDURE [dbo].[spCustomQuestion_RegisterInput]
	@CustomQuestionTypeId uniqueidentifier,
	@InputId uniqueidentifier,
	@Description nvarchar(255),
	@ElementLimit int,
	@Required bit,
	@IsKeyValue bit
AS
	IF NOT EXISTS(SELECT * 
					FROM CustomQuestion_InputType 
					WHERE InputTypeId = @InputId AND @CustomQuestionTypeId = @CustomQuestionTypeId)
	BEGIN
		INSERT INTO CustomQuestion_InputType(InputTypeId, CustomQuestionTypeId, InputTypeDescription, ElementLimit, [Required], IsKeyValue)
		VALUES	(@InputId, @CustomQuestionTypeId, @Description, @ElementLimit, @Required, @IsKeyValue);
	END
GO


ALTER TABLE Intelledox_User
ADD IsAnonymousUser bit 
DEFAULT 0 NOT NULL;
GO

CREATE TABLE AnonymousUser(
UserGuid [uniqueidentifier] NOT NULL,
AccessCode [nvarchar](50) PRIMARY KEY CLUSTERED 
)
GO

ALTER procedure [dbo].[spUsers_updateUser]
	@UserID int,
	@Username nvarchar(256),
	@Password nvarchar(1000),
	@NewID int = 0 output,
	@WinNT_User bit,
	@BusinessUnitGUID uniqueidentifier,
	@User_GUID uniqueidentifier,
	@SelectedTheme nvarchar(100),
	@ChangePassword int,
	@PasswordSalt nvarchar(128),
	@PasswordFormat int,
	@Disabled int,
	@Address_Id int,
	@Timezone nvarchar(50),
	@Culture nvarchar(11),
	@Language nvarchar(11),
	@InvalidLogonAttempts int,
	@PasswordSetUtc datetime,
	@EulaAcceptedUtc datetime,
	@IsGuest bit,
	@TwoFactorSecret nvarchar(100),
	@IsAnonymousUser bit
as
	SET NOCOUNT ON

	DECLARE @IdTable TABLE (ID INT);

	if @UserID = 0 OR @UserID IS NULL
	begin
		INSERT INTO Intelledox_User(Username, PwdHash, WinNT_User, Business_Unit_GUID, User_Guid, SelectedTheme, 
				ChangePassword, PwdSalt, PwdFormat, [Disabled], Address_ID, Timezone, Culture, Language, IsGuest, 
				Invalid_Logon_Attempts, Password_Set_Utc, EulaAcceptanceUtc, TwoFactorSecret, IsAnonymousUser)
		OUTPUT Inserted.User_ID INTO @IdTable
		VALUES (@Username, @Password, @WinNT_User, @BusinessUnitGUID, @User_Guid, @SelectedTheme, 
				@ChangePassword, @PasswordSalt, @PasswordFormat, @Disabled, @Address_Id, @Timezone, @Culture, @Language, @IsGuest, 
				@InvalidLogonAttempts, @PasswordSetUtc, @EulaAcceptedUtc, @TwoFactorSecret, @IsAnonymousUser);
		
		SET @NewID = (SELECT ID FROM @IdTable);

		INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
		SELECT	@User_Guid, User_Group.Group_Guid, 0
		FROM	User_Group
		WHERE	User_Group.AutoAssignment = 1
				AND Business_Unit_Guid = @BusinessUnitGUID;
	end
	else
	begin
		UPDATE Intelledox_User
		SET Username = @Username,  
			PwdHash = @Password, 
			WinNT_User = @WinNT_User,
			SelectedTheme = @SelectedTheme,
			ChangePassword = @ChangePassword,
			PwdSalt = @PasswordSalt,
			PwdFormat = @PasswordFormat,
			[Disabled] = @Disabled,
			Timezone = @Timezone,
			Culture = @Culture,
			Language = @Language,
			Address_ID = @Address_Id,
			Invalid_Logon_Attempts = @InvalidLogonAttempts,
			Password_Set_Utc = @PasswordSetUtc,
			EulaAcceptanceUtc = @EulaAcceptedUtc,
			TwoFactorSecret = @TwoFactorSecret,
			IsAnonymousUser = @IsAnonymousUser
		WHERE [User_ID] = @UserID;
	end
GO

CREATE PROCEDURE [dbo].[spUser_GenerateAccessCode]
AS
BEGIN
	DECLARE @Length int;
	DECLARE @ValidCharacters char(100)
	DECLARE @ValidCharactersLength int;
	DECLARE @counter int;
	DECLARE @RandomString char(100)
	DECLARE @LoopCount int;
	DECLARE @RandomNumber float;
	DECLARE @RandomNumberInt int;
	DECLARE @CurrentCharacter char(1);
	DECLARE @code nvarchar(50);

	SET @Length = 6;

	SET @ValidCharacters ='BCDFGHJKLMNPQRSTVWXYZ123456789';
	SET @ValidCharactersLength = Len(@ValidCharacters);

	SET @counter = 0;
	SET @code = '';

	WHILE (@counter < @Length) BEGIN
		SET @RandomNumber = Rand();
        SET @RandomNumberInt = convert(tinyint, ((@ValidCharactersLength - 1) * @RandomNumber + 1));
        SELECT @CurrentCharacter = SUBSTRING(@ValidCharacters, @RandomNumberInt, 1);
        SET @counter = @counter + 1;
        SET @code = @code + @CurrentCharacter;
	END

	SELECT @code
END
GO

CREATE PROCEDURE [dbo].[spUser_InsertIntoAccessCode]
	@UserGuid uniqueidentifier,
	@AccessCode nvarchar(50)
AS
BEGIN
	INSERT INTO AnonymousUser (UserGuid, AccessCode)
	VALUES (@UserGuid, @AccessCode) 
END
GO

CREATE PROCEDURE [dbo].[spUser_GetUserFromAccessCode]
	@AccessCode nvarchar(50)
AS
BEGIN
	IF @AccessCode != ''
	BEGIN
	SELECT Intelledox_User.*, Address_Book.Email_Address FROM Intelledox_User
	INNER JOIN AnonymousUser on AnonymousUser.UserGuid = Intelledox_User.User_Guid
	INNER JOIN Address_Book on Intelledox_User.Address_Id = Address_Book.Address_id
	WHERE AnonymousUser.AccessCode = @AccessCode AND Intelledox_User.IsAnonymousUser = 1
	END
END
GO

CREATE PROCEDURE [dbo].[spWorkflow_WorkflowUserByTaskListStateGuid]
	@taskListStateGuid uniqueidentifier
AS
BEGIN
	SELECT	AssignedGuid
	FROM	ActionListState
	WHERE	ActionListStateId = @taskListStateGuid;
END
GO

ALTER procedure [dbo].[spUsers_RemoveUser]
	@UserGuid uniqueidentifier
AS
	SET NOCOUNT ON;

	DECLARE @UserId int;
	DECLARE @AddressId int;
	
	SELECT	@UserId = [User_Id], @AddressId = Address_ID
	FROM	Intelledox_User
	WHERE	User_Guid = @UserGuid;

	-- In case a restored user has been re-deleted, clear the history item
	DELETE Intelledox_UserDeleted WHERE UserGuid = @UserGuid;

	INSERT INTO Intelledox_UserDeleted(UserGuid, Username, BusinessUnitGuid, FirstName, LastName, Email, User_ID)
	SELECT Intelledox_User.User_Guid, Intelledox_User.Username, Intelledox_User.Business_Unit_GUID,
			Address_Book.First_Name, Address_Book.Last_Name, Address_Book.Email_Address, @UserId
	FROM Intelledox_User
		LEFT JOIN Address_Book ON Intelledox_User.Address_ID = Address_Book.Address_ID
	WHERE Intelledox_User.User_Guid = @UserGuid;
	
	DELETE Address_Book WHERE Address_ID = @AddressId;
	DELETE User_Address_Book WHERE [User_Id] = @UserId;
	DELETE User_Group_Subscription WHERE UserGuid = @UserGuid;
	DELETE User_Session WHERE User_Guid = @UserGuid;
	UPDATE Template SET LockedByUserGuid = null WHERE LockedByUserGuid = @UserGuid;
	DELETE Intelledox_User WHERE User_Guid = @UserGuid;
	DELETE AnonymousUser WHERE UserGuid = @UserGuid;

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
	DECLARE @AnonymousUsersCleanup DateTime;

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

	SET @AnonymousUsersCleanup = DATEADD(HOUR, -2, GetUtcDate());
										
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

	-- ==================================================
	-- Expired AnonymousUsers
	TRUNCATE TABLE #ExpiredItems;

  	INSERT #ExpiredItems (Id)
	SELECT DISTINCT(UserGuid)
	FROM AnonymousUser WITH (READUNCOMMITTED)
	INNER JOIN Intelledox_User ON AnonymousUser.UserGuid = Intelledox_User.User_Guid
	INNER JOIN Template_Log ON Intelledox_User.User_ID = Template_Log.User_ID
	WHERE Intelledox_User.IsAnonymousUser = 1 AND 
		Template_Log.ActionListStateId = '00000000-0000-0000-0000-000000000000' AND
		Template_Log.DateTime_Finish < @AnonymousUsersCleanup;

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
	
GO
