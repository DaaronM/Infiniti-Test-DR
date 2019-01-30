/*
** Database Update package 6.0.3
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.0.3')
go

--1864
ALTER PROCEDURE [dbo].[spReport_UsageDataMostRunTemplates] (
	@StartDate datetime,
	@FinishDate datetime,
	@BusinessUnitGuid uniqueidentifier
)
AS
	SELECT TOP 10 Template.Template_Guid,
		Template.Name AS TemplateName,
		COUNT(*) AS NumRuns
	FROM Template_Log 
		INNER JOIN Template_Group_Item ON Template_Log.Template_Group_ID = Template_Group_Item.Template_Group_ID
		INNER JOIN Template ON Template.Template_Guid = Template_Group_Item.Template_Guid
		INNER JOIN Intelledox_User ON Intelledox_User.User_ID = Template_Log.User_ID
    WHERE Template_Log.DateTime_Finish IS NOT NULL
		AND Template_Log.DateTime_Finish >= @StartDate
        AND Template_Log.DateTime_Finish <= @FinishDate + 1
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
    GROUP BY Template.Template_Guid,
		Template.Name
	ORDER BY NumRuns DESC;
GO

ALTER PROCEDURE [dbo].[spReport_UsageDataTimeTaken] (
	@StartDate datetime,
	@FinishDate datetime,
	@BusinessUnitGuid uniqueidentifier
)
AS
	SELECT TOP 10 Template.Name AS TemplateName,
		AVG(DateDiff(second, Template_Log.DateTime_Start, Template_Log.DateTime_Finish)) AS AvgTimeTaken
	FROM Template_Log 
		INNER JOIN Template_Group_Item ON Template_Log.Template_Group_ID = Template_Group_Item.Template_Group_ID
		INNER JOIN Template ON Template.Template_Guid = Template_Group_Item.Template_Guid
		INNER JOIN Intelledox_User ON Intelledox_User.User_ID = Template_Log.User_ID
    WHERE Template_Log.DateTime_Finish IS NOT NULL
		AND Template_Log.DateTime_Finish >= @StartDate
        AND Template_Log.DateTime_Finish <= @FinishDate + 1
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
    GROUP BY Template.Template_Guid,
		Template.Name
	ORDER BY AVG(DateDiff(second, Template_Log.DateTime_Start, Template_Log.DateTime_Finish)) DESC;

	GO

ALTER PROCEDURE [dbo].[spReport_UsageDataTopUsers] (
	@StartDate datetime,
	@FinishDate datetime,
	@BusinessUnitGuid uniqueidentifier
)
AS
	
	SELECT TOP 10 Intelledox_User.Username,
		COUNT(*) AS NumRuns
	FROM Template_Log 
		INNER JOIN Intelledox_User ON Intelledox_User.User_ID = Template_Log.User_ID
    WHERE Template_Log.DateTime_Finish IS NOT NULL
		AND Template_Log.DateTime_Finish >= @StartDate
        AND Template_Log.DateTime_Finish <= @FinishDate + 1
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
    GROUP BY Template_Log.User_ID,
		Intelledox_User.Username
	ORDER BY NumRuns DESC;

GO

--1865
ALTER TABLE dbo.Template_Group_Item ADD
	Template_Version int NULL,
	Layout_Version int NULL;
GO

CREATE VIEW [dbo].[vwTemplateVersion]
AS

		SELECT	Template_Version.Template_Version, 
			Template_Version.Template_Guid,
			Template_Version.Modified_Date,
			Template.Template_Type_ID,
			Intelledox_User.Username,
			CASE WHEN Template_Group_Item.Template_Group_Item_ID IS NULL
				THEN 0
				ELSE 1
			END AS InUse,
			0 AS Latest
		FROM	Template_Version
			INNER JOIN Template ON Template_Version.Template_Guid = Template.Template_Guid
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template_Version.Modified_By
			LEFT JOIN Template_Group_Item ON (Template_Group_Item.Template_Guid = Template_Version.Template_Guid
					AND Template_Group_Item.Template_Version = Template_Version.Template_Version)
				OR (Template_Group_Item.Layout_Guid = Template_Version.Template_Guid
					AND Template_Group_Item.Layout_Version = Template_Version.Template_Version)
	UNION ALL
		SELECT	Template.Template_Version, 
			Template.Template_Guid,
			Template.Modified_Date,
			Template.Template_Type_ID,
			Intelledox_User.Username,
			CASE WHEN Template_Group_Item.Template_Group_Item_ID IS NULL
				THEN 0
				ELSE 1
			END AS InUse,
			1 AS Latest
		FROM	Template
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By
			LEFT JOIN Template_Group_Item ON (Template_Group_Item.Template_Guid = Template.Template_Guid
					AND Template_Group_Item.Template_Version = Template.Template_Version)
				OR (Template_Group_Item.Layout_Guid = Template.Template_Guid
					AND Template_Group_Item.Layout_Version = Template.Template_Version)

GO

ALTER PROCEDURE [dbo].[spProjectGrp_SubscribeProjectGroup]
	@ProjectGroupGuid uniqueidentifier,
	@ProjectGuid uniqueidentifier,
	@LayoutGuid uniqueidentifier,
	@ProjectVersion int,
	@LayoutVersion int
AS
	DECLARE @SubscriptionCount int,
		@TemplateId int,
		@LayoutId int,
		@TemplateGroupId int
	
	SELECT	@SubscriptionCount = COUNT(*)
	FROM	Template_Group_Item
	WHERE	Template_Group_Guid = @ProjectGroupGuid
			AND Template_Guid = @ProjectGuid;
	
	IF @SubscriptionCount = 0
	BEGIN
		SELECT	@TemplateId = Template_Id FROM template WHERE template_guid = @ProjectGuid;
		SELECT	@LayoutId = Template_Id FROM template WHERE template_guid = @LayoutGuid;
		SELECT	@TemplateGroupId = Template_Group_Id FROM template_group WHERE template_Group_Guid = @ProjectGroupGuid;

		INSERT INTO Template_Group_Item (template_group_id, template_id, layout_id, template_Group_guid, template_guid, layout_guid, Template_Version, Layout_Version)
		VALUES (@TemplateGroupID, @TemplateID, @LayoutID, @ProjectGroupGuid, @ProjectGuid, @LayoutGuid, @ProjectVersion, @LayoutVersion);
	END
GO

ALTER PROCEDURE [dbo].[spProjectGrp_ProjectGroupList]
      @ProjectGroupGuid uniqueidentifier
as
    SELECT	a.Template_Group_ID, a.[Name] as Template_Group_Name, a.template_group_guid, 
			a.helptext as TemplateGroup_HelpText, b.template_guid, b.Layout_Guid,
			b.Template_Version, b.Layout_Version
    FROM	Template_Group a
			LEFT JOIN Template_Group_Item b on a.template_group_id = b.template_group_id
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;

GO

ALTER PROCEDURE [dbo].[spProject_DefinitionsByGroup] (
	@TemplateGroupGuid uniqueidentifier
)
AS
		SELECT	Template.Template_Guid, 
			Template.Project_Definition, 
			Template.Template_Type_ID
		FROM	Template_Group
				INNER JOIN Template_Group_Item ON Template_Group.Template_Group_Guid = Template_Group_Item.Template_Group_Guid
				INNER JOIN Template ON (Template_Group_Item.Template_Guid = Template.Template_Guid 
						AND (Template_Group_Item.Template_Version IS NULL
							OR Template_Group_Item.Template_Version = Template.Template_Version))
					OR (Template_Group_Item.Layout_Guid = Template.Template_Guid
						AND (Template_Group_Item.Layout_Version IS NULL
							OR Template_Group_Item.Layout_Version = Template.Template_Version))
		WHERE	Template_Group.Template_Group_Guid = @TemplateGroupGuid
	UNION ALL
		SELECT	Template_Version.Template_Guid, 
			Template_Version.Project_Definition, 
			Template.Template_Type_ID
		FROM	Template_Group
				INNER JOIN Template_Group_Item ON Template_Group.Template_Group_Guid = Template_Group_Item.Template_Group_Guid
				INNER JOIN Template ON Template_Group_Item.Template_Guid = Template.Template_Guid
				INNER JOIN Template_Version ON (Template_Group_Item.Template_Guid = Template_Version.Template_Guid 
						AND Template_Group_Item.Template_Version = Template_Version.Template_Version)
					OR (Template_Group_Item.Layout_Guid = Template_Version.Template_Guid
						AND Template_Group_Item.Layout_Version = Template_Version.Template_Version)
		WHERE	Template_Group.Template_Group_Guid = @TemplateGroupGuid
	ORDER BY Template_Type_ID;
GO

ALTER procedure [dbo].[spProject_GetProjectVersions]
	@ProjectGuid uniqueidentifier
as
		SELECT	vwTemplateVersion.Template_Version, 
			vwTemplateVersion.Modified_Date,
			vwTemplateVersion.Username,
			vwTemplateVersion.InUse
		FROM	vwTemplateVersion
		WHERE	vwTemplateVersion.Template_Guid = @ProjectGuid
	ORDER BY Template_Version DESC;
GO

ALTER PROCEDURE [dbo].[spProject_Binary] (
	@TemplateGuid uniqueidentifier,
	@VersionNumber int
)
AS
	If @VersionNumber = 0
	BEGIN
		SELECT	[Binary]  
		FROM	Template 
		WHERE	Template_Guid = @TemplateGuid;
	END
	ELSE
	BEGIN
		SELECT	[Binary]  
		FROM	Template 
		WHERE	Template_Guid = @TemplateGuid
			AND Template_Version = @VersionNumber
	UNION ALL
		SELECT	[Binary]  
		FROM	Template_Version
		WHERE	Template_Guid = @TemplateGuid
			AND Template_Version = @VersionNumber;
	END

GO

ALTER PROCEDURE [dbo].[spProject_Definition] (
	@TemplateGuid uniqueidentifier,
	@VersionNumber int
)
AS
	If @VersionNumber = 0
	BEGIN
		SELECT	Project_Definition 
		FROM	Template 
		WHERE	Template_Guid = @TemplateGuid;
	END
	ELSE
	BEGIN
		SELECT Project_Definition 
		FROM	Template 
		WHERE	Template_Guid = @TemplateGuid
			AND Template_Version = @VersionNumber
		UNION ALL
		SELECT	Project_Definition 
		FROM	Template_Version
		WHERE	Template_Guid = @TemplateGuid
			AND Template_Version = @VersionNumber;
	END

GO

ALTER procedure [dbo].[spProject_AddNewProjectVersion]
	@ProjectGuid uniqueidentifier
as
	BEGIN TRAN

		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Binary,
			Project_Definition)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,
			Template.Modified_By,
			Template.Binary,
			Template.Project_Definition
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
		
		IF (SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 9
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT MIN(Template_Version) 
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0)
				AND Template_Guid = @ProjectGuid;
		END
		
	COMMIT
GO

--1866
ALTER PROCEDURE [dbo].[spReport_UsageDataTopUsers] (
	@StartDate datetime,
	@FinishDate datetime,
	@BusinessUnitGuid uniqueidentifier
)
AS
	
	SELECT TOP 10 Intelledox_User.Username,
		COUNT(*) AS NumRuns,
		Address_Book.Full_Name
	FROM Template_Log 
		INNER JOIN Intelledox_User ON Intelledox_User.User_ID = Template_Log.User_ID
		LEFT JOIN Address_Book ON Address_Book.User_ID = Intelledox_User.User_ID
    WHERE Template_Log.DateTime_Finish IS NOT NULL
		AND Template_Log.DateTime_Finish >= @StartDate
        AND Template_Log.DateTime_Finish <= @FinishDate + 1
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
    GROUP BY Template_Log.User_ID,
		Intelledox_User.Username,
		Address_Book.Full_Name
	ORDER BY NumRuns DESC;
GO


--1867
CREATE procedure [dbo].[spProjectGrp_FolderList]
	@FolderGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier
AS
	IF @FolderGuid IS NULL
	BEGIN
		SELECT	*
		FROM	Folder
		WHERE	Business_Unit_Guid = @BusinessUnitGuid
		ORDER BY Folder_Name;
	END
	ELSE
	BEGIN
		SELECT	*
		FROM	Folder
		WHERE	Folder_Guid = @FolderGuid;
	END
GO
CREATE procedure [dbo].[spProjectGrp_RemoveFolder]
	@FolderGuid uniqueidentifier
AS
	DECLARE @FolderID INT
	
	SET NOCOUNT ON
	
	SELECT	@FolderID = Folder_Id
	FROM	Folder
	WHERE	Folder_Guid = @FolderGuid;
	
	DELETE Template_Group_Item
	WHERE Template_Group_Id IN (
		SELECT	Template_Group_Id
		FROM	Template_Group
		WHERE	Template_Group_Id IN (
			SELECT	FolderItem_Id
			FROM	Folder_Template
			WHERE	Folder_ID = @FolderID)
		);
		
	DELETE Template_Group 
	WHERE Template_Group_Id IN (
		SELECT	FolderItem_id
		FROM	Folder_Template
		WHERE	Folder_ID = @FolderID);
		
	DELETE Folder_Template WHERE Folder_ID = @FolderID;
	
	DELETE Folder WHERE Folder_ID = @FolderID;
GO
CREATE procedure [dbo].[spProjectGrp_UpdateFolder]
	@FolderGuid uniqueidentifier,
	@Name nvarchar(100),
	@BusinessUnitGUID uniqueidentifier
AS
	IF EXISTS(SELECT * FROM Folder WHERE Folder_Guid = @FolderGuid)
	BEGIN
		UPDATE	Folder
		SET		folder_name = @Name
		WHERE	Folder_Guid = @FolderGuid;
	END
	ELSE
	BEGIN
		INSERT INTO Folder(Folder_Name, Business_Unit_GUID, Folder_Guid)
		VALUES (@Name, @BusinessUnitGUID, @FolderGuid)
	END
GO
ALTER PROCEDURE [dbo].[spProjectGrp_RemoveProjectGroup]
	@ProjectGroupGuid uniqueidentifier
AS
	-- Remove the group records
	DELETE Package_Template WHERE Template_Group_Id IN (SELECT Template_Group_Id FROM Template_Group_Item WHERE Template_Group_Guid = @ProjectGroupGuid);
	DELETE Folder_Template WHERE ItemType_id = 1 AND FolderItem_ID IN (SELECT Template_Group_Id FROM Template_Group_Item WHERE Template_Group_Guid = @ProjectGroupGuid);
	DELETE Template_Group_Item WHERE Template_Group_Guid = @ProjectGroupGuid;
	DELETE Template_Group WHERE Template_Group_Guid = @ProjectGroupGuid;
GO
CREATE PROCEDURE dbo.spProjectGrp_Unpublish
	@ProjectGroupGuid uniqueidentifier,
	@FolderGuid uniqueidentifier
AS
	DELETE Folder_Template 
	WHERE ItemType_id = 1 
		AND FolderItem_ID IN (SELECT Template_Group_Id FROM Template_Group_Item WHERE Template_Group_Guid = @ProjectGroupGuid)
		AND Folder_Id IN (SELECT Folder_Id FROM Folder WHERE Folder_Guid = @FolderGuid);
GO
CREATE PROCEDURE [dbo].[spProjectGrp_Publish]
	@ProjectGroupGuid uniqueidentifier,
	@FolderGuid uniqueidentifier
as
	DECLARE @SubscriptionCount int
	DECLARE @TemplateGroupID int
	DECLARE @FolderId int
	
	SELECT	@TemplateGroupID = Template_Group_Id
	FROM	Template_Group
	WHERE	Template_Group_Guid = @ProjectGroupGuid;
	
	SELECT	@FolderId = Folder_Id
	FROM	Folder
	WHERE	Folder_Guid = @FolderGuid;
	
	SELECT	@SubscriptionCount = COUNT(*)
	FROM	Folder_Template
	WHERE	folderitem_ID = @TemplateGroupID
			AND Folder_ID = @FolderID
			AND itemtype_id = 1;
	
	IF @SubscriptionCount = 0
	begin
		INSERT INTO Folder_Template
		VALUES (@FolderID, @TemplateGroupID, 1);
	end
GO
CREATE procedure [dbo].[spProjectGrp_PublishPackage]
	@TemplatePackageId int,
	@FolderGuid uniqueidentifier
AS
	DECLARE @SubscriptionCount int
	DECLARE @FolderId Int
	
	SELECT	@SubscriptionCount = COUNT(*)
	FROM	Folder_Template
	WHERE	Folderitem_ID = @TemplatePackageId
		AND Folder_ID = @FolderId
		AND itemtype_id = 2;
		
	SELECT	@FolderId = Folder_Id
	FROM	Folder
	WHERE	Folder_Guid = @FolderGuid;
	
	IF @SubscriptionCount = 0
	BEGIN
		INSERT INTO Folder_Template
		VALUES (@FolderID, @TemplatePackageId, 2);
	END
GO
CREATE procedure [dbo].[spProjectGrp_UnpublishPackage]
	@TemplatePackageId int,
	@FolderGuid uniqueidentifier
AS
	DECLARE @FolderId Int
	
	SELECT	@FolderId = Folder_Id
	FROM	Folder
	WHERE	Folder_Guid = @FolderGuid;
	
	DELETE	Folder_Template
	WHERE	Folder_ID = @FolderID
		AND folderitem_ID = @TemplatePackageId
		AND itemtype_id = 2;
GO
CREATE procedure [dbo].[spProjectGrp_PackageListByFolder]
	@FolderGuid uniqueidentifier
AS
	DECLARE @FolderId Int
	
	SELECT	@FolderId = Folder_Id
	FROM	Folder
	WHERE	Folder_Guid = @FolderGuid;

	SELECT	p.*
	FROM	folder_template f
			INNER JOIN package p on f.folderitem_id = p.package_id and f.itemtype_id = 2
	WHERE	f.folder_id = @FolderId
			AND (p.IsArchived = '0' or p.IsArchived is null)
	ORDER BY p.Name;
GO
ALTER PROCEDURE [dbo].[spProjectGrp_ProjectGroupListByFolder]
	@FolderGuid uniqueidentifier
AS
	SELECT	d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, b.FormatTypeId, d.Template_Group_Guid,
			b.Template_Guid, e.Layout_Guid
	FROM	Folder a
			INNER JOIN Folder_Template c on a.Folder_ID = c.Folder_ID
			INNER JOIN Template_Group d on c.folderitem_ID = d.Template_Group_ID and itemtype_id = 1
			INNER JOIN Template_Group_Item e on d.Template_Group_ID = e.Template_Group_ID
			INNER JOIN Template b on e.Template_ID = b.Template_ID
	WHERE	a.Folder_Guid = @FolderGuid
	ORDER BY d.[Name], b.[Name], c.folderitem_id;
GO

