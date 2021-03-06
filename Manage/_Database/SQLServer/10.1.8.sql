truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.1.8');
GO
DELETE FROM LoggedOutSessions WHERE AuthCookieValue LIKE 'chunks:%'
GO

IF EXISTS(SELECT * FROM sys.procedures 
          WHERE Name = 'spLog_TemplateLogListByRunId')
BEGIN
	SET NOEXEC ON;
END
GO

CREATE procedure [dbo].[spLog_TemplateLogListByRunId]
	@RunId varchar(50) = '',
	@ErrorCode int output
as
	SELECT	Template_Log.Log_Guid, Template_Log.Answer_File, Template_Log.EncryptedAnswerFile, 
	Template_Log.Last_Bookmark_Group_Guid, Template_Log.ActionListStateId
	FROM	Template_Log
	WHERE	Template_Log.RunID = @RunId
	
	set @ErrorCode = @@error;

GO
	
DROP procedure [dbo].[spLog_TemplateLogListByTaskListId];
GO

SET NOEXEC OFF
GO
ALTER PROCEDURE [dbo].[spProject_UnlockProject]
	@ProjectGuid uniqueidentifier,
	@VersionComment nvarchar(max) = '',
	@UserGuid uniqueidentifier,
	@ForceUnlock bit
AS
	BEGIN TRAN
		--Allows unlock either by any user if its a force unlock OR by the same user who has currently locked the project if general unlock
		IF @ForceUnlock = 1 OR (@ForceUnlock = 0 AND EXISTS(SELECT LockedByUserGuid FROM Template WHERE Template_Guid = @ProjectGuid AND LockedByUserGuid = @UserGuid))
		BEGIN
			DECLARE @FinalComment AS NVARCHAR(MAX) = ISNULL((SELECT Comment FROM Template WHERE Template_Guid = @ProjectGuid),'')
			
			IF LEN(@FinalComment) = 0
			BEGIN
				SET @FinalComment = @VersionComment
			END
			ELSE IF LEN(@VersionComment) > 0
			BEGIN
				SET @FinalComment = @VersionComment + CHAR(13) + @FinalComment
			END

			UPDATE	Template
			SET		LockedByUserGuid = NULL,
					Comment = @FinalComment,
					IsMajorVersion = 1
			WHERE	Template_Guid = @ProjectGuid;
		END
	COMMIT
GO
