truncate table dbversion;
GO
insert into dbversion(dbversion) values ('10.1.7');
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
	WHERE  (Template_Log.Answer_File IS NOT NULL AND CAST(Template_Log.Answer_File as varchar(max)) != '') AND 
			(Template_Log.CompletionState = 3
			 OR (Template_Log.CompletionState = 2
				 AND Template_Log.DateTime_Finish IN (SELECT MAX(tl.DateTime_Finish)
					 FROM Template_Log tl
						  INNER JOIN ActionListState als On tl.ActionListStateId = als.ActionListStateId
						AND als.ActionListId = ActionListState.ActionListId)))
GO
