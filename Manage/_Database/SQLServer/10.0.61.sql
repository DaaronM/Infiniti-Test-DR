truncate table dbversion;
GO
insert into dbversion(dbversion) values ('10.0.61');
GO

IF EXISTS(SELECT * FROM sys.procedures WHERE Name = 'spLibrary_GetCustomFieldBinary')
BEGIN
	DROP PROCEDURE spLibrary_GetCustomFieldBinary;
END
GO
CREATE PROCEDURE [dbo].[spLibrary_GetCustomFieldBinary] (
	@UserGuid as uniqueidentifier,
	@DataGuid as uniqueidentifier
)
AS
	DECLARE @DataGuidString NVARCHAR(36)

	SET @DataGuidString = CAST(@DataGuid as NVARCHAR(36));

	IF EXISTS(
		-- Profile
		SELECT	Intelledox_User.User_Guid
		FROM	Intelledox_User
				INNER JOIN Address_Book_Custom_Field ON Intelledox_User.Address_ID = Address_Book_Custom_Field.Address_ID
		WHERE	Intelledox_User.User_Guid = @UserGuid
				AND Address_Book_Custom_Field.Custom_Value = @DataGuidString) OR
		EXISTS(
		-- Contact
		SELECT	Intelledox_User.User_Guid
		FROM	Intelledox_User
				INNER JOIN User_Address_Book ON Intelledox_User.User_ID = User_Address_Book.User_ID
				INNER JOIN Address_Book_Custom_Field ON User_Address_Book.Address_ID = Address_Book_Custom_Field.Address_ID
		WHERE	Intelledox_User.User_Guid = @UserGuid
				AND Address_Book_Custom_Field.Custom_Value = @DataGuidString)
	BEGIN
		SELECT	cd.ContentData as [Binary]
		FROM	ContentData_Binary cd
		WHERE	ContentData_Guid = @DataGuid;
	END
GO

ALTER SCHEMA dbo
	TRANSFER TemporaryUser
GO

DROP VIEW vwUserAssignedAnswers;
GO
CREATE VIEW [dbo].vwUserAssignedAnswers
AS
SELECT ans.AnswerFile_Id AS AnswerFileId, ans.User_Guid AS UserGuid, template.Business_Unit_Guid, ans.Template_Group_Guid AS ProjectGroupGuid, ans.Description,   
    ans.RunDate, ans.InProgress, ans.AnswerFile_Guid AS AnswerFileGuid, ans.RunID,  
    Template.Name AS ProjectName,
    ans.FirstLaunchTimeUtc, Template_Group.MatchProjectVersion
FROM answer_file ans  
	JOIN Intelledox_User usr ON usr.User_Guid = ans.User_Guid
	INNER JOIN Template_Group ON ans.Template_Group_Guid = Template_Group.Template_Group_Guid  
	INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid 
	INNER JOIN Folder f ON  f.Folder_Guid = Template_Group.Folder_Guid   
WHERE Usr.IsGuest = 0 AND Ans.InProgress = 1 
AND (Template_Group.EnforcePublishPeriod = 0   
		OR ((Template_Group.PublishStartDate IS NULL OR Template_Group.PublishStartDate < getdate())  
			AND (Template_Group.PublishFinishDate IS NULL OR Template_Group.PublishFinishDate > getdate())))  
AND f.Folder_Guid IN (SELECT fg.FolderGuid 
	FROM folder_group fg 
	WHERE F.Folder_Guid = fg.FolderGuid  
		 AND fg.GroupGuid IN (SELECT b.group_guid
			FROM User_Group_Subscription c 
		    INNER JOIN user_group b ON c.groupguid = b.group_guid
			WHERE c.UserGuid = ans.User_Guid))  
 GO
 
DROP VIEW vwUserAvailableForms;
GO
CREATE VIEW [dbo].[vwUserAvailableForms]
AS

SELECT f.Folder_Name AS FolderName, 
f.Business_Unit_Guid, u.User_Guid AS UserGuid, 
   tg.HelpText as ProjectHelpText, t.[Name] as ProjectName,   
   tg.Template_Group_Guid AS ProjectGroupGuid, 
        CASE WHEN t.Template_Type_ID = 1 THEN 'Form'
             WHEN t.Template_Type_ID = 2 THEN 'Layout'
             WHEN t.Template_Type_ID = 4 THEN 'FragmentPage'
             WHEN t.Template_Type_ID = 5 THEN 'FragmentPortion'
             WHEN t.Template_Type_ID = 6 THEN 'Dashboard'
             ELSE CAST(t.Template_Type_ID AS varchar)
        END AS ProjectType, tg.FeatureFlags, 
   CASE WHEN Log_Guid IS NULL THEN cast(cast(0 as binary) as uniqueidentifier) ELSE l.Log_Guid END AS LogGuid, l.DateTime_Start AS DateTimeStart 
 FROM Folder f  
 LEFT JOIN ( SELECT DISTINCT Folder_Group.FolderGuid, Intelledox_User.User_Guid FROM Folder_Group  
      INNER JOIN User_Group ON Folder_Group.GroupGuid = User_Group.Group_Guid  
      INNER JOIN User_Group_Subscription ON User_Group.Group_Guid = User_Group_Subscription.GroupGuid  
      INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid  ) u
	   ON u.FolderGuid = f.Folder_Guid
   INNER JOIN Template_Group tg on f.folder_Guid = tg.Folder_Guid  
   INNER JOIN Template t on tg.Template_Guid =t.Template_Guid  
   LEFT JOIN Template_Recent l on tg.Template_Group_Guid = l.Template_Group_Guid  AND l.User_Guid = u.User_Guid
 WHERE (tg.EnforcePublishPeriod = 0   
    OR ((tg.PublishStartDate IS NULL OR tg.PublishStartDate < getdate())  
    AND (tg.PublishFinishDate IS NULL OR tg.PublishFinishDate > getdate())))

GO


DROP VIEW vwUserAnswerFiles;
GO
CREATE VIEW [dbo].vwUserAnswerFiles
AS  

SELECT ans.AnswerFile_Id AS AnswerFileId, ans.User_Guid AS UserGuid, ans.Description,   
    ans.RunDate, ans.InProgress, ans.AnswerFile_Guid AS AnswerFileGuid, ans.RunID,  
    Template.Name AS ProjectName, Template_Group.Template_Group_Guid as ProjectGroupGuid,  
    ans.FirstLaunchTimeUtc, Template_Group.MatchProjectVersion, Template.Business_Unit_Guid
FROM answer_file ans
    INNER JOIN Template_Group ON ans.Template_Group_Guid = Template_Group.Template_Group_Guid  
    INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid  
	INNER JOIN Folder f ON f.Folder_Guid = Template_Group.Folder_Guid 
WHERE Ans.InProgress = 0   
AND (Template_Group.EnforcePublishPeriod = 0   
	OR ((Template_Group.PublishStartDate IS NULL OR Template_Group.PublishStartDate < getdate())  
		AND (Template_Group.PublishFinishDate IS NULL OR Template_Group.PublishFinishDate > getdate())))  
AND f.Folder_Guid IN (SELECT fg.FolderGuid 
	FROM folder_group fg 
	WHERE F.Folder_Guid = fg.FolderGuid  
		 AND fg.GroupGuid IN (SELECT b.group_guid
			FROM User_Group_Subscription c 
		    INNER JOIN user_group b ON c.groupguid = b.group_guid
			WHERE c.UserGuid = ans.User_Guid))  
    
GO


DROP VIEW vwUserDocuments;
GO
CREATE VIEW [dbo].vwUserDocuments
AS
	SELECT Document.DocumentId,   
		Document.Extension,    
		Document.DisplayName,    
		Document.ProjectDocumentGuid,    
		Document.DateCreated,    
		Document.JobId,  
		Document.ActionOnly,  
		Document.RepeatIndices,  
		Template.Name As ProjectName,
		Document.UserGuid,
		Template.Business_Unit_Guid
	FROM Document WITH (NOLOCK)  
		INNER JOIN ProcessJob ON Document.JobId = ProcessJob.JobId  
		INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid  
		INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid  
	WHERE Document.ActionOnly = 0  AND Document.DocumentLength <> -1
GO

DROP PROCEDURE spLicense_UpdateLicenseFile;
GO
CREATE PROCEDURE [dbo].[spLicense_UpdateLicenseFile]
	@BusinessUnitGuid uniqueidentifier, 
	@LicenseFile varbinary(MAX)
AS
BEGIN
	UPDATE Business_Unit
	SET EncryptedLicenseFile = @LicenseFile
	WHERE Business_Unit_GUID = @BusinessUnitGuid;
END
GO


DROP PROCEDURE spLicense_GetLicenseFile;
GO
CREATE PROCEDURE [dbo].[spLicense_GetLicenseFile]
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN

	SELECT EncryptedLicenseFile
	FROM Business_Unit
	WHERE Business_Unit_GUID = @BusinessUnitGuid;
END

GO


DROP VIEW vwInteractionLog;
GO
CREATE VIEW [dbo].vwInteractionLog
AS
SELECT T.Business_Unit_GUID, I.Log_Guid, T.Name As Form, I.PageTitle As Page, I.ControlID, I.EventType, I.FocusTimeUTC, I.BlurTimeUTC
FROM dbo.Analytics_InteractionLog I 
     JOIN dbo.Template_Log L ON  L.Log_Guid = I.Log_Guid
	 JOIN dbo.Template_Group G ON G.Template_Group_ID = l.Template_Group_ID
	 JOIN dbo.Template T ON G.Template_Guid = T.Template_Guid
GO


DROP VIEW vwInteractionLog_DropOff;
GO
CREATE VIEW [dbo].vwInteractionLog_DropOff
AS
SELECT DropOffPage.*, DropOffQuestion.Question, DropOffQuestion.QuestionFocusTimeUTC
FROM (SELECT il.Business_Unit_GUID, il.Log_Guid, il.Form, il.[Page], FocusTimeUTC AS PageFocusTimeUTC
      FROM dbo.vwInteractionLog il
	  JOIN (SELECT Log_Guid, MAX(FocusTimeUTC) AS LastPageInteractionTimeUTC
            FROM dbo.Analytics_InteractionLog
            WHERE Log_Guid NOT IN (SELECT Log_Guid FROM dbo.Analytics_InteractionLog WHERE ControlID = '(Submit)' OR ControlID = '(Save)' OR EventType = 'tileGoToProject' OR EventType = 'reassign')
                  AND EventType = 'pageOpen'
            GROUP BY Log_Guid) lp ON il.FocusTimeUTC = lp.LastPageInteractionTimeUTC AND il.Log_Guid = lp.Log_Guid) DropOffPage
      LEFT JOIN (SELECT  il.Log_Guid, il.ControlID As Question, FocusTimeUTC AS QuestionFocusTimeUTC
                 FROM dbo.Analytics_InteractionLog il 
				 JOIN (SELECT Log_Guid, MAX(FocusTimeUTC) AS LastQuestionInteractionTimeUtc
                       FROM dbo.Analytics_InteractionLog
                       WHERE EventType IS NULL
                       AND ControlID <> 'goToHome'
                       GROUP BY Log_Guid) lq 
				 ON il.FocusTimeUTC = lq.LastQuestionInteractionTimeUtc AND il.Log_Guid = lq.Log_Guid) DropOffQuestion 
      ON DropOffPage.Log_Guid = DropOffQuestion.Log_Guid AND DropOffQuestion.QuestionFocusTimeUTC > DropOffPage.PageFocusTimeUTC
GO

DROP VIEW vwInteractionLog_Save;
GO
CREATE VIEW [dbo].vwInteractionLog_Save
AS
SELECT il.Business_Unit_GUID, s.Log_Guid, s.LastSaveTimeUTC, il.Form, il.Page AS LastSavePage, s.SaveCount
FROM dbo.vwInteractionLog il JOIN
  (SELECT Log_Guid, COUNT(LOG_GUID) As SaveCount, MAX(FocusTimeUTC) AS LastSaveTimeUTC
   FROM dbo.Analytics_InteractionLog
   WHERE ControlID = '(Save)'
   GROUP BY Log_Guid) s ON il.Log_Guid = s.Log_Guid AND il.FocusTimeUTC = s.LastSaveTimeUTC
GO

DROP VIEW vwInteractionLog_Page;
GO
CREATE VIEW [dbo].vwInteractionLog_Page
AS
SELECT il.Business_Unit_GUID, il.Form, il.Page, il.FocusTimeUTC, p.SecondsOnPage
FROM vwInteractionLog il JOIN
      (SELECT a.FocusTimeUTC,
       a.Log_Guid,
	   DATEDIFF(second, a.FocusTimeUTC, b.FocusTimeUTC) AS secondsOnPage
	   FROM (SELECT FirstLogRow.FocusTimeUTC,
	                FirstLogRow.Log_Guid,
					ROW_NUMBER() OVER(ORDER BY FirstLogRow.Log_Guid, FirstLogRow.FocusTimeUTC) AS rowNumber
			 FROM Analytics_InteractionLog FirstLogRow
			 WHERE FirstLogRow.EventType = 'pageOpen' OR ControlID = '(Submit)' OR EventType = 'tileGoToProject' OR EventType = 'reassign') A
	   INNER JOIN (SELECT SecondLogRow.FocusTimeUTC,
	                SecondLogRow.Log_Guid,
					ROW_NUMBER() OVER(ORDER BY SecondLogRow.Log_Guid, SecondLogRow.FocusTimeUTC) AS rowNumber
			 FROM Analytics_InteractionLog SecondLogRow
			 WHERE SecondLogRow.EventType = 'pageOpen' OR ControlID = '(Submit)' OR EventType = 'tileGoToProject' OR EventType = 'reassign') B ON A.rowNumber = b.rowNumber - 1
			 WHERE a.Log_Guid = b.Log_Guid) p ON il.Log_Guid = p.Log_Guid AND il.FocusTimeUTC = p.FocusTimeUTC
GO

DROP VIEW vwInteractionLog_InteractionTime;
GO
CREATE VIEW [dbo].vwInteractionLog_InteractionTime
AS
SELECT il.Business_Unit_GUID, il.Log_Guid, il.Form, il.[Page], il.ControlID, il.EventType, il.FocusTimeUTC, q.InteractionSeconds
FROM vwInteractionLog il JOIN
      (SELECT a.FocusTimeUTC,
       a.Log_Guid,
	   DATEDIFF(second, a.FocusTimeUTC, b.FocusTimeUTC) AS InteractionSeconds
	   FROM (SELECT FirstLogRow.FocusTimeUTC,
	                FirstLogRow.Log_Guid,
					ROW_NUMBER() OVER(ORDER BY FirstLogRow.Log_Guid, FirstLogRow.FocusTimeUTC) AS rowNumber
			 FROM Analytics_InteractionLog FirstLogRow) A
	   INNER JOIN (SELECT SecondLogRow.FocusTimeUTC,
	                SecondLogRow.Log_Guid,
                    ROW_NUMBER() OVER(ORDER BY SecondLogRow.Log_Guid, SecondLogRow.FocusTimeUTC) AS rowNumber
			 FROM Analytics_InteractionLog SecondLogRow) B ON A.rowNumber = b.rowNumber - 1
			 WHERE a.Log_Guid = b.Log_Guid) Q ON  il.Log_Guid = q.Log_Guid AND il.FocusTimeUTC = q.FocusTimeUTC
GO

DROP VIEW vwDeviceLog;
GO
CREATE VIEW [dbo].vwDeviceLog
AS
       SELECT u.Business_Unit_GUID
	  ,[UserGuid]
	  ,u.[Username]
	  ,[IPAddress]
      ,[OS]
      ,[OSVersionMajor]
      ,[OSVersionMinor]
      ,[City]
      ,[Country]
      ,[CountryCode]
      ,[Region]
      ,[RegionCode]
      ,[PostalCode]
      ,[l].[TimeZone]
      ,[Browser]
      ,[BrowserVersionMajor]
      ,[BrowserVersionMinor]
      ,[Device]
      ,[Model]
      ,[Platform]
      ,[Latitude]
      ,[Longitude]
      ,[Languages]
      ,[LoginTimeUtc]
      ,[LocationAccuracy]
FROM dbo.Analytics_DeviceLog l JOIN dbo.Intelledox_User u ON l.UserGuid = u.User_Guid
GO

DROP VIEW vwInProgressFormsByUser
GO
DROP VIEW vwInProgressByUserGroups
GO
DROP VIEW vwFormActivityByUser
GO
DROP VIEW vwInProgressForms
GO

DROP PROCEDURE spUsers_GroupIdToGuid;
GO
CREATE PROCEDURE [dbo].spUsers_GroupIdToGuid  
 @id int  
AS  
 SELECT Group_Guid  
 FROM User_Group  
 WHERE User_Group_ID = @id
GO

DROP PROCEDURE spContent_ContentFolderProjectCount;
GO
CREATE PROCEDURE [dbo].spContent_ContentFolderProjectCount
@FolderGuid uniqueidentifier
AS
	WITH ContentFolderCte (FolderGuid)
		AS
		( 
			SELECT @FolderGuid
			UNION ALL
			SELECT Content_Folder.FolderGuid
			FROM Content_Folder
				INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid
		)
		
		SELECT COUNT(Template_Guid) AS [Count]
		FROM Template
		WHERE Template.FolderGuid IN (SELECT FolderGuid FROM ContentFolderCte)
GO

DROP PROCEDURE spContent_ContentFolderByName;
GO
CREATE PROCEDURE [dbo].spContent_ContentFolderByName
    @FolderName NVARCHAR(50),
	@BusinessUnitGuid uniqueidentifier
AS
	BEGIN
		SELECT	*
		FROM	Content_Folder
		WHERE	BusinessUnitGuid = @BusinessUnitGuid
		AND FolderName = @FolderName	
	END
GO

DROP PROCEDURE spStoredWizard_RemoveStoredWizard;
GO
CREATE proc [dbo].spStoredWizard_RemoveStoredWizard
	@JobGuid uniqueidentifier
AS
	DELETE FROM	StoredWizard
	WHERE	JobGuid = @JobGuid;
GO

DROP PROCEDURE spStoredWizard_StoredWizardList;
GO
CREATE proc [dbo].spStoredWizard_StoredWizardList
	@JobGuid uniqueidentifier
AS
	SELECT	Wizard
	FROM	StoredWizard
	WHERE	JobGuid = @JobGuid;
GO

DROP PROCEDURE spStoredWizard_UpdateStoredWizard;
GO
CREATE proc [dbo].spStoredWizard_UpdateStoredWizard
	@JobGuid uniqueidentifier,
	@Wizard varbinary(max)
AS
	INSERT INTO	StoredWizard(JobGuid, Wizard)
	VALUES (@JobGuid, @Wizard);
GO
