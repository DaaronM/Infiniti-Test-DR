truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.7.1.5');
go
ALTER PROCEDURE [dbo].[spProjectGroup_FolderListAll]
	@UserGuid uniqueidentifier,
	@FolderSearch nvarchar(50),
	@ProjectSearch nvarchar(100)
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid;

	SELECT	f.Folder_Name, f.Folder_Guid, tg.Template_Group_ID,
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
			AND f.Folder_Name COLLATE Latin1_General_CI_AI LIKE (@FolderSearch + '%') COLLATE Latin1_General_CI_AI
			AND t.Name COLLATE Latin1_General_CI_AI LIKE (@ProjectSearch + '%') COLLATE Latin1_General_CI_AI
			AND (tg.EnforcePublishPeriod = 0 
				OR ((tg.PublishStartDate IS NULL OR tg.PublishStartDate < getdate())
					AND (tg.PublishFinishDate IS NULL OR tg.PublishFinishDate > getdate())))
	ORDER BY f.Folder_Name, t.[Name]
GO










