/*
** Database Update package 6.0.1
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.0.1')
go

--1856
ALTER PROCEDURE [dbo].[spDocument_UpdateDocument]
	@DocumentId uniqueidentifier,
	@Extension nvarchar(10),
	@UserGuid uniqueidentifier,
	@DocumentBinary varbinary(max),
	@DocumentLength int
as
	UPDATE	Document
	SET		DocumentBinary = @DocumentBinary,
			DocumentLength = @DocumentLength
	WHERE	DocumentId = @DocumentId
			AND UserGuid = @UserGuid
			AND Extension = @Extension;
GO

