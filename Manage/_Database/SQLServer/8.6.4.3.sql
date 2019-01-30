truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.4.3');
go
ALTER procedure [dbo].[spJob_DueList]
	@FromDate DateTime
AS
	SELECT	* 
	FROM	JobDefinition
	WHERE	NextRunDate <= @FromDate
	ORDER BY NextRunDate, DateCreated, Name;
GO
