truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.5.4');
go

ALTER procedure [dbo].[spLog_TemplateLogList]
	@LogGuid varchar(50) = '',
	@ErrorCode int output
as
	SELECT	Template_Log.*, 
			Template_Group.Template_Group_Guid, 
			(SELECT User_Guid FROM Intelledox_User WHERE Intelledox_User.User_ID = Template_Log.User_ID
				UNION
				SELECT UserGuid FROM Intelledox_UserDeleted WHERE Intelledox_UserDeleted.User_ID = Template_Log.User_ID)
			AS User_Guid
	FROM	Template_Log
			INNER JOIN Template_Group ON Template_Log.Template_Group_Id = Template_Group.Template_Group_Id
	WHERE	Template_Log.Log_Guid = @LogGuid;
	
	set @ErrorCode = @@error


GO
ALTER PROCEDURE [dbo].[spProject_DeleteOldProjectVersion]
	@ProjectGuid uniqueidentifier,
	@NextVersion nvarchar(10),
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN

	IF (SELECT COUNT(*) 
		FROM Template_Group 
		WHERE (Template_Group.Layout_Guid = @ProjectGuid OR Template_Group.Template_Guid = @ProjectGuid)
			AND Template_Group.MatchProjectVersion = 1) = 0
	BEGIN
	
		--delete the earliest minor version which does not belong to the next version number
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
						AND (FLOOR(vwTemplateVersion.Template_Version) < FLOOR(@NextVersion))) > 0)
		BEGIN

			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version 
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
						AND (FLOOR(vwTemplateVersion.Template_Version) < FLOOR(@NextVersion))
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END
			
		--otherwise	
		--delete earliest major version, leaving at least one major version untouched			
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 1) > 1)
		BEGIN

			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 1
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END

		--otherwise
		--delete the earliest left minor version
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0) > 0)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END

		DELETE FROM Xtf_Datasource_Dependency
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	vwTemplateVersion
					WHERE	Template_Guid = @ProjectGuid);

		DELETE FROM Xtf_ContentLibrary_Dependency
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	vwTemplateVersion
					WHERE	Template_Guid = @ProjectGuid);

		DELETE FROM Xtf_Fragment_Dependency
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	vwTemplateVersion
					WHERE	Template_Guid = @ProjectGuid);
				
		DELETE FROM Template_File_Version
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	vwTemplateVersion
					WHERE	Template_Guid = @ProjectGuid);
	END
END
GO

ALTER PROCEDURE [dbo].[spUser_GetUser]
	@UserID int,
	@UserGuid uniqueidentifier = null
AS
BEGIN
	if @UserGuid is null
	begin
		select	Intelledox_User.*, Address_Book.Full_Name, Address_Book.Email_Address
		from	Intelledox_User
			left join Address_Book on Intelledox_User.Address_Id = Address_Book.Address_id
		where	Intelledox_User.[User_ID] = @UserID;
	end
	else
	begin
		select	Intelledox_User.*, Address_Book.Full_Name, Address_Book.Email_Address
		from	Intelledox_User
			left join Address_Book on Intelledox_User.Address_Id = Address_Book.Address_id
		where	Intelledox_User.User_Guid = @UserGuid;
	end
END
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
       @LicenseHolderName nvarchar(4000)
)
AS
       DECLARE @GuestUserGuid uniqueidentifier
       DECLARE @TenantGroupGuid uniqueidentifier
	   DECLARE @BusinessUnitIdentifier int

       SET @GuestUserGuid = NewID()
	   SET @BusinessUnitIdentifier = floor(rand(CONVERT([varbinary],newid(),(0)))*(89999))+(10000)

	   WHILE @BusinessUnitIdentifier IN (SELECT IdentifyBusinessUnit FROM Business_Unit)
	   BEGIN
		SET @BusinessUnitIdentifier = floor(rand(CONVERT([varbinary],newid(),(0)))*(89999))+(10000)
	   END
	   
       --New business unit (Company in SaaS)
       INSERT INTO Business_Unit(Business_Unit_Guid, Name, TenantKey, TenantType, IdentifyBusinessUnit)
       VALUES (@NewBusinessUnit, @TenantName, CONVERT(varbinary(MAX), @TenantKey), @TenantType, @BusinessUnitIdentifier)

		
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
