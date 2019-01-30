/*
** Database Update package 8.2.3.12
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.3.12');
go



ALTER TABLE Template_Log
ADD ActionListStateId uniqueidentifier NOT NULL
CONSTRAINT ActionListStateIdDefault DEFAULT '00000000-0000-0000-0000-000000000000'
GO


ALTER procedure [dbo].[spLog_InsertTemplateLog]
	@LogGuid uniqueidentifier,
	@UserGuid uniqueidentifier,	
	@TemplateGroupGuid uniqueidentifier,
	@StartTime datetime,
	@AnswerFileUsed bit,
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
	INSERT INTO Template_Log WITH (ROWLOCK) (Log_Guid, [User_ID], Template_Group_ID, DateTime_Start, Completed, Answer_File_Used, InProgress, Answer_File, ActionListStateId)
	VALUES (@LogGuid, @UserID, @TemplateGroupID, @StartTime, 0, @AnswerFileUsed, 1, @AnswerFile, @ActionListStateId);

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


ALTER PROCEDURE [dbo].[spLog_UpdateTemplateLog]
	@LogGuid uniqueidentifier,
	@LastGroupGuid uniqueidentifier,
	@AnswerFile xml,
	@ActionListStateId uniqueidentifier = '00000000-0000-0000-0000-000000000000'
AS
	UPDATE	Template_Log WITH (ROWLOCK, UPDLOCK)
	SET		Answer_File = @AnswerFile,
			Last_Bookmark_Group_Guid = @LastGroupGuid,
			ActionListStateId = @ActionListStateId
	WHERE	Log_Guid = @LogGuid;

GO
ALTER PROCEDURE [dbo].[spDocument_InsertDocument]
	@DocumentId uniqueidentifier,
	@Extension nvarchar(10),
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier,
	@DisplayName nvarchar(255),
	@DateCreated datetime,
	@DocumentBinary varbinary(max),
	@DocumentLength int,
	@ProjectDocumentGuid uniqueidentifier,
	@ActionOnly bit
as
	INSERT INTO Document(DocumentId, 
		Extension, 
		JobId, 
		UserGuid, 
		DisplayName, 
		DateCreated, 
		DocumentBinary, 
		DocumentLength,
		ProjectDocumentGuid,
		Downloadable,
		ActionOnly)
	VALUES (@DocumentId, 
		@Extension, 
		@JobId, 
		@UserGuid, 
		@DisplayName, 
		@DateCreated, 
		@DocumentBinary, 
		@DocumentLength,
		@ProjectDocumentGuid,
		CASE WHEN @ActionOnly = 1 THEN 0 ELSE 1 END,
		@ActionOnly);
		
	-- Update less recent documents to be no longer "downloadable"
	-- First get the setting
	DECLARE @DownloadableDocNum int;
	SET @DownloadableDocNum = (SELECT OptionValue 
		FROM Global_Options 
		WHERE OptionCode = 'DOWNLOADABLE_DOC_NUM');
				
	-- Then update any documents that aren't ones we're supposed to keep
	UPDATE	Document
	SET		Downloadable = 0
	WHERE	UserGuid = @UserGuid
		AND Downloadable = 1
		AND JobId NOT IN
			(
				SELECT TOP(@DownloadableDocNum) JobId
				FROM Document
				WHERE UserGuid = @UserGuid
				GROUP BY JobId, DateCreated
				ORDER BY DateCreated DESC
			);
GO
