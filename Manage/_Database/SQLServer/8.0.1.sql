/*
** Database Update package 8.0.1
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.0.1');
go

--2046
ALTER TABLE dbo.[Document] ADD
	ProjectDocumentGuid uniqueidentifier NULL;
GO

ALTER PROCEDURE [dbo].[spDocument_DocumentList] (
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier
)
AS
	SELECT	DocumentId, Extension, DisplayName, ProjectDocumentGuid
	FROM	Document
	WHERE	JobId = @JobId
			AND UserGuid = @UserGuid --Security check;
GO

ALTER PROCEDURE [dbo].[spDocument_InsertDocument]
	@DocumentId uniqueidentifier,
	@Extension nvarchar(10),
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier,
	@DisplayName nvarchar(255),
	@DateCreated datetime,
	@DocumentBinary varbinary(max),
	@DocumentLength int,
	@ProjectDocumentGuid uniqueidentifier
as
	INSERT INTO Document(DocumentId, 
		Extension, 
		JobId, 
		UserGuid, 
		DisplayName, 
		DateCreated, 
		DocumentBinary, 
		DocumentLength,
		ProjectDocumentGuid)
	VALUES (@DocumentId, 
		@Extension, 
		@JobId, 
		@UserGuid, 
		@DisplayName, 
		@DateCreated, 
		@DocumentBinary, 
		@DocumentLength,
		@ProjectDocumentGuid);
GO

