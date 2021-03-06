truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.43');
GO

ALTER TABLE [dbo].[Intelledox_User] 
ADD CONSTRAINT UC_UserGuid UNIQUE (User_Guid)
GO
ALTER procedure [spLog_InsertTemplateLog]
	@LogGuid uniqueidentifier,
	@UserGuid uniqueidentifier,	
	@TemplateGroupGuid uniqueidentifier,
	@StartTime datetime,
	@AnswerFile xml,
	@RunID uniqueidentifier,
	@UpdateRecent bit = 0,
	@ActionListStateId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
	@LoginTimeUtc datetime = NULL,
	@Latitude decimal (9,6) = NULL,
	@Longitude decimal (9,6) = NULL,
	@CompletionState tinyint
AS
	DECLARE @UserId INT;
	DECLARE @TemplateGroupId INT;
	
	SET NOCOUNT ON;
	
	SET @UserId = (SELECT User_Id FROM Intelledox_User WITH (NOLOCK) WHERE User_Guid = @UserGuid);
	SET	@TemplateGroupId = (SELECT Template_Group_Id FROM Template_Group WITH (NOLOCK) WHERE Template_Group_Guid = @TemplateGroupGuid);
	
	IF @LogGuid IS NULL
		SET @LogGuid = newid();

	--Add to log
	INSERT INTO Template_Log WITH (ROWLOCK) (Log_Guid, [User_ID], Template_Group_ID, DateTime_Start, CompletionState, Answer_File, ActionListStateId, RunID, LoginTimeUtc, Latitude, Longitude)
	VALUES (@LogGuid, @UserID, @TemplateGroupID, @StartTime, @CompletionState, @AnswerFile, @ActionListStateId, @RunID, @LoginTimeUtc, @Latitude, @Longitude);

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
