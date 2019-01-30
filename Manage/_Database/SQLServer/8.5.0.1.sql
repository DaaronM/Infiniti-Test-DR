truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.5.0.1');
go
INSERT INTO Group_Output(GroupGuid, FormatTypeId, LockOutput)
SELECT	DISTINCT GroupGuid, 19, 0
FROM	Group_Output
WHERE	GroupGuid NOT IN (
		SELECT	GroupGuid
		FROM	Group_Output
		WHERE	FormatTypeId = 19 or
				FormatTypeId = 20)
GO

ALTER TABLE dbo.Business_Unit ADD
	TenantKey varbinary(50) NULL
GO

ALTER TABLE dbo.Answer_File ADD
	EncryptedAnswerString varbinary(MAX) NULL
GO

ALTER TABLE dbo.Template_Log ADD
	EncryptedAnswerFile varbinary(MAX) NULL
GO

ALTER PROCEDURE [dbo].[spTenant_ProvisionTenant] (
	   @TemplateBusinessUnit uniqueidentifier,
       @TenantName nvarchar(200),
       @FirstName nvarchar(50),
       @LastName nvarchar(50),
       @UserName nvarchar(50),
       @UserPasswordHash varchar(1000),
       @UserPwdSalt nvarchar(128),
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

INSERT INTO Global_Options (BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
VALUES ('00000000-0000-0000-0000-000000000000', 'ENCRYPT_DATA', 'Encrypt Answer Files and Project Definitions in Database', 'false');
GO

CREATE PROCEDURE [dbo].spAudit_FullAnswerFileList
	@BusinessUnit_Guid uniqueidentifier
AS
BEGIN

        SELECT	Answer_File.AnswerFile_Guid
		FROM	Answer_File
			INNER JOIN Intelledox_User ON Answer_File.User_Guid = Intelledox_User.User_Guid
		WHERE	Intelledox_User.Business_Unit_Guid = @BusinessUnit_Guid
END
GO

ALTER procedure [dbo].[spAudit_UpdateAnswerFile]
	@AnswerFile_ID int,
	@AnswerFile_Guid uniqueidentifier,
	@User_Guid uniqueidentifier,
	@Template_Group_Guid uniqueidentifier,
	@Description nvarchar(255),
	@RunDate datetime,
	@UnencryptedAnswerString xml,
	@EncryptedAnswerString varbinary(MAX),
	@InProgress bit = 0,
	@NewID int output,
	@ErrorCode int output
AS
	set nocount on
	
	if ((@AnswerFile_ID = 0 OR @AnswerFile_ID IS NULL) AND @AnswerFile_Guid IS NOT NULL)
	begin
		 SELECT	@AnswerFile_ID = AnswerFile_ID 
		 FROM	Answer_File 
		 WHERE	AnswerFile_Guid = @AnswerFile_Guid
	end

	if (@AnswerFile_ID > 0)
	begin
		update Answer_File
		set [Description] = @Description,
			RunDate = @RunDate,
			AnswerString = @UnencryptedAnswerString,
			EncryptedAnswerString = @EncryptedAnswerString
		where AnswerFile_ID = @AnswerFile_ID;
	end
	else
	begin
		insert into Answer_File (AnswerFile_Guid, [User_Guid], [Template_Group_Guid], [Description], [RunDate], [AnswerString], [InProgress], [EncryptedAnswerString])
		values (@AnswerFile_Guid, @User_Guid, @Template_Group_Guid, @Description, @RunDate, @UnencryptedAnswerString, @InProgress, @EncryptedAnswerString);

		select @NewID = @@Identity;
	end

	set @ErrorCode = @@Error;
GO

ALTER procedure [dbo].[spTenant_UpdateBusinessUnit]
	@BusinessUnitGuid uniqueidentifier,
	@Name nvarchar(200),
	@SubscriptionType int,
	@ExpiryDate datetime,
	@TenantFee money,
	@DefaultCulture nvarchar(11),
	@DefaultLanguage nvarchar(11),
	@DefaultTimezone nvarchar(50),
	@UserFee money,
	@SamlEnabled bit, 
	@SamlCertificate nvarchar(max), 
	@SamlCertificateType int, 
	@SamlCreateUsers bit, 
	@SamlIssuer nvarchar(255), 
	@SamlLoginUrl nvarchar(1500), 
	@SamlLogoutUrl nvarchar(1500),
	@SamlManageEntityId nvarchar(1500),
	@SamlProduceEntityId nvarchar(1500),
	@SamlLastLoginFail nvarchar(max),
	@TenantKey varbinary(50)
AS
	UPDATE	Business_Unit
	SET		Name = @Name,
			SubscriptionType = @SubscriptionType,
			ExpiryDate = @ExpiryDate,
			TenantFee = @TenantFee,
			DefaultCulture = @DefaultCulture,
			DefaultLanguage = @DefaultLanguage,
			DefaultTimezone = @DefaultTimezone,
			UserFee = @UserFee,
			SamlEnabled = @SamlEnabled,
			SamlCertificate = @SamlCertificate,
			SamlCertificateType = @SamlCertificateType, 
			SamlCreateUsers = @SamlCreateUsers, 
			SamlIssuer = @SamlIssuer, 
			SamlLoginUrl = @SamlLoginUrl, 
			SamlLogoutUrl = @SamlLogoutUrl,
			SamlManageEntityId = @SamlManageEntityId,
			SamlProduceEntityId = @SamlProduceEntityId,
			SamlLastLoginFail = @SamlLastLoginFail,
			TenantKey = @TenantKey
	WHERE	Business_Unit_Guid = @BusinessUnitGuid;
GO

CREATE procedure [dbo].[spLog_GetAllProjectLogs]
	@BusinessUnitGuid uniqueidentifier
as
	SELECT	Template_Log.Log_Guid
	FROM	Template_Log
			INNER JOIN Intelledox_User ON Template_Log.User_Id = Intelledox_User.User_Id
	WHERE	Intelledox_User.Business_Unit_GUID = @BusinessUnitGuid;
GO

ALTER PROCEDURE [dbo].[spLog_UpdateTemplateLog]
	@LogGuid uniqueidentifier,
	@LastGroupGuid uniqueidentifier,
	@AnswerFile xml,
	@EncryptedAnswerFile varbinary(MAX),
	@ActionListStateId uniqueidentifier = '00000000-0000-0000-0000-000000000000'
AS
	UPDATE	Template_Log WITH (ROWLOCK, UPDLOCK)
	SET		Answer_File = @AnswerFile,
			Last_Bookmark_Group_Guid = @LastGroupGuid,
			ActionListStateId = @ActionListStateId,
			EncryptedAnswerFile = @EncryptedAnswerFile
	WHERE	Log_Guid = @LogGuid;
GO

ALTER TABLE dbo.ActionListState ADD
	EncryptedAnswerFileXml varbinary(MAX) NULL
GO
CREATE PROCEDURE [dbo].[spSecurity_RolePermissions]
	@RoleGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	SELECT	*
	FROM	Role_Permission
	JOIN	Permission ON Role_Permission.PermissionGuid = Permission.PermissionGuid
	WHERE	Role_Permission.RoleGuid = @RoleGuid

	SET @ERRORCODE = @@ERROR

GO

ALTER procedure [dbo].[spUsers_UserData]
	@BusinessUnitGUID uniqueidentifier,
	@Username nvarchar(50) = '',
	@UserGroupID int = 0,
	@ShowActive int = 0,
	@FirstName nvarchar(50) = '',
	@LastName nvarchar(50) = '',
	@ErrorCode int = 0 output
	
AS

	SET NOCOUNT ON;

	DECLARE @ColNames nvarchar(MAX);
	
	-- Find the Custom_Fields
	-- Will look like "[CustomField1],[CustomField2],[Custom_Field."
	SET @ColNames = '[' + (
		SELECT Title + '],[' 
		FROM Custom_Field 
		WHERE Validation_Type <> 3
			AND BusinessUnitGUID = @BusinessUnitGUID
		FOR XML PATH('')) ;
	-- Cut off the final ",["
	SET @ColNames = SUBSTRING(@ColNames, 1, LEN(@ColNames)-2);
	SET @Username = REPLACE(@Username, '''', '''''');
	SET @FirstName = REPLACE(@FirstName, '''', '''''');
	SET @LastName = REPLACE(@LastName, '''', '''''');
	
	DECLARE @SQL nvarchar(MAX);
	SET @SQL = 'SELECT Username, 
			First_Name,
			Last_Name,
			SelectedTheme,
			Inactive,
			Full_Name,
			Salutation_Name,
			Title,
			Organisation_Name,
			Phone_Number,
			Fax_Number,
			Email_Address,
			Street_Address_1,
			Street_Address_2,
			Street_Address_Suburb,
			Street_Address_State,
			Street_Address_Postcode,
			Street_Address_Country,
			Postal_Address_1,
			Postal_Address_2,
			Postal_Address_Suburb,
			Postal_Address_State,
			Postal_Address_Postcode,
			Postal_Address_Country 
			' + ISNULL(',' + @ColNames, '') + ' 
		FROM (
			SELECT Intelledox_User.Username, 
				Intelledox_User.SelectedTheme,
				Intelledox_User.[Disabled] As Inactive,
				Address_Book.First_Name,
				Address_Book.Last_Name,
				Address_Book.Full_Name,
				Address_Book.Salutation_Name,
				Address_Book.Title,
				Address_Book.Organisation_Name,
				Address_Book.Phone_Number,
				Address_Book.Fax_Number,
				Address_Book.Email_Address,
				Address_Book.Street_Address_1,
				Address_Book.Street_Address_2,
				Address_Book.Street_Address_Suburb,
				Address_Book.Street_Address_State,
				Address_Book.Street_Address_Postcode,
				Address_Book.Street_Address_Country,
				Address_Book.Postal_Address_1,
				Address_Book.Postal_Address_2,
				Address_Book.Postal_Address_Suburb,
				Address_Book.Postal_Address_State,
				Address_Book.Postal_Address_Postcode,
				Address_Book.Postal_Address_Country, 
				Custom_Field.Title As CustomFieldTitle,
				ISNULL(Address_Book_Custom_Field.Custom_Value, '''') AS Custom_Value
			FROM Intelledox_User
				LEFT JOIN User_Group_Subscription ON Intelledox_User.[User_Guid] = User_Group_Subscription.[UserGuid]
				LEFT JOIN User_Group ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
				LEFT JOIN Address_Book ON Intelledox_User.[Address_ID] = Address_Book.[Address_ID] 
				LEFT JOIN Address_Book_Custom_Field ON Address_Book.Address_ID = Address_Book_Custom_Field.Address_ID
				LEFT JOIN Custom_Field ON Address_Book_Custom_Field.Custom_Field_ID = Custom_Field.Custom_Field_ID
					AND Custom_Field.Validation_Type <> 3
			WHERE (''' + @Username + ''' = '''' OR Intelledox_User.Username LIKE ''' + @Username + '%'')
				AND (''' + @FirstName + ''' = '''' OR ''' + @FirstName + ''' IS NULL OR Address_Book.First_Name LIKE ''%' + @FirstName + '%'')
				AND (''' + @LastName + ''' = '''' OR ''' + @LastName + ''' IS NULL OR Address_Book.Last_Name LIKE ''%' + @LastName + '%'')
				AND Intelledox_User.Business_Unit_GUID = CONVERT(uniqueidentifier, ''' + CONVERT(nvarchar(50), @BusinessUnitGUID) + ''')
				AND	(' + CONVERT(varchar, @UserGroupID) + ' = 0 
					OR User_Group.User_Group_ID = ' + CONVERT(varchar, @UserGroupID) + '
					OR (' + CONVERT(varchar, @UserGroupID) + ' = -1 AND User_Group.User_Group_ID IS NULL))
				AND (' + CONVERT(varchar, @ShowActive) + ' = 0 
					OR (' + CONVERT(varchar, @ShowActive) + ' = 1 AND Intelledox_User.[Disabled] = 0)
					OR (' + CONVERT(varchar, @ShowActive) + ' = 2 AND Intelledox_User.[Disabled] = 1))
				
			GROUP BY Intelledox_User.Username, 
				Intelledox_User.SelectedTheme,
				Intelledox_User.[Disabled],
				Address_Book.First_Name,
				Address_Book.Last_Name,
				Address_Book.Full_Name,
				Address_Book.Salutation_Name,
				Address_Book.Title,
				Address_Book.Organisation_Name,
				Address_Book.Phone_Number,
				Address_Book.Fax_Number,
				Address_Book.Email_Address,
				Address_Book.Street_Address_1,
				Address_Book.Street_Address_2,
				Address_Book.Street_Address_Suburb,
				Address_Book.Street_Address_State,
				Address_Book.Street_Address_Postcode,
				Address_Book.Street_Address_Country,
				Address_Book.Postal_Address_1,
				Address_Book.Postal_Address_2,
				Address_Book.Postal_Address_Suburb,
				Address_Book.Postal_Address_State,
				Address_Book.Postal_Address_Postcode,
				Address_Book.Postal_Address_Country, 
				Custom_Field.Title,
				ISNULL(Address_Book_Custom_Field.Custom_Value, '''')
			) Data
			' + ISNULL('PIVOT (MAX(Custom_Value) FOR CustomFieldTitle IN (' + @ColNames + ')) AS PivotedData', '') + 
			' ORDER BY Username';
		
	EXECUTE sp_executesql @SQL;
 
	SET @ErrorCode = @@ERROR;

GO

