/*
** Database Update package 6.2.6
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.2.6')
go

--1915
CREATE TABLE dbo.Template_File
	(
	Template_Guid uniqueidentifier NOT NULL,
	File_Guid uniqueidentifier NOT NULL,
	Binary varbinary(MAX) NOT NULL
	)  ON [PRIMARY]
	 TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE dbo.Template_File ADD CONSTRAINT
	PK_Template_File PRIMARY KEY CLUSTERED 
	(
	Template_Guid,
	File_Guid
	) ON [PRIMARY]
GO
CREATE TABLE dbo.Template_File_Version
	(
	Template_Guid uniqueidentifier NOT NULL,
	File_Guid uniqueidentifier NOT NULL,
	Binary varbinary(MAX) NOT NULL,
	Template_Version int not null
	)  ON [PRIMARY]
	 TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE dbo.Template_File_Version ADD CONSTRAINT
	PK_Template_File_Version PRIMARY KEY CLUSTERED 
	(
	Template_Guid,
	File_Guid,
	Template_Version
	) ON [PRIMARY]
GO
INSERT INTO Template_File(Template_Guid, File_Guid, [Binary])
SELECT	Template_Guid, Template_Guid, [Binary]
FROM	Template
WHERE	[Binary] IS NOT NULL;
GO
INSERT INTO Template_File_Version(Template_Guid, File_Guid, [Binary], Template_Version)
SELECT	Template_Guid, Template_Guid, [Binary], Template_Version
FROM	Template_Version
WHERE	[Binary] IS NOT NULL
GO
ALTER TABLE Template
	DROP COLUMN Layout_ID
GO
ALTER TABLE Template
	DROP COLUMN [Binary]
GO
ALTER TABLE Template
	DROP COLUMN File_Length
GO
ALTER TABLE Template
	DROP COLUMN xlmodel_file
GO
ALTER TABLE Template
	DROP COLUMN Template_Xml
GO
ALTER TABLE Template
	DROP CONSTRAINT DF_Template_Store_XML
GO
ALTER TABLE Template
	DROP COLUMN Web_Template
GO
ALTER TABLE Template_Version
	DROP COLUMN [Binary]
GO
ALTER procedure [dbo].[spTemplate_RemoveTemplate]
	@TemplateGuid uniqueidentifier,
	@OnlyChildInfo bit
as
	DECLARE @TemplateId Int

	SELECT	@TemplateId = Template_Id
	FROM	Template
	WHERE	Template_Guid = @TemplateGuid;

	DELETE	template_macro
	WHERE	template_id = @TemplateID;

	IF @OnlyChildInfo = 0
	BEGIN
		DELETE	template_Group_item
		WHERE	template_id = @TemplateID
			OR	layout_id = @TemplateID;

		DELETE	template_Group
		WHERE	Template_Group_id NOT IN (
			SELECT	Template_Group_id
			FROM	Template_Group_Item
		);

		DELETE	Package_Template
		WHERE	Template_Group_id NOT IN (
			SELECT	Template_Group_id
			FROM	template_Group
		);

		DELETE	Template_Category
		WHERE	Template_ID = @TemplateID;

		DELETE	User_Group_Template
		WHERE	Template_ID = @TemplateID;
	END
	
	DELETE	Template_File
	WHERE	Template_Guid = @TemplateGuid;
	
	DELETE	Template
	WHERE	Template_Guid = @TemplateGuid;
	
	DELETE	Template_File_Version
	WHERE	Template_Guid = @TemplateGuid;
	
	DELETE	Template_Version
	WHERE	Template_Guid = @TemplateGuid;
GO
DROP procedure [dbo].[spTemplate_TemplateBinary]
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
		WHERE	Template_Guid = @TemplateGuid;
	END

	IF @TemplateID = 0 
		SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, b.Category_ID, 
				b.[Name] as Category_Name, a.FormatTypeId, a.Supplier_Guid, a.Business_Unit_Guid,
				a.Content_Bookmark, a.HelpText, a.Modified_Date, Intelledox_User.Username, 
				a.[name] as Project_Name
		FROM	Template a
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		ORDER BY a.[Name];
	ELSE
		SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, b.Category_ID, 
				b.[Name] as Category_Name, a.FormatTypeId, a.Supplier_Guid, a.Business_Unit_Guid,
				a.Content_Bookmark, a.HelpText, a.Modified_Date, Intelledox_User.Username,
				a.[name] as Project_Name
		FROM	Template a
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		WHERE	a.template_id = @TemplateID
		ORDER BY a.[Name];

	set @ErrorCode = @@error;

GO
ALTER procedure [dbo].[spTemplate_TemplateListByFilter]
	@UserID int,
	@TemplateID int = 0,
	@TemplateTypeID int = 0,
	@CategoryID int = 0,
	@UserGroupID int = 0,
	@FormatTypeID int = 0,
	@BusinessUnitGUID uniqueidentifier,
	@SearchString nvarchar(100),
	@ErrorCode int output
as
/*
Vers	Date		Developer	Description
-------------------------------------------------------------------------------------------------------------
3.3.0	17/01/2005	Chrisg		created to support filtered template view
4.0.0	14/06/2005	Chrisg		returns Store_Xml field for web
4.0.1	14/07/2005	Chrisg		Returns new version and import date fields
4.1.8	04/10/2005	chrisg		No longer loads template_xml field to reduce load times.
4.6.0	18/12/2006	Chrisg		support for formattypeid and store_xml changed to web_template
4.6.1	16/01/2007	Chrisg		formattypeid can now be used as a filter
-------------------------------------------------------------------------------------------------------------
*/
	declare @IsGlobal bit

	--select @IsGlobal = a.globaltemplate
	--from administrator_level a
	--inner join Intelledox_User b on a.adminlevel_id = b.adminlevel_id and b.[user_id] = @UserID

	IF EXISTS(SELECT	Administrator_Level.*
		FROM	Administrator_Level
				INNER JOIN Role_Permission ON Administrator_Level.RoleGuid = Role_Permission.RoleGuid
				INNER JOIN User_Role ON Administrator_Level.RoleGuid = User_Role.RoleGuid
				INNER JOIN Intelledox_User ON User_Role.UserGuid = Intelledox_User.User_Guid
		WHERE	Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' --Manage Templates
				AND User_Role.GroupGuid IS NULL
				AND Intelledox_User.[User_ID] = @UserID)
	BEGIN
		SET @IsGlobal = 1;
	END

	IF @TemplateID = 0 
	begin
		if @UserGroupID = -1	--all usergroups
		begin
			SELECT 	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, a.template_guid,
				b.Category_ID, b.[Name] as Category_Name, a.template_version, a.import_date, a.FormatTypeId
			FROM	Template a
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
			WHERE (@TemplateTypeID = 0 or @TemplateTypeID = a.Template_Type_ID)
				and (@CategoryID = 0 or @CategoryID = c.Category_ID)
				and (@FormatTypeID = 0 or @FormatTypeID = a.FormatTypeID)
				and (@IsGlobal = 1 or a.template_id in (
					SELECT	User_Group_Template.Template_ID
					FROM	Role_Permission
							INNER JOIN User_Role ON Role_Permission.RoleGuid = User_Role.RoleGuid
							INNER JOIN Intelledox_User ON User_Role.UserGuid = Intelledox_User.User_Guid
							INNER JOIN User_Group_Subscription ON Intelledox_User.[User_ID] = User_Group_Subscription.[User_ID] 
							INNER JOIN User_Group ON User_Role.GroupGuid = User_Group.Group_Guid
							INNER JOIN User_Group_Template ON User_Group_Subscription.User_Group_Id = User_Group_Template.User_Group_Id 
					WHERE	Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' --Manage Templates
				AND Intelledox_User.[User_ID] = @UserID
					))
				AND (a.Business_Unit_GUID = @BusinessUnitGUID) 
				AND a.Name LIKE @SearchString + '%'
			ORDER BY a.[name];
		end
		else
		begin
			if @UserGroupID = 0	--global only
				SELECT 	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, a.template_guid, 
					b.Category_ID, b.[Name] as Category_Name, a.template_version, a.import_date, a.FormatTypeId
				FROM	Template a
					left join Template_Category c on a.Template_ID = c.Template_ID
					left join Category b on c.Category_ID = b.Category_ID
				WHERE (@TemplateTypeID = 0 or @TemplateTypeID = a.Template_Type_ID)
					and (@CategoryID = 0 or @CategoryID = c.Category_ID)
					and (@FormatTypeID = 0 or @FormatTypeID = a.FormatTypeID)
					and a.template_id not in (
						select template_id from user_group_template
					)
					and (@IsGlobal = 1)
					and (a.Business_Unit_GUID = @BusinessUnitGUID) 
					AND a.Name LIKE '%' + @SearchString + '%'
				ORDER BY a.[name];
			else	--specific user group
				SELECT 	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, a.template_guid, 
					b.Category_ID, b.[Name] as Category_Name, a.template_version, a.import_date, a.FormatTypeId
				FROM	Template a
					left join Template_Category c on a.Template_ID = c.Template_ID
					left join Category b on c.Category_ID = b.Category_ID
					inner join User_Group_Template d on a.Template_ID = d.Template_ID and d.User_Group_ID = @UserGroupID
				WHERE (@TemplateTypeID = 0 or @TemplateTypeID = a.Template_Type_ID)
					and (@CategoryID = 0 or @CategoryID = c.Category_ID)
					and (@FormatTypeID = 0 or @FormatTypeID = a.FormatTypeID)
					and (@IsGlobal = 1 or a.template_id in (
						SELECT	User_Group_Template.Template_ID
						FROM	Role_Permission
								INNER JOIN User_Role ON Role_Permission.RoleGuid = User_Role.RoleGuid
								INNER JOIN Intelledox_User ON User_Role.UserGuid = Intelledox_User.User_Guid
								INNER JOIN User_Group_Subscription ON Intelledox_User.[User_ID] = User_Group_Subscription.[User_ID] 
								INNER JOIN User_Group ON User_Role.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Template ON User_Group_Subscription.User_Group_Id = User_Group_Template.User_Group_Id 
						WHERE	Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' --Manage Templates
					))
					and (a.Business_Unit_GUID = @BusinessUnitGUID) 
					AND a.Name LIKE @SearchString + '%'
				ORDER BY a.[name];
		end
	end
	ELSE
	begin
		SELECT a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, a.template_guid, 
				b.Category_ID, b.[Name] as Category_Name, a.template_version, a.import_date, a.FormatTypeId
		FROM	Template a
			left join Template_Category c on a.Template_ID = c.Template_ID
			left join Category b on c.Category_ID = b.Category_ID
		WHERE a.template_id = @TemplateID
			and (@IsGlobal = 1 or a.template_id in (
					SELECT	User_Group_Template.Template_ID
					FROM	Role_Permission
							INNER JOIN User_Role ON Role_Permission.RoleGuid = User_Role.RoleGuid
							INNER JOIN Intelledox_User ON User_Role.UserGuid = Intelledox_User.User_Guid
							INNER JOIN User_Group_Subscription ON Intelledox_User.[User_ID] = User_Group_Subscription.[User_ID] 
							INNER JOIN User_Group ON User_Role.GroupGuid = User_Group.Group_Guid
							INNER JOIN User_Group_Template ON User_Group_Subscription.User_Group_Id = User_Group_Template.User_Group_Id 
					WHERE	Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' --Manage Templates
			))
		ORDER BY a.[name];
	end

	set @ErrorCode = @@error;

GO
ALTER procedure [dbo].[spTemplateGrp_TemplateList]
	@TemplateID int = 0,
	@ErrorCode int output
as
	SELECT	a.Template_ID, a.[Name], a.Template_Type_ID, a.Fax_Template_ID, a.template_guid, 
		b.Category_ID, b.[Name] as Category_Name
	FROM	Template a
		left join Template_Category c on a.Template_ID = c.Template_ID
		left join Category b on c.Category_ID = b.Category_ID
	WHERE	@TemplateID = 0 OR a.Template_ID = @TemplateID;

	set @ErrorCode = @@error;

GO
ALTER PROCEDURE [dbo].[spTemplateGrp_UpdateTemplate]
	@TemplateID int,
	@Name nvarchar(100),
	@TemplateTypeID int,
	@ContentBookmark nvarchar(100),
	@Template_Guid nvarchar(40),
	@Template_Version nvarchar(25),
	@Import_Date datetime,
	@HelpText nvarchar(4000),
	@FormatTypeId int,
	@SupplierGUID uniqueidentifier,
	@ErrorCode int output
as
/*
Vers	Date		Developer	Description
-------------------------------------------------------------------------------------------------------------
3.1.2	24/07/2004	Chrisg		modified to support guids for import/export
4.0.0	14/06/2005	Chrisg		new parameter - @Store_Xml for web
4.0.1	14/07/2005	Chrisg		Version info added for improved import/export
4.1.0	02/08/2005	Chrisg		Added 'HelpText' parameter
4.6.0	18/12/2006	Chrisg		Added support for FormatTypeID column
-------------------------------------------------------------------------------------------------------------
*/
	UPDATE	template
	SET	[name] = @Name, template_type_id = @TemplateTypeID, 
		content_bookmark = @ContentBookmark,
		template_version = @Template_Version, import_date = @Import_Date, helptext = @HelpText,
		formattypeid = @FormatTypeID, Supplier_GUID = @SupplierGUID
	WHERE template_id = @TemplateID;

	set @ErrorCode = @@error;
GO
ALTER PROCEDURE [dbo].[spTemplateGrp_InsertTemplate]
	@Name nvarchar(100),
	@TemplateTypeID int,
	@FaxTemplateID int,
	@ContentBookmark nvarchar(100),
	@Template_Guid nvarchar(40),
	@Template_Version nvarchar(25),
	@Import_Date datetime,
	@HelpText nvarchar(4000),
	@FormatTypeId int,
	@BusinessUnitGUID uniqueidentifier,
	@SupplierGUID uniqueidentifier,
	@NewTemplateID int output,
	@ErrorCode int output
as
	if (select count(*) from template where template_guid = cast(@Template_Guid as uniqueidentifier)) = 0
	begin
		INSERT INTO template ([name], template_type_id, fax_template_id, content_bookmark, Template_Guid, Template_Version, Import_Date, helptext, FormatTypeId, Business_Unit_GUID, Supplier_GUID)
		VALUES (@Name, @TemplateTypeID, @FaxTemplateID, @ContentBookmark, @Template_Guid, @Template_Version, @Import_Date, @HelpText, @FormatTypeId, @BusinessUnitGUID, @SupplierGUID);
		
		set @NewTemplateID = @@identity;
	end

	set @ErrorCode = @@error;
GO
DROP PROCEDURE [dbo].[spTemplateGrp_FolderListAll]
GO
ALTER procedure [dbo].[spProject_ProjectList]
	@UserGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ProjectTypeId int,
	@SearchString nvarchar(100)
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
				a.template_guid, a.template_version, a.import_date, a.FormatTypeId,
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
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
		ORDER BY a.[name];
	end
	else
	begin
		--specific user group
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, a.template_version, a.import_date, a.FormatTypeId,
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
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
		ORDER BY a.[name];
	end
GO
alter procedure [dbo].[spProject_GetProjectsByContentItem]
	@ContentGuid varchar(40),
	@BusinessUnitGuid uniqueidentifier
as
	SET ARITHABORT ON 

	SELECT 	Template.template_id, 
			Template.[name] as project_name, 
			Template.template_type_id, 
			Template.fax_template_id, 
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
alter procedure [dbo].[spProject_GetProjectsByContentDefinition]
	@ContentGuid varchar(40),
	@BusinessUnitGuid uniqueidentifier
as
	SET ARITHABORT ON 

	SELECT 	Template.template_id, 
			Template.[name] as project_name, 
			Template.template_type_id, 
			Template.fax_template_id, 
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
alter procedure [dbo].[spProject_AddNewProjectVersion]
	@ProjectGuid uniqueidentifier
as
	BEGIN TRAN

		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Project_Definition)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,
			Template.Modified_By,
			Template.Project_Definition
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File_Version (Template_Guid, File_Guid, Template_Version, [Binary])
		SELECT	Template.Template_Guid, Template_File.File_Guid, Template.Template_Version, 
				Template_File.[Binary]
		FROM	Template
				INNER JOIN Template_File ON Template.Template_Guid = Template_File.Template_Guid
		WHERE	Template.Template_Guid = @ProjectGuid;
		
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0) > 0)
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
				
		DELETE FROM Template_File_Version
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	Template_Version
					WHERE	Template_Guid = @ProjectGuid);
	COMMIT
GO
alter procedure [dbo].[spProject_RestoreVersion]
	@ProjectGuid uniqueidentifier,
	@VersionNumber int,
	@UserGuid uniqueidentifier
as
	SET NOCOUNT ON
		
	BEGIN TRAN	
	
		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Project_Definition)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,
			Template.Modified_By,
			Template.Project_Definition
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
			
		UPDATE Template
		SET	Project_Definition = (SELECT Project_Definition
				FROM Template_Version 
				WHERE Template_Guid = @ProjectGuid 
					AND Template_Version = @VersionNumber), 
			Template_Version = Template_Version + 1, 
			Modified_Date = GetUTCdate(),
			Modified_By = @UserGuid
		WHERE	Template_Guid = @ProjectGuid;
		
		DELETE FROM Template_File
		WHERE	Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File(Template_Guid, File_Guid, [Binary])
		SELECT	@ProjectGuid, Template_File_Version.File_Guid, Template_File_Version.[Binary]
		FROM	Template_File_Version 
		WHERE	Template_Guid = @ProjectGuid 
				AND Template_Version = @VersionNumber; 
				
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0) > 0)
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
ALTER PROCEDURE [dbo].[spProject_UpdateBinary] (
	@Bytes image,
	@TemplateGuid uniqueidentifier,
	@FileGuid uniqueidentifier
)
AS
	IF EXISTS(SELECT File_Guid FROM Template_File WHERE Template_Guid = @TemplateGuid AND File_Guid = @FileGuid)
	BEGIN
		UPDATE	Template_File
		SET		[Binary] = @Bytes
		WHERE	Template_Guid = @TemplateGuid
				AND File_Guid = @FileGuid;
	END
	ELSE
	BEGIN
		INSERT INTO Template_File(Template_Guid, File_Guid, [Binary])
		VALUES (@TemplateGuid, @FileGuid, @Bytes);
	END
GO
ALTER PROCEDURE [dbo].[spProject_Binary] (
	@TemplateGuid uniqueidentifier,
	@FileGuid uniqueidentifier,
	@VersionNumber int
)
AS
	If @VersionNumber = 0
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
ALTER PROCEDURE [dbo].[spLibrary_GetBinary] (
	@UniqueId as uniqueidentifier
)
AS
	SELECT	cd.ContentData as [Binary]
	FROM	ContentData_Binary cd
			INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
	WHERE	ContentItem_Guid = @UniqueId;
	
GO

--1916
ALTER TABLE Template_File
ADD FormatTypeId int
GO

UPDATE Template_File
SET FormatTypeId =
	(SELECT Template.FormatTypeId
	FROM Template
	WHERE Template.Template_Guid = Template_File.Template_Guid)
GO

ALTER TABLE Template_File_Version
ADD FormatTypeId int
GO

UPDATE Template_File_Version
SET FormatTypeId =
	(SELECT Template.FormatTypeId
	FROM Template
	WHERE Template.Template_Guid = Template_File_Version.Template_Guid)
GO

ALTER TABLE Template
	DROP COLUMN FormatTypeId
GO

CREATE PROCEDURE [dbo].[spProject_GetBinaries] (
	@TemplateGuid uniqueidentifier,
	@VersionNumber int
)
AS
	If @VersionNumber = 0
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
Go

CREATE procedure [dbo].[spProject_RemoveBinaries]
	@ProjectGuid uniqueidentifier
as
	DELETE FROM Template_File
	WHERE Template_Guid = @ProjectGuid;
GO

--1917
ALTER PROCEDURE [dbo].[spProject_UpdateBinary] (
	@Bytes image,
	@TemplateGuid uniqueidentifier,
	@FileGuid uniqueidentifier,
	@FormatType int
)
AS
	IF EXISTS(SELECT File_Guid FROM Template_File WHERE Template_Guid = @TemplateGuid AND File_Guid = @FileGuid)
	BEGIN
		UPDATE	Template_File
		SET		[Binary] = @Bytes,
				FormatTypeId = @FormatType
		WHERE	Template_Guid = @TemplateGuid
				AND File_Guid = @FileGuid;
	END
	ELSE
	BEGIN
		INSERT INTO Template_File(Template_Guid, File_Guid, [Binary], FormatTypeId)
		VALUES (@TemplateGuid, @FileGuid, @Bytes, @FormatType);
	END
GO

ALTER procedure [dbo].[spProject_UpdateProject]
	@BusinessUnitGuid uniqueidentifier,
	@FormatTypeId int,
	@Name nvarchar(100),
	@ProjectGuid uniqueidentifier,
	@SupplierGuid uniqueidentifier,
	@ContentBookmark nvarchar(100),
	@UserGuid uniqueidentifier = NULL
as
	BEGIN TRAN

		IF NOT EXISTS(SELECT Template_Guid FROM Template WHERE Template_Guid = @ProjectGuid)
		BEGIN
			INSERT INTO Template(Business_Unit_Guid, Name, Template_Guid, 
				Template_Type_Id, Supplier_Guid, Content_Bookmark, Template_Version)
			VALUES (@BusinessUnitGuid, @Name, @ProjectGuid, 
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

--1918
ALTER procedure [dbo].[spProject_RestoreVersion]
	@ProjectGuid uniqueidentifier,
	@VersionNumber int,
	@UserGuid uniqueidentifier
as
	SET NOCOUNT ON
		
	BEGIN TRAN	
	
		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Project_Definition)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,
			Template.Modified_By,
			Template.Project_Definition
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
			
		UPDATE Template
		SET	Project_Definition = (SELECT Project_Definition
				FROM Template_Version 
				WHERE Template_Guid = @ProjectGuid 
					AND Template_Version = @VersionNumber), 
			Template_Version = Template_Version + 1, 
			Modified_Date = GetUTCdate(),
			Modified_By = @UserGuid
		WHERE	Template_Guid = @ProjectGuid;
		
		DELETE FROM Template_File
		WHERE	Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File(Template_Guid, File_Guid, [Binary], FormatTypeId)
		SELECT	@ProjectGuid, Template_File_Version.File_Guid, Template_File_Version.[Binary],
				Template_File_Version.FormatTypeId
		FROM	Template_File_Version 
		WHERE	Template_Guid = @ProjectGuid 
				AND Template_Version = @VersionNumber; 
				
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0) > 0)
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

ALTER procedure [dbo].[spProject_AddNewProjectVersion]
	@ProjectGuid uniqueidentifier
as
	BEGIN TRAN

		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Project_Definition)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,
			Template.Modified_By,
			Template.Project_Definition
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File_Version (Template_Guid, File_Guid, Template_Version, [Binary],
				FormatTypeId)
		SELECT	Template.Template_Guid, Template_File.File_Guid, Template.Template_Version, 
				Template_File.[Binary], Template_File.FormatTypeId
		FROM	Template
				INNER JOIN Template_File ON Template.Template_Guid = Template_File.Template_Guid
		WHERE	Template.Template_Guid = @ProjectGuid;
		
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0) > 0)
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
				
		DELETE FROM Template_File_Version
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	Template_Version
					WHERE	Template_Guid = @ProjectGuid);
	COMMIT
GO

--1919
ALTER procedure [dbo].[spProject_GetProjectsByContentDefinition]
	@ContentGuid varchar(40),
	@BusinessUnitGuid uniqueidentifier
as
	SET ARITHABORT ON 

	SELECT 	Template.template_id, 
			Template.[name] as project_name, 
			Template.template_type_id, 
			Template.fax_template_id, 
			Template.template_guid, 
			Template.template_version, 
			Template.import_date,
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

ALTER procedure [dbo].[spProject_GetProjectsByContentItem]
	@ContentGuid varchar(40),
	@BusinessUnitGuid uniqueidentifier
as
	SET ARITHABORT ON 

	SELECT 	Template.template_id, 
			Template.[name] as project_name, 
			Template.template_type_id, 
			Template.fax_template_id, 
			Template.template_guid, 
			Template.template_version, 
			Template.import_date,
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

ALTER procedure [dbo].[spProject_ProjectList]
	@UserGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ProjectTypeId int,
	@SearchString nvarchar(100)
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
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
		ORDER BY a.[name];
	end
	else
	begin
		--specific user group
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, a.template_version, a.import_date, 
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
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
		ORDER BY a.[name];
	end
GO

ALTER procedure [dbo].[spProject_UpdateProject]
	@BusinessUnitGuid uniqueidentifier,
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
			INSERT INTO Template(Business_Unit_Guid, Name, Template_Guid, 
				Template_Type_Id, Supplier_Guid, Content_Bookmark, Template_Version)
			VALUES (@BusinessUnitGuid, @Name, @ProjectGuid, 
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

ALTER PROCEDURE [dbo].[spProjectGroup_FolderListAll]
	@UserGuid uniqueidentifier,
	@FolderSearch nvarchar(50),
	@ProjectSearch nvarchar(100)
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid;
	
	SELECT	DISTINCT a.*, d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, b.Template_ID, b.[Name] as Template_Name, 
			b.Template_Type_ID, d.Template_Group_Guid
	FROM	Folder a
			INNER JOIN Folder_Template c on a.Folder_ID = c.Folder_ID
			INNER JOIN Template_Group d on c.folderitem_ID = d.Template_Group_ID and itemtype_id = 1
			INNER JOIN Template_Group_Item e on d.Template_Group_ID = e.Template_Group_ID
			INNER JOIN Template b on e.Template_ID = b.Template_ID
	WHERE	a.Business_Unit_GUID = @BusinessUnitGUID
			AND a.Folder_Guid IN (
				SELECT	Folder_Group.FolderGuid
				FROM	Folder_Group
						INNER JOIN User_Group ON Folder_Group.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Subscription ON User_Group.User_Group_Id = User_Group_Subscription.User_Group_Id
						INNER JOIN Intelledox_User ON User_Group_Subscription.User_Id = Intelledox_User.User_Id
				WHERE	Intelledox_User.User_Guid = @UserGuid
				)
			AND a.Folder_Name LIKE @FolderSearch + '%'
			AND CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END LIKE @ProjectSearch + '%'
	ORDER BY a.Folder_Name, a.Folder_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END;
GO

ALTER PROCEDURE [dbo].[spProjectGroup_Recent]
	@UserGuid uniqueidentifier,
	@ProjectSearch nvarchar(100)
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid;
	
	SELECT	DISTINCT d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, b.Template_ID, b.[Name] as Template_Name, 
			b.Template_Type_ID, d.Template_Group_Guid, l.DateTime_Start
	FROM	Folder a
			INNER JOIN Folder_Template c on a.Folder_ID = c.Folder_ID
			INNER JOIN Template_Group d on c.folderitem_ID = d.Template_Group_ID and itemtype_id = 1
			INNER JOIN Template_Group_Item e on d.Template_Group_Guid = e.Template_Group_Guid
			INNER JOIN Template b on e.Template_Guid = b.Template_Guid
			INNER JOIN Template_Recent l on d.Template_Group_Guid = l.Template_Group_Guid
	WHERE	a.Business_Unit_GUID = @BusinessUnitGUID
			AND a.Folder_Guid IN (
				SELECT	Folder_Group.FolderGuid
				FROM	Folder_Group
						INNER JOIN User_Group ON Folder_Group.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Subscription ON User_Group.User_Group_Id = User_Group_Subscription.User_Group_Id
						INNER JOIN Intelledox_User ON User_Group_Subscription.User_Id = Intelledox_User.User_Id
				WHERE	Intelledox_User.User_Guid = @UserGuid
				)
			AND CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END LIKE @ProjectSearch + '%'
			AND l.[User_Guid] = @UserGuid
	ORDER BY l.DateTime_Start DESC;
GO

ALTER PROCEDURE [dbo].[spProjectGrp_ProjectGroupListByFolder]
	@FolderGuid uniqueidentifier
AS
	SELECT	d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, d.Template_Group_Guid,
			b.Template_Guid, e.Layout_Guid
	FROM	Folder a
			INNER JOIN Folder_Template c on a.Folder_ID = c.Folder_ID
			INNER JOIN Template_Group d on c.folderitem_ID = d.Template_Group_ID and itemtype_id = 1
			INNER JOIN Template_Group_Item e on d.Template_Group_ID = e.Template_Group_ID
			INNER JOIN Template b on e.Template_ID = b.Template_ID
	WHERE	a.Folder_Guid = @FolderGuid
	ORDER BY d.[Name], b.[Name], c.folderitem_id;
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
		WHERE	Template_Guid = @TemplateGuid;
	END

	IF @TemplateID = 0 
		SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, b.Category_ID, 
				b.[Name] as Category_Name, a.Supplier_Guid, a.Business_Unit_Guid,
				a.Content_Bookmark, a.HelpText, a.Modified_Date, Intelledox_User.Username, 
				a.[name] as Project_Name
		FROM	Template a
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		ORDER BY a.[Name];
	ELSE
		SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, b.Category_ID, 
				b.[Name] as Category_Name, a.Supplier_Guid, a.Business_Unit_Guid,
				a.Content_Bookmark, a.HelpText, a.Modified_Date, Intelledox_User.Username,
				a.[name] as Project_Name
		FROM	Template a
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		WHERE	a.template_id = @TemplateID
		ORDER BY a.[Name];

	set @ErrorCode = @@error;
GO

ALTER procedure [dbo].[spTemplate_TemplateListByFilter]
	@UserID int,
	@TemplateID int = 0,
	@TemplateTypeID int = 0,
	@CategoryID int = 0,
	@UserGroupID int = 0,
	@FormatTypeID int = 0,
	@BusinessUnitGUID uniqueidentifier,
	@SearchString nvarchar(100),
	@ErrorCode int output
as
/*
Vers	Date		Developer	Description
-------------------------------------------------------------------------------------------------------------
3.3.0	17/01/2005	Chrisg		created to support filtered template view
4.0.0	14/06/2005	Chrisg		returns Store_Xml field for web
4.0.1	14/07/2005	Chrisg		Returns new version and import date fields
4.1.8	04/10/2005	chrisg		No longer loads template_xml field to reduce load times.
4.6.0	18/12/2006	Chrisg		support for formattypeid and store_xml changed to web_template
4.6.1	16/01/2007	Chrisg		formattypeid can now be used as a filter
-------------------------------------------------------------------------------------------------------------
*/
	declare @IsGlobal bit

	--select @IsGlobal = a.globaltemplate
	--from administrator_level a
	--inner join Intelledox_User b on a.adminlevel_id = b.adminlevel_id and b.[user_id] = @UserID

	IF EXISTS(SELECT	Administrator_Level.*
		FROM	Administrator_Level
				INNER JOIN Role_Permission ON Administrator_Level.RoleGuid = Role_Permission.RoleGuid
				INNER JOIN User_Role ON Administrator_Level.RoleGuid = User_Role.RoleGuid
				INNER JOIN Intelledox_User ON User_Role.UserGuid = Intelledox_User.User_Guid
		WHERE	Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' --Manage Templates
				AND User_Role.GroupGuid IS NULL
				AND Intelledox_User.[User_ID] = @UserID)
	BEGIN
		SET @IsGlobal = 1;
	END

	IF @TemplateID = 0 
	begin
		if @UserGroupID = -1	--all usergroups
		begin
			SELECT 	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, a.template_guid,
				b.Category_ID, b.[Name] as Category_Name, a.template_version, a.import_date
			FROM	Template a
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
			WHERE (@TemplateTypeID = 0 or @TemplateTypeID = a.Template_Type_ID)
				and (@CategoryID = 0 or @CategoryID = c.Category_ID)
				and (@FormatTypeID = 0 or @FormatTypeID = a.FormatTypeID)
				and (@IsGlobal = 1 or a.template_id in (
					SELECT	User_Group_Template.Template_ID
					FROM	Role_Permission
							INNER JOIN User_Role ON Role_Permission.RoleGuid = User_Role.RoleGuid
							INNER JOIN Intelledox_User ON User_Role.UserGuid = Intelledox_User.User_Guid
							INNER JOIN User_Group_Subscription ON Intelledox_User.[User_ID] = User_Group_Subscription.[User_ID] 
							INNER JOIN User_Group ON User_Role.GroupGuid = User_Group.Group_Guid
							INNER JOIN User_Group_Template ON User_Group_Subscription.User_Group_Id = User_Group_Template.User_Group_Id 
					WHERE	Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' --Manage Templates
				AND Intelledox_User.[User_ID] = @UserID
					))
				AND (a.Business_Unit_GUID = @BusinessUnitGUID) 
				AND a.Name LIKE @SearchString + '%'
			ORDER BY a.[name];
		end
		else
		begin
			if @UserGroupID = 0	--global only
				SELECT 	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, a.template_guid, 
					b.Category_ID, b.[Name] as Category_Name, a.template_version, a.import_date
				FROM	Template a
					left join Template_Category c on a.Template_ID = c.Template_ID
					left join Category b on c.Category_ID = b.Category_ID
				WHERE (@TemplateTypeID = 0 or @TemplateTypeID = a.Template_Type_ID)
					and (@CategoryID = 0 or @CategoryID = c.Category_ID)
					and (@FormatTypeID = 0 or @FormatTypeID = a.FormatTypeID)
					and a.template_id not in (
						select template_id from user_group_template
					)
					and (@IsGlobal = 1)
					and (a.Business_Unit_GUID = @BusinessUnitGUID) 
					AND a.Name LIKE '%' + @SearchString + '%'
				ORDER BY a.[name];
			else	--specific user group
				SELECT 	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, a.template_guid, 
					b.Category_ID, b.[Name] as Category_Name, a.template_version, a.import_date
				FROM	Template a
					left join Template_Category c on a.Template_ID = c.Template_ID
					left join Category b on c.Category_ID = b.Category_ID
					inner join User_Group_Template d on a.Template_ID = d.Template_ID and d.User_Group_ID = @UserGroupID
				WHERE (@TemplateTypeID = 0 or @TemplateTypeID = a.Template_Type_ID)
					and (@CategoryID = 0 or @CategoryID = c.Category_ID)
					and (@FormatTypeID = 0 or @FormatTypeID = a.FormatTypeID)
					and (@IsGlobal = 1 or a.template_id in (
						SELECT	User_Group_Template.Template_ID
						FROM	Role_Permission
								INNER JOIN User_Role ON Role_Permission.RoleGuid = User_Role.RoleGuid
								INNER JOIN Intelledox_User ON User_Role.UserGuid = Intelledox_User.User_Guid
								INNER JOIN User_Group_Subscription ON Intelledox_User.[User_ID] = User_Group_Subscription.[User_ID] 
								INNER JOIN User_Group ON User_Role.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Template ON User_Group_Subscription.User_Group_Id = User_Group_Template.User_Group_Id 
						WHERE	Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' --Manage Templates
					))
					and (a.Business_Unit_GUID = @BusinessUnitGUID) 
					AND a.Name LIKE @SearchString + '%'
				ORDER BY a.[name];
		end
	end
	ELSE
	begin
		SELECT a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, a.template_guid, 
				b.Category_ID, b.[Name] as Category_Name, a.template_version, a.import_date
		FROM	Template a
			left join Template_Category c on a.Template_ID = c.Template_ID
			left join Category b on c.Category_ID = b.Category_ID
		WHERE a.template_id = @TemplateID
			and (@IsGlobal = 1 or a.template_id in (
					SELECT	User_Group_Template.Template_ID
					FROM	Role_Permission
							INNER JOIN User_Role ON Role_Permission.RoleGuid = User_Role.RoleGuid
							INNER JOIN Intelledox_User ON User_Role.UserGuid = Intelledox_User.User_Guid
							INNER JOIN User_Group_Subscription ON Intelledox_User.[User_ID] = User_Group_Subscription.[User_ID] 
							INNER JOIN User_Group ON User_Role.GroupGuid = User_Group.Group_Guid
							INNER JOIN User_Group_Template ON User_Group_Subscription.User_Group_Id = User_Group_Template.User_Group_Id 
					WHERE	Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' --Manage Templates
			))
		ORDER BY a.[name];
	end

	set @ErrorCode = @@error;
GO

DROP PROCEDURE [dbo].[spTemplateGrp_InsertTemplate]
GO

DROP PROCEDURE [dbo].[spTemplateGrp_UpdateTemplate]
GO

ALTER TABLE Template
DROP COLUMN FormatTypeId
GO

--1920
SELECT
  CASE FormatTypeId
         WHEN 1 THEN '.doc'
          WHEN 3 THEN '.docx'
          WHEN 4 THEN '.docm'
          ELSE ''
        END
        AS FormatType,
  Template_Guid AS TemplateGuid,
  File_Guid As FileGuid
INTO #FormatType
FROM Template_File

ALTER TABLE Template_File
ALTER COLUMN FormatTypeId varchar(6)

UPDATE Template_File
SET FormatTypeId = 
	(SELECT FormatType FROM #FormatType
	WHERE #FormatType.TemplateGuid = Template_File.Template_Guid
		AND #FormatType.FileGuid = Template_File.File_Guid)

DROP TABLE #FormatType
GO

SELECT
  CASE FormatTypeId
         WHEN 1 THEN '.doc'
          WHEN 3 THEN '.docx'
          WHEN 4 THEN '.docm'
          ELSE ''
        END
        AS FormatType,
  Template_Guid AS TemplateGuid,
  File_Guid As FileGuid,
  Template_Version As Template_Version
INTO #FormatType
FROM Template_File_Version

ALTER TABLE Template_File_Version
ALTER COLUMN FormatTypeId varchar(6)

UPDATE Template_File_Version
SET FormatTypeId = 
	(SELECT FormatType FROM #FormatType
	WHERE #FormatType.TemplateGuid = Template_File_Version.Template_Guid
		AND #FormatType.FileGuid = Template_File_Version.File_Guid
		AND #FormatType.Template_Version = Template_File_Version.Template_Version)

DROP TABLE #FormatType
GO

--1921
ALTER PROCEDURE [dbo].[spProject_UpdateBinary] (
	@Bytes image,
	@TemplateGuid uniqueidentifier,
	@FileGuid uniqueidentifier,
	@FormatType varchar(6)
)
AS
	IF EXISTS(SELECT File_Guid FROM Template_File WHERE Template_Guid = @TemplateGuid AND File_Guid = @FileGuid)
	BEGIN
		UPDATE	Template_File
		SET		[Binary] = @Bytes,
				FormatTypeId = @FormatType
		WHERE	Template_Guid = @TemplateGuid
				AND File_Guid = @FileGuid;
	END
	ELSE
	BEGIN
		INSERT INTO Template_File(Template_Guid, File_Guid, [Binary], FormatTypeId)
		VALUES (@TemplateGuid, @FileGuid, @Bytes, @FormatType);
	END
GO


