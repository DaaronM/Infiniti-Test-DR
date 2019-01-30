truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.5.0.3');
go

ALTER TABLE [dbo].[Address_Book]
	ALTER COLUMN [Email_Address] [nvarchar](256) NULL
GO

ALTER TABLE [dbo].[AuditLog]
	ALTER COLUMN [UserName] [nvarchar](256) NULL
GO

ALTER TABLE [dbo].[MultiTenantPortal_Admin]
	ALTER COLUMN [Username] [nvarchar](256) NULL
GO

ALTER PROCEDURE [dbo].[spMultiTenantAdmin_UpdateUser]
	@Username nvarchar(256),
	@Password nvarchar(1000),
	@PasswordSalt nvarchar(128),
	@ChangePassword int,
	@ErrorCode int = 0 output
AS

	BEGIN
		UPDATE MultiTenantPortal_Admin
		SET PwdHash = @Password, 
			PwdSalt = @PasswordSalt,
			ChangePassword = @ChangePassword
		WHERE [Username] = @Username;
	END

	SET @ErrorCode = @@error;
GO

ALTER PROCEDURE [dbo].[spMultiTenantAdmin_UserByUsername]
	@Username nvarchar(256)
AS
	SELECT	MultiTenantPortal_Admin.*
	FROM	MultiTenantPortal_Admin
	WHERE	Username = @Username;
GO

ALTER PROCEDURE [dbo].[spTenant_ProvisionTenant] (
	   @TemplateBusinessUnit uniqueidentifier,
       @TenantName nvarchar(200),
       @FirstName nvarchar(50),
       @LastName nvarchar(50),
       @UserName nvarchar(256),
       @UserPasswordHash varchar(1000),
       @UserPwdSalt nvarchar(128),
       @Email nvarchar(256),
       @TenantKey varbinary(MAX)
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
       VALUES (@TemplateBusinessUnit, @TenantName, CONVERT(varbinary(MAX), @TenantKey))


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

ALTER PROCEDURE [dbo].[spUser_ClearInvalidLogonAttempts]
	@Username varchar(256)
AS
BEGIN
	UPDATE Intelledox_User
	SET [Invalid_Logon_Attempts] = 0
	WHERE Username = @Username
END
GO

ALTER PROCEDURE [dbo].[spUser_InvalidLogonAttempt]
	@Username varchar(256)
AS
BEGIN
	UPDATE Intelledox_User
	SET [Invalid_Logon_Attempts] = [Invalid_Logon_Attempts] + 1
	WHERE Username = @Username
END
GO

ALTER PROCEDURE [dbo].[spUser_IsLockedOut]
	@Username varchar(256)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT COUNT(*)
	FROM Intelledox_User
	WHERE Intelledox_User.Username = @Username AND
		Intelledox_User.Locked_Until_Utc IS NOT NULL AND
		Intelledox_User.Locked_Until_Utc > GETUTCDATE()
END
GO

ALTER PROCEDURE [dbo].[spUser_SetLockedOutUtc]
	@Username nvarchar(256),
	@LockedOutUtc DateTime
AS
	UPDATE Intelledox_User
	SET [Locked_Until_Utc] = @LockedOutUtc
	WHERE Username = @Username
GO

ALTER procedure [dbo].[spUsers_ConfirmUniqueUsername]
	@UserID int,
	@Username nvarchar(256) = ''
as
	SELECT	COUNT(*)
	FROM	Intelledox_User
	WHERE	[Username] = @Username
			AND [User_ID] <> @UserID
GO

ALTER procedure [dbo].[spUsers_updateUser]
	@UserID int,
	@Username nvarchar(256),
	@Password nvarchar(1000),
	@NewID int = 0 output,
	@WinNT_User bit,
	@BusinessUnitGUID uniqueidentifier,
	@User_GUID uniqueidentifier,
	@SelectedTheme nvarchar(100),
	@ChangePassword int,
	@PasswordSalt nvarchar(128),
	@PasswordFormat int,
	@Disabled int,
	@Address_Id int,
	@Timezone nvarchar(50),
	@Culture nvarchar(11),
	@Language nvarchar(11),
	@InvalidLogonAttempts int,
	@PasswordSetUtc datetime,
	@IsGuest bit = 0,
	@ErrorCode int = 0 output
as
	if @UserID = 0 OR @UserID IS NULL
	begin
		INSERT INTO Intelledox_User(Username, PwdHash, WinNT_User, Business_Unit_GUID, User_Guid, SelectedTheme, 
				ChangePassword, PwdSalt, PwdFormat, [Disabled], Address_ID, Timezone, Culture, Language, IsGuest, Invalid_Logon_Attempts, Password_Set_Utc)
		VALUES (@Username, @Password, @WinNT_User, @BusinessUnitGUID, @User_Guid, @SelectedTheme, 
				@ChangePassword, @PasswordSalt, @PasswordFormat, @Disabled, @Address_Id, @Timezone, @Culture, @Language, @IsGuest, @InvalidLogonAttempts, @PasswordSetUtc);
		
		select @NewID = @@identity;

		INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
		SELECT	@User_Guid, User_Group.Group_Guid, 0
		FROM	User_Group
		WHERE	User_Group.AutoAssignment = 1
				AND Business_Unit_Guid = @BusinessUnitGUID;
	end
	else
	begin
		UPDATE Intelledox_User
		SET Username = @Username,  
			PwdHash = @Password, 
			WinNT_User = @WinNT_User,
			SelectedTheme = @SelectedTheme,
			ChangePassword = @ChangePassword,
			PwdSalt = @PasswordSalt,
			PwdFormat = @PasswordFormat,
			[Disabled] = @Disabled,
			Timezone = @Timezone,
			Culture = @Culture,
			Language = @Language,
			Address_ID = @Address_Id,
			Invalid_Logon_Attempts = @InvalidLogonAttempts,
			Password_Set_Utc = @PasswordSetUtc
		WHERE [User_ID] = @UserID;
	end

	set @ErrorCode = @@error;
GO

ALTER procedure [dbo].[spUsers_UserByUsername]
	@UserName nvarchar(256)
AS

	SELECT	Intelledox_User.*, Business_Unit.DefaultLanguage
	FROM	Intelledox_User
			INNER JOIN Business_Unit ON Intelledox_User.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
	WHERE	Intelledox_User.Username = @UserName;
GO

ALTER procedure [dbo].[spUsers_UserData]
	@BusinessUnitGUID uniqueidentifier,
	@Username nvarchar(256) = '',
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

ALTER PROCEDURE [dbo].[spUsers_UserGroupByUser]
	-- Add the parameters for the stored procedure here
	@UserID int,
	@BusinessUnitGUID uniqueidentifier,
	@Username nvarchar(256) = '',
	@UserGroupID int = 0,
	@UserGuid uniqueidentifier = null,
	@ShowActive int = 0,
	@ErrorCode int = 0 output,
	@Firstname nvarchar(50) = '',
	@Lastname nvarchar(50) = ''
AS
BEGIN
	if @UserGroupID = 0	--all user groups
	begin
		if @UserGuid is null
		begin
			if @UserID is null or @UserID = 0
			begin
				select	a.*, Business_Unit.DefaultLanguage
				from	Intelledox_User a
					left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
					left join Address_Book d on a.Address_ID = d.Address_ID
				where	(@Username = '' OR @Username is null OR a.[Username] like + @Username + '%')
					AND (@Firstname = '' OR @Firstname is null OR d.[First_Name] like + '%' + @Firstname + '%')
					AND (@Lastname = '' or @Lastname is null or d.[Last_Name] like + '%' + @Lastname + '%')
					AND (a.Business_Unit_GUID = @BusinessUnitGUID)
					AND (@ShowActive = 0 
						OR (@ShowActive = 1 AND a.[Disabled] = 0)
						OR (@ShowActive = 2 AND a.[Disabled] = 1))
				ORDER BY a.[Username]
			end
			else
			begin
				select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
				from	Intelledox_User a
					left join User_Group_Subscription c on a.User_Guid = c.UserGuid
					left join User_Group b on c.GroupGuid = b.Group_Guid
					left join Address_Book d on a.Address_Id = d.Address_id
					left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
				where	(a.[User_ID] = @UserID)
					AND (@ShowActive = 0 
						OR (@ShowActive = 1 AND a.[Disabled] = 0)
						OR (@ShowActive = 2 AND a.[Disabled] = 1))
				ORDER BY a.[Username]
			end
		end
		else
		begin
			select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
			from	Intelledox_User a
				left join User_Group_Subscription c on a.User_Guid = c.UserGuid
				left join User_Group b on c.GroupGuid = b.Group_Guid
				left join Address_Book d on a.Address_Id = d.Address_id
				left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			where	(User_Guid = @UserGuid)
				AND (@ShowActive = 0 
					OR (@ShowActive = 1 AND a.[Disabled] = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1))
			ORDER BY a.[Username]
		end
	end
	else
	begin
		if @UserGroupID = -1	--users with no user groups
		begin
			select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
			from	Intelledox_User a
				left join User_Group_Subscription c on a.User_Guid = c.UserGuid
				left join User_Group b on c.GroupGuid = b.Group_Guid
				left join Address_Book d on a.Address_Id = d.Address_id
				left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			where	(@UserID = 0 OR @UserID IS NULL OR a.[User_ID] = @UserID)
				AND	(@Username = '' OR @Username is null OR a.[Username] like + @Username + '%')
				AND (@Firstname = '' OR @Firstname is null OR d.[First_Name] like + '%' + @Firstname + '%')
				AND (@Lastname = '' or @Lastname is null or d.[Last_Name] like + '%' + @Lastname + '%')
				AND	a.User_Guid not in (
						select a.userGuid
						from user_group_subscription a 
						inner join user_Group b on a.GroupGuid = b.Group_Guid
					)
				AND (a.Business_Unit_GUID = @BusinessUnitGUID)
				AND (@ShowActive = 0 
					OR (@ShowActive = 1 AND a.[Disabled] = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1))
			ORDER BY a.[Username]
		end
		else			--users in specified user group
		begin
			select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
			from	Intelledox_User a
				left join User_Group_Subscription c on a.User_Guid = c.UserGuid
				left join User_Group b on c.GroupGuid = b.Group_Guid
				left join Address_Book d on a.Address_Id = d.Address_id
				left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			where	(@UserID = 0 OR @UserID IS NULL OR a.[User_ID] = @UserID)
				AND	(@Username = '' OR @Username is null OR a.[Username] like + @Username + '%')
				AND (@Firstname = '' OR @Firstname is null OR d.[First_Name] like + '%' + @Firstname + '%')
				AND (@Lastname = '' or @Lastname is null or d.[Last_Name] like + '%' + @Lastname + '%')
				AND	c.GroupGuid = (SELECT Group_Guid FROM User_Group WHERE User_Group_id = @UserGroupID)
				AND (a.Business_Unit_GUID = @BusinessUnitGUID)
				AND (@ShowActive = 0 
					OR (@ShowActive = 1 AND a.[Disabled] = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1))
			ORDER BY a.[Username]
		end
	end

	set @ErrorCode = @@error;

END
GO

ALTER procedure [dbo].[spUsers_UserLogin]
	@Username nvarchar(256),
	@Password nvarchar(1000),
	@Secured bit = 1,
	@SingleUser bit = 0, 
	@Authenticated int = 0 output,
	@ErrorCode int = 0 output
as
	declare @ValidateCount int,
		@UserID int,
		@Business_Unit_GUID uniqueidentifier
	
	if @Secured = 0
	begin
		select @ValidateCount = COUNT(*)
		from Intelledox_User
		where lower(Username) = lower(@Username)

		set @Authenticated = 1
	end
	else
	begin
		select @ValidateCount = COUNT(*)
		from Intelledox_User
		where lower(Username) = lower(@Username)
		AND pwdhash = @Password
		set @Authenticated = 2
	end

	if @ValidateCount = 0
	begin
		set @Authenticated = -1
		select a.*, b.*, '' as DefaultLanguage
		from Intelledox_User a, Address_Book b
		where a.[User_ID] is null
	end
	else
	begin
		select @ValidateCount = COUNT(*)
		from Intelledox_User a, Address_Book b
		where lower(a.Username) = lower(@Username)
			AND a.Address_ID = b.Address_ID

		if @ValidateCount = 0	--if address record doesn't exist, create one
		begin
			select @UserID = [user_id] from Intelledox_User where lower(username) = lower(@Username)

			INSERT INTO address_book (full_name)
			VALUES (@Username)
			
			UPDATE	Intelledox_User
			SET		Address_ID = @@IDENTITY
			WHERE	USER_ID = @UserID;
		end

		select a.*, b.*, Business_Unit.DefaultLanguage
		from Intelledox_User a
			left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			, Address_Book b
		where lower(a.Username) = lower(@Username)
			AND a.Address_ID = b.Address_ID
	end

	set @ErrorCode = @@error
GO

ALTER procedure [dbo].[spAddBk_UpdateAddress]
	@AddressID int,
	@AddressTypeID int,
	@Reference nvarchar(50),
	@Prefix nvarchar(50),
	@Title nvarchar(50),
	@FullName nvarchar(100),
	@FirstName nvarchar(50),
	@LastName nvarchar(50),
	@Salutation nvarchar(50),
	@Organisation nvarchar(100),
	@EmailAddress nvarchar(256),
	@FaxNumber nvarchar(50),
	@PhoneNumber nvarchar(50),
	@StreetAddress1 nvarchar(50),
	@StreetAddress2 nvarchar(50),
	@StreetSuburb nvarchar(50),
	@StreetState nvarchar(50),
	@StreetPostcode nvarchar(50),
	@StreetCountry nvarchar(50),
	@PostalAddress1 nvarchar(50),
	@PostalAddress2 nvarchar(50),
	@PostalSuburb nvarchar(50),
	@PostalState nvarchar(50),
	@PostalPostcode nvarchar(50),
	@PostalCountry nvarchar(50),
	@SubscribeUser int,
	@EmailIndividualMembers bit = 0,
	@NewID int = 0 output,
	@ErrorCode int = 0 output
AS
	--This may be an insert or an update, depending on AddressID.
	IF @AddressID = 0
	begin
		INSERT INTO Address_Book (addresstype_id, address_reference,
			prefix, first_name, last_name, full_name, salutation_name, title,
			organisation_name, phone_number, fax_number, email_address,
			street_address_1, street_address_2, street_address_suburb, street_address_state,
			street_address_postcode, street_address_country, postal_address_1, postal_address_2,
			postal_address_suburb, postal_address_state, postal_address_postcode, postal_address_country, email_individual_members)
		VALUES (@AddressTypeID, @Reference,
			@Prefix, @FirstName, @LastName, @FullName, @Salutation, @Title,
			@Organisation, @PhoneNumber, @FaxNumber, @EmailAddress,
			@StreetAddress1, @StreetAddress2, @StreetSuburb, @StreetState,
			@StreetPostcode, @StreetCountry, @PostalAddress1, @PostalAddress2,
			@PostalSuburb, @PostalState, @PostalPostcode, @PostalCountry, @EmailIndividualMembers);

		SELECT @NewID = @@Identity;
		SET @AddressID = @NewID;
	end
	ELSE
	begin
		UPDATE Address_Book
		SET Addresstype_ID = @AddressTypeID,
			Address_Reference = @Reference, Prefix = @Prefix, First_Name = @FirstName,
			Last_Name = @LastName, Full_Name = @FullName, Salutation_Name = @Salutation,
			Title = @Title, Organisation_Name = @Organisation, Phone_number = @PhoneNumber,
			Fax_number = @FaxNumber, Email_Address = @EmailAddress,
			Street_Address_1 = @StreetAddress1, Street_Address_2 = @StreetAddress2,
			Street_Address_Suburb = @StreetSuburb, Street_Address_State = @StreetState,
			Street_Address_Postcode = @StreetPostcode, Street_Address_Country = @StreetCountry,
			Postal_Address_1 = @PostalAddress1, Postal_Address_2 = @PostalAddress2,
			Postal_Address_Suburb = @PostalSuburb, Postal_Address_State = @PostalState,
			Postal_Address_Postcode = @PostalPostcode, Postal_Address_Country = @PostalCountry, Email_Individual_Members = @EmailIndividualMembers
		WHERE Address_ID = @AddressID;
	end
		
	IF (@SubscribeUser > 0) AND (@SubscribeUser IS NOT NULL)
		exec spAddBk_SubscribeUserAddress @SubscribeUser, @AddressID, @ErrorCode output;

	set @errorcode = @@error;
GO
UPDATE Template_File
SET	FormatTypeId = '.doc'
WHERE FormatTypeId = ''
	OR FormatTypeId IS NULL

UPDATE Template_File_Version
SET	FormatTypeId = '.doc'
WHERE FormatTypeId = ''
	OR FormatTypeId IS NULL
GO
