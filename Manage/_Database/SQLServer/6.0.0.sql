/*
** Database Update package 6.0.0
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.0.0')
go

--1855
CREATE PROCEDURE [dbo].[spDocument_UpdateDocument]
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
