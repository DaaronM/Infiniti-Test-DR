truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.4.0.8');
go
IF (NOT EXISTS (SELECT * FROM dbo.FX_PortalAdmin WHERE Username = 'admin'))
BEGIN
	INSERT INTO [dbo].[FX_PortalAdmin]
				   ([UserGuid], [Username], [PwdHash], [PwdSalt], [PwdFormat], [ChangePassword], [Disabled])
			 VALUES(NewID(), 'admin', '', '', 2, 1, 0);		
END
GO
IF OBJECT_ID('[dbo].[spTenant_FetchTenantAdminUsers]') IS NOT NULL
DROP PROCEDURE [dbo].[spTenant_FetchTenantAdminUsers]
GO
ALTER TABLE dbo.Business_Unit
ADD Disabled [bit] NOT NULL DEFAULT 0;
GO
CREATE PROCEDURE [dbo].[spTenant_ChangeStatus]
	@BusinessUnitGuid uniqueidentifier,
	@Disabled bit
AS
	UPDATE	Business_Unit
	SET		Disabled = @Disabled
	WHERE	Business_Unit_GUID = @BusinessUnitGuid;
	
	UPDATE Intelledox_User
	SET		Disabled = @Disabled
	WHERE	Business_Unit_GUID = @BusinessUnitGuid;
GO
ALTER PROCEDURE [dbo].[spTenant_ProvisionTenant] (
	   @TemplateBusinessUnit uniqueidentifier,
       @TenantName nvarchar(200),
       @FirstName nvarchar(50),
       @LastName nvarchar(50),
       @UserName nvarchar(50),
       @UserPasswordHash varchar(1000),
       @UserPwdSalt nvarchar(128),
       @Email nvarchar(50)
)
AS
       DECLARE @AdminUserGuid uniqueidentifier
       DECLARE @GuestUserGuid uniqueidentifier
       DECLARE @TemplateUser uniqueidentifier
       DECLARE @GlobalAdminRoleGuid uniqueidentifier
       DECLARE @TenantGroupGuid uniqueidentifier

       SET @AdminUserGuid = NewID()
       SET @GuestUserGuid = NewID()

       --New business unit (Company in SaaS)
       INSERT INTO Business_Unit(Business_Unit_Guid, Name)
       VALUES (@TemplateBusinessUnit, @TenantName)


       --Insert roles
       --End User
       --Global Administrator
       --Workflow Administrator
       INSERT INTO Administrator_Level(AdminLevel_Description, RoleGuid, Business_Unit_Guid)
       VALUES ('End User', NewId(), @TemplateBusinessUnit)

       SET @GlobalAdminRoleGuid = NewId() -- We need this later
       INSERT INTO Administrator_Level(AdminLevel_Description, RoleGuid, Business_Unit_Guid)
       VALUES ('Global Administrator', @GlobalAdminRoleGuid, @TemplateBusinessUnit)

       INSERT INTO Administrator_Level(AdminLevel_Description, RoleGuid, Business_Unit_Guid)
       VALUES ('Workflow Administrator', NewId(), @TemplateBusinessUnit)
       ---------------------------------------------------------------------------------------

       --Permissions are global
     --Insert into Role_Permission with the new admin level
       INSERT INTO Role_Permission(PermissionGuid, RoleGuid)
       SELECT Permission.PermissionGuid,  @GlobalAdminRoleGuid
       FROM   Permission

       SET @TenantGroupGuid = NewId()
	   --Group address for User Group
       INSERT INTO Address_Book (Organisation_Name)
       VALUES (@TenantName + ' Users')

       --New group
       INSERT INTO User_Group(Name, WinNT_Group, Business_Unit_Guid, Group_Guid, AutoAssignment, SystemGroup, Address_ID)
       VALUES (@TenantName + ' Users', 0, @TemplateBusinessUnit, @TenantGroupGuid, 1, 1, @@IDENTITY)

       --User address for admin user
       INSERT INTO address_book (full_name, first_name, last_name, email_address)
       VALUES (@FirstName + ' ' + @LastName, @FirstName, @LastName, @Email)

       --Admin
       INSERT INTO Intelledox_User(Username, Pwdhash, PwdSalt, PwdFormat, ChangePassword, WinNT_User, Business_Unit_Guid, User_Guid, Address_ID, IsGuest)
       VALUES (@UserName, @UserPasswordHash, @UserPwdSalt, 2, 1, 0, @TemplateBusinessUnit, @AdminUserGuid, @@IDENTITY, 0)

       --User address for guest user
       INSERT INTO address_book (full_name, first_name, last_name, email_address)
       VALUES (@TenantName + 'Guest', '', '', '') --Empty?
       --Guest
       INSERT INTO Intelledox_User(Username, Pwdhash, PwdSalt, PwdFormat, WinNT_User, Business_Unit_Guid, User_Guid, Address_ID, IsGuest)
       VALUES (@TenantName + 'Guest', '', '', 2, 0, @TemplateBusinessUnit, @GuestUserGuid, @@IDENTITY, 1)

       --User permissions
       --Make admin user a global admin (that we previously defined)
       INSERT INTO User_Role(UserGuid, RoleGuid, GroupGuid)
       VALUES(@AdminUserGuid, @GlobalAdminRoleGuid, NULL)

       --Subscribe users to the default group
       INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
       VALUES(@AdminUserGuid, @TenantGroupGuid, 1)

       INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
       VALUES(@GuestUserGuid, @TenantGroupGuid, 1)

       INSERT INTO Global_Options(BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
       SELECT @TemplateBusinessUnit, OptionCode, OptionDescription, OptionValue
       FROM   Global_Options
       WHERE  BusinessUnitGuid = (SELECT Business_Unit_GUID FROM Business_Unit WHERE UPPER(Name) = 'DEFAULT');


       UPDATE Global_Options
       SET OptionValue='DoNotReply@intelledox.com'
       WHERE BusinessUnitGuid = @TemplateBusinessUnit AND OptionCode='FROM_EMAIL_ADDRESS';
GO


















