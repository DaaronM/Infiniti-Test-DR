/*
** Database Update package 6.0.2
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.0.2')
go

--1857
CREATE PROCEDURE [dbo].[spReport_UsageDataTopUsers] (
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
        AND Template_Log.DateTime_Finish <= @FinishDate
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
    GROUP BY Template_Log.User_ID,
		Intelledox_User.Username
	ORDER BY NumRuns DESC;

GO

CREATE PROCEDURE [dbo].[spReport_UsageDataTimeTaken] (
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
        AND Template_Log.DateTime_Finish <= @FinishDate
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
    GROUP BY Template.Template_Guid,
		Template.Name
	ORDER BY AVG(DateDiff(second, Template_Log.DateTime_Start, Template_Log.DateTime_Finish)) DESC;
	
GO

CREATE PROCEDURE [dbo].[spReport_UsageDataMostRunTemplates] (
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
        AND Template_Log.DateTime_Finish <= @FinishDate
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
    GROUP BY Template.Template_Guid,
		Template.Name
	ORDER BY NumRuns DESC;
GO

--1858
CREATE procedure [dbo].[spProject_GetProjectsByContentDefinition]
	@ContentGuid varchar(40),
	@BusinessUnitGuid uniqueidentifier
as
	SET ARITHABORT ON 
	
	SELECT 	Template.template_id, 
			Template.[name] as project_name, 
			Template.template_type_id, 
			Template.fax_template_id, 
			Template.layout_id, 
			Template.template_guid, 
			Template.template_version, 
			Template.import_date, 
			Template.FormatTypeId,
			Template.Business_Unit_GUID, 
			Template.Supplier_Guid
	FROM	Template
	WHERE	Template.Business_Unit_GUID = @BusinessUnitGuid
		AND Project_Definition.exist('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question/Answer/ContentDefinition[@Id = sql:variable("@ContentGuid")])[1]') = 1
	ORDER BY Template.[name];
		

GO

CREATE procedure [dbo].[spProject_GetProjectsByContentItem]
	@ContentGuid varchar(40),
	@BusinessUnitGuid uniqueidentifier
as
	SET ARITHABORT ON 
	
	SELECT 	Template.template_id, 
			Template.[name] as project_name, 
			Template.template_type_id, 
			Template.fax_template_id, 
			Template.layout_id, 
			Template.template_guid, 
			Template.template_version, 
			Template.import_date, 
			Template.FormatTypeId,
			Template.Business_Unit_GUID, 
			Template.Supplier_Guid
	FROM	Template
	WHERE	Template.Business_Unit_GUID = @BusinessUnitGuid
		AND Project_Definition.exist('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question/Answer/ContentItem[@Id = sql:variable("@ContentGuid")])[1]') = 1
	ORDER BY Template.[name];
		

GO

--1859
CREATE PROCEDURE [dbo].[spProject_GetFoldersByProject]
	@ProjectGuid uniqueidentifier
AS
	SELECT	Folder.Folder_Name
	FROM	Folder
			INNER JOIN Folder_Template ON Folder.Folder_ID = Folder_Template.Folder_ID
			INNER JOIN Template_Group ON Folder_Template.FolderItem_ID = Template_Group.Template_Group_ID
			INNER JOIN Template_Group_Item ON Template_Group.Template_Group_ID = Template_Group_Item.Template_Group_ID
			INNER JOIN Template ON Template_Group_Item.Template_ID = Template.Template_ID
	WHERE	Template.Template_Guid = @ProjectGuid
	ORDER BY Folder.Folder_Name;
		

GO

--1860
ALTER PROCEDURE [dbo].[spAudit_UpdateAnswerFile]
	@AnswerFile_ID int,
	@User_ID int,
	@Template_Group_ID int,
	@Description nvarchar(255),
	@RunDate datetime,
	@AnswerString xml,
	@InProgress char(1) = '0',
	@NewID int output,
	@ErrorCode int output
AS
	set nocount on

	if @AnswerFile_ID = 0 or @AnswerFile_ID is null
	begin
		insert into Answer_File ([User_ID], [Template_Group_ID], [Description], [RunDate], [AnswerString], [InProgress])
		values (@User_ID, @Template_Group_ID, @Description, @RunDate, @AnswerString, @InProgress)

		select @NewID = @@Identity
	end
	else
	begin
		update Answer_File
		set [Description] = @Description,
			RunDate = @RunDate,
			AnswerString = @AnswerString
		where AnswerFile_ID = @AnswerFile_ID
	end

	set @ErrorCode = @@Error
GO

--1861
ALTER TABLE dbo.Template ADD
	Modified_Date datetime NULL,
	Modified_By uniqueidentifier NULL;
GO

UPDATE Template 
SET Template_Version = '1';
GO

UPDATE Template
SET Modified_Date = 
		(SELECT MIN(DateTime_Start)
		FROM Template_Log
			INNER JOIN Template_Group_Item ON Template_Log.Template_Group_ID = Template_Group_Item.Template_Group_ID
		WHERE Template.Template_Guid = Template_Group_Item.Template_Guid)
WHERE	Template.Template_Type_Id = 1;
GO

UPDATE Template
SET Modified_Date = 
		(SELECT MIN(DateTime_Start)
		FROM Template_Log
			INNER JOIN Template_Group_Item ON Template_Log.Template_Group_ID = Template_Group_Item.Template_Group_ID
		WHERE Template.Template_Guid = Template_Group_Item.Layout_Guid)
WHERE	Template.Template_Type_Id = 2;
GO

ALTER TABLE dbo.Template
ALTER COLUMN Template_Version int NOT NULL
GO


CREATE TABLE dbo.Template_Version
	(
	Template_Version int NOT NULL,
	Template_Guid uniqueidentifier NOT NULL,
	Modified_Date datetime NULL,
	Modified_By uniqueidentifier NULL,
	Binary varbinary(MAX) NULL,
	Project_Definition xml NULL
	);
GO

ALTER TABLE dbo.Template_Version ADD CONSTRAINT
	PK_Template_Version PRIMARY KEY CLUSTERED 
	(
	Template_Guid,
	Template_Version
	
	);
GO

--1862
CREATE procedure [dbo].[spProject_AddNewProjectVersion]
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
					FROM Template_Version 
					WHERE Template_Guid = @ProjectGuid)
				AND Template_Guid = @ProjectGuid;
		END
		
	COMMIT
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

CREATE procedure [dbo].[spProject_GetProjectVersions]
	@ProjectGuid uniqueidentifier
as

		SELECT	Template_Version.Template_Version, 
			Template_Version.Modified_Date,
			Intelledox_User.Username
		FROM	Template_Version
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template_Version.Modified_By
		WHERE	Template_Version.Template_Guid = @ProjectGuid
	UNION
		SELECT	Template.Template_Version, 
			Template.Modified_Date,
			Intelledox_User.Username
		FROM	Template
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By
		WHERE	Template.Template_Guid = @ProjectGuid
	ORDER BY Template_Version DESC;		

GO

CREATE procedure [dbo].[spProject_RestoreVersion]
	@ProjectGuid uniqueidentifier,
	@VersionNumber int,
	@UserGuid uniqueidentifier
as
	SET NOCOUNT ON
		
	BEGIN TRAN	
	
		EXEC spProject_AddNewProjectVersion @ProjectGuid;
			
		UPDATE Template
		SET Binary = (SELECT Binary 
				FROM Template_Version 
				WHERE Template_Guid = @ProjectGuid 
					AND Template_Version = @VersionNumber), 
			Project_Definition = (SELECT Project_Definition
				FROM Template_Version 
				WHERE Template_Guid = @ProjectGuid 
					AND Template_Version = @VersionNumber), 
			Template_Version = Template_Version + 1, 
			Modified_Date = getUTCdate(),
			Modified_By = @UserGuid
		WHERE	Template_Guid = @ProjectGuid;
		
	COMMIT
GO

ALTER PROCEDURE [dbo].[spProject_UpdateDefinition] (
	@Xtf xml,
	@TemplateGuid uniqueidentifier,
	@UserGuid uniqueidentifier = NULL
)
AS
	BEGIN TRAN
		IF @UserGuid IS NOT NULL
		BEGIN
			EXEC spProject_AddNewProjectVersion @TemplateGuid;
		END
		
		UPDATE	Template 
		SET		Project_Definition = @XTF 
		WHERE	Template_Guid = @TemplateGuid;
		
		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE Template
			SET Template_Version = Template_Version + 1,
				Modified_By = @UserGuid,
				Modified_Date = getUTCdate()
			WHERE Template_Guid = @TemplateGuid;
		END
	COMMIT

GO

ALTER procedure [dbo].[spProject_UpdateProject]
	@BusinessUnitGuid uniqueidentifier,
	@FormatTypeId int,
	@Name nvarchar(100),
	@ProjectGuid uniqueidentifier,
	@ProjectTypeID int,
	@SupplierGuid uniqueidentifier,
	@ContentBookmark nvarchar(100),
	@UserGuid uniqueidentifier = NULL
as
	BEGIN TRAN

		IF NOT EXISTS(SELECT Template_Guid FROM Template WHERE Template_Guid = @ProjectGuid)
		BEGIN
			INSERT INTO Template(Business_Unit_Guid, FormatTypeId, Name, Template_Guid, 
				Template_Type_Id, Supplier_Guid, Content_Bookmark, Template_Version)
			VALUES (@BusinessUnitGuid, @FormatTypeId, @Name, @ProjectGuid, 
				@ProjectTypeId, @SupplierGuid, @ContentBookmark, 0);
		END
		ELSE
		BEGIN
		
			IF @UserGuid IS NOT NULL
			BEGIN
				EXEC spProject_AddNewProjectVersion @ProjectGuid;
			END
		
			UPDATE	Template
			SET		[name] = @Name, 
					Template_type_id = @ProjectTypeID, 
					FormatTypeId = @FormatTypeID, 
					Supplier_GUID = @SupplierGuid,
					Content_Bookmark = @ContentBookmark
			WHERE	Template_Guid = @ProjectGuid;
		END

		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE Template
			SET Modified_Date = getUTCdate(),
				Modified_By = @UserGuid,
				Template_Version = Template_Version + 1
			WHERE Template_Guid = @ProjectGuid;
		END
	
	COMMIT

GO

--1863
ALTER procedure [dbo].[spProject_ProjectList]
	@UserGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@SearchString nvarchar(100)
as
	declare @IsGlobal bit
	declare @BusinessUnitGUID uniqueidentifier

	SELECT	@BusinessUnitGUID = Business_Unit_GUID
	FROM	Intelledox_User
	WHERE	User_Guid = @UserGuid

	IF EXISTS(SELECT	vwUserPermissions.*
		FROM	vwUserPermissions
		WHERE	vwUserPermissions.CanDesignProjects = 1
				AND vwUserPermissions.GroupGuid IS NULL
				AND vwUserPermissions.UserGuid = @UserGuid)
	BEGIN
		SET @IsGlobal = 1
	END

	if @GroupGuid IS NULL
	begin
		--all usergroups
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.layout_id, a.template_guid, a.template_version, a.import_date, a.FormatTypeId,
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Content_Bookmark
		FROM	Template a
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		WHERE	(@IsGlobal = 1 or a.template_id in (
				SELECT	User_Group_Template.Template_ID
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.[User_ID] = User_Group_Subscription.[User_ID] 
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.User_Group_Id = User_Group_Template.User_Group_Id 
				WHERE	vwUserPermissions.CanDesignProjects = 1
			AND Intelledox_User.User_Guid = @UserGuid
				))
			AND (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
		ORDER BY a.[name]
	end
	else
	begin
		--specific user group
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.layout_id, a.template_guid, a.template_version, a.import_date, a.FormatTypeId,
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Content_Bookmark
		FROM	Template a
				INNER JOIN User_Group_Template d on a.Template_ID = d.Template_ID
				INNER JOIN User_Group ON d.User_Group_ID = User_Group.User_Group_ID  AND User_Group.Group_Guid = @GroupGuid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		WHERE	(@IsGlobal = 1 or a.template_id in (
				SELECT	User_Group_Template.Template_ID
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.[User_ID] = User_Group_Subscription.[User_ID] 
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.User_Group_Id = User_Group_Template.User_Group_Id 
				WHERE	vwUserPermissions.CanDesignProjects = 1
			))
			and (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
		ORDER BY a.[name]
	end

GO

ALTER procedure [dbo].[spProject_GetProjectsByContentItem]
	@ContentGuid varchar(40),
	@BusinessUnitGuid uniqueidentifier
as
	SELECT 	Template.template_id, 
			Template.[name] as project_name, 
			Template.template_type_id, 
			Template.fax_template_id, 
			Template.layout_id, 
			Template.template_guid, 
			Template.template_version, 
			Template.import_date, 
			Template.FormatTypeId,
			Template.Business_Unit_GUID, 
			Template.Supplier_Guid,
			Template.Content_Bookmark,
			Template.Modified_Date,
			Intelledox_User.Username
	FROM	Template
		LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By
	WHERE	Template.Business_Unit_GUID = @BusinessUnitGuid
		AND Project_Definition.exist('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question/Answer/ContentItem[@Id = sql:variable("@ContentGuid")])[1]') = 1
	ORDER BY Template.[name];

GO

ALTER procedure [dbo].[spProject_GetProjectsByContentDefinition]
	@ContentGuid varchar(40),
	@BusinessUnitGuid uniqueidentifier
as
	SELECT 	Template.template_id, 
			Template.[name] as project_name, 
			Template.template_type_id, 
			Template.fax_template_id, 
			Template.layout_id, 
			Template.template_guid, 
			Template.template_version, 
			Template.import_date, 
			Template.FormatTypeId,
			Template.Business_Unit_GUID, 
			Template.Supplier_Guid,
			Template.Content_Bookmark,
			Template.Modified_Date,
			Intelledox_User.Username
	FROM	Template
		LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By
	WHERE	Template.Business_Unit_GUID = @BusinessUnitGuid
		AND Project_Definition.exist('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question/Answer/ContentDefinition[@Id = sql:variable("@ContentGuid")])[1]') = 1
	ORDER BY Template.[name];

GO

ALTER procedure [dbo].[spTemplate_TemplateList]
	@TemplateID int = 0,
	@TemplateGuid uniqueidentifier = null,
	@ErrorCode int output
as
	SET NOCOUNT ON
	
	If @TemplateGuid IS NOT NULL
	BEGIN
		SELECT	@TemplateId = Template_Id
		FROM	Template
		WHERE	Template_Guid = @TemplateGuid
	END

	IF @TemplateID = 0 
		SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.file_length, a.fax_template_id, 
				a.layout_id, a.xlmodel_file, a.template_guid, a.web_template,  b.Category_ID, 
				b.[Name] as Category_Name, a.FormatTypeId, a.Supplier_Guid, a.Business_Unit_Guid,
				a.Content_Bookmark, a.HelpText, a.Modified_Date, Intelledox_User.Username, 
				a.[name] as Project_Name
		FROM	Template a
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		ORDER BY a.[Name]
	ELSE
		SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.file_length, a.fax_template_id, 
				a.layout_id, a.xlmodel_file, a.template_guid, a.web_template, b.Category_ID, 
				b.[Name] as Category_Name, a.FormatTypeId, a.Supplier_Guid, a.Business_Unit_Guid,
				a.Content_Bookmark, a.HelpText, a.Modified_Date, Intelledox_User.Username,
				a.[name] as Project_Name
		FROM	Template a
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		WHERE	a.template_id = @TemplateID
		ORDER BY a.[Name]

	set @ErrorCode = @@error
GO

