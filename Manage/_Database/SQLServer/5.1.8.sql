/*
** Database Update package 5.1.8
*/

--set version
truncate table dbversion
go
insert into dbversion values ('5.1.8')
go

--1853
ALTER TABLE dbo.Template_Log
	ADD InProgress bit NULL;
GO
UPDATE	Template_Log
SET		InProgress = 0
WHERE	InProgress IS NULL;
GO
ALTER procedure [dbo].[spLog_TemplateLogList]
	@LogGuid varchar(50) = '',
	@PackageRunId int = 0,
	@ErrorCode int output
as
	IF @PackageRunId <> 0
		SELECT	Template_Log.*, Template_Group.Template_Group_Guid, Intelledox_User.User_Guid
		FROM	Template_Log
				INNER JOIN Template_Group ON Template_Log.Template_Group_Id = Template_Group.Template_Group_Id
				INNER JOIN Intelledox_User ON Template_Log.User_Id = Intelledox_User.User_Id
		WHERE	Template_Log.Package_Run_Id = @PackageRunId;
	ELSE
		SELECT	Template_Log.*, Template_Group.Template_Group_Guid, Intelledox_User.User_Guid
		FROM	Template_Log
				INNER JOIN Template_Group ON Template_Log.Template_Group_Id = Template_Group.Template_Group_Id
				INNER JOIN Intelledox_User ON Template_Log.User_Id = Intelledox_User.User_Id
		WHERE	Template_Log.Log_Guid = @LogGuid;
	
	set @ErrorCode = @@error
GO
ALTER PROCEDURE [dbo].[spLog_InsertTemplateLog]
	@LogGuid uniqueidentifier,
	@UserGuid uniqueidentifier,	
	@TemplateGroupGuid uniqueidentifier,
	@StartTime datetime,
	@AnswerFileUsed bit,
	@PackageRunId int,
	@AnswerFile xml
AS
	DECLARE @UserId INT;
	DECLARE @TemplateGroupId INT;
	
	SET @UserId = (SELECT User_Id FROM Intelledox_User WHERE User_Guid = @UserGuid);
	SET	@TemplateGroupId = (SELECT Template_Group_Id FROM Template_Group WHERE Template_Group_Guid = @TemplateGroupGuid);
	
	IF @LogGuid IS NULL
		SET @LogGuid = newid();

	INSERT INTO Template_Log(Log_Guid, [User_ID], Template_Group_ID, DateTime_Start, Completed, Answer_File_Used, Package_Run_Id, InProgress, Answer_File)
	VALUES (@LogGuid, @UserID, @TemplateGroupID, @StartTime, 0, @AnswerFileUsed, @PackageRunId, 1, @AnswerFile);
GO
ALTER PROCEDURE [dbo].[spLog_UpdateTemplateLog]
	@LogGuid uniqueidentifier,
	@LastGroupGuid uniqueidentifier,
	@AnswerFile xml
AS
	UPDATE	Template_Log 
	SET		Answer_File = @AnswerFile,
			Last_Bookmark_Group_Guid = @LastGroupGuid
	WHERE	Log_Guid = @LogGuid;
GO
CREATE PROCEDURE [dbo].[spLog_CompleteTemplateLog]
	@LogGuid uniqueidentifier,
	@PackageRunId Int
AS
	DECLARE @FinishDate datetime;
	
	SET @FinishDate = GetDate();
	
	If @PackageRunId <> 0
	BEGIN
		DECLARE @TemplateGroupID Int;
		DECLARE @UserID Int;

		SELECT TOP 1 @TemplateGroupID = Template_Group_ID,
				@UserID = [User_ID]
		FROM	Template_Log
		WHERE	Log_Guid = @LogGuid;

		IF EXISTS(SELECT * FROM Template_Log 
					WHERE	Template_Group_ID = @TemplateGroupID
							AND Package_Run_Id = @PackageRunId
							AND [User_ID] = @UserID
							AND Log_Guid <> @LogGuid)
		BEGIN
			UPDATE	Template_Log 
			SET		Package_Run_Id = NULL
			WHERE	Template_Group_ID = @TemplateGroupID
					AND Package_Run_Id = @PackageRunId
					AND [User_ID] = @UserID
					AND Log_Guid <> @LogGuid;
		END
	END

	UPDATE	Template_Log 
	SET		DateTime_Finish = @FinishDate, 
			Completed = 1,
			Package_Run_Id = @PackageRunId,
			InProgress = 0
	WHERE	Log_Guid = @LogGuid;
GO
CREATE PROCEDURE dbo.spLog_LastUnfinished
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
				AND InProgress = 1
				AND Answer_File IS NOT NULL)
		AND User_Id = @UserId;
GO
CREATE PROCEDURE dbo.spLog_ClearUnfinished
	@UserGuid uniqueidentifier
AS
	DECLARE @UserId INT;
	
	SET NOCOUNT ON;
	
	SET @UserId = (SELECT User_Id FROM Intelledox_User WHERE User_Guid = @UserGuid);
	
	UPDATE	Template_Log
	SET		InProgress = 0
	WHERE	User_Id = @UserId;
GO

--1854
ALTER TABLE User_Session
	Add Log_Guid uniqueidentifier null;
GO
DELETE FROM User_Session
WHERE Modified_Date < DateAdd(d, -1, GetDate());
GO
CREATE procedure [dbo].[spSession_RemoveUserSession]
	@SessionGuid uniqueidentifier
AS
	DELETE FROM	User_Session
	WHERE Session_Guid = @SessionGuid
GO
ALTER procedure [dbo].[spSession_UpdateUserSession]
	@SessionGuid uniqueidentifier,
	@UserGuid uniqueidentifier,
	@ModifiedDate datetime,
	@AnswerFileID int,
	@LogGuid uniqueidentifier
as
	IF EXISTS(SELECT * FROM User_Session WHERE Session_Guid = @SessionGuid)
		UPDATE	User_Session
		SET		AnswerFile_ID = @AnswerFileID,
				Log_Guid = @LogGuid
		WHERE	Session_Guid = @SessionGuid;
	ELSE
		INSERT INTO User_Session (Session_Guid, User_Guid, Modified_Date, AnswerFile_ID, Log_Guid)
		VALUES (@SessionGuid, @UserGuid, @ModifiedDate, @AnswerFileID, @LogGuid);
GO

