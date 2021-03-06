truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.1.3');
go
ALTER PROCEDURE [dbo].[spTenant_CreateAdminUser] (
	   @NewBusinessUnit uniqueidentifier,
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
    VALUES (@UserName, @UserPasswordHash, @UserPwdSalt, @UserPwdFormat, 1, 0, @NewBusinessUnit, @AdminUserGuid, @@IDENTITY, 0)

	IF NOT EXISTS(SELECT 1 
					FROM Administrator_Level 
					WHERE AdminLevel_Description = 'Global Administrator' 
						AND Business_Unit_Guid = @NewBusinessUnit)
	BEGIN
		SET @GlobalAdminRoleGuid = NewId() -- We need this later
		INSERT INTO Administrator_Level(AdminLevel_Description, RoleGuid, Business_Unit_Guid)
		VALUES ('Global Administrator', @GlobalAdminRoleGuid, @NewBusinessUnit)
		
		INSERT INTO Role_Permission(PermissionGuid, RoleGuid)
		SELECT Permission.PermissionGuid, @GlobalAdminRoleGuid
		FROM Permission
	END
	ELSE
	BEGIN
		SELECT @GlobalAdminRoleGuid = RoleGuid  
		FROM Administrator_Level 
		WHERE AdminLevel_Description = 'Global Administrator' 
			AND Business_Unit_Guid = @NewBusinessUnit
	END
	
    --Make admin user a global admin (that we previously defined)
	INSERT INTO User_Role(UserGuid, RoleGuid, GroupGuid)
	VALUES(@AdminUserGuid, @GlobalAdminRoleGuid, NULL)

	--Group assignment for the admin user
    INSERT INTO User_Group_Subscription(UserGuid, IsDefaultGroup, GroupGuid)
    SELECT @AdminUserGuid, 1, Group_Guid 
    FROM User_Group
    WHERE SystemGroup = 1 
    AND Business_Unit_Guid = @NewBusinessUnit
GO
ALTER PROCEDURE [dbo].[spTenant_ProvisionTenant] (
	   @NewBusinessUnit uniqueidentifier,
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
       @TenantType int,
       @TenantImage image,
       @LicenseHolderName nvarchar(4000)
)
AS
       DECLARE @GuestUserGuid uniqueidentifier
       DECLARE @TenantGroupGuid uniqueidentifier

       SET @GuestUserGuid = NewID()

       --New business unit (Company in SaaS)
       INSERT INTO Business_Unit(Business_Unit_Guid, Name, TenantKey, TenantType)
       VALUES (@NewBusinessUnit, @TenantName, CONVERT(varbinary(MAX), @TenantKey), @TenantType)

		IF DATALENGTH(@TenantImage) > 0
		BEGIN
			UPDATE	Business_Unit
			SET		TenantLogo = @TenantImage
			WHERE	Business_Unit_Guid = @NewBusinessUnit
		END

       --Insert roles
       --End User
       --Workflow Administrator
       INSERT INTO Administrator_Level(AdminLevel_Description, RoleGuid, Business_Unit_Guid)
       VALUES ('End User', NewId(), @NewBusinessUnit)

       INSERT INTO Administrator_Level(AdminLevel_Description, RoleGuid, Business_Unit_Guid)
       VALUES ('Workflow Administrator', NewId(), @NewBusinessUnit)

       SET @TenantGroupGuid = NewId()
	   --Group address for User Group
       INSERT INTO Address_Book (Organisation_Name)
       VALUES (@TenantName + ' Users')

       --New group
       INSERT INTO User_Group(Name, WinNT_Group, Business_Unit_Guid, Group_Guid, AutoAssignment, SystemGroup, Address_ID)
       VALUES (@TenantName + ' Users', 0, @NewBusinessUnit, @TenantGroupGuid, 1, 1, @@IDENTITY)

	   --Mobile App Users Group
	   INSERT INTO Address_Book(Full_Name, Organisation_Name)
	   VALUES ('Mobile App Users', 'Mobile App Users');

	   INSERT INTO User_Group(Name, WinNT_Group, Business_Unit_Guid, Group_Guid, AutoAssignment, SystemGroup, Address_ID)
	   VALUES ('Mobile App Users', 0, @NewBusinessUnit, NewId(), 0, 1, @@IDENTITY);

		--call procedure for creating admin user, global administrator role, role mapping and group assignment
	   EXEC spTenant_CreateAdminUser @NewBusinessUnit, @AdminUserGuid, @FirstName, @LastName, @UserName, 
										@UserPasswordHash, @UserPwdSalt, @UserPwdFormat, @Email 

       --User address for guest user
       INSERT INTO address_book (full_name, first_name, last_name, email_address)
       VALUES (@LicenseHolderName + '_Guest', '', '', '')
       --Guest
       INSERT INTO Intelledox_User(Username, Pwdhash, PwdSalt, PwdFormat, WinNT_User, Business_Unit_Guid, User_Guid, Address_ID, IsGuest)
       VALUES (@LicenseHolderName + '_Guest', '', '', @UserPwdFormat, 0, @NewBusinessUnit, @GuestUserGuid, @@IDENTITY, 1)

       INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
       VALUES(@GuestUserGuid, @TenantGroupGuid, 1)

       INSERT INTO Global_Options(BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
       SELECT @NewBusinessUnit, OptionCode, OptionDescription, OptionValue
       FROM   Global_Options
       WHERE  BusinessUnitGuid = (SELECT OptionValue
									FROM Global_Options
									WHERE UPPER(OptionCode) = 'DEFAULT_TENANT');

       UPDATE Global_Options
       SET OptionValue='DoNotReply@intelledox.com'
       WHERE BusinessUnitGuid = @NewBusinessUnit AND OptionCode='FROM_EMAIL_ADDRESS';

	   --sync the license holder name to tenant name
       UPDATE Global_Options
       SET OptionValue=@LicenseHolderName
       WHERE BusinessUnitGuid = @NewBusinessUnit AND OptionCode='LICENSE_HOLDER';
GO
ALTER TABLE [dbo].[CustomQuestion_Type]
	ADD [Icon48] [varbinary](max) NULL
GO
UPDATE CustomQuestion_Type
SET Icon48 = Icon
WHERE Icon48 IS NULL
GO
DELETE FROM CustomQuestion_Type
WHERE CustomQuestionTypeId = '8681C0A9-831B-4E49-9445-EB659E1BF033'
GO
ALTER PROCEDURE [dbo].[spCustomQuestion_RegisterType]
	@Id uniqueidentifier,
	@Description nvarchar(255),
	@Icon16 varbinary(MAX),
	@Icon48 varbinary(MAX),
	@ModuleId nvarchar(4) = NULL

AS
	IF NOT EXISTS(SELECT * FROM CustomQuestion_Type WHERE CustomQuestionTypeId = @id)
	BEGIN
		INSERT INTO CustomQuestion_Type(CustomQuestionTypeId, Description, Icon, Icon48, ModuleId)
		VALUES	(@id, @Description, @Icon16, @Icon48, @ModuleId);
	END
GO
