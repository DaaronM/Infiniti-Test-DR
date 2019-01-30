/*
** Database Update package 6.2.4
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.2.4')
go

--1910
ALTER TABLE Data_Object
	ADD Display_Name nvarchar(500) null
GO
UPDATE	Data_Object
SET		Display_Name = [Object_Name]
WHERE	Display_Name IS NULL;
GO
ALTER PROCEDURE [dbo].[spDataSource_DataObjectList]
	@DataObjectGuid uniqueidentifier = null,
	@DataServiceGuid uniqueidentifier = null
as
	IF @DataObjectGuid IS NULL
		SELECT	o.[Object_Name], o.data_object_guid, o.data_service_guid, o.Object_Type,
				o.Display_Name
		FROM	data_object o
		WHERE	o.data_service_guid = @DataServiceGuid
		ORDER BY o.[Object_Name];
	ELSE
		SELECT	o.[Object_Name], o.data_object_guid, o.data_service_guid, o.Merge_Source, 
				o.Object_Type, o.Display_Name
		FROM	data_object o
		WHERE	o.data_object_guid = @DataObjectGuid
		ORDER BY o.[Object_Name];
GO
ALTER PROCEDURE [dbo].[spDataSource_UpdateDataObject]
	@DataObjectGuid uniqueidentifier,
	@DataServiceGuid uniqueidentifier,
	@Name nvarchar(500),
	@DisplayName nvarchar(500),
	@MergeSource bit,
	@ObjectType uniqueidentifier
AS
	IF NOT EXISTS(SELECT * FROM data_object WHERE Data_Object_Guid = @DataObjectGuid)
	BEGIN
		INSERT INTO data_object (Data_Service_Guid, [Object_Name], Merge_Source, 
				Data_Object_Guid, Object_Type, Display_Name)
		VALUES (@DataServiceGuid, @Name, @MergeSource, 
				@DataObjectGuid, @ObjectType, @DisplayName);
	END	
	ELSE
	BEGIN		
		UPDATE	data_object
		SET		[object_name] = @Name, 
				merge_source = @MergeSource,
				Object_Type = @ObjectType,
				Display_Name = @DisplayName
		WHERE	data_object_guid = @DataObjectGuid;
	END
GO

--1911
-- XML
UPDATE	Data_Object
SET		Object_Type = '6A5B9DB1-058B-4B1E-B7DD-FDF64EE10CA3'
FROM	Data_Service
		INNER JOIN Data_Object ON Data_Service.Data_Service_Guid = Data_Object.Data_Service_Guid
WHERE	Data_Service.Provider_Name = 'XML'
		AND Data_Object.Object_Type <> '6A5B9DB1-058B-4B1E-B7DD-FDF64EE10CA3'
		
-- Web Service
UPDATE	Data_Object
SET		Object_Type = 'EB9A43D2-C6E5-4C39-A24F-9BC420072739'
FROM	Data_Service
		INNER JOIN Data_Object ON Data_Service.Data_Service_Guid = Data_Object.Data_Service_Guid
WHERE	Data_Service.Provider_Name = 'Web Service'
		AND Data_Object.Object_Type <> 'EB9A43D2-C6E5-4C39-A24F-9BC420072739' 
		
-- RSS Feed
UPDATE	Data_Object
SET		Object_Type = 'F7394584-7DDE-4A7F-9DD0-E7CC3E8B2CD3'
FROM	Data_Service
		INNER JOIN Data_Object ON Data_Service.Data_Service_Guid = Data_Object.Data_Service_Guid
WHERE	Data_Service.Provider_Name = 'RSS Feed'
		AND Data_Object.Object_Type <> 'F7394584-7DDE-4A7F-9DD0-E7CC3E8B2CD3' 
		
-- ODBC
UPDATE	Data_Object
SET		Object_Type = 'BF6143AD-B7D9-44A6-9D11-E9B23ABB65D0'
FROM	Data_Service
		INNER JOIN Data_Object ON Data_Service.Data_Service_Guid = Data_Object.Data_Service_Guid
WHERE	Data_Service.Provider_Name = 'ODBC'
		AND Data_Object.Object_Type <> 'BF6143AD-B7D9-44A6-9D11-E9B23ABB65D0'
GO


--1912
CREATE PROCEDURE [dbo].[spBU_ProvisionTenant] (
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
		
		INSERT INTO User_Group(Name, Deleted, WinNT_Group, WinNT_Sync, Business_Unit_Guid, Group_Guid, AutoAssignment, SystemGroup)
		SELECT	@TenantName + ' Users', Deleted, WinNT_Group, WinNT_Sync, @BusinessUnitGuid, @UG, AutoAssignment, SystemGroup
		FROM	User_Group
		WHERE	Name = 'Intelledox Users' and SystemGroup = '1';
	end
	
	--User
	INSERT INTO Intelledox_User(Username, Pwdhash, Deleted, WinNT_User, Business_Unit_Guid, User_Guid, PwdFormat, PwdSalt)
	VALUES (@UserName, @UserPasswordHash, 0, 0, @BusinessUnitGuid, @UserGuid, 2, @UserPasswordSalt)

	--User Address
	INSERT INTO address_book ([user_id], full_name, first_name, last_name, email_address)
	VALUES (@@IDENTITY, @FirstName + ' ' + @LastName, @FirstName, @LastName, @UserEmail)

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
	declare @UserId int,
			@GroupId int
			
	select @UserId = [User_ID] from intelledox_user where user_guid = @UserGuid;
	select @GroupId = User_Group_ID from user_group where business_unit_guid = @BusinessUnitGuid;
	
	INSERT INTO User_Group_Subscription([User_ID], User_Group_ID, Default_Group)
	values (@UserId, @GroupId, '1');

GO

--1913
ALTER TABLE Template_Group
	ADD WizardFinishText nvarchar(max) null
GO
ALTER PROCEDURE [dbo].[spProjectGrp_UpdateProjectGroup]
	@ProjectGroupGuid uniqueidentifier,
	@Name nvarchar(100),
	@HelpText nvarchar(4000),
	@AllowPreview bit,
	@WizardFinishText nvarchar(max),
	@PostGenerateText nvarchar(4000),
	@UpdateDocumentFields bit,
	@EnforceValidation bit
AS
	IF NOT EXISTS(SELECT * FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid)
	BEGIN
		INSERT INTO Template_Group ([name], template_group_guid, helptext, AllowPreview, PostGenerateText, 
				UpdateDocumentFields, EnforceValidation, WizardFinishText)
		VALUES (@Name, @ProjectGroupGuid, @HelpText, @AllowPreview, @PostGenerateText, 
				@UpdateDocumentFields, @EnforceValidation, @WizardFinishText);
	END
	ELSE
	BEGIN
		UPDATE	Template_Group
		SET		[Name] = @Name,
				HelpText = @HelpText,
				AllowPreview = @AllowPreview,
				PostGenerateText = @PostGenerateText,
				UpdateDocumentFields = @UpdateDocumentFields,
				EnforceValidation = @EnforceValidation,
				WizardFinishText = @WizardFinishText
		WHERE	Template_Group_Guid = @ProjectGroupGuid;
	END
GO
ALTER PROCEDURE [dbo].[spProjectGrp_ProjectGroupList]
      @ProjectGroupGuid uniqueidentifier
AS
    SELECT	a.Template_Group_ID, a.[Name] as Template_Group_Name, a.template_group_guid, 
			a.helptext as TemplateGroup_HelpText, b.template_guid, b.Layout_Guid,
			b.Template_Version, b.Layout_Version, a.AllowPreview, a.PostGenerateText,
			a.UpdateDocumentFields, a.EnforceValidation, a.WizardFinishText
    FROM	Template_Group a
			LEFT JOIN Template_Group_Item b on a.template_group_id = b.template_group_id
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;
GO

