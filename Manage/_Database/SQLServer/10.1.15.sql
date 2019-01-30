truncate table dbversion;
GO
insert into dbversion(dbversion) values ('10.1.15');
GO

ALTER VIEW [dbo].[vwInteractionLog_Save]
AS
SELECT il.Business_Unit_GUID, s.Log_Guid, s.LastSaveTimeUTC, il.Form, il.Page AS LastSavePage, s.SaveCount
FROM dbo.vwInteractionLog il JOIN
  (SELECT Log_Guid, COUNT(LOG_GUID) As SaveCount, MAX(FocusTimeUTC) AS LastSaveTimeUTC
   FROM dbo.Analytics_InteractionLog
   WHERE EventType = 'save'
   GROUP BY Log_Guid) s ON il.Log_Guid = s.Log_Guid AND il.FocusTimeUTC = s.LastSaveTimeUTC

GO
