/*
** Database Update package 5.1.0.6
*/

--set version
truncate table dbversion
go
insert into dbversion values ('5.1.0.6')
go

--1832
IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.Columns WHERE TABLE_NAME = 'Intelledox_User' AND COLUMN_NAME = 'ChangePassword')
	ALTER TABLE dbo.Intelledox_User
		ADD ChangePassword bit null
GO
ALTER procedure [dbo].[spUsers_updateUser]
	@UserID int,
	@Username nvarchar(50),
	@Password nvarchar(1000),
	@NewID int = 0 output,
	@WinNT_User char(1),
	@BusinessUnitGUID uniqueidentifier,
	@User_GUID uniqueidentifier,
	@SelectedTheme nvarchar(100),
	@ChangePassword int,
	@ErrorCode int = 0 output
as
	if @UserID = 0 OR @UserID IS NULL
	begin
		INSERT INTO Intelledox_User(Username, PwdHash, WinNT_User, Business_Unit_GUID, User_Guid, SelectedTheme, ChangePassword)
		VALUES (@Username, @Password, @WinNT_User, @BusinessUnitGUID, @User_Guid, @SelectedTheme, @ChangePassword)
		
		select @NewID = @@identity

		INSERT INTO User_Group_Subscription(User_ID, User_Group_ID, Default_Group)
		SELECT	@NewID, User_Group.User_Group_ID, 0
		FROM	User_Group
		WHERE	User_Group.AutoAssignment = '1'
	end
	else
	begin
		update Intelledox_User
		SET Username = @Username,  
			PwdHash = @Password, 
			WinNT_User = @WinNT_User,
			SelectedTheme = @SelectedTheme,
			ChangePassword = @ChangePassword
		where [User_ID] = @UserID
	end

	set @ErrorCode = @@error
GO

--1833
CREATE procedure [dbo].[spUsers_UserByUsername]
	@UserName nvarchar(50)
AS
	SELECT	Intelledox_User.*, Business_Unit.DefaultLanguage
	FROM	Intelledox_User
			INNER JOIN Business_Unit ON Intelledox_User.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
	WHERE	Intelledox_User.Username = @UserName;
GO
ALTER procedure [dbo].[spUsers_UserGroupByUser]
	@UserID int,
	@BusinessUnitGUID uniqueidentifier,
	@Username nvarchar(50) = '',
	@UserGroupID int = 0,
	@UserGuid uniqueidentifier = null,
	@ErrorCode int = 0 output
as
/* MOD HISTORY
VERSION	DATE		DEVELOPER		DESCRIPTION
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
3.2.2		14-dec-04	chrisg			Allow filtering on username and usergroupid (new parameters)
*/
	if @UserGroupID = 0	--all user groups
	begin
		if @UserGuid is null
		begin
			if @UserID is null or @UserID = 0
			begin
				select	a.*, Business_Unit.DefaultLanguage
				from	Intelledox_User a
					left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
				where	(@Username = '' OR @Username is null OR a.[Username] like @Username + '%')
					AND (a.Business_Unit_GUID = @BusinessUnitGUID)
				ORDER BY a.[Username]
			end
			else
			begin
				select	a.*, b.*, c.Default_Group, d.Full_Name, Business_Unit.DefaultLanguage
				from	Intelledox_User a
					left join User_Group_Subscription c on a.[User_ID] = c.[User_ID]
					left join User_Group b on c.User_Group_ID = b.User_Group_ID
					left join Address_Book d on a.[User_ID] = d.[User_ID]
					left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
				where	(a.[User_ID] = @UserID)
				ORDER BY a.[Username]
			end
		end
		else
		begin
			select	a.*, b.*, c.Default_Group, d.Full_Name, Business_Unit.DefaultLanguage
			from	Intelledox_User a
				left join User_Group_Subscription c on a.[User_ID] = c.[User_ID]
				left join User_Group b on c.User_Group_ID = b.User_Group_ID
				left join Address_Book d on a.[User_ID] = d.[User_ID]
				left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			where	(User_Guid = @UserGuid)
			ORDER BY a.[Username]
		end
	end
	else
	begin
		if @UserGroupID = -1	--users with no user groups
		begin
			select	a.*, b.*, c.Default_Group, d.Full_Name, Business_Unit.DefaultLanguage
			from	Intelledox_User a
				left join User_Group_Subscription c on a.[User_ID] = c.[User_ID]
				left join User_Group b on c.User_Group_ID = b.User_Group_ID
				left join Address_Book d on a.[User_ID] = d.[User_ID]
				left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			where	(@UserID = 0 OR @UserID IS NULL OR a.[User_ID] = @UserID)
				AND	(@Username = '' OR @Username is null OR a.[Username] like @Username + '%')
				AND	a.[User_ID] not in (
						select a.[user_id]
						from user_group_subscription a 
						inner join user_Group b on a.user_group_id = b.user_group_id
						where b.deleted = 0 or b.deleted is null
					)
				AND (@UserID <> 0 OR a.Business_Unit_GUID = @BusinessUnitGUID)
			ORDER BY a.[Username]
		end
		else			--users in specified user group
		begin
			select	a.*, b.*, c.Default_Group, d.Full_Name, Business_Unit.DefaultLanguage
			from	Intelledox_User a
				left join User_Group_Subscription c on a.[User_ID] = c.[User_ID]
				left join User_Group b on c.User_Group_ID = b.User_Group_ID
				left join Address_Book d on a.[User_ID] = d.[User_ID]
				left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			where	(@UserID = 0 OR @UserID IS NULL OR a.[User_ID] = @UserID)
				AND	(@Username = '' OR @Username is null OR a.[Username] like @Username + '%')
				AND	c.User_Group_ID = @UserGroupID
				AND (@UserID <> 0 OR a.Business_Unit_GUID = @BusinessUnitGUID)
			ORDER BY a.[Username]
		end
	end

	set @ErrorCode = @@error
GO


--1834
CREATE PROCEDURE [dbo].[spProjectGroup_Recent]
	@UserGuid uniqueidentifier,
	@ProjectSearch nvarchar(100)
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid
	
	SELECT	TOP 5 d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, b.Template_ID, b.[Name] as Template_Name, 
			b.Template_Type_ID, b.FormatTypeId, d.Template_Group_Guid, MAX(l.DateTime_Start) as DateTime_Start
	FROM	Folder a
			INNER JOIN Folder_Template c on a.Folder_ID = c.Folder_ID
			INNER JOIN Template_Group d on c.folderitem_ID = d.Template_Group_ID and itemtype_id = 1
			INNER JOIN Template_Group_Item e on d.Template_Group_ID = e.Template_Group_ID
			INNER JOIN Template b on e.Template_ID = b.Template_ID
			INNER JOIN Template_Log l on d.Template_Group_ID = l.Template_Group_ID
			INNER JOIN Intelledox_User u on u.[User_Id] = l.[User_Id]
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
			AND u.[User_Guid] = @UserGuid
	GROUP BY d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END, 
			d.HelpText, b.Template_ID, b.[Name], 
			b.Template_Type_ID, b.FormatTypeId, d.Template_Group_Guid
	ORDER BY MAX(l.DateTime_Start) DESC
GO


--1835
CREATE TABLE dbo.ProcessJob
	(
	JobId uniqueidentifier NOT NULL,
	Completed bit NOT NULL
	)
GO
ALTER TABLE dbo.ProcessJob ADD CONSTRAINT
	PK_ProcessJob PRIMARY KEY CLUSTERED 
	(
	JobId
	) ON [PRIMARY]
GO
CREATE TABLE dbo.Document
	(
	DocumentId uniqueidentifier NOT NULL,
	Extension nvarchar(10) NOT NULL,
	JobId uniqueidentifier NOT NULL,
	UserGuid uniqueidentifier NOT NULL,
	DisplayName nvarchar(255) NOT NULL,
	DateCreated datetime NOT NULL,
	DocumentBinary varbinary(MAX) NOT NULL,
	DocumentLength int NOT NULL
	)  ON [PRIMARY]
	 TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE dbo.Document ADD CONSTRAINT
	PK_Document PRIMARY KEY CLUSTERED 
	(
	DocumentId,
	Extension
	) ON [PRIMARY]
GO
CREATE PROCEDURE dbo.spDocument_Cleanup
AS
	DELETE FROM Document
	WHERE	DateCreated < DATEADD(d, -1, GetDate());
GO
CREATE PROCEDURE dbo.spDocument_DocumentBinary (
	@UserGuid uniqueidentifier,
	@DocumentId uniqueidentifier,
	@Extension nvarchar(10)
)
AS
	SELECT	DocumentBinary, DocumentLength
	FROM	Document
	WHERE	UserGuid = @UserGuid	--Security Check
			AND DocumentId = @DocumentId
			AND Extension = @Extension;
GO
CREATE PROCEDURE [dbo].[spDocument_InsertDocument]
	@DocumentId uniqueidentifier,
	@Extension nvarchar(10),
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier,
	@DisplayName nvarchar(255),
	@DateCreated datetime,
	@DocumentBinary varbinary(max),
	@DocumentLength int
as
	INSERT INTO Document(DocumentId, Extension, JobId, UserGuid, DisplayName, DateCreated, DocumentBinary, DocumentLength)
	VALUES (@DocumentId, @Extension, @JobId, @UserGuid, @DisplayName, @DateCreated, @DocumentBinary, @DocumentLength);
GO
CREATE PROCEDURE dbo.spJob_IsComplete (
	@JobId uniqueidentifier
)
AS
	SELECT	Completed
	FROM	ProcessJob
	WHERE	JobId = @JobId;
GO
CREATE PROCEDURE dbo.spJob_JobCompleted (
	@JobId uniqueidentifier
)
AS
	UPDATE	ProcessJob
	SET		Completed = 1
	WHERE	JobId = @JobId;
GO
CREATE PROCEDURE dbo.spJob_LodgeJob (
	@JobId uniqueidentifier
)
AS
	INSERT INTO ProcessJob(JobId, Completed)
	VALUES (@JobId, 0);
GO
CREATE PROCEDURE dbo.[spDocument_DocumentList] (
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier
)
AS
	SELECT	DocumentId, Extension, DisplayName
	FROM	Document
	WHERE	JobId = @JobId
			AND UserGuid = @UserGuid --Security check;
GO

