/*
** Database Update package 7.1.6
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.1.6')
go

--1971
ALTER PROCEDURE [dbo].[spDocument_DocumentList] (
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier
)
AS
	SELECT	DocumentId, Extension, DisplayName
	FROM	Document
	WHERE	JobId = @JobId
			AND UserGuid = @UserGuid --Security check;
	ORDER BY DisplayName
GO


