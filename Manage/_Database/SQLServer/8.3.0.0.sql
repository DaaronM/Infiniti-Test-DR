truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.3.0.0');
go
CREATE PROCEDURE dbo.spDataSource_ProjectGroupUsingDataObject
    @DataObjectGuid uniqueidentifier
AS
    SELECT	Template_Group.Template_Group_Guid
    FROM	Template
            CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question)') as ProjectXML(P)
            INNER JOIN Template_Group ON Template.Template_Guid = Template_Group.Template_Guid OR Template.Template_Guid = Template_Group.Layout_Guid
    WHERE	P.value('@DataObjectGuid', 'uniqueidentifier') = @DataObjectGuid;
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
-- Clean up orphaned rows from imports
SELECT	CAST(Custom_Value AS uniqueidentifier) as CustomGuid
INTO	#CustomFields
FROM	Address_Book_Custom_Field
		INNER JOIN Custom_Field ON Address_Book_Custom_Field.Custom_Field_ID = Custom_Field.Custom_Field_ID
WHERE	Validation_Type = 3	-- Image
		AND Len(Custom_Value) = 36	-- Guid length

DELETE FROM ContentData_Binary
WHERE	ContentData_Guid not in (
	SELECT	ContentData_Guid
	FROM	Content_Item
	UNION ALL
	SELECT CustomGuid
	FROM #CustomFields);

DELETE FROM ContentData_Binary_Version
WHERE	ContentData_Guid not in (
	SELECT	ContentData_Guid
	FROM	Content_Item
	UNION ALL
	SELECT CustomGuid
	FROM #CustomFields);

DELETE FROM ContentData_Text
WHERE	ContentData_Guid not in (
	SELECT	ContentData_Guid
	FROM	Content_Item);

DELETE FROM ContentData_Text_Version
WHERE	ContentData_Guid not in (
	SELECT	ContentData_Guid
	FROM	Content_Item);

DROP TABLE #CustomFields
GO
-- Remove duplicate custom field values
DELETE FROM	Address_Book_Custom_Field
WHERE Address_Book_Custom_Field.Address_Book_Custom_Field_ID NOT IN (
	SELECT	MIN(Address_Book_Custom_Field_ID)
	FROM	Address_Book_Custom_Field
	GROUP BY Address_ID, Custom_Field_ID, Custom_Value
)
GO
CREATE PROCEDURE [dbo].[spUsers_UserCountByProject]
	@ProjectGuid uniqueidentifier = null,
	@Anonymous bit,
	@ErrorCode int = 0 output
	
AS

BEGIN

	SELECT COUNT(Intelledox_User.User_Guid) 
	FROM Template_Group
	INNER JOIN Folder_Group ON Template_Group.Folder_Guid = Folder_Group.FolderGuid 
	INNER JOIN User_Group_Subscription ON Folder_Group.GroupGuid = User_Group_Subscription.GroupGuid
	INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
	WHERE Template_Guid = @ProjectGuid
	AND ((@Anonymous = 1 AND Intelledox_User.User_Guid = '99999999-9999-9999-9999-999999999999') 
		OR (@Anonymous = 0 AND Intelledox_User.User_Guid <> '99999999-9999-9999-9999-999999999999'))
	AND [Disabled] = 0;

	SET @ErrorCode = @@ERROR;
	
END
GO
CREATE PROCEDURE [dbo].[spUsers_UserCountByFolder]
	@FolderGuid uniqueidentifier = null,
	@Anonymous bit,
	@ErrorCode int = 0 output
	
AS

BEGIN

	SELECT COUNT(Intelledox_User.User_Guid) 
	FROM Folder_Group
	INNER JOIN User_Group_Subscription ON Folder_Group.GroupGuid = User_Group_Subscription.GroupGuid
	INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
	WHERE FolderGuid = @FolderGuid
	AND ((@Anonymous = 1 AND Intelledox_User.User_Guid = '99999999-9999-9999-9999-999999999999') 
		OR (@Anonymous = 0 AND Intelledox_User.User_Guid <> '99999999-9999-9999-9999-999999999999'))
	AND [Disabled] = 0;

	SET @ErrorCode = @@ERROR;
	
END
GO
CREATE PROCEDURE [dbo].[spUsers_UserCountByGroup]
	@GroupGuid uniqueidentifier = null,
	@Anonymous bit,
	@ErrorCode int = 0 output
	
AS

BEGIN

	SELECT COUNT(Intelledox_User.User_Guid)
	FROM User_Group_Subscription
	INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
	WHERE GroupGuid = @GroupGuid
	AND ((@Anonymous = 1 AND Intelledox_User.User_Guid = '99999999-9999-9999-9999-999999999999') 
		OR (@Anonymous = 0 AND Intelledox_User.User_Guid <> '99999999-9999-9999-9999-999999999999'))
	AND [Disabled] = 0;

	SET @ErrorCode = @@ERROR;
	
END
GO
CREATE procedure [dbo].[spProject_GetInUseProjectLicenseCount]
	@Anonymous bit,
	@ErrorCode int = 0 output
AS

BEGIN

	SELECT COUNT(DISTINCT Template_Guid) 
	FROM Template_Group
	INNER JOIN Folder_Group ON Template_Group.Folder_Guid = Folder_Group.FolderGuid 
	INNER JOIN User_Group_Subscription ON Folder_Group.GroupGuid = User_Group_Subscription.GroupGuid
	INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
	WHERE ((@Anonymous = 1 AND Intelledox_User.User_Guid = '99999999-9999-9999-9999-999999999999')
			OR (@Anonymous = 0 AND Intelledox_User.User_Guid <> '99999999-9999-9999-9999-999999999999'))
		AND [Disabled] = 0;

	SET @ErrorCode = @@ERROR;
	
END
GO
CREATE procedure [dbo].[spProject_GetProjectCount]
	@FolderGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@Anonymous bit,
	@ErrorCode int = 0 output
AS

	DECLARE @ProjectAllCount int,
			@ProjectCount int
	
BEGIN

	SELECT @ProjectAllCount = COUNT(DISTINCT Template_Guid)
	FROM Template_Group
	LEFT JOIN Folder_Group ON Template_Group.Folder_Guid = Folder_Group.FolderGuid 
	WHERE (Folder_Guid = @FolderGuid OR @FolderGuid IS NULL) 
		AND (GroupGuid = @GroupGuid OR @GroupGuid IS NULL);

	SELECT @ProjectCount = COUNT(DISTINCT Template_Guid)
	FROM Template_Group
	INNER JOIN Folder_Group ON Template_Group.Folder_Guid = Folder_Group.FolderGuid 
	INNER JOIN User_Group_Subscription ON Folder_Group.GroupGuid = User_Group_Subscription.GroupGuid
	INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
	WHERE Template_Guid IN 
		(SELECT Template_Guid 
			FROM Template_Group
			LEFT JOIN Folder_Group ON Template_Group.Folder_Guid = Folder_Group.FolderGuid 
			WHERE (Folder_Guid = @FolderGuid OR @FolderGuid IS NULL) 
				AND (GroupGuid = @GroupGuid OR @GroupGuid IS NULL)) 
	AND ((@Anonymous = 1 AND Intelledox_User.User_Guid = '99999999-9999-9999-9999-999999999999') 
		OR (@Anonymous = 0 AND Intelledox_User.User_Guid <> '99999999-9999-9999-9999-999999999999'))
	AND [Disabled] = 0;
		
	SELECT @ProjectAllCount - @ProjectCount;

	SET @ErrorCode = @@ERROR;
	
END
GO
update Routing_ElementType
set	ElementTypeDescription = 'Source Tray Name'
where RoutingElementTypeId = 'F1BBC234-17DF-4B39-83FA-B220A04F7183' 
	and ElementTypeDescription = 'Tray Name'

update ConnectorSettings_ElementType
set	DescriptionDefault = 'Default Source Tray Name'
where ConnectorSettingsElementTypeId = '8585D2B7-DE77-4448-94F5-85329488C058'
	and DescriptionDefault = 'Default Tray Name'
GO
ALTER VIEW [dbo].[vwProjectDetails]
AS
SELECT  t.Template_ID, t.Name, t.Template_Type_ID, t.Fax_Template_ID, t.content_bookmark, t.Template_Guid, t.Template_Version, t.Import_Date, t.HelpText, 
        t.Business_Unit_GUID, t.Supplier_Guid, t.Project_Definition, t.Modified_Date, t.Modified_By, t.Comment, t.LockedByUserGuid, t.FeatureFlags, 
        t.IsMajorVersion, tg.Template_Group_ID, t.Name AS GroupName, tg.Template_Group_Guid, tg.HelpText AS GroupHelpText, tg.AllowPreview, tg.PostGenerateText, 
        tg.UpdateDocumentFields, tg.EnforceValidation, tg.WizardFinishText, tg.EnforcePublishPeriod, tg.PublishStartDate, tg.PublishFinishDate, 
        tg.HideNavigationPane, tg.Template_Guid AS Expr3, tg.Template_Version AS Expr4, tg.Layout_Guid, tg.Layout_Version, tg.Folder_Guid
FROM    dbo.Template AS t INNER JOIN
        dbo.Template_Group AS tg ON tg.Template_Guid = t.Template_Guid
GO
ALTER VIEW [dbo].[vwTemplateGroup]
AS
SELECT     TOP 100 PERCENT tg.Template_Group_ID, t.Name AS TemplateGroup
FROM       Template AS t INNER JOIN
		   Template_Group AS tg ON tg.Template_Guid = t.Template_Guid
ORDER BY   T.Name
GO
ALTER PROCEDURE [dbo].[spAudit_AnswerFileList]
	@AnswerFile_ID int = 0,
	@AnswerFile_Guid uniqueidentifier = null,
	@User_Guid uniqueidentifier = null,
	@InProgress bit = 0,
	@TemplateGroupGuid uniqueidentifier = null,
	@ErrorCode int output
AS
	set nocount on
	
	IF (@AnswerFile_Guid IS NOT NULL)
	BEGIN
		SELECT	@AnswerFile_ID = AnswerFile_ID
		FROM	Answer_File
		WHERE	AnswerFile_Guid = @AnswerFile_Guid;
	END

	if @AnswerFile_ID = 0 or @AnswerFile_ID is null
    begin
		if @TemplateGroupGuid is null
			select	ans.AnswerFile_Id, ans.User_Guid, ans.Template_Group_Guid, ans.Description, 
					ans.RunDate, ans.InProgress, ans.AnswerFile_Guid,
					Template.Name as Template_Name, Template_Group.Template_Group_Guid
			from	answer_file ans
					inner join Template_Group on ans.Template_Group_Guid = Template_Group.Template_Group_Guid
					inner join Template on Template_Group.Template_Guid = Template.Template_Guid
			where	Ans.[User_Guid] = @user_Guid
					AND Ans.[InProgress] = @InProgress
					AND Ans.template_group_Guid in (

				-- Get a union of template group.
				SELECT DISTINCT tg.Template_Group_Guid
				FROM Folder f
					left join (
						SELECT tg.Template_Group_ID, tg.Folder_Guid, tg.Template_Group_Guid, tg.Template_Guid
						FROM template_group tg 
						WHERE (tg.EnforcePublishPeriod = 0 
								OR ((tg.PublishStartDate IS NULL OR tg.PublishStartDate < getdate())
									AND (tg.PublishFinishDate IS NULL OR tg.PublishFinishDate > getdate())))
					) tg on f.Folder_Guid = tg.Folder_Guid
					left join template t on tg.Template_Guid = t.Template_Guid
					inner join folder_group fg on F.Folder_Guid = fg.FolderGuid
				where 	(fg.GroupGuid in
							(select b.Group_Guid
							from intelledox_user a
							left join User_Group_Subscription c on a.User_Guid = c.UserGuid
							left join user_group b on c.groupguid = b.group_guid
							where c.UserGuid = @user_guid)
						)
			)
			order by [RunDate] desc;
		else
			select	ans.AnswerFile_Id, ans.User_Guid, ans.Template_Group_Guid, ans.Description, 
					ans.RunDate, ans.InProgress, ans.AnswerFile_Guid,
					T.Name as Template_Name
			from	answer_file ans					
					INNER JOIN Template_Group on ans.Template_Group_Guid = Template_Group.Template_Group_Guid
					INNER JOIN Template AS T ON Template_Group.Template_Guid = T.Template_Guid
			where	Ans.[user_Guid] = @user_Guid
					AND Ans.Template_group_Guid = @TemplateGroupGuid
			order by [RunDate] desc;
    end
    else
    begin
        SELECT	Answer_File.*
		FROM	Answer_File
        WHERE	Answer_File.AnswerFile_Id = @AnswerFile_Id
        ORDER BY Answer_File.[RunDate] desc;
    end

GO
ALTER PROCEDURE [dbo].[spProjectGroup_FolderListAll]
	@UserGuid uniqueidentifier,
	@FolderSearch nvarchar(50),
	@ProjectSearch nvarchar(100)
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid;
	
	SELECT	DISTINCT a.*, d.Template_Group_ID,
			d.HelpText as TemplateGroup_HelpText, b.Template_ID, b.[Name] as Template_Name, 
			b.Template_Type_ID, d.Template_Group_Guid
	FROM	Folder a
			INNER JOIN Template_Group d on a.folder_Guid = d.Folder_Guid
			INNER JOIN Template b on d.Template_Guid = b.Template_Guid
	WHERE	a.Business_Unit_GUID = @BusinessUnitGUID
			AND a.Folder_Guid IN (
				SELECT	Folder_Group.FolderGuid
				FROM	Folder_Group
						INNER JOIN User_Group ON Folder_Group.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Subscription ON User_Group.Group_Guid = User_Group_Subscription.GroupGuid
						INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
				WHERE	Intelledox_User.User_Guid = @UserGuid
				)
			AND a.Folder_Name LIKE @FolderSearch + '%'
			AND b.Name LIKE @ProjectSearch + '%'
			AND (d.EnforcePublishPeriod = 0 
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getdate())))
	ORDER BY a.Folder_Name, a.Folder_ID, b.Name;

GO
ALTER PROCEDURE [dbo].[spProjectGroup_Recent]
	@UserGuid uniqueidentifier,
	@ProjectSearch nvarchar(100)
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid;
	
	SELECT	DISTINCT d.Template_Group_ID, 
			d.HelpText as TemplateGroup_HelpText, b.Template_ID, b.[Name] as Template_Name, 
			b.Template_Type_ID, d.Template_Group_Guid, l.DateTime_Start, l.Log_Guid
	FROM	Folder a
			INNER JOIN Template_Group d on a.folder_Guid = d.Folder_Guid
			INNER JOIN Template b on d.Template_Guid = b.Template_Guid
			INNER JOIN Template_Recent l on d.Template_Group_Guid = l.Template_Group_Guid
	WHERE	a.Business_Unit_GUID = @BusinessUnitGUID
			AND a.Folder_Guid IN (
				SELECT	Folder_Group.FolderGuid
				FROM	Folder_Group
						INNER JOIN User_Group ON Folder_Group.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Subscription ON User_Group.Group_Guid = User_Group_Subscription.GroupGuid
						INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
				WHERE	Intelledox_User.User_Guid = @UserGuid
				)
			AND b.Name LIKE @ProjectSearch + '%'
			AND l.[User_Guid] = @UserGuid
			AND (d.EnforcePublishPeriod = 0 
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getdate())))
	ORDER BY l.DateTime_Start DESC;

GO
ALTER PROCEDURE [dbo].[spProjectGrp_UpdateProjectGroup]
	@ProjectGroupGuid uniqueidentifier,
	@HelpText nvarchar(4000),
	@AllowPreview bit,
	@WizardFinishText nvarchar(max),
	@PostGenerateText nvarchar(4000),
	@UpdateDocumentFields bit,
	@EnforceValidation bit,
	@HideNavigationPane bit,
	@EnforcePublishPeriod bit,
	@PublishStartDate datetime,
	@PublishFinishDate datetime,
	@ProjectGuid uniqueidentifier,
	@LayoutGuid uniqueidentifier,
	@ProjectVersion nvarchar(10),
	@LayoutVersion nvarchar(10),
	@FolderGuid uniqueidentifier
AS
	IF NOT EXISTS(SELECT * FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid)
	BEGIN
		INSERT INTO Template_Group (template_group_guid, helptext, AllowPreview, PostGenerateText, 
				UpdateDocumentFields, EnforceValidation, WizardFinishText, EnforcePublishPeriod,
				PublishStartDate, PublishFinishDate, HideNavigationPane, Template_Guid, Layout_Guid,
				Template_Version, Layout_Version, Folder_Guid)
		VALUES (@ProjectGroupGuid, @HelpText, @AllowPreview, @PostGenerateText, 
				@UpdateDocumentFields, @EnforceValidation, @WizardFinishText, @EnforcePublishPeriod,
				@PublishStartDate, @PublishFinishDate, @HideNavigationPane, @ProjectGuid, @LayoutGuid,
				@ProjectVersion, @LayoutVersion, @FolderGuid);
	END
	ELSE
	BEGIN
		UPDATE	Template_Group
		SET		HelpText = @HelpText,
				AllowPreview = @AllowPreview,
				PostGenerateText = @PostGenerateText,
				UpdateDocumentFields = @UpdateDocumentFields,
				EnforceValidation = @EnforceValidation,
				WizardFinishText = @WizardFinishText,
				EnforcePublishPeriod = @EnforcePublishPeriod,
				PublishStartDate = @PublishStartDate,
				PublishFinishDate = @PublishFinishDate,
				HideNavigationPane = @HideNavigationPane,
				Template_Guid = @ProjectGuid,
				Layout_Guid = @LayoutGuid,
				Template_Version = @ProjectVersion,
				Layout_Version = @LayoutVersion,
				Folder_Guid = @FolderGuid
		WHERE	Template_Group_Guid = @ProjectGroupGuid;
	END

GO
DROP PROCEDURE [dbo].[spTemplateGrp_FolderTemplateList]
GO
ALTER procedure [dbo].[spProjectGrp_ProjectGroupList]
      @ProjectGroupGuid uniqueidentifier
AS
    SELECT	a.Template_Group_ID, t.[Name] as Template_Name, a.template_group_guid, 
			a.helptext as TemplateGroup_HelpText, a.Template_Guid, a.Layout_Guid,
			a.Template_Version, a.Layout_Version, a.AllowPreview, a.PostGenerateText,
			a.UpdateDocumentFields, a.EnforceValidation, a.WizardFinishText, 
			a.EnforcePublishPeriod, a.PublishStartDate, a.PublishFinishDate,
			a.HideNavigationPane
    FROM	Template_Group a
			INNER JOIN Template t on a.Template_Guid = t.Template_Guid
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;
GO
ALTER procedure [dbo].[spProjectGrp_ProjectGroupListByFolder]
	@FolderGuid uniqueidentifier,
	@IncludeRestricted bit
AS
	SELECT	d.Template_Group_ID, b.Name as Template_Name, 
			d.HelpText as TemplateGroup_HelpText, d.Template_Group_Guid,
			b.Template_Guid, d.Layout_Guid
	FROM	Folder a
			INNER JOIN Template_Group d on a.folder_Guid = d.Folder_Guid
			INNER JOIN Template b on d.Template_Guid = b.Template_Guid
	WHERE	a.Folder_Guid = @FolderGuid
			AND ((d.EnforcePublishPeriod = 0 OR @IncludeRestricted = 1)
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getdate())))
	ORDER BY b.[Name], d.Template_Group_ID;
GO
ALTER TABLE Template_Group
DROP COLUMN Name
GO

ALTER PROCEDURE [dbo].[spLog_ClearUnfinished]
	@UserGuid uniqueidentifier
AS
	DECLARE @UserId INT;
	
	SET NOCOUNT ON;
	
	SET @UserId = (SELECT User_Id FROM Intelledox_User WHERE User_Guid = @UserGuid);
	
	UPDATE	Template_Log
	SET		InProgress = 0
	WHERE	User_Id = @UserId
		AND InProgress = 1;
GO
