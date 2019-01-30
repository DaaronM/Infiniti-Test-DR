/*
** Database Update package 8.2.0.5
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.0.5');
go

--2105
ALTER TABLE dbo.[Document] ADD
	ActionOnly bit NOT NULL CONSTRAINT DF_Document_ActionOnly DEFAULT 0;
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
	@ProjectDocumentGuid uniqueidentifier,
	@ActionOnly bit
as
	INSERT INTO Document(DocumentId, 
		Extension, 
		JobId, 
		UserGuid, 
		DisplayName, 
		DateCreated, 
		DocumentBinary, 
		DocumentLength,
		ProjectDocumentGuid,
		Downloadable,
		ActionOnly)
	VALUES (@DocumentId, 
		@Extension, 
		@JobId, 
		@UserGuid, 
		@DisplayName, 
		@DateCreated, 
		@DocumentBinary, 
		@DocumentLength,
		@ProjectDocumentGuid,
		CASE WHEN @ActionOnly = 1 THEN 0 ELSE 1 END,
		@ActionOnly);
		
	-- Update less recent documents to be no longer "downloadable"
	-- First get the setting
	DECLARE @DownloadableDocNum int;
	SET @DownloadableDocNum = (SELECT OptionValue 
		FROM Global_Options 
		WHERE OptionCode = 'DOWNLOADABLE_DOC_NUM');
		
	-- Then create a table and fill it with the documents we have to keep
	CREATE TABLE #DownloadableDocs (
		JobId uniqueidentifier,
		DateCreated datetime);
		
	SET ROWCOUNT @DownloadableDocNum;
	
	INSERT #DownloadableDocs (JobId, DateCreated)
	SELECT JobId, DateCreated
		FROM Document
		WHERE UserGuid = @UserGuid
		GROUP BY JobId, DateCreated
		ORDER BY DateCreated DESC;
		
	SET ROWCOUNT 0;
			
	-- Then update any documents that aren't ones we're supposed to keep
	UPDATE Document
	SET Downloadable = 0
	WHERE UserGuid = @UserGuid
		AND JobId NOT IN
			(
			SELECT JobId
			FROM #DownloadableDocs
			);
GO

ALTER PROCEDURE [dbo].[spDocument_DocumentList] (
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier
)
AS
	SELECT	Document.DocumentId, 
			Document.Extension,  
			Document.DisplayName,  
			Document.ProjectDocumentGuid,  
			Document.DateCreated,  
			Document.JobId,
			Document.ActionOnly,
			Template.Name As ProjectName
	FROM	Document
			INNER JOIN ProcessJob ON Document.JobId = ProcessJob.JobId
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
	WHERE	(Document.JobId = @JobId OR @JobId IS NULL)
			AND Document.UserGuid = @UserGuid; --Security check
GO

ALTER PROCEDURE [dbo].[spDocument_DocumentList] (
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier,
	@IncludeActionOnlyDocs bit
)
AS
	SELECT	Document.DocumentId, 
			Document.Extension,  
			Document.DisplayName,  
			Document.ProjectDocumentGuid,  
			Document.DateCreated,  
			Document.JobId,
			Document.ActionOnly,
			Template.Name As ProjectName
	FROM	Document
			INNER JOIN ProcessJob ON Document.JobId = ProcessJob.JobId
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
	WHERE	(Document.JobId = @JobId OR @JobId IS NULL)
			AND (@IncludeActionOnlyDocs = 1 OR Document.ActionOnly = 0)
			AND Document.UserGuid = @UserGuid; --Security check
GO


