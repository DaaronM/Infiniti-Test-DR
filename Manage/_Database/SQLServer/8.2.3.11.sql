/*
** Database Update package 8.2.3.11
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.3.11');
go


ALTER procedure [dbo].[spLog_InsertTemplateLog]
	@LogGuid uniqueidentifier,
	@UserGuid uniqueidentifier,	
	@TemplateGroupGuid uniqueidentifier,
	@StartTime datetime,
	@AnswerFileUsed bit,
	@AnswerFile xml,
	@UpdateRecent bit = 0
AS
	DECLARE @UserId INT;
	DECLARE @TemplateGroupId INT;
	
	SET NOCOUNT ON;
	
	SET @UserId = (SELECT User_Id FROM Intelledox_User WITH (NOLOCK) WHERE User_Guid = @UserGuid);
	SET	@TemplateGroupId = (SELECT Template_Group_Id FROM Template_Group WITH (NOLOCK) WHERE Template_Group_Guid = @TemplateGroupGuid);
	
	IF @LogGuid IS NULL
		SET @LogGuid = newid();

	--Add to log
	INSERT INTO Template_Log WITH (ROWLOCK) (Log_Guid, [User_ID], Template_Group_ID, DateTime_Start, Completed, Answer_File_Used, InProgress, Answer_File)
	VALUES (@LogGuid, @UserID, @TemplateGroupID, @StartTime, 0, @AnswerFileUsed, 1, @AnswerFile);

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
	@MessageXml xml = null
AS
	DECLARE @FinishDate datetime;
	DECLARE @UserGuid uniqueidentifier;
	DECLARE @TemplateGroupGuid uniqueidentifier;
	
	SET NOCOUNT ON;

	SET @FinishDate = GetUtcDate();
	SET @UserGuid = (SELECT User_Guid 
						FROM Template_Log
						INNER JOIN Intelledox_User ON Template_Log.[User_ID] = Intelledox_User.[User_ID]
						WHERE Log_Guid = @LogGuid);
	SET	@TemplateGroupGuid = (SELECT Template_Group_Guid 
								FROM Template_Log
								INNER JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
								WHERE Log_Guid = @LogGuid);

	UPDATE	Template_Log 
	SET		DateTime_Finish = @FinishDate, 
			Completed = 1,
			Messages = @MessageXml,
			InProgress = 0
	WHERE	Log_Guid = @LogGuid;
	
	
	--update recent completed log
	UPDATE	Template_Recent
	SET		Log_Guid = @LogGuid
	WHERE	User_Guid = @UserGuid 
			AND Template_Group_Guid = @TemplateGroupGuid;
GO



