/*
** Database Update package 8.2.0.3
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.0.3');
go

--2086
ALTER TABLE Template
ALTER COLUMN Template_Version nvarchar(10)
GO

ALTER TABLE Template_Group
ALTER COLUMN Template_Version nvarchar(10)
GO

ALTER TABLE Template_Group
ALTER COLUMN Layout_Version nvarchar(10)
GO

BEGIN TRANSACTION
GO

CREATE TABLE dbo.Tmp_Template_Version
	(
	Template_Version nvarchar(10) NOT NULL,
	Template_Guid uniqueidentifier NOT NULL,
	Modified_Date datetime NULL,
	Modified_By uniqueidentifier NULL,
	Project_Definition xml NULL,
	Comment nvarchar(max) NULL
	) 
GO

ALTER TABLE dbo.Tmp_Template_Version ADD CONSTRAINT
	PK_Template_Version2 PRIMARY KEY CLUSTERED 
	(
	Template_Guid,
	Template_Version
	)
GO

IF EXISTS(SELECT * FROM dbo.Template_Version)
	 EXEC('INSERT INTO dbo.Tmp_Template_Version (Template_Version, Template_Guid, Modified_Date, Modified_By, Project_Definition, Comment)
		SELECT CONVERT(nvarchar(10), Template_Version), Template_Guid, Modified_Date, Modified_By, Project_Definition, Comment FROM dbo.Template_Version')
GO

DROP TABLE dbo.Template_Version
GO

EXECUTE sp_rename N'dbo.Tmp_Template_Version', N'Template_Version', 'OBJECT' 
GO

COMMIT
GO

BEGIN TRANSACTION
GO

CREATE TABLE dbo.Tmp_Template_File_Version
	(
	Template_Guid uniqueidentifier NOT NULL,
	File_Guid uniqueidentifier NOT NULL,
	Binary varbinary(MAX) NOT NULL,
	Template_Version nvarchar(10) NOT NULL,
	FormatTypeId varchar(6) NULL
	) 
GO

ALTER TABLE dbo.Tmp_Template_File_Version ADD CONSTRAINT
	PK_Template_File_Version2 PRIMARY KEY CLUSTERED 
	(
	Template_Guid,
	File_Guid,
	Template_Version
	)
GO

IF EXISTS(SELECT * FROM dbo.Template_File_Version)
	 EXEC('INSERT INTO dbo.Tmp_Template_File_Version (Template_Guid, File_Guid, Binary, Template_Version, FormatTypeId)
		SELECT Template_Guid, File_Guid, Binary, CONVERT(nvarchar(10), Template_Version), FormatTypeId FROM dbo.Template_File_Version')
GO

DROP TABLE dbo.Template_File_Version
GO

EXECUTE sp_rename N'dbo.Tmp_Template_File_Version', N'Template_File_Version', 'OBJECT' 
GO

COMMIT
GO

ALTER TABLE Template
ADD IsMajorVersion bit not null default (0)
GO

ALTER TABLE Template_Version
ADD IsMajorVersion bit not null default (0)
GO

--2087
UPDATE Template
SET Template_Version = '0.' + Template_Version
GO

UPDATE Template_Group
SET Template_Version = '0.' + Template_Version,
	Layout_Version = '0.' + Layout_Version
GO

UPDATE Template_Version
SET Template_Version = '0.' + Template_Version
GO

UPDATE Template_File_Version
SET Template_Version = '0.' + Template_Version
GO

UPDATE Template
SET IsMajorVersion = 1
GO

UPDATE Template_Version
SET IsMajorVersion = 0
GO

--2088
ALTER VIEW [dbo].[vwTemplateVersion]
AS
	SELECT	Template_Version.Template_Version, 
			Template_Version.Template_Guid,
			Template_Version.Modified_Date,
			Template_Version.Comment,
			Template.Template_Type_ID,
			Template.LockedByUserGuid,
			Template_Version.IsMajorVersion,
			Intelledox_User.Username,
			CASE (SELECT COUNT(*)
					FROM Template_Group 
					WHERE (Template_Group.Template_Guid = Template_Version.Template_Guid
								AND Template_Group.Template_Version = Template_Version.Template_Version)
							OR (Template_Group.Layout_Guid = Template_Version.Template_Guid
								AND Template_Group.Layout_Version = Template_Version.Template_Version)) 
				WHEN 0
				THEN 0
				ELSE 1
			END AS InUse,
			0 AS Latest
		FROM	Template_Version
			INNER JOIN Template ON Template_Version.Template_Guid = Template.Template_Guid
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template_Version.Modified_By
	UNION ALL
		SELECT	Template.Template_Version, 
				Template.Template_Guid,
				Template.Modified_Date,
				Template.Comment,
				Template.Template_Type_ID,
				Template.LockedByUserGuid,
				Template.IsMajorVersion,
				Intelledox_User.Username,
				CASE (SELECT COUNT(*)
						FROM Template_Group 
						WHERE (Template_Group.Template_Guid = Template.Template_Guid
									AND (Template_Group.Template_Version = Template.Template_Version OR ISNULL(Template_Group.Template_Version, '0') = '0'))
							OR (Template_Group.Layout_Guid = Template.Template_Guid
									AND (Template_Group.Layout_Version = Template.Template_Version OR ISNULL(Template_Group.Layout_Version, '0') = '0')))
					WHEN 0
					THEN 0
					ELSE 1
				END AS InUse,
				1 AS Latest
		FROM	Template
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By;

GO

--2089
ALTER procedure [dbo].[spProject_RestoreVersion]
	@ProjectGuid uniqueidentifier,
	@VersionNumber nvarchar(10),
	@UserGuid uniqueidentifier,
	@RestoreVersionComment nvarchar(50),
	@NextVersion nvarchar(10)
as
	SET NOCOUNT ON

	BEGIN TRAN	
	
		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Project_Definition,
			Comment,
			IsMajorVersion)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,	
			Template.Modified_By,
			Template.Project_Definition,
			Template.Comment,
			Template.IsMajorVersion
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
			
		UPDATE Template
		SET	Project_Definition = (SELECT Project_Definition
				FROM Template_Version 
				WHERE Template_Guid = @ProjectGuid 
					AND Template_Version = @VersionNumber), 
			Template_Version = @NextVersion, 
			Comment = @RestoreVersionComment,
			Modified_Date = GetUTCdate(),
			Modified_By = @UserGuid,
			IsMajorVersion = 1
		WHERE	Template_Guid = @ProjectGuid;
		
		DELETE FROM Template_File
		WHERE	Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File(Template_Guid, File_Guid, [Binary], FormatTypeId)
		SELECT	@ProjectGuid, Template_File_Version.File_Guid, Template_File_Version.[Binary],
				Template_File_Version.FormatTypeId
		FROM	Template_File_Version 
		WHERE	Template_Guid = @ProjectGuid 
				AND Template_Version = @VersionNumber; 
				
		--delete the earliest minor version which does not belong to the next version number
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
						AND (FLOOR(vwTemplateVersion.Template_Version) < FLOOR(@NextVersion))) > 0)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version 
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
						AND (FLOOR(vwTemplateVersion.Template_Version) < FLOOR(@NextVersion))
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END
			
		--otherwise	
		--delete earliest major version, leaving at least one major version untouched			
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 1) > 1)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 1
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END

		--otherwise
		--delete the earliest left minor version
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0) > 0)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END
				
	COMMIT

GO

--2090
ALTER PROCEDURE [dbo].[spProject_Binary] (
	@TemplateGuid uniqueidentifier,
	@FileGuid uniqueidentifier,
	@VersionNumber nvarchar(10) = '0'
)
AS
	If @VersionNumber = '0'
	BEGIN
		SELECT	[Binary]  
		FROM	Template_File
		WHERE	Template_Guid = @TemplateGuid
				AND File_Guid = @FileGuid;
	END
	ELSE
	BEGIN
		SELECT	Template_File.[Binary]  
		FROM	Template_File
				INNER JOIN Template ON Template.Template_Guid = Template_File.Template_Guid
		WHERE	Template.Template_Guid = @TemplateGuid
			AND Template.Template_Version = @VersionNumber
				AND Template_File.File_Guid = @FileGuid
		UNION ALL
		SELECT	[Binary]  
		FROM	Template_File_Version
		WHERE	Template_Guid = @TemplateGuid
			AND Template_Version = @VersionNumber
				AND File_Guid = @FileGuid;
	END

GO

--2091
ALTER PROCEDURE [dbo].[spProject_Definition] (
	@TemplateGuid uniqueidentifier,
	@VersionNumber nvarchar(10) = '0'
)
AS
	If @VersionNumber = '0'
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

--2092
ALTER PROCEDURE [dbo].[spProject_GetBinaries] (
	@TemplateGuid uniqueidentifier,
	@VersionNumber nvarchar(10) = '0'
)
AS
	If @VersionNumber = '0'
	BEGIN
		SELECT	[Binary], File_Guid, FormatTypeId
		FROM	Template_File
		WHERE	Template_Guid = @TemplateGuid;
	END
	ELSE
	BEGIN
		SELECT	Template_File.[Binary], Template_File.File_Guid, Template_File.FormatTypeId
		FROM	Template_File
				INNER JOIN Template ON Template.Template_Guid = Template_File.Template_Guid
		WHERE	Template.Template_Guid = @TemplateGuid
			AND Template.Template_Version = @VersionNumber
		UNION ALL
		SELECT	[Binary], File_Guid, FormatTypeId
		FROM	Template_File_Version
		WHERE	Template_Guid = @TemplateGuid
			AND Template_Version = @VersionNumber;
	END

GO

--2093
ALTER PROCEDURE [dbo].[spProjectGrp_UpdateProjectGroup]
	@ProjectGroupGuid uniqueidentifier,
	@Name nvarchar(100),
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
		INSERT INTO Template_Group ([name], template_group_guid, helptext, AllowPreview, PostGenerateText, 
				UpdateDocumentFields, EnforceValidation, WizardFinishText, EnforcePublishPeriod,
				PublishStartDate, PublishFinishDate, HideNavigationPane, Template_Guid, Layout_Guid,
				Template_Version, Layout_Version, Folder_Guid)
		VALUES (@Name, @ProjectGroupGuid, @HelpText, @AllowPreview, @PostGenerateText, 
				@UpdateDocumentFields, @EnforceValidation, @WizardFinishText, @EnforcePublishPeriod,
				@PublishStartDate, @PublishFinishDate, @HideNavigationPane, @ProjectGuid, @LayoutGuid,
				@ProjectVersion, @LayoutVersion, @FolderGuid);
	END
	ELSE
	BEGIN
		UPDATE	Template_Group
		SET		[Name] = @Name,
				HelpText = @HelpText,
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

--2094
ALTER procedure [dbo].[spProject_AddNewProjectVersion]
	@ProjectGuid uniqueidentifier,
	@NextVersion nvarchar(10)

AS
	BEGIN TRAN

		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Project_Definition,
			Comment,
			IsMajorVersion)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,
			Template.Modified_By,
			Template.Project_Definition,
			Template.Comment,
			Template.IsMajorVersion
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File_Version (Template_Guid, File_Guid, Template_Version, [Binary],
				FormatTypeId)
		SELECT	Template.Template_Guid, Template_File.File_Guid, Template.Template_Version, 
				Template_File.[Binary], Template_File.FormatTypeId
		FROM	Template
				INNER JOIN Template_File ON Template.Template_Guid = Template_File.Template_Guid
		WHERE	Template.Template_Guid = @ProjectGuid;
		
		--delete the earliest minor version which does not belong to the next version number
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
						AND (FLOOR(vwTemplateVersion.Template_Version) < FLOOR(@NextVersion))) > 0)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version 
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
						AND (FLOOR(vwTemplateVersion.Template_Version) < FLOOR(@NextVersion))
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END
			
		--otherwise	
		--delete earliest major version, leaving at least one major version untouched			
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 1) > 1)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 1
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END

		--otherwise
		--delete the earliest left minor version
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0) > 0)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END
				
		DELETE FROM Template_File_Version
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	Template_Version
					WHERE	Template_Guid = @ProjectGuid);
	COMMIT

GO

--2095
ALTER procedure [dbo].[spProject_UpdateProject]
	@BusinessUnitGuid uniqueidentifier,
	@Name nvarchar(100),
	@ProjectGuid uniqueidentifier,
	@ProjectTypeID int,
	@SupplierGuid uniqueidentifier,
	@ContentBookmark nvarchar(100),
	@NextVersion nvarchar(10) = '0',
	@UserGuid uniqueidentifier = NULL
as
	BEGIN TRAN

		IF NOT EXISTS(SELECT Template_Guid FROM Template WHERE Template_Guid = @ProjectGuid)
		BEGIN
			INSERT INTO Template(Business_Unit_Guid, Name, Template_Guid, 
				Template_Type_Id, Supplier_Guid, Content_Bookmark, Template_Version, IsMajorVersion)
			VALUES (@BusinessUnitGuid, @Name, @ProjectGuid, 
				@ProjectTypeId, @SupplierGuid, @ContentBookmark, '0.0', 0);
		END
		ELSE
		BEGIN
		
			IF @UserGuid IS NOT NULL
			BEGIN
				EXEC spProject_AddNewProjectVersion @ProjectGuid, @NextVersion;
			END
		
			UPDATE	Template
			SET		[name] = @Name, 
					Template_type_id = @ProjectTypeID, 
					Supplier_GUID = @SupplierGuid,
					Content_Bookmark = @ContentBookmark
			WHERE	Template_Guid = @ProjectGuid;
		END

		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE Template
			SET Modified_Date = getUTCdate(),
				Modified_By = @UserGuid,
				Template_Version = @NextVersion,
				Comment = NULL,
				IsMajorVersion = 0
			WHERE Template_Guid = @ProjectGuid;
		END
	
	COMMIT
	
GO

--2096
ALTER PROCEDURE [dbo].[spProject_UnlockProject]
	@ProjectGuid uniqueidentifier,
	@VersionComment text = '',
	@UserGuid uniqueidentifier,
	@ForceUnlock bit
AS

	BEGIN TRAN
	
		--allows unlock either by any user if its a force unlock OR by the same user who has currently locked the project if general unlock
		IF @ForceUnlock = 1 OR (@ForceUnlock = 0 AND EXISTS(SELECT LockedByUserGuid FROM Template WHERE Template_Guid = @ProjectGuid AND LockedByUserGuid = @UserGuid))
		BEGIN
			IF EXISTS(SELECT Comment FROM Template WHERE Template_Guid = @ProjectGuid AND LEN(Comment) > 0) AND DATALENGTH(@VersionComment) = 0
			BEGIN
				UPDATE	Template
				SET		LockedByUserGuid = NULL,
						IsMajorVersion = 1
				WHERE	Template_Guid = @ProjectGuid;
			END
			ELSE
			BEGIN
				UPDATE	Template
				SET		LockedByUserGuid = NULL,
						Comment = @VersionComment,
						IsMajorVersion = 1
				WHERE	Template_Guid = @ProjectGuid;
			END
		END

	COMMIT

GO

--2097
ALTER procedure [dbo].[spProject_GetProjectVersions]
	@ProjectGuid uniqueidentifier
as
		SELECT vwTemplateVersion.Template_Version, 
			vwTemplateVersion.Modified_Date,
			vwTemplateVersion.Username,
			vwTemplateVersion.Comment,
			vwTemplateVersion.LockedByUserGuid,
			vwTemplateVersion.InUse
		FROM	vwTemplateVersion
		WHERE	vwTemplateVersion.Template_Guid = @ProjectGuid
	ORDER BY Modified_Date DESC;

GO

--2098
ALTER procedure [dbo].[spTemplate_TemplateList]
	@TemplateID int = 0,
	@TemplateGuid uniqueidentifier = null,
	@ErrorCode int output
AS
	SET NOCOUNT ON
	
	If @TemplateGuid IS NOT NULL
	BEGIN
		SELECT	@TemplateId = Template_Id
		FROM	Template
		WHERE	Template_Guid = @TemplateGuid;
	END

	IF @TemplateID = 0 
		SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, b.Category_ID, 
				b.[Name] as Category_Name, a.Supplier_Guid, a.Business_Unit_Guid,
				a.Content_Bookmark, a.HelpText, a.Modified_Date, Intelledox_User.Username, 
				a.[name] as Project_Name, a.Modified_By, lockedByUser.Username AS LockedBy, a.Comment, a.Template_Version
		FROM	Template a 
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		ORDER BY a.[Name];
	ELSE
		SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, b.Category_ID, 
				b.[Name] as Category_Name, a.Supplier_Guid, a.Business_Unit_Guid,
				a.Content_Bookmark, a.HelpText, a.Modified_Date, Intelledox_User.Username,
				a.[name] as Project_Name, a.Modified_By, lockedByUser.Username AS LockedBy, a.Comment, a.Template_Version
		FROM	Template a
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		WHERE	a.template_id = @TemplateID
		ORDER BY a.[Name];

	set @ErrorCode = @@error;

GO

--2099
ALTER PROCEDURE [dbo].[spProject_UpdateDefinition] (
	@Xtf xml,
	@TemplateGuid uniqueidentifier
)
AS
	BEGIN TRAN
	
		UPDATE	Template 
		SET		Project_Definition = @XTF 
		WHERE	Template_Guid = @TemplateGuid;
		
	COMMIT

GO

--2100
ALTER TABLE Template
	ADD FeatureFlags Int not null default (0)
GO
ALTER TABLE Template_Version
	ADD FeatureFlags Int not null default (0)
GO
SET ARITHABORT ON 

-- Workflow
UPDATE	Template
SET		FeatureFlags = 1
FROM	Template
		CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/Workflow)') as ProjectXML(P);

UPDATE	Template_Version
SET		FeatureFlags = 1
FROM	Template_Version
		CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/Workflow)') as ProjectXML(P);
GO
SET ARITHABORT ON 

-- Data source
UPDATE	Template
SET		FeatureFlags = FeatureFlags | 2
FROM	Template
		CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
		CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
WHERE	Q.value('@TypeId', 'int') = 2		-- Data field
		OR Q.value('@TypeId', 'int') = 9	-- Data table
		OR Q.value('@TypeId', 'int') = 12	-- Data list
		OR Q.value('@TypeId', 'int') = 14;	-- Data source

UPDATE	Template_Version
SET		FeatureFlags = FeatureFlags | 2
FROM	Template_Version
		CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
		CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
WHERE	Q.value('@TypeId', 'int') = 2		-- Data field
		OR Q.value('@TypeId', 'int') = 9	-- Data table
		OR Q.value('@TypeId', 'int') = 12	-- Data list
		OR Q.value('@TypeId', 'int') = 14;	-- Data source
GO
SET ARITHABORT ON 

-- Content library
UPDATE	Template
SET		FeatureFlags = FeatureFlags | 4
FROM	Template
		CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
		CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
WHERE	Q.value('@TypeId', 'int') = 11
		AND Q.value('@DisplayType', 'int') = 8; -- Existing content item

UPDATE	Template_Version
SET		FeatureFlags = FeatureFlags | 4
FROM	Template_Version
		CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
		CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
WHERE	Q.value('@TypeId', 'int') = 11
		AND Q.value('@DisplayType', 'int') = 8; -- Existing content item

UPDATE	Template
SET		FeatureFlags = FeatureFlags | 8
FROM	Template
		CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
		CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
WHERE	Q.value('@TypeId', 'int') = 11
		AND Q.value('@DisplayType', 'int') = 4; -- Search

UPDATE	Template_Version
SET		FeatureFlags = FeatureFlags | 8
FROM	Template_Version
		CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
		CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
WHERE	Q.value('@TypeId', 'int') = 11
		AND Q.value('@DisplayType', 'int') = 4; -- Search
GO
SET ARITHABORT ON 

-- Address
UPDATE	Template
SET		FeatureFlags = FeatureFlags | 16
FROM	Template
		CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
		CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
WHERE	Q.value('@TypeId', 'int') = 1

UPDATE	Template_Version
SET		FeatureFlags = FeatureFlags | 16
FROM	Template_Version
		CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
		CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
WHERE	Q.value('@TypeId', 'int') = 1
GO
SET ARITHABORT ON 

-- Sign off
UPDATE	Template
SET		FeatureFlags = FeatureFlags | 32
FROM	Template
		CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
		CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
WHERE	Q.value('@TypeId', 'int') = 5

UPDATE	Template_Version
SET		FeatureFlags = FeatureFlags | 32
FROM	Template_Version
		CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
		CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
WHERE	Q.value('@TypeId', 'int') = 5
GO
ALTER PROCEDURE [dbo].[spProject_UpdateDefinition] (
	@Xtf xml,
	@TemplateGuid uniqueidentifier,
	@UserGuid uniqueidentifier = NULL
)
AS
	DECLARE @FeatureFlags int;

	BEGIN TRAN
		-- Feature detection --
		SET @FeatureFlags = 0

		-- Workflow
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/Workflow)') as ProjectXML(P))
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 1;
		END

		-- Data source
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 2		-- Data field
						OR Q.value('@TypeId', 'int') = 9	-- Data table
						OR Q.value('@TypeId', 'int') = 12	-- Data list
						OR Q.value('@TypeId', 'int') = 14)	-- Data source
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 2;
		END

		-- Content library
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 11
						AND Q.value('@DisplayType', 'int') = 8) -- Existing content item
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 4;
		END
		
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 11
						AND Q.value('@DisplayType', 'int') = 4) -- Search
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 8;
		END

		-- Address
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 1)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 16;
		END

		-- Sign off
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 5)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 32;
		END

		IF @UserGuid IS NOT NULL
		BEGIN
			EXEC spProject_AddNewProjectVersion @TemplateGuid;
		END
		
		UPDATE	Template 
		SET		Project_Definition = @XTF,
				FeatureFlags = @FeatureFlags
		WHERE	Template_Guid = @TemplateGuid;
		
		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE Template
			SET Template_Version = Template_Version + 1,
				Comment = NULL,
				Modified_By = @UserGuid,
				Modified_Date = GETUTCDATE()
			WHERE Template_Guid = @TemplateGuid;
		END
	COMMIT
GO
ALTER procedure [dbo].[spProject_AddNewProjectVersion]
	@ProjectGuid uniqueidentifier,
	@NextVersion nvarchar(10)
AS
	BEGIN TRAN

		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Project_Definition,
			Comment,
			IsMajorVersion,
			FeatureFlags)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,
			Template.Modified_By,
			Template.Project_Definition,
			Template.Comment,
			Template.IsMajorVersion,
			Template.FeatureFlags
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File_Version (Template_Guid, File_Guid, Template_Version, [Binary],
				FormatTypeId)
		SELECT	Template.Template_Guid, Template_File.File_Guid, Template.Template_Version, 
				Template_File.[Binary], Template_File.FormatTypeId
		FROM	Template
				INNER JOIN Template_File ON Template.Template_Guid = Template_File.Template_Guid
		WHERE	Template.Template_Guid = @ProjectGuid;
		
		--delete the earliest minor version which does not belong to the next version number
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
						AND (FLOOR(vwTemplateVersion.Template_Version) < FLOOR(@NextVersion))) > 0)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version 
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
						AND (FLOOR(vwTemplateVersion.Template_Version) < FLOOR(@NextVersion))
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END
			
		--otherwise	
		--delete earliest major version, leaving at least one major version untouched			
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 1) > 1)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 1
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END

		--otherwise
		--delete the earliest left minor version
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0) > 0)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END
				
		DELETE FROM Template_File_Version
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	Template_Version
					WHERE	Template_Guid = @ProjectGuid);
	COMMIT
GO
ALTER procedure [dbo].[spProject_RestoreVersion]
	@ProjectGuid uniqueidentifier,
	@VersionNumber nvarchar(10),
	@UserGuid uniqueidentifier,
	@RestoreVersionComment nvarchar(50),
	@NextVersion nvarchar(10)
as
	SET NOCOUNT ON

	BEGIN TRAN	
	
		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Project_Definition,
			Comment,
			IsMajorVersion,
			FeatureFlags)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,	
			Template.Modified_By,
			Template.Project_Definition,
			Template.Comment,
			Template.IsMajorVersion,
			Template.FeatureFlags
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
			
		DECLARE @ProjectDefinition xml,
				@FeatureFlags int

		SELECT	@ProjectDefinition = Project_Definition,
				@FeatureFlags = FeatureFlags
		FROM	Template_Version 
		WHERE	Template_Guid = @ProjectGuid 
				AND Template_Version = @VersionNumber

		UPDATE	Template
		SET		Project_Definition = @ProjectDefinition, 
				Template_Version = @NextVersion, 
				Comment = @RestoreVersionComment,
				Modified_Date = GetUTCdate(),
				Modified_By = @UserGuid,
				IsMajorVersion = 1,
				FeatureFlags = @FeatureFlags
		WHERE	Template_Guid = @ProjectGuid;
		
		DELETE FROM Template_File
		WHERE	Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File(Template_Guid, File_Guid, [Binary], FormatTypeId)
		SELECT	@ProjectGuid, Template_File_Version.File_Guid, Template_File_Version.[Binary],
				Template_File_Version.FormatTypeId
		FROM	Template_File_Version 
		WHERE	Template_Guid = @ProjectGuid 
				AND Template_Version = @VersionNumber; 
				
		--delete the earliest minor version which does not belong to the next version number
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
						AND (FLOOR(vwTemplateVersion.Template_Version) < FLOOR(@NextVersion))) > 0)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version 
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
						AND (FLOOR(vwTemplateVersion.Template_Version) < FLOOR(@NextVersion))
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END
			
		--otherwise	
		--delete earliest major version, leaving at least one major version untouched			
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 1) > 1)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 1
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END

		--otherwise
		--delete the earliest left minor version
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0) > 0)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END
				
	COMMIT
GO
ALTER procedure [dbo].[spProject_ProjectList]
	@UserGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ProjectTypeId int,
	@SearchString nvarchar(100),
	@Purpose nvarchar(10)
as
	declare @IsGlobal bit
	declare @BusinessUnitGUID uniqueidentifier

	SELECT	@BusinessUnitGUID = Business_Unit_GUID
	FROM	Intelledox_User
	WHERE	User_Guid = @UserGuid;

	IF EXISTS(SELECT	vwUserPermissions.*
		FROM	vwUserPermissions
		WHERE	((@Purpose = 'Design' AND vwUserPermissions.CanDesignProjects = 1)
					OR (@Purpose = 'Publish' AND vwUserPermissions.CanPublishProjects = 1))
				AND vwUserPermissions.GroupGuid IS NULL
				AND vwUserPermissions.UserGuid = @UserGuid)
	BEGIN
		SET @IsGlobal = 1;
	END

	if @GroupGuid IS NULL
	begin
		--all usergroups
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, a.template_version, a.import_date, 
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Content_Bookmark, a.Modified_By, lockedByUser.Username AS LockedBy,
				a.FeatureFlags
		FROM	Template a
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
			LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		WHERE	(@IsGlobal = 1 or a.Template_Guid in (
				SELECT	User_Group_Template.TemplateGuid
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid
				WHERE	((@Purpose = 'Design' AND vwUserPermissions.CanDesignProjects = 1)
					OR (@Purpose = 'Publish' AND vwUserPermissions.CanPublishProjects = 1))
			AND Intelledox_User.User_Guid = @UserGuid
				))
			AND (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
		ORDER BY a.[name];
	end
	else
	begin
		--specific user group
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, a.template_version, a.import_date, 
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Content_Bookmark, a.Modified_By, lockedByUser.Username AS LockedBy,
				a.FeatureFlags
		FROM	Template a
				INNER JOIN User_Group_Template d on a.Template_Guid = d.TemplateGuid
				INNER JOIN User_Group ON d.GroupGuid = User_Group.Group_Guid AND User_Group.Group_Guid = @GroupGuid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		WHERE	(@IsGlobal = 1 or a.template_Guid in (
				SELECT	User_Group_Template.TemplateGuid
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid
				WHERE	((@Purpose = 'Design' AND vwUserPermissions.CanDesignProjects = 1)
					OR (@Purpose = 'Publish' AND vwUserPermissions.CanPublishProjects = 1))
			))
			and (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
		ORDER BY a.[name];
	end
GO
ALTER procedure [dbo].[spProject_ProjectListFullText]
	@UserGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ProjectTypeId int,
	@SearchString nvarchar(100),
	@FullText NVarChar(1000)
as
	declare @IsGlobal bit
	declare @BusinessUnitGUID uniqueidentifier

	SELECT	@BusinessUnitGUID = Business_Unit_GUID
	FROM	Intelledox_User
	WHERE	User_Guid = @UserGuid;

	IF EXISTS(SELECT	vwUserPermissions.*
		FROM	vwUserPermissions
		WHERE	vwUserPermissions.CanDesignProjects = 1
				AND vwUserPermissions.GroupGuid IS NULL
				AND vwUserPermissions.UserGuid = @UserGuid)
	BEGIN
		SET @IsGlobal = 1;
	END

	if @GroupGuid IS NULL
	begin
		--all usergroups
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, a.template_version, a.import_date, 
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Content_Bookmark, a.Modified_By, lockedByUser.Username AS LockedBy,
				a.FeatureFlags
		FROM	Template a
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		WHERE	(@IsGlobal = 1 or a.template_Guid in (
				SELECT	User_Group_Template.TemplateGuid
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid 
				WHERE	vwUserPermissions.CanDesignProjects = 1
			AND Intelledox_User.User_Guid = @UserGuid
				))
			AND (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
			AND (a.Template_Guid IN (
					SELECT	Template_Guid
					FROM	Template_File tf
					WHERE	Contains(*, @FullText)
				))
		ORDER BY a.[name];
	end
	else
	begin
		--specific user group
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, a.template_version, a.import_date, 
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Content_Bookmark, a.Modified_By, lockedByUser.Username AS LockedBy,
				a.FeatureFlags
		FROM	Template a
				INNER JOIN User_Group_Template d on a.Template_Guid = d.TemplateGuid
				INNER JOIN User_Group ON d.GroupGuid = User_Group.Group_Guid  AND User_Group.Group_Guid = @GroupGuid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		WHERE	(@IsGlobal = 1 or a.template_Guid in (
				SELECT	User_Group_Template.TemplateGuid
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid 
				WHERE	vwUserPermissions.CanDesignProjects = 1
			))
			and (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
			AND (a.Template_Guid IN (
					SELECT	Template_Guid
					FROM	Template_File tf
					WHERE	Contains(*, @FullText)
				))
		ORDER BY a.[name];
	end
GO
ALTER procedure [dbo].[spTemplate_TemplateList]
	@TemplateID int = 0,
	@TemplateGuid uniqueidentifier = null,
	@ErrorCode int output
AS
	SET NOCOUNT ON
	
	If @TemplateGuid IS NOT NULL
	BEGIN
		SELECT	@TemplateId = Template_Id
		FROM	Template
		WHERE	Template_Guid = @TemplateGuid;
	END

	IF @TemplateID = 0 
		SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, b.Category_ID, 
				b.[Name] as Category_Name, a.Supplier_Guid, a.Business_Unit_Guid,
				a.Content_Bookmark, a.HelpText, a.Modified_Date, Intelledox_User.Username, 
				a.[name] as Project_Name, a.Modified_By, lockedByUser.Username AS LockedBy, a.Comment, 
				a.Template_Version, a.FeatureFlags
		FROM	Template a 
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		ORDER BY a.[Name];
	ELSE
		SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, b.Category_ID, 
				b.[Name] as Category_Name, a.Supplier_Guid, a.Business_Unit_Guid,
				a.Content_Bookmark, a.HelpText, a.Modified_Date, Intelledox_User.Username,
				a.[name] as Project_Name, a.Modified_By, lockedByUser.Username AS LockedBy, a.Comment, 
				a.Template_Version, a.FeatureFlags
		FROM	Template a
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		WHERE	a.template_id = @TemplateID
		ORDER BY a.[Name];

	set @ErrorCode = @@error;
GO

SET ARITHABORT ON

--2101
-- Rich text
UPDATE	Template
SET		FeatureFlags = FeatureFlags | 64
FROM	Template
		CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
		CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
WHERE	Q.value('@TypeId', 'int') = 19

UPDATE	Template_Version
SET		FeatureFlags = FeatureFlags | 64
FROM	Template_Version
		CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
		CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
WHERE	Q.value('@TypeId', 'int') = 19
GO
ALTER PROCEDURE [dbo].[spProject_UpdateDefinition] (
	@Xtf xml,
	@TemplateGuid uniqueidentifier
)
AS
	DECLARE @FeatureFlags int;

	BEGIN TRAN
		-- Feature detection --
		SET @FeatureFlags = 0

		-- Workflow
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/Workflow)') as ProjectXML(P))
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 1;
		END

		-- Data source
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 2		-- Data field
						OR Q.value('@TypeId', 'int') = 9	-- Data table
						OR Q.value('@TypeId', 'int') = 12	-- Data list
						OR Q.value('@TypeId', 'int') = 14)	-- Data source
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 2;
		END

		-- Content library
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 11
						AND Q.value('@DisplayType', 'int') = 8) -- Existing content item
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 4;
		END
		
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 11
						AND Q.value('@DisplayType', 'int') = 4) -- Search
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 8;
		END

		-- Address
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 1)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 16;
		END

		-- Sign off
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 5)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 32;
		END

		-- Rich text
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 19)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 64;
		END
				
		UPDATE	Template 
		SET		Project_Definition = @XTF,
				FeatureFlags = @FeatureFlags
		WHERE	Template_Guid = @TemplateGuid;
	COMMIT
GO

