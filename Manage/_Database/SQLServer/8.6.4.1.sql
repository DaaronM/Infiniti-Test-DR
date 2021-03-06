truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.4.1');
go

ALTER PROCEDURE [dbo].[spLibrary_UpdateBinary] (
	@UniqueId as uniqueidentifier,
	@ContentData as image,
	@Extension as varchar(5),
	@UserGuid as uniqueidentifier
)
AS
	DECLARE @ContentData_Guid uniqueidentifier;
	DECLARE @ContentItem_Guid uniqueidentifier;
	DECLARE @BusinessUnitGuid uniqueidentifier;
	DECLARE @Approvals nvarchar(10);
	DECLARE @MaxVersion int;
	DECLARE @CIApproved int;

	SET NOCOUNT ON;

	SELECT	@ContentData_Guid = ContentData_Guid, 
			@ContentItem_Guid = ContentItem_Guid,
			@BusinessUnitGuid = Business_Unit_Guid,
			@CIApproved = Approved
	FROM	Content_Item
	WHERE	ContentItem_Guid = @UniqueId;
	
	SELECT	@Approvals = OptionValue
	FROM	Global_Options
	WHERE	OptionCode = 'REQUIRE_CONTENT_APPROVAL'
			AND BusinessUnitGuid = @BusinessUnitGuid;


	IF (@Approvals = 'true')
	BEGIN
		IF @ContentData_Guid IS NULL OR NOT EXISTS(SELECT ContentData_Guid 
												FROM ContentData_Binary 
												WHERE	ContentData_Guid = @ContentData_Guid)
		BEGIN
			SET	@ContentData_Guid = newid();
			
			INSERT INTO ContentData_Binary(ContentData_Guid, ContentData, FileType, ContentData_Version, Modified_Date, Modified_By)
			VALUES (@ContentData_Guid, @ContentData, @Extension, 1, getUTCdate(), @UserGuid);

			UPDATE	Content_Item
			SET		ContentData_Guid = @ContentData_Guid,
					Approved = 0
			WHERE	ContentItem_Guid = @UniqueId;
		END
		ELSE
		BEGIN
			IF (@CIApproved = 0)
			BEGIN
				-- Content item hasnt been approved yet so we can replace it
				EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 1, @UniqueId;
				
				UPDATE	ContentData_Binary
				SET		ContentData = @ContentData,
						FileType = @Extension,
						Modified_Date = getUTCdate(),
						Modified_By = @UserGuid,
						ContentData_Version = ContentData_Version + 1
				WHERE	ContentData_Guid = @ContentData_Guid;

				-- Expire old unapproved versions
				UPDATE	ContentData_Binary_Version
				SET		Approved = 1
				WHERE	ContentData_Guid = @ContentData_Guid
						AND Approved = 0;
			END
			ELSE
			BEGIN
				SELECT	@MaxVersion = MAX(ContentData_Version)
				FROM	(SELECT ContentData_Version
						FROM	ContentData_Binary_Version
						WHERE	ContentData_Guid = @ContentData_Guid
						UNION
						SELECT	ContentData_Version
						FROM	ContentData_Binary
						WHERE	ContentData_Guid = @ContentData_Guid) Versions

				-- Expire old unapproved versions
				UPDATE	ContentData_Binary_Version
				SET		Approved = 1
				WHERE	ContentData_Guid = @ContentData_Guid
						AND Approved = 0;
			
				-- Insert new unapproved version
				INSERT INTO ContentData_Binary_Version(ContentData_Guid, ContentData, FileType, ContentData_Version, Modified_Date, Modified_By, Approved)
				VALUES (@ContentData_Guid, @ContentData, @Extension, IsNull(@MaxVersion, 0) + 1, getUTCdate(), @UserGuid, 0);
			END
			
			-- ContentItem_Guid must be lower case for xml query
			DECLARE @LowerContentGuid varchar(40)
			SET @LowerContentGuid = LOWER(@UniqueId)
				
			IF (SELECT COUNT(*)
				FROM	Template
					INNER JOIN Template_Group ON Template_Group.Layout_Guid = Template.Template_Guid OR Template_Group.Template_Guid = Template.Template_Guid
				WHERE	Template_Group.MatchProjectVersion = 1
					AND Project_Definition.exist('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question/Answer/ContentItem[@Id = sql:variable("@LowerContentGuid")])[1]') = 1) = 0
			BEGIN
				EXEC spLibrary_ClearExcessVersions @ContentData_Guid, 0;
			END
			
		END
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT ContentData_Guid FROM ContentData_Binary WHERE ContentData_Guid = @ContentData_Guid)
		BEGIN
			EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 1, @UniqueId;
			
			UPDATE	ContentData_Binary
			SET		ContentData = @ContentData,
					FileType = @Extension
			WHERE	ContentData_Guid = @ContentData_Guid;
		END
		ELSE
		BEGIN
			IF @ContentItem_Guid IS NOT NULL
			BEGIN
				SET	@ContentData_Guid = newid();

				INSERT INTO ContentData_Binary(ContentData_Guid, ContentData, FileType, ContentData_Version)
				VALUES (@ContentData_Guid, @ContentData, @Extension, 0);

				UPDATE	Content_Item
				SET		ContentData_Guid = @ContentData_Guid
				WHERE	ContentItem_Guid = @UniqueId;
			END
		END
		
		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE	ContentData_Binary
			SET		Modified_Date = getUTCdate(),
					Modified_By = @UserGuid,
					ContentData_Version = ContentData_Version + 1
			WHERE	ContentData_Guid = @ContentData_Guid;
		END
	END

	DELETE	FROM Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItem_Guid;
	
	UPDATE	Content_Item
	SET		IsIndexed = 0
	WHERE	ContentItem_Guid = @ContentItem_Guid;
GO

ALTER PROCEDURE [dbo].[spLibrary_UpdateText] (
	@UniqueId as uniqueidentifier,
	@ContentData as nvarchar(max),
	@UserGuid as uniqueidentifier
)
AS
	DECLARE @ContentData_Guid uniqueidentifier;
	DECLARE @BusinessUnitGuid uniqueidentifier;
	DECLARE @Approvals nvarchar(10);
	DECLARE @MaxVersion int;

	SELECT	@ContentData_Guid = ContentData_Guid,
			@BusinessUnitGuid = Business_Unit_Guid
	FROM	Content_Item
	WHERE	ContentItem_Guid = @UniqueId
	
	SELECT	@Approvals = OptionValue
	FROM	Global_Options
	WHERE	OptionCode = 'REQUIRE_CONTENT_APPROVAL'
			AND BusinessUnitGuid = @BusinessUnitGuid;


	IF (@Approvals = 'true')
	BEGIN
		IF @ContentData_Guid IS NULL OR NOT EXISTS(SELECT ContentData_Guid 
												FROM ContentData_Text 
												WHERE	ContentData_Guid = @ContentData_Guid)
		BEGIN
			SET	@ContentData_Guid = newid();
			
			INSERT INTO ContentData_Text(ContentData_Guid, ContentData, ContentData_Version, Modified_Date, Modified_By)
			VALUES (@ContentData_Guid, @ContentData, 1, getUTCdate(), @UserGuid)

			UPDATE	Content_Item
			SET		ContentData_Guid = @ContentData_Guid,
					Approved = 0
			WHERE	ContentItem_Guid = @UniqueId;
		END
		ELSE
		BEGIN
			SELECT	@MaxVersion = MAX(ContentData_Version)
			FROM	(SELECT ContentData_Version
					FROM	ContentData_Text_Version
					WHERE	ContentData_Guid = @ContentData_Guid
					UNION
					SELECT	ContentData_Version
					FROM	ContentData_Text
					WHERE	ContentData_Guid = @ContentData_Guid) Versions

			-- Expire old unapproved versions
			UPDATE	ContentData_Text_Version
			SET		Approved = 1
			WHERE	ContentData_Guid = @ContentData_Guid
					AND Approved = 0;
		
			-- Insert new unapproved version
			INSERT INTO ContentData_Text_Version(ContentData_Guid, ContentData, ContentData_Version, Modified_Date, Modified_By, Approved)
			VALUES (@ContentData_Guid, @ContentData, IsNull(@MaxVersion, 0) + 1, getUTCdate(), @UserGuid, 0);
			
			-- ContentItem_Guid must be lower case for xml query
			DECLARE @LowerContentGuid varchar(40)
			SET @LowerContentGuid = LOWER(@UniqueId)
				
			IF (SELECT COUNT(*)
				FROM	Template
					INNER JOIN Template_Group ON Template_Group.Layout_Guid = Template.Template_Guid OR Template_Group.Template_Guid = Template.Template_Guid
				WHERE	Template_Group.MatchProjectVersion = 1
					AND Project_Definition.exist('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question/Answer/ContentItem[@Id = sql:variable("@LowerContentGuid")])[1]') = 1) = 0
			BEGIN
				EXEC spLibrary_ClearExcessVersions @ContentData_Guid, 0;
			END
		END
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT ContentData_Guid FROM ContentData_Text WHERE ContentData_Guid = @ContentData_Guid)
		BEGIN
			EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 0, @UniqueId;
			
			UPDATE	ContentData_Text
			SET		ContentData = @ContentData
			WHERE	ContentData_Guid = @ContentData_Guid
		END
		ELSE
		BEGIN
			SET	@ContentData_Guid = newid()

			INSERT INTO ContentData_Text(ContentData_Guid, ContentData, ContentData_Version)
			VALUES (@ContentData_Guid, @ContentData, 0)

			UPDATE	Content_Item
			SET		ContentData_Guid = @ContentData_Guid
			WHERE	ContentItem_Guid = @UniqueId
		END
		
		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE	ContentData_Text
			SET		Modified_Date = getUTCdate(),
					Modified_By = @UserGuid,
					ContentData_Version = ContentData_Version + 1
			WHERE	ContentData_Guid = @ContentData_Guid;
		END
	END
GO

ALTER PROCEDURE [dbo].[spLibrary_AddNewLibraryVersion]
	@ContentData_Guid uniqueidentifier,
	@IsBinary bit,
	@ContentItem_Guid varchar(40)
AS
	BEGIN TRAN

	If (@IsBinary = 1)
	BEGIN
		INSERT INTO ContentData_Binary_Version 
			(ContentData_Version, 
			ContentData_Guid, 
			ContentData,
			FileType,
			Modified_Date, 
			Modified_By,
			Approved)
		SELECT ContentData_Binary.ContentData_Version,
			ContentData_Binary.ContentData_Guid,
			ContentData_Binary.ContentData,
			ContentData_Binary.FileType,
			ContentData_Binary.Modified_Date,
			ContentData_Binary.Modified_By,
			CASE Content_Item.Approved WHEN 0 THEN 1 ELSE Content_Item.Approved END AS Approved
		FROM ContentData_Binary	
			INNER JOIN Content_Item ON ContentData_Binary.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE ContentData_Binary.ContentData_Guid = @ContentData_Guid;
	END
	ELSE
	BEGIN
		INSERT INTO ContentData_Text_Version 
			(ContentData_Version, 
			ContentData_Guid, 
			ContentData,
			Modified_Date, 
			Modified_By,
			Approved)
		SELECT ContentData_Text.ContentData_Version,
			ContentData_Text.ContentData_Guid,
			ContentData_Text.ContentData,
			ContentData_Text.Modified_Date,
			ContentData_Text.Modified_By,
			CASE Content_Item.Approved WHEN 0 THEN 1 ELSE Content_Item.Approved END AS Approved
		FROM ContentData_Text
			INNER JOIN Content_Item ON ContentData_Text.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE ContentData_Text.ContentData_Guid = @ContentData_Guid;
	END
	
	-- ContentItem_Guid must be lower case for xml query
	DECLARE @LowerContentGuid varchar(40)
	SET @LowerContentGuid = LOWER(@ContentItem_Guid)
	
	IF (SELECT COUNT(*)
		FROM	Template
			INNER JOIN Template_Group ON Template_Group.Layout_Guid = Template.Template_Guid OR Template_Group.Template_Guid = Template.Template_Guid
		WHERE	Template_Group.MatchProjectVersion = 1
			AND Project_Definition.exist('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question/Answer/ContentItem[@Id = sql:variable("@LowerContentGuid")])[1]') = 1) = 0
	BEGIN
		EXEC spLibrary_ClearExcessVersions @ContentData_Guid, @IsBinary;
	END
			
	COMMIT
GO

ALTER procedure [dbo].[spLibrary_RestoreVersion]
	@ContentItemGuid uniqueidentifier,
	@VersionNumber int,
	@UserGuid uniqueidentifier
AS
	SET NOCOUNT ON
	
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @IsBinary bit
	
	SELECT	@ContentData_Guid = ContentData_Guid, 
			@IsBinary = CASE WHEN ContentType_Id = 2 THEN 0 ELSE 1 END
	FROM	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;
		
	BEGIN TRAN	
	
	EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, @IsBinary, @ContentItemGuid;
	
	IF (@IsBinary = 1)
	BEGIN
		UPDATE	ContentData_Binary
		SET		ContentData = ContentData_Binary_Version.ContentData, 
				FileType = ContentData_Binary_Version.FileType,
				ContentData_Version = ContentData_Binary.ContentData_Version + 1, 
				Modified_Date = GetUTCdate(),
				Modified_By = @UserGuid
		FROM	ContentData_Binary, 
				ContentData_Binary_Version
		WHERE	ContentData_Binary.ContentData_Guid = @ContentData_Guid
				AND ContentData_Binary_Version.ContentData_Guid = @ContentData_Guid 
				AND	ContentData_Binary_Version.ContentData_Version = @VersionNumber;
	END
	ELSE
	BEGIN
		UPDATE	ContentData_Text
		SET		ContentData = ContentData_Text_Version.ContentData, 
				ContentData_Version = ContentData_Text.ContentData_Version + 1, 
				Modified_Date = GetUTCdate(),
				Modified_By = @UserGuid
		FROM	ContentData_Text, 
				ContentData_Text_Version
		WHERE	ContentData_Text.ContentData_Guid = @ContentData_Guid
				AND ContentData_Text_Version.ContentData_Guid = @ContentData_Guid 
				AND	ContentData_Text_Version.ContentData_Version = @VersionNumber;
	END
	
	-- ContentItem_Guid must be lower case for xml query
	DECLARE @LowerContentGuid varchar(40)
	SET @LowerContentGuid = LOWER(@ContentItemGuid)
		
	IF (SELECT COUNT(*)
		FROM	Template
			INNER JOIN Template_Group ON Template_Group.Layout_Guid = Template.Template_Guid OR Template_Group.Template_Guid = Template.Template_Guid
		WHERE	Template_Group.MatchProjectVersion = 1
			AND Project_Definition.exist('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question/Answer/ContentItem[@Id = sql:variable("@LowerContentGuid")])[1]') = 1) = 0
	BEGIN
		EXEC spLibrary_ClearExcessVersions @ContentData_Guid, @IsBinary;
	END
	
	UPDATE	Content_Item
	SET		IsIndexed = 0
	WHERE	ContentItem_Guid = @ContentItemGuid;
	
	DELETE	Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItemGuid;
		
	COMMIT
GO

ALTER procedure [dbo].[spProject_GetFoldersByProject]
	@ProjectGuid uniqueidentifier
AS
	SELECT	Folder.Folder_Name, Folder.Folder_Guid, Template_Group.Template_Group_Guid,
			Template.Template_Type_ID, Template_Group.MatchProjectVersion
	FROM	Folder
			INNER JOIN Template_Group on Folder.Folder_Guid = Template_Group.Folder_Guid
			INNER JOIN Template on Template_Group.Template_Guid = Template.Template_Guid
	WHERE	Template.Template_Guid = @ProjectGuid
	ORDER BY Folder.Folder_Name;
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
	ORDER BY f.Folder_Name, t.[Name]
GO
CREATE TABLE dbo.Intelledox_UserDeleted
	(
	UserGuid uniqueidentifier NOT NULL,
	Username nvarchar(256) NULL,
	BusinessUnitGuid uniqueidentifier NOT NULL,
	FirstName nvarchar(50) NULL,
	LastName nvarchar(50) NULL,
	Email nvarchar(256) NULL
	)
GO
ALTER TABLE dbo.Intelledox_UserDeleted ADD CONSTRAINT
	PK_Intelledox_UserDeleted PRIMARY KEY CLUSTERED 
	(
	UserGuid
	)
GO
ALTER procedure [dbo].[spUsers_RemoveUser]
	@UserGuid uniqueidentifier
AS
	SET NOCOUNT ON;

	DECLARE @UserId int;
	DECLARE @AddressId int;
	
	SELECT	@UserId = [User_Id], @AddressId = Address_ID
	FROM	Intelledox_User
	WHERE	User_Guid = @UserGuid;

	-- In case a restored user has been re-deleted, clear the history item
	DELETE Intelledox_UserDeleted WHERE UserGuid = @UserGuid;

	INSERT INTO Intelledox_UserDeleted(UserGuid, Username, BusinessUnitGuid, FirstName, LastName, Email)
	SELECT Intelledox_User.User_Guid, Intelledox_User.Username, Intelledox_User.Business_Unit_GUID,
			Address_Book.First_Name, Address_Book.Last_Name, Address_Book.Email_Address
	FROM Intelledox_User
		LEFT JOIN Address_Book ON Intelledox_User.Address_ID = Address_Book.Address_ID
	WHERE Intelledox_User.User_Guid = @UserGuid;
	
	DELETE Address_Book WHERE Address_ID = @AddressId;
	DELETE User_Address_Book WHERE [User_Id] = @UserId;
	DELETE User_Group_Subscription WHERE UserGuid = @UserGuid;
	DELETE Intelledox_User WHERE User_Guid = @UserGuid;
GO
CREATE procedure dbo.spUsers_DeletedUser
	@UserGuid uniqueidentifier
AS
	SELECT	*
	FROM	Intelledox_UserDeleted
	WHERE	UserGuid = @UserGuid;
GO
ALTER VIEW [dbo].[vwTemplateVersion]
AS
	SELECT	Template_Version.Template_Version, 
			Template_Version.Template_Guid,
			Template_Version.Modified_Date,
			Template_Version.Modified_By,
			Template_Version.Comment,
			Template.Template_Type_ID,
			Template.LockedByUserGuid,
			Template_Version.IsMajorVersion,
			Intelledox_User.Username,
			Address_Book.First_Name + ' ' + Address_Book.Last_Name AS Full_Name,
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
			LEFT JOIN Address_Book ON Intelledox_User.Address_ID = Address_Book.Address_ID
	UNION ALL
		SELECT	Template.Template_Version, 
				Template.Template_Guid,
				Template.Modified_Date,
				Template.Modified_By,
				Template.Comment,
				Template.Template_Type_ID,
				Template.LockedByUserGuid,
				Template.IsMajorVersion,
				Intelledox_User.Username,
				Address_Book.First_Name + ' ' + Address_Book.Last_Name AS Full_Name,
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
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By
			LEFT JOIN Address_Book ON Intelledox_User.Address_ID = Address_Book.Address_ID;
GO
ALTER procedure [dbo].[spProject_GetProjectVersions]
	@ProjectGuid uniqueidentifier
as
		SELECT vwTemplateVersion.Template_Version, 
			vwTemplateVersion.Modified_Date,
			vwTemplateVersion.Modified_By,
			vwTemplateVersion.Username,
			ISNULL(vwTemplateVersion.Full_Name, '') AS Full_Name,
			vwTemplateVersion.Comment,
			vwTemplateVersion.LockedByUserGuid,
			vwTemplateVersion.InUse
		FROM	vwTemplateVersion
		WHERE	vwTemplateVersion.Template_Guid = @ProjectGuid
	ORDER BY Modified_Date DESC;
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
					Content.Modified_By,
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
					Content.Modified_By,
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
					NULL as Modified_By,
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
					Content.Modified_By,
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
				Content.Modified_By,
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
				Content.Modified_By,
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
			Content.Modified_By,
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
					Content.Modified_By,
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
					Content.Modified_By,
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
				Content.Modified_By,
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
ALTER procedure [dbo].[spLibrary_GetContentVersions]
	@ContentItemGuid uniqueidentifier
as
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @Approved Int
	DECLARE @ExpiryDate datetime
	
	UPDATE Content_Item
	SET Approved = 1
	WHERE ExpiryDate < GETDATE()
		And ContentItem_Guid = @ContentItemGuid;

	SELECT	@ContentData_Guid = ContentData_Guid, @Approved = Approved, @ExpiryDate = ExpiryDate
	FROM	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;

	SELECT	ContentData_Version, Modified_Date, Versions.Modified_By, Intelledox_User.Username,
			Approved, ExpiryDate
	FROM	(SELECT	ContentData_Guid, 
				Modified_Date, 
				Modified_By, 
				ContentData_Version, 
				@Approved as Approved, 
				@ExpiryDate AS ExpiryDate
			FROM	ContentData_Binary
			UNION
			SELECT	ContentData_Guid, 
				Modified_Date, 
				Modified_By, 
				ContentData_Version, 
				Approved, 
				NULL AS ExpiryDate
			FROM	ContentData_Binary_Version
			UNION
			SELECT	ContentData_Guid, 
				Modified_Date, 
				Modified_By, 
				ContentData_Version, 
				@Approved as Approved, 
				@ExpiryDate AS ExpiryDate
			FROM	ContentData_Text
			UNION
			SELECT	ContentData_Guid, 
				Modified_Date, 
				Modified_By, 
				ContentData_Version, 
				Approved, 
				NULL AS ExpiryDate
			FROM	ContentData_Text_Version) Versions
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Versions.Modified_By
	WHERE	ContentData_Guid = @ContentData_Guid
	ORDER BY ContentData_Version DESC;
GO
ALTER PROCEDURE [dbo].[spJob_QueueList]
	@BusinessUnitGuid uniqueidentifier,
	@StartDate DateTime,
	@FinishDate DateTime,
	@CurrentStatus Int
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus,
			Template.Name as ProjectName, Intelledox_User.Username, ProcessJob.UserGuid,
			ProcessJob.LogGuid,
			CASE WHEN template_Log.Messages IS NOT NULL THEN 1 ELSE 0 END AS HasMessages
	FROM	ProcessJob
			LEFT JOIN Intelledox_User ON ProcessJob.UserGuid = Intelledox_User.User_Guid
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
			LEFT JOIN Template_Log ON ProcessJob.LogGuid = Template_Log.Log_Guid
	WHERE	ProcessJob.DateStarted BETWEEN @StartDate AND @FinishDate
			AND ((@CurrentStatus = 0) OR 
				(@CurrentStatus = -1 AND ProcessJob.CurrentStatus <> 7) OR 
				(@CurrentStatus <> -1 AND ProcessJob.CurrentStatus = @CurrentStatus))
			AND Template.Business_Unit_Guid = @BusinessUnitGuid
	ORDER BY ProcessJob.DateStarted DESC;
GO

CREATE PROCEDURE dbo.spProject_DeleteOldProjectVersion
	@ProjectGuid uniqueidentifier,
	@NextVersion nvarchar(10),
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN

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
END
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
		
		UPDATE	Template
		SET		Project_Definition = Template_Version.Project_Definition, 
				Template_Version = @NextVersion, 
				Comment = @RestoreVersionComment,
				Modified_Date = GetUTCdate(),
				Modified_By = @UserGuid,
				IsMajorVersion = 1,
				FeatureFlags = Template_Version.FeatureFlags,
				EncryptedProjectDefinition = Template_Version.EncryptedProjectDefinition
		FROM	Template
				INNER JOIN Template_Version ON Template.Template_Guid = Template_Version.Template_Guid
		WHERE	Template_Version.Template_Guid = @ProjectGuid
				AND Template_Version.Template_Version = @VersionNumber
		
		DELETE FROM Template_File
		WHERE	Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File(Template_Guid, File_Guid, [Binary], FormatTypeId)
		SELECT	@ProjectGuid, Template_File_Version.File_Guid, Template_File_Version.[Binary],
				Template_File_Version.FormatTypeId
		FROM	Template_File_Version 
		WHERE	Template_Guid = @ProjectGuid 
				AND Template_Version = @VersionNumber; 
				
		EXEC spProject_DeleteOldProjectVersion @ProjectGuid=@ProjectGuid, 
			@NextVersion=@NextVersion,
			@BusinessUnitGuid=@BusinessUnitGuid;

		EXEC spProjectGroup_UpdateFeatureFlags @ProjectGuid=@ProjectGuid;
	COMMIT
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
		
		EXEC spProject_DeleteOldProjectVersion @ProjectGuid=@ProjectGuid, 
			@NextVersion=@NextVersion,
			@BusinessUnitGuid=@BusinessUnitGuid;
	COMMIT
GO



CREATE TABLE [dbo].[Xtf_Datasource_Dependency] (
    [Template_Guid] [uniqueidentifier] NOT NULL,
	[Template_Version] [nvarchar](10) NOT NULL,
	[Data_Object_Guid] [uniqueidentifier] NOT NULL,
 CONSTRAINT [Template_Guid_pk] PRIMARY KEY CLUSTERED 
(
	[Template_Guid] ASC,
	[Template_Version] ASC,
	[Data_Object_Guid] ASC
)
)

GO

CREATE TABLE [dbo].[Xtf_ContentLibrary_Dependency] (
    [Template_Guid] [uniqueidentifier] NOT NULL,
	[Template_Version] [nvarchar](10) NOT NULL,
	[Content_Object_Guid] [uniqueidentifier] NOT NULL,
 CONSTRAINT [ContentLibrary_Guid_pk] PRIMARY KEY CLUSTERED 
(
	[Template_Guid] ASC,
	[Template_Version] ASC,
	[Content_Object_Guid] ASC
)
) 

GO

SET ARITHABORT ON 

--Migrate 
INSERT INTO [dbo].[Xtf_Datasource_Dependency](Template_Guid, Template_Version, Data_Object_Guid)
SELECT DISTINCT Template.Template_Guid,
		Template.Template_Version,
		Q.value('@DataObjectGuid', 'uniqueidentifier')
FROM [Template]
	CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question)') as QuestionXML(Q)
WHERE Q.value('@DataObjectGuid', 'uniqueidentifier') is not null


CREATE TABLE #ContentQuestionExisting
(
	Id int identity(1,1),
	TemplateGuid uniqueidentifier,
	TemplateVersion nvarchar(10),
	ContentObjectGuid uniqueidentifier
);

INSERT INTO #ContentQuestionExisting(TemplateGuid, TemplateVersion, ContentObjectGuid)
SELECT [Template].Template_Guid, [Template].Template_Version, 
		C.value('@Id', 'uniqueidentifier')
FROM [Template]
	CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question/Answer/ContentItem)') as ContentItemXML(C)
			

INSERT INTO #ContentQuestionExisting(TemplateGuid, TemplateVersion, ContentObjectGuid)
SELECT [Template].Template_Guid,
		[Template].Template_Version,
		Q.value('@ContentItemGuid', 'uniqueidentifier')
FROM [Template]
	CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question)') as QuestionXML(Q)
WHERE Q.value('@ContentItemGuid', 'uniqueidentifier') is not null
			

INSERT INTO [dbo].[Xtf_ContentLibrary_Dependency](Template_Guid, Template_Version, Content_Object_Guid)
SELECT r.TemplateGuid,
		r.TemplateVersion,
		r.ContentObjectGuid
FROM #ContentQuestionExisting r
GROUP BY r.ContentObjectGuid, r.TemplateGuid, r.TemplateVersion

DROP TABLE #ContentQuestionExisting;
GO

ALTER procedure [dbo].[spDataSource_HasAccess]
	@DataObjectGuid varchar(40),
	@UserGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier
as
	SET ARITHABORT ON 

	SELECT 	TOP 1
		1
	FROM	Template
		INNER JOIN Template_Group ON Template_Group.Template_Guid = Template.Template_Guid
				OR Template_Group.Layout_Guid = Template.Template_Guid
		INNER JOIN Folder_Group ON Folder_Group.FolderGuid = Template_Group.Folder_Guid
		INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = Folder_Group.GroupGuid
		INNER JOIN Xtf_Datasource_Dependency ON Xtf_Datasource_Dependency.Template_Guid = Template.Template_Guid
	WHERE	Template.Business_Unit_GUID = @BusinessUnitGuid
		AND User_Group_Subscription.UserGuid = @UserGuid
		AND Xtf_Datasource_Dependency.Data_Object_Guid = @DataObjectGuid

GO

ALTER PROCEDURE [dbo].[spProject_DeleteOldProjectVersion]
	@ProjectGuid uniqueidentifier,
	@NextVersion nvarchar(10),
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN

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

		DELETE FROM Xtf_Datasource_Dependency
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	Template_Version
					WHERE	Template_Guid = @ProjectGuid);

		DELETE FROM Xtf_ContentLibrary_Dependency
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	Template_Version
					WHERE	Template_Guid = @ProjectGuid);
				
		DELETE FROM Template_File_Version
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	Template_Version
					WHERE	Template_Guid = @ProjectGuid);
	END
END
GO

ALTER PROCEDURE [dbo].[spLibrary_AddNewLibraryVersion]
	@ContentData_Guid uniqueidentifier,
	@IsBinary bit,
	@ContentItem_Guid varchar(40)
AS
	BEGIN TRAN

	If (@IsBinary = 1)
	BEGIN
		INSERT INTO ContentData_Binary_Version 
			(ContentData_Version, 
			ContentData_Guid, 
			ContentData,
			FileType,
			Modified_Date, 
			Modified_By,
			Approved)
		SELECT ContentData_Binary.ContentData_Version,
			ContentData_Binary.ContentData_Guid,
			ContentData_Binary.ContentData,
			ContentData_Binary.FileType,
			ContentData_Binary.Modified_Date,
			ContentData_Binary.Modified_By,
			CASE Content_Item.Approved WHEN 0 THEN 1 ELSE Content_Item.Approved END AS Approved
		FROM ContentData_Binary	
			INNER JOIN Content_Item ON ContentData_Binary.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE ContentData_Binary.ContentData_Guid = @ContentData_Guid;
	END
	ELSE
	BEGIN
		INSERT INTO ContentData_Text_Version 
			(ContentData_Version, 
			ContentData_Guid, 
			ContentData,
			Modified_Date, 
			Modified_By,
			Approved)
		SELECT ContentData_Text.ContentData_Version,
			ContentData_Text.ContentData_Guid,
			ContentData_Text.ContentData,
			ContentData_Text.Modified_Date,
			ContentData_Text.Modified_By,
			CASE Content_Item.Approved WHEN 0 THEN 1 ELSE Content_Item.Approved END AS Approved
		FROM ContentData_Text
			INNER JOIN Content_Item ON ContentData_Text.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE ContentData_Text.ContentData_Guid = @ContentData_Guid;
	END
	
	IF (SELECT COUNT(*)
		FROM	Template
			INNER JOIN Template_Group ON Template_Group.Layout_Guid = Template.Template_Guid OR Template_Group.Template_Guid = Template.Template_Guid
			INNER JOIN Xtf_ContentLibrary_Dependency on Xtf_ContentLibrary_Dependency.Template_Guid = Template.Template_Guid
		WHERE	Template_Group.MatchProjectVersion = 1
			AND Xtf_ContentLibrary_Dependency.Content_Object_Guid = @ContentItem_Guid) = 0
	BEGIN
		EXEC spLibrary_ClearExcessVersions @ContentData_Guid, @IsBinary;
	END
			
	COMMIT

GO

ALTER procedure [dbo].[spLibrary_RestoreVersion]
	@ContentItemGuid uniqueidentifier,
	@VersionNumber int,
	@UserGuid uniqueidentifier
AS
	SET NOCOUNT ON
	
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @IsBinary bit
	
	SELECT	@ContentData_Guid = ContentData_Guid, 
			@IsBinary = CASE WHEN ContentType_Id = 2 THEN 0 ELSE 1 END
	FROM	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;
		
	BEGIN TRAN	
	
	EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, @IsBinary, @ContentItemGuid;
	
	IF (@IsBinary = 1)
	BEGIN
		UPDATE	ContentData_Binary
		SET		ContentData = ContentData_Binary_Version.ContentData, 
				FileType = ContentData_Binary_Version.FileType,
				ContentData_Version = ContentData_Binary.ContentData_Version + 1, 
				Modified_Date = GetUTCdate(),
				Modified_By = @UserGuid
		FROM	ContentData_Binary, 
				ContentData_Binary_Version
		WHERE	ContentData_Binary.ContentData_Guid = @ContentData_Guid
				AND ContentData_Binary_Version.ContentData_Guid = @ContentData_Guid 
				AND	ContentData_Binary_Version.ContentData_Version = @VersionNumber;
	END
	ELSE
	BEGIN
		UPDATE	ContentData_Text
		SET		ContentData = ContentData_Text_Version.ContentData, 
				ContentData_Version = ContentData_Text.ContentData_Version + 1, 
				Modified_Date = GetUTCdate(),
				Modified_By = @UserGuid
		FROM	ContentData_Text, 
				ContentData_Text_Version
		WHERE	ContentData_Text.ContentData_Guid = @ContentData_Guid
				AND ContentData_Text_Version.ContentData_Guid = @ContentData_Guid 
				AND	ContentData_Text_Version.ContentData_Version = @VersionNumber;
	END
		
	IF (SELECT COUNT(*)
		FROM	Template
			INNER JOIN Template_Group ON Template_Group.Layout_Guid = Template.Template_Guid OR Template_Group.Template_Guid = Template.Template_Guid
			INNER JOIN Xtf_ContentLibrary_Dependency on Xtf_ContentLibrary_Dependency.Template_Guid = Template.Template_Guid
		WHERE	Template_Group.MatchProjectVersion = 1
			AND Xtf_ContentLibrary_Dependency.Content_Object_Guid = @ContentItemGuid) = 0
	BEGIN
		EXEC spLibrary_ClearExcessVersions @ContentData_Guid, @IsBinary;
	END
	
	UPDATE	Content_Item
	SET		IsIndexed = 0
	WHERE	ContentItem_Guid = @ContentItemGuid;
	
	DELETE	Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItemGuid;
		
	COMMIT
GO

ALTER PROCEDURE [dbo].[spLibrary_UpdateBinary] (
	@UniqueId as uniqueidentifier,
	@ContentData as image,
	@Extension as varchar(5),
	@UserGuid as uniqueidentifier
)
AS
	DECLARE @ContentData_Guid uniqueidentifier;
	DECLARE @ContentItem_Guid uniqueidentifier;
	DECLARE @BusinessUnitGuid uniqueidentifier;
	DECLARE @Approvals nvarchar(10);
	DECLARE @MaxVersion int;
	DECLARE @CIApproved int;

	SET NOCOUNT ON;

	SELECT	@ContentData_Guid = ContentData_Guid, 
			@ContentItem_Guid = ContentItem_Guid,
			@BusinessUnitGuid = Business_Unit_Guid,
			@CIApproved = Approved
	FROM	Content_Item
	WHERE	ContentItem_Guid = @UniqueId;
	
	SELECT	@Approvals = OptionValue
	FROM	Global_Options
	WHERE	OptionCode = 'REQUIRE_CONTENT_APPROVAL'
			AND BusinessUnitGuid = @BusinessUnitGuid;


	IF (@Approvals = 'true')
	BEGIN
		IF @ContentData_Guid IS NULL OR NOT EXISTS(SELECT ContentData_Guid 
												FROM ContentData_Binary 
												WHERE	ContentData_Guid = @ContentData_Guid)
		BEGIN
			SET	@ContentData_Guid = newid();
			
			INSERT INTO ContentData_Binary(ContentData_Guid, ContentData, FileType, ContentData_Version, Modified_Date, Modified_By)
			VALUES (@ContentData_Guid, @ContentData, @Extension, 1, getUTCdate(), @UserGuid);

			UPDATE	Content_Item
			SET		ContentData_Guid = @ContentData_Guid,
					Approved = 0
			WHERE	ContentItem_Guid = @UniqueId;
		END
		ELSE
		BEGIN
			IF (@CIApproved = 0)
			BEGIN
				-- Content item hasnt been approved yet so we can replace it
				EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 1, @UniqueId;
				
				UPDATE	ContentData_Binary
				SET		ContentData = @ContentData,
						FileType = @Extension,
						Modified_Date = getUTCdate(),
						Modified_By = @UserGuid,
						ContentData_Version = ContentData_Version + 1
				WHERE	ContentData_Guid = @ContentData_Guid;

				-- Expire old unapproved versions
				UPDATE	ContentData_Binary_Version
				SET		Approved = 1
				WHERE	ContentData_Guid = @ContentData_Guid
						AND Approved = 0;
			END
			ELSE
			BEGIN
				SELECT	@MaxVersion = MAX(ContentData_Version)
				FROM	(SELECT ContentData_Version
						FROM	ContentData_Binary_Version
						WHERE	ContentData_Guid = @ContentData_Guid
						UNION
						SELECT	ContentData_Version
						FROM	ContentData_Binary
						WHERE	ContentData_Guid = @ContentData_Guid) Versions

				-- Expire old unapproved versions
				UPDATE	ContentData_Binary_Version
				SET		Approved = 1
				WHERE	ContentData_Guid = @ContentData_Guid
						AND Approved = 0;
			
				-- Insert new unapproved version
				INSERT INTO ContentData_Binary_Version(ContentData_Guid, ContentData, FileType, ContentData_Version, Modified_Date, Modified_By, Approved)
				VALUES (@ContentData_Guid, @ContentData, @Extension, IsNull(@MaxVersion, 0) + 1, getUTCdate(), @UserGuid, 0);
			END
				
			IF (SELECT COUNT(*)
				FROM	Template
					INNER JOIN Template_Group ON Template_Group.Layout_Guid = Template.Template_Guid OR Template_Group.Template_Guid = Template.Template_Guid
					INNER JOIN Xtf_ContentLibrary_Dependency on Xtf_ContentLibrary_Dependency.Template_Guid = Template.Template_Guid
				WHERE	Template_Group.MatchProjectVersion = 1
						AND Xtf_ContentLibrary_Dependency.Content_Object_Guid = @ContentData_Guid) = 0
			BEGIN
				EXEC spLibrary_ClearExcessVersions @ContentData_Guid, 0;
			END
			
		END
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT ContentData_Guid FROM ContentData_Binary WHERE ContentData_Guid = @ContentData_Guid)
		BEGIN
			EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 1, @UniqueId;
			
			UPDATE	ContentData_Binary
			SET		ContentData = @ContentData,
					FileType = @Extension
			WHERE	ContentData_Guid = @ContentData_Guid;
		END
		ELSE
		BEGIN
			IF @ContentItem_Guid IS NOT NULL
			BEGIN
				SET	@ContentData_Guid = newid();

				INSERT INTO ContentData_Binary(ContentData_Guid, ContentData, FileType, ContentData_Version)
				VALUES (@ContentData_Guid, @ContentData, @Extension, 0);

				UPDATE	Content_Item
				SET		ContentData_Guid = @ContentData_Guid
				WHERE	ContentItem_Guid = @UniqueId;
			END
		END
		
		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE	ContentData_Binary
			SET		Modified_Date = getUTCdate(),
					Modified_By = @UserGuid,
					ContentData_Version = ContentData_Version + 1
			WHERE	ContentData_Guid = @ContentData_Guid;
		END
	END

	DELETE	FROM Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItem_Guid;
	
	UPDATE	Content_Item
	SET		IsIndexed = 0
	WHERE	ContentItem_Guid = @ContentItem_Guid;

GO

ALTER PROCEDURE [dbo].[spLibrary_UpdateText] (
	@UniqueId as uniqueidentifier,
	@ContentData as nvarchar(max),
	@UserGuid as uniqueidentifier
)
AS
	DECLARE @ContentData_Guid uniqueidentifier;
	DECLARE @BusinessUnitGuid uniqueidentifier;
	DECLARE @Approvals nvarchar(10);
	DECLARE @MaxVersion int;

	SELECT	@ContentData_Guid = ContentData_Guid,
			@BusinessUnitGuid = Business_Unit_Guid
	FROM	Content_Item
	WHERE	ContentItem_Guid = @UniqueId
	
	SELECT	@Approvals = OptionValue
	FROM	Global_Options
	WHERE	OptionCode = 'REQUIRE_CONTENT_APPROVAL'
			AND BusinessUnitGuid = @BusinessUnitGuid;


	IF (@Approvals = 'true')
	BEGIN
		IF @ContentData_Guid IS NULL OR NOT EXISTS(SELECT ContentData_Guid 
												FROM ContentData_Text 
												WHERE	ContentData_Guid = @ContentData_Guid)
		BEGIN
			SET	@ContentData_Guid = newid();
			
			INSERT INTO ContentData_Text(ContentData_Guid, ContentData, ContentData_Version, Modified_Date, Modified_By)
			VALUES (@ContentData_Guid, @ContentData, 1, getUTCdate(), @UserGuid)

			UPDATE	Content_Item
			SET		ContentData_Guid = @ContentData_Guid,
					Approved = 0
			WHERE	ContentItem_Guid = @UniqueId;
		END
		ELSE
		BEGIN
			SELECT	@MaxVersion = MAX(ContentData_Version)
			FROM	(SELECT ContentData_Version
					FROM	ContentData_Text_Version
					WHERE	ContentData_Guid = @ContentData_Guid
					UNION
					SELECT	ContentData_Version
					FROM	ContentData_Text
					WHERE	ContentData_Guid = @ContentData_Guid) Versions

			-- Expire old unapproved versions
			UPDATE	ContentData_Text_Version
			SET		Approved = 1
			WHERE	ContentData_Guid = @ContentData_Guid
					AND Approved = 0;
		
			-- Insert new unapproved version
			INSERT INTO ContentData_Text_Version(ContentData_Guid, ContentData, ContentData_Version, Modified_Date, Modified_By, Approved)
			VALUES (@ContentData_Guid, @ContentData, IsNull(@MaxVersion, 0) + 1, getUTCdate(), @UserGuid, 0);
			
			IF (SELECT COUNT(*)
				FROM	Template
					INNER JOIN Template_Group ON Template_Group.Layout_Guid = Template.Template_Guid OR Template_Group.Template_Guid = Template.Template_Guid
					INNER JOIN Xtf_ContentLibrary_Dependency on Xtf_ContentLibrary_Dependency.Template_Guid = Template.Template_Guid
				WHERE	Template_Group.MatchProjectVersion = 1
						AND Xtf_ContentLibrary_Dependency.Content_Object_Guid = @UniqueId) = 0
			BEGIN
				EXEC spLibrary_ClearExcessVersions @ContentData_Guid, 0;
			END
		END
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT ContentData_Guid FROM ContentData_Text WHERE ContentData_Guid = @ContentData_Guid)
		BEGIN
			EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 0, @UniqueId;
			
			UPDATE	ContentData_Text
			SET		ContentData = @ContentData
			WHERE	ContentData_Guid = @ContentData_Guid
		END
		ELSE
		BEGIN
			SET	@ContentData_Guid = newid()

			INSERT INTO ContentData_Text(ContentData_Guid, ContentData, ContentData_Version)
			VALUES (@ContentData_Guid, @ContentData, 0)

			UPDATE	Content_Item
			SET		ContentData_Guid = @ContentData_Guid
			WHERE	ContentItem_Guid = @UniqueId
		END
		
		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE	ContentData_Text
			SET		Modified_Date = getUTCdate(),
					Modified_By = @UserGuid,
					ContentData_Version = ContentData_Version + 1
			WHERE	ContentData_Guid = @ContentData_Guid;
		END
	END

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
			Intelledox_User.Username,
			Template.Modified_By,
			Template.FeatureFlags
	FROM	Template
		LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By
		LEFT JOIN Xtf_ContentLibrary_Dependency on Xtf_ContentLibrary_Dependency.Template_Guid = Template.Template_Guid
	WHERE	Template.Business_Unit_GUID = @BusinessUnitGuid
		AND Xtf_ContentLibrary_Dependency.Content_Object_Guid = @ContentGuid 
	ORDER BY Template.[name];

GO


ALTER PROCEDURE [dbo].[spProject_UpdateDefinition] (
	@Xtf xml,
	@TemplateGuid uniqueidentifier,
	@EncryptedXtf varbinary(MAX)
)
AS
	DECLARE @FeatureFlags int;
	DECLARE @DataObjectGuid uniqueidentifier;
	DECLARE @XtfVersion nvarchar(10)

	BEGIN TRAN
		-- Feature detection --
		SET @FeatureFlags = 0
		SELECT @XtfVersion = Template.Template_Version FROM Template WHERE Template.Template_Guid = @TemplateGuid

		-- Workflow
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/Workflow/State/Transition)') as ProjectXML(P))
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

			INSERT INTO [dbo].[Xtf_Datasource_Dependency](Template_Guid, Template_Version, Data_Object_Guid)
			SELECT DISTINCT @TemplateGuid,
					@XtfVersion,
					Q.value('@DataObjectGuid', 'uniqueidentifier')
			FROM 
				@Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question)') as QuestionXML(Q)
			WHERE Q.value('@DataObjectGuid', 'uniqueidentifier') is not null
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

		BEGIN

		CREATE TABLE #ContentQuestionExisting
		(
			Id int identity(1,1),
			TemplateGuid uniqueidentifier,
			TemplateVersion nvarchar(10),
			ContentObjectGuid uniqueidentifier
		);

		INSERT INTO #ContentQuestionExisting(TemplateGuid, TemplateVersion, ContentObjectGuid)
		SELECT @TemplateGuid,
			   @XtfVersion,
			   C.value('@Id', 'uniqueidentifier')
		FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question/Answer/ContentItem)') as ContentItemXML(C)
			

		INSERT INTO #ContentQuestionExisting(TemplateGuid, TemplateVersion, ContentObjectGuid)
		SELECT @TemplateGuid,
			   @XtfVersion,
			   Q.value('@ContentItemGuid', 'uniqueidentifier')
		FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question)') as QuestionXML(Q)
		WHERE Q.value('@ContentItemGuid', 'uniqueidentifier') is not null
			

		INSERT INTO [dbo].[Xtf_ContentLibrary_Dependency](Template_Guid, Template_Version, Content_Object_Guid)
		SELECT r.TemplateGuid,
				r.TemplateVersion,
				r.ContentObjectGuid
		FROM #ContentQuestionExisting r
		GROUP BY r.ContentObjectGuid, r.TemplateGuid, r.TemplateVersion

		DROP TABLE #ContentQuestionExisting

		END

		-- Address
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 1)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 16;
		END

		-- Rich text
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 19)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 64;
		END
			
		-- Custom Question
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 22)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 128;
		END
					
		IF @EncryptedXtf IS NULL
		BEGIN
			UPDATE	Template 
			SET		Project_Definition = @XTF,
					FeatureFlags = @FeatureFlags,
					EncryptedProjectDefinition = NULL
			WHERE	Template_Guid = @TemplateGuid;
		END
		ELSE
		BEGIN
			UPDATE	Template 
			SET		EncryptedProjectDefinition = @EncryptedXtf,
					FeatureFlags = @FeatureFlags,
					Project_Definition = NULL
			WHERE	Template_Guid = @TemplateGuid;
		END

		EXEC spProjectGroup_UpdateFeatureFlags @ProjectGuid=@TemplateGuid;
	COMMIT

GO
