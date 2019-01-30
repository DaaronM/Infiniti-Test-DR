truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.5.0.12');
go

CREATE PROCEDURE [dbo].[spLog_HasTaskCompleted]
	@ActionListStateId uniqueidentifier

AS

BEGIN

	IF EXISTS(
				SELECT	1
				FROM	Template_Log
				WHERE	ActionListStateId = @ActionListStateId 
						AND Completed = 1
				) 
	BEGIN
		SELECT 1;
	END
	ELSE	
	BEGIN
		SELECT 0;
	END
	
END
GO









