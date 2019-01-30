/*
** Database Update package 5.1.1.5
*/

--set version
truncate table dbversion
go
insert into dbversion values ('5.1.1.5')
go

--1842
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vwStatsDailyLoginReport]'))
DROP VIEW [dbo].[vwStatsDailyLoginReport]
GO

CREATE view [dbo].[vwStatsDailyLoginReport]
as
select u.Username, ab.first_name as firstname, ab.last_name as lastname, ab.organisation_name, tblLog.GenDate as LoginDate, tblLog.Startcount, tblLog.Finishcount from (
	select logstart.User_Id, cast(floor(cast(logstart.DateTime_Start as float)) as datetime) as GenDate, count(logstart.log_guid) as StartCount, logfinish.FinishCount
	from template_log logStart
	left join (
		select User_Id, cast(floor(cast(DateTime_Finish as float)) as datetime) as FinishDate, count(log_guid) as FinishCount
		from template_log
		where datetime_finish is not null
		group by User_ID, cast(floor(cast(DateTime_Finish as float)) as datetime)
	) logFinish on logStart.user_id = logfinish.user_id and logfinish.Finishdate = cast(floor(cast(logstart.DateTime_Start as float)) as datetime)
	where logstart.DateTime_Start is not null
	group by logstart.User_ID, cast(floor(cast(logstart.DateTime_Start as float)) as datetime), logfinish.FinishCount
) tblLog
left join address_book ab on tblLog.User_id = ab.user_id
left join intelledox_user u on u.user_id = tblLog.user_id
GO

IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vwStatsDailyLoginReportSummary]'))
DROP VIEW [dbo].[vwStatsDailyLoginReportSummary]
GO

CREATE view [dbo].[vwStatsDailyLoginReportSummary]
as
select LoginDate, sum(StartCount) as StartTotal, sum(FinishCount) as FinishTotal
from (
select u.Username, ab.first_name as firstname, ab.last_name as lastname, ab.organisation_name, tblLog.GenDate as LoginDate, tblLog.Startcount, tblLog.Finishcount from (
	select logstart.User_Id, cast(floor(cast(logstart.DateTime_Start as float)) as datetime) as GenDate, count(logstart.log_guid) as StartCount, logfinish.FinishCount
	from template_log logStart
	left join (
		select User_Id, cast(floor(cast(DateTime_Finish as float)) as datetime) as FinishDate, count(log_guid) as FinishCount
		from template_log
		where datetime_finish is not null
		group by User_ID, cast(floor(cast(DateTime_Finish as float)) as datetime)
	) logFinish on logStart.user_id = logfinish.user_id and logfinish.Finishdate = cast(floor(cast(logstart.DateTime_Start as float)) as datetime)
	where logstart.DateTime_Start is not null
	group by logstart.User_ID, cast(floor(cast(logstart.DateTime_Start as float)) as datetime), logfinish.FinishCount
) tblLog
left join address_book ab on tblLog.User_id = ab.user_id
left join intelledox_user u on u.user_id = tblLog.user_id
) a
group by LoginDate
GO

