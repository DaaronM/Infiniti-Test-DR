/*
** Database Update package 8.0.0.16
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.0.0.16');
go

--2044
ALTER PROCEDURE [dbo].[spJob_QueueList]
	@StartDate DateTime,
	@FinishDate DateTime,
	@CurrentStatus Int
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus,
			Template.Name as ProjectName, Intelledox_User.Username, 
			ProcessJob.LogGuid,
			CASE WHEN template_Log.Messages IS NOT NULL THEN 1 ELSE 0 END AS HasMessages
	FROM	ProcessJob
			INNER JOIN Intelledox_User ON ProcessJob.UserGuid = Intelledox_User.User_Guid
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template_Group_Item ON Template_Group.Template_Group_Guid = Template_Group_Item.Template_Group_Guid
			INNER JOIN Template ON Template_Group_Item.Template_Guid = Template.Template_Guid
			LEFT JOIN Template_Log ON ProcessJob.LogGuid = Template_Log.Log_Guid
	WHERE	ProcessJob.DateStarted BETWEEN @StartDate AND @FinishDate
			AND ((@CurrentStatus = 0) OR 
				(@CurrentStatus = -1 AND ProcessJob.CurrentStatus <> 7) OR 
				(@CurrentStatus <> -1 AND ProcessJob.CurrentStatus = @CurrentStatus))
	ORDER BY ProcessJob.DateStarted DESC;
GO


