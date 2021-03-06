truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.2.3');
go

ALTER VIEW [dbo].[vwPageLog]
AS

SELECT      Template_PageLog.Log_Guid AS LogGuid, 
			Template_PageLog.RunId,
			Template_PageLog.PageTitle,
			Template_PageLog.PageGuid,
			Template.Name AS ProjectName,
			TimeonPage_Sec AS TimeonPageSec,
			Template_Log.DateTime_Start AS ProjectStartTimeUTC,
			Template_Log.DateTime_Finish AS ProjectFinishTimeUTC,
			CASE WHEN Template_Log.DateTime_Finish IS NULL THEN 0 ELSE 1 END AS Finished,
			SaveTimeUTC,
			(SELECT TOP 1 PageTitle
				FROM Template_PageLog CurrentPageLog
				WHERE CurrentPageLog.Log_Guid = Template_PageLog.Log_Guid
				ORDER BY CurrentPageLog.DateTimeUTC DESC) AS LastPage,
			Template.Business_Unit_Guid
FROM        Template_PageLog
		INNER JOIN Template_Log ON Template_PageLog.Log_Guid = Template_Log.Log_Guid
		INNER JOIN Template_Group ON Template_Group.Template_Group_ID = Template_Log.Template_Group_ID
		INNER JOIN Template ON Template.Template_Guid = Template_Group.Template_Guid
		LEFT JOIN (SELECT a.DateTimeUTC,
						a.Log_Guid,
						b.PageGuid AS bGuid,
						DATEDIFF(second, a.DateTimeUTC, b.DateTimeUTC) AS timeOnPage_Sec
					FROM (SELECT FirstLogRow.DateTimeUTC, 
								FirstLogRow.PageGuid,
								FirstLogRow.Log_Guid,
								ROW_NUMBER() OVER (ORDER BY FirstLogRow.Log_Guid, FirstLogRow.DateTimeUTC) AS rowNumber  
							FROM Template_PageLog FirstLogRow) A 
						INNER JOIN (SELECT SecondLogRow.DateTimeUTC, 
								SecondLogRow.PageGuid, 
								SecondLogRow.Log_Guid,
								ROW_NUMBER() OVER (ORDER BY SecondLogRow.Log_Guid, SecondLogRow.DateTimeUTC) AS rowNumber  
							FROM Template_PageLog SecondLogRow) B ON a.rowNumber = b.rowNumber - 1
					WHERE a.Log_Guid = b.Log_Guid) Results
				ON Results.DateTimeUTC = Template_PageLog.DateTimeUTC
					AND Results.Log_Guid = Template_PageLog.Log_Guid
				
GO
