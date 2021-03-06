truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.15');
GO

ALTER VIEW [dbo].[vwSubmissions]
AS

	SELECT	Template_Log.Log_Guid,
			Template.Template_Id,
			Template.Business_Unit_GUID,
			Template_Log.RunID AS _RunID,
			Template_Log.DateTime_Finish AS _Completion_Time_UTC,
			(SELECT Username FROM Intelledox_User WHERE User_ID = Template_Log.User_ID
				UNION
				SELECT Username FROM Intelledox_UserDeleted WHERE User_ID = Template_Log.User_ID)
			AS _Username,
			CASE WHEN Template_Log.CompletionState = 3 THEN 1 ELSE 0 END AS _Completed,
			CASE WHEN Template_Log.CompletionState = 2 THEN 1 ELSE 0 END AS _WorkflowInProgress,
			(SELECT TOP 1 LatestState.StateName
				FROM ActionListState LatestState
				WHERE LatestState.ActionListId = ActionListState.ActionListId
				ORDER BY LatestState.DateCreatedUtc DESC) AS _CurrentState
	FROM	Template_Log 
			INNER JOIN Template_Group ON Template_Group.Template_Group_Id = Template_Log.Template_Group_Id
			INNER JOIN Template ON Template.Template_Guid = Template_Group.Template_Guid
			LEFT JOIN ActionListState ON Template_Log.ActionListStateId = ActionListState.ActionListStateId
	WHERE Template_Log.CompletionState = 3
		OR (Template_Log.CompletionState = 2
			AND Template_Log.DateTime_Finish IN (SELECT MAX(tl.DateTime_Finish)
				FROM Template_Log tl
					INNER JOIN ActionListState als On tl.ActionListStateId = als.ActionListStateId
						AND als.ActionListId = ActionListState.ActionListId))
GO

ALTER PROCEDURE [dbo].[spContent_RemoveContentFolder]
	@FolderGuid uniqueidentifier
AS

    DECLARE @GuidId uniqueidentifier;
	--CONTENT ITEMS
	DECLARE @DeletedContentItem AS TABLE (ContentItem_Guid UNIQUEIDENTIFIER)
	BEGIN
	--Use a CTE Table to retrive the child folders (recursive)
	WITH ContentFolderCte (FolderGuid)
		AS
		( 
			SELECT @FolderGuid
			UNION ALL
			SELECT Content_Folder.FolderGuid
			FROM Content_Folder
				INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid
		)
		--Store the ID's of the content items to be deleted into a temp table vairable.
		INSERT INTO @DeletedContentItem
		SELECT ContentItem_Guid
		FROM Content_Item
		WHERE Content_Item.FolderGuid IN (SELECT FolderGuid FROM ContentFolderCte)

		IF ((SELECT COUNT(ContentItem_Guid) FROM  @DeletedContentItem) <> 0)
		  BEGIN
		    DECLARE ExpiredItemCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
			FOR SELECT ContentItem_Guid FROM @DeletedContentItem
		
			OPEN ExpiredItemCursor;
			FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;

			WHILE @@FETCH_STATUS = 0 
				BEGIN
					EXEC spContent_RemoveContentItem @GuidId
					FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;
				END

			CLOSE ExpiredItemCursor;
			DEALLOCATE ExpiredItemCursor;
		  END
	END

	--PROJECTS (Repeat above approach)
	DECLARE @DeletedProject AS TABLE (Template_Guid UNIQUEIDENTIFIER)
	BEGIN
	WITH ContentFolderCte (FolderGuid)
		AS
		( 
			SELECT @FolderGuid
			UNION ALL
			SELECT Content_Folder.FolderGuid
			FROM Content_Folder
				INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid
		)
		
		INSERT INTO @DeletedProject
		SELECT Template_Guid
		FROM Template
		WHERE Template.FolderGuid IN (SELECT FolderGuid FROM ContentFolderCte)

		IF ((SELECT COUNT(Template_Guid) FROM  @DeletedProject) <> 0)
		  BEGIN
		    DECLARE ExpiredItemCursor CURSOR LOCAL FORWARD_ONLY READ_ONLY
			FOR SELECT Template_Guid FROM @DeletedProject
		
			OPEN ExpiredItemCursor;
			FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;

			WHILE @@FETCH_STATUS = 0 
				BEGIN
					EXEC spTemplate_RemoveTemplate @GuidId, 0
					FETCH NEXT FROM ExpiredItemCursor INTO @GuidId;
				END

			CLOSE ExpiredItemCursor;
			DEALLOCATE ExpiredItemCursor;
		  END
	END

	--FOLDER GROUPS (Edit Permissions)
	BEGIN
	WITH ContentFolderCte (FolderGuid)
	AS
	( 
		SELECT @FolderGuid
		UNION ALL
		SELECT Content_Folder.FolderGuid
		FROM Content_Folder
			INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid
	)
	DELETE Content_Folder_Group
	FROM ContentFolderCte
	WHERE ContentFolderCte.FolderGuid = Content_Folder_Group.FolderGuid
	END

	--CONTENT FOLDERS
	BEGIN
	WITH ContentFolderCte (FolderGuid)
	AS
	( 
		SELECT @FolderGuid
		UNION ALL
		SELECT Content_Folder.FolderGuid
		FROM Content_Folder
			INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid
	)
	DELETE Content_Folder
	FROM ContentFolderCte
	WHERE ContentFolderCte.FolderGuid = Content_Folder.FolderGuid
	END
GO
