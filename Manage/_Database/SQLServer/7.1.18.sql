/*
** Database Update package 7.1.18
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.1.18')
go

--1990
ALTER PROCEDURE [dbo].[spJob_Queued]
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus,
			ProcessJob.LogGuid, ProcessJob.JobDefinitionGuid
	FROM	ProcessJob
	WHERE	ProcessJob.CurrentStatus = 1
	ORDER BY ProcessJob.DateStarted;
GO


