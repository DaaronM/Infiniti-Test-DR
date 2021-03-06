truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.1.9');
go

ALTER TABLE [dbo].[Business_Unit]
	ADD [Tracker] [int] NOT NULL DEFAULT ((0))
GO

CREATE PROCEDURE [dbo].[spTenant_IncrementTracker]
	@BusinessUnitGuid uniqueidentifier
	
AS

	UPDATE	Business_Unit
	SET		Tracker = Tracker + 1
	WHERE	Business_Unit_GUID = @BusinessUnitGuid;
GO

CREATE VIEW [dbo].[vwSubmissions]
AS

	SELECT	Template_Log.Log_Guid,
			Template.Template_Id,
			Template_Log.DateTime_Finish AS _Completion_Time_UTC,
			Intelledox_User.Username AS _Username,
			CASE WHEN Template_Log.CompletionState = 3 THEN 1 ELSE 0 END AS _Completed,
			CASE WHEN Template_Log.CompletionState = 2 THEN 1 ELSE 0 END AS _WorkflowInProgress
	FROM	Template_Log 
			INNER JOIN Template_Group ON Template_Group.Template_Group_Id = Template_Log.Template_Group_Id
			INNER JOIN Template ON Template.Template_Guid = Template_Group.Template_Guid
			LEFT JOIN Intelledox_User ON Intelledox_User.User_ID = Template_Log.User_Id
	WHERE Template_Log.CompletionState = 3
		OR (Template_Log.CompletionState = 2
			AND Template_Log.DateTime_Finish IN (SELECT MAX(tl.DateTime_Finish)
				FROM Template_Log tl
					INNER JOIN ActionListState On tl.ActionListStateId = ActionListState.ActionListStateId
				GROUP BY ActionListState.ActionListId))
GO

DROP PROCEDURE [dbo].[spDataSource_ProjectAnswers]
GO
INSERT INTO Global_Options (BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
SELECT bu.Business_Unit_GUID, 'GOOGLE_ANALYTICS', 'Defines the Tracking Code used by Google Analytics', ''
FROM Business_Unit bu
GO

ALTER TABLE dbo.[Document] ADD
	RepeatIndices nvarchar(255) NULL
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
	@ActionOnly bit,
	@RepeatIndices nvarchar(255)
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
		ActionOnly,
		RepeatIndices)
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
		@ActionOnly,
		@RepeatIndices);

GO

ALTER PROCEDURE [dbo].[spDocument_DocumentList] (
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier,
	@IncludeActionOnlyDocs bit
)
AS
	IF (@JobId IS NULL)
	BEGIN
		SELECT	TOP 500
				Document.DocumentId, 
				Document.Extension,  
				Document.DisplayName,  
				Document.ProjectDocumentGuid,  
				Document.DateCreated,  
				Document.JobId,
				Document.ActionOnly,
				Document.RepeatIndices,
				Template.Name As ProjectName
		FROM	Document WITH (NOLOCK)
				INNER JOIN ProcessJob ON Document.JobId = ProcessJob.JobId
				INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
				INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
		WHERE	(@IncludeActionOnlyDocs = 1 OR Document.ActionOnly = 0)
				AND Document.UserGuid = @UserGuid;
	END
	ELSE
	BEGIN
		SELECT	Document.DocumentId, 
				Document.Extension,  
				Document.DisplayName,  
				Document.ProjectDocumentGuid,  
				Document.DateCreated,  
				Document.JobId,
				Document.ActionOnly,
				Document.RepeatIndices,
				Template.Name As ProjectName
		FROM	Document
				INNER JOIN ProcessJob ON Document.JobId = ProcessJob.JobId
				INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
				INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
		WHERE	Document.JobId = @JobId
				AND (@IncludeActionOnlyDocs = 1 OR Document.ActionOnly = 0)
				AND Document.UserGuid = @UserGuid --Security check
				ORDER BY Document.DisplayName;
	END
GO
