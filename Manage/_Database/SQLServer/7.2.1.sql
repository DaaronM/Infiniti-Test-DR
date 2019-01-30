/*
** Database Update package 7.2.1
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.2.1')
go

--1982
CREATE PROCEDURE [dbo].[spJob_DeleteRecurrencePattern] (
	@JobDefinitionId uniqueidentifier)
AS
	DELETE FROM RecurrencePattern 
	WHERE JobDefinitionId = @JobDefinitionId;
GO


--1983
ALTER PROCEDURE [dbo].[spJob_UpdateJobDefinition](
	@JobDefinitionId uniqueidentifier,
	@Name nvarchar(200),
	@IsEnabled bit,
	@OwnerGuid uniqueidentifier,
	@DateModified datetime,
	@JobDefinition xml,
	@WatchFolder nvarchar(300),
	@DataSourceGuid uniqueidentifier,
	@DeleteAfterDays int
)
AS
	UPDATE	JobDefinition
	SET		Name = @Name, 
			IsEnabled = @IsEnabled, 
			OwnerGuid = @OwnerGuid, 
			DateModified = @DateModified, 
			JobDefinition = @JobDefinition,
			WatchFolder = @WatchFolder,
			DataSourceGuid = @DataSourceGuid,
			DeleteAfterDays = @DeleteAfterDays
	WHERE	JobDefinitionId = @JobDefinitionId;
GO


