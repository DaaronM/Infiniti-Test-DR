/*
** Database Update package 6.1.3
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.1.3')
go

--1878
create procedure [dbo].[spOptions_UpdateOptionValue]
	@Code nvarchar(255),
	@Value nvarchar(4000)
as
	UPDATE	global_options
	SET		optionvalue = @Value
	WHERE optioncode = @Code;
GO

--1879
ALTER procedure [dbo].[spAddBk_UpdateAddress]
	@AddressID int,
	@AddressTypeID int,
	@Reference nvarchar(50),
	@UserGroupID int,
	@UserID int,
	@Prefix nvarchar(50),
	@Title nvarchar(50),
	@FullName nvarchar(100),
	@FirstName nvarchar(50),
	@LastName nvarchar(50),
	@Salutation nvarchar(50),
	@Organisation nvarchar(100),
	@EmailAddress nvarchar(50),
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
	@NewID int = 0 output,
	@ErrorCode int = 0 output
AS
	--This may be an insert or an update, depending on AddressID.
	IF @AddressID = 0
	begin
		INSERT INTO Address_Book (addresstype_id, [user_id], usergroup_id, address_reference,
			prefix, first_name, last_name, full_name, salutation_name, title,
			organisation_name, phone_number, fax_number, email_address,
			street_address_1, street_address_2, street_address_suburb, street_address_state,
			street_address_postcode, street_address_country, postal_address_1, postal_address_2,
			postal_address_suburb, postal_address_state, postal_address_postcode, postal_address_country)
		VALUES (@AddressTypeID, @UserID, @UserGroupID, @Reference,
			@Prefix, @FirstName, @LastName, @FullName, @Salutation, @Title,
			@Organisation, @PhoneNumber, @FaxNumber, @EmailAddress,
			@StreetAddress1, @StreetAddress2, @StreetSuburb, @StreetState,
			@StreetPostcode, @StreetCountry, @PostalAddress1, @PostalAddress2,
			@PostalSuburb, @PostalState, @PostalPostcode, @PostalCountry);

		SELECT @NewID = @@Identity;
		SET @AddressID = @NewID;
	end
	ELSE
	begin
		UPDATE Address_Book
		SET Addresstype_ID = @AddressTypeID, [User_ID] = @UserID, UserGroup_ID = @UserGroupID,
			Address_Reference = @Reference, Prefix = @Prefix, First_Name = @FirstName,
			Last_Name = @LastName, Full_Name = @FullName, Salutation_Name = @Salutation,
			Title = @Title, Organisation_Name = @Organisation, Phone_number = @PhoneNumber,
			Fax_number = @FaxNumber, Email_Address = @EmailAddress,
			Street_Address_1 = @StreetAddress1, Street_Address_2 = @StreetAddress2,
			Street_Address_Suburb = @StreetSuburb, Street_Address_State = @StreetState,
			Street_Address_Postcode = @StreetPostcode, Street_Address_Country = @StreetCountry,
			Postal_Address_1 = @PostalAddress1, Postal_Address_2 = @PostalAddress2,
			Postal_Address_Suburb = @PostalSuburb, Postal_Address_State = @PostalState,
			Postal_Address_Postcode = @PostalPostcode, Postal_Address_Country = @PostalCountry
		WHERE Address_ID = @AddressID;
	end
		
	IF (@SubscribeUser > 0) AND (@SubscribeUser IS NOT NULL)
		exec spAddBk_SubscribeUserAddress @SubscribeUser, @AddressID, @ErrorCode output;

	set @errorcode = @@error;
GO

--1880
ALTER procedure [dbo].[spProject_GetProjectsByContentItem]
	@ContentGuid varchar(40),
	@BusinessUnitGuid uniqueidentifier
as
	SET ARITHABORT ON 
	
	SELECT 	Template.template_id, 
			Template.[name] as project_name, 
			Template.template_type_id, 
			Template.fax_template_id, 
			Template.layout_id, 
			Template.template_guid, 
			Template.template_version, 
			Template.import_date, 
			Template.FormatTypeId,
			Template.Business_Unit_GUID, 
			Template.Supplier_Guid,
			Template.Content_Bookmark,
			Template.Modified_Date,
			Intelledox_User.Username
	FROM	Template
		LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By
	WHERE	Template.Business_Unit_GUID = @BusinessUnitGuid
		AND Project_Definition.exist('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question/Answer/ContentItem[@Id = sql:variable("@ContentGuid")])[1]') = 1
	ORDER BY Template.[name];
GO


--1881
ALTER procedure [dbo].[spProject_GetProjectsByContentDefinition]
	@ContentGuid varchar(40),
	@BusinessUnitGuid uniqueidentifier
as
	SET ARITHABORT ON 

	SELECT 	Template.template_id, 
			Template.[name] as project_name, 
			Template.template_type_id, 
			Template.fax_template_id, 
			Template.layout_id, 
			Template.template_guid, 
			Template.template_version, 
			Template.import_date, 
			Template.FormatTypeId,
			Template.Business_Unit_GUID, 
			Template.Supplier_Guid,
			Template.Content_Bookmark,
			Template.Modified_Date,
			Intelledox_User.Username
	FROM	Template
		LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By
	WHERE	Template.Business_Unit_GUID = @BusinessUnitGuid
		AND Project_Definition.exist('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question/Answer/ContentDefinition[@Id = sql:variable("@ContentGuid")])[1]') = 1
	ORDER BY Template.[name];
GO


