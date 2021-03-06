truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.33');
go
INSERT INTO Global_Options (BusinessUnitGuid,OptionCode,OptionDescription,OptionValue)
SELECT bu.Business_Unit_GUID,'FORM_INTERACTION_LOG','Default for the Form Interaction Log publish option', 'True'
FROM Business_Unit bu
GO
UPDATE	Routing_Type
SET ModuleId = '1003'
WHERE ModuleId = 'Repo'
GO
UPDATE	Routing_Type
SET ModuleId = '6123'
WHERE ModuleId = 'Shar'
GO
UPDATE ConnectorSettings_Type
SET ModuleId = '6123'
WHERE ModuleId = 'Shar'
GO
CREATE VIEW vwDeviceLog
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
ALTER PROCEDURE [dbo].[spProjectGroup_FolderListSearch]
	@UserGuid uniqueidentifier,
	@SearchTerm nvarchar(50),
	@HomePageOnly bit
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid;

	SELECT	f.Folder_Name, tg.Template_Group_ID,
			tg.HelpText as TemplateGroup_HelpText, t.[Name] as Template_Name, 
			tg.Template_Group_Guid, tg.FeatureFlags
	FROM	Folder f
			INNER JOIN Template_Group tg on f.Folder_Guid = tg.Folder_Guid
			INNER JOIN Template t on tg.Template_Guid = t.Template_Guid
	WHERE	f.Business_Unit_GUID = @BusinessUnitGUID
			AND f.Folder_Guid IN (
				SELECT	Folder_Group.FolderGuid
				FROM	Folder_Group
						INNER JOIN User_Group_Subscription ON Folder_Group.GroupGuid = User_Group_Subscription.GroupGuid
				WHERE	User_Group_Subscription.UserGuid = @UserGuid
				)
			AND (f.Folder_Name COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchTerm + '%') COLLATE Latin1_General_CI_AI
			    OR t.Name COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchTerm + '%') COLLATE Latin1_General_CI_AI
				OR tg.HelpText COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchTerm + '%') COLLATE Latin1_General_CI_AI)
			AND (tg.EnforcePublishPeriod = 0 
				OR ((tg.PublishStartDate IS NULL OR tg.PublishStartDate < getdate())
					AND (tg.PublishFinishDate IS NULL OR tg.PublishFinishDate > getdate())))
			AND (@HomePageOnly = 0
				OR (@HomePageOnly = 1 AND tg.IsHomePage = 1))
	ORDER BY f.Folder_Name, t.[Name]

GO
