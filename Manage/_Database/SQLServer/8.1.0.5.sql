/*
** Database Update package 8.1.0.5
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.1.0.5');
go

--2055

ALTER TABLE dbo.[Document] ADD
	Downloadable bit NOT NULL CONSTRAINT DF_Document_Downloadable DEFAULT 0;
GO
	
ALTER procedure [dbo].[spDocument_GetCleanupJobs]
AS
	SELECT JobId
	FROM Document
	WHERE Downloadable = 0
		AND DateCreated < DATEADD(hour, -CAST((SELECT OptionValue 
									FROM Global_Options 
									WHERE OptionCode = 'CLEANUP_HOURS') AS float), GetUtcDate());
GO

ALTER procedure [dbo].[spDocument_Cleanup]
AS
	DELETE FROM Document
	WHERE	Downloadable = 0 
		AND DateCreated < DATEADD(hour, -CAST((SELECT OptionValue 
									FROM Global_Options 
									WHERE OptionCode = 'CLEANUP_HOURS') AS float), GetUtcDate());
GO

INSERT INTO Global_Options (OptionCode, OptionDescription, OptionValue)
VALUES ('DOWNLOADABLE_DOC_NUM', 'Number of Documents to keep available for download per user', 0);
GO

ALTER PROCEDURE [dbo].[spDocument_InsertDocument]
	@DocumentId uniqueidentifier,
	@Extension nvarchar(10),
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier,
	@DisplayName nvarchar(255),
	@DateCreated datetime,
	@DocumentBinary varbinary(max),
	@DocumentLength int,
	@ProjectDocumentGuid uniqueidentifier
as
	INSERT INTO Document(DocumentId, 
		Extension, 
		JobId, 
		UserGuid, 
		DisplayName, 
		DateCreated, 
		DocumentBinary, 
		DocumentLength,
		ProjectDocumentGuid,
		Downloadable)
	VALUES (@DocumentId, 
		@Extension, 
		@JobId, 
		@UserGuid, 
		@DisplayName, 
		@DateCreated, 
		@DocumentBinary, 
		@DocumentLength,
		@ProjectDocumentGuid,
		1);
		
	-- Update less recent documents to be no longer "downloadable"
	-- First get the setting
	DECLARE @DownloadableDocNum int;
	SET @DownloadableDocNum = (SELECT OptionValue 
		FROM Global_Options 
		WHERE OptionCode = 'DOWNLOADABLE_DOC_NUM');
		
	-- Then create a table and fill it with the documents we have to keep
	CREATE TABLE #DownloadableDocs (
		JobId uniqueidentifier,
		DateCreated datetime);
		
	SET ROWCOUNT @DownloadableDocNum;
	
	INSERT #DownloadableDocs (JobId, DateCreated)
	SELECT JobId, DateCreated
		FROM Document
		WHERE UserGuid = @UserGuid
		GROUP BY JobId, DateCreated
		ORDER BY DateCreated DESC;
		
	SET ROWCOUNT 0;
			
	-- Then update any documents that aren't ones we're supposed to keep
	UPDATE Document
	SET Downloadable = 0
	WHERE UserGuid = @UserGuid
		AND JobId NOT IN
			(
			SELECT JobId
			FROM #DownloadableDocs
			);
GO

ALTER PROCEDURE [dbo].[spDocument_DocumentList] (
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier
)
AS
	SELECT	Document.DocumentId, 
			Document.Extension,  
			Document.DisplayName,  
			Document.ProjectDocumentGuid,  
			Document.DateCreated,  
			Document.JobId,
			Template.Name As ProjectName
	FROM	Document
			INNER JOIN ProcessJob ON Document.JobId = ProcessJob.JobId
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template_Group_Item ON Template_Group.Template_Group_Guid = Template_Group_Item.Template_Group_Guid
			INNER JOIN Template ON Template_Group_Item.Template_Guid = Template.Template_Guid
	WHERE	(Document.JobId = @JobId OR @JobId IS NULL)
			AND Document.UserGuid = @UserGuid --Security check;
GO
			
CREATE PROCEDURE [dbo].[spDocument_DeleteDocument]
	@DocumentId uniqueidentifier
as
	DELETE FROM	Document
	WHERE	DocumentId = @DocumentId;

GO

--2056
UPDATE	User_Group
SET		Name = 'Infiniti Users'
WHERE	Name = 'Intelledox Users' and SystemGroup = 1;
GO
ALTER procedure [dbo].[spBU_ProvisionTenant] (
	@BusinessUnitGuid uniqueidentifier,
	@TenantName nvarchar(200),
	@UserType int, -- 0 = normal user, 1 = admin, 2 = global admin (site owner)
	@FirstName nvarchar(200),
	@LastName nvarchar(200),
	@UserName nvarchar(50),
	@UserPasswordHash varchar(100),
	@UserPasswordSalt nvarchar(128),
	@SubscriptionType int = 1,
	@ExpiryDate datetime = null, --ExpiryDate is required if SubscriptionType is "1".
	@DefaultLanguage nvarchar(10) = null, --Leave null for default.
	@UserEmail nvarchar(200) = null
)
AS
	DECLARE @UserGuid uniqueidentifier
	DECLARE @TemplateBusinessUnit uniqueidentifier

	SET @UserGuid = NewID()

	SELECT	@TemplateBusinessUnit = Business_Unit_Guid
	FROM	Business_Unit
	WHERE	Name = 'Default'

	IF (select count(*) from business_unit where Business_Unit_Guid = @BusinessUnitGuid) = 0
	begin

		IF (@DefaultLanguage is null or @DefaultLanguage = '')
		begin
			if (select count(*) from Business_Unit where name = 'Default') = 1
				select top 1 @DefaultLanguage = DefaultLanguage from Business_Unit where Name = 'Default';
			else
				set @DefaultLanguage = 'en-AU';
		end

		--New business unit
		INSERT INTO Business_Unit(Business_Unit_Guid, Name, SubscriptionType, ExpiryDate, TenantFee, DefaultLanguage, UserFee)
		VALUES (@BusinessUnitGuid, @TenantName, @SubscriptionType, @ExpiryDate, 0, @DefaultLanguage, 0);
	end
	

	declare @FullAdminRoleGuid uniqueidentifier,
			@AdminRoleGuid uniqueidentifier,
			@UserRoleGuid uniqueidentifier
	
	--Roles
	IF (select count(*) from Administrator_Level where Business_Unit_Guid = @BusinessUnitGuid) = 0
	begin
		set @FullAdminRoleGuid = newid();
		set @AdminRoleGuid = newid();
		set @UserRoleGuid = newid();
		
		insert into Administrator_Level (AdminLevel_Description, RoleGuid, Business_Unit_Guid)
		values (substring(@TenantName, 0, 36) + ' Global Admin', @FullAdminRoleGuid, @BusinessUnitGuid);
		
		insert into Administrator_Level (AdminLevel_Description, RoleGuid, Business_Unit_Guid)
		values (substring(@TenantName, 0, 36) + ' Administrator', @AdminRoleGuid, @BusinessUnitGuid);
		
		insert into Administrator_Level (AdminLevel_Description, RoleGuid, Business_Unit_Guid)
		values (substring(@TenantName, 0, 36) + ' User', @UserRoleGuid, @BusinessUnitGuid);
		
		--Role Permissions
		
		--full admin
		insert into Role_Permission (PermissionGuid, RoleGuid)
		select Permission.PermissionGuid, @FullAdminRoleGuid
		from Permission;
		--admin
		insert into Role_Permission (PermissionGuid, RoleGuid) values (cast('CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' as uniqueidentifier), @AdminRoleGuid);
		insert into Role_Permission (PermissionGuid, RoleGuid) values (cast('6B96BAF3-8A76-4F42-B1E7-DF87142444E0' as uniqueidentifier), @AdminRoleGuid);
		insert into Role_Permission (PermissionGuid, RoleGuid) values (cast('FA2C7769-6D15-442E-9F7F-E8CE82590D8D' as uniqueidentifier), @AdminRoleGuid);
	end
	else
	begin
		select @FullAdminRoleGuid = RoleGuid from Administrator_Level where AdminLevel_Description like '%Global Admin' and Business_Unit_Guid = @BusinessUnitGuid;
		select @AdminRoleGuid = RoleGuid from Administrator_Level where AdminLevel_Description like '%Administrator' and Business_Unit_Guid = @BusinessUnitGuid;
		select @UserRoleGuid = RoleGuid from Administrator_Level where AdminLevel_Description like '%User' and Business_Unit_Guid = @BusinessUnitGuid;
	end
	
	--Groups
	IF (select count(*) from User_Group where Business_Unit_Guid = @BusinessUnitGuid) = 0
	begin
		declare @UG uniqueidentifier
		set @UG = newid()
		
		INSERT INTO User_Group(Name, WinNT_Group, Business_Unit_Guid, Group_Guid, AutoAssignment, SystemGroup)
		SELECT	@TenantName + ' Users', WinNT_Group, @BusinessUnitGuid, @UG, AutoAssignment, SystemGroup
		FROM	User_Group
		WHERE	Name = 'Infiniti Users' and SystemGroup = 1;
	end
	
	--User Address
	INSERT INTO address_book (full_name, first_name, last_name, email_address)
	VALUES (@FirstName + ' ' + @LastName, @FirstName, @LastName, @UserEmail)
	
	--User
	INSERT INTO Intelledox_User(Username, Pwdhash, WinNT_User, Business_Unit_Guid, User_Guid, PwdFormat, PwdSalt, Address_ID)
	VALUES (@UserName, @UserPasswordHash, 0, @BusinessUnitGuid, @UserGuid, 2, @UserPasswordSalt, @@IDENTITY)


	--User Permissions
	declare @UserRole uniqueidentifier;
	if @UserType = 0
		set @UserRole = @UserRoleGuid;
	else
		if @UserType = 1
			set @UserRole = @AdminRoleGuid;
		else
			set @UserRole = @FullAdminRoleGuid;
	
	insert into user_role (UserGuid, RoleGuid, GroupGuid)
	values (@UserGuid, @UserRole, NULL);
	
	--User Group subscription
	declare @GroupGuid uniqueidentifier
			
	select @GroupGuid = Group_Guid from user_group where business_unit_guid = @BusinessUnitGuid;
	
	INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
	values (@UserGuid, @GroupGuid, 1);
GO

--2057
ALTER TABLE dbo.ActionListState ADD
	AllowReassign bit NOT NULL CONSTRAINT DF_ActionListState_AllowReassign DEFAULT 0,
	RestrictToGroupGuid uniqueidentifier NULL
GO

