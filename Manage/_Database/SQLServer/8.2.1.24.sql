/*
** Database Update package 8.2.1.24
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.1.24');
go
ALTER procedure [dbo].[spLog_CompleteProjectLog]
	@LogGuid uniqueidentifier,
	@MessageXml xml = null
AS
	DECLARE @FinishDate datetime;
	
	SET @FinishDate = GetUtcDate();
	
	UPDATE	Template_Log 
	SET		DateTime_Finish = @FinishDate, 
			Completed = 1,
			Messages = @MessageXml,
			InProgress = 0
	WHERE	Log_Guid = @LogGuid;
GO
