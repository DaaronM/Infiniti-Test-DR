truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.5.3');
go
DROP INDEX IX_Intelledox_User_Username ON dbo.Intelledox_User
GO
ALTER TABLE [dbo].[Intelledox_User]
	ALTER COLUMN [Username] [nvarchar](256) NULL
GO
IF EXISTS(SELECT Username FROM	Intelledox_User GROUP BY Username HAVING COUNT(*) > 1)
BEGIN
	CREATE NONCLUSTERED INDEX IX_Intelledox_User_Username ON dbo.Intelledox_User
		(
		Username
		)
END
ELSE
BEGIN
	CREATE UNIQUE NONCLUSTERED INDEX IX_Intelledox_User_Username ON dbo.Intelledox_User
		(
		Username
		)
END
GO
DROP PROCEDURE spGetBilling;
GO
DROP VIEW vwStatsSummaryData;
GO
DROP VIEW vwStatsAllData;
GO
ALTER PROCEDURE [dbo].[spLog_HasTaskCompleted]
	@ActionListStateId uniqueidentifier
AS
BEGIN
	IF EXISTS(
				SELECT	1
				FROM	Template_Log
				WHERE	ActionListStateId = @ActionListStateId 
						AND (CompletionState = 3 OR CompletionState = 2)
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
