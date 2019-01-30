/*
** Database Update package 7.0.0.4
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.0.0.4')
go

--1944
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
	@GroupGuid uniqueidentifier,
	@UserId uniqueidentifier,
	@NoGroup bit
as
	IF @ItemGuid is null 
		IF @ExactMatch = 1
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as 
HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = 
User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON 
User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
								INNER JOIN Intelledox_User ON 
User_Group_Subscription.User_ID = Intelledox_User.User_ID
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit,
					ci.FolderGuid
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = 
Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = 
UnapprovedRevisions.ContentData_Guid
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
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as 
HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = 
User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON 
User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
								INNER JOIN Intelledox_User ON 
User_Group_Subscription.User_ID = Intelledox_User.User_ID
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit,
					ci.FolderGuid
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = 
Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = 
UnapprovedRevisions.ContentData_Guid
						
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity LIKE '%' + @Name + '%'
					AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND ci.Description LIKE '%' + @Description + '%'
					AND (@Category = 0 or ci.Category = @Category)
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
					AND (@NoGroup = 0 AND
							(@GroupGuid IS NULL 
							OR EXISTS (SELECT * 
								FROM Content_Folder_Group 
								WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid
									AND Content_Folder_Group.GroupGuid = @GroupGuid))
						OR (@NoGroup = 1 AND
							NOT EXISTS (SELECT * 
								FROM Content_Folder_Group 
								WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid)))
			ORDER BY ci.NameIdentity;
	ELSE
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Intelledox_User.UserName,
				CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as 
HasUnapprovedRevision,
				CASE WHEN (@UserId IS NULL 
					OR ci.FolderGuid IS NULL 
					OR (NOT EXISTS (
						SELECT * 
						FROM Content_Folder_Group 
						WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
					OR EXISTS (
						SELECT * 
						FROM Content_Folder_Group
							INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = 
User_Group.Group_Guid
							INNER JOIN User_Group_Subscription ON 
User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
							INNER JOIN Intelledox_User ON User_Group_Subscription.User_ID = 
Intelledox_User.User_ID
						WHERE Intelledox_User.User_Guid = @UserId
							AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
				THEN 1 ELSE 0 END
				AS CanEdit,
				ci.FolderGuid
		FROM	content_item ci
				LEFT JOIN (
					SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
					FROM	ContentData_Binary
					UNION
					SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
					FROM	ContentData_Text) Content ON ci.ContentData_Guid = 
Content.ContentData_Guid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
				LEFT JOIN (
					SELECT	ContentData_Guid
					FROM	vwContentItemVersionDetails
					WHERE	Approved = 0
					) UnapprovedRevisions ON ci.ContentData_Guid = 
UnapprovedRevisions.ContentData_Guid
		WHERE	ci.contentitem_guid = @ItemGuid;
	
	set @ErrorCode = @@error;
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
	@GroupGuid uniqueidentifier,
	@UserId uniqueidentifier,
	@NoGroup bit
as
	IF @ItemGuid is null 
		IF @ExactMatch = 1
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as 
HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = 
User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON 
User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
								INNER JOIN Intelledox_User ON 
User_Group_Subscription.User_ID = Intelledox_User.User_ID
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = 
Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = 
UnapprovedRevisions.ContentData_Guid
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
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as 
HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = 
User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON 
User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
								INNER JOIN Intelledox_User ON 
User_Group_Subscription.User_ID = Intelledox_User.User_ID
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = 
Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = 
UnapprovedRevisions.ContentData_Guid
					
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity LIKE '%' + @Name + '%'
					AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND ci.Description LIKE '%' + @Description + '%'
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
					AND (@NoGroup = 0 AND
							(@GroupGuid IS NULL 
							OR EXISTS (SELECT * 
								FROM Content_Folder_Group 
								WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid
									AND Content_Folder_Group.GroupGuid = @GroupGuid))
						OR (@NoGroup = 1 AND
							NOT EXISTS (SELECT * 
								FROM Content_Folder_Group 
								WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid)))
			ORDER BY ci.NameIdentity;
	ELSE
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Intelledox_User.UserName,
				CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as 
HasUnapprovedRevision,
				CASE WHEN (@UserId IS NULL 
					OR ci.FolderGuid IS NULL 
					OR (NOT EXISTS (
						SELECT * 
						FROM Content_Folder_Group 
						WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
					OR EXISTS (
						SELECT * 
						FROM Content_Folder_Group
							INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = 
User_Group.Group_Guid
							INNER JOIN User_Group_Subscription ON 
User_Group_Subscription.User_Group_ID = User_Group.User_Group_ID
							INNER JOIN Intelledox_User ON User_Group_Subscription.User_ID = 
Intelledox_User.User_ID
						WHERE Intelledox_User.User_Guid = @UserId
							AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
				THEN 1 ELSE 0 END
				AS CanEdit
		FROM	content_item ci
				LEFT JOIN (
					SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
					FROM	ContentData_Binary
					UNION
					SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
					FROM	ContentData_Text) Content ON ci.ContentData_Guid = 
Content.ContentData_Guid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
				LEFT JOIN (
					SELECT	ContentData_Guid
					FROM	vwContentItemVersionDetails
					WHERE	Approved = 0
					) UnapprovedRevisions ON ci.ContentData_Guid = 
UnapprovedRevisions.ContentData_Guid
		WHERE	ci.contentitem_guid = @ItemGuid;
	
	set @ErrorCode = @@error;
GO

--1945
CREATE procedure [dbo].[spContent_UserHasAccess]
	@FolderGuid uniqueidentifier,
	@UserId uniqueidentifier
as
	SELECT	
		CASE WHEN (@FolderGuid IS NULL 
			OR (NOT EXISTS (
				SELECT * 
				FROM Content_Folder_Group 
				WHERE @FolderGuid = Content_Folder_Group.FolderGuid))
			OR EXISTS (
				SELECT * 
				FROM Content_Folder_Group
					INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
					INNER JOIN User_Group_Subscription ON User_Group_Subscription.User_Group_ID = 
User_Group.User_Group_ID
					INNER JOIN Intelledox_User ON User_Group_Subscription.User_ID = 
Intelledox_User.User_ID
				WHERE Intelledox_User.User_Guid = @UserId
					AND @FolderGuid = Content_Folder_Group.FolderGuid))
		THEN 1 ELSE 0 END
		AS HasAccess
	FROM	Content_Folder
	WHERE	FolderGuid = @FolderGuid OR @FolderGuid IS NULL;
GO

--1946

CREATE procedure [dbo].[spContent_RemoveContentFolder]
	@FolderGuid uniqueidentifier
AS

	DELETE Content_Folder
	WHERE FolderGuid = @FolderGuid;
	
	DELETE Content_Folder_Group
	WHERE FolderGuid = @FolderGuid;
	
	UPDATE Content_Item
	SET FolderGuid = NULL
	WHERE FolderGuid = FolderGuid;
	
GO

--1947
ALTER PROCEDURE [dbo].[spLog_InsertTemplateLog]
	@LogGuid uniqueidentifier,
	@UserGuid uniqueidentifier,	
	@TemplateGroupGuid uniqueidentifier,
	@StartTime datetime,
	@AnswerFileUsed bit,
	@AnswerFile xml,
	@UpdateRecent bit = 0
AS
	DECLARE @UserId INT;
	DECLARE @TemplateGroupId INT;
	
	SET NOCOUNT ON;
	
	SET @UserId = (SELECT User_Id FROM Intelledox_User WITH (NOLOCK) WHERE User_Guid = @UserGuid);
	SET	@TemplateGroupId = (SELECT Template_Group_Id FROM Template_Group WITH (NOLOCK) WHERE Template_Group_Guid = @TemplateGroupGuid);
	
	IF @LogGuid IS NULL
		SET @LogGuid = newid();

	--Add to log
	INSERT INTO Template_Log WITH (ROWLOCK) (Log_Guid, [User_ID], Template_Group_ID, DateTime_Start, Completed, Answer_File_Used, InProgress, Answer_File)
	VALUES (@LogGuid, @UserID, @TemplateGroupID, @StartTime, 0, @AnswerFileUsed, 1, @AnswerFile);

	--Add to recent
	If @UpdateRecent = 1
	BEGIN
		IF EXISTS (SELECT * FROM Template_Recent WHERE User_Guid = @UserGuid AND Template_Group_Guid = @TemplateGroupGuid)
		BEGIN
			--Update time ran
			UPDATE	Template_Recent
			SET		DateTime_Start = @StartTime
			WHERE	User_Guid = @UserGuid 
					AND Template_Group_Guid = @TemplateGroupGuid;
		END
		ELSE
		BEGIN
			IF ((SELECT COUNT(*) FROM Template_Recent WHERE User_Guid = @UserGuid) = 5)
			BEGIN
				--Remove oldest recent record
				DELETE Template_Recent
				WHERE DateTime_Start = (SELECT MIN(DateTime_Start)
					FROM	Template_Recent
					WHERE	User_Guid = @UserGuid)
					AND User_Guid = @UserGuid;
			END
			
			INSERT INTO Template_Recent(User_Guid, DateTime_Start, Template_Group_Guid)
			VALUES (@UserGuid, @StartTime, @TemplateGroupGuid);
		END
	END
GO
ALTER procedure [dbo].[spLog_TemplateLogList]
	@LogGuid varchar(50) = '',
	@ErrorCode int output
as
	SELECT	Template_Log.*, Template_Group.Template_Group_Guid, Intelledox_User.User_Guid
	FROM	Template_Log
			INNER JOIN Template_Group ON Template_Log.Template_Group_Id = Template_Group.Template_Group_Id
			INNER JOIN Intelledox_User ON Template_Log.User_Id = Intelledox_User.User_Id
	WHERE	Template_Log.Log_Guid = @LogGuid;
	
	set @ErrorCode = @@error
GO
ALTER procedure [dbo].[spAudit_AnswerFileList]
	@AnswerFile_ID int = 0,
	@User_Guid uniqueidentifier = null,
	@WebOnly char(1) = 0,
	@InProgress char(1) = '0',
	@TemplateGroupGuid uniqueidentifier = null,
	@ErrorCode int output
AS
	DECLARE @User_Id Int
	
	set nocount on
	
	IF (@User_Guid IS NOT NULL)
	BEGIN
		SELECT	@User_Id = User_Id
		FROM	Intelledox_User
		WHERE	User_Guid = @User_Guid;
	END

	if @AnswerFile_ID = 0 or @AnswerFile_ID is null
    begin
        if @User_ID = 0 or @User_ID is null
            SELECT	Answer_File.*, Template_Group.Template_Group_Guid, Intelledox_User.User_Guid
			FROM	Answer_File
					INNER JOIN Template_Group ON Answer_File.Template_Group_Id = Template_Group.Template_Group_Id
					INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
					INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
					INNER JOIN Intelledox_User ON Answer_File.User_Id = Intelledox_User.User_ID
			WHERE	Answer_File.InProgress = @InProgress
            order by Answer_File.[RunDate] desc;
        else
		begin
			if @TemplateGroupGuid is null
				select ans.*, T.Name as TemplateGroup_Name, Template_Group.Template_Group_Guid,
						Intelledox_User.User_Guid
				from	answer_file ans
						INNER JOIN Template_Group on ans.Template_Group_ID = Template_Group.Template_Group_ID
						INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
						INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
						INNER JOIN Intelledox_User ON ans.User_Id = Intelledox_User.User_ID
				where Ans.[user_ID] = @user_id
					AND Ans.[InProgress] = @InProgress
					AND Ans.template_group_id in(

					-- Get a union of template group.
					SELECT DISTINCT tg.Template_Group_ID
					FROM Folder f
						left join (
							SELECT tg.Template_Group_ID, ft.Folder_ID
							FROM folder_template ft
							LEFT JOIN template_group tg ON ft.FolderItem_ID = tg.Template_Group_ID AND ft.ItemType_ID = 1
						) tg on f.Folder_ID = tg.Folder_ID
						left join template_group_item tgi on tg.template_group_id = tgi.template_group_id
						left join template t on tgi.template_id = t.template_id
						inner join folder_group fg on F.Folder_Guid = fg.FolderGuid
					where 	(fg.GroupGuid in
								(select b.Group_Guid
								from intelledox_user a
								left join User_Group_Subscription c on a.[User_ID] = c.[User_ID]
								left join user_group b on c.user_group_id = b.user_group_id
								where c.[user_id] = @user_id)
							)
				)
				order by [RunDate] desc;
			else
				select	ans.*, Template_Group.Name as TemplateGroup_Name, Template_Group.Template_Group_Guid,
						Intelledox_User.User_Guid
				from	answer_file ans
						INNER JOIN Template_Group on ans.Template_Group_ID = Template_Group.Template_Group_ID
						INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
						INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
						INNER JOIN Intelledox_User ON ans.User_Id = Intelledox_User.User_ID
				where Ans.[user_ID] = @user_id
					AND Template_Group.Template_group_Guid = @TemplateGroupGuid
				order by [RunDate] desc;
		end
    end
    else
    begin
        SELECT	Answer_File.*, Template_Group.Template_Group_Guid, Intelledox_User.User_Guid
		FROM	Answer_File
				INNER JOIN Template_Group ON Answer_File.Template_Group_Id = Template_Group.Template_Group_Id
				INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
				INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
				INNER JOIN Intelledox_User ON Answer_File.User_Id = Intelledox_User.User_ID
        WHERE	Answer_File.AnswerFile_Id = @AnswerFile_Id
        ORDER BY Answer_File.[RunDate] desc;
    end
GO
ALTER procedure [dbo].[spTemplateGrp_RemoveTemplateGroup]
	@TemplateGroupID int,
	@ErrorCode int output
as
	-- Remove the group records
	DELETE Template_Group_Item WHERE Template_Group_ID = @TemplateGroupID;
	DELETE Template_Group WHERE Template_Group_ID = @TemplateGroupID;
	
	set @ErrorCode = @@error;
GO
ALTER PROCEDURE [dbo].[spProjectGrp_RemoveProjectGroup]
	@ProjectGroupGuid uniqueidentifier
AS
	-- Remove the group records
	DELETE Folder_Template WHERE ItemType_id = 1 AND FolderItem_ID IN (SELECT Template_Group_Id FROM Template_Group_Item WHERE Template_Group_Guid = @ProjectGroupGuid);
	DELETE Template_Group_Item WHERE Template_Group_Guid = @ProjectGroupGuid;
	DELETE Template_Group WHERE Template_Group_Guid = @ProjectGroupGuid;
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
exec sp_rename 'dbo.Package', 'zzPackage', 'OBJECT';
GO
exec sp_rename 'dbo.Package_Run', 'zzPackage_Run', 'OBJECT';
GO
exec sp_rename 'dbo.Package_Template', 'zzPackage_Template', 'OBJECT';
GO
DROP PROCEDURE dbo.spProjectPackage_FolderListAll;
GO
DROP PROCEDURE dbo.spLog_CompleteTemplateLog;
GO
DROP PROCEDURE dbo.spProjectGrp_PublishPackage;
GO
DROP PROCEDURE dbo.spProjectGrp_UnPublishPackage;
GO
DROP PROCEDURE dbo.spProjectGrp_PackageListByFolder;
GO
DROP PROCEDURE dbo.spTemplateGrp_PackageList;
GO
DROP PROCEDURE dbo.spTemplateGrp_PackageTemplateList;
GO
DROP PROCEDURE dbo.spTemplateGrp_UpdatePackage;
GO
DROP PROCEDURE dbo.spTemplateGrp_RemovePackage;
GO
DROP PROCEDURE dbo.spTemplateGrp_SubscribePackageTemplate;
GO
DROP PROCEDURE dbo.spTemplateGrp_PackageRunList;
GO
DROP PROCEDURE dbo.spTemplateGrp_UpdatePackageRun;
GO
DROP PROCEDURE dbo.spTemplateGrp_RemovePackageRun;
GO
DROP PROCEDURE dbo.spTemplateGrp_SubscribeFolderPackage;
GO
DROP PROCEDURE dbo.spTemplateGrp_UnsubscribeFolderPackage;
GO
DROP PROCEDURE dbo.spTemplateGrp_PackageListByFolder;
GO

--1948
ALTER procedure [dbo].[spTemplate_RemoveTemplate]
	@TemplateGuid uniqueidentifier,
	@OnlyChildInfo bit
as
	DECLARE @TemplateId Int

	SELECT	@TemplateId = Template_Id
	FROM	Template
	WHERE	Template_Guid = @TemplateGuid;

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
DROP PROCEDURE dbo.spMacro_MacroList;
GO
DROP PROCEDURE dbo.spMacro_MacroTemplateList;
GO
DROP PROCEDURE dbo.spMacro_RemoveMacro;
GO
DROP PROCEDURE dbo.spMacro_SubscribeMacro;
GO
DROP PROCEDURE dbo.spMacro_UnsubscribeMacro;
GO
DROP PROCEDURE dbo.spMacro_UpdateMacro;
GO
DROP PROCEDURE dbo.spTemplateGrp_RatingList;
GO
exec sp_rename 'dbo.Comparison_Type', 'zzComparison_Type', 'OBJECT';
GO
exec sp_rename 'dbo.Macro', 'zzMacro', 'OBJECT';
GO
exec sp_rename 'dbo.Template_Macro', 'zzTemplate_Macro', 'OBJECT';
GO
exec sp_rename 'dbo.Template_Rating', 'zzTemplate_Rating', 'OBJECT';
GO
exec sp_rename 'dbo.Variable', 'zzVariable', 'OBJECT';
GO

--1949
ALTER PROCEDURE [dbo].[spDataSource_DataObjectList]
	@DataObjectGuid uniqueidentifier = null,
	@DataServiceGuid uniqueidentifier = null
as
	IF @DataObjectGuid IS NULL
		SELECT	o.[Object_Name], o.data_object_guid, o.data_service_guid, o.Merge_Source, 
				o.Object_Type, o.Display_Name
		FROM	data_object o
		WHERE	o.data_service_guid = @DataServiceGuid
		ORDER BY o.[Object_Name];
	ELSE
		SELECT	o.[Object_Name], o.data_object_guid, o.data_service_guid, o.Merge_Source, 
				o.Object_Type, o.Display_Name
		FROM	data_object o
		WHERE	o.data_object_guid = @DataObjectGuid
		ORDER BY o.[Object_Name];
GO


--1950
ALTER procedure [dbo].[spContent_RemoveContentFolder]
	@FolderGuid uniqueidentifier
AS

	DELETE Content_Folder
	WHERE FolderGuid = @FolderGuid;
	
	DELETE Content_Folder_Group
	WHERE FolderGuid = @FolderGuid;
	
	UPDATE Content_Item
	SET FolderGuid = NULL
	WHERE FolderGuid = @FolderGuid;
GO

--1951
ALTER procedure [dbo].[spContent_UpdateContentItem]
	@ContentItemGuid uniqueidentifier,
	@Description nvarchar(1000),
	@Name nvarchar(255),
	@ContentTypeId Int,
	@BusinessUnitGuid uniqueidentifier,
	@ContentDataGuid uniqueidentifier,
	@SizeScale int,
	@Category int,
	@ProviderName nvarchar(50),
	@ReferenceId nvarchar(255),
	@IsIndexed bit,
	@FolderGuid uniqueidentifier
as
	DECLARE @Approvals nvarchar(10)
	DECLARE @CheckedFolderGuid uniqueidentifier
	
	SELECT @CheckedFolderGuid = FolderGuid
	FROM Content_Folder
	WHERE FolderGuid = @FolderGuid
	
	IF NOT EXISTS(SELECT * FROM Content_Item WHERE ContentItem_Guid = @ContentItemGuid)
	begin
		SELECT	@Approvals = OptionValue
		FROM	Global_Options
		WHERE	OptionCode = 'REQUIRE_CONTENT_APPROVAL';
		
		INSERT INTO Content_Item (ContentItem_Guid, [Description], NameIdentity, ContentType_Id, Business_Unit_Guid, ContentData_Guid, SizeScale, Category, Provider_Name, Reference_Id, IsIndexed, Approved, FolderGuid)
		VALUES (@ContentItemGuid, @Description, @Name, @ContentTypeId, @BusinessUnitGuid, @ContentDataGuid, @SizeScale, @Category, @ProviderName, @ReferenceId, 0, CASE WHEN @Approvals = 'true' THEN 0 ELSE 2 END, @CheckedFolderGuid);
	end
	ELSE
		UPDATE Content_Item
		SET NameIdentity = @Name,
			[Description] = @Description,
			SizeScale = @SizeScale,
			ContentData_Guid = @ContentDataGuid,
			Category = @Category,
			Provider_Name = @ProviderName,
			Reference_Id = @ReferenceId,
			IsIndexed = @IsIndexed,
			FolderGuid = @CheckedFolderGuid
		WHERE ContentItem_Guid = @ContentItemGuid;
GO

