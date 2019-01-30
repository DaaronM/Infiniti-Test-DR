truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.4.0.2');
go
ALTER procedure [dbo].[spTemplateGrp_RemoveCategory]
	@CategoryID int,
	@ErrorCode int output
as
	DELETE category WHERE category_id = @CategoryID
	
	set @ErrorCode = @@error
GO
