truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.0.4');
go
ALTER PROCEDURE [dbo].[spUser_UpdatePassword]
	@UserGuid uniqueidentifier,
	@PasswordHash varchar(1000),
	@PasswordSalt nvarchar(128),
	@PasswordFormat int
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE Intelledox_User
	SET pwdhash = @PasswordHash,
		ChangePassword = 1,
		PwdFormat = @PasswordFormat,
		PwdSalt = @PasswordSalt
	WHERE User_Guid = @UserGuid;
END
GO
UPDATE	Data_Service
SET		Allow_Insert = '0'
WHERE	Allow_Insert IS NULL OR
		Allow_Insert = ' '
GO
UPDATE	Data_Service
SET		Allow_Writeback = '0'
WHERE	Allow_Writeback IS NULL OR
		Allow_Writeback = ' '
GO
UPDATE	Data_Service
SET		Allow_Connection_Export = '0'
WHERE	Allow_Connection_Export IS NULL OR
		Allow_Connection_Export = ' '
GO
ALTER TABLE Data_Service
	ALTER COLUMN Allow_Insert bit not null
GO
ALTER TABLE Data_Service
	ALTER COLUMN Allow_Writeback bit not null
GO
ALTER TABLE Data_Service
	ALTER COLUMN Allow_Connection_Export bit not null
GO
ALTER TABLE dbo.Data_Service ADD CONSTRAINT
	DF_Data_Service_allow_writeback DEFAULT 0 FOR allow_writeback
GO
ALTER TABLE dbo.Data_Service ADD CONSTRAINT
	DF_Data_Service_Allow_Insert DEFAULT 0 FOR Allow_Insert
GO
ALTER TABLE dbo.Data_Service ADD CONSTRAINT
	DF_Data_Service_Allow_Connection_Export DEFAULT 0 FOR Allow_Connection_Export
GO
ALTER TABLE Data_Service
	DROP COLUMN merge_source
GO
ALTER TABLE Data_Service
	DROP COLUMN Database_Object
GO
ALTER TABLE Data_Service
	DROP COLUMN Data_Service_ID
GO
ALTER PROCEDURE [dbo].[spTenant_ProvisionTenant] (
	   @TemplateBusinessUnit uniqueidentifier,
       @TenantName nvarchar(200),
       @FirstName nvarchar(50),
       @LastName nvarchar(50),
       @UserName nvarchar(50),
       @UserPasswordHash varchar(1000),
       @UserPwdSalt nvarchar(128),
	   @UserPwdFormat int,
       @Email nvarchar(50),
       @TenantKey varbinary(50)
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
       INSERT INTO Business_Unit(Business_Unit_Guid, Name, TenantKey)
       VALUES (@TemplateBusinessUnit, @TenantName, @TenantKey)


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
       VALUES (@UserName, @UserPasswordHash, @UserPwdSalt, @UserPwdFormat, 1, 0, @TemplateBusinessUnit, @AdminUserGuid, @@IDENTITY, 0)

       --User address for guest user
       INSERT INTO address_book (full_name, first_name, last_name, email_address)
       VALUES (@TenantName + 'Guest', '', '', '') --Empty?
       --Guest
       INSERT INTO Intelledox_User(Username, Pwdhash, PwdSalt, PwdFormat, WinNT_User, Business_Unit_Guid, User_Guid, Address_ID, IsGuest)
       VALUES (@TenantName + 'Guest', '', '', @UserPwdFormat, 0, @TemplateBusinessUnit, @GuestUserGuid, @@IDENTITY, 1)

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

CREATE TABLE [dbo].[CustomQuestion_Type](
	[CustomQuestionTypeId] [uniqueidentifier] NOT NULL,
	[Description] [nvarchar](50) NOT NULL,
	[Icon] [varbinary](max) NULL,
 CONSTRAINT [PK_CustomQuestion_Type] PRIMARY KEY CLUSTERED 
(
	[CustomQuestionTypeId] ASC
)
) ON [PRIMARY]

GO

CREATE procedure [dbo].[spCustomQuestion_TypeList]
AS
	SELECT *
	FROM CustomQuestion_Type
GO

CREATE PROCEDURE [dbo].[spCustomQuestion_RegisterType]
	@Id uniqueidentifier,
	@Description nvarchar(255),
	@Icon varbinary(MAX)

AS
	IF NOT EXISTS(SELECT * FROM CustomQuestion_Type WHERE CustomQuestionTypeId = @id)
	BEGIN
		INSERT INTO CustomQuestion_Type(CustomQuestionTypeId, Description, Icon)
		VALUES	(@id, @Description, @Icon);
	END

GO

CREATE TABLE [dbo].[CustomQuestion_InputType](
	[InputTypeId] [uniqueidentifier] NOT NULL,
	[CustomQuestionTypeId] [uniqueidentifier] NOT NULL,
	[InputTypeDescription] [nvarchar](255) NULL,
	[ElementLimit] [int] NOT NULL,
	[Required] [bit] NOT NULL,
 CONSTRAINT [PK_CustomQuestion_InputType] PRIMARY KEY CLUSTERED 
(
	[InputTypeId] ASC
)
)  ON [PRIMARY]

GO

CREATE PROCEDURE [dbo].[spCustomQuestion_RegisterInput]
	@CustomQuestionTypeId uniqueidentifier,
	@InputId uniqueidentifier,
	@Description nvarchar(255),
	@ElementLimit int,
	@Required bit
AS
	IF NOT EXISTS(SELECT * 
					FROM CustomQuestion_InputType 
					WHERE InputTypeId = @InputId AND @CustomQuestionTypeId = @CustomQuestionTypeId)
	BEGIN
		INSERT INTO CustomQuestion_InputType(InputTypeId, CustomQuestionTypeId, InputTypeDescription, ElementLimit, [Required])
		VALUES	(@InputId, @CustomQuestionTypeId, @Description, @ElementLimit, @Required);
	END

GO

CREATE procedure [dbo].[spCustomQuestion_InputTypeList]
	@CustomQuestionId uniqueidentifier
AS
	SELECT *
	FROM CustomQuestion_InputType
	WHERE CustomQuestionTypeId = @CustomQuestionId
GO

CREATE TABLE [dbo].[CustomQuestion_Output](
	[CustomQuestionTypeID] [uniqueidentifier] NOT NULL,
	[OutputID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
	[OutputType] [int] NOT NULL,
 CONSTRAINT [PK_CustomQuestion_Output] PRIMARY KEY CLUSTERED 
(
	[OutputID] ASC
)
)
GO

CREATE procedure [dbo].[spCustomQuestion_OutputTypeList]
	@CustomQuestionId uniqueidentifier
AS
	SELECT *
	FROM CustomQuestion_Output
	WHERE CustomQuestionTypeId = @CustomQuestionId

GO

CREATE PROCEDURE [dbo].[spCustomQuestion_RegisterOutput]
	@CustomQuestionTypeId uniqueidentifier,
	@OutputId uniqueidentifier,
	@Name nvarchar(255),
	@OutputType int
AS
	IF NOT EXISTS(SELECT * 
		FROM CustomQuestion_Output 
		WHERE CustomQuestionTypeId = @CustomQuestionTypeId 
			AND OutputId = @OutputId)
	BEGIN
		INSERT INTO CustomQuestion_Output(CustomQuestionTypeId, OutputId, Name, OutputType)
		VALUES	(@CustomQuestionTypeId, @OutputId, @Name, @OutputType);
	END
GO
