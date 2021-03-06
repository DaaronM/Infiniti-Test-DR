TRUNCATE TABLE dbversion;
GO
INSERT INTO dbversion(dbversion) VALUES ('10.2.7');
GO
ALTER PROCEDURE [dbo].[spUsers_UserByUsernameOrEmail]
	@BusinessUnitGuid uniqueidentifier,
	@UsernameOrEmail nvarchar(256)
AS
BEGIN
	IF @BusinessUnitGuid <> '00000000-0000-0000-0000-000000000000' AND 
		EXISTS(SELECT 1 
			FROM Global_Options
			WHERE Global_Options.BusinessUnitGuid = @BusinessUnitGuid
				AND Global_Options.OptionCode = 'PRODUCER_URL'
				AND Global_Options.OptionValue <> '')
	BEGIN
		SELECT Intelledox_User.*, Address_Book.Email_Address
		FROM Intelledox_User
			LEFT JOIN Address_Book ON Intelledox_User.Address_ID = Address_Book.Address_ID
		WHERE (Email_Address = @UsernameOrEmail OR Username = @UsernameOrEmail)
			AND Intelledox_User.Disabled = 0
			AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid;
	END
	ELSE
	BEGIN
		-- Exclude tenants that have their own urls
		SELECT Intelledox_User.*, Address_Book.Email_Address
		FROM Intelledox_User
			INNER JOIN Business_Unit ON Intelledox_User.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			INNER JOIN Global_Options ON Business_Unit.Business_Unit_Guid = Global_Options.BusinessUnitGuid
			LEFT JOIN Address_Book ON Intelledox_User.Address_ID = Address_Book.Address_ID
		WHERE (Email_Address = @UsernameOrEmail OR Username = @UsernameOrEmail)
			AND Intelledox_User.Disabled = 0
			AND Global_Options.OptionCode = 'PRODUCER_URL'
			AND Global_Options.OptionValue = '';
	END
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
       INSERT INTO Business_Unit(Business_Unit_Guid, Name, TenantKey, TenantType, IdentifyBusinessUnit, TenancyKeyDateUtc)
       VALUES (@NewBusinessUnit, @TenantName, CONVERT(varbinary(MAX), @TenantKey), @TenantType, @BusinessUnitIdentifier, GETUTCDATE())

		
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
       SET OptionValue=''
       WHERE BusinessUnitGuid = @NewBusinessUnit
			AND UPPER(OptionCode) IN (
			   'APPLE_PUSH_CERT',
			   'APPLE_PUSH_CERT_PASSWORD',
			   'ANDROID_PUSH_API_KEY',
			   'PRODUCER_URL',
			   'DIRECTOR_URL'
		   );

       UPDATE Global_Options
       SET OptionValue='DoNotReply@intelledox.com'
       WHERE BusinessUnitGuid = @NewBusinessUnit AND OptionCode='FROM_EMAIL_ADDRESS';

	   	   --sync the license holder name to tenant name
       UPDATE Global_Options
       SET OptionValue=@LicenseHolderName
       WHERE BusinessUnitGuid = @NewBusinessUnit AND OptionCode='LICENSE_HOLDER';
GO

ALTER PROCEDURE [dbo].[spProject_UpdateDefinition] (
	@Xtf xml,
	@TemplateGuid uniqueidentifier,
	@EncryptedXtf varbinary(MAX)
)
AS
	SET ARITHABORT ON

	DECLARE @ExistingFeatureFlags int;
	DECLARE @FeatureFlags int;
	DECLARE @DataObjectGuid uniqueidentifier;
	DECLARE @XtfVersion nvarchar(10)

	BEGIN TRAN
		-- Feature detection --
		SET @FeatureFlags = 0
		SELECT @XtfVersion = Template.Template_Version, @ExistingFeatureFlags = ISNULL(Template.FeatureFlags, 0) FROM Template WHERE Template.Template_Guid = @TemplateGuid;

		-- Workflow
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/Workflow/State/Transition)') as ProjectXML(P))
		BEGIN
			--Looking for a specified transition from the start state
			-- Transition from Start->Finish is OK
			IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/Workflow/State)') as StateXML(S)
					  CROSS APPLY S.nodes('(Transition)') as TransitionXML(T)
					  WHERE S.value('@ID', 'uniqueidentifier') = cast('11111111-1111-1111-1111-111111111111' as uniqueidentifier)
					  AND (T.value('@SendToType', 'int') = 0 or T.value('@SendToType', 'int') IS NULL					  
						OR T.value('@StateId', 'uniqueidentifier') = cast('99999999-9999-9999-9999-999999999999' as uniqueidentifier)))
			BEGIN
				SET @FeatureFlags = @FeatureFlags | 256;
			END
			ELSE
			BEGIN
				SET @FeatureFlags = @FeatureFlags | 1;
			END
		END

		-- Data source
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 2		-- Data field
						OR Q.value('@TypeId', 'int') = 9	-- Data table
						OR Q.value('@TypeId', 'int') = 12	-- Data list
						OR Q.value('@TypeId', 'int') = 14)	-- Data source
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 2;

			INSERT INTO Xtf_Datasource_Dependency(Template_Guid, Template_Version, Data_Object_Guid)
			SELECT DISTINCT @TemplateGuid,
					@XtfVersion,
					Q.value('@DataObjectGuid', 'uniqueidentifier')
			FROM 
				@Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question)') as QuestionXML(Q)
			WHERE Q.value('@DataObjectGuid', 'uniqueidentifier') is not null
				AND Q.value('@DataServiceGuid', 'uniqueidentifier') <> '6a4af944-0563-4c95-aba1-ddf2da4337b1'
				AND (SELECT  COUNT(*)
				FROM    Xtf_Datasource_Dependency 
				WHERE   Template_Guid = @TemplateGuid
				AND     Template_Version = @XtfVersion 
				AND		Data_Object_Guid = Q.value('@DataObjectGuid', 'uniqueidentifier')) = 0
			
		END

		-- Content library
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 11
						AND Q.value('@DisplayType', 'int') = 8) -- Existing content item
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 4;
		END
		
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 11
						AND Q.value('@DisplayType', 'int') = 4) -- Search
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 8;
		END

		IF EXISTS(SELECT 1 FROM Xtf_ContentLibrary_Dependency
			WHERE	Xtf_ContentLibrary_Dependency.Template_Guid = @TemplateGuid AND
					Xtf_ContentLibrary_Dependency.Template_Version = @XtfVersion)
		BEGIN
			DELETE FROM Xtf_ContentLibrary_Dependency
			WHERE	Xtf_ContentLibrary_Dependency.Template_Guid = @TemplateGuid AND
					Xtf_ContentLibrary_Dependency.Template_Version = @XtfVersion;
		END

		INSERT INTO Xtf_ContentLibrary_Dependency(Template_Guid, Template_Version, Content_Object_Guid, Display_Type)
		SELECT DISTINCT @TemplateGuid, @XtfVersion, Content_Object_Guid, Display_Type
		FROM (
			SELECT C.value('@Id', 'uniqueidentifier') as Content_Object_Guid,
				-1 AS Display_Type
			FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question/Answer/ContentItem)') as ContentItemXML(C)
			UNION
			SELECT Q.value('@ContentItemGuid', 'uniqueidentifier'),
				Q.value('@DisplayType', 'int') AS Display_Type
			FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question)') as QuestionXML(Q)
			WHERE Q.value('@ContentItemGuid', 'uniqueidentifier') is not null) Content

		-- Address
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 1)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 16;
		END

		-- Rich text
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 19)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 64;
		END
			
		-- Custom Question
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 22)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 128;
		END

		-- Fragments
		IF EXISTS(SELECT 1 FROM Xtf_Fragment_Dependency
					WHERE	Xtf_Fragment_Dependency.Template_Guid = @TemplateGuid AND
							Xtf_Fragment_Dependency.Template_Version = @XtfVersion)
		BEGIN
			DELETE FROM Xtf_Fragment_Dependency
			WHERE	Xtf_Fragment_Dependency.Template_Guid = @TemplateGuid AND
					Xtf_Fragment_Dependency.Template_Version = @XtfVersion;
		END
		
		INSERT INTO Xtf_Fragment_Dependency(Template_Guid, Template_Version, Fragment_Guid)
		SELECT DISTINCT @TemplateGuid, @XtfVersion, Fragment_Guid
		FROM (
			SELECT fp.value('@ProjectGuid', 'uniqueidentifier') as Fragment_Guid
			FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as PageFragmentXML(fp)
			WHERE fp.value('@ProjectGuid', 'uniqueidentifier') IS NOT NULL
			UNION
			SELECT fn.value('@ProjectGuid', 'uniqueidentifier')
			FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Layout//Fragment)') as NodeFragmentXML(fn)
			WHERE fn.value('@ProjectGuid', 'uniqueidentifier') IS NOT NULL) Fragments

		IF EXISTS(SELECT 1 FROM Xtf_Fragment_Dependency WHERE Template_Guid = @TemplateGuid AND Template_Version = @XtfVersion)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 512;
		END

		-- Summary Question
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 26)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 1024;
		END

		
		-- Run Action Button Question
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 27)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 2048;
		END

		IF @EncryptedXtf IS NULL
		BEGIN
			UPDATE	Template 
			SET		Project_Definition = @XTF,
					FeatureFlags = @FeatureFlags,
					EncryptedProjectDefinition = NULL
			WHERE	Template_Guid = @TemplateGuid;
		END
		ELSE
		BEGIN
			UPDATE	Template 
			SET		EncryptedProjectDefinition = @EncryptedXtf,
					FeatureFlags = @FeatureFlags,
					Project_Definition = NULL
			WHERE	Template_Guid = @TemplateGuid;
		END

		-- Updating project group feature flags is expensive, only do it if our flags have changed
		-- or we contain project fragments (could have been added or removed)
		IF @ExistingFeatureFlags <> @FeatureFlags OR (@FeatureFlags & 512) = 512
		BEGIN
			EXEC spProjectGroup_UpdateFeatureFlags @ProjectGuid=@TemplateGuid;
		END
	COMMIT
GO
