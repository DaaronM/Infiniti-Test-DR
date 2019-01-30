/*
** Database Update package 7.2.0
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.2.0')
go

--1976
INSERT INTO Routing_ElementType(RoutingElementTypeId, RoutingTypeId, ElementTypeDescription, ElementLimit, Required)
VALUES ('6F0DAD75-A96E-41D0-9233-B226119C608A', '230DD56C-0018-4D49-945E-5B6E5B08EAF6', 'Reply To', 1, 0);
GO


--1977
ALTER procedure [dbo].[spProject_GetFoldersByProject]
	@ProjectGuid uniqueidentifier
as
	SELECT	Folder.Folder_Name, Folder.Folder_Guid, Template_Group.Template_Group_Guid
	FROM	Folder
			INNER JOIN Folder_Template on Folder.Folder_ID = Folder_Template.Folder_ID
			INNER JOIN Template_Group on Folder_Template.FolderItem_ID = Template_Group.Template_Group_ID
			INNER JOIN Template_Group_Item on Template_Group.Template_Group_ID = Template_Group_Item.Template_Group_ID
			INNER JOIN Template on Template_Group_Item.Template_ID = Template.Template_ID
	WHERE	Template.Template_Guid = @ProjectGuid
	ORDER BY Folder.Folder_Name;
GO

--1979
CREATE NONCLUSTERED INDEX IX_Content_Item_ExpiryDate ON dbo.Content_Item
	(
	ExpiryDate
	)
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
		WHERE ExpiryDate < GETUTCDATE();
		
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
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
								INNER JOIN Intelledox_User ON User_Group_Subscription.User_ID = Intelledox_User.User_ID
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
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
								INNER JOIN Intelledox_User ON User_Group_Subscription.User_ID = Intelledox_User.User_ID
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
					AND ci.NameIdentity LIKE '%' + @Name + '%'
					AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND ci.Description LIKE '%' + @Description + '%'
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
		WHERE	ExpiryDate < GETUTCDATE()
				AND contentitem_guid = @ItemGuid;
		
		IF (@MinimalGet = 1)
		BEGIN
			SELECT	ci.*, 
					'' as FileType, 
					NULL as Modified_Date, 
					'' as UserName,
					0 as HasUnapprovedRevision,
					0 as CanEdit,
					'' as FolderName						
			FROM	content_item ci
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
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
								INNER JOIN Intelledox_User ON User_Group_Subscription.User_ID = Intelledox_User.User_ID
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


--1980
INSERT INTO Global_Options (OptionCode, OptionDescription, OptionValue)
VALUES ('PDF_FORMAT', 'Default PDF format', '0');
GO


--1981
ALTER TABLE JobDefinition
	ADD DeleteAfterDays int null,
		LastRunDate datetime null
GO
UPDATE	JobDefinition
SET		DeleteAfterDays = 0
WHERE	DeleteAfterDays IS NULL;
GO
ALTER TABLE JobDefinition
	ALTER COLUMN DeleteAfterDays int not null
GO
CREATE PROCEDURE [dbo].[spJob_JobDefinitionSearch](
	@Name nvarchar(200),
	@DateCreatedFrom datetime,
	@DateCreatedTo datetime,
	@NextRunFrom datetime,
	@NextRunTo datetime
)
AS
	SELECT	*
	FROM	JobDefinition
	WHERE	(Name LIKE @Name + '%' OR @Name = '')
			AND (NextRunDate >= @NextRunFrom OR @NextRunFrom IS NULL)
			AND (NextRunDate < @NextRunTo OR @NextRunTo IS NULL)
			AND (DateCreated >= @DateCreatedFrom OR @DateCreatedFrom IS NULL)
			AND (DateCreated < @DateCreatedTo OR @DateCreatedTo IS NULL)
	ORDER BY Name;
GO
ALTER PROCEDURE [dbo].[spJob_UpdateJobDefinition](
	@JobDefinitionId uniqueidentifier,
	@Name nvarchar(200),
	@IsEnabled bit,
	@OwnerGuid uniqueidentifier,
	@DateModified datetime,
	@JobDefinition xml,
	@DeleteAfterDays int
)
AS
	UPDATE	JobDefinition
	SET		Name = @Name, 
			IsEnabled = @IsEnabled, 
			OwnerGuid = @OwnerGuid, 
			DateModified = @DateModified, 
			JobDefinition = @JobDefinition,
			DeleteAfterDays = @DeleteAfterDays
	WHERE	JobDefinitionId = @JobDefinitionId;
GO
ALTER PROCEDURE [dbo].[spJob_CreateJobDefinition](
	@JobDefinitionId uniqueidentifier,
	@Name nvarchar(200),
	@IsEnabled bit,
	@OwnerGuid uniqueidentifier,
	@DateCreated datetime,
	@DateModified datetime,
	@JobDefinition xml,
	@NextRunDate datetime,
	@WatchFolder nvarchar(300),
	@DataSourceGuid uniqueidentifier,
	@DeleteAfterDays int
)
AS
	INSERT INTO JobDefinition(JobDefinitionId, Name, NextRunDate, IsEnabled, OwnerGuid, DateCreated, 
		DateModified, JobDefinition, WatchFolder, DataSourceGuid, DeleteAfterDays)
	VALUES (@JobDefinitionId, @Name, @NextRunDate, @IsEnabled, @OwnerGuid, @DateCreated, 
		@DateModified, @JobDefinition, @WatchFolder, @DataSourceGuid, @DeleteAfterDays);
GO
ALTER PROCEDURE [dbo].[spJob_UpdateNextRun]
	@JobDefinitionId uniqueidentifier,
	@LastRunDate datetime,
	@RunDate datetime
AS
	UPDATE	JobDefinition
	SET		LastRunDate = @LastRunDate,
			NextRunDate = @RunDate
	WHERE	JobDefinitionId = @JobDefinitionId;
GO

