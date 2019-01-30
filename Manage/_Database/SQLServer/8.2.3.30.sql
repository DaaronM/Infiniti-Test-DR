/*
** Database Update package 8.2.3.30
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.3.30');
go

ALTER procedure [dbo].[spLog_CompleteProjectLog]
	@LogGuid uniqueidentifier,
	@MessageXml xml = null,
	@UpdateRecent bit = 0
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
	
	
	If @UpdateRecent = 1
	BEGIN
		--update recent completed log
		UPDATE	Template_Recent
		SET		Log_Guid = @LogGuid
		WHERE	User_Guid = @UserGuid 
				AND Template_Group_Guid = @TemplateGroupGuid;
	END
GO
