/*
** Database Update package 5.1.0.3
*/

--set version
truncate table dbversion
go
insert into dbversion values ('5.1.0.3')
go

--1825
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
			@PostalSuburb, @PostalState, @PostalPostcode, @PostalCountry)

		SELECT @NewID = @@Identity
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
		WHERE Address_ID = @AddressID
	end
		
	IF (@SubscribeUser > 0) AND (@SubscribeUser IS NOT NULL)
		exec spAddBk_SubscribeUserAddress @SubscribeUser, @AddressID, @ErrorCode output

	set @errorcode = @@error
GO

--1826
ALTER TABLE [dbo].[Answer_File]
	ALTER COLUMN AnswerString xml NULL
GO
ALTER TABLE [dbo].[ContentData_Text]
	ALTER COLUMN [ContentData] nvarchar(max) NULL
GO
ALTER TABLE [dbo].[EventLog]
	ALTER COLUMN [Message] nvarchar(max) NOT NULL
GO
ALTER TABLE [dbo].[Market]
	ALTER COLUMN [Description] nvarchar(max) NOT NULL
GO
ALTER TABLE [dbo].[PurchaseTransaction]
	ALTER COLUMN [Response_Text] nvarchar(max) NULL
GO
ALTER TABLE [dbo].[Template]
	ALTER COLUMN [Template_Xml] nvarchar(max) NULL
GO
ALTER TABLE [dbo].[Template]
	ALTER COLUMN [Project_Definition] xml NULL
GO
ALTER TABLE [dbo].[Template]
	ALTER COLUMN [Binary] varbinary(max) NULL
GO
ALTER TABLE [dbo].[Template_Log]
	ALTER COLUMN [Answer_File] xml NULL
GO
ALTER TABLE [dbo].[ContentData_Binary]
	ALTER COLUMN [ContentData] varbinary(max) NULL
GO
ALTER TABLE [dbo].[Image_Library]
	ALTER COLUMN [Image_Binary] varbinary(max) NULL
GO
ALTER TABLE [dbo].[Market]
	ALTER COLUMN [Sample] varbinary(max) NULL
GO
ALTER procedure [dbo].[spAudit_InsertTransaction]
	@BusinessUnitGuid uniqueidentifier,
	@TransactionID int,
	@UserID int,
	@Price money,
	@TransactionAmount money,
	@TransactionDate datetime,
	@TemplateGuid uniqueidentifier,
	@SupplierGuid uniqueidentifier,
	@OrderNumber nvarchar(100),
	@CardType nvarchar(100),
	@CardNumber nvarchar(4),
	@CardName nvarchar(100),
	@ResponseText nvarchar(max),
	@ResponseSummary nvarchar(10),
	@ResponseCode nvarchar(10),
	@ResponseRRN nvarchar(50),
	@ErrorNumber nvarchar(10),
	@ErrorMessage nvarchar(1000),
	@Approved nvarchar(10),
	@Remote_Ip nvarchar(20),
	@Description nvarchar(300),
	@NewTransactionID int output,
	@ErrorCode int output
as
	SET NOCOUNT ON

	if (@TransactionID > 0)
	begin
		UPDATE	PurchaseTransaction
		SET		Business_Unit_Guid = @BusinessUnitGuid,
				[User_ID] = @UserID,
				Price = @Price,
				Transaction_Amount = @TransactionAmount,
				Transaction_Date = @TransactionDate,
				Order_Number = @OrderNumber,
				Card_Type = @CardType,
				Card_Number = @CardNumber,
				Card_Name = @CardName,
				Response_Text = @ResponseText,
				Response_Summary = @ResponseSummary,
				Response_Code = @ResponseCode,
				Response_RRN = @ResponseRRN,
				Error_Number = @ErrorNumber,
				Error_Message = @ErrorMessage,
				Approved = @Approved,
				Remote_Ip = @Remote_Ip,
				Description = @Description
		WHERE	Transaction_ID = @TransactionID

		IF NOT EXISTS(SELECT * FROM PurchaseLineItem)
		BEGIN
			INSERT INTO PurchaseLineItem(Transaction_ID, Description, Item_Guid, Supplier_Guid, Price)
			SELECT	@NewTransactionID, Name, @TemplateGuid, @SupplierGuid, @Price
			FROM	Template
			WHERE	Template_Guid = @TemplateGuid
		END

		set @NewTransactionID = @TransactionID
	end
	else
	begin
		INSERT INTO PurchaseTransaction (Business_Unit_Guid, [User_Id], Price, Transaction_Amount, Transaction_Date, Order_Number, Card_Type,	Card_Number, Card_Name,	Response_Text, Response_Summary, Response_Code,	Response_RRN, Error_Number,	Error_Message, Approved, Remote_Ip, Description)
		VALUES (@BusinessUnitGuid, @UserId, @Price, @TransactionAmount, @TransactionDate, @OrderNumber, @CardType, @CardNumber, @CardName, @ResponseText, @ResponseSummary, @ResponseCode, @ResponseRRN, @ErrorNumber, @ErrorMessage, @Approved, @Remote_Ip, @Description)
		
		set @NewTransactionID = @@identity
	end

	set @ErrorCode = @@error

GO
ALTER PROCEDURE [dbo].[spAudit_UpdateAnswerFile]
	@AnswerFile_ID int,
	@User_ID int,
	@Template_Group_ID int,
	@Description nvarchar(255),
	@RunDate datetime,
	@AnswerString text,
	@InProgress char(1) = '0',
	@NewID int output,
	@ErrorCode int output
AS
	set nocount on

	if @AnswerFile_ID = 0 or @AnswerFile_ID is null
	begin
		insert into Answer_File ([User_ID], [Template_Group_ID], [Description], [RunDate], [AnswerString], [InProgress])
		values (@User_ID, @Template_Group_ID, @Description, @RunDate, @AnswerString, @InProgress)

		select @NewID = @@Identity
	end
	else
	begin
		update Answer_File
		set [Description] = @Description,
			RunDate = @RunDate,
			AnswerString = @AnswerString
		where AnswerFile_ID = @AnswerFile_ID
	end

	set @ErrorCode = @@Error

GO
ALTER PROCEDURE [dbo].[spAudit_UpdateSiteEvent]
	@DateTime DateTime,
	@Message nvarchar(max),
	@LevelID Int
AS
	INSERT INTO EventLog (DateTime, Message, LevelID)
	VALUES (@DateTime, @Message, @LevelID)

GO
ALTER PROCEDURE [dbo].[spLibrary_UpdateText] (
	@UniqueId as uniqueidentifier,
	@ContentData as nvarchar(max)
)
AS
	DECLARE @ContentData_Guid uniqueidentifier

	SELECT	@ContentData_Guid = ContentData_Guid
	FROM	Content_Item
	WHERE	ContentItem_Guid = @UniqueId

	IF EXISTS(SELECT ContentData_Guid FROM ContentData_Text WHERE ContentData_Guid = @ContentData_Guid)
	BEGIN
		UPDATE	ContentData_Text
		SET		ContentData = @ContentData
		WHERE	ContentData_Guid = @ContentData_Guid
	END
	ELSE
	BEGIN
		SET	@ContentData_Guid = newid()

		INSERT INTO ContentData_Text(ContentData_Guid, ContentData)
		VALUES (@ContentData_Guid, @ContentData)

		UPDATE	Content_Item
		SET		ContentData_Guid = @ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId
	END

GO
ALTER PROCEDURE [dbo].[spLog_UpdateTemplateLog]
	@LogGuid uniqueidentifier,
	@Finish datetime,
	@AnswerFile xml,
	@PackageRunId Int,
	@ErrorCode int output
AS
	If @PackageRunId <> 0
	BEGIN
		DECLARE @TemplateGroupID Int
		DECLARE @UserID Int

		SELECT TOP 1 @TemplateGroupID = Template_Group_ID,
				@UserID = [User_ID]
		FROM	Template_Log
		WHERE	Log_Guid = @LogGuid

		IF EXISTS(SELECT * FROM Template_Log 
					WHERE	Template_Group_ID = @TemplateGroupID
							AND Package_Run_Id = @PackageRunId
							AND [User_ID] = @UserID
							AND Log_Guid <> @LogGuid)
		BEGIN
			UPDATE	Template_Log 
			SET		Package_Run_Id = NULL
			WHERE	Template_Group_ID = @TemplateGroupID
					AND Package_Run_Id = @PackageRunId
					AND [User_ID] = @UserID
					AND Log_Guid <> @LogGuid
		END
	END

	UPDATE	Template_Log 
	SET		DateTime_Finish = @Finish, 
			Answer_File = @AnswerFile,
			Completed = 1,
			Package_Run_Id = @PackageRunId
	WHERE	Log_Guid = @LogGuid

	set @ErrorCode = @@Error

GO
ALTER PROCEDURE [dbo].[spMarket_UpdateMarket]
	@TemplateGuid uniqueidentifier,
	@Price money,
	@Description nvarchar(max),
	@Supplier nvarchar(100),
	@SupplierWebsite nvarchar(255),
	@ShortDescription nvarchar(100),
	@ErrorCode int output
as
	IF NOT EXISTS(SELECT * FROM Market WHERE TemplateGuid = @TemplateGuid)
	begin
		INSERT INTO Market (TemplateGuid, Price, Description, Supplier, SupplierWebsite, ShortDescription) 
		VALUES (@TemplateGuid, @Price, @Description, @Supplier, @SupplierWebsite, @ShortDescription)
	end
	ELSE
	begin
		UPDATE	Market
		SET		Price = @Price,
				Description = @Description,
				Supplier = @Supplier,
				SupplierWebsite = @SupplierWebsite,
				ShortDescription = @ShortDescription
		WHERE	TemplateGuid = @TemplateGuid
	end
	
	set @ErrorCode = @@error	

GO
ALTER PROCEDURE [dbo].[spProject_UpdateDefinition] (
	@Xtf xml,
	@TemplateGuid uniqueidentifier
)
AS
	UPDATE	Template 
	SET		Project_Definition = @XTF 
	WHERE	Template_Guid = @TemplateGuid

GO
ALTER PROCEDURE [dbo].[spTemplateGrp_InsertTemplate]
	@Name nvarchar(100),
	@TemplateTypeID int,
	@LayoutID int,
	@FaxTemplateID int,
	@ContentBookmark nvarchar(100),
	@xlModel_File nvarchar(1500),
	@Template_Guid nvarchar(40),
	@Web_Template char(1),
	@Template_Xml nvarchar(max),
	@Template_Version nvarchar(25),
	@Import_Date datetime,
	@HelpText nvarchar(4000),
	@FormatTypeId int,
	@BusinessUnitGUID uniqueidentifier,
	@SupplierGUID uniqueidentifier,
	@NewTemplateID int output,
	@ErrorCode int output
as
/*
Vers	Date		Developer	Description
-------------------------------------------------------------------------------------------------------------
3.1.1	10/07/2004	Chrisg		modified to support guids for import/export
4.0.0	14/06/2005	Chrisg		New paramter - @Store_Xml
4.0.1	14/07/2005	Chrisg		Version support for improved import/export
4.1.0	02/08/2005	Chrisg		Added 'HelpText' parameter
4.6.0	18/12/2006	Chrisg		Store_xml changed to web_template
-------------------------------------------------------------------------------------------------------------
*/
	if (select count(*) from template where template_guid = cast(@Template_Guid as uniqueidentifier)) = 0
	begin
		INSERT INTO template ([name], template_type_id, layout_id, fax_template_id, content_bookmark, file_length, xlModel_File, Template_Guid, web_template, Template_Xml, Template_Version, Import_Date, helptext, FormatTypeId, Business_Unit_GUID, Supplier_GUID)
		VALUES (@Name, @TemplateTypeID, @LayoutID, @FaxTemplateID, @ContentBookmark, 0, @xlModel_File, @Template_Guid, @Web_Template, @Template_Xml, @Template_Version, @Import_Date, @HelpText, @FormatTypeId, @BusinessUnitGUID, @SupplierGUID)
		
		set @NewTemplateID = @@identity
	end

	set @ErrorCode = @@error

GO
ALTER PROCEDURE [dbo].[spTemplateGrp_InsertTemplateLog]
	@UserID int,	
	@TemplateGroupID int,
	@Start datetime,
	@Finish datetime,
	@AnswerFile xml,
	@ErrorCode int output
AS
	insert into Template_Log ([User_ID], Template_Group_ID, DateTime_Start, DateTime_Finish, Answer_File)
	values (@UserID, @TemplateGroupID, @Start, @Finish, @AnswerFile)

	set @ErrorCode = @@Error

GO
ALTER PROCEDURE [dbo].[spTemplateGrp_UpdateTemplate]
	@TemplateID int,
	@Name nvarchar(100),
	@TemplateTypeID int,
	@LayoutID int,
	@FaxTemplateID int,
	@ContentBookmark nvarchar(100),
	@xlModel_File nvarchar(1500),
	@Template_Guid nvarchar(40),
	@Web_Template char(1),
	@Template_Xml nvarchar(max),
	@Template_Version nvarchar(25),
	@Import_Date datetime,
	@HelpText nvarchar(4000),
	@FormatTypeId int,
	@SupplierGUID uniqueidentifier,
	@ErrorCode int output
as
/*
Vers	Date		Developer	Description
-------------------------------------------------------------------------------------------------------------
3.1.2	24/07/2004	Chrisg		modified to support guids for import/export
4.0.0	14/06/2005	Chrisg		new parameter - @Store_Xml for web
4.0.1	14/07/2005	Chrisg		Version info added for improved import/export
4.1.0	02/08/2005	Chrisg		Added 'HelpText' parameter
4.6.0	18/12/2006	Chrisg		Added support for FormatTypeID column
-------------------------------------------------------------------------------------------------------------
*/
	UPDATE	template
	SET	[name] = @Name, template_type_id = @TemplateTypeID, layout_id = @LayoutID,
		fax_template_id = @FaxTemplateID, content_bookmark = @ContentBookmark,
		xlModel_File = @xlModel_File, web_template = @Web_Template, --template_xml = @Template_Xml,
		template_version = @Template_Version, import_date = @Import_Date, helptext = @HelpText,
		formattypeid = @FormatTypeID, Supplier_GUID = @SupplierGUID
	WHERE template_id = @TemplateID

	set @ErrorCode = @@error

GO

--1828
ALTER procedure [dbo].[spTemplateGrp_PackageRunList]
	@PackageRunId int = 0,
	@UserId int = 0,
	@ErrorCode int output
as
/*
Vers	Date		Developer	Description
-------------------------------------------------------------------------------------------------------------
1.3.0	24/04/2006	bruceb		Procedure created
-------------------------------------------------------------------------------------------------------------
*/
	IF @PackageRunId <> 0
	BEGIN
		SELECT	*
		FROM	Package_Run
		WHERE	(Package_Run_Id = @PackageRunId)
				AND (Status_Id = 0)
	END
	ELSE
	BEGIN
		SELECT	Package_Run.Package_Run_id, Package_Run.Package_id, Package_Run.Title, Package_Run.Description, Package_Run.Status_id, Package.Name, Max(Template_Log.DateTime_Finish) as LastUsed
		FROM	Package_Run
				LEFT JOIN Template_Log ON Package_Run.Package_Run_Id = Template_Log.Package_Run_Id
				INNER JOIN Package ON Package_Run.Package_Id = Package.Package_Id
		WHERE	(Package_Run.[User_Id] = @UserId)
				AND (Status_Id = 0)
				AND Package.IsArchived = 0
		GROUP BY Package_Run.Package_Run_id, Package_Run.Package_id, Package_Run.Title, Package_Run.Description, Package_Run.Status_id, Package.Name
		ORDER BY Max(Template_Log.DateTime_Finish) DESC, Package_Run.Title, Package.Name	
	END
GO
ALTER procedure [dbo].[spTemplateGrp_FolderListAll]
	@WebOnly char(1) = '0',
	@BusinessUnitGUID uniqueidentifier,
	@ErrorCode int output
as
--v4.0.1 fixed for web version
--v4.1.2 now webonly also detects related fax coversheet
--v4.6.0 support for web_template

	if @WebOnly = 1
	begin
		SELECT	a.*, 
			case when c.ItemType_Id = 1 then d.Template_Group_ID else 0 end as Template_Group_ID, 
			case when c.ItemType_Id = 1 then CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END else null end as Template_Group_Name,
			case when c.ItemType_Id = 1 then d.HelpText else NULL end as TemplateGroup_HelpText, 
			case when c.ItemType_Id = 1 then b.Template_ID else NULL end as Template_ID,
			case when c.ItemType_Id = 1 then b.[Name] else NULL end as Template_Name,
			case when c.ItemType_Id = 1 then b.Template_Type_ID else NULL end as Template_Type_ID,
			case when c.ItemType_Id = 1 then b.FormatTypeId else NULL end as FormatTypeId,
			d.Template_Group_Guid
		FROM	Folder a
			left join Folder_Template c on a.Folder_ID = c.Folder_ID
			left join Template_Group d on c.FolderItem_Id = d.Template_Group_ID and c.ItemType_Id = 1
			left join Template_Group_Item e on d.Template_Group_ID = e.Template_Group_ID
			left join Template b on e.Template_ID = b.Template_ID
		WHERE	((c.ItemType_ID = 1 and d.Template_Group_ID in (
						select	a.template_group_id
						from	template_group_item a
								inner join template b on a.template_id = b.template_id or a.layout_id = b.template_id
								inner join template_group c on a.template_group_id = c.template_group_id
								left join template_group_item d on c.fax_template_group_id = d.template_group_id
								left join template e on d.template_id = e.template_id or d.layout_id = e.template_id
						group by a.template_group_id
						having min(b.web_template) = 1 and (min(e.web_template) = 1 or min(e.web_template) is null)
					)
				)
			or (c.ItemType_ID = 2))
			and a.Business_Unit_GUID = @BusinessUnitGUID
		ORDER BY a.Folder_Name, a.Folder_ID, c.folderitem_id
	end
	else
	begin
		SELECT	a.*, d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
				d.HelpText as TemplateGroup_HelpText, b.Template_ID, b.[Name] as Template_Name, 
				b.Template_Type_ID, b.FormatTypeId, d.Template_Group_Guid
		FROM	Folder a
				left join Folder_Template c on a.Folder_ID = c.Folder_ID
				left join Template_Group d on c.folderitem_ID = d.Template_Group_ID and itemtype_id = 1
				left join Template_Group_Item e on d.Template_Group_ID = e.Template_Group_ID
				left join Template b on e.Template_ID = b.Template_ID
		WHERE a.Business_Unit_GUID = @BusinessUnitGUID
		ORDER BY a.Folder_Name, a.Folder_ID, d.[Name], b.[Name], c.folderitem_id
	end

	set @ErrorCode = @@error
GO
