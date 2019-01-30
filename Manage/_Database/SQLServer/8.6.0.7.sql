truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.0.7');
go
ALTER PROCEDURE [dbo].[spUser_AddToPasswordHistory]
	@UserId int,
	@PwdHash varchar(1000)
AS
BEGIN
	DECLARE @HistoryLimit integer
	DECLARE @BusinessUnitGuid uniqueidentifier
	DECLARE @UserGuid uniqueidentifier

	SELECT	@BusinessUnitGuid = Business_Unit_GUID,
			@UserGuid = User_Guid
	FROM	Intelledox_User
	WHERE	User_ID = @UserId;

	SET @HistoryLimit = (SELECT Global_Options.OptionValue 
						FROM Global_Options 
						WHERE  Global_Options.BusinessUnitGuid = @BusinessUnitGuid
							AND Global_Options.OptionCode = 'PASSWORD_HISTORY_COUNT')

	IF (@HistoryLimit > 0)
	BEGIN
		INSERT INTO [Password_History] (User_Guid, pwdhash)
		VALUES (@UserGuid, @PwdHash)

		DELETE FROM Password_History
		WHERE id NOT IN (SELECT TOP (@HistoryLimit) id 
						FROM Password_History 
						WHERE User_Guid = @UserGuid
						ORDER BY DateCreatedUtc DESC)
			AND User_Guid = @UserGuid;
	END
END
GO

ALTER PROCEDURE [dbo].[spTenant_CreateAdminUser] (
	   @TemplateBusinessUnit uniqueidentifier,
	   @AdminUserGuid uniqueidentifier,
       @FirstName nvarchar(50),
       @LastName nvarchar(50),
       @UserName nvarchar(256),
       @UserPasswordHash varchar(1000),
       @UserPwdSalt nvarchar(128),
       @UserPwdFormat int,
       @Email nvarchar(256)
)
AS
		
	DECLARE @GlobalAdminRoleGuid uniqueidentifier

	--User address for admin user
    INSERT INTO Address_Book (Full_Name, First_Name, Last_Name, Email_Address)
    VALUES (@FirstName + ' ' + @LastName, @FirstName, @LastName, @Email)

    --Admin
    INSERT INTO Intelledox_User(Username, Pwdhash, PwdSalt, PwdFormat, ChangePassword, WinNT_User, Business_Unit_Guid, User_Guid, Address_ID, IsGuest)
    VALUES (@UserName, @UserPasswordHash, @UserPwdSalt, @UserPwdFormat, 1, 0, @TemplateBusinessUnit, @AdminUserGuid, @@IDENTITY, 0)

	IF NOT EXISTS(SELECT 1 
					FROM Administrator_Level 
					WHERE AdminLevel_Description = 'Global Administrator' 
						AND Business_Unit_Guid = @TemplateBusinessUnit)
	BEGIN
		SET @GlobalAdminRoleGuid = NewId() -- We need this later
		INSERT INTO Administrator_Level(AdminLevel_Description, RoleGuid, Business_Unit_Guid)
		VALUES ('Global Administrator', @GlobalAdminRoleGuid, @TemplateBusinessUnit)
		
		INSERT INTO Role_Permission(PermissionGuid, RoleGuid)
		SELECT Permission.PermissionGuid, @GlobalAdminRoleGuid
		FROM Permission
	END
	ELSE
	BEGIN
		SELECT @GlobalAdminRoleGuid = RoleGuid  
		FROM Administrator_Level 
		WHERE AdminLevel_Description = 'Global Administrator' 
			AND Business_Unit_Guid = @TemplateBusinessUnit
	END
	
    --Make admin user a global admin (that we previously defined)
	INSERT INTO User_Role(UserGuid, RoleGuid, GroupGuid)
	VALUES(@AdminUserGuid, @GlobalAdminRoleGuid, NULL)

	--Group assignment for the admin user
    INSERT INTO User_Group_Subscription(UserGuid, IsDefaultGroup, GroupGuid)
    SELECT @AdminUserGuid, 1, Group_Guid 
    FROM User_Group
    WHERE SystemGroup = 1 
    AND UPPER(Name) <> 'MOBILE APP USERS'
    AND Business_Unit_Guid = @TemplateBusinessUnit
GO

ALTER PROCEDURE [dbo].[spTenant_ProvisionTenant] (
	   @TemplateBusinessUnit uniqueidentifier,
	   @AdminUserGuid uniqueidentifier,
       @TenantName nvarchar(200),
       @FirstName nvarchar(50),
       @LastName nvarchar(50),
       @UserName nvarchar(256),
       @UserPasswordHash varchar(1000),
       @UserPwdSalt nvarchar(128),
       @UserPwdFormat int,
       @Email nvarchar(256),
       @TenantKey varbinary(MAX),
       @TenantType int
)
AS
       DECLARE @GuestUserGuid uniqueidentifier
       DECLARE @TenantGroupGuid uniqueidentifier

       SET @GuestUserGuid = NewID()

       --New business unit (Company in SaaS)
       INSERT INTO Business_Unit(Business_Unit_Guid, Name, TenantKey, TenantType)
       VALUES (@TemplateBusinessUnit, @TenantName, CONVERT(varbinary(MAX), @TenantKey), @TenantType)

       --Insert roles
       --End User
       --Workflow Administrator
       INSERT INTO Administrator_Level(AdminLevel_Description, RoleGuid, Business_Unit_Guid)
       VALUES ('End User', NewId(), @TemplateBusinessUnit)

       INSERT INTO Administrator_Level(AdminLevel_Description, RoleGuid, Business_Unit_Guid)
       VALUES ('Workflow Administrator', NewId(), @TemplateBusinessUnit)

       SET @TenantGroupGuid = NewId()
	   --Group address for User Group
       INSERT INTO Address_Book (Organisation_Name)
       VALUES (@TenantName + ' Users')

       --New group
       INSERT INTO User_Group(Name, WinNT_Group, Business_Unit_Guid, Group_Guid, AutoAssignment, SystemGroup, Address_ID)
       VALUES (@TenantName + ' Users', 0, @TemplateBusinessUnit, @TenantGroupGuid, 1, 1, @@IDENTITY)

	   --Mobile App Users Group
	   INSERT INTO Address_Book(Full_Name, Organisation_Name)
	   VALUES ('Mobile App Users', 'Mobile App Users');

	   INSERT INTO User_Group(Name, WinNT_Group, Business_Unit_Guid, Group_Guid, AutoAssignment, SystemGroup, Address_ID)
	   VALUES ('Mobile App Users', 0, @TemplateBusinessUnit, NewId(), 0, 1, @@IDENTITY);

		--call procedure for creating admin user, global administrator role, role mapping and group assignment
	   EXEC spTenant_CreateAdminUser @TemplateBusinessUnit, @AdminUserGuid, @FirstName, @LastName, @UserName, 
										@UserPasswordHash, @UserPwdSalt, @UserPwdFormat, @Email 

       --User address for guest user
       INSERT INTO address_book (full_name, first_name, last_name, email_address)
       VALUES (@TenantName + 'Guest', '', '', '')
       --Guest
       INSERT INTO Intelledox_User(Username, Pwdhash, PwdSalt, PwdFormat, WinNT_User, Business_Unit_Guid, User_Guid, Address_ID, IsGuest)
       VALUES (@TenantName + 'Guest', '', '', @UserPwdFormat, 0, @TemplateBusinessUnit, @GuestUserGuid, @@IDENTITY, 1)

       INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
       VALUES(@GuestUserGuid, @TenantGroupGuid, 1)

       INSERT INTO Global_Options(BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
       SELECT @TemplateBusinessUnit, OptionCode, OptionDescription, OptionValue
       FROM   Global_Options
       WHERE  BusinessUnitGuid = (SELECT OptionValue
									FROM Global_Options
									WHERE UPPER(OptionCode) = 'DEFAULT_TENANT');

       UPDATE Global_Options
       SET OptionValue='DoNotReply@intelledox.com'
       WHERE BusinessUnitGuid = @TemplateBusinessUnit AND OptionCode='FROM_EMAIL_ADDRESS';

	   --sync the license holder name to tenant name
       UPDATE Global_Options
       SET OptionValue=@TenantName
       WHERE BusinessUnitGuid = @TemplateBusinessUnit AND OptionCode='LICENSE_HOLDER';
GO

ALTER procedure [dbo].[spProject_GetInUseProjectLicenseCount]
	@BusinessUnitGuid uniqueidentifier,
	@Anonymous bit,
	@ErrorCode int = 0 output
AS

BEGIN

	SELECT COUNT(DISTINCT Template_Guid) 
	FROM Template_Group
	INNER JOIN Folder_Group ON Template_Group.Folder_Guid = Folder_Group.FolderGuid 
	INNER JOIN User_Group_Subscription ON Folder_Group.GroupGuid = User_Group_Subscription.GroupGuid
	INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
	WHERE Intelledox_User.IsGuest = @Anonymous
	AND [Disabled] = 0 AND Business_Unit_GUID = @BusinessUnitGuid;

	SET @ErrorCode = @@ERROR;
	
END
GO

IF NOT EXISTS(SELECT * FROM Global_Options WHERE OptionCode = 'DEFAULT_TENANT')
BEGIN
INSERT INTO Global_Options (BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
VALUES ('00000000-0000-0000-0000-000000000000', 'DEFAULT_TENANT', 'Business Unit Guid of the default tenant', '0CC2007E-3344-4059-B368-9BAD2B9BD42B');
END
GO

ALTER procedure [dbo].[spTenant_BusinessUnitList]
	@BusinessUnitGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	IF (@BusinessUnitGuid IS NULL)
	BEGIN
		SELECT	*
		FROM	Business_Unit;
	END
	ELSE
	BEGIN
		SELECT	*
		FROM	Business_Unit
		WHERE	Business_Unit_Guid = @BusinessUnitGuid;
	END

	set @errorcode = @@error;
GO

ALTER PROCEDURE [dbo].[spTenant_GetDefaultPublishedProjectList]
	@BusinessUnitGuid uniqueidentifier

AS

	SELECT	DISTINCT t.Name AS Template_Name, t.Template_Guid AS Template_Guid, tg.Template_Group_Guid, PublishStartDate
	FROM	Folder f
			INNER JOIN Template_Group tg on f.Folder_Guid = tg.Folder_Guid
			INNER JOIN Template t on tg.Template_Guid = t.Template_Guid
	WHERE	f.Business_Unit_GUID = (SELECT OptionValue
										FROM Global_Options
										WHERE UPPER(OptionCode) = 'DEFAULT_TENANT')
			AND t.Name NOT IN (SELECT Name
								FROM Template
								WHERE Business_Unit_GUID = @BusinessUnitGuid)
	ORDER BY t.Name, PublishStartDate;

GO

CREATE PROCEDURE [dbo].[spTenant_GetExistingProjectListByBu]
	@BusinessUnitGuid uniqueidentifier

AS

	SELECT	DISTINCT t.Name AS Template_Name, t.Template_Guid AS Template_Guid
	FROM	Template t
	WHERE	Business_Unit_GUID = @BusinessUnitGuid
	AND		t.Name IN (SELECT Name 
					   FROM Template t
					   INNER JOIN Template_Group tg ON t.Template_Guid = tg.Template_Guid
					   INNER JOIN Folder f ON tg.Folder_Guid = f.Folder_Guid
					   WHERE t.Business_Unit_GUID = (SELECT OptionValue
												   FROM Global_Options
												   WHERE UPPER(OptionCode) = 'DEFAULT_TENANT'))
	ORDER BY t.Name;

GO
