truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.4.0');
go

UPDATE Template
SET Modified_Date = cast('2000-1-1' as datetime)
WHERE Modified_Date IS NULL
GO

UPDATE Template_Version
SET Modified_Date = cast('2000-1-1' as datetime)
WHERE Modified_Date IS NULL
GO

UPDATE [ContentData_Binary]
SET Modified_Date = cast('2000-1-1' as datetime)
WHERE Modified_Date IS NULL
GO

UPDATE ContentData_Binary_Version
SET Modified_Date = cast('2000-1-1' as datetime)
WHERE Modified_Date IS NULL
GO

UPDATE [ContentData_Text]
SET Modified_Date = cast('2000-1-1' as datetime)
WHERE Modified_Date IS NULL
GO

UPDATE ContentData_Text_Version
SET Modified_Date = cast('2000-1-1' as datetime)
WHERE Modified_Date IS NULL
GO

CREATE VIEW dbo.vwUserAI
AS
	SELECT u.Business_Unit_GUID as BusinessUnitGuid,
			u.User_Guid as UserGuid,
			u.IsGuest,
			u.Username COLLATE Latin1_General_CI_AI as Username,
			ud.First_Name COLLATE Latin1_General_CI_AI as FirstName,
			ud.Last_Name COLLATE Latin1_General_CI_AI as LastName
	FROM Intelledox_User u
		LEFT JOIN Address_Book ud ON u.Address_ID = ud.Address_ID
	WHERE u.Disabled = 0;
GO
CREATE VIEW dbo.vwProjectAI
AS
	SELECT	p.Business_Unit_GUID as BusinessUnitGuid,
			p.Template_Guid as ProjectGuid,
			p.Name COLLATE Latin1_General_CI_AI as Name
	FROM	Template p
GO
CREATE VIEW dbo.vwUserGroupSubscriptionAI
AS
	SELECT	ugs.*
	FROM	User_Group_Subscription ugs
GO
ALTER PROCEDURE [dbo].[spUsers_UserGroupByUser]
	@UserID int,
	@BusinessUnitGUID uniqueidentifier,
	@Username nvarchar(50) = '',
	@UserGroupID int = 0,
	@UserGuid uniqueidentifier = null,
	@ShowActive int = 0,
	@ErrorCode int = 0 output,
	@Firstname nvarchar(50) = '',
	@Lastname nvarchar(50) = ''
AS
BEGIN
	if @UserGroupID = 0	--all user groups
	begin
		if @UserGuid is null
		begin
			if @UserID is null or @UserID = 0
			begin
				select	a.*, Business_Unit.DefaultLanguage
				from	Intelledox_User a
					left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
					left join Address_Book d on a.Address_ID = d.Address_ID
				where	(@Username = '' OR @Username is null OR a.[Username] COLLATE Latin1_General_CI_AI like (@Username + '%') COLLATE Latin1_General_CI_AI)
					AND (@Firstname = '' OR @Firstname is null OR d.[First_Name] COLLATE Latin1_General_CI_AI like ('%' + @Firstname + '%') COLLATE Latin1_General_CI_AI)
					AND (@Lastname = '' or @Lastname is null or d.[Last_Name] COLLATE Latin1_General_CI_AI like ('%' + @Lastname + '%') COLLATE Latin1_General_CI_AI)
					AND (a.Business_Unit_GUID = @BusinessUnitGUID)
					AND (@ShowActive = 0 
						OR (@ShowActive = 1 AND a.[Disabled] = 0)
						OR (@ShowActive = 2 AND a.[Disabled] = 1))
				ORDER BY a.[Username]
			end
			else
			begin
				select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
				from	Intelledox_User a
					left join User_Group_Subscription c on a.User_Guid = c.UserGuid
					left join User_Group b on c.GroupGuid = b.Group_Guid
					left join Address_Book d on a.Address_Id = d.Address_id
					left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
				where	(a.[User_ID] = @UserID)
					AND (@ShowActive = 0 
						OR (@ShowActive = 1 AND a.[Disabled] = 0)
						OR (@ShowActive = 2 AND a.[Disabled] = 1))
				ORDER BY a.[Username]
			end
		end
		else
		begin
			select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
			from	Intelledox_User a
				left join User_Group_Subscription c on a.User_Guid = c.UserGuid
				left join User_Group b on c.GroupGuid = b.Group_Guid
				left join Address_Book d on a.Address_Id = d.Address_id
				left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			where	(User_Guid = @UserGuid)
				AND (@ShowActive = 0 
					OR (@ShowActive = 1 AND a.[Disabled] = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1))
			ORDER BY a.[Username]
		end
	end
	else
	begin
		if @UserGroupID = -1	--users with no user groups
		begin
			select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
			from	Intelledox_User a
				left join User_Group_Subscription c on a.User_Guid = c.UserGuid
				left join User_Group b on c.GroupGuid = b.Group_Guid
				left join Address_Book d on a.Address_Id = d.Address_id
				left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			where	(@UserID = 0 OR @UserID IS NULL OR a.[User_ID] = @UserID)
				AND	(@Username = '' OR @Username is null OR a.[Username] COLLATE Latin1_General_CI_AI like (@Username + '%') COLLATE Latin1_General_CI_AI)
				AND (@Firstname = '' OR @Firstname is null OR d.[First_Name] COLLATE Latin1_General_CI_AI like ('%' + @Firstname + '%') COLLATE Latin1_General_CI_AI)
				AND (@Lastname = '' or @Lastname is null or d.[Last_Name] COLLATE Latin1_General_CI_AI like ('%' + @Lastname + '%') COLLATE Latin1_General_CI_AI)
				AND	a.User_Guid not in (
						select a.userGuid
						from user_group_subscription a 
						inner join user_Group b on a.GroupGuid = b.Group_Guid
					)
				AND (a.Business_Unit_GUID = @BusinessUnitGUID)
				AND (@ShowActive = 0 
					OR (@ShowActive = 1 AND a.[Disabled] = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1))
			ORDER BY a.[Username]
		end
		else			--users in specified user group
		begin
			select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
			from	Intelledox_User a
				left join User_Group_Subscription c on a.User_Guid = c.UserGuid
				left join User_Group b on c.GroupGuid = b.Group_Guid
				left join Address_Book d on a.Address_Id = d.Address_id
				left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			where	(@UserID = 0 OR @UserID IS NULL OR a.[User_ID] = @UserID)
				AND	(@Username = '' OR @Username is null OR a.[Username] COLLATE Latin1_General_CI_AI like (@Username + '%') COLLATE Latin1_General_CI_AI)
				AND (@Firstname = '' OR @Firstname is null OR d.[First_Name] COLLATE Latin1_General_CI_AI like ('%' + @Firstname + '%') COLLATE Latin1_General_CI_AI)
				AND (@Lastname = '' or @Lastname is null or d.[Last_Name] COLLATE Latin1_General_CI_AI like ('%' + @Lastname + '%') COLLATE Latin1_General_CI_AI)
				AND	c.GroupGuid = (SELECT Group_Guid FROM User_Group WHERE User_Group_id = @UserGroupID)
				AND (a.Business_Unit_GUID = @BusinessUnitGUID)
				AND (@ShowActive = 0 
					OR (@ShowActive = 1 AND a.[Disabled] = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1))
			ORDER BY a.[Username]
		end
	end

	set @ErrorCode = @@error;

END
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
			AND a.Name COLLATE Latin1_General_CI_AI LIKE (@SearchString + '%') COLLATE Latin1_General_CI_AI
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
			AND a.Name COLLATE Latin1_General_CI_AI LIKE (@SearchString + '%') COLLATE Latin1_General_CI_AI
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
			AND a.Name COLLATE Latin1_General_CI_AI LIKE (@SearchString + '%') COLLATE Latin1_General_CI_AI
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
			AND a.Name COLLATE Latin1_General_CI_AI LIKE (@SearchString + '%') COLLATE Latin1_General_CI_AI
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
			AND (a.Template_Guid IN (
					SELECT	Template_Guid
					FROM	Template_File tf
					WHERE	Contains(*, @FullText)
				))
		ORDER BY a.[name];
	end

GO
ALTER procedure [dbo].[spContent_ContentItemList]
	@ItemGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier,
	@ExactMatch bit,
	@ContentTypeId int,
	@Name NVarChar(255),
	@Description NVarChar(1000),
	@Category int,
	@Approved int = 2,
	@ErrorCode int output,
	@FolderGuid uniqueidentifier,
	@UserId uniqueidentifier,
	@NoFolder bit,
	@MinimalGet bit
as
	IF @ItemGuid is null 
	BEGIN
		UPDATE Content_Item
		SET Approved = 1
		WHERE ExpiryDate < GETDATE()
			AND Approved = 0;
		
		IF @ExactMatch = 1
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
								INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit,
					ci.FolderGuid,
					Content_Folder.FolderName
					
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity = @Name
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
			ORDER BY ci.NameIdentity;
		ELSE
			SELECT DISTINCT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
								INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit,
					ci.FolderGuid,
					Content_Folder.FolderName
					
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
						
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity COLLATE Latin1_General_CI_AI LIKE ('%' + @Name + '%') COLLATE Latin1_General_CI_AI
					AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND ci.Description COLLATE Latin1_General_CI_AI LIKE ('%' + @Description + '%') COLLATE Latin1_General_CI_AI
					AND (@Category = 0 or ci.Category = @Category)
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
					AND ((@NoFolder = 0 AND (@FolderGuid IS NULL OR ci.FolderGuid = @FolderGuid))
						OR (@NoFolder = 1 AND ci.FolderGuid IS NULL))
			ORDER BY ci.ContentType_Id,
					ci.NameIdentity;
	END
	ELSE
	BEGIN
		UPDATE	Content_Item
		SET		Approved = 1
		WHERE	ExpiryDate < GETDATE()
				AND Approved = 0
				AND contentitem_guid = @ItemGuid;
		
		IF (@MinimalGet = 1)
		BEGIN
			SELECT	ci.*, 
					'' as FileType, 
					NULL as Modified_Date, 
					'' as UserName,
					0 as HasUnapprovedRevision,
					0 as CanEdit,
					Content_Folder.FolderName						
			FROM	content_item ci
				LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
			WHERE	ci.contentitem_guid = @ItemGuid;
		END
		ELSE
		BEGIN
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
								INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit,
					Content_Folder.FolderName
						
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
						
			WHERE	ci.contentitem_guid = @ItemGuid;
		END
	END
	
	set @ErrorCode = @@error;
GO
ALTER procedure [dbo].[spContent_ContentItemListBySearch]
	@BusinessUnitGuid uniqueidentifier,
	@SearchString NVarChar(1000),
	@ContentTypeId Int,
	@FolderGuid uniqueidentifier
	
AS
	IF @SearchString IS NULL OR @SearchString = ''
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Intelledox_User.UserName,
				0 as HasUnapprovedRevision,
				0 AS CanEdit,
				Content_Folder.FolderName
		FROM	content_item ci
				LEFT JOIN (
					SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
					FROM	ContentData_Binary
					UNION
					SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
					FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
				LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
		WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
				AND ci.Approved = 2
				AND ci.ContentType_Id = @ContentTypeId
					--Search all folders/none folder/specific folder
				AND (
					@FolderGuid = '00000000-0000-0000-0000-000000000000' --all
					OR (@FolderGuid = '99999999-9999-9999-9999-999999999999'  AND ci.FolderGuid IS NULL) --none
					OR ci.FolderGuid = @FolderGuid --a specific folder
					)
		ORDER BY ci.NameIdentity;
ELSE
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Intelledox_User.UserName,
				0 as HasUnapprovedRevision,
				0 AS CanEdit,
				Content_Folder.FolderName
		FROM	content_item ci
				LEFT JOIN (
					SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
					FROM	ContentData_Binary
					UNION
					SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
					FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
				LEFT JOIN Category ON ci.Category = Category.Category_ID
				LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
		WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
				AND ci.Approved = 2
				AND ci.ContentType_Id = @ContentTypeId
				AND (ci.NameIdentity COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchString + '%') COLLATE Latin1_General_CI_AI
					OR ci.Description COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchString + '%') COLLATE Latin1_General_CI_AI
					OR Category.Name COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchString + '%') COLLATE Latin1_General_CI_AI
					)
					--Search all folders/none folder/specific folder
				AND (
					@FolderGuid = '00000000-0000-0000-0000-000000000000' --all
					OR (@FolderGuid = '99999999-9999-9999-9999-999999999999'  AND ci.FolderGuid IS NULL) --none
					OR ci.FolderGuid = @FolderGuid --a specific folder
					)
		ORDER BY ci.NameIdentity;
GO
ALTER procedure [dbo].[spContent_ContentItemListBySearchFullText]
	@BusinessUnitGuid uniqueidentifier,
	@SearchString NVarChar(1000),
	@FullTextSearchString NVarChar(1000),
	@ContentTypeId Int,
	@FolderGuid uniqueidentifier
AS
	SELECT	ci.*, 
			Content.FileType, 
			Content.Modified_Date, 
			Intelledox_User.UserName,
			0 as HasUnapprovedRevision,
			0 AS CanEdit,
			Content_Folder.FolderName
	FROM	content_item ci
			LEFT JOIN (
				SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
				FROM	ContentData_Binary
				UNION
				SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
				FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
			LEFT JOIN Category ON ci.Category = Category.Category_ID
			LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
			LEFT JOIN FREETEXTTABLE(ContentData_Binary, *, @FullTextSearchString) as Ftt
				ON ci.ContentData_Guid = Ftt.[Key]
	WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
			AND ci.Approved = 2
			AND ci.ContentType_Id = @ContentTypeId
			AND (ci.NameIdentity COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchString + '%') COLLATE Latin1_General_CI_AI
				OR ci.Description COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchString + '%') COLLATE Latin1_General_CI_AI
				OR Category.Name COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchString + '%') COLLATE Latin1_General_CI_AI
				OR (ci.ContentData_Guid IN (
						SELECT	ContentData_Guid
						FROM	ContentData_Binary cdb
						WHERE	Contains(*, @FullTextSearchString)
						)
					OR
					ci.ContentData_Guid IN (
						SELECT	ContentData_Guid
						FROM	ContentData_Text cdt
						WHERE	Contains(*, @FullTextSearchString)
						)
					)
				)
				--Search all folders/none folder/specific folder
			AND (
				@FolderGuid = '00000000-0000-0000-0000-000000000000' --all
				OR @FolderGuid = '99999999-9999-9999-9999-999999999999'  AND ci.FolderGuid IS NULL --none
				OR ci.FolderGuid = @FolderGuid --a specific folder
				)
	ORDER BY Ftt.Rank DESC, ci.NameIdentity;
GO
ALTER procedure [dbo].[spContent_ContentItemListFullText]
	@ItemGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier,
	@ExactMatch bit,
	@ContentTypeId int,
	@Name NVarChar(255),
	@Description NVarChar(1000),
	@Category int,
	@FullText NVarChar(1000),
	@Approved int = 2,
	@ErrorCode int output,
	@FolderGuid uniqueidentifier,
	@UserId uniqueidentifier,
	@NoFolder bit
as

	UPDATE Content_Item
	SET Approved = 1
	WHERE ExpiryDate < GETDATE()
		AND Approved = 0;

	IF @ItemGuid is null 
		IF @ExactMatch = 1
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
								INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit,
					Content_Folder.FolderName
					
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity = @Name
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
			ORDER BY ci.NameIdentity;
		ELSE
			--Full text search
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
								INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit,
					Content_Folder.FolderName
					
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity COLLATE Latin1_General_CI_AI LIKE ('%' + @Name + '%') COLLATE Latin1_General_CI_AI
					AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND ci.Description COLLATE Latin1_General_CI_AI LIKE ('%' + @Description + '%') COLLATE Latin1_General_CI_AI
					AND (@Category = 0 or ci.Category = @Category)
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
					AND (ci.ContentData_Guid IN (
							SELECT	ContentData_Guid
							FROM	ContentData_Binary cdb
							WHERE	Contains(*, @FullText)
							)
						OR
						ci.ContentData_Guid IN (
							SELECT	ContentData_Guid
							FROM	ContentData_Text cdt
							WHERE	Contains(*, @FullText)
							)
						)
					AND ((@NoFolder = 0 AND (@FolderGuid IS NULL OR ci.FolderGuid = @FolderGuid))
						OR (@NoFolder = 1 AND ci.FolderGuid IS NULL))
			ORDER BY ci.NameIdentity;
	ELSE
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Intelledox_User.UserName,
				CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
				CASE WHEN (@UserId IS NULL 
					OR ci.FolderGuid IS NULL 
					OR (NOT EXISTS (
						SELECT * 
						FROM Content_Folder_Group 
						WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
					OR EXISTS (
						SELECT * 
						FROM Content_Folder_Group
							INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
							INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
							INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
						WHERE Intelledox_User.User_Guid = @UserId
							AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
				THEN 1 ELSE 0 END
				AS CanEdit,
				Content_Folder.FolderName
					
		FROM	content_item ci
				LEFT JOIN (
					SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
					FROM	ContentData_Binary
					UNION
					SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
					FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
				LEFT JOIN (
					SELECT	ContentData_Guid
					FROM	vwContentItemVersionDetails
					WHERE	Approved = 0
					) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
				LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
		WHERE	ci.contentitem_guid = @ItemGuid;
	
	set @ErrorCode = @@error;

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
			AND f.Folder_Name COLLATE Latin1_General_CI_AI LIKE (@FolderSearch + '%') COLLATE Latin1_General_CI_AI
			AND t.Name COLLATE Latin1_General_CI_AI LIKE (@ProjectSearch + '%') COLLATE Latin1_General_CI_AI
			AND (tg.EnforcePublishPeriod = 0 
				OR ((tg.PublishStartDate IS NULL OR tg.PublishStartDate < getdate())
					AND (tg.PublishFinishDate IS NULL OR tg.PublishFinishDate > getdate())))
GO

ALTER PROCEDURE [dbo].[spProject_DefinitionsByGroup] (
	@TemplateGroupGuid uniqueidentifier,
	@PublishedBy datetime
)
AS

		SELECT	Template.Template_Guid, 
			Template.Template_Type_ID,
			Template.Template_Version, 
			CASE WHEN Template.EncryptedProjectDefinition IS NULL THEN 0 ELSE 1 END AS Encrypted,
			Template.EncryptedProjectDefinition,
			Template.Project_Definition
		FROM	Template_Group
				INNER JOIN Template ON (Template_Group.Template_Guid = Template.Template_Guid 
						AND (Template_Group.Template_Version IS NULL
							OR Template_Group.Template_Version = Template.Template_Version))
					OR (Template_Group.Layout_Guid = Template.Template_Guid
						AND (Template_Group.Layout_Version IS NULL
							OR Template_Group.Layout_Version = Template.Template_Version))
		WHERE	Template_Group.Template_Group_Guid = @TemplateGroupGuid
			AND (Template_Group.MatchProjectVersion = 0 
				OR Template.Modified_Date <= @PublishedBy)
	UNION ALL
		SELECT	Template_Version.Template_Guid, 
			Template.Template_Type_ID,
			Template_Version.Template_Version, 
			CASE WHEN Template_Version.EncryptedProjectDefinition IS NULL THEN 0 ELSE 1 END AS Encrypted,
			Template_Version.EncryptedProjectDefinition,
			Template_Version.Project_Definition
		FROM	Template_Group
				INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
				INNER JOIN Template_Version ON (Template_Group.Template_Guid = Template_Version.Template_Guid 
						AND Template_Group.Template_Version = Template_Version.Template_Version
						AND Template_Group.MatchProjectVersion = 0)
					OR (Template_Group.Layout_Guid = Template_Version.Template_Guid
						AND Template_Group.Layout_Version = Template_Version.Template_Version
						AND Template_Group.MatchProjectVersion = 0)
					OR (Template_Group.MatchProjectVersion = 1 
						AND ((Template_Group.Template_Guid = Template_Version.Template_Guid
								OR Template_Group.Layout_Guid = Template_Version.Template_Guid)
							AND Template.Modified_Date > @PublishedBy
							AND Template_Version.Modified_Date = (SELECT TOP 1 VersionDate.Modified_Date
								FROM Template_Version VersionDate
								WHERE VersionDate.Template_Guid = Template.Template_Guid
									AND VersionDate.Modified_Date <= @PublishedBy
								ORDER BY VersionDate.Modified_Date DESC)))
		WHERE	Template_Group.Template_Group_Guid = @TemplateGroupGuid
	ORDER BY Template_Type_ID;
GO

ALTER procedure [dbo].[spProject_AddNewProjectVersion]
	@ProjectGuid uniqueidentifier,
	@NextVersion nvarchar(10)
AS
	BEGIN TRAN

		SET NOCOUNT ON

		DECLARE @BusinessUnitGuid uniqueidentifier;

		SELECT TOP 1 @BusinessUnitGuid = Business_Unit_Guid 
		FROM Template
		WHERE Template_Guid = @ProjectGuid;

		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Project_Definition,
			Comment,
			IsMajorVersion,
			FeatureFlags,
			EncryptedProjectDefinition)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,
			Template.Modified_By,
			Template.Project_Definition,
			Template.Comment,
			Template.IsMajorVersion,
			Template.FeatureFlags,
			Template.EncryptedProjectDefinition
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File_Version (Template_Guid, File_Guid, Template_Version, [Binary],
				FormatTypeId)
		SELECT	Template.Template_Guid, Template_File.File_Guid, Template.Template_Version, 
				Template_File.[Binary], Template_File.FormatTypeId
		FROM	Template
				INNER JOIN Template_File ON Template.Template_Guid = Template_File.Template_Guid
		WHERE	Template.Template_Guid = @ProjectGuid;
		
		IF (SELECT COUNT(*) 
			FROM Template_Group 
			WHERE (Template_Group.Layout_Guid = @ProjectGuid OR Template_Group.Template_Guid = @ProjectGuid)
				AND Template_Group.MatchProjectVersion = 1) = 0
		BEGIN
		
			--delete the earliest minor version which does not belong to the next version number
			WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
				(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
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
				(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
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
				(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
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
		END
	COMMIT
GO

CREATE PROCEDURE dbo.spProject_GetProjectVersionByPublishedBy
	@ProjectGuid uniqueidentifier, 
	@PublishedBy datetime
AS
BEGIN

    SELECT MAX(Versions.Template_Version)
    FROM (SELECT Template.Template_Version
			FROM Template
			WHERE Template.Template_Guid = @ProjectGuid
				AND Template.Modified_Date <= @PublishedBy
		UNION
			SELECT Template_Version.Template_Version
			FROM Template_Version
			WHERE Template_Version.Template_Guid = @ProjectGuid
				AND Template_Version.Modified_Date <= @PublishedBy) Versions
END
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
					Template.Name as Template_Name, Template_Group.Template_Group_Guid,
					ans.FirstLaunchTimeUtc, Template_Group.MatchProjectVersion
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
					T.Name as Template_Name,
					ans.FirstLaunchTimeUtc, Template_Group.MatchProjectVersion
			from	answer_file ans					
					INNER JOIN Template_Group on ans.Template_Group_Guid = Template_Group.Template_Group_Guid
					INNER JOIN Template AS T ON Template_Group.Template_Guid = T.Template_Guid
			where	Ans.[user_Guid] = @user_Guid
					AND Ans.Template_group_Guid = @TemplateGroupGuid
			order by [RunDate] desc;
    end
    else
    begin
        SELECT	Answer_File.*, Template_Group.MatchProjectVersion
		FROM	Answer_File
			INNER JOIN Template_Group ON Answer_File.Template_Group_Guid = Template_Group.Template_Group_Guid
        WHERE	Answer_File.AnswerFile_Id = @AnswerFile_Id
        ORDER BY Answer_File.[RunDate] desc;
    end
GO

CREATE PROCEDURE dbo.spProject_GetVersionModifiedDate
	@ProjectGuid uniqueidentifier,
	@Version varchar(10)
AS
BEGIN
		SELECT Template.Modified_Date
		FROM Template
		WHERE Template.Template_Version = @Version
			AND Template.Template_Guid = @ProjectGuid
	UNION
		SELECT Template_Version.Modified_Date
		FROM Template_Version
		WHERE Template_Version.Template_Version = @Version
			AND Template_Version.Template_Guid = @ProjectGuid
END
GO

ALTER procedure [dbo].[spAudit_UpdateAnswerFile]
	@AnswerFile_ID int,
	@AnswerFile_Guid uniqueidentifier,
	@User_Guid uniqueidentifier,
	@Template_Group_Guid uniqueidentifier,
	@Description nvarchar(255),
	@RunDate datetime,
	@UnencryptedAnswerString xml,
	@EncryptedAnswerString varbinary(MAX),
	@FirstLaunchTimeUtc datetime,
	@InProgress bit = 0,
	@NewID int output,
	@ErrorCode int output
AS
	set nocount on
	
	if ((@AnswerFile_ID = 0 OR @AnswerFile_ID IS NULL) AND @AnswerFile_Guid IS NOT NULL)
	begin
		 SELECT	@AnswerFile_ID = AnswerFile_ID 
		 FROM	Answer_File 
		 WHERE	AnswerFile_Guid = @AnswerFile_Guid
	end

	if (@AnswerFile_ID > 0)
	begin
		update Answer_File
		set [Description] = @Description,
			RunDate = @RunDate,
			AnswerString = @UnencryptedAnswerString,
			EncryptedAnswerString = @EncryptedAnswerString
		where AnswerFile_ID = @AnswerFile_ID;
	end
	else
	begin
		insert into Answer_File (AnswerFile_Guid, [User_Guid], [Template_Group_Guid], [Description], [RunDate], [AnswerString], [InProgress], [EncryptedAnswerString], FirstLaunchTimeUtc)
		values (@AnswerFile_Guid, @User_Guid, @Template_Group_Guid, @Description, @RunDate, @UnencryptedAnswerString, @InProgress, @EncryptedAnswerString, @FirstLaunchTimeUtc);

		select @NewID = @@Identity;
	end

	set @ErrorCode = @@Error;
GO

ALTER PROCEDURE [dbo].[spLibrary_GetText] (
	@UniqueId as uniqueidentifier,
	@VersionNumber as varchar(50),
	@PublishedBy As datetime
)
AS
	If @VersionNumber = '0'
	BEGIN
		SELECT	cd.ContentData as [Text] 
		FROM	ContentData_Text cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId
			AND cd.Modified_Date <= @PublishedBy
		UNION
		SELECT	cd.ContentData as [Text]
		FROM	ContentData_Text_Version cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
				INNER JOIN ContentData_Text ON ContentData_Text.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId
				AND ContentData_Text.Modified_Date > @PublishedBy
				AND cd.Modified_Date = 
					(SELECT MAX(LatestValidVersionText.Modified_Date)
					FROM ContentData_Text_Version LatestValidVersionText
						INNER JOIN Content_Item LatestValidVersion ON LatestValidVersion.ContentData_Guid = LatestValidVersionText.ContentData_Guid
					WHERE LatestValidVersion.ContentItem_Guid = @UniqueId
						AND LatestValidVersionText.Modified_Date <= @PublishedBy);
	END
	ELSE
	BEGIN
		SELECT	cd.ContentData as [Text] 
		FROM	ContentData_Text cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId
				AND cd.ContentData_Version = @VersionNumber
		UNION ALL
		SELECT	cd.ContentData as [Text] 
		FROM	ContentData_Text_Version cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId
				AND cd.ContentData_Version = @VersionNumber;
	END
GO

ALTER PROCEDURE [dbo].[spLibrary_GetBinary] (
	@UniqueId as uniqueidentifier,
	@VersionNumber as varchar(50),
	@PublishedBy as datetime
)
AS
	If @VersionNumber = '0'
	BEGIN
		SELECT	cd.ContentData as [Binary]
		FROM	ContentData_Binary cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId
			AND cd.Modified_Date <= @PublishedBy
		UNION
		SELECT	cd.ContentData as [Binary]
		FROM	ContentData_Binary_Version cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
				INNER JOIN ContentData_Binary ON ContentData_Binary.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId
				AND ContentData_Binary.Modified_Date > @PublishedBy
				AND cd.Modified_Date = 
					(SELECT MAX(LatestValidVersionBinary.Modified_Date)
					FROM ContentData_Binary_Version LatestValidVersionBinary
						INNER JOIN Content_Item LatestValidVersion ON LatestValidVersion.ContentData_Guid = LatestValidVersionBinary.ContentData_Guid
					WHERE LatestValidVersion.ContentItem_Guid = @UniqueId
						AND LatestValidVersionBinary.Modified_Date <= @PublishedBy);
	END
	ELSE
	BEGIN
		SELECT	cd.ContentData as [Binary]
		FROM	ContentData_Binary cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId
				AND cd.ContentData_Version = @VersionNumber
		UNION ALL
		SELECT	cd.ContentData as [Binary]
		FROM	ContentData_Binary_Version cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId
				AND cd.ContentData_Version = @VersionNumber;
	END
GO
