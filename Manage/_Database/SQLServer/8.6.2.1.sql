truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.2.1');
go

UPDATE Content_Item
SET		NameIdentity = LTRIM(RTRIM(NameIdentity))
FROM	Content_Item
WHERE	NameIdentity LIKE ' %'
		OR NameIdentity LIKE '% '
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
       @TenantType int,
       @TenantImage image
)
AS
       DECLARE @GuestUserGuid uniqueidentifier
       DECLARE @TenantGroupGuid uniqueidentifier

       SET @GuestUserGuid = NewID()

       --New business unit (Company in SaaS)
       INSERT INTO Business_Unit(Business_Unit_Guid, Name, TenantKey, TenantType)
       VALUES (@TemplateBusinessUnit, @TenantName, CONVERT(varbinary(MAX), @TenantKey), @TenantType)

		IF DATALENGTH(@TenantImage) > 0
		BEGIN
			UPDATE	Business_Unit
			SET		TenantLogo = @TenantImage
			WHERE	Business_Unit_Guid = @TemplateBusinessUnit
		END

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

ALTER PROCEDURE [dbo].[spTenant_UpdateTenant]
	@BusinessUnitID uniqueidentifier,
	@TenantName nvarchar(200) = '',
	@TenantType int,
	@TenantImage image	

AS

	UPDATE	Business_Unit
	SET		NAME = @TenantName,
			TenantType = @TenantType,
			TenantLogo = CASE WHEN DATALENGTH(@TenantImage) > 0 THEN @TenantImage 
							ELSE TenantLogo END 
	WHERE	Business_Unit_GUID = @BusinessUnitID;
GO

