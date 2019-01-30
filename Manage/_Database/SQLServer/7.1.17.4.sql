/*
** Database Update package 7.1.17.4
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.1.17.4')
go

--1985
ALTER PROCEDURE [dbo].[spDataSource_RemoveDataKey]
	@FieldName nvarchar(500),
	@DataObjectGuid nvarchar(40)
AS
	DELETE	data_object_key 
	WHERE	Data_Object_Guid = @DataObjectGuid
			and field_name = @FieldName;
GO


--1986
ALTER PROCEDURE [dbo].[spJob_DueList]
AS
	SELECT	* 
	FROM	JobDefinition
	WHERE	NextRunDate <= GETUTCDATE()
	ORDER BY NextRunDate, DateCreated, Name;
GO

