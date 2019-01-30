truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.4.0.7');
go
ALTER procedure [dbo].[spProject_GetProjectVersions]
	@ProjectGuid uniqueidentifier
as
		SELECT vwTemplateVersion.Template_Version, 
			vwTemplateVersion.Modified_Date,
			vwTemplateVersion.Username,
			ISNULL(vwTemplateVersion.Full_Name, '') AS Full_Name,
			vwTemplateVersion.Comment,
			vwTemplateVersion.LockedByUserGuid,
			vwTemplateVersion.InUse
		FROM	vwTemplateVersion
		WHERE	vwTemplateVersion.Template_Guid = @ProjectGuid
	ORDER BY Modified_Date DESC;
GO
CREATE TABLE [dbo].[FX_PortalAdmin](
	[UserGuid] [uniqueidentifier] NOT NULL,
	[Username] [nvarchar](50) NULL,
	[PwdHash] [varchar](1000) NULL,
	[PwdSalt] [nvarchar](128) NULL,
	[PwdFormat] [int] NOT NULL,
	[ChangePassword] [bit] NOT NULL,
	[Disabled] [bit] NOT NULL
)
GO
ALTER TABLE dbo.FX_PortalAdmin ADD CONSTRAINT
PK_FX_PortalAdmin PRIMARY KEY CLUSTERED 
(
UserGuid
) 
GO
ALTER TABLE dbo.FX_PortalAdmin ADD CONSTRAINT
DF_FX_PortalAdmin_Disabled DEFAULT ((0)) FOR Disabled
GO
ALTER TABLE dbo.FX_PortalAdmin ADD CONSTRAINT
DF_FX_PortalAdmin_ChangePassword DEFAULT ((0)) FOR ChangePassword
GO
ALTER TABLE dbo.FX_PortalAdmin ADD CONSTRAINT
DF_FX_PortalAdmin_PwdFormat DEFAULT ((1)) FOR PwdFormat
GO
INSERT INTO [dbo].[FX_PortalAdmin]
           ([UserGuid], [Username], [PwdHash], [PwdSalt], [PwdFormat], [ChangePassword], [Disabled])
     VALUES(NewID(), 'admin', '', '', 2, 1, 0);
GO
CREATE PROCEDURE [dbo].[FX_spUsers_UserByUsername]
	@Username nvarchar(50)
AS
	SELECT	FX_PortalAdmin.*
	FROM	FX_PortalAdmin
	WHERE	Username = @Username;
GO
CREATE PROCEDURE [dbo].[FX_spUsers_UpdateUser]
	@Username nvarchar(50),
	@Password nvarchar(1000),
	@PasswordSalt nvarchar(128),
	@ChangePassword int,
	@ErrorCode int = 0 output
AS

	BEGIN
		UPDATE FX_PortalAdmin
		SET PwdHash = @Password, 
			PwdSalt = @PasswordSalt,
			ChangePassword = @ChangePassword
		WHERE [Username] = @Username;
	END

	SET @ErrorCode = @@error;
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
       --New group
       INSERT INTO User_Group(Name, WinNT_Group, Business_Unit_Guid, Group_Guid, AutoAssignment, SystemGroup)
       VALUES (@TenantName + ' Users', 0, @TemplateBusinessUnit, @TenantGroupGuid, 1, 1)

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
CREATE PROCEDURE [dbo].[spTenant_UpdateTenant]
	@BusinessUnitID uniqueidentifier,
	@TenantName nvarchar(200) = ''

AS

	UPDATE	Business_Unit
	SET		NAME = @TenantName
	WHERE	Business_Unit_GUID = @BusinessUnitID;
GO
CREATE PROCEDURE [dbo].[spTenant_FetchTenantAdminUsers]
	@BusinessUnitID uniqueidentifier

AS

	SELECT	Intelledox_User.*
	FROM	Intelledox_User
	JOIN	User_Role ON Intelledox_User.User_Guid = User_Role.UserGuid
	JOIN	Administrator_Level ON User_Role.RoleGuid = Administrator_Level.RoleGuid
			AND Intelledox_User.Business_Unit_GUID = Administrator_Level.Business_Unit_GUID
	WHERE	AdminLevel_Description = 'Global Administrator' 
		AND Intelledox_User.Business_Unit_GUID = @BusinessUnitID
	ORDER BY Username;
GO

UPDATE Global_Options
SET OptionValue = '0'
WHERE OptionCode = 'MINIMUM_PASSWORD_LENGTH' AND OptionValue ='1'
GO








