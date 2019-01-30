truncate table dbversion;
GO
insert into dbversion(dbversion) values ('10.2.11');
GO

ALTER procedure [dbo].[spReport_UsageDataTimeTaken] (
	@StartDate datetime,
	@FinishDate datetime,
	@BusinessUnitGuid uniqueidentifier
)
AS
	SELECT TOP 10 Template.Name AS TemplateName,
		AVG(CASE WHEN Totals.SumTime IS NULL 
			THEN DateDiff(second, Template_Log.DateTime_Start, Template_Log.DateTime_Finish)
			ELSE Totals.SumTime END) AS AvgTimeTaken
	FROM Template_Log 
		INNER JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
		INNER JOIN Template ON Template.Template_Guid = Template_Group.Template_Guid
		INNER JOIN Intelledox_User ON Intelledox_User.User_ID = Template_Log.User_ID
		LEFT JOIN ActionListState ON Template_Log.ActionListStateId = ActionListState.ActionListStateId
		LEFT JOIN (SELECT WorkflowTotalState.ActionListId, 
						SUM(CAST(DateDiff(second, WorkflowLog.DateTime_Start, WorkflowLog.DateTime_Finish) AS BIGINT)) as SumTime
					FROM ActionListState WorkflowTotalState
						INNER JOIN Template_Log WorkflowLog ON WorkflowTotalState.ActionListStateId = WorkflowLog.ActionListStateId
					WHERE WorkflowLog.DateTime_Finish IS NOT NULL
					GROUP BY WorkflowTotalState.ActionListId) as Totals ON ActionListState.ActionListId = Totals.ActionListId
    WHERE Template_Log.DateTime_Finish >= @StartDate
        AND Template_Log.DateTime_Finish <= @FinishDate + 1
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
		AND Template_Log.CompletionState = 3
    GROUP BY Template.Template_Guid,
		Template.Name
	ORDER BY AVG(CASE WHEN Totals.SumTime IS NULL 
			THEN DateDiff(second, Template_Log.DateTime_Start, Template_Log.DateTime_Finish)
			ELSE Totals.SumTime END) DESC;
GO
