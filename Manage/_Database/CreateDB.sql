/* Collation Latin1_General_CI_AS */
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
	CREATE FULLTEXT CATALOG Intelledox AS DEFAULT;
end
GO
CREATE ROLE db_executor
GRANT EXECUTE TO db_executor
GO
CREATE TABLE [dbo].[Action_Output](
	[ActionTypeID] [uniqueidentifier] NOT NULL,
	[ActionOutputID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_Action_Output] PRIMARY KEY CLUSTERED 
(
	[ActionOutputID] ASC
)
)
GO
CREATE TABLE [dbo].[ActionList](
	[ActionListId] [uniqueidentifier] NOT NULL,
	[ProjectGroupGuid] [uniqueidentifier] NOT NULL,
	[CreatorGuid] [uniqueidentifier] NOT NULL,
	[DateCreatedUtc] [datetime] NOT NULL,
 CONSTRAINT [PK_ActionList] PRIMARY KEY CLUSTERED 
(
	[ActionListId] ASC
)
)
GO
CREATE TABLE [dbo].[ActionListState](
	[ActionListStateId] [uniqueidentifier] NOT NULL,
	[ActionListId] [uniqueidentifier] NOT NULL,
	[StateGuid] [uniqueidentifier] NOT NULL,
	[StateName] [nvarchar](200) NOT NULL,
	[PreviousActionListStateId] [uniqueidentifier] NULL,
	[Comment] [nvarchar](max) NULL,
	[AnswerFileXml] [xml] NULL,
	[AssignedGuid] [uniqueidentifier] NOT NULL,
	[AssignedType] [int] NOT NULL,
	[DateCreatedUtc] [datetime] NOT NULL,
	[DateUpdatedUtc] [datetime] NULL,
	[AssignedByGuid] [uniqueidentifier] NULL,
	[LockedByUserGuid] [uniqueidentifier] NULL,
	[ExpireOnUtc] [datetime] NULL,
	[ExpiryEmailBody] [nvarchar](max) NULL,
	[ExpiryEmailSubject] [nvarchar](400) NULL,
	[IsComplete] [bit] NOT NULL,
	[AllowReassign] [bit] NOT NULL,
	[RestrictToGroupGuid] [uniqueidentifier] NULL,
 CONSTRAINT [PK_ActionListState] PRIMARY KEY CLUSTERED 
(
	[ActionListStateId] ASC
)
)
GO
CREATE TABLE [dbo].[Address_Book](
	[Address_ID] [int] IDENTITY(1,1) NOT NULL,
	[Addresstype_ID] [int] NULL,
	[Address_Reference] [nvarchar](50) NULL,
	[Prefix] [nvarchar](50) NULL,
	[First_Name] [nvarchar](50) NULL,
	[Last_Name] [nvarchar](50) NULL,
	[Full_Name] [nvarchar](100) NULL,
	[Salutation_Name] [nvarchar](50) NULL,
	[Title] [nvarchar](50) NULL,
	[Organisation_Name] [nvarchar](100) NULL,
	[Phone_Number] [nvarchar](50) NULL,
	[Fax_Number] [nvarchar](50) NULL,
	[Email_Address] [nvarchar](50) NULL,
	[Street_Address_1] [nvarchar](50) NULL,
	[Street_Address_2] [nvarchar](50) NULL,
	[Street_Address_Suburb] [nvarchar](50) NULL,
	[Street_Address_State] [nvarchar](50) NULL,
	[Street_Address_Postcode] [nvarchar](50) NULL,
	[Street_Address_Country] [nvarchar](50) NULL,
	[Postal_Address_1] [nvarchar](50) NULL,
	[Postal_Address_2] [nvarchar](50) NULL,
	[Postal_Address_Suburb] [nvarchar](50) NULL,
	[Postal_Address_State] [nvarchar](50) NULL,
	[Postal_Address_Postcode] [nvarchar](50) NULL,
	[Postal_Address_Country] [nvarchar](50) NULL,
 CONSTRAINT [Address_Book_pk] PRIMARY KEY CLUSTERED 
(
	[Address_ID] ASC
)
)
GO
CREATE TABLE [dbo].[Address_Book_Custom_Field](
	[Address_Book_Custom_Field_ID] [int] IDENTITY(1,1) NOT NULL,
	[Address_ID] [int] NOT NULL,
	[Custom_Field_ID] [int] NOT NULL,
	[Custom_Value] [nvarchar](4000) NULL,
 CONSTRAINT [PK_Address_Book_Custom_Field_ID] PRIMARY KEY NONCLUSTERED 
(
	[Address_Book_Custom_Field_ID] ASC
)
)
GO
CREATE CLUSTERED INDEX [IX_Address_Book_Custom_Field] ON [dbo].[Address_Book_Custom_Field]
(
	[Address_ID] ASC,
	[Custom_Field_ID] ASC
)
GO
CREATE TABLE [dbo].[Address_Type](
	[Address_Type_ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NULL,
 CONSTRAINT [Address_Type_pk] PRIMARY KEY CLUSTERED 
(
	[Address_Type_ID] ASC
)
)
GO
CREATE TABLE [dbo].[Admin_Group](
	[AdminGroup_ID] [int] IDENTITY(1,1) NOT NULL,
	[AdminLevel_ID] [int] NOT NULL,
	[Windows_Group] [nvarchar](256) NULL,
	[Group_Domain] [nvarchar](256) NULL,
 CONSTRAINT [PK_Admin_Groups] PRIMARY KEY CLUSTERED 
(
	[AdminGroup_ID] ASC
)
)
GO
CREATE TABLE [dbo].[Administrator_Level](
	[AdminLevel_ID] [int] IDENTITY(1,1) NOT NULL,
	[AdminLevel_Description] [nvarchar](50) NULL,
	[RoleGuid] [uniqueidentifier] NULL,
	[Business_Unit_Guid] [uniqueidentifier] NULL,
 CONSTRAINT [Administrator_Level_pk] PRIMARY KEY CLUSTERED 
(
	[AdminLevel_ID] ASC
)
)
GO
CREATE TABLE [dbo].[Answer_File](
	[AnswerFile_Guid] [uniqueidentifier] NOT NULL,
	[User_Guid] [uniqueidentifier] NOT NULL,
	[Template_Group_Guid] [uniqueidentifier] NOT NULL,
	[AnswerFile_ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [nvarchar](255) NULL,
	[RunDate] [datetime] NULL,
	[AnswerString] [xml] NULL,
	[InProgress] [bit] NOT NULL,
 CONSTRAINT [PK_Answer_File2] PRIMARY KEY NONCLUSTERED 
(
	[AnswerFile_Guid] ASC
)
)
GO
CREATE CLUSTERED INDEX [IX_Answer_File_UserGuid] ON [dbo].[Answer_File]
(
	[User_Guid] ASC,
	[Template_Group_Guid] ASC
)
GO
CREATE TABLE [dbo].[Bookmark_Group_Log](
	[Bookmark_Group_Log_Guid] [uniqueidentifier] NOT NULL,
	[Log_Guid] [uniqueidentifier] NOT NULL,
	[Bookmark_Group_Guid] [uniqueidentifier] NOT NULL,
	[TimeTaken] [int] NULL,
 CONSTRAINT [PK_Bookmark_Group_Log] PRIMARY KEY NONCLUSTERED 
(
	[Bookmark_Group_Log_Guid] ASC
)
)
GO
CREATE CLUSTERED INDEX [IX_Bookmark_Group_Log_LogGuid] ON [dbo].[Bookmark_Group_Log]
(
	[Log_Guid] ASC
)
GO
CREATE TABLE [dbo].[Business_Unit](
	[Business_Unit_GUID] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Business_Unit_Business_Unit_GUID]  DEFAULT (newid()),
	[Name] [nvarchar](200) NULL,
	[SubscriptionType] [int] NULL,
	[ExpiryDate] [datetime] NULL,
	[TenantFee] [money] NULL,
	[DefaultLanguage] [nvarchar](10) NULL,
	[UserFee] [money] NULL,
	[SamlEnabled] [bit] NOT NULL DEFAULT ((0)),
	[SamlCertificate] [nvarchar](max) NULL,
	[SamlCertificateType] [int] NOT NULL DEFAULT ((0)),
	[SamlCreateUsers] [bit] NOT NULL DEFAULT ((0)),
	[SamlIssuer] [nvarchar](255) NULL,
	[SamlLoginUrl] [nvarchar](1500) NULL,
	[SamlLogoutUrl] [nvarchar](1500) NULL,
	[SamlLastLoginFail] [nvarchar](max) NULL,
	[SamlManageEntityId] [nvarchar](1500) NULL,
	[SamlProduceEntityId] [nvarchar](1500) NULL,
	[DefaultTimezone] [nvarchar](50) NULL,
	[DefaultCulture] [nvarchar](11) NULL,
 CONSTRAINT [PK_Business_Unit] PRIMARY KEY CLUSTERED 
(
	[Business_Unit_GUID] ASC
)
)
GO
CREATE TABLE [dbo].[Category](
	[Category_ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NULL,
 CONSTRAINT [Category_pk] PRIMARY KEY CLUSTERED 
(
	[Category_ID] ASC
)
)
GO
CREATE TABLE [dbo].[ConnectorSettings_ElementType](
	[ConnectorSettingsElementTypeId] [uniqueidentifier] NOT NULL,
	[ConnectorSettingsTypeId] [uniqueidentifier] NOT NULL,
	[DescriptionDefault] [nvarchar](255) NULL,
	[Encrypt] [bit] NULL,
	[SortOrder] [numeric](18, 0) NULL,
	[ElementValue] [nvarchar](max) NULL,
 CONSTRAINT [PK_ConnectorSettings_ElementType] PRIMARY KEY CLUSTERED 
(
	[ConnectorSettingsElementTypeId] ASC
)
)
GO
CREATE TABLE [dbo].[ConnectorSettings_Type](
	[ConnectorSettingsTypeId] [uniqueidentifier] NOT NULL,
	[ConnectorSettingsDescription] [nvarchar](255) NULL,
 CONSTRAINT [PK_ConnectorSettings_Type] PRIMARY KEY CLUSTERED 
(
	[ConnectorSettingsTypeId] ASC
)
)
GO
CREATE TABLE [dbo].[Content_Definition](
	[ContentDefinition_Id] [int] IDENTITY(1,1) NOT NULL,
	[ContentDefinition_Guid] [uniqueidentifier] NOT NULL,
	[NameIdentity] [nvarchar](255) NOT NULL,
	[Description] [nvarchar](1000) NULL,
 CONSTRAINT [PK_Content_Definition] PRIMARY KEY CLUSTERED 
(
	[ContentDefinition_Guid] ASC
)
)
GO
CREATE TABLE [dbo].[Content_Definition_Item](
	[ContentDefinitionItem_Id] [int] IDENTITY(1,1) NOT NULL,
	[ContentDefinition_Id] [int] NULL,
	[ContentDefinition_Guid] [uniqueidentifier] NULL,
	[ContentItem_Id] [int] NULL,
	[ContentItem_Guid] [uniqueidentifier] NULL,
	[SortIndex] [int] NOT NULL,
 CONSTRAINT [PK_ContentDefinition_Item] PRIMARY KEY NONCLUSTERED 
(
	[ContentDefinitionItem_Id] ASC
)
)
GO
CREATE CLUSTERED INDEX [IX_Content_Definition_Item] ON [dbo].[Content_Definition_Item]
(
	[ContentDefinition_Guid] ASC,
	[ContentItem_Guid] ASC
)
GO
CREATE TABLE [dbo].[Content_Folder](
	[FolderGuid] [uniqueidentifier] NOT NULL,
	[FolderName] [nvarchar](50) NULL,
	[BusinessUnitGuid] [uniqueidentifier] NULL,
 CONSTRAINT [PK_Content_Folder] PRIMARY KEY CLUSTERED 
(
	[FolderGuid] ASC
)
)
GO
CREATE TABLE [dbo].[Content_Folder_Group](
	[FolderGuid] [uniqueidentifier] NOT NULL,
	[GroupGuid] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_Content_Folder_Group] PRIMARY KEY CLUSTERED 
(
	[FolderGuid] ASC,
	[GroupGuid] ASC
)
)
GO
CREATE TABLE [dbo].[Content_Item](
	[ContentItem_Id] [int] IDENTITY(1,1) NOT NULL,
	[ContentItem_Guid] [uniqueidentifier] NOT NULL,
	[NameIdentity] [nvarchar](255) NOT NULL,
	[ContentType_Id] [int] NULL,
	[Description] [nvarchar](1000) NULL,
	[Business_Unit_GUID] [uniqueidentifier] NULL,
	[ContentData_Id] [int] NULL,
	[ContentData_Guid] [uniqueidentifier] NULL,
	[SizeScale] [real] NULL,
	[Reference_Id] [varchar](255) NULL,
	[Category] [int] NULL,
	[Provider_Name] [nvarchar](50) NULL,
	[IsIndexed] [bit] NULL,
	[Approved] [int] NOT NULL,
	[FolderGuid] [uniqueidentifier] NULL,
	[ExpiryDate] [datetime] NULL,
 CONSTRAINT [PK_Content_Item] PRIMARY KEY CLUSTERED 
(
	[ContentItem_Guid] ASC
)
)
GO
CREATE TABLE [dbo].[Content_Item_Placeholder](
	[ContentItemGuid] [uniqueidentifier] NOT NULL,
	[PlaceholderName] [nvarchar](100) NOT NULL,
	[TypeId] [int] NOT NULL
)
GO
CREATE CLUSTERED INDEX [IX_Content_Item_Placeholder] ON [dbo].[Content_Item_Placeholder]
(
	[ContentItemGuid] ASC
)
GO
CREATE TABLE [dbo].[Content_Type](
	[ContentType_Id] [int] IDENTITY(1,1) NOT NULL,
	[ContentType_Name] [varchar](255) NULL,
 CONSTRAINT [PK_Content_Type] PRIMARY KEY CLUSTERED 
(
	[ContentType_Id] ASC
)
)
GO
CREATE TABLE [dbo].[ContentData_Binary](
	[ContentData_Id] [int] IDENTITY(1,1) NOT NULL,
	[ContentData_Guid] [uniqueidentifier] NOT NULL,
	[ContentData] [varbinary](max) NULL,
	[FileType] [varchar](5) NULL,
	[tStamp] [timestamp] NOT NULL,
	[ContentData_Version] [int] NULL,
	[Modified_Date] [datetime] NULL,
	[Modified_By] [uniqueidentifier] NULL,
 CONSTRAINT [PK_Content_Binary] PRIMARY KEY CLUSTERED 
(
	[ContentData_Guid] ASC
)
)
GO
CREATE TABLE [dbo].[ContentData_Binary_Version](
	[ContentData_Version] [int] NOT NULL,
	[ContentData_Guid] [uniqueidentifier] NOT NULL,
	[ContentData] [varbinary](max) NULL,
	[FileType] [varchar](5) NULL,
	[Modified_Date] [datetime] NULL,
	[Modified_By] [uniqueidentifier] NULL,
	[Approved] [int] NOT NULL,
 CONSTRAINT [PK_Content_Binary_Version] PRIMARY KEY CLUSTERED 
(
	[ContentData_Guid] ASC,
	[ContentData_Version] ASC
)
)
GO
CREATE TABLE [dbo].[ContentData_Text](
	[ContentData_Id] [int] IDENTITY(1,1) NOT NULL,
	[ContentData_Guid] [uniqueidentifier] NOT NULL,
	[ContentData] [nvarchar](max) NULL,
	[ContentData_Version] [int] NULL,
	[Modified_Date] [datetime] NULL,
	[Modified_By] [uniqueidentifier] NULL,
 CONSTRAINT [PK_ContentData_Text] PRIMARY KEY CLUSTERED 
(
	[ContentData_Guid] ASC
)
)
GO
CREATE TABLE [dbo].[ContentData_Text_Version](
	[ContentData_Version] [int] NOT NULL,
	[ContentData_Guid] [uniqueidentifier] NOT NULL,
	[ContentData] [nvarchar](max) NULL,
	[Modified_Date] [datetime] NULL,
	[Modified_By] [uniqueidentifier] NULL,
	[Approved] [int] NOT NULL,
 CONSTRAINT [PK_Content_Text_Version] PRIMARY KEY CLUSTERED 
(
	[ContentData_Guid] ASC,
	[ContentData_Version] ASC
)
)
GO
CREATE TABLE [dbo].[Custom_Field](
	[Custom_Field_ID] [int] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](100) NOT NULL,
	[Validation_Type] [int] NOT NULL,
	[Field_Length] [int] NOT NULL,
	[Location] [int] NULL,
 CONSTRAINT [PK_Custom_Field] PRIMARY KEY NONCLUSTERED 
(
	[Custom_Field_ID] ASC
)
)
GO
CREATE CLUSTERED INDEX [IX_Custom_Field_LocationTitle] ON [dbo].[Custom_Field]
(
	[Location] ASC,
	[Title] ASC
)
GO
CREATE TABLE [dbo].[Data_Object](
	[Data_Object_ID] [int] IDENTITY(1,1) NOT NULL,
	[Data_Service_ID] [int] NULL,
	[Object_Name] [nvarchar](500) NULL,
	[Merge_Source] [char](1) NULL,
	[Data_Object_Guid] [uniqueidentifier] NOT NULL,
	[Data_Service_Guid] [uniqueidentifier] NULL,
	[Object_Type] [uniqueidentifier] NULL,
	[Display_Name] [nvarchar](500) NULL,
 CONSTRAINT [PK_Data_Object] PRIMARY KEY NONCLUSTERED 
(
	[Data_Object_Guid] ASC
)
)
GO
CREATE CLUSTERED INDEX [IX_Data_Object_DataServiceGuid] ON [dbo].[Data_Object]
(
	[Data_Service_Guid] ASC
)
GO
CREATE TABLE [dbo].[Data_Object_Display](
	[Data_Object_Guid] [uniqueidentifier] NOT NULL,
	[Field_Name] [nvarchar](500) NOT NULL,
	[Display_Name] [nvarchar](500) NOT NULL
)
GO
CREATE CLUSTERED INDEX [IX_Data_Object_Display] ON [dbo].[Data_Object_Display]
(
	[Data_Object_Guid] ASC
)
GO
CREATE TABLE [dbo].[Data_Object_Key](
	[Data_Object_Key_ID] [int] IDENTITY(1,1) NOT NULL,
	[Data_Object_ID] [int] NULL,
	[Field_Name] [nvarchar](500) NULL,
	[Data_Type] [int] NULL,
	[Required] [char](1) NULL,
	[Display_Name] [nvarchar](500) NULL,
	[Data_Object_Guid] [uniqueidentifier] NULL,
	[Data_Object_Key_Guid] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_Data_Object_Key] PRIMARY KEY NONCLUSTERED 
(
	[Data_Object_Key_Guid] ASC
)
)
GO
CREATE CLUSTERED INDEX [IX_Data_Object_Key_DataObjectGuid] ON [dbo].[Data_Object_Key]
(
	[Data_Object_Guid] ASC
)
GO
CREATE TABLE [dbo].[Data_Service](
	[Data_Service_ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NULL,
	[Connection_String] [nvarchar](max) NULL,
	[Database_Object] [nvarchar](100) NULL,
	[merge_source] [char](1) NULL,
	[allow_writeback] [char](1) NULL,
	[Data_Service_Guid] [uniqueidentifier] NOT NULL,
	[Requires_Credentials] [char](1) NULL,
	[Allow_Connection_Export] [char](1) NULL,
	[Business_Unit_Guid] [uniqueidentifier] NOT NULL,
	[Provider_Name] [nvarchar](50) NULL,
	[Allow_Insert] [char](1) NULL,
	[Credential_Method] [int] NULL,
	[PasswordHash] [varchar](1000) NULL,
	[Username] [nvarchar](100) NULL,
 CONSTRAINT [PK_Data_Service] PRIMARY KEY CLUSTERED 
(
	[Data_Service_Guid] ASC
)
)
GO
CREATE TABLE [dbo].[Data_Service_Credential](
	[Data_Service_Credential_ID] [int] IDENTITY(1,1) NOT NULL,
	[Data_Service_ID] [int] NOT NULL,
	[User_ID] [int] NOT NULL,
	[Username] [nvarchar](50) NULL,
	[Password] [nvarchar](500) NULL,
	[Data_Service_Guid] [uniqueidentifier] NULL,
 CONSTRAINT [PK_Data_Service_Credential] PRIMARY KEY CLUSTERED 
(
	[Data_Service_Credential_ID] ASC
)
)
GO
CREATE TABLE [dbo].[dbversion](
	[dbversion] [varchar](20) NOT NULL,
 CONSTRAINT [PK_dbversion] PRIMARY KEY CLUSTERED 
(
	[dbversion] ASC
)
)
GO
CREATE TABLE [dbo].[Document](
	[DocumentId] [uniqueidentifier] NOT NULL,
	[Extension] [nvarchar](10) NOT NULL,
	[JobId] [uniqueidentifier] NOT NULL,
	[UserGuid] [uniqueidentifier] NOT NULL,
	[DisplayName] [nvarchar](255) NOT NULL,
	[DateCreated] [datetime] NOT NULL,
	[DocumentBinary] [varbinary](max) NOT NULL,
	[DocumentLength] [int] NOT NULL,
	[ProjectDocumentGuid] [uniqueidentifier] NULL,
	[Downloadable] [bit] NOT NULL,
	[ActionOnly] [bit] NOT NULL,
 CONSTRAINT [PK_Document] PRIMARY KEY CLUSTERED 
(
	[DocumentId] ASC,
	[Extension] ASC
)
)
GO
CREATE TABLE [dbo].[EventLog](
	[LogEventID] [int] IDENTITY(1,1) NOT NULL,
	[DateTime] [datetime] NOT NULL,
	[Message] [nvarchar](max) NOT NULL,
	[LevelID] [int] NOT NULL,
 CONSTRAINT [PK_EventLog] PRIMARY KEY CLUSTERED 
(
	[LogEventID] ASC
)
)
GO
CREATE TABLE [dbo].[Folder](
	[Folder_ID] [int] IDENTITY(1,1) NOT NULL,
	[Folder_Name] [nvarchar](50) NULL,
	[User_Group_ID] [int] NULL,
	[Business_Unit_GUID] [uniqueidentifier] NULL,
	[Folder_Guid] [uniqueidentifier] NULL,
 CONSTRAINT [Folder_pk] PRIMARY KEY CLUSTERED 
(
	[Folder_ID] ASC
)
)
GO
CREATE TABLE [dbo].[Folder_Group](
	[FolderGuid] [uniqueidentifier] NOT NULL,
	[GroupGuid] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_Folder_Group] PRIMARY KEY CLUSTERED 
(
	[FolderGuid] ASC,
	[GroupGuid] ASC
)
)
GO
CREATE TABLE [dbo].[Format_Type](
	[FormatTypeId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](255) NULL,
	[FileExtension] [varchar](50) NULL,
	[Description] [nvarchar](4000) NULL,
 CONSTRAINT [PK_Format_Type] PRIMARY KEY CLUSTERED 
(
	[FormatTypeId] ASC
)
)
GO
CREATE TABLE [dbo].[Global_Options](
	[OptionID] [int] IDENTITY(1,1) NOT NULL,
	[OptionCode] [nvarchar](255) NOT NULL,
	[OptionDescription] [nvarchar](1000) NULL,
	[OptionValue] [nvarchar](4000) NULL,
 CONSTRAINT [PK_Global_Options] PRIMARY KEY CLUSTERED 
(
	[OptionID] ASC
)
)
GO
CREATE TABLE [dbo].[Group_Output](
	[GroupGuid] [uniqueidentifier] NOT NULL,
	[FormatTypeId] [int] NOT NULL,
	[LockOutput] [bit] NOT NULL,
	[EmbedFullFonts] [bit] NOT NULL,
 CONSTRAINT [PK_Folder_Group_Output] PRIMARY KEY CLUSTERED 
(
	[GroupGuid] ASC,
	[FormatTypeId] ASC
)
)
GO
CREATE TABLE [dbo].[Intelledox_User](
	[User_ID] [int] IDENTITY(1,1) NOT NULL,
	[Username] [nvarchar](50) NULL,
	[pwdhash] [varchar](1000) NULL,
	[AdminLevel_ID] [int] NULL,
	[WinNT_User] [bit] NOT NULL CONSTRAINT [DF_Intelledox_User_WinNT_User]  DEFAULT ((0)),
	[Business_Unit_GUID] [uniqueidentifier] NULL,
	[User_Guid] [uniqueidentifier] NULL,
	[SelectedTheme] [nvarchar](100) NULL,
	[ChangePassword] [bit] NOT NULL CONSTRAINT [DF_Intelledox_User_ChangePassword]  DEFAULT ((0)),
	[PwdFormat] [int] NULL CONSTRAINT [DF_Intelledox_User_PwdFormat]  DEFAULT ((1)),
	[PwdSalt] [nvarchar](128) NULL,
	[Disabled] [bit] NOT NULL CONSTRAINT [DF_Intelledox_User_Disabled]  DEFAULT ((0)),
	[Address_ID] [int] NULL,
	[Timezone] [nvarchar](50) NULL,
	[Culture] [nvarchar](11) NULL,
	[Language] [nvarchar](11) NULL,
 CONSTRAINT [PK_Intelledox_User] PRIMARY KEY NONCLUSTERED 
(
	[User_ID] ASC
)
)
GO
CREATE CLUSTERED INDEX [IX_Intelledox_User_UserGuid] ON [dbo].[Intelledox_User]
(
	[User_Guid] ASC
)
GO
CREATE TABLE [dbo].[JobDefinition](
	[JobDefinitionId] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](200) NULL,
	[NextRunDate] [datetime] NULL,
	[IsEnabled] [bit] NULL,
	[OwnerGuid] [uniqueidentifier] NULL,
	[DateCreated] [datetime] NULL,
	[DateModified] [datetime] NULL,
	[JobDefinition] [xml] NULL,
	[WatchFolder] [nvarchar](300) NULL,
	[DataSourceGuid] [uniqueidentifier] NULL,
	[DeleteAfterDays] [int] NOT NULL,
	[LastRunDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[JobDefinitionId] ASC
)
)
GO
CREATE TABLE [dbo].[License_Key](
	[LicenseKeyId] [int] IDENTITY(1,1) NOT NULL,
	[LicenseKey] [varchar](1000) NOT NULL,
	[IsProductKey] [char](1) NOT NULL,
 CONSTRAINT [PK_License_Key] PRIMARY KEY CLUSTERED 
(
	[LicenseKeyId] ASC
)
)
GO
CREATE TABLE [dbo].[Permission](
	[PermissionGuid] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Permission_PermissionGuid]  DEFAULT (newid()),
	[Name] [nvarchar](100) NOT NULL,
	[Description] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_Permission] PRIMARY KEY CLUSTERED 
(
	[PermissionGuid] ASC
)
)
GO
CREATE TABLE [dbo].[ProcessJob](
	[JobId] [uniqueidentifier] NOT NULL,
	[UserGuid] [uniqueidentifier] NULL,
	[DateStarted] [datetime] NULL,
	[ProjectGroupGuid] [uniqueidentifier] NULL,
	[CurrentStatus] [int] NULL,
	[LogGuid] [uniqueidentifier] NULL,
	[JobDefinitionGuid] [uniqueidentifier] NULL,
 CONSTRAINT [PK_ProcessJob] PRIMARY KEY CLUSTERED 
(
	[JobId] ASC
)
)
GO
CREATE TABLE [dbo].[PurchaseLineItem](
	[Line_Item_ID] [int] IDENTITY(1,1) NOT NULL,
	[Transaction_ID] [int] NOT NULL,
	[Description] [nvarchar](300) NOT NULL,
	[Item_Guid] [uniqueidentifier] NOT NULL,
	[Supplier_Guid] [uniqueidentifier] NOT NULL,
	[Price] [money] NOT NULL,
	[Claimed] [datetime] NULL,
 CONSTRAINT [PK_PurchaseLineItem] PRIMARY KEY NONCLUSTERED 
(
	[Line_Item_ID] ASC
)
)
GO
CREATE CLUSTERED INDEX [IX_PurchaseLineItem_TransactionID] ON [dbo].[PurchaseLineItem]
(
	[Transaction_ID] ASC
)
GO
CREATE TABLE [dbo].[PurchaseTransaction](
	[Transaction_ID] [int] IDENTITY(1,1) NOT NULL,
	[User_Id] [int] NULL,
	[Price] [money] NULL,
	[Transaction_Amount] [money] NULL,
	[Transaction_Date] [datetime] NULL,
	[Order_Number] [nvarchar](100) NULL,
	[Card_Type] [nvarchar](100) NULL,
	[Card_Number] [nvarchar](4) NULL,
	[Card_Name] [nvarchar](100) NULL,
	[Response_Text] [nvarchar](max) NULL,
	[Response_Summary] [nvarchar](10) NULL,
	[Response_Code] [nvarchar](10) NULL,
	[Response_RRN] [nvarchar](50) NULL,
	[Error_Number] [nvarchar](10) NULL,
	[Error_Message] [nvarchar](1000) NULL,
	[Approved] [nvarchar](10) NULL,
	[Remote_Ip] [nvarchar](20) NULL,
	[Description] [nvarchar](300) NULL,
	[Business_Unit_Guid] [uniqueidentifier] NULL,
 CONSTRAINT [PK_PurchaseTransaction] PRIMARY KEY CLUSTERED 
(
	[Transaction_ID] ASC
)
)
GO
CREATE TABLE [dbo].[Question_Type](
	[Question_Type_ID] [int] IDENTITY(1,1) NOT NULL,
	[Description] [nvarchar](100) NULL,
	[Web_Type] [char](1) NOT NULL CONSTRAINT [DF_Question_Type_Desktop_Only]  DEFAULT ((1)),
 CONSTRAINT [Question_Type_pk] PRIMARY KEY CLUSTERED 
(
	[Question_Type_ID] ASC
)
)
GO
CREATE TABLE [dbo].[RecurrencePattern](
	[RecurrencePatternID] [uniqueidentifier] NOT NULL,
	[JobDefinitionId] [uniqueidentifier] NOT NULL,
	[Frequency] [varchar](10) NULL,
	[StartDate] [datetime] NOT NULL,
	[RepeatUntil] [datetime] NULL,
	[RepeatCount] [int] NULL,
	[Interval] [int] NULL,
	[ByDay] [varchar](50) NULL,
	[ByMonthDay] [varchar](50) NULL,
	[ByYearDay] [varchar](50) NULL,
	[ByWeekNo] [varchar](50) NULL,
	[ByMonth] [varchar](50) NULL,
	[BySetPosition] [int] NULL,
	[WeekStart] [varchar](2) NULL,
 CONSTRAINT [PK_RecurrencePattern] PRIMARY KEY CLUSTERED 
(
	[RecurrencePatternID] ASC
)
)
GO
CREATE TABLE [dbo].[Role_Permission](
	[PermissionGuid] [uniqueidentifier] NOT NULL,
	[RoleGuid] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_Role_Permission] PRIMARY KEY CLUSTERED 
(
	[PermissionGuid] ASC,
	[RoleGuid] ASC
)
)
GO
CREATE TABLE [dbo].[Routing_ElementType](
	[RoutingElementTypeId] [uniqueidentifier] NOT NULL,
	[RoutingTypeId] [uniqueidentifier] NULL,
	[ElementTypeDescription] [nvarchar](255) NULL,
	[ElementLimit] [int] NULL,
	[Required] [bit] NOT NULL,
 CONSTRAINT [PK_Routing_ElementType_Guid] PRIMARY KEY CLUSTERED 
(
	[RoutingElementTypeId] ASC
)
)
GO
CREATE TABLE [dbo].[Routing_Type](
	[RoutingTypeId] [uniqueidentifier] NOT NULL,
	[RoutingTypeDescription] [nvarchar](255) NULL,
	[ProviderType] [int] NULL,
	[RunForAllProjects] [bit] NOT NULL,
	[SupportsUI] [bit] NULL,
	[SupportsRun] [bit] NULL,
 CONSTRAINT [PK_Routing_Type_Guid] PRIMARY KEY CLUSTERED 
(
	[RoutingTypeId] ASC
)
)
GO
CREATE TABLE [dbo].[Template](
	[Template_ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NULL,
	[Template_Type_ID] [int] NULL,
	[Fax_Template_ID] [int] NULL,
	[content_bookmark] [nvarchar](100) NULL,
	[Template_Guid] [uniqueidentifier] NULL,
	[Template_Version] [nvarchar](10) NULL,
	[Import_Date] [datetime] NULL,
	[HelpText] [nvarchar](4000) NULL,
	[Business_Unit_GUID] [uniqueidentifier] NULL,
	[Supplier_Guid] [uniqueidentifier] NULL,
	[Project_Definition] [xml] NULL,
	[Modified_Date] [datetime] NULL,
	[Modified_By] [uniqueidentifier] NULL,
	[Comment] [nvarchar](max) NULL,
	[LockedByUserGuid] [uniqueidentifier] NULL,
	[IsMajorVersion] [bit] NOT NULL,
	[FeatureFlags] [int] NOT NULL,
 CONSTRAINT [Template_pk] PRIMARY KEY CLUSTERED 
(
	[Template_ID] ASC
)
)
GO
CREATE TABLE [dbo].[Template_Category](
	[Template_Category_ID] [int] IDENTITY(1,1) NOT NULL,
	[Template_ID] [int] NULL,
	[Category_ID] [int] NULL,
 CONSTRAINT [Template_Category_pk] PRIMARY KEY CLUSTERED 
(
	[Template_Category_ID] ASC
)
)
GO
CREATE TABLE [dbo].[Template_File](
	[Template_Guid] [uniqueidentifier] NOT NULL,
	[File_Guid] [uniqueidentifier] NOT NULL,
	[Binary] [varbinary](max) NOT NULL,
	[FormatTypeId] [varchar](6) NULL,
	[TemplateFileId] [uniqueidentifier] NOT NULL,
	[tStamp] [timestamp] NOT NULL,
 CONSTRAINT [PK_Template_File] PRIMARY KEY CLUSTERED 
(
	[Template_Guid] ASC,
	[File_Guid] ASC
)
)
GO
CREATE TABLE [dbo].[Template_File_Version](
	[Template_Guid] [uniqueidentifier] NOT NULL,
	[File_Guid] [uniqueidentifier] NOT NULL,
	[Binary] [varbinary](max) NOT NULL,
	[Template_Version] [nvarchar](10) NOT NULL,
	[FormatTypeId] [varchar](6) NULL,
 CONSTRAINT [PK_Template_File_Version2] PRIMARY KEY CLUSTERED 
(
	[Template_Guid] ASC,
	[File_Guid] ASC,
	[Template_Version] ASC
)
)
GO
CREATE TABLE [dbo].[Template_Group](
	[Template_Group_ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NULL,
	[Template_Group_Guid] [uniqueidentifier] NOT NULL,
	[HelpText] [nvarchar](max) NULL,
	[AllowPreview] [bit] NULL,
	[PostGenerateText] [nvarchar](max) NULL,
	[UpdateDocumentFields] [bit] NULL,
	[EnforceValidation] [bit] NULL,
	[WizardFinishText] [nvarchar](max) NULL,
	[EnforcePublishPeriod] [bit] NULL,
	[PublishStartDate] [datetime] NULL,
	[PublishFinishDate] [datetime] NULL,
	[HideNavigationPane] [bit] NULL,
	[Template_Guid] [uniqueidentifier] NULL,
	[Template_Version] [nvarchar](10) NULL,
	[Layout_Guid] [uniqueidentifier] NULL,
	[Layout_Version] [nvarchar](10) NULL,
	[Folder_Guid] [uniqueidentifier] NULL,
 CONSTRAINT [PK_Template_Group] PRIMARY KEY CLUSTERED 
(
	[Template_Group_Guid] ASC
)
)
GO
CREATE TABLE [dbo].[Template_Log](
	[Log_Guid] [uniqueidentifier] NOT NULL,
	[User_ID] [int] NULL,
	[Template_Group_ID] [int] NULL,
	[DateTime_Start] [datetime] NOT NULL,
	[DateTime_Finish] [datetime] NULL,
	[Answer_File] [xml] NULL,
	[Completed] [bit] NULL,
	[Last_Bookmark_Group_Guid] [uniqueidentifier] NULL,
	[Answer_File_Used] [bit] NULL,
	[Package_Run_Id] [int] NULL,
	[InProgress] [bit] NULL,
	[Messages] [xml] NULL,
 CONSTRAINT [PK_Template_Log] PRIMARY KEY NONCLUSTERED 
(
	[Log_Guid] ASC
)
)
GO
CREATE CLUSTERED INDEX [IX_Template_Log_Dates] ON [dbo].[Template_Log]
(
	[DateTime_Start] ASC,
	[DateTime_Finish] ASC
)
GO
CREATE TABLE [dbo].[Template_Recent](
	[User_Guid] [uniqueidentifier] NOT NULL,
	[DateTime_Start] [datetime] NOT NULL,
	[Template_Group_Guid] [uniqueidentifier] NOT NULL,
	[Log_Guid] [uniqueidentifier] NULL
)
GO
CREATE CLUSTERED INDEX [IX_Template_Recent] ON [dbo].[Template_Recent]
(
	[User_Guid] ASC,
	[DateTime_Start] DESC,
	[Template_Group_Guid] ASC
)
GO
CREATE TABLE [dbo].[Template_Styles](
	[ProjectGuid] [uniqueidentifier] NOT NULL,
	[Title] [nvarchar](100) NOT NULL,
	[FontName] [nvarchar](100) NOT NULL,
	[Size] [decimal](9, 3) NOT NULL,
	[FontColour] [int] NOT NULL,
	[Bold] [bit] NOT NULL,
	[Italic] [bit] NOT NULL,
	[Underline] [bit] NOT NULL,
	[TemplateStyleGuid] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_Template_Styles] PRIMARY KEY NONCLUSTERED 
(
	[TemplateStyleGuid] ASC
)
)
GO
CREATE CLUSTERED INDEX [IX_Template_Styles_ProjectGuid] ON [dbo].[Template_Styles]
(
	[ProjectGuid] ASC
)
GO
CREATE TABLE [dbo].[Template_Version](
	[Template_Version] [nvarchar](10) NOT NULL,
	[Template_Guid] [uniqueidentifier] NOT NULL,
	[Modified_Date] [datetime] NULL,
	[Modified_By] [uniqueidentifier] NULL,
	[Project_Definition] [xml] NULL,
	[Comment] [nvarchar](max) NULL,
	[IsMajorVersion] [bit] NOT NULL,
	[FeatureFlags] [int] NOT NULL,
 CONSTRAINT [PK_Template_Version2] PRIMARY KEY CLUSTERED 
(
	[Template_Guid] ASC,
	[Template_Version] ASC
)
)
GO
CREATE TABLE [dbo].[User_Address_Book](
	[User_Address_Book_ID] [int] IDENTITY(1,1) NOT NULL,
	[User_ID] [int] NOT NULL,
	[Address_ID] [int] NULL,
 CONSTRAINT [User_Address_Book_pk] PRIMARY KEY CLUSTERED 
(
	[User_Address_Book_ID] ASC
)
)
GO
CREATE TABLE [dbo].[User_Group](
	[User_Group_ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NULL,
	[WinNT_Group] [bit] NOT NULL CONSTRAINT [DF_User_Group_WinNT_Group]  DEFAULT ((0)),
	[Business_Unit_GUID] [uniqueidentifier] NULL,
	[Group_Guid] [uniqueidentifier] NULL,
	[AutoAssignment] [bit] NOT NULL CONSTRAINT [DF_User_Group_AutoAssignment]  DEFAULT ((0)),
	[SystemGroup] [bit] NOT NULL CONSTRAINT [DF_User_Group_SystemGroup]  DEFAULT ((0)),
	[Address_ID] [int] NULL,
 CONSTRAINT [User_Group_pk] PRIMARY KEY NONCLUSTERED 
(
	[User_Group_ID] ASC
)
)
GO
CREATE CLUSTERED INDEX [IX_User_Group_GroupGuid] ON [dbo].[User_Group]
(
	[Group_Guid] ASC
)
GO
CREATE TABLE [dbo].[User_Group_Role](
	[GroupGuid] [uniqueidentifier] NOT NULL,
	[RoleGuid] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_User_Group_Role] PRIMARY KEY CLUSTERED 
(
	[GroupGuid] ASC,
	[RoleGuid] ASC
)
)
GO
CREATE TABLE [dbo].[User_Group_Subscription](
	[UserGuid] [uniqueidentifier] NOT NULL,
	[GroupGuid] [uniqueidentifier] NOT NULL,
	[IsDefaultGroup] [bit] NOT NULL CONSTRAINT [DF_User_Group_Subscription_IsDefaultGroup]  DEFAULT ((0)),
 CONSTRAINT [PK_User_Group_Subscription] PRIMARY KEY CLUSTERED 
(
	[UserGuid] ASC,
	[GroupGuid] ASC
)
)
GO
CREATE TABLE [dbo].[User_Group_Template](
	[GroupGuid] [uniqueidentifier] NOT NULL,
	[TemplateGuid] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_User_Group_Template] PRIMARY KEY CLUSTERED 
(
	[TemplateGuid] ASC,
	[GroupGuid] ASC
)
)
GO
CREATE TABLE [dbo].[User_Role](
	[UserGuid] [uniqueidentifier] NOT NULL,
	[RoleGuid] [uniqueidentifier] NOT NULL,
	[GroupGuid] [uniqueidentifier] NULL
)
GO
CREATE UNIQUE CLUSTERED INDEX [IX_User_Role] ON [dbo].[User_Role]
(
	[UserGuid] ASC,
	[RoleGuid] ASC,
	[GroupGuid] ASC
)
GO
CREATE TABLE [dbo].[User_Session](
	[Session_Guid] [uniqueidentifier] NOT NULL,
	[User_Guid] [uniqueidentifier] NOT NULL,
	[Modified_Date] [datetime] NOT NULL,
	[AnswerFile_ID] [int] NULL,
	[Log_Guid] [uniqueidentifier] NULL,
 CONSTRAINT [PK_User_Session] PRIMARY KEY CLUSTERED 
(
	[Session_Guid] ASC
)
)
GO
CREATE TABLE [dbo].[User_Signoff](
	[Signoff_Id] [int] IDENTITY(1,1) NOT NULL,
	[User_ID] [int] NOT NULL,
	[Name] [nvarchar](50) NULL,
	[Other_Detail] [nvarchar](4000) NULL,
 CONSTRAINT [User_Signoff_pk] PRIMARY KEY CLUSTERED 
(
	[Signoff_Id] ASC
)
)
GO
CREATE VIEW [dbo].[vwContentItemVersionDetails]
AS
	SELECT	ContentData_Version, ContentData_Guid, Modified_Date, Modified_By, Approved
	FROM	ContentData_Binary_Version
	UNION
	SELECT	ContentData_Version, ContentData_Guid, Modified_Date, Modified_By, Approved
	FROM	ContentData_Text_Version

GO
CREATE VIEW [dbo].[vwStatsAllData]
AS
SELECT     TLog.Log_Guid, T.Name AS TemplateGroup, IUser.Username AS Creator, TLog.DateTime_Start, TLog.DateTime_Finish, 
                      CASE WHEN day(tlog.datetime_start) < 10 THEN substring(CAST(CONVERT(varchar(50), TLog.DateTime_Start, 103) AS varchar(50)), 2, 9) 
                      ELSE CAST(CONVERT(varchar(50), TLog.DateTime_Start, 103) AS varchar(50)) END AS Date_Start, DATEDIFF(s, TLog.DateTime_Start, 
                      TLog.DateTime_Finish) AS TimeTaken
FROM        Template_Log AS TLog 
			INNER JOIN Intelledox_User AS IUser ON TLog.User_ID = IUser.User_ID 
			INNER JOIN Template_Group AS TG ON TG.Template_Group_ID = TLog.Template_Group_ID
			INNER JOIN Template AS T ON TG.Template_Guid = T.Template_Guid

GO
CREATE VIEW [dbo].[vwStatsDailyLoginReport]
as
    select u.Username, ab.first_name as firstname, ab.last_name as lastname, ab.organisation_name, tblLog.GenDate as LoginDate, tblLog.Startcount, tblLog.Finishcount from (
        select logstart.User_Id, cast(floor(cast(logstart.DateTime_Start as float)) as datetime) as GenDate, count(logstart.log_guid) as StartCount, logfinish.FinishCount
        from template_log logStart
        left join (
            select User_Id, cast(floor(cast(DateTime_Finish as float)) as datetime) as FinishDate, count(log_guid) as FinishCount
            from template_log
            where datetime_finish is not null
            group by User_ID, cast(floor(cast(DateTime_Finish as float)) as datetime)
        ) logFinish on logStart.user_id = logfinish.user_id and logfinish.Finishdate = cast(floor(cast(logstart.DateTime_Start as float)) as datetime)
        where logstart.DateTime_Start is not null
        group by logstart.User_ID, cast(floor(cast(logstart.DateTime_Start as float)) as datetime), logfinish.FinishCount
    ) tblLog
    left join intelledox_user u on u.user_id = tblLog.user_id
    left join address_book ab on u.Address_Id = ab.Address_ID

GO
CREATE VIEW [dbo].[vwStatsDailyLoginReportSummary]
as
    select LoginDate, sum(StartCount) as StartTotal, sum(FinishCount) as FinishTotal
    from (
        select u.Username, ab.first_name as firstname, ab.last_name as lastname, ab.organisation_name, tblLog.GenDate as LoginDate, tblLog.Startcount, tblLog.Finishcount from (
            select logstart.User_Id, cast(floor(cast(logstart.DateTime_Start as float)) as datetime) as GenDate, count(logstart.log_guid) as StartCount, logfinish.FinishCount
            from template_log logStart
            left join (
                select User_Id, cast(floor(cast(DateTime_Finish as float)) as datetime) as FinishDate, count(log_guid) as FinishCount
                from template_log
                where datetime_finish is not null
                group by User_ID, cast(floor(cast(DateTime_Finish as float)) as datetime)
            ) logFinish on logStart.user_id = logfinish.user_id and logfinish.Finishdate = cast(floor(cast(logstart.DateTime_Start as float)) as datetime)
            where logstart.DateTime_Start is not null
            group by logstart.User_ID, cast(floor(cast(logstart.DateTime_Start as float)) as datetime), logfinish.FinishCount
        ) tblLog
        left join intelledox_user u on u.user_id = tblLog.user_id
        left join address_book ab on u.Address_ID = ab.Address_ID
        ) a
    group by LoginDate


GO
CREATE VIEW [dbo].[vwStatsSummaryData]
AS
SELECT     TOP 100 PERCENT IUser.Username AS Creator, T.Name AS TemplateGroup, AVG(DATEDIFF(s, TLog.DateTime_Start, TLog.DateTime_Finish)) 
                      AS AverageTimeTakenLast30Days
FROM        Template_Log AS TLog 
			INNER JOIN Intelledox_User AS IUser ON TLog.User_ID = IUser.User_ID 
			INNER JOIN Template_Group AS TG ON TG.Template_Group_ID = TLog.Template_Group_ID
			INNER JOIN Template AS T ON TG.Template_Guid = T.Template_Guid
WHERE     (TLog.Completed = 1) AND (TLog.DateTime_Start BETWEEN DATEADD(d, - 30, GETDATE()) AND GETDATE())
GROUP BY IUser.Username, T.Name
ORDER BY IUser.Username, T.Name
GO
CREATE VIEW [dbo].[vwTemplateGroup]
AS
SELECT     TOP 100 PERCENT Template_Group_ID, Name AS TemplateGroup
FROM         Template_Group
ORDER BY Name
GO
CREATE VIEW [dbo].[vwTemplateVersion]
AS
	SELECT	Template_Version.Template_Version, 
			Template_Version.Template_Guid,
			Template_Version.Modified_Date,
			Template_Version.Comment,
			Template.Template_Type_ID,
			Template.LockedByUserGuid,
			Template_Version.IsMajorVersion,
			Intelledox_User.Username,
			CASE (SELECT COUNT(*)
					FROM Template_Group 
					WHERE (Template_Group.Template_Guid = Template_Version.Template_Guid
								AND Template_Group.Template_Version = Template_Version.Template_Version)
							OR (Template_Group.Layout_Guid = Template_Version.Template_Guid
								AND Template_Group.Layout_Version = Template_Version.Template_Version)) 
				WHEN 0
				THEN 0
				ELSE 1
			END AS InUse,
			0 AS Latest
		FROM	Template_Version
			INNER JOIN Template ON Template_Version.Template_Guid = Template.Template_Guid
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template_Version.Modified_By
	UNION ALL
		SELECT	Template.Template_Version, 
				Template.Template_Guid,
				Template.Modified_Date,
				Template.Comment,
				Template.Template_Type_ID,
				Template.LockedByUserGuid,
				Template.IsMajorVersion,
				Intelledox_User.Username,
				CASE (SELECT COUNT(*)
						FROM Template_Group 
						WHERE (Template_Group.Template_Guid = Template.Template_Guid
									AND (Template_Group.Template_Version = Template.Template_Version OR ISNULL(Template_Group.Template_Version, '0') = '0'))
							OR (Template_Group.Layout_Guid = Template.Template_Guid
									AND (Template_Group.Layout_Version = Template.Template_Version OR ISNULL(Template_Group.Layout_Version, '0') = '0')))
					WHEN 0
					THEN 0
					ELSE 1
				END AS InUse,
				1 AS Latest
		FROM	Template
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By;
GO
CREATE VIEW [dbo].[vwTemplateVersionLatest]
AS
	SELECT Template_Version, Template_Guid, Modified_Date, Modified_By, Project_Definition
	FROM	Template
GO
CREATE VIEW [dbo].[vwUser]
AS
SELECT     TOP 100 PERCENT User_ID, Username AS Creator
FROM         Intelledox_User
ORDER BY Username
GO
CREATE VIEW [dbo].[vwUserPermissions]
AS
	SELECT	UserGuid,
			RoleGuid, 
			GroupGuid,
			MAX(CanDesignProjects) as CanDesignProjects, 
			MAX(CanPublishProjects) as CanPublishProjects, 
			MAX(CanManageContent) as CanManageContent, 
			MAX(CanManageUsers) as CanManageUsers, 
			MAX(CanManageGroups) as CanManageGroups, 
			MAX(CanManageSecurity) as CanManageSecurity, 
			MAX(CanManageDataSources) as CanManageDataSources,
			MIN(IsInherited) as IsInherited,
			MAX(CanMaintainLicensing) as CanMaintainLicensing,
			MAX(CanChangeSettings) as CanChangeSettings,
			MAX(CanManageConsole) as CanManageConsole,
			MAX(CanApproveContent) as CanApproveContent,
			MAX(CanManageWorkflowTasks) as CanManageWorkflowTasks
	FROM (
		SELECT User_Role.UserGuid,
			User_Role.RoleGuid,
			User_Role.GroupGuid,
			--Design projects
			CASE WHEN Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' THEN 1 ELSE 0 END AS CanDesignProjects,
			--Publish projects
			CASE WHEN Role_Permission.PermissionGuid = '6B96BAF3-8A76-4F42-B1E7-DF87142444E0' THEN 1 ELSE 0 END AS CanPublishProjects,
			--Manage content
			CASE WHEN Role_Permission.PermissionGuid = 'FA2C7769-6D15-442E-9F7F-E8CE82590D8D' THEN 1 ELSE 0 END AS CanManageContent,
			--Manage users
			CASE WHEN Role_Permission.PermissionGuid = '7D98327C-B4CB-48DC-9FF7-E613C26FA918' THEN 1 ELSE 0 END AS CanManageUsers,
			--Manage groups
			CASE WHEN Role_Permission.PermissionGuid = '33FC4FFE-9108-4D56-9A08-DD128255D87C' THEN 1 ELSE 0 END AS CanManageGroups,
			--Manage security
			CASE WHEN Role_Permission.PermissionGuid = '09B7187E-E432-4B03-BDC9-C7FC2C82B9F1' THEN 1 ELSE 0 END AS CanManageSecurity,
			--Manage data sources
			CASE WHEN Role_Permission.PermissionGuid = 'B0761CDD-BE11-45EE-8133-BF1D6AA65D6D' THEN 1 ELSE 0 END AS CanManageDataSources,
			0 as IsInherited,
			--Maintain Licensing
			CASE WHEN Role_Permission.PermissionGuid = 'BB4F1768-DBC7-46C7-9A52-09159DB15A02' THEN 1 ELSE 0 END AS CanMaintainLicensing,
			--Change Settings
			CASE WHEN Role_Permission.PermissionGuid = 'D0416D36-5C3C-4CB7-8686-74432261A87A' THEN 1 ELSE 0 END AS CanChangeSettings,
			--Management Console
			CASE WHEN Role_Permission.PermissionGuid = '22A89A6C-C131-4DF1-9A4F-50CFC5E69B58' THEN 1 ELSE 0 END AS CanManageConsole,
			--Content Approver
			CASE WHEN Role_Permission.PermissionGuid = 'F9A676FF-93F8-4D15-9F24-B95DD8C01762' THEN 1 ELSE 0 END AS CanApproveContent,
			--Workflow Tasks
			CASE WHEN Role_Permission.PermissionGuid = '73843C3F-21D0-4861-8886-7071E174DA04' THEN 1 ELSE 0 END AS CanManageWorkflowTasks
		FROM	User_Role
				LEFT JOIN Role_Permission ON Role_Permission.RoleGuid = User_Role.RoleGuid
		UNION
		SELECT Intelledox_User.User_Guid as UserGuid,
			Role_Permission.RoleGuid,
			NULL as GroupGuid,
			--Design projects
			CASE WHEN Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' THEN 1 ELSE 0 END AS CanDesignProjects,
			--Publish projects
			CASE WHEN Role_Permission.PermissionGuid = '6B96BAF3-8A76-4F42-B1E7-DF87142444E0' THEN 1 ELSE 0 END AS CanPublishProjects,
			--Manage content
			CASE WHEN Role_Permission.PermissionGuid = 'FA2C7769-6D15-442E-9F7F-E8CE82590D8D' THEN 1 ELSE 0 END AS CanManageContent,
			--Manage users
			CASE WHEN Role_Permission.PermissionGuid = '7D98327C-B4CB-48DC-9FF7-E613C26FA918' THEN 1 ELSE 0 END AS CanManageUsers,
			--Manage groups
			CASE WHEN Role_Permission.PermissionGuid = '33FC4FFE-9108-4D56-9A08-DD128255D87C' THEN 1 ELSE 0 END AS CanManageGroups,
			--Manage security
			CASE WHEN Role_Permission.PermissionGuid = '09B7187E-E432-4B03-BDC9-C7FC2C82B9F1' THEN 1 ELSE 0 END AS CanManageSecurity,
			--Manage data sources
			CASE WHEN Role_Permission.PermissionGuid = 'B0761CDD-BE11-45EE-8133-BF1D6AA65D6D' THEN 1 ELSE 0 END AS CanManageDataSources,
			1 as IsInherited,
			--Maintain Licensing
			CASE WHEN Role_Permission.PermissionGuid = 'BB4F1768-DBC7-46C7-9A52-09159DB15A02' THEN 1 ELSE 0 END AS CanMaintainLicensing,
			--Change Settings
			CASE WHEN Role_Permission.PermissionGuid = 'D0416D36-5C3C-4CB7-8686-74432261A87A' THEN 1 ELSE 0 END AS CanChangeSettings,
			--Management Console
			CASE WHEN Role_Permission.PermissionGuid = '22A89A6C-C131-4DF1-9A4F-50CFC5E69B58' THEN 1 ELSE 0 END AS CanManageConsole,
			--Content Approver
			CASE WHEN Role_Permission.PermissionGuid = 'F9A676FF-93F8-4D15-9F24-B95DD8C01762' THEN 1 ELSE 0 END AS CanApproveContent,
			--Workflow Tasks
			CASE WHEN Role_Permission.PermissionGuid = '73843C3F-21D0-4861-8886-7071E174DA04' THEN 1 ELSE 0 END AS CanManageWorkflowTasks
		FROM	Role_Permission
				INNER JOIN User_Group_Role ON Role_Permission.RoleGuid = User_Group_Role.RoleGuid
				INNER JOIN User_Group ON User_Group_Role.GroupGuid = User_Group.Group_Guid
				INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
				INNER JOIN Intelledox_User ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
		) PermissionCombination
		GROUP BY UserGuid, RoleGuid, GroupGuid
GO
CREATE NONCLUSTERED INDEX [FK_WorkflowState_ActionListGuid] ON [dbo].[ActionListState]
(
	[ActionListId] ASC
)
GO
CREATE NONCLUSTERED INDEX [FK_WorkflowState_AssignedGuid] ON [dbo].[ActionListState]
(
	[AssignedGuid] ASC
)
GO
CREATE NONCLUSTERED INDEX [IX_Answer_File_AnswerFileId] ON [dbo].[Answer_File]
(
	[AnswerFile_ID] ASC
)
GO
CREATE UNIQUE NONCLUSTERED INDEX [ixContentDefinition_NameIdentity] ON [dbo].[Content_Definition]
(
	[NameIdentity] ASC
)
GO
CREATE NONCLUSTERED INDEX [IX_Content_Item_BusinessUnit] ON [dbo].[Content_Item]
(
	[Business_Unit_GUID] ASC
)
GO
CREATE NONCLUSTERED INDEX [IX_Content_Item_ExpiryDate] ON [dbo].[Content_Item]
(
	[ExpiryDate] ASC
)
GO
CREATE UNIQUE NONCLUSTERED INDEX [ixContentItem_NameIdentityBU] ON [dbo].[Content_Item]
(
	[NameIdentity] ASC,
	[Business_Unit_GUID] ASC
)
GO
CREATE NONCLUSTERED INDEX [IX_Data_Object_ServiceGuid] ON [dbo].[Data_Object]
(
	[Data_Service_Guid] ASC
)
GO
CREATE NONCLUSTERED INDEX [IX_Data_Service_BusinessUnitGuid] ON [dbo].[Data_Service]
(
	[Business_Unit_Guid] ASC
)
GO
CREATE NONCLUSTERED INDEX [IX_Intelledox_User_BU] ON [dbo].[Intelledox_User]
(
	[Business_Unit_GUID] ASC
)
GO
CREATE NONCLUSTERED INDEX [IX_Intelledox_User_Username] ON [dbo].[Intelledox_User]
(
	[Username] ASC
)
GO
CREATE NONCLUSTERED INDEX [IX_PurchaseTransaction_BU] ON [dbo].[PurchaseTransaction]
(
	[Business_Unit_Guid] ASC
)
GO
CREATE NONCLUSTERED INDEX [IX_Template_Guid] ON [dbo].[Template]
(
	[Template_Guid] ASC
)
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_TemplateFileId] ON [dbo].[Template_File]
(
	[TemplateFileId] ASC
)
GO
CREATE NONCLUSTERED INDEX [IX_Template_Group_Template_Group_ID] ON [dbo].[Template_Group]
(
	[Template_Group_ID] ASC
)
GO
CREATE NONCLUSTERED INDEX [IX_Template_Log_TemplateGroup] ON [dbo].[Template_Log]
(
	[Template_Group_ID] ASC
)
GO
CREATE NONCLUSTERED INDEX [IX_Template_Log_UserId] ON [dbo].[Template_Log]
(
	[User_ID] ASC,
	[DateTime_Start] ASC,
	[InProgress] ASC
)
GO
ALTER TABLE [dbo].[ActionListState] ADD  CONSTRAINT [DF__ActionLis__IsCom__75586032]  DEFAULT ((0)) FOR [IsComplete]
GO
ALTER TABLE [dbo].[ActionListState] ADD  CONSTRAINT [DF_ActionListState_AllowReassign]  DEFAULT ((0)) FOR [AllowReassign]
GO
ALTER TABLE [dbo].[Answer_File] ADD  CONSTRAINT [DF_Answer_File_InProgress]  DEFAULT ((0)) FOR [InProgress]
GO
ALTER TABLE [dbo].[Bookmark_Group_Log] ADD  CONSTRAINT [DF_Bookmark_Group_Log_Bookmark_Group_Log_Guid]  DEFAULT (newid()) FOR [Bookmark_Group_Log_Guid]
GO
ALTER TABLE [dbo].[Content_Definition] ADD  CONSTRAINT [DF_Content_Definition_ContentDefinition_Id]  DEFAULT (newid()) FOR [ContentDefinition_Guid]
GO
ALTER TABLE [dbo].[Content_Definition_Item] ADD  CONSTRAINT [DF_ContentDefinition_Item_SortIndex]  DEFAULT ((0)) FOR [SortIndex]
GO
ALTER TABLE [dbo].[Content_Item] ADD  CONSTRAINT [DF_Table_1_Content_Id]  DEFAULT (newid()) FOR [ContentItem_Guid]
GO
ALTER TABLE [dbo].[Content_Item] ADD  CONSTRAINT [DF_Content_Item_SizeScale]  DEFAULT ((0)) FOR [SizeScale]
GO
ALTER TABLE [dbo].[Content_Item_Placeholder] ADD  CONSTRAINT [DF__Content_I__TypeI__74643BF9]  DEFAULT ((0)) FOR [TypeId]
GO
ALTER TABLE [dbo].[ContentData_Binary] ADD  CONSTRAINT [DF_Content_Binary_ContentBinary_Id]  DEFAULT (newid()) FOR [ContentData_Guid]
GO
ALTER TABLE [dbo].[ContentData_Text] ADD  CONSTRAINT [DF_ContentData_Text_ContentData_Id]  DEFAULT (newid()) FOR [ContentData_Guid]
GO
ALTER TABLE [dbo].[Document] ADD  CONSTRAINT [DF_Document_Downloadable]  DEFAULT ((0)) FOR [Downloadable]
GO
ALTER TABLE [dbo].[Document] ADD  CONSTRAINT [DF_Document_ActionOnly]  DEFAULT ((0)) FOR [ActionOnly]
GO
ALTER TABLE [dbo].[Group_Output] ADD  CONSTRAINT [DF_Group_Output_EmbedFullFonts]  DEFAULT ((0)) FOR [EmbedFullFonts]
GO
ALTER TABLE [dbo].[License_Key] ADD  CONSTRAINT [DF_License_Key_IsProductKey]  DEFAULT ((0)) FOR [IsProductKey]
GO
ALTER TABLE [dbo].[Routing_ElementType] ADD  CONSTRAINT [DF_Routing_ElementType_Required2]  DEFAULT ((0)) FOR [Required]
GO
ALTER TABLE [dbo].[Routing_Type] ADD  CONSTRAINT [DF__Routing_T__RunFo__727BF387]  DEFAULT ((0)) FOR [RunForAllProjects]
GO
ALTER TABLE [dbo].[Template] ADD  CONSTRAINT [DF__Template__IsMajo__03A67F89]  DEFAULT ((0)) FOR [IsMajorVersion]
GO
ALTER TABLE [dbo].[Template] ADD  CONSTRAINT [DF__Template__Featur__058EC7FB]  DEFAULT ((0)) FOR [FeatureFlags]
GO
ALTER TABLE [dbo].[Template_File] ADD  CONSTRAINT [DF_Template_File_TemplateFileId]  DEFAULT (newid()) FOR [TemplateFileId]
GO
ALTER TABLE [dbo].[Template_Group] ADD  CONSTRAINT [DF_Template_Group_AllowPreview]  DEFAULT ((0)) FOR [AllowPreview]
GO
ALTER TABLE [dbo].[Template_Group] ADD  CONSTRAINT [DF_Template_Group_UpdateDocumentFields]  DEFAULT ((0)) FOR [UpdateDocumentFields]
GO
ALTER TABLE [dbo].[Template_Group] ADD  CONSTRAINT [DF_Template_Group_EnforceValidation]  DEFAULT ((0)) FOR [EnforceValidation]
GO
ALTER TABLE [dbo].[Template_Group] ADD  CONSTRAINT [DF_Template_Group_EnforcePublishPeriod]  DEFAULT ((0)) FOR [EnforcePublishPeriod]
GO
ALTER TABLE [dbo].[Template_Group] ADD  CONSTRAINT [DF_Template_Group_HideNavigationPane]  DEFAULT ((0)) FOR [HideNavigationPane]
GO
ALTER TABLE [dbo].[Template_Log] ADD  CONSTRAINT [DF_Template_Log_Log_Guid]  DEFAULT (newid()) FOR [Log_Guid]
GO
ALTER TABLE [dbo].[Template_Styles] ADD  CONSTRAINT [DF_Template_Styles_TemplateStyleGuid]  DEFAULT (newid()) FOR [TemplateStyleGuid]
GO
ALTER TABLE [dbo].[Template_Version] ADD  CONSTRAINT [DF__Template___IsMaj__049AA3C2]  DEFAULT ((0)) FOR [IsMajorVersion]
GO
ALTER TABLE [dbo].[Template_Version] ADD  CONSTRAINT [DF__Template___Featu__0682EC34]  DEFAULT ((0)) FOR [FeatureFlags]
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
	CREATE FULLTEXT INDEX ON dbo.ContentData_Binary(ContentData TYPE COLUMN FileType) 
	   KEY INDEX PK_Content_Binary;
end
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
	CREATE FULLTEXT INDEX ON dbo.ContentData_Text(ContentData) 
	   KEY INDEX PK_ContentData_Text;
end
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
	CREATE FULLTEXT INDEX ON dbo.Template_File([Binary] TYPE COLUMN FormatTypeId) 
	KEY INDEX IX_TemplateFileId;
end
GO
CREATE procedure [dbo].[spAddBk_AddressList]
    @AddressID int = 0,
    @ErrorCode int = 0 output
AS
    SELECT *
    FROM Address_Book
    WHERE (@AddressID = 0
        OR @AddressID IS NULL
        OR Address_ID = @AddressID);

    set @errorcode = @@error;
GO
create procedure [dbo].[spAddBk_AddressTypeList]
	@AddressTypeID int,
	@ErrorCode int = 0 output
AS
	SELECT *
	FROM Address_Type
	WHERE @AddressTypeID = 0
	OR @AddressTypeID IS NULL
	OR Address_Type_ID = @AddressTypeID
	
	set @errorcode = @@error	
GO
create procedure [dbo].[spAddBk_RemoveAddress]
	@AddressID int,
	@ErrorCode int = 0 output
AS
	DELETE Address_Book
	WHERE Address_ID = @AddressID
	
	DELETE user_address_book
	WHERE address_id = @AddressID
	
	set @errorcode = @@error
GO
create procedure [dbo].[spAddBk_RemoveAddressType]
	@AddressTypeID int,
	@ErrorCode int = 0 output
AS
	DELETE Address_Type
	WHERE Address_Type_ID = @AddressTypeID
	
	set @errorcode = @@error
GO
create procedure [dbo].[spAddBk_SubscribeUserAddress]
	@UserID int,
	@AddressID int,
	@ErrorCode int = 0 output
AS
	--Check if address is already subscribed before subscribing it
	if (SELECT COUNT(*) FROM User_Address_Book WHERE [User_ID] = @UserID AND Address_ID = @AddressID) = 0
		INSERT INTO User_Address_Book ([user_id], address_id)
		VALUES (@UserID, @AddressID)

	set @errorcode = @@error
GO
CREATE procedure [dbo].[spAddBk_UpdateAddress]
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
        INSERT INTO Address_Book (addresstype_id, address_reference,
            prefix, first_name, last_name, full_name, salutation_name, title,
            organisation_name, phone_number, fax_number, email_address,
            street_address_1, street_address_2, street_address_suburb, street_address_state,
            street_address_postcode, street_address_country, postal_address_1, postal_address_2,
            postal_address_suburb, postal_address_state, postal_address_postcode, postal_address_country)
        VALUES (@AddressTypeID, @Reference,
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
            Postal_Address_Postcode = @PostalPostcode, Postal_Address_Country = @PostalCountry
        WHERE Address_ID = @AddressID;
    end
        
    IF (@SubscribeUser > 0) AND (@SubscribeUser IS NOT NULL)
        exec spAddBk_SubscribeUserAddress @SubscribeUser, @AddressID, @ErrorCode output;

    set @errorcode = @@error;

GO
create procedure [dbo].[spAddBk_UpdateAddressType]
	@AddressTypeID int = 0,
	@Name nvarchar(50),
	@NewID int = 0 output,
	@ErrorCode int = 0 output
AS
	IF (@AddressTypeID = 0) OR (@AddressTypeID IS NULL)
	begin
		INSERT INTO Address_Type ([Name])
		VALUES (@Name)

		SELECT @NewID = @@identity
	end
	ELSE
	begin
		UPDATE Address_Type
		SET [Name] = @Name
		WHERE Address_Type_ID = @AddressTypeID
	end
	
	set @errorcode = @@error	
GO
CREATE procedure [dbo].[spAddBk_UserAddress]
    @UserID int,
    @ErrorCode int = 0 output
AS
    SELECT	Address_Book.*
    FROM	Address_Book
            INNER JOIN Intelledox_User u ON Address_Book.Address_Id = u.Address_Id
    WHERE	u.[User_ID] = @UserID;

    set @ErrorCode = @@error;
GO
CREATE procedure [dbo].[spAddBk_UserAddressList]
    @UserID int,
    @ErrorCode int = 0 output
AS
    SELECT	a.*
    FROM	Address_Book a,
            User_Address_Book b
    WHERE	b.[User_ID] = @UserID
            AND	a.Address_ID = b.Address_ID
    order by a.Last_Name, a.First_Name, a.Prefix, a.Organisation_Name;

    set @errorcode = @@error;
GO
CREATE procedure [dbo].[spAddBk_UserGroupAddress]
    @UserGroupID int,
    @ErrorCode int = 0 output
AS
    SELECT	Address_Book.*
    FROM	Address_Book
            INNER JOIN User_Group ug ON Address_Book.Address_Id = ug.Address_Id
    WHERE	ug.User_Group_ID = @UserGroupID;

    set @errorcode = @@error;
GO
CREATE procedure [dbo].[spAudit_AnswerFileList]
	@AnswerFile_ID int = 0,
	@AnswerFile_Guid uniqueidentifier = null,
	@User_Guid uniqueidentifier = null,
	@InProgress bit = 0,
	@TemplateGroupGuid uniqueidentifier = null,
	@ErrorCode int output
AS
	set nocount on
	
	IF (@AnswerFile_Guid IS NOT NULL)
	BEGIN
		SELECT	@AnswerFile_ID = AnswerFile_ID
		FROM	Answer_File
		WHERE	AnswerFile_Guid = @AnswerFile_Guid;
	END

	if @AnswerFile_ID = 0 or @AnswerFile_ID is null
    begin
		if @TemplateGroupGuid is null
			select	ans.AnswerFile_Id, ans.User_Guid, ans.Template_Group_Guid, ans.Description, 
					ans.RunDate, ans.InProgress, ans.AnswerFile_Guid,
					Template.Name as TemplateGroup_Name, Template_Group.Template_Group_Guid
			from	answer_file ans
					inner join Template_Group on ans.Template_Group_Guid = Template_Group.Template_Group_Guid
					inner join Template on Template_Group.Template_Guid = Template.Template_Guid
			where	Ans.[User_Guid] = @user_Guid
					AND Ans.[InProgress] = @InProgress
					AND Ans.template_group_Guid in (

				-- Get a union of template group.
				SELECT DISTINCT tg.Template_Group_Guid
				FROM Folder f
					left join (
						SELECT tg.Template_Group_ID, tg.Folder_Guid, tg.Template_Group_Guid, tg.Template_Guid
						FROM template_group tg 
						WHERE (tg.EnforcePublishPeriod = 0 
								OR ((tg.PublishStartDate IS NULL OR tg.PublishStartDate < getdate())
									AND (tg.PublishFinishDate IS NULL OR tg.PublishFinishDate > getdate())))
					) tg on f.Folder_Guid = tg.Folder_Guid
					left join template t on tg.Template_Guid = t.Template_Guid
					inner join folder_group fg on F.Folder_Guid = fg.FolderGuid
				where 	(fg.GroupGuid in
							(select b.Group_Guid
							from intelledox_user a
							left join User_Group_Subscription c on a.User_Guid = c.UserGuid
							left join user_group b on c.groupguid = b.group_guid
							where c.UserGuid = @user_guid)
						)
			)
			order by [RunDate] desc;
		else
			select	ans.AnswerFile_Id, ans.User_Guid, ans.Template_Group_Guid, ans.Description, 
					ans.RunDate, ans.InProgress, ans.AnswerFile_Guid,
					Template_Group.Name as TemplateGroup_Name
			from	answer_file ans					
					INNER JOIN Template_Group on ans.Template_Group_Guid = Template_Group.Template_Group_Guid
					INNER JOIN Template AS T ON Template_Group.Template_Guid = T.Template_Guid
			where	Ans.[user_Guid] = @user_Guid
					AND Ans.Template_group_Guid = @TemplateGroupGuid
			order by [RunDate] desc;
    end
    else
    begin
        SELECT	Answer_File.*
		FROM	Answer_File
        WHERE	Answer_File.AnswerFile_Id = @AnswerFile_Id
        ORDER BY Answer_File.[RunDate] desc;
    end
GO
CREATE procedure [dbo].[spAudit_InsertTransaction]
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
CREATE procedure [dbo].[spAudit_RemoveAnswerFile]
	@AnswerFile_Guid uniqueidentifier
AS
	set nocount on

	delete Answer_File
	where AnswerFile_Guid = @AnswerFile_Guid;
GO
CREATE PROCEDURE [dbo].[spAudit_TransactionLineItemList] (
	@SupplierGuid uniqueidentifier,
	@Unclaimed bit,
	@ErrorCode int output
)
AS
	SELECT	PurchaseLineItem.*
	FROM	PurchaseLineItem
	WHERE	Supplier_Guid = @SupplierGuid
			AND (Claimed IS NULL OR @Unclaimed = 0)

	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spAudit_TransactionList]
	@BusinessUnitGuid uniqueidentifier,
	@RangeFrom datetime,
	@RangeTo datetime,
	@ErrorCode int output
as
	SELECT	*
	FROM	PurchaseTransaction
	WHERE	Business_Unit_Guid = @BusinessUnitGuid
			AND (Transaction_Date >= @RangeFrom or @RangeFrom IS NULL)
			AND (Transaction_Date <= @RangeTo + 1 or @RangeTo IS NULL)
	ORDER BY Transaction_ID
	
	set @ErrorCode = @@error	
GO
CREATE procedure [dbo].[spAudit_UpdateAnswerFile]
	@AnswerFile_ID int,
	@AnswerFile_Guid uniqueidentifier,
	@User_Guid uniqueidentifier,
	@Template_Group_Guid uniqueidentifier,
	@Description nvarchar(255),
	@RunDate datetime,
	@AnswerString xml,
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
			AnswerString = @AnswerString
		where AnswerFile_ID = @AnswerFile_ID;
	end
	else
	begin
		insert into Answer_File (AnswerFile_Guid, [User_Guid], [Template_Group_Guid], [Description], [RunDate], [AnswerString], [InProgress])
		values (@AnswerFile_Guid, @User_Guid, @Template_Group_Guid, @Description, @RunDate, @AnswerString, @InProgress);

		select @NewID = @@Identity;
	end

	set @ErrorCode = @@Error;
GO
CREATE PROCEDURE [dbo].[spAudit_UpdateSiteEvent]
	@DateTime DateTime,
	@Message nvarchar(max),
	@LevelID Int
AS
	INSERT INTO EventLog (DateTime, Message, LevelID)
	VALUES (@DateTime, @Message, @LevelID)
GO
CREATE PROCEDURE [dbo].[spAudit_UpdateTransactionLineItem]
	@LineItemID int,
	@TransactionID int,
	@Description nvarchar(300),
	@ItemGuid uniqueidentifier,
	@SupplierGuid uniqueidentifier,
	@Price money,
	@Claimed datetime,
	@NewID int output,
	@ErrorCode int output
AS
	IF @LineItemID = 0 OR @LineItemID IS NULL
	BEGIN
		INSERT INTO PurchaseLineItem(Transaction_ID, Description, Item_Guid, Supplier_Guid, Price, Claimed)
		VALUES (@TransactionID, @Description, @ItemGuid, @SupplierGuid, @Price, @Claimed)

		SELECT @NewID = @@identity
	END	
	ELSE
	BEGIN		
		UPDATE	PurchaseLineItem
		SET		Claimed = @Claimed
		WHERE	Line_Item_ID = @LineItemID
	END

	SET @ErrorCode = @@error
GO
CREATE procedure [dbo].[spBU_ProvisionTenant] (
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
		
		INSERT INTO User_Group(Name, WinNT_Group, Business_Unit_Guid, Group_Guid, AutoAssignment, SystemGroup)
		SELECT	@TenantName + ' Users', WinNT_Group, @BusinessUnitGuid, @UG, AutoAssignment, SystemGroup
		FROM	User_Group
		WHERE	Name = 'Infiniti Users' and SystemGroup = 1;
	end
	
	--User Address
	INSERT INTO address_book (full_name, first_name, last_name, email_address)
	VALUES (@FirstName + ' ' + @LastName, @FirstName, @LastName, @UserEmail)
	
	--User
	INSERT INTO Intelledox_User(Username, Pwdhash, WinNT_User, Business_Unit_Guid, User_Guid, PwdFormat, PwdSalt, Address_ID)
	VALUES (@UserName, @UserPasswordHash, 0, @BusinessUnitGuid, @UserGuid, 2, @UserPasswordSalt, @@IDENTITY)


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
	declare @GroupGuid uniqueidentifier
			
	select @GroupGuid = Group_Guid from user_group where business_unit_guid = @BusinessUnitGuid;
	
	INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
	values (@UserGuid, @GroupGuid, 1);
GO
CREATE PROCEDURE [dbo].[spConnectorSettings_ElementTypeList] 
	-- Add the parameters for the stored procedure here
	@ConnectorSettingsTypeId uniqueidentifier
AS
BEGIN
	SELECT * 
	FROM ConnectorSettings_ElementType
	WHERE ConnectorSettingsTypeId = @ConnectorSettingsTypeId
	ORDER BY SortOrder, DescriptionDefault
END
GO
CREATE PROCEDURE [dbo].[spConnectorSettings_RegisterElementType]
	@ConnectorSettingsElementTypeId uniqueidentifier,
	@ConnectorSettingsTypeId uniqueidentifier,
	@Description nvarchar(255),
	@Encrypt bit,
	@SortOrder int,
	@ElementValue nvarchar(max) = ''
AS
	IF NOT EXISTS(SELECT * FROM ConnectorSettings_ElementType WHERE ConnectorSettingsElementTypeId = @ConnectorSettingsElementTypeId AND ConnectorSettingsTypeId = @ConnectorSettingsTypeId)
	BEGIN
		INSERT INTO ConnectorSettings_ElementType(ConnectorSettingsElementTypeId,ConnectorSettingsTypeId,DescriptionDefault,Encrypt,SortOrder,ElementValue)
		VALUES (@ConnectorSettingsElementTypeId,@ConnectorSettingsTypeId,@Description,@Encrypt,@SortOrder,@ElementValue);
	END
GO
CREATE PROCEDURE [dbo].[spConnectorSettings_RegisterSettingsType]
	@Id uniqueidentifier,
	@Description nvarchar(255)
AS
	IF NOT EXISTS(SELECT * FROM  ConnectorSettings_Type WHERE ConnectorSettingsTypeId = @id)
	BEGIN
		INSERT INTO ConnectorSettings_Type(ConnectorSettingsTypeId, ConnectorSettingsDescription)
		VALUES	(@id, @Description);
	END
GO
CREATE PROCEDURE [dbo].[spConnectorSettings_TypeList]
	
AS
BEGIN
	SELECT * 
	FROM ConnectorSettings_Type
	ORDER BY ConnectorSettingsDescription
END
GO
CREATE PROCEDURE [dbo].[spConnectorSettings_UpdateElementTypeValue]
	-- Add the parameters for the stored procedure here
	@ConnectorSettingsElementTypeId uniqueidentifier,
	@ElementValue nvarchar(max)
AS
BEGIN
	UPDATE ConnectorSettings_ElementType
	SET ElementValue = @ElementValue
	WHERE ConnectorSettingsElementTypeId = @ConnectorSettingsElementTypeId
END
GO
CREATE procedure [dbo].[spContent_ContentDefinitionList]
	@ContentDefinitionGuid uniqueidentifier,
	@ExactMatch bit,
	@Name as nvarchar(255),
	@Description as nvarchar(1000),
	@ErrorCode int output
as
	declare @GuidEmpty uniqueidentifier
	set @GuidEmpty = cast('00000000-0000-0000-0000-000000000000' as uniqueidentifier)
	
	IF @ContentDefinitionGuid = @GuidEmpty or @ContentDefinitionGuid is null 
		IF @ExactMatch = 1
			SELECT	*
			FROM	Content_Definition
			WHERE	NameIdentity = @Name
			ORDER BY NameIdentity
		ELSE
			SELECT	*
			FROM	Content_Definition
			WHERE	NameIdentity LIKE @Name + '%'
					AND Description LIKE '%' + @Description + '%'
			ORDER BY NameIdentity
	ELSE
		SELECT	*
		FROM	Content_Definition
		WHERE	ContentDefinition_Guid = @ContentDefinitionGuid
	
	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spContent_ContentFolderList]
	@FolderGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier,
	@UserId uniqueidentifier
AS
	IF @FolderGuid IS NULL
	BEGIN
		SELECT	*
		FROM	Content_Folder
		WHERE	BusinessUnitGuid = @BusinessUnitGuid
		ORDER BY FolderName;
	END
	ELSE
	BEGIN
		SELECT	*
		FROM	Content_Folder
		WHERE	FolderGuid = @FolderGuid;
	END
GO
CREATE procedure [dbo].[spContent_ContentItemList]
    @ItemGuid uniqueidentifier,
    @BusinessUnitGuid uniqueidentifier,
    @ExactMatch bit,
    @ContentTypeId int,
    @Name NVarChar(255),
    @Description NVarChar(1000),
    @Category int,
    @Approved int = 2,
    @ErrorCode int output,
    @FolderGuid uniqueidentifier,
    @UserId uniqueidentifier,
    @NoFolder bit,
    @MinimalGet bit
as
    IF @ItemGuid is null 
    BEGIN
        UPDATE Content_Item
        SET Approved = 1
        WHERE ExpiryDate < GETUTCDATE();
        
        IF @ExactMatch = 1
            SELECT	ci.*, 
                    Content.FileType, 
                    Content.Modified_Date, 
                    Intelledox_User.UserName,
                    CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
                    CASE WHEN (@UserId IS NULL 
                        OR ci.FolderGuid IS NULL 
                        OR (NOT EXISTS (
                            SELECT * 
                            FROM Content_Folder_Group 
                            WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
                        OR EXISTS (
                            SELECT * 
                            FROM Content_Folder_Group
                                INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
                                INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
                                INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
                            WHERE Intelledox_User.User_Guid = @UserId
                                AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
                    THEN 1 ELSE 0 END
                    AS CanEdit,
                    ci.FolderGuid,
                    Content_Folder.FolderName
                    
            FROM	content_item ci
                    LEFT JOIN (
                        SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
                        FROM	ContentData_Binary
                        UNION
                        SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
                        FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
                    LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
                    LEFT JOIN (
                        SELECT	ContentData_Guid
                        FROM	vwContentItemVersionDetails
                        WHERE	Approved = 0
                        ) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
                    LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
                    
            WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
                    AND ci.NameIdentity = @Name
                    AND (@Approved = -1 
                        OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
                        OR ci.Approved = @Approved)
            ORDER BY ci.NameIdentity;
        ELSE
            SELECT DISTINCT	ci.*, 
                    Content.FileType, 
                    Content.Modified_Date, 
                    Intelledox_User.UserName,
                    CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
                    CASE WHEN (@UserId IS NULL 
                        OR ci.FolderGuid IS NULL 
                        OR (NOT EXISTS (
                            SELECT * 
                            FROM Content_Folder_Group 
                            WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
                        OR EXISTS (
                            SELECT * 
                            FROM Content_Folder_Group
                                INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
                                INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
                                INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
                            WHERE Intelledox_User.User_Guid = @UserId
                                AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
                    THEN 1 ELSE 0 END
                    AS CanEdit,
                    ci.FolderGuid,
                    Content_Folder.FolderName
                    
            FROM	content_item ci
                    LEFT JOIN (
                        SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
                        FROM	ContentData_Binary
                        UNION
                        SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
                        FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
                    LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
                    LEFT JOIN (
                        SELECT	ContentData_Guid
                        FROM	vwContentItemVersionDetails
                        WHERE	Approved = 0
                        ) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
                    LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
                        
            WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
                    AND ci.NameIdentity LIKE '%' + @Name + '%'
                    AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
                    AND ci.Description LIKE '%' + @Description + '%'
                    AND (@Category = 0 or ci.Category = @Category)
                    AND (@Approved = -1 
                        OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
                        OR ci.Approved = @Approved)
                    AND ((@NoFolder = 0 AND (@FolderGuid IS NULL OR ci.FolderGuid = @FolderGuid))
                        OR (@NoFolder = 1 AND ci.FolderGuid IS NULL))
            ORDER BY ci.ContentType_Id,
                    ci.NameIdentity;
    END
    ELSE
    BEGIN
        UPDATE	Content_Item
        SET		Approved = 1
        WHERE	ExpiryDate < GETUTCDATE()
                AND contentitem_guid = @ItemGuid;
        
        IF (@MinimalGet = 1)
        BEGIN
            SELECT	ci.*, 
                    '' as FileType, 
                    NULL as Modified_Date, 
                    '' as UserName,
                    0 as HasUnapprovedRevision,
                    0 as CanEdit,
                    Content_Folder.FolderName						
            FROM	content_item ci
                LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
            WHERE	ci.contentitem_guid = @ItemGuid;
        END
        ELSE
        BEGIN
            SELECT	ci.*, 
                    Content.FileType, 
                    Content.Modified_Date, 
                    Intelledox_User.UserName,
                    CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
                    CASE WHEN (@UserId IS NULL 
                        OR ci.FolderGuid IS NULL 
                        OR (NOT EXISTS (
                            SELECT * 
                            FROM Content_Folder_Group 
                            WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
                        OR EXISTS (
                            SELECT * 
                            FROM Content_Folder_Group
                                INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
                                INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
                                INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
                            WHERE Intelledox_User.User_Guid = @UserId
                                AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
                    THEN 1 ELSE 0 END
                    AS CanEdit,
                    Content_Folder.FolderName
                        
            FROM	content_item ci
                    LEFT JOIN (
                        SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
                        FROM	ContentData_Binary
                        UNION
                        SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
                        FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
                    LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
                    LEFT JOIN (
                        SELECT	ContentData_Guid
                        FROM	vwContentItemVersionDetails
                        WHERE	Approved = 0
                        ) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
                    LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
                        
            WHERE	ci.contentitem_guid = @ItemGuid;
        END
    END
    
    set @ErrorCode = @@error;
GO
CREATE procedure [dbo].[spContent_ContentItemListByDefinition]
	@ContentDefinitionGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier,
	@ErrorCode int output
as
	SELECT	ci.*, cdi.SortIndex, cib.FileType, cib.Modified_Date, Intelledox_User.Username,
			0 as HasUnapprovedRevision, 0 AS CanEdit, Content_Folder.FolderName
	FROM	content_item ci
			INNER JOIN content_definition_item cdi ON ci.ContentItem_Guid = cdi.ContentItem_Guid
				AND cdi.ContentDefinition_Guid = @ContentDefinitionGuid
			LEFT JOIN ContentData_Binary cib ON ci.ContentData_Guid = cib.ContentData_Guid
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = cib.Modified_By
			LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
	WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
	ORDER BY cdi.SortIndex;
	
	set @ErrorCode = @@error;
GO
CREATE procedure [dbo].[spContent_ContentItemListByFolder]
    @FolderGuid uniqueidentifier,
    @UserId uniqueidentifier
as
    SELECT	Content_Item.*, 
        ContentData_Binary.FileType, 
        ContentData_Binary.Modified_Date, 
        Intelledox_User.Username,
        0 As HasUnapprovedRevision,
        CASE WHEN (@UserId IS NULL 
            OR Content_Item.FolderGuid IS NULL 
            OR (NOT EXISTS (
                SELECT * 
                FROM Content_Folder_Group 
                WHERE Content_Item.FolderGuid = Content_Folder_Group.FolderGuid))
            OR EXISTS (
                SELECT * 
                FROM Content_Folder_Group
                    INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
                    INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
                    INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
                WHERE Intelledox_User.User_Guid = @UserId
                    AND Content_Item.FolderGuid = Content_Folder_Group.FolderGuid))
        THEN 1 ELSE 0 END
        AS CanEdit
    FROM	Content_Item
        LEFT JOIN ContentData_Binary ON Content_Item.ContentData_Guid = ContentData_Binary.ContentData_Guid
        LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = ContentData_Binary.Modified_By
    WHERE	FolderGuid = @FolderGuid
        OR (FolderGuid IS NULL AND @FolderGuid IS NULL)
    ORDER BY Content_Item.ContentType_Id,
        Content_Item.NameIdentity
GO
CREATE procedure [dbo].[spContent_ContentItemListBySearch]
	@BusinessUnitGuid uniqueidentifier,
	@SearchString NVarChar(1000),
	@ContentTypeId Int,
	@FolderGuid uniqueidentifier
	
AS
	SELECT	ci.*, 
			Content.FileType, 
			Content.Modified_Date, 
			Intelledox_User.UserName,
			0 as HasUnapprovedRevision,
			0 AS CanEdit,
			Content_Folder.FolderName
	FROM	content_item ci
			LEFT JOIN (
				SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
				FROM	ContentData_Binary
				UNION
				SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
				FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
			LEFT JOIN Category ON ci.Category = Category.Category_ID
			LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
	WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
			AND ci.Approved = 2
			AND ci.ContentType_Id = @ContentTypeId
			AND (ci.NameIdentity LIKE '%' + @SearchString + '%'
				OR ci.Description LIKE '%' + @SearchString + '%'
				OR Category.Name LIKE '%' + @SearchString + '%'
				)
				--Search all folders/none folder/specific folder
			AND (
				@FolderGuid = '00000000-0000-0000-0000-000000000000' --all
				OR @FolderGuid = '99999999-9999-9999-9999-999999999999'  AND ci.FolderGuid IS NULL --none
				OR ci.FolderGuid = @FolderGuid --a specific folder
				)
						
	ORDER BY ci.NameIdentity;
GO
CREATE PROCEDURE [dbo].[spContent_ContentItemPlaceholderList]
	@ContentItemGuid uniqueidentifier
AS
	SET NOCOUNT ON;
	
	SELECT	*
	FROM	Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItemGuid;
	
	IF @@RowCount = 0
	BEGIN
		IF EXISTS(SELECT * FROM Content_Item WHERE ContentItem_Guid = @ContentItemGuid AND IsIndexed = 1)
			RETURN 1;
		ELSE
			RETURN 0;
	END
	ELSE
	BEGIN
		RETURN 1;
	END
GO
CREATE procedure [dbo].[spContent_FolderGroupList]
	@FolderGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	SELECT	*
	FROM	Content_Folder_Group
	WHERE	FolderGuid = @FolderGuid

	set @errorcode = @@error
GO
CREATE procedure [dbo].[spContent_IsFullTextEnabled]
AS
	SELECT IsNull(INDEXPROPERTY( OBJECT_ID('dbo.ContentData_Binary'), 'PK_Content_Binary',  'IsFulltextKey' ), 0);

GO
CREATE procedure [dbo].[spContent_RemoveContentDefinition]
	@ContentDefinitionGuid uniqueidentifier
as
	DELETE Content_Definition_Item WHERE contentdefinition_guid = @ContentDefinitionGuid
	DELETE content_definition WHERE contentdefinition_guid = @ContentDefinitionGuid
GO
CREATE procedure [dbo].[spContent_RemoveContentDefinitionItems]
	@ContentDefinitionGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier
AS
	DELETE FROM Content_Definition_Item
	WHERE ContentDefinition_Guid = @ContentDefinitionGuid
		AND ContentItem_Guid IN (
			SELECT	ContentItem_Guid
			FROM	Content_Item
			WHERE	Business_Unit_Guid = @BusinessUnitGuid
		)
GO
CREATE procedure [dbo].[spContent_RemoveContentFolder]
	@FolderGuid uniqueidentifier
AS

	DELETE Content_Folder
	WHERE FolderGuid = @FolderGuid;
	
	DELETE Content_Folder_Group
	WHERE FolderGuid = @FolderGuid;
	
	UPDATE Content_Item
	SET FolderGuid = NULL
	WHERE FolderGuid = @FolderGuid;
GO
CREATE procedure [dbo].[spContent_RemoveContentItem]
	@ContentItemGuid uniqueidentifier
AS
	DECLARE @ContentDataGuid uniqueidentifier;
	
	SET		@ContentDataGuid = (SELECT ContentData_Guid FROM Content_Item WHERE ContentItem_Guid = @ContentItemGuid);

	DELETE	Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItemGuid;
	
	DELETE	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;
	
	DELETE	ContentData_Binary
	WHERE	ContentData_Guid = @ContentDataGuid;
	
	DELETE	ContentData_Binary_Version
	WHERE	ContentData_Guid = @ContentDataGuid;

	DELETE	ContentData_Text
	WHERE	ContentData_Guid = @ContentDataGuid;
	
	DELETE	ContentData_Text_Version
	WHERE	ContentData_Guid = @ContentDataGuid;

GO
CREATE procedure [dbo].[spContent_RemoveFolderGroup]
	@FolderGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	DELETE FROM Content_Folder_Group
	WHERE	FolderGuid = @FolderGuid
			AND GroupGuid = @GroupGuid
	
	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spContent_UpdateContentDefinition]
	@ContentDefinitionGuid uniqueidentifier,
	@Description nvarchar(1000),
	@Name nvarchar(255)
as
	IF NOT EXISTS(SELECT * FROM Content_Definition WHERE ContentDefinition_Guid = @ContentDefinitionGuid)
	begin
		INSERT INTO Content_Definition (ContentDefinition_Guid, Description, NameIdentity)
		VALUES (@ContentDefinitionGuid, @Description, @Name)
	end
	ELSE
		UPDATE Content_Definition
		SET NameIdentity = @Name,
			Description = @Description
		WHERE ContentDefinition_Guid = @ContentDefinitionGuid
GO
CREATE procedure [dbo].[spContent_UpdateContentDefinitionItem]
	@ContentDefinitionGuid uniqueidentifier,
	@ContentItemGuid uniqueidentifier,
	@SortIndex int
as
	INSERT INTO Content_Definition_Item (ContentDefinition_Guid, ContentItem_Guid, SortIndex)
	VALUES (@ContentDefinitionGuid, @ContentItemGuid, @SortIndex)
GO
CREATE procedure [dbo].[spContent_UpdateContentFolder]
	@FolderGuid uniqueidentifier,
	@Name nvarchar(100),
	@BusinessUnitGUID uniqueidentifier
AS
	IF EXISTS(SELECT * FROM Content_Folder WHERE FolderGuid = @FolderGuid)
	BEGIN
		UPDATE	Content_Folder
		SET		FolderName = @Name
		WHERE	FolderGuid = @FolderGuid;
	END
	ELSE
	BEGIN
		INSERT INTO Content_Folder(FolderName, BusinessUnitGuid, FolderGuid)
		VALUES (@Name, @BusinessUnitGUID, @FolderGuid)
	END
GO
CREATE procedure [dbo].[spContent_UpdateContentItem]
	@ContentItemGuid uniqueidentifier,
	@Description nvarchar(1000),
	@Name nvarchar(255),
	@ContentTypeId Int,
	@BusinessUnitGuid uniqueidentifier,
	@ContentDataGuid uniqueidentifier,
	@SizeScale int,
	@Category int,
	@ProviderName nvarchar(50),
	@ReferenceId nvarchar(255),
	@IsIndexed bit,
	@FolderGuid uniqueidentifier
as
	DECLARE @Approvals nvarchar(10)
	DECLARE @CheckedFolderGuid uniqueidentifier
	
	SELECT @CheckedFolderGuid = FolderGuid
	FROM Content_Folder
	WHERE FolderGuid = @FolderGuid
	
	IF NOT EXISTS(SELECT * FROM Content_Item WHERE ContentItem_Guid = @ContentItemGuid)
	begin
		SELECT	@Approvals = OptionValue
		FROM	Global_Options
		WHERE	OptionCode = 'REQUIRE_CONTENT_APPROVAL';
		
		INSERT INTO Content_Item (ContentItem_Guid, [Description], NameIdentity, ContentType_Id, Business_Unit_Guid, ContentData_Guid, SizeScale, Category, Provider_Name, Reference_Id, IsIndexed, Approved, FolderGuid)
		VALUES (@ContentItemGuid, @Description, @Name, @ContentTypeId, @BusinessUnitGuid, @ContentDataGuid, @SizeScale, @Category, @ProviderName, @ReferenceId, 0, CASE WHEN @Approvals = 'true' THEN 0 ELSE 2 END, @CheckedFolderGuid);
	end
	ELSE
		UPDATE Content_Item
		SET NameIdentity = @Name,
			[Description] = @Description,
			SizeScale = @SizeScale,
			ContentData_Guid = @ContentDataGuid,
			Category = @Category,
			Provider_Name = @ProviderName,
			Reference_Id = @ReferenceId,
			IsIndexed = @IsIndexed,
			FolderGuid = @CheckedFolderGuid
		WHERE ContentItem_Guid = @ContentItemGuid;
GO
CREATE procedure [dbo].[spContent_UpdateFolderGroup]
	@FolderGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	INSERT INTO Content_Folder_Group (FolderGuid, GroupGuid)
	VALUES (@FolderGuid, @GroupGuid)
	
	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spContent_UpdatePlaceholder]
	@ContentItemGuid uniqueidentifier,
	@Placeholder nvarchar(100),
	@TypeId int
AS
	INSERT INTO Content_Item_Placeholder(ContentItemGuid, PlaceholderName, TypeId)
	VALUES (@ContentItemGuid, @Placeholder, @TypeId);
GO
CREATE procedure [dbo].[spContent_UserHasAccess]
    @FolderGuid uniqueidentifier,
    @UserId uniqueidentifier
as
    SELECT	
        CASE WHEN (@FolderGuid IS NULL 
            OR (NOT EXISTS (
                SELECT * 
                FROM Content_Folder_Group 
                WHERE @FolderGuid = Content_Folder_Group.FolderGuid))
            OR EXISTS (
                SELECT * 
                FROM Content_Folder_Group
                    INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
                    INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
                    INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
                WHERE Intelledox_User.User_Guid = @UserId
                    AND @FolderGuid = Content_Folder_Group.FolderGuid))
        THEN 1 ELSE 0 END
        AS HasAccess
    FROM	Content_Folder
    WHERE	FolderGuid = @FolderGuid OR @FolderGuid IS NULL
GO
CREATE procedure [dbo].[spCustomField_AddressBookCustomFieldList]
	@AddressBookCustomFieldID int = 0,
	@AddressID int = 0,
	@ErrorCode int = 0 output
AS
	IF (@AddressID = 0 OR @AddressID IS NULL)
		SELECT	Address_Book_Custom_Field.*, Custom_Field.Validation_Type
		FROM	Address_Book_Custom_Field
				INNER JOIN Custom_Field ON Address_Book_Custom_Field.Custom_Field_Id = Custom_Field.Custom_Field_Id
		WHERE	@AddressBookCustomFieldID IS NULL
				OR Address_Book_Custom_Field_ID = @AddressBookCustomFieldID;
	ELSE
		SELECT	Address_Book_Custom_Field.*, Custom_Field.Validation_Type
		FROM	Address_Book_Custom_Field
				INNER JOIN Custom_Field ON Address_Book_Custom_Field.Custom_Field_Id = Custom_Field.Custom_Field_Id
		WHERE	Address_ID = @AddressID;
	
	set @errorcode = @@error;
GO
CREATE procedure [dbo].[spCustomField_CustomFieldList]
	@CustomFieldID int = 0,
	@Location int = 0,
	@ErrorCode int = 0 output
AS
	SELECT *
	FROM Custom_Field
	WHERE (@CustomFieldID IS NULL OR @CustomFieldID = 0	OR Custom_Field_ID = @CustomFieldID)
		AND (@Location = 0 OR Location = @Location)
	ORDER BY Title
	
	set @errorcode = @@error	
GO
CREATE procedure [dbo].[spCustomField_RemoveAddressBookCustomField]
	@AddressBookCustomFieldID int,
	@ErrorCode int = 0 output
AS
	DELETE Address_Book_Custom_Field
	WHERE Address_Book_Custom_Field_ID = @AddressBookCustomFieldID
	
	set @errorcode = @@error
GO
CREATE procedure [dbo].[spCustomField_RemoveCustomField]
	@CustomFieldID int,
	@ErrorCode int = 0 output
AS
	DELETE Custom_Field
	WHERE Custom_Field_ID = @CustomFieldID
	
	set @errorcode = @@error
GO
CREATE procedure [dbo].[spCustomField_UpdateAddressBookCustomField]
	@AddressBookCustomFieldID int = 0,
	@AddressID int,
	@CustomFieldID int,
	@CustomValue nvarchar(4000),
	@NewID int = 0 output,
	@ErrorCode int = 0 output
AS
	IF (@AddressBookCustomFieldID IS NULL OR @AddressBookCustomFieldID = 0)
	begin
		INSERT INTO Address_Book_Custom_Field (Address_ID, Custom_Field_ID, Custom_Value)
		VALUES (@AddressID, @CustomFieldID, @CustomValue)

		SET @NewID = @@IDENTITY
	end
	ELSE
	begin
		UPDATE Address_Book_Custom_Field
		SET Custom_Value = @CustomValue
		WHERE Address_Book_Custom_Field_ID = @AddressBookCustomFieldID
	end
	
	set @errorcode = @@error	
GO
CREATE procedure [dbo].[spCustomField_UpdateCustomField]
	@CustomFieldID int = 0,
	@Title nvarchar(100),
	@ValidationType int,
	@FieldLength int,
	@Location int,
	@NewID int = 0 output,
	@ErrorCode int = 0 output
AS
	IF (@CustomFieldID IS NULL OR @CustomFieldID = 0)
	begin
		INSERT INTO Custom_Field (Title, Validation_Type, Field_Length, Location)
		VALUES (@Title, @ValidationType, @FieldLength, @Location)
	end
	ELSE
	begin
		UPDATE Custom_Field
		SET Title = @Title,
			Validation_Type = @ValidationType,
			Field_Length = @FieldLength,
			Location = @Location
		WHERE Custom_Field_ID = @CustomFieldID
	end
	
	set @errorcode = @@error	
GO
create procedure [dbo].[spData_DataKeyList]
	@DataServiceID int,
	@ErrorCode int output
as
	SELECT
		d.data_service_id, d.[name], d.connection_string,
		ob.data_object_id, ob.[object_name], ob.merge_source,
		dk.data_object_key_id, dk.field_name AS keyfield_name, dk.data_type, dk.required, dk.display_name
	FROM
		data_service d
		LEFT JOIN data_object ob ON d.data_service_id = ob.data_service_id
		LEFT JOIN data_object_key dk ON dk.data_object_id = ob.data_object_id
	WHERE
		d.data_service_id = @DataServiceID
	ORDER BY
		d.data_service_id, ob.data_object_id, dk.required DESC, dk.data_object_key_id
	
	set @ErrorCode = @@error
GO
create procedure [dbo].[spData_DataObjectListByGuid]
	@DataObjectGuid nvarchar(40),
	@ErrorCode int output
as
	SELECT *
	FROM data_object
	WHERE data_object_guid = @DataObjectGuid

	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spData_DataServiceCredentialList]
	@DataServiceCredentialID int = 0,
	@UserID int = 0,
	@ErrorCode int = 0 output
AS
	IF (@UserID = 0 OR @UserID IS NULL)
		SELECT Data_Service_Credential.*, Data_Service.Name
		FROM	Data_Service_Credential
				INNER JOIN Data_Service ON Data_Service_Credential.Data_Service_ID = Data_Service.Data_Service_ID
		WHERE @DataServiceCredentialID IS NULL
		OR Data_Service_Credential.Data_Service_Credential_ID = @DataServiceCredentialID
	ELSE
		SELECT Data_Service_Credential.*, Data_Service.Name
		FROM	Data_Service_Credential
				INNER JOIN Data_Service ON Data_Service_Credential.Data_Service_ID = Data_Service.Data_Service_ID
		WHERE @UserID IS NULL
		OR Data_Service_Credential.User_ID = @UserID
	
	set @errorcode = @@error
GO
CREATE procedure [dbo].[spData_DataServiceList]
	@DataServiceID int,
	@ErrorCode int output
as
	IF @DataServiceID = 0
		SELECT
			d.data_service_id, d.[name], d.connection_string, d.data_service_guid,
			ob.data_object_id, ob.[object_name], ob.merge_source, ob.data_object_guid,
			dk.data_object_key_id, dk.field_name AS keyfield_name, dk.data_type, dk.required, 
			dk.display_name, d.Allow_WriteBack, d.Requires_Credentials, d.Allow_Connection_Export
		FROM
			data_service d
			LEFT JOIN data_object ob ON d.data_service_id = ob.data_service_id
			LEFT JOIN data_object_key dk ON dk.data_object_id = ob.data_object_id
		ORDER BY
			d.data_service_id, ob.data_object_id, dk.required DESC, dk.data_object_key_id
	ELSE
		SELECT
			d.data_service_id, d.[name], d.connection_string, d.data_service_guid,
			ob.data_object_id, ob.[object_name], ob.merge_source, ob.data_object_guid,
			dk.data_object_key_id, dk.field_name AS keyfield_name, dk.data_type, dk.required, 
			dk.display_name, d.Allow_WriteBack, d.Requires_Credentials, d.Allow_Connection_Export
		FROM
			data_service d
			LEFT JOIN data_object ob ON d.data_service_id = ob.data_service_id
			LEFT JOIN data_object_key dk ON dk.data_object_id = ob.data_object_id
		WHERE
			d.data_service_id = @DataServiceID
		ORDER BY
			d.data_service_id, ob.data_object_id, dk.required DESC, dk.data_object_key_id

	set @ErrorCode = @@error
GO
create procedure [dbo].[spData_RemoveDataKey]
	@DataObjectKeyID int = 0,
	@DataObjectID int,
	@ErrorCode int output
as
	IF @DataObjectKeyID = 0 OR @DataObjectKeyID IS NULL
		DELETE data_object_key WHERE data_object_id = @DataObjectID
	ELSE
		DELETE data_object_key WHERE data_object_key_id = @DataObjectKeyID
	
	set @ErrorCode = @@error
GO
create procedure [dbo].[spData_RemoveDataObject]
	@DataObjectID int = 0,
	@DataServiceID int,
	@ErrorCode int output
AS
	IF @DataObjectID = 0 OR @DataObjectID IS NULL
	BEGIN
		DELETE data_object_key
		WHERE data_object_id in (
			SELECT data_object_id
			FROM data_object
			WHERE data_service_id = @DataServiceID
		)

		delete data_object where data_service_id = @DataServiceID
	END
	ELSE
	BEGIN
		delete data_object_key
		where data_object_id = @DataObjectID

		delete data_object where data_object_id = @DataObjectID
	END

	set @ErrorCode = @@error



GO
create procedure [dbo].[spData_RemoveDataService]
	@DataServiceID int,
	@ErrorCode int output
as
	DELETE data_object_key WHERE data_object_id in (
		select data_object_id from data_object where data_service_id = @DataServiceID
	)
	DELETE data_object WHERE data_service_ID = @DataServiceID
	DELETE data_service WHERE data_service_id = @DataServiceID
	
	set @ErrorCode = @@error



GO
CREATE procedure [dbo].[spData_RemoveDataServiceCredential]
	@DataServiceCredentialID int,
	@ErrorCode int = 0 output
AS
	DELETE Data_Service_Credential
	WHERE Data_Service_Credential_ID = @DataServiceCredentialID
	
	set @errorcode = @@error

GO
CREATE procedure [dbo].[spData_UpdateDataKey]
	@DataObjectKeyID int,
	@DataObjectID int,
	@FieldName nvarchar(100),
	@DataType int,
	@Required char(1),
	@DisplayName nvarchar(100),
	@DataObjectGuid nvarchar(40),
	@DataObjectKeyGuid uniqueidentifier,
	@NewID int output,
	@ErrorCode int output
as
	declare @DataObjectGuid2 uniqueidentifier

	--begin 3.1.3
	if (@DataObjectID = 0 or @DataObjectID IS NULL) and @DataObjectGuid <> ''
	begin
		select @DataObjectID = data_object_id from data_object where data_object_guid = cast(@dataObjectGuid as uniqueidentifier)
		set @DataObjectGuid2 = cast(@DataObjectGuid as uniqueidentifier)
	end
	else
	begin
		select @DataObjectGuid2 = Data_Object_Guid from Data_Object where Data_Object_ID = @DataObjectID
	end
	--end 3.1.3

	IF @DataObjectKeyID = 0 OR @DataObjectKeyID IS NULL
	begin
		if (select count(*) from data_object_key where data_object_guid = @DataObjectGuid2 and field_name = @FieldName) = 0
		begin
			INSERT INTO data_object_key (Data_Object_ID, Field_Name, Data_Type, Required, Display_Name, Data_Object_Guid, Data_Object_Key_Guid)
			VALUES (@DataObjectID, @FieldName, @DataType, @Required, @DisplayName, @DataObjectGuid2, @DataObjectKeyGuid)
			select @NewID = @@identity
		end
		else
		begin
			select @NewID = data_object_key_id
			from data_object_key where data_object_guid = @DataObjectGuid2 and field_name = @FieldName
		end
	end
	ELSE
	begin
		UPDATE data_object_key
		SET data_object_id = @DataObjectID,
			field_name = @FieldName,
			data_type = @DataType,
			required = @Required,
			display_name = @DisplayName,
			data_object_guid = @DataObjectGuid
		WHERE data_object_key_id = @DataObjectKeyID
	end

	set @ErrorCode = @@error

GO
CREATE procedure [dbo].[spData_UpdateDataObject]
	@DataObjectID int = 0,
	@DataServiceID int,
	@Name nvarchar(100),
	@MergeSource char(1),
	@DataObjectGuid nvarchar(40),
	@NewID int output,
	@ErrorCode int output
AS
	declare @DataServiceGuid uniqueidentifier

	select @DataServiceGuid = Data_Service_Guid from Data_service where Data_Service_ID = @DataServiceID

	IF @DataObjectID = 0 OR @DataObjectID IS NULL
	BEGIN
		if (select count(*) from data_object where data_object_guid = cast(@DataObjectGuid as uniqueidentifier)) = 0
		begin
			INSERT INTO data_object (Data_Service_ID, [Object_Name], Merge_Source, Data_Object_Guid, Data_Service_Guid)
			VALUES (@DataServiceID, @Name, @MergeSource, @DataObjectGuid, @DataServiceGuid)

			select @NewID = @@identity
		end
		else
		begin
			select @NewID = data_object_id
			from data_object
			where data_object_guid = cast(@DataObjectGuid as uniqueidentifier)
		end
	END	
	ELSE
	BEGIN		
		UPDATE data_object
		SET [object_name] = @Name, merge_source = @MergeSource, data_service_guid = @DataServiceGuid
		WHERE data_object_id = @DataObjectID
	END

	set @ErrorCode = @@error

GO
CREATE procedure [dbo].[spData_UpdateDataService]
	@DataServiceID int,
	@Name nvarchar(100),
	@ConnectionString nvarchar(1000),
	@DatabaseObject nvarchar(100),
	@MergeSource char(1),
	@AllowWriteback char(1),
	@DataServiceGuid nvarchar(40),
	@RequiresCredentials char(1),
	@AllowConnectionExport char(1),
	@ProviderName nvarchar(100),
	@NewID int output,
	@ErrorCode int output
as
	IF @DataServiceID = 0 OR @DataServiceID IS NULL
	begin
		if (select count(*) from data_service where data_service_guid = cast(@DataServiceGuid as uniqueidentifier)) = 0
		begin
			INSERT INTO data_service ([name], connection_string, database_object, merge_source, allow_writeback, data_service_guid, Requires_Credentials, Allow_Connection_Export, Provider_Name)
			VALUES (@Name, @ConnectionString, @DatabaseObject, @MergeSource, @AllowWriteback, @DataServiceGuid, @RequiresCredentials, @AllowConnectionExport, @ProviderName)
			select @NewID = @@identity
		end
		else
		begin
			declare @ConnString nvarchar(1000)

			select @NewID = data_service_id, @ConnString = connection_string
			from data_Service
			where data_service_guid = cast(@DataServiceGuid as uniqueidentifier)

			if @ConnString is null or @ConnString = ''
				update data_service set connection_string = @ConnectionString where data_service_id = @NewID
		end
	end
	ELSE
		UPDATE data_service
		SET [name] = @Name,
			connection_string = @ConnectionString,
			database_object = @DatabaseObject,
			merge_source = @MergeSource,
			allow_writeback = @AllowWriteback,
			Requires_Credentials = @RequiresCredentials,
			Allow_Connection_Export = @AllowConnectionExport,
			Provider_Name = @ProviderName
		WHERE data_service_id = @DataServiceID

	set @ErrorCode = @@error

GO
CREATE procedure [dbo].[spData_UpdateDataServiceCredential]
	@DataServiceCredentialID int = 0,
	@DataServiceID int,
	@UserID int,
	@Username nvarchar(50),
	@Password nvarchar(500),
	@NewID int = 0 output,
	@ErrorCode int = 0 output
AS
	IF (@DataServiceCredentialID IS NULL OR @DataServiceCredentialID = 0)
	begin
		DECLARE @Data_Service_Guid uniqueidentifier

		SELECT	@Data_Service_Guid = Data_Service_Guid
		FROM	Data_Service
		WHERE	Data_Service_ID = @DataServiceID

		INSERT INTO Data_Service_Credential (Data_Service_ID, User_ID, Username, Password, Data_Service_Guid)
		VALUES (@DataServiceID, @UserID, @Username, @Password, @Data_Service_Guid)

		SET @NewID = @@IDENTITY
	end
	ELSE
	begin
		UPDATE Data_Service_Credential
		SET Username = @Username,
			Password = @Password
		WHERE Data_Service_Credential_ID = @DataServiceCredentialID
	end
	
	set @errorcode = @@error	
GO
CREATE PROCEDURE [dbo].[spDataSource_DataKeyList]
	@DataObjectGuid uniqueidentifier = null,
	@Name nvarchar(500) = null
AS
	IF @Name IS NULL
		SELECT	dk.data_object_key_guid, dk.field_name, dk.required, dk.display_name, dk.data_object_guid,
				dk.Data_Object_Key_Id
		FROM	data_object_key dk
		WHERE	dk.data_object_guid = @DataObjectGuid
		ORDER BY dk.field_name
	ELSE
		SELECT	dk.data_object_key_guid, dk.field_name, dk.required, dk.display_name, dk.data_object_guid,
				dk.Data_Object_Key_Id
		FROM	data_object_key dk
		WHERE	dk.data_object_guid = @DataObjectGuid
				AND dk.Field_Name = @Name
		ORDER BY dk.field_name

GO
CREATE PROCEDURE [dbo].[spDataSource_DataObjectList]
	@DataObjectGuid uniqueidentifier = null,
	@DataServiceGuid uniqueidentifier = null
AS
	IF @DataObjectGuid IS NULL
		SELECT	o.[Object_Name], o.data_object_guid, o.data_service_guid, o.Merge_Source, 
				o.Object_Type, o.Display_Name
		FROM	data_object o
		WHERE	o.data_service_guid = @DataServiceGuid
		ORDER BY o.Display_Name;
	ELSE
		SELECT	o.[Object_Name], o.data_object_guid, o.data_service_guid, o.Merge_Source, 
				o.Object_Type, o.Display_Name
		FROM	data_object o
		WHERE	o.data_object_guid = @DataObjectGuid
		ORDER BY o.Display_Name;
GO
CREATE PROCEDURE [dbo].[spDataSource_DataSourceList]
	@DataServiceGuid uniqueidentifier = null,
	@BusinessUnitGuid uniqueidentifier = null
as
	IF @DataServiceGuid IS NULL
		SELECT	d.[name], d.connection_string, d.data_service_guid,
				d.Allow_WriteBack, d.Credential_Method, d.Allow_Connection_Export,
				d.Business_Unit_Guid, d.Provider_Name, d.Allow_Insert
		FROM	data_service d
		WHERE	d.business_unit_guid = @BusinessUnitGuid
		ORDER BY d.[name]
	ELSE
		SELECT	d.[name], d.connection_string, d.data_service_guid,
				d.Allow_WriteBack, d.Credential_Method, d.Allow_Connection_Export,
				d.Business_Unit_Guid, d.Provider_Name, d.Allow_Insert, d.Username, d.PasswordHash
		FROM	data_service d
		WHERE	d.data_service_guid = @DataServiceGuid
		ORDER BY d.[name]
GO
CREATE PROCEDURE [dbo].[spDataSource_DisplayFieldList]
	@DataObjectGuid uniqueidentifier = null,
	@Name nvarchar(500) = null
AS
	IF @Name IS NULL
		SELECT	field_name, display_name, data_object_guid
		FROM	data_object_display
		WHERE	data_object_guid = @DataObjectGuid
		ORDER BY field_name;
	ELSE
		SELECT	field_name, display_name, data_object_guid
		FROM	data_object_display
		WHERE	data_object_guid = @DataObjectGuid
				AND Field_Name = @Name
		ORDER BY field_name;
GO
CREATE PROCEDURE [dbo].[spDataSource_RemoveDataKey]
	@FieldName nvarchar(500),
	@DataObjectGuid nvarchar(40)
AS
	DELETE	data_object_key 
	WHERE	Data_Object_Guid = @DataObjectGuid
			and field_name = @FieldName;
GO
CREATE PROCEDURE [dbo].[spDataSource_RemoveDataObject]
	@DataObjectGuid uniqueidentifier
AS
	DELETE	data_object_key
	WHERE	data_object_guid = @DataObjectGuid;
	
	DELETE	data_object_display
	WHERE	data_object_guid = @DataObjectGuid;

	DELETE	data_object 
	WHERE	data_object_guid = @DataObjectGuid;
GO
CREATE PROCEDURE [dbo].[spDataSource_RemoveDataSource]
	@DataServiceGuid uniqueidentifier
as
	DECLARE @DataServiceId INT

	SELECT	@DataServiceId = Data_Service_ID
	FROM	Data_Service
	WHERE	data_service_guid = @DataServiceGuid

	DELETE data_object_key WHERE data_object_id in (
		SELECT data_object_id FROM data_object WHERE data_service_ID = @DataServiceID
	)
	DELETE data_object WHERE data_service_ID = @DataServiceID
	DELETE data_service WHERE data_service_guid = @DataServiceGuid
GO
CREATE PROCEDURE [dbo].[spDataSource_RemoveDisplayField]
	@FieldName nvarchar(500),
	@DataObjectGuid uniqueidentifier
AS
	DELETE	data_object_display
	WHERE	Data_Object_Guid = @DataObjectGuid
			and field_name = @FieldName;
GO
CREATE procedure [dbo].[spDataSource_UpdateDataKey]
	@FieldName nvarchar(500),
	@Required bit,
	@DisplayName nvarchar(500),
	@DataObjectGuid nvarchar(40)
AS
	IF NOT EXISTS(SELECT * FROM data_object_key WHERE Field_Name = @FieldName AND Data_Object_Guid = @DataObjectGuid)
	begin
		INSERT INTO data_object_key (Data_Object_Key_Guid, Field_Name, [Required], Display_Name, Data_Object_Guid)
		VALUES (newid(), @FieldName, @Required, @DisplayName, @DataObjectGuid);
	end
	ELSE
	begin
		UPDATE	data_object_key
		SET		[required] = @Required,
				display_name = @DisplayName
		WHERE	Data_Object_Guid = @DataObjectGuid
			and field_name = @FieldName;
	end
GO
CREATE PROCEDURE [dbo].[spDataSource_UpdateDataObject]
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
CREATE PROCEDURE [dbo].[spDataSource_UpdateDataService]
	@DataServiceGuid uniqueidentifier,
	@Name nvarchar(100),
	@ConnectionString nvarchar(MAX),
	@AllowUpdate bit,
	@CredentialMethod int,
	@AllowConnectionExport bit,
	@BusinessUnitGuid uniqueidentifier,
	@ProviderName nvarchar(100),
	@AllowInsert bit,
	@Username nvarchar(100),
	@PasswordHash varchar(1000)
as
	IF NOT EXISTS(SELECT * FROM Data_Service WHERE data_service_guid = @DataServiceGuid)
		INSERT INTO Data_Service ([name], connection_string, allow_writeback, data_service_guid, 
				Credential_Method, Allow_Connection_Export, Business_Unit_Guid, Provider_Name, 
				Allow_Insert, Username, PasswordHash)
		VALUES (@Name, @ConnectionString, @AllowUpdate, @DataServiceGuid, 
				@CredentialMethod, @AllowConnectionExport, @BusinessUnitGuid, @ProviderName, 
				@AllowInsert, @Username, @PasswordHash);
	ELSE
		UPDATE Data_Service
		SET [name] = @Name,
			connection_string = @ConnectionString,
			allow_writeback = @AllowUpdate,
			Credential_Method = @CredentialMethod,
			Allow_Connection_Export = @AllowConnectionExport,
			Business_Unit_Guid = @BusinessUnitGuid,
			Provider_Name = @ProviderName,
			Allow_Insert = @AllowInsert,
			Username = @Username,
			PasswordHash = @PasswordHash
		WHERE Data_Service_Guid = @DataServiceGuid;
GO
CREATE procedure [dbo].[spDataSource_UpdateDisplayField]
	@FieldName nvarchar(500),
	@DisplayName nvarchar(500),
	@DataObjectGuid uniqueidentifier
AS
	IF NOT EXISTS(SELECT * FROM data_object_display WHERE Field_Name = @FieldName AND Data_Object_Guid = @DataObjectGuid)
	begin
		INSERT INTO data_object_display (Field_Name, Display_Name, Data_Object_Guid)
		VALUES (@FieldName, @DisplayName, @DataObjectGuid);
	end
	ELSE
	begin
		UPDATE	data_object_display
		SET		display_name = @DisplayName
		WHERE	Data_Object_Guid = @DataObjectGuid
			and field_name = @FieldName;
	end
GO
CREATE procedure [dbo].[spDocument_Cleanup]
AS
	SET NOCOUNT ON

	WHILE (1=1)
	BEGIN
		DELETE TOP(200) FROM Document
		WHERE	Downloadable = 0 
			AND DateCreated < DATEADD(hour, -CAST((SELECT OptionValue 
										FROM Global_Options 
										WHERE OptionCode = 'CLEANUP_HOURS') AS float), GetUtcDate());

		IF (@@ROWCOUNT < 200) break;
	END
GO
CREATE PROCEDURE [dbo].[spDocument_DeleteDocument]
	@DocumentId uniqueidentifier
as
	DELETE FROM	Document
	WHERE	DocumentId = @DocumentId;
GO
CREATE PROCEDURE [dbo].[spDocument_DocumentBinary] (
	@UserGuid uniqueidentifier,
	@DocumentId uniqueidentifier,
	@Extension nvarchar(10)
)
AS
	SELECT	DocumentBinary, DocumentLength
	FROM	Document
	WHERE	UserGuid = @UserGuid	--Security Check
			AND DocumentId = @DocumentId
			AND Extension = @Extension;
GO
CREATE PROCEDURE [dbo].[spDocument_DocumentList] (
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier,
	@IncludeActionOnlyDocs bit
)
AS
	SELECT	Document.DocumentId, 
			Document.Extension,  
			Document.DisplayName,  
			Document.ProjectDocumentGuid,  
			Document.DateCreated,  
			Document.JobId,
			Document.ActionOnly,
			Template.Name As ProjectName
	FROM	Document
			INNER JOIN ProcessJob ON Document.JobId = ProcessJob.JobId
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
	WHERE	(Document.JobId = @JobId OR @JobId IS NULL)
			AND (@IncludeActionOnlyDocs = 1 OR Document.ActionOnly = 0)
			AND Document.UserGuid = @UserGuid; --Security check
GO
CREATE procedure [dbo].[spDocument_GetCleanupJobs]
AS
	SELECT JobId
	FROM Document
	WHERE Downloadable = 0
		AND DateCreated < DATEADD(hour, -CAST((SELECT OptionValue 
									FROM Global_Options 
									WHERE OptionCode = 'CLEANUP_HOURS') AS float), GetUtcDate());
GO
CREATE PROCEDURE [dbo].[spDocument_InsertDocument]
	@DocumentId uniqueidentifier,
	@Extension nvarchar(10),
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier,
	@DisplayName nvarchar(255),
	@DateCreated datetime,
	@DocumentBinary varbinary(max),
	@DocumentLength int,
	@ProjectDocumentGuid uniqueidentifier,
	@ActionOnly bit
as
	INSERT INTO Document(DocumentId, 
		Extension, 
		JobId, 
		UserGuid, 
		DisplayName, 
		DateCreated, 
		DocumentBinary, 
		DocumentLength,
		ProjectDocumentGuid,
		Downloadable,
		ActionOnly)
	VALUES (@DocumentId, 
		@Extension, 
		@JobId, 
		@UserGuid, 
		@DisplayName, 
		@DateCreated, 
		@DocumentBinary, 
		@DocumentLength,
		@ProjectDocumentGuid,
		CASE WHEN @ActionOnly = 1 THEN 0 ELSE 1 END,
		@ActionOnly);
		
	-- Update less recent documents to be no longer "downloadable"
	-- First get the setting
	DECLARE @DownloadableDocNum int;
	SET @DownloadableDocNum = (SELECT OptionValue 
		FROM Global_Options 
		WHERE OptionCode = 'DOWNLOADABLE_DOC_NUM');
		
	-- Then create a table and fill it with the documents we have to keep
	CREATE TABLE #DownloadableDocs (
		JobId uniqueidentifier,
		DateCreated datetime);
		
	SET ROWCOUNT @DownloadableDocNum;
	
	INSERT #DownloadableDocs (JobId, DateCreated)
	SELECT JobId, DateCreated
		FROM Document
		WHERE UserGuid = @UserGuid
		GROUP BY JobId, DateCreated
		ORDER BY DateCreated DESC;
		
	SET ROWCOUNT 0;
			
	-- Then update any documents that aren't ones we're supposed to keep
	UPDATE Document
	SET Downloadable = 0
	WHERE UserGuid = @UserGuid
		AND JobId NOT IN
			(
			SELECT JobId
			FROM #DownloadableDocs
			);
GO
CREATE PROCEDURE [dbo].[spDocument_UpdateDocument]
	@DocumentId uniqueidentifier,
	@Extension nvarchar(10),
	@UserGuid uniqueidentifier,
	@DocumentBinary varbinary(max),
	@DocumentLength int
as
	UPDATE	Document
	SET		DocumentBinary = @DocumentBinary,
			DocumentLength = @DocumentLength
	WHERE	DocumentId = @DocumentId
			AND UserGuid = @UserGuid
			AND Extension = @Extension;
GO
CREATE procedure [dbo].[spFolder_FolderGroupList]
	@FolderGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	SELECT	*
	FROM	Folder_Group
	WHERE	FolderGuid = @FolderGuid

	set @errorcode = @@error
GO
CREATE procedure [dbo].[spFolder_PublishedProjectList]
	@UserGuid uniqueidentifier,
	@ErrorCode int output
as
	declare @BusinessUnitGuid uniqueidentifier
	select @BusinessUnitGuid = business_unit_guid from Intelledox_User where User_Guid = @UserGuid

	SELECT	a.Folder_ID, a.Folder_Guid, a.Folder_Name, d.Template_Group_Id, b.[Name] as Project_Name,
			d.Template_Group_Guid
	FROM	Folder a
		left join Template_Group d on a.Folder_Guid = d.Folder_Guid
			AND (d.EnforcePublishPeriod = 0 
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getdate())))
		left join Template b on d.Template_Guid = b.Template_Guid
	WHERE	((d.Template_Group_Guid in (
					select	c.Template_Group_Guid
					from	template_group c
							inner join template b on c.Template_Guid = b.template_Guid or c.Layout_Guid = b.template_Guid
					group by c.Template_Group_Guid
				)
			))
		and a.Business_Unit_GUID = @BusinessUnitGuid
		and a.Folder_Guid in (
			SELECT	FolderGuid
			FROM	Folder_Group
			WHERE	GroupGuid in (
				select	distinct b.Group_Guid
				from	Intelledox_User a
						left join User_Group_Subscription c on a.User_Guid = c.UserGuid
						left join User_Group b on c.GroupGuid = b.Group_Guid
				where	b.Group_Guid is not null
				and		a.User_Guid = @UserGuid
			)
		)
	ORDER BY a.Folder_Name, a.Folder_ID, d.template_group_id
	
	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spFolder_RemoveFolderGroup]
	@FolderGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	DELETE FROM Folder_Group
	WHERE	FolderGuid = @FolderGuid
			AND GroupGuid = @GroupGuid
	
	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spFolder_UpdateFolderGroup]
	@FolderGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	INSERT INTO Folder_Group (FolderGuid, GroupGuid)
	VALUES (@FolderGuid, @GroupGuid)
	
	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spGetBilling]
AS
	DECLARE @CurrentDate DateTime
	DECLARE @LicenseHolder NVarchar(1000)
	
	SET NOCOUNT ON
	
	SET @CurrentDate = CAST(CONVERT(Varchar(10), GETUTCDATE(), 102) AS DateTime)
	
	SELECT	@LicenseHolder = OptionValue 
	FROM	Global_Options
	WHERE	OptionCode = 'LICENSE_HOLDER'

	SELECT	@LicenseHolder as LicenseHolder, CONVERT(Varchar(10), Template_Log.DateTime_Finish, 102) as ActivityDate, 
			IsNull(Template.Name, '') as ProjectName, COUNT(*) AS DocumentCount
	FROM	Template_Log
			LEFT JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
			LEFT JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
	WHERE	Template_Log.Completed = 1
			AND Template_Log.DateTime_Finish BETWEEN DATEADD(d, -30, @CurrentDate) AND @CurrentDate
	GROUP BY CONVERT(Varchar(10), Template_Log.DateTime_Finish, 102), IsNull(Template.Name, '')
GO
CREATE procedure [dbo].[spGroups_IdToGuid]
	@id int
AS
	SELECT	Group_Guid
	FROM	User_Group
	WHERE	User_Group_ID = @id;
GO
CREATE PROCEDURE [dbo].[spImportUsers](
	@Contact_ID int,
	@Contact_name varchar(1000),
	@Email varchar(1000),
	@Username varchar(1000),
	@Password varchar(1000),
	@Customer_ID int,
	@Customer_Name varchar(1000),
	@Website varchar(1000),
	@AddressLine1 varchar(1000),
	@AddressLine2 varchar(1000),
	@AddressLine3 varchar(1000),
	@AddressLine4 varchar(1000),
	@Post_Code varchar(50)
)
AS
	declare @BusinessUnitGUID uniqueidentifier
	declare @NewUserID int
	declare @NewGroupID int
	declare @TrialGroupID int
	declare @NewAddressID int
	declare @FirstName varchar(100)
	declare @LastName varchar(100)

	SELECT	@BusinessUnitGUID = Business_Unit_GUID
	FROM	Business_Unit
	
	INSERT INTO Intelledox_User(Username, PwdHash, WinNT_User, Business_Unit_GUID, User_Guid)
	VALUES (@Username, @Password, 0, @BusinessUnitGUID, newid())
	
	SET @NewUserID = @@identity

	SELECT	@NewGroupID = User_group_id
	FROM	User_Group
	WHERE	[Name] = @Customer_Name

	SELECT	@TrialGroupID = User_group_id
	FROM	User_Group
	WHERE	[Name] = 'Initial Trial'

	IF @NewGroupID IS NULL
	BEGIN
		INSERT INTO User_Group ([Name], [WinNT_Group], Business_Unit_GUID, Group_Guid, AutoAssignment, SystemGroup)
		VALUES (@Customer_Name, 0, @BusinessUnitGUID, newid(), '0', '0')

		SET @NewGroupID = @@identity

		INSERT INTO Address_Book (addresstype_id,address_reference,
			prefix, first_name, last_name, full_name, salutation_name, title,
			organisation_name, phone_number, fax_number, email_address,
			street_address_1, street_address_2, street_address_suburb, street_address_state,
			street_address_postcode, street_address_country, postal_address_1, postal_address_2,
			postal_address_suburb, postal_address_state, postal_address_postcode, postal_address_country)
		VALUES (0, '',
			'', @FirstName, @LastName, @Contact_name, '', '',
			'', '', '', @Email,
			@AddressLine1, @AddressLine2, @AddressLine3, @AddressLine4,
			@Post_Code, '', '', '',
			'', '', '', '')

		SET @NewAddressID = @@identity
	END

	IF @TrialGroupID IS NULL
	BEGIN
		INSERT INTO User_Group ([Name], [WinNT_Group], Business_Unit_GUID, Group_Guid, AutoAssignment, SystemGroup)
		VALUES ('Initial Trial', '0', @BusinessUnitGUID, newid(), '0', '0')

		SET @TrialGroupID = @@identity
	END

	IF CHARINDEX(' ', @Contact_name) > 1
	BEGIN
		SET @FirstName = LEFT(@Contact_name, CHARINDEX(' ', @Contact_name) - 1)
		SET @LastName = SUBSTRING(@Contact_name, CHARINDEX(' ', @Contact_name) + 1, LEN(@Contact_name) - CHARINDEX(' ', @Contact_name))
	END
	ELSE
	BEGIN
		SET @FirstName = @Contact_name
		SET @LastName = @Contact_name
	END

	INSERT INTO Address_Book (addresstype_id, address_reference,
		prefix, first_name, last_name, full_name, salutation_name, title,
		organisation_name, phone_number, fax_number, email_address,
		street_address_1, street_address_2, street_address_suburb, street_address_state,
		street_address_postcode, street_address_country, postal_address_1, postal_address_2,
		postal_address_suburb, postal_address_state, postal_address_postcode, postal_address_country)
	VALUES (0, '',
		'', @FirstName, @LastName, @Contact_name, '', '',
		'', '', '', @Email,
		@AddressLine1, @AddressLine2, @AddressLine3, @AddressLine4,
		@Post_Code, '', '', '',
		'', '', '', '')

	SET @NewAddressID = @@identity

	exec spAddBk_SubscribeUserAddress @NewUserID, @NewAddressID, 0

GO
CREATE PROCEDURE [dbo].[spJob_CreateJobDefinition](
	@JobDefinitionId uniqueidentifier,
	@Name nvarchar(200),
	@IsEnabled bit,
	@OwnerGuid uniqueidentifier,
	@DateCreated datetime,
	@DateModified datetime,
	@JobDefinition xml,
	@NextRunDate datetime,
	@WatchFolder nvarchar(300),
	@DataSourceGuid uniqueidentifier,
	@DeleteAfterDays int
)
AS
	INSERT INTO JobDefinition(JobDefinitionId, Name, NextRunDate, IsEnabled, OwnerGuid, DateCreated, 
		DateModified, JobDefinition, WatchFolder, DataSourceGuid, DeleteAfterDays)
	VALUES (@JobDefinitionId, @Name, @NextRunDate, @IsEnabled, @OwnerGuid, @DateCreated, 
		@DateModified, @JobDefinition, @WatchFolder, @DataSourceGuid, @DeleteAfterDays);
GO
CREATE PROCEDURE [dbo].[spJob_DeleteJobDefinition](
	@JobDefinitionId uniqueidentifier
)
AS
	DELETE FROM JobDefinition
	WHERE	JobDefinitionId = @JobDefinitionId;
GO
CREATE PROCEDURE [dbo].[spJob_DeleteRecurrencePattern] (
	@JobDefinitionId uniqueidentifier)
AS
	DELETE FROM RecurrencePattern 
	WHERE JobDefinitionId = @JobDefinitionId;
GO
CREATE PROCEDURE [dbo].[spJob_DueList]
AS
	SELECT	* 
	FROM	JobDefinition
	WHERE	NextRunDate <= GETUTCDATE()
	ORDER BY NextRunDate, DateCreated, Name;
GO
CREATE PROCEDURE [dbo].[spJob_GetStatus] (
	@JobId uniqueidentifier
)
AS
	SELECT	CurrentStatus
	FROM	ProcessJob
	WHERE	JobId = @JobId;
GO
CREATE PROCEDURE [dbo].[spJob_JobDefinitionList](
	@JobDefinitionId uniqueidentifier
)
AS
	IF @JobDefinitionId IS NULL
		SELECT	*
		FROM	JobDefinition
		ORDER BY Name;
	ELSE
		SELECT	*
		FROM	JobDefinition
		WHERE	JobDefinitionId = @JobDefinitionId;
GO
CREATE PROCEDURE [dbo].[spJob_JobDefinitionSearch](
	@Name nvarchar(200),
	@DateCreatedFrom datetime,
	@DateCreatedTo datetime,
	@NextRunFrom datetime,
	@NextRunTo datetime
)
AS
	SELECT	*
	FROM	JobDefinition
	WHERE	(Name LIKE @Name + '%' OR @Name = '')
			AND (NextRunDate >= @NextRunFrom OR @NextRunFrom IS NULL)
			AND (NextRunDate < @NextRunTo OR @NextRunTo IS NULL)
			AND (DateCreated >= @DateCreatedFrom OR @DateCreatedFrom IS NULL)
			AND (DateCreated < @DateCreatedTo OR @DateCreatedTo IS NULL)
	ORDER BY Name;
GO
CREATE PROCEDURE [dbo].[spJob_LodgeJob] (
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier,
	@DateStarted datetime,
	@ProjectGroupGuid uniqueidentifier,
	@LogGuid uniqueidentifier,
	@JobDefinitionGuid uniqueidentifier,
	@InitialStatus int
)
AS
	IF (@ProjectGroupGuid IS NULL AND @JobDefinitionGuid IS NOT NULL)
	BEGIN
		SELECT	@ProjectGroupGuid = JobDefinition.value('data(AnswerFile/HeaderInfo/TemplateInfo/@TemplateGroupGuid)[1]', 'uniqueidentifier')
		FROM	JobDefinition
		WHERE	JobDefinitionId = @JobDefinitionGuid;
	END

	INSERT INTO ProcessJob(JobId, UserGuid, DateStarted, ProjectGroupGuid, CurrentStatus, LogGuid, JobDefinitionGuid)
	VALUES (@JobId, @UserGuid, @DateStarted, @ProjectGroupGuid, @InitialStatus, @LogGuid, @JobDefinitionGuid);
GO
CREATE PROCEDURE [dbo].[spJob_Queued]
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus,
			ProcessJob.LogGuid, ProcessJob.JobDefinitionGuid
	FROM	ProcessJob
	WHERE	ProcessJob.CurrentStatus = 1
	ORDER BY ProcessJob.DateStarted;

GO
CREATE PROCEDURE [dbo].[spJob_QueuedJobList]
	@Jobid uniqueidentifier
AS
	SELECT	*
	FROM	ProcessJob
	WHERE	JobId = @Jobid;
GO
CREATE PROCEDURE [dbo].[spJob_QueueList]
	@StartDate DateTime,
	@FinishDate DateTime,
	@CurrentStatus Int
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus,
			Template.Name as ProjectName, Intelledox_User.Username, 
			ProcessJob.LogGuid,
			CASE WHEN template_Log.Messages IS NOT NULL THEN 1 ELSE 0 END AS HasMessages
	FROM	ProcessJob
			INNER JOIN Intelledox_User ON ProcessJob.UserGuid = Intelledox_User.User_Guid
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
			LEFT JOIN Template_Log ON ProcessJob.LogGuid = Template_Log.Log_Guid
	WHERE	ProcessJob.DateStarted BETWEEN @StartDate AND @FinishDate
			AND ((@CurrentStatus = 0) OR 
				(@CurrentStatus = -1 AND ProcessJob.CurrentStatus <> 7) OR 
				(@CurrentStatus <> -1 AND ProcessJob.CurrentStatus = @CurrentStatus))
	ORDER BY ProcessJob.DateStarted DESC;
GO
CREATE PROCEDURE [dbo].[spJob_QueueListByDefinition]
	@JobDefinitionId uniqueidentifier
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus,
			Template.Name as ProjectName, Intelledox_User.Username, 
			ProcessJob.LogGuid,
			CASE WHEN template_Log.Messages IS NOT NULL THEN 1 ELSE 0 END AS HasMessages
	FROM	ProcessJob
			INNER JOIN Intelledox_User ON ProcessJob.UserGuid = Intelledox_User.User_Guid
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
			LEFT JOIN Template_Log ON ProcessJob.LogGuid = Template_Log.Log_Guid
	WHERE	ProcessJob.JobDefinitionGuid = @JobDefinitionId
	ORDER BY ProcessJob.DateStarted DESC;
GO
CREATE PROCEDURE [dbo].[spJob_RecurrencePatternList]
	@RecurrencePatternId uniqueidentifier,
	@JobDefinitionId uniqueidentifier
AS
	IF @JobDefinitionId IS NULL
		SELECT	*
		FROM	RecurrencePattern
		WHERE	RecurrencePatternID = @RecurrencePatternId;
	ELSE
		SELECT	*
		FROM	RecurrencePattern
		WHERE	JobDefinitionId = @JobDefinitionId;
GO
CREATE PROCEDURE [dbo].[spJob_RemoveJobDefinition]
	@JobDefinitionId uniqueidentifier
AS
	DELETE	FROM RecurrencePattern
	WHERE	JobDefinitionId = @JobDefinitionId;
	
	DELETE	FROM JobDefinition
	WHERE	JobDefinitionId = @JobDefinitionId;
GO
CREATE PROCEDURE [dbo].[spJob_SetQueueStatus]
	@NewState int,
	@JobId uniqueidentifier
AS
	IF @JobId IS NULL
		--Update all queued or paused items
		UPDATE	ProcessJob
		SET		CurrentStatus = @NewState
		WHERE	(CurrentStatus = 1
				OR CurrentStatus = 3);
	ELSE
		UPDATE	ProcessJob
		SET		CurrentStatus = @NewState
		WHERE	JobId = @JobId
				AND (CurrentStatus = 1
					OR CurrentStatus = 3);
GO
CREATE PROCEDURE [dbo].[spJob_UpdateJobDefinition](
	@JobDefinitionId uniqueidentifier,
	@Name nvarchar(200),
	@IsEnabled bit,
	@OwnerGuid uniqueidentifier,
	@DateModified datetime,
	@JobDefinition xml,
	@WatchFolder nvarchar(300),
	@DataSourceGuid uniqueidentifier,
	@DeleteAfterDays int,
	@NextRunDate datetime
)
AS
	UPDATE	JobDefinition
	SET		Name = @Name, 
			IsEnabled = @IsEnabled, 
			OwnerGuid = @OwnerGuid, 
			DateModified = @DateModified, 
			JobDefinition = @JobDefinition,
			WatchFolder = @WatchFolder,
			DataSourceGuid = @DataSourceGuid,
			DeleteAfterDays = @DeleteAfterDays,
			NextRunDate = @NextRunDate
	WHERE	JobDefinitionId = @JobDefinitionId;
GO
CREATE PROCEDURE [dbo].[spJob_UpdateNextRun]
	@JobDefinitionId uniqueidentifier,
	@LastRunDate datetime,
	@RunDate datetime
AS
	UPDATE	JobDefinition
	SET		LastRunDate = @LastRunDate,
			NextRunDate = @RunDate
	WHERE	JobDefinitionId = @JobDefinitionId;
GO
CREATE PROCEDURE [dbo].[spJob_UpdateQueuedJob]
	@JobId uniqueidentifier,
	@DateStarted datetime,
	@Status int,
	@LogGuid uniqueidentifier,
	@JobDefinitionGuid uniqueidentifier
AS
	UPDATE	ProcessJob
	SET		DateStarted = @DateStarted,
			CurrentStatus = @Status,
			LogGuid = @LogGuid,
			JobDefinitionGuid = JobDefinitionGuid
	WHERE	JobId = @JobId;
GO
CREATE PROCEDURE [dbo].[spJob_UpdateRecurrencePattern] (
	@RecurrencePatternID uniqueidentifier,
	@JobDefinitionId uniqueidentifier,
	@Frequency [varchar](10),
	@StartDate [datetime],
	@RepeatUntil [datetime],
	@RepeatCount [int],
	@Interval [int],
	@ByDay [varchar](50),
	@ByMonthDay [varchar](50),
	@ByYearDay [varchar](50),
	@ByWeekNo [varchar](50),
	@ByMonth [varchar](50),
	@BySetPosition [int],
	@WeekStart [varchar](2))
AS
	IF NOT EXISTS(SELECT * FROM RecurrencePattern WHERE RecurrencePatternID = @RecurrencePatternId)
	BEGIN
		INSERT INTO RecurrencePattern (RecurrencePatternID, JobDefinitionId, Frequency, StartDate, RepeatUntil, RepeatCount, Interval, ByDay, ByMonthDay, ByYearDay, ByWeekNo, ByMonth, BySetPosition, WeekStart)
		VALUES (@RecurrencePatternID, @JobDefinitionId, @Frequency, @StartDate, @RepeatUntil, @RepeatCount, @Interval, @ByDay, @ByMonthDay, @ByYearDay, @ByWeekNo, @ByMonth, @BySetPosition, @WeekStart);
	END
	ELSE
	BEGIN
		UPDATE	RecurrencePattern
		SET		JobDefinitionId = @JobDefinitionId,
				Frequency = @Frequency,
				StartDate = @StartDate,
				RepeatUntil = @RepeatUntil,
				RepeatCount = @RepeatCount,
				Interval = @Interval,
				ByDay = @ByDay,
				ByMonthDay = @ByMonthDay,
				ByYearDay = @ByYearDay,
				ByWeekNo = @ByWeekNo,
				ByMonth = @ByMonth,
				BySetPosition = @BySetPosition,
				WeekStart = @WeekStart
		WHERE	RecurrencePatternID = @RecurrencePatternID;
	END
GO
CREATE PROCEDURE [dbo].[spJob_UpdateStatus] (
	@JobId uniqueidentifier,
	@CurrentStatus int
)
AS
	UPDATE	ProcessJob
	SET		CurrentStatus = @CurrentStatus
	WHERE	JobId = @JobId;
GO
CREATE PROCEDURE [dbo].[spLibrary_ClearExcessVersions]
	@ContentData_Guid uniqueidentifier,
	@IsBinary bit
AS	
	If (@IsBinary = 1)
	BEGIN
		WHILE ((SELECT	COUNT(*) 
				FROM	ContentData_Binary_Version 
				WHERE	ContentData_Guid = @ContentData_Guid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
		BEGIN
			IF (SELECT	COUNT(*) 
				FROM	ContentData_Binary_Version 
				WHERE	ContentData_Guid = @ContentData_Guid
						AND Approved = 1) > 0
			BEGIN
				--Clear unapproved expired first
				DELETE FROM ContentData_Binary_Version
				WHERE ContentData_Version = 
						(SELECT MIN(ContentData_Version) 
						FROM	ContentData_Binary_Version 
						WHERE	ContentData_Guid = @ContentData_Guid
								AND Approved = 1)
					AND ContentData_Guid = @ContentData_Guid;
			END
			ELSE
			BEGIN
				--Clear Oldest
				DELETE FROM ContentData_Binary_Version
				WHERE ContentData_Version = 
						(SELECT MIN(ContentData_Version) 
						FROM	ContentData_Binary_Version 
						WHERE	ContentData_Guid = @ContentData_Guid)
					AND ContentData_Guid = @ContentData_Guid;
			END
		END
	END
	ELSE
	BEGIN
		WHILE ((SELECT	COUNT(*) 
				FROM	ContentData_Text_Version
				WHERE	ContentData_Guid = @ContentData_Guid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
		BEGIN
			IF (SELECT	COUNT(*) 
				FROM	ContentData_Text_Version 
				WHERE	ContentData_Guid = @ContentData_Guid
						AND Approved = 1) > 0
			BEGIN
				--Clear unapproved expired first
				DELETE FROM ContentData_Text_Version
				WHERE ContentData_Version = 
						(SELECT MIN(ContentData_Version) 
						FROM	ContentData_Text_Version 
						WHERE	ContentData_Guid = @ContentData_Guid
								AND Approved = 1)
					AND ContentData_Guid = @ContentData_Guid;
			END
			ELSE
			BEGIN
				--Clear Oldest
				DELETE FROM ContentData_Text_Version
				WHERE ContentData_Version = 
						(SELECT MIN(ContentData_Version) 
						FROM ContentData_Text_Version 
						WHERE ContentData_Guid = @ContentData_Guid)
					AND ContentData_Guid = @ContentData_Guid;
			END
		END
	END
GO
CREATE PROCEDURE [dbo].[spLibrary_AddNewLibraryVersion]
	@ContentData_Guid uniqueidentifier,
	@IsBinary bit
AS
	BEGIN TRAN

	If (@IsBinary = 1)
	BEGIN
		INSERT INTO ContentData_Binary_Version 
			(ContentData_Version, 
			ContentData_Guid, 
			ContentData,
			FileType,
			Modified_Date, 
			Modified_By,
			Approved)
		SELECT ContentData_Binary.ContentData_Version,
			ContentData_Binary.ContentData_Guid,
			ContentData_Binary.ContentData,
			ContentData_Binary.FileType,
			ContentData_Binary.Modified_Date,
			ContentData_Binary.Modified_By,
			CASE Content_Item.Approved WHEN 0 THEN 1 ELSE Content_Item.Approved END AS Approved
		FROM ContentData_Binary	
			INNER JOIN Content_Item ON ContentData_Binary.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE ContentData_Binary.ContentData_Guid = @ContentData_Guid;
	END
	ELSE
	BEGIN
		INSERT INTO ContentData_Text_Version 
			(ContentData_Version, 
			ContentData_Guid, 
			ContentData,
			Modified_Date, 
			Modified_By,
			Approved)
		SELECT ContentData_Text.ContentData_Version,
			ContentData_Text.ContentData_Guid,
			ContentData_Text.ContentData,
			ContentData_Text.Modified_Date,
			ContentData_Text.Modified_By,
			CASE Content_Item.Approved WHEN 0 THEN 1 ELSE Content_Item.Approved END AS Approved
		FROM ContentData_Text
			INNER JOIN Content_Item ON ContentData_Text.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE ContentData_Text.ContentData_Guid = @ContentData_Guid;
	END
	
	EXEC spLibrary_ClearExcessVersions @ContentData_Guid, @IsBinary;
	
	COMMIT
GO
CREATE procedure [dbo].[spLibrary_ApproveVersion]
	@ContentItemGuid uniqueidentifier,
	@VersionNumber int,
	@UserGuid uniqueidentifier,
	@ExpiryDate datetime
as
	SET NOCOUNT ON
	
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @IsBinary bit
	DECLARE @IsCurrentVersion int
	
	SELECT	@ContentData_Guid = ContentData_Guid, 
			@IsBinary = CASE WHEN ContentType_Id = 2 THEN 0 ELSE 1 END
	FROM	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;
	
	IF (@IsBinary = 1)
	BEGIN
		SELECT	@IsCurrentVersion = COUNT(*)
		FROM	ContentData_Binary
		WHERE	ContentData_Guid = @ContentData_Guid
				AND ContentData_Version = @VersionNumber;
	END
	ELSE
	BEGIN
		SELECT	@IsCurrentVersion = COUNT(*)
		FROM	ContentData_Text
		WHERE	ContentData_Guid = @ContentData_Guid
				AND ContentData_Version = @VersionNumber;
	END
		
	BEGIN TRAN	
	
	IF (@IsCurrentVersion = 0)
	BEGIN
		IF (@IsBinary = 1)
		BEGIN
			--Archive current version
			INSERT INTO ContentData_Binary_Version 
				(ContentData_Version, 
				ContentData_Guid, 
				ContentData,
				FileType,
				Modified_Date, 
				Modified_By,
				Approved)
			SELECT ContentData_Binary.ContentData_Version,
				ContentData_Binary.ContentData_Guid,
				ContentData_Binary.ContentData,
				ContentData_Binary.FileType,
				ContentData_Binary.Modified_Date,
				ContentData_Binary.Modified_By,
				Content_Item.Approved
			FROM	ContentData_Binary
					INNER JOIN Content_Item ON ContentData_Binary.ContentData_Guid = Content_Item.ContentData_Guid
			WHERE	ContentData_Binary.ContentData_Guid = @ContentData_Guid;
			
			--Copy approved version into current
			UPDATE	ContentData_Binary
			SET		ContentData = ContentData_Binary_Version.ContentData, 
					FileType = ContentData_Binary_Version.FileType,
					ContentData_Version = @VersionNumber,
					Modified_Date = ContentData_Binary_Version.Modified_Date,
					Modified_By = ContentData_Binary_Version.Modified_By
			FROM	ContentData_Binary, 
					ContentData_Binary_Version
			WHERE	ContentData_Binary.ContentData_Guid = @ContentData_Guid
					AND ContentData_Binary_Version.ContentData_Guid = @ContentData_Guid 
					AND	ContentData_Binary_Version.ContentData_Version = @VersionNumber;
			
			--Delete the version as it is now current
			DELETE FROM ContentData_Binary_Version
			WHERE	ContentData_Binary_Version.ContentData_Guid = @ContentData_Guid 
					AND	ContentData_Binary_Version.ContentData_Version = @VersionNumber;
		END
		ELSE
		BEGIN
			--Archive current version
			INSERT INTO ContentData_Text_Version 
				(ContentData_Version, 
				ContentData_Guid, 
				ContentData,
				Modified_Date, 
				Modified_By,
				Approved)
			SELECT ContentData_Text.ContentData_Version,
				ContentData_Text.ContentData_Guid,
				ContentData_Text.ContentData,
				ContentData_Text.Modified_Date,
				ContentData_Text.Modified_By,
				Content_Item.Approved
			FROM	ContentData_Text
					INNER JOIN Content_Item ON ContentData_Text.ContentData_Guid = Content_Item.ContentData_Guid
			WHERE ContentData_Text.ContentData_Guid = @ContentData_Guid;
			
			--Copy approved version into current
			UPDATE	ContentData_Text
			SET		ContentData = ContentData_Text_Version.ContentData, 
					ContentData_Version = @VersionNumber, 
					Modified_Date = ContentData_Text_Version.Modified_Date,
					Modified_By = ContentData_Text_Version.Modified_By
			FROM	ContentData_Text, 
					ContentData_Text_Version
			WHERE	ContentData_Text.ContentData_Guid = @ContentData_Guid
					AND ContentData_Text_Version.ContentData_Guid = @ContentData_Guid 
					AND	ContentData_Text_Version.ContentData_Version = @VersionNumber;
			
			--Delete the version as it is now current
			DELETE FROM ContentData_Text_Version
			WHERE	ContentData_Text_Version.ContentData_Guid = @ContentData_Guid 
					AND	ContentData_Text_Version.ContentData_Version = @VersionNumber;
		END
	END
		
	UPDATE	Content_Item
	SET		Approved = 2,
			IsIndexed = 0,
			ExpiryDate = @ExpiryDate
	WHERE	ContentData_Guid = @ContentData_Guid;
	
	DELETE	Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItemGuid;
	
	COMMIT
GO
CREATE PROCEDURE [dbo].[spLibrary_GetBinary] (
	@UniqueId as uniqueidentifier,
	@VersionNumber as varchar(50)
)
AS
	If @VersionNumber = '0'
	BEGIN
		SELECT	cd.ContentData as [Binary]
		FROM	ContentData_Binary cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId;
	END
	ELSE
	BEGIN
		SELECT	cd.ContentData as [Binary]
		FROM	ContentData_Binary cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId
				AND cd.ContentData_Version = @VersionNumber
		UNION ALL
		SELECT	cd.ContentData as [Binary]
		FROM	ContentData_Binary_Version cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId
				AND cd.ContentData_Version = @VersionNumber;
	END
GO
CREATE PROCEDURE [dbo].[spLibrary_GetBinaryByDataGuid] (
	@DataGuid as uniqueidentifier
)
AS
	SELECT	cd.ContentData as [Binary]
	FROM	ContentData_Binary cd
	WHERE	ContentData_Guid = @DataGuid
GO
CREATE procedure [dbo].[spLibrary_GetContentVersions]
	@ContentItemGuid uniqueidentifier
as
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @Approved Int
	DECLARE @ExpiryDate datetime
	
	UPDATE Content_Item
	SET Approved = 1
	WHERE ExpiryDate < GETUTCDATE()
		And ContentItem_Guid = @ContentItemGuid;

	SELECT	@ContentData_Guid = ContentData_Guid, @Approved = Approved, @ExpiryDate = ExpiryDate
	FROM	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;

	SELECT	ContentData_Version, Modified_Date, Intelledox_User.Username,
			Approved, ExpiryDate
	FROM	(SELECT	ContentData_Guid, 
				Modified_Date, 
				Modified_By, 
				ContentData_Version, 
				@Approved as Approved, 
				@ExpiryDate AS ExpiryDate
			FROM	ContentData_Binary
			UNION
			SELECT	ContentData_Guid, 
				Modified_Date, 
				Modified_By, 
				ContentData_Version, 
				Approved, 
				NULL AS ExpiryDate
			FROM	ContentData_Binary_Version
			UNION
			SELECT	ContentData_Guid, 
				Modified_Date, 
				Modified_By, 
				ContentData_Version, 
				@Approved as Approved, 
				@ExpiryDate AS ExpiryDate
			FROM	ContentData_Text
			UNION
			SELECT	ContentData_Guid, 
				Modified_Date, 
				Modified_By, 
				ContentData_Version, 
				Approved, 
				NULL AS ExpiryDate
			FROM	ContentData_Text_Version) Versions
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Versions.Modified_By
	WHERE	ContentData_Guid = @ContentData_Guid
	ORDER BY ContentData_Version DESC;
GO
CREATE PROCEDURE [dbo].[spLibrary_GetText] (
	@UniqueId as uniqueidentifier,
	@VersionNumber as varchar(50)
)
AS
	If @VersionNumber = '0'
	BEGIN
		SELECT	cd.ContentData as [Text] 
		FROM	ContentData_Text cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId;
	END
	ELSE
	BEGIN
		SELECT	cd.ContentData as [Text] 
		FROM	ContentData_Text cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId
				AND cd.ContentData_Version = @VersionNumber
		UNION ALL
		SELECT	cd.ContentData as [Text] 
		FROM	ContentData_Text_Version cd
				INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE	ContentItem_Guid = @UniqueId
				AND cd.ContentData_Version = @VersionNumber;
	END
GO
CREATE procedure [dbo].[spLibrary_RestoreVersion]
	@ContentItemGuid uniqueidentifier,
	@VersionNumber int,
	@UserGuid uniqueidentifier
AS
	SET NOCOUNT ON
	
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @IsBinary bit
	
	SELECT	@ContentData_Guid = ContentData_Guid, 
			@IsBinary = CASE WHEN ContentType_Id = 2 THEN 0 ELSE 1 END
	FROM	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;
		
	BEGIN TRAN	
	
	EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, @IsBinary;
	
	IF (@IsBinary = 1)
	BEGIN
		UPDATE	ContentData_Binary
		SET		ContentData = ContentData_Binary_Version.ContentData, 
				FileType = ContentData_Binary_Version.FileType,
				ContentData_Version = ContentData_Binary.ContentData_Version + 1, 
				Modified_Date = GetUTCdate(),
				Modified_By = @UserGuid
		FROM	ContentData_Binary, 
				ContentData_Binary_Version
		WHERE	ContentData_Binary.ContentData_Guid = @ContentData_Guid
				AND ContentData_Binary_Version.ContentData_Guid = @ContentData_Guid 
				AND	ContentData_Binary_Version.ContentData_Version = @VersionNumber;
	END
	ELSE
	BEGIN
		UPDATE	ContentData_Text
		SET		ContentData = ContentData_Text_Version.ContentData, 
				ContentData_Version = ContentData_Text.ContentData_Version + 1, 
				Modified_Date = GetUTCdate(),
				Modified_By = @UserGuid
		FROM	ContentData_Text, 
				ContentData_Text_Version
		WHERE	ContentData_Text.ContentData_Guid = @ContentData_Guid
				AND ContentData_Text_Version.ContentData_Guid = @ContentData_Guid 
				AND	ContentData_Text_Version.ContentData_Version = @VersionNumber;
	END
	
	EXEC spLibrary_ClearExcessVersions @ContentData_Guid, @IsBinary;
	
	UPDATE	Content_Item
	SET		IsIndexed = 0
	WHERE	ContentItem_Guid = @ContentItemGuid;
	
	DELETE	Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItemGuid;
		
	COMMIT
GO
CREATE PROCEDURE [dbo].[spLibrary_UpdateBinary] (
	@UniqueId as uniqueidentifier,
	@ContentData as image,
	@Extension as varchar(5),
	@UserGuid as uniqueidentifier
)
AS
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @ContentItem_Guid uniqueidentifier
	DECLARE @Approvals nvarchar(10)
	DECLARE @MaxVersion int
	DECLARE @CIApproved int

	SET NOCOUNT ON;

	SELECT	@ContentData_Guid = ContentData_Guid, 
			@ContentItem_Guid = ContentItem_Guid,
			@CIApproved = Approved
	FROM	Content_Item
	WHERE	ContentItem_Guid = @UniqueId;
	
	SELECT	@Approvals = OptionValue
	FROM	Global_Options
	WHERE	OptionCode = 'REQUIRE_CONTENT_APPROVAL';


	IF (@Approvals = 'true')
	BEGIN
		IF @ContentData_Guid IS NULL OR NOT EXISTS(SELECT ContentData_Guid 
												FROM ContentData_Binary 
												WHERE	ContentData_Guid = @ContentData_Guid)
		BEGIN
			SET	@ContentData_Guid = newid();
			
			INSERT INTO ContentData_Binary(ContentData_Guid, ContentData, FileType, ContentData_Version, Modified_Date, Modified_By)
			VALUES (@ContentData_Guid, @ContentData, @Extension, 1, getUTCdate(), @UserGuid);

			UPDATE	Content_Item
			SET		ContentData_Guid = @ContentData_Guid,
					Approved = 0
			WHERE	ContentItem_Guid = @UniqueId;
		END
		ELSE
		BEGIN
			IF (@CIApproved = 0)
			BEGIN
				-- Content item hasnt been approved yet so we can replace it
				EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 1;
				
				UPDATE	ContentData_Binary
				SET		ContentData = @ContentData,
						FileType = @Extension,
						Modified_Date = getUTCdate(),
						Modified_By = @UserGuid,
						ContentData_Version = ContentData_Version + 1
				WHERE	ContentData_Guid = @ContentData_Guid;

				-- Expire old unapproved versions
				UPDATE	ContentData_Binary_Version
				SET		Approved = 1
				WHERE	ContentData_Guid = @ContentData_Guid
						AND Approved = 0;
			END
			ELSE
			BEGIN
				SELECT	@MaxVersion = MAX(ContentData_Version)
				FROM	(SELECT ContentData_Version
						FROM	ContentData_Binary_Version
						WHERE	ContentData_Guid = @ContentData_Guid
						UNION
						SELECT	ContentData_Version
						FROM	ContentData_Binary
						WHERE	ContentData_Guid = @ContentData_Guid) Versions

				-- Expire old unapproved versions
				UPDATE	ContentData_Binary_Version
				SET		Approved = 1
				WHERE	ContentData_Guid = @ContentData_Guid
						AND Approved = 0;
			
				-- Insert new unapproved version
				INSERT INTO ContentData_Binary_Version(ContentData_Guid, ContentData, FileType, ContentData_Version, Modified_Date, Modified_By, Approved)
				VALUES (@ContentData_Guid, @ContentData, @Extension, IsNull(@MaxVersion, 0) + 1, getUTCdate(), @UserGuid, 0);
			END
							
			EXEC spLibrary_ClearExcessVersions @ContentData_Guid, 1;
		END
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT ContentData_Guid FROM ContentData_Binary WHERE ContentData_Guid = @ContentData_Guid)
		BEGIN
			EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 1;
			
			UPDATE	ContentData_Binary
			SET		ContentData = @ContentData,
					FileType = @Extension
			WHERE	ContentData_Guid = @ContentData_Guid;
		END
		ELSE
		BEGIN
			IF @ContentItem_Guid IS NOT NULL
			BEGIN
				SET	@ContentData_Guid = newid();

				INSERT INTO ContentData_Binary(ContentData_Guid, ContentData, FileType, ContentData_Version)
				VALUES (@ContentData_Guid, @ContentData, @Extension, 0);

				UPDATE	Content_Item
				SET		ContentData_Guid = @ContentData_Guid
				WHERE	ContentItem_Guid = @UniqueId;
			END
		END
		
		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE	ContentData_Binary
			SET		Modified_Date = getUTCdate(),
					Modified_By = @UserGuid,
					ContentData_Version = ContentData_Version + 1
			WHERE	ContentData_Guid = @ContentData_Guid;
		END
	END

	DELETE	FROM Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItem_Guid;
	
	UPDATE	Content_Item
	SET		IsIndexed = 0
	WHERE	ContentItem_Guid = @ContentItem_Guid;
GO
CREATE PROCEDURE [dbo].[spLibrary_UpdateBinaryByDataGuid] (
	@DataGuid as uniqueidentifier,
	@ContentData as image,
	@Extension as varchar(5)
)
AS
	DECLARE @ContentItem_Guid uniqueidentifier

	SELECT	@ContentItem_Guid = ContentItem_Guid
	FROM	Content_Item
	WHERE	ContentData_Guid = @DataGuid;
	
	IF EXISTS(SELECT ContentData_Guid FROM ContentData_Binary WHERE ContentData_Guid = @DataGuid)
	BEGIN
		UPDATE	ContentData_Binary
		SET		ContentData = @ContentData,
				FileType = @Extension
		WHERE	ContentData_Guid = @DataGuid;
	END
	ELSE
	BEGIN
		INSERT INTO ContentData_Binary(ContentData_Guid, ContentData, FileType)
		VALUES (@DataGuid, @ContentData, @Extension);
	END
		
	DELETE	FROM Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItem_Guid;
	
	UPDATE	Content_Item
	SET		IsIndexed = 0
	WHERE	ContentItem_Guid = @ContentItem_Guid;
GO
CREATE PROCEDURE [dbo].[spLibrary_UpdateText] (
	@UniqueId as uniqueidentifier,
	@ContentData as nvarchar(max),
	@UserGuid as uniqueidentifier
)
AS
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @Approvals nvarchar(10)
	DECLARE @MaxVersion int

	SELECT	@ContentData_Guid = ContentData_Guid
	FROM	Content_Item
	WHERE	ContentItem_Guid = @UniqueId
	
	SELECT	@Approvals = OptionValue
	FROM	Global_Options
	WHERE	OptionCode = 'REQUIRE_CONTENT_APPROVAL';


	IF (@Approvals = 'true')
	BEGIN
		IF @ContentData_Guid IS NULL OR NOT EXISTS(SELECT ContentData_Guid 
												FROM ContentData_Text 
												WHERE	ContentData_Guid = @ContentData_Guid)
		BEGIN
			SET	@ContentData_Guid = newid();
			
			INSERT INTO ContentData_Text(ContentData_Guid, ContentData, ContentData_Version, Modified_Date, Modified_By)
			VALUES (@ContentData_Guid, @ContentData, 1, getUTCdate(), @UserGuid)

			UPDATE	Content_Item
			SET		ContentData_Guid = @ContentData_Guid,
					Approved = 0
			WHERE	ContentItem_Guid = @UniqueId;
		END
		ELSE
		BEGIN
			SELECT	@MaxVersion = MAX(ContentData_Version)
			FROM	(SELECT ContentData_Version
					FROM	ContentData_Text_Version
					WHERE	ContentData_Guid = @ContentData_Guid
					UNION
					SELECT	ContentData_Version
					FROM	ContentData_Text
					WHERE	ContentData_Guid = @ContentData_Guid) Versions

			-- Expire old unapproved versions
			UPDATE	ContentData_Text_Version
			SET		Approved = 1
			WHERE	ContentData_Guid = @ContentData_Guid
					AND Approved = 0;
		
			-- Insert new unapproved version
			INSERT INTO ContentData_Text_Version(ContentData_Guid, ContentData, ContentData_Version, Modified_Date, Modified_By, Approved)
			VALUES (@ContentData_Guid, @ContentData, IsNull(@MaxVersion, 0) + 1, getUTCdate(), @UserGuid, 0);
			
			EXEC spLibrary_ClearExcessVersions @ContentData_Guid, 0;
		END
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT ContentData_Guid FROM ContentData_Text WHERE ContentData_Guid = @ContentData_Guid)
		BEGIN
			EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 0;
			
			UPDATE	ContentData_Text
			SET		ContentData = @ContentData
			WHERE	ContentData_Guid = @ContentData_Guid
		END
		ELSE
		BEGIN
			SET	@ContentData_Guid = newid()

			INSERT INTO ContentData_Text(ContentData_Guid, ContentData, ContentData_Version)
			VALUES (@ContentData_Guid, @ContentData, 0)

			UPDATE	Content_Item
			SET		ContentData_Guid = @ContentData_Guid
			WHERE	ContentItem_Guid = @UniqueId
		END
		
		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE	ContentData_Text
			SET		Modified_Date = getUTCdate(),
					Modified_By = @UserGuid,
					ContentData_Version = ContentData_Version + 1
			WHERE	ContentData_Guid = @ContentData_Guid;
		END
	END
GO
CREATE PROCEDURE [dbo].[spLicense_LicenseKeyList] 
	@LicenseKeyId int = 0,
	@ErrorCode int output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @LicenseKeyId = 0
	BEGIN
	    SELECT * FROM License_Key;
	END
	ELSE
	BEGIN
		SELECT * FROM License_Key
		WHERE LicenseKeyId = @LicenseKeyId;
	END
END
GO
CREATE PROCEDURE [dbo].[spLicense_RemoveLicenseKey] 
	@LicenseKeyId int = 0,
	@ErrorCode int output
AS
BEGIN
	SET NOCOUNT ON;

	DELETE dbo.License_Key
	WHERE LicenseKeyId = @LicenseKeyId
END
GO
CREATE PROCEDURE [dbo].[spLicense_UpdateLicenseKey] 
	@LicenseKeyId int output,
	@LicenseKey varchar(1000),
	@IsProductKey char(1),
	@ErrorCode int output
AS
BEGIN
	SET NOCOUNT ON;

	IF @IsProductKey IS NULL
		SET @IsProductKey = '0';
	
	IF @IsProductKey <> '0'
		SET @IsProductKey = '1';

	IF @IsProductKey = '1' AND @LicenseKeyId = 0 AND (select count(*) from dbo.License_Key where IsProductKey = '1') > 0
		SELECT @LicenseKeyId = LicenseKeyId
		FROM dbo.License_Key
		WHERE IsProductKey = '1';

	if @LicenseKeyId = 0
	begin
		if (select count(*) from dbo.License_Key where LicenseKey = @LicenseKey) = 0
		begin
			if @IsProductKey = '1'
				update dbo.License_Key set IsProductKey = '0';

			insert into dbo.License_Key(LicenseKey, IsProductKey)
			values (@LicenseKey, @IsProductKey);

			select @LicenseKeyId = @@IDENTITY;
		end
	end
	else
	begin
		if (select count(*) from dbo.License_Key where LicenseKey = @LicenseKey) = 0
		begin
			if @IsProductKey = '1'
				update dbo.License_Key set IsProductKey = '0';

			update dbo.License_Key
			set LicenseKey = @LicenseKey, IsProductKey = @IsProductKey
			where LicenseKeyId = @LicenseKeyId;
		end
	end
END
GO
CREATE PROCEDURE [dbo].[spLog_ClearUnfinished]
	@UserGuid uniqueidentifier
AS
	DECLARE @UserId INT;
	
	SET NOCOUNT ON;
	
	SET @UserId = (SELECT User_Id FROM Intelledox_User WHERE User_Guid = @UserGuid);
	
	UPDATE	Template_Log
	SET		InProgress = 0
	WHERE	User_Id = @UserId;
GO
CREATE PROCEDURE [dbo].[spLog_CompleteProjectLog]
	@LogGuid uniqueidentifier,
	@MessageXml xml = null
AS
	DECLARE @FinishDate datetime;
	
	SET @FinishDate = GetDate();
	
	UPDATE	Template_Log 
	SET		DateTime_Finish = @FinishDate, 
			Completed = 1,
			Messages = @MessageXml,
			InProgress = 0
	WHERE	Log_Guid = @LogGuid;
GO
CREATE PROCEDURE [dbo].[spLog_InsertBookmarkGroupLog]
	@LogGuid uniqueidentifier,
	@BookmarkGroupGuid uniqueidentifier,	
	@ErrorCode int output
AS

	if not exists(SELECT * FROM Bookmark_Group_Log WHERE Log_Guid = @LogGuid AND Bookmark_Group_Guid = @BookmarkGroupGuid)
		insert into Bookmark_Group_Log (Log_Guid, Bookmark_Group_Guid, TimeTaken)
		values (@LogGuid, @BookmarkGroupGuid, NULL)

	set @ErrorCode = @@Error
GO
CREATE procedure [dbo].[spLog_InsertTemplateLog]
	@LogGuid uniqueidentifier,
	@UserGuid uniqueidentifier,	
	@TemplateGroupGuid uniqueidentifier,
	@StartTime datetime,
	@AnswerFileUsed bit,
	@AnswerFile xml,
	@UpdateRecent bit = 0
AS
	DECLARE @UserId INT;
	DECLARE @TemplateGroupId INT;
	
	SET NOCOUNT ON;
	
	SET @UserId = (SELECT User_Id FROM Intelledox_User WITH (NOLOCK) WHERE User_Guid = @UserGuid);
	SET	@TemplateGroupId = (SELECT Template_Group_Id FROM Template_Group WITH (NOLOCK) WHERE Template_Group_Guid = @TemplateGroupGuid);
	
	IF @LogGuid IS NULL
		SET @LogGuid = newid();

	--Add to log
	INSERT INTO Template_Log WITH (ROWLOCK) (Log_Guid, [User_ID], Template_Group_ID, DateTime_Start, Completed, Answer_File_Used, InProgress, Answer_File)
	VALUES (@LogGuid, @UserID, @TemplateGroupID, @StartTime, 0, @AnswerFileUsed, 1, @AnswerFile);

	--Add to recent
	If @UpdateRecent = 1
	BEGIN
		IF EXISTS (SELECT * FROM Template_Recent WHERE User_Guid = @UserGuid AND Template_Group_Guid = @TemplateGroupGuid)
		BEGIN
			--Update time ran
			UPDATE	Template_Recent
			SET		DateTime_Start = @StartTime,
					Log_Guid = @LogGuid
			WHERE	User_Guid = @UserGuid 
					AND Template_Group_Guid = @TemplateGroupGuid;
		END
		ELSE
		BEGIN
			IF ((SELECT COUNT(*) FROM Template_Recent WHERE User_Guid = @UserGuid) = 5)
			BEGIN
				--Remove oldest recent record
				DELETE Template_Recent
				WHERE DateTime_Start = (SELECT MIN(DateTime_Start)
					FROM	Template_Recent
					WHERE	User_Guid = @UserGuid)
					AND User_Guid = @UserGuid;
			END
			
			INSERT INTO Template_Recent(User_Guid, DateTime_Start, Template_Group_Guid, Log_Guid)
			VALUES (@UserGuid, @StartTime, @TemplateGroupGuid, @LogGuid);
		END
	END
GO
CREATE PROCEDURE [dbo].[spLog_LastUnfinished]
	@UserGuid uniqueidentifier
AS
	DECLARE @UserId INT;
	
	SET NOCOUNT ON;
	
	SET @UserId = (SELECT User_Id FROM Intelledox_User WHERE User_Guid = @UserGuid);
	
	SELECT	Log_Guid
	FROM	Template_Log
	WHERE	DateTime_Start = (
		SELECT	MAX(DateTime_Start)
		FROM	Template_Log
		WHERE	User_Id = @UserId
				AND InProgress = 1
				AND Answer_File IS NOT NULL)
		AND User_Id = @UserId;
GO
CREATE procedure [dbo].[spLog_TemplateLogList]
	@LogGuid varchar(50) = '',
	@ErrorCode int output
as
	SELECT	Template_Log.*, Template_Group.Template_Group_Guid, Intelledox_User.User_Guid
	FROM	Template_Log
			INNER JOIN Template_Group ON Template_Log.Template_Group_Id = Template_Group.Template_Group_Id
			INNER JOIN Intelledox_User ON Template_Log.User_Id = Intelledox_User.User_Id
	WHERE	Template_Log.Log_Guid = @LogGuid;
	
	set @ErrorCode = @@error
GO
CREATE PROCEDURE [dbo].[spLog_UpdateBookmarkGroupLog]
	@LogGuid uniqueidentifier,
	@BookmarkGroupGuid uniqueidentifier,
	@TimeTaken int,
	@ErrorCode int output
AS
	declare @OriginalTimeTaken int

	select @OriginalTimeTaken = TimeTaken
	from Bookmark_Group_Log
	where Log_Guid = @LogGuid AND Bookmark_Group_Guid = @BookmarkGroupGuid

	if @OriginalTimeTaken is not null
		set @TimeTaken = @TimeTaken + @OriginalTimeTaken

	if @TimeTaken < 1
		set @TimeTaken = 1

	update Bookmark_Group_Log 
	set	TimeTaken = @TimeTaken
	where Log_Guid = @LogGuid AND Bookmark_Group_Guid = @BookmarkGroupGuid

	update Template_Log
	set Last_Bookmark_Group_Guid = @BookmarkGroupGuid
	where Log_Guid = @LogGuid

	set @ErrorCode = @@Error
GO
CREATE PROCEDURE [dbo].[spLog_UpdateTemplateLog]
	@LogGuid uniqueidentifier,
	@LastGroupGuid uniqueidentifier,
	@AnswerFile xml
AS
	UPDATE	Template_Log WITH (ROWLOCK, UPDLOCK)
	SET		Answer_File = @AnswerFile,
			Last_Bookmark_Group_Guid = @LastGroupGuid
	WHERE	Log_Guid = @LogGuid;
GO
CREATE procedure [dbo].[spOptions_LoadOptions]
	@OptionID int = 0,
	@Code nvarchar(255) = '',
	@ErrorCode int output
as
	select *
	from global_options
	where (@OptionID = 0 or @OptionID = optionid)
	and (@Code = '' or @Code = optioncode)

	select @ErrorCode = @@error
GO
create procedure [dbo].[spOptions_RemoveOption]
	@OptionID int,
	@ErrorCode int output
as
	delete global_options where optionid = @OptionID

	select @ErrorCode = @@error
GO
create procedure [dbo].[spOptions_UpdateOption]
	@OptionID int,
	@Code nvarchar(255),
	@Description nvarchar(1000),
	@Value nvarchar(4000),
	@NewID int output,
	@ErrorCode int output
as
	if @OptionID = 0
	begin
		--insert
		insert into global_options (OptionCode, OptionDescription, OptionValue)
		values (@Code, @Description, @Value)

		select @NewId = @@Identity
	end
	else
	begin
		--update
		update global_options
		set optioncode = @Code, optiondescription = @Description, optionvalue = @Value
		where optionid = @OptionID
	end

	select @ErrorCode = @@error
GO
create procedure [dbo].[spOptions_UpdateOptionValue]
	@Code nvarchar(255),
	@Value nvarchar(4000)
as
	UPDATE	global_options
	SET		optionvalue = @Value
	WHERE optioncode = @Code;
GO
CREATE procedure [dbo].[spProject_AddNewProjectVersion]
	@ProjectGuid uniqueidentifier,
	@NextVersion nvarchar(10)
AS
	BEGIN TRAN

		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Project_Definition,
			Comment,
			IsMajorVersion,
			FeatureFlags)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,
			Template.Modified_By,
			Template.Project_Definition,
			Template.Comment,
			Template.IsMajorVersion,
			Template.FeatureFlags
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File_Version (Template_Guid, File_Guid, Template_Version, [Binary],
				FormatTypeId)
		SELECT	Template.Template_Guid, Template_File.File_Guid, Template.Template_Version, 
				Template_File.[Binary], Template_File.FormatTypeId
		FROM	Template
				INNER JOIN Template_File ON Template.Template_Guid = Template_File.Template_Guid
		WHERE	Template.Template_Guid = @ProjectGuid;
		
		--delete the earliest minor version which does not belong to the next version number
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
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
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
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
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
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
				
		DELETE FROM Template_File_Version
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	Template_Version
					WHERE	Template_Guid = @ProjectGuid);
	COMMIT
GO
CREATE PROCEDURE [dbo].[spProject_Binary] (
	@TemplateGuid uniqueidentifier,
	@FileGuid uniqueidentifier,
	@VersionNumber nvarchar(10) = '0'
)
AS
	If @VersionNumber = '0'
	BEGIN
		SELECT	[Binary]  
		FROM	Template_File
		WHERE	Template_Guid = @TemplateGuid
				AND File_Guid = @FileGuid;
	END
	ELSE
	BEGIN
		SELECT	Template_File.[Binary]  
		FROM	Template_File
				INNER JOIN Template ON Template.Template_Guid = Template_File.Template_Guid
		WHERE	Template.Template_Guid = @TemplateGuid
			AND Template.Template_Version = @VersionNumber
				AND Template_File.File_Guid = @FileGuid
		UNION ALL
		SELECT	[Binary]  
		FROM	Template_File_Version
		WHERE	Template_Guid = @TemplateGuid
			AND Template_Version = @VersionNumber
				AND File_Guid = @FileGuid;
	END
GO
CREATE PROCEDURE [dbo].[spProject_Definition] (
	@TemplateGuid uniqueidentifier,
	@VersionNumber nvarchar(10) = '0'
)
AS
	If @VersionNumber = '0'
	BEGIN
		SELECT	Project_Definition 
		FROM	Template 
		WHERE	Template_Guid = @TemplateGuid;
	END
	ELSE
	BEGIN
		SELECT Project_Definition 
		FROM	Template 
		WHERE	Template_Guid = @TemplateGuid
			AND Template_Version = @VersionNumber
		UNION ALL
		SELECT	Project_Definition 
		FROM	Template_Version
		WHERE	Template_Guid = @TemplateGuid
			AND Template_Version = @VersionNumber;
	END
GO
CREATE PROCEDURE [dbo].[spProject_DefinitionsByGroup] (
	@TemplateGroupGuid uniqueidentifier
)
AS
		SELECT	Template.Template_Guid, 
			Template.Project_Definition, 
			Template.Template_Type_ID
		FROM	Template_Group
				INNER JOIN Template ON (Template_Group.Template_Guid = Template.Template_Guid 
						AND (Template_Group.Template_Version IS NULL
							OR Template_Group.Template_Version = Template.Template_Version))
					OR (Template_Group.Layout_Guid = Template.Template_Guid
						AND (Template_Group.Layout_Version IS NULL
							OR Template_Group.Layout_Version = Template.Template_Version))
		WHERE	Template_Group.Template_Group_Guid = @TemplateGroupGuid
	UNION ALL
		SELECT	Template_Version.Template_Guid, 
			Template_Version.Project_Definition, 
			Template.Template_Type_ID
		FROM	Template_Group
				INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
				INNER JOIN Template_Version ON (Template_Group.Template_Guid = Template_Version.Template_Guid 
						AND Template_Group.Template_Version = Template_Version.Template_Version)
					OR (Template_Group.Layout_Guid = Template_Version.Template_Guid
						AND Template_Group.Layout_Version = Template_Version.Template_Version)
		WHERE	Template_Group.Template_Group_Guid = @TemplateGroupGuid
	ORDER BY Template_Type_ID;
GO
CREATE PROCEDURE [dbo].[spProject_GetBinaries] (
	@TemplateGuid uniqueidentifier,
	@VersionNumber nvarchar(10) = '0'
)
AS
	If @VersionNumber = '0'
	BEGIN
		SELECT	[Binary], File_Guid, FormatTypeId
		FROM	Template_File
		WHERE	Template_Guid = @TemplateGuid;
	END
	ELSE
	BEGIN
		SELECT	Template_File.[Binary], Template_File.File_Guid, Template_File.FormatTypeId
		FROM	Template_File
				INNER JOIN Template ON Template.Template_Guid = Template_File.Template_Guid
		WHERE	Template.Template_Guid = @TemplateGuid
			AND Template.Template_Version = @VersionNumber
		UNION ALL
		SELECT	[Binary], File_Guid, FormatTypeId
		FROM	Template_File_Version
		WHERE	Template_Guid = @TemplateGuid
			AND Template_Version = @VersionNumber;
	END
GO
CREATE procedure [dbo].[spProject_GetFoldersByProject]
	@ProjectGuid uniqueidentifier
AS
	SELECT	Folder.Folder_Name, Folder.Folder_Guid, Template_Group.Template_Group_Guid,
			Template.Template_Type_ID
	FROM	Folder
			INNER JOIN Template_Group on Folder.Folder_Guid = Template_Group.Folder_Guid
			INNER JOIN Template on Template_Group.Template_Guid = Template.Template_Guid
	WHERE	Template.Template_Guid = @ProjectGuid
	ORDER BY Folder.Folder_Name;
GO
CREATE procedure [dbo].[spProject_GetProjectsByContentDefinition]
	@ContentGuid varchar(40),
	@BusinessUnitGuid uniqueidentifier
as
	SET ARITHABORT ON 

	SELECT 	Template.template_id, 
			Template.[name] as project_name, 
			Template.template_type_id, 
			Template.fax_template_id, 
			Template.template_guid, 
			Template.template_version, 
			Template.import_date,
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
CREATE procedure [dbo].[spProject_GetProjectsByContentItem]
	@ContentGuid varchar(40),
	@BusinessUnitGuid uniqueidentifier
as
	SET ARITHABORT ON 

	SELECT 	Template.template_id, 
			Template.[name] as project_name, 
			Template.template_type_id, 
			Template.fax_template_id, 
			Template.template_guid, 
			Template.template_version, 
			Template.import_date,
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
CREATE procedure [dbo].[spProject_GetProjectVersions]
	@ProjectGuid uniqueidentifier
as
		SELECT vwTemplateVersion.Template_Version, 
			vwTemplateVersion.Modified_Date,
			vwTemplateVersion.Username,
			vwTemplateVersion.Comment,
			vwTemplateVersion.LockedByUserGuid,
			vwTemplateVersion.InUse
		FROM	vwTemplateVersion
		WHERE	vwTemplateVersion.Template_Guid = @ProjectGuid
	ORDER BY Modified_Date DESC;
GO
CREATE procedure [dbo].[spProject_ProjectList]
	@UserGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ProjectTypeId int,
	@SearchString nvarchar(100),
	@Purpose nvarchar(10)
as
	declare @IsGlobal bit
	declare @BusinessUnitGUID uniqueidentifier

	SELECT	@BusinessUnitGUID = Business_Unit_GUID
	FROM	Intelledox_User
	WHERE	User_Guid = @UserGuid;

	IF EXISTS(SELECT	vwUserPermissions.*
		FROM	vwUserPermissions
		WHERE	((@Purpose = 'Design' AND vwUserPermissions.CanDesignProjects = 1)
					OR (@Purpose = 'Publish' AND vwUserPermissions.CanPublishProjects = 1))
				AND vwUserPermissions.GroupGuid IS NULL
				AND vwUserPermissions.UserGuid = @UserGuid)
	BEGIN
		SET @IsGlobal = 1;
	END

	if @GroupGuid IS NULL
	begin
		--all usergroups
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, a.template_version, a.import_date, 
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Content_Bookmark, a.Modified_By, lockedByUser.Username AS LockedBy,
				a.FeatureFlags
		FROM	Template a
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
			LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		WHERE	(@IsGlobal = 1 or a.Template_Guid in (
				SELECT	User_Group_Template.TemplateGuid
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid
				WHERE	((@Purpose = 'Design' AND vwUserPermissions.CanDesignProjects = 1)
					OR (@Purpose = 'Publish' AND vwUserPermissions.CanPublishProjects = 1))
			AND Intelledox_User.User_Guid = @UserGuid
				))
			AND (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
		ORDER BY a.[name];
	end
	else
	begin
		--specific user group
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, a.template_version, a.import_date, 
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Content_Bookmark, a.Modified_By, lockedByUser.Username AS LockedBy,
				a.FeatureFlags
		FROM	Template a
				INNER JOIN User_Group_Template d on a.Template_Guid = d.TemplateGuid
				INNER JOIN User_Group ON d.GroupGuid = User_Group.Group_Guid AND User_Group.Group_Guid = @GroupGuid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		WHERE	(@IsGlobal = 1 or a.template_Guid in (
				SELECT	User_Group_Template.TemplateGuid
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid
				WHERE	((@Purpose = 'Design' AND vwUserPermissions.CanDesignProjects = 1)
					OR (@Purpose = 'Publish' AND vwUserPermissions.CanPublishProjects = 1))
			))
			and (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
		ORDER BY a.[name];
	end
GO
CREATE procedure [dbo].[spProject_RemoveBinaries]
	@ProjectGuid uniqueidentifier
as
	DELETE FROM Template_File
	WHERE Template_Guid = @ProjectGuid;
GO
CREATE PROCEDURE [dbo].[spProject_RemoveStyles] (
	@ProjectGuid uniqueidentifier)
AS
	DELETE FROM	Template_Styles
	WHERE ProjectGuid = @ProjectGuid;
GO
CREATE procedure [dbo].[spProject_RestoreVersion]
	@ProjectGuid uniqueidentifier,
	@VersionNumber nvarchar(10),
	@UserGuid uniqueidentifier,
	@RestoreVersionComment nvarchar(50),
	@NextVersion nvarchar(10)
as
	SET NOCOUNT ON

	BEGIN TRAN	
	
		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Project_Definition,
			Comment,
			IsMajorVersion,
			FeatureFlags)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,	
			Template.Modified_By,
			Template.Project_Definition,
			Template.Comment,
			Template.IsMajorVersion,
			Template.FeatureFlags
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
			
		INSERT INTO Template_File_Version (Template_Guid, File_Guid, Template_Version, [Binary],
				FormatTypeId)
		SELECT	Template.Template_Guid, Template_File.File_Guid, Template.Template_Version, 
				Template_File.[Binary], Template_File.FormatTypeId
		FROM	Template
				INNER JOIN Template_File ON Template.Template_Guid = Template_File.Template_Guid
		WHERE	Template.Template_Guid = @ProjectGuid;
					
		DECLARE @ProjectDefinition xml,
				@FeatureFlags int

		SELECT	@ProjectDefinition = Project_Definition,
				@FeatureFlags = FeatureFlags
		FROM	Template_Version 
		WHERE	Template_Guid = @ProjectGuid 
				AND Template_Version = @VersionNumber

		UPDATE	Template
		SET		Project_Definition = @ProjectDefinition, 
				Template_Version = @NextVersion, 
				Comment = @RestoreVersionComment,
				Modified_Date = GetUTCdate(),
				Modified_By = @UserGuid,
				IsMajorVersion = 1,
				FeatureFlags = @FeatureFlags
		WHERE	Template_Guid = @ProjectGuid;
		
		DELETE FROM Template_File
		WHERE	Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File(Template_Guid, File_Guid, [Binary], FormatTypeId)
		SELECT	@ProjectGuid, Template_File_Version.File_Guid, Template_File_Version.[Binary],
				Template_File_Version.FormatTypeId
		FROM	Template_File_Version 
		WHERE	Template_Guid = @ProjectGuid 
				AND Template_Version = @VersionNumber; 
				
		--delete the earliest minor version which does not belong to the next version number
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
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
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
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
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
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
			
		DELETE FROM Template_File_Version
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	Template_Version
					WHERE	Template_Guid = @ProjectGuid);
				
	COMMIT
GO
CREATE PROCEDURE [dbo].[spProject_StylesList] (
	@ProjectGuid uniqueidentifier)
AS
	SELECT	*
	FROM	Template_Styles
	WHERE	ProjectGuid = @ProjectGuid;
GO
CREATE PROCEDURE [dbo].[spProject_TryLockProject]
	@ProjectGuid uniqueidentifier,
	@UserGuid uniqueidentifier
	
AS

	BEGIN TRAN
	
		--check for a deleted project
		IF NOT EXISTS(SELECT 1 FROM Template WHERE Template_Guid = @ProjectGuid) 
			SELECT ''
		ELSE
		BEGIN
			IF EXISTS(SELECT 1 FROM Template WHERE Template_Guid = @ProjectGuid AND LockedByUserGuid IS NULL)
			BEGIN
				UPDATE	Template
				SET		LockedByUserGuid = @UserGuid
				WHERE	Template_Guid = @ProjectGuid;
				
				SELECT ''				
			END
			ELSE
			BEGIN
				SELECT	Username 
				FROM	Intelledox_User 
						INNER JOIN Template ON Intelledox_User.User_Guid = Template.LockedByUserGuid
				WHERE	Template_Guid = @ProjectGuid						
			END
		END
		
	COMMIT
GO
CREATE PROCEDURE [dbo].[spProject_UnlockProject]
	@ProjectGuid uniqueidentifier,
	@VersionComment text = '',
	@UserGuid uniqueidentifier,
	@ForceUnlock bit
AS

	BEGIN TRAN
	
		--allows unlock either by any user if its a force unlock OR by the same user who has currently locked the project if general unlock
		IF @ForceUnlock = 1 OR (@ForceUnlock = 0 AND EXISTS(SELECT LockedByUserGuid FROM Template WHERE Template_Guid = @ProjectGuid AND LockedByUserGuid = @UserGuid))
		BEGIN
			IF EXISTS(SELECT Comment FROM Template WHERE Template_Guid = @ProjectGuid AND LEN(Comment) > 0) AND DATALENGTH(@VersionComment) = 0
			BEGIN
				UPDATE	Template
				SET		LockedByUserGuid = NULL,
						IsMajorVersion = 1
				WHERE	Template_Guid = @ProjectGuid;
			END
			ELSE
			BEGIN
				UPDATE	Template
				SET		LockedByUserGuid = NULL,
						Comment = @VersionComment,
						IsMajorVersion = 1
				WHERE	Template_Guid = @ProjectGuid;
			END
		END

	COMMIT
GO
CREATE PROCEDURE [dbo].[spProject_UpdateBinary] (
	@Bytes image,
	@TemplateGuid uniqueidentifier,
	@FileGuid uniqueidentifier,
	@FormatType varchar(6)
)
AS
	IF EXISTS(SELECT File_Guid FROM Template_File WHERE Template_Guid = @TemplateGuid AND File_Guid = @FileGuid)
	BEGIN
		UPDATE	Template_File
		SET		[Binary] = @Bytes,
				FormatTypeId = @FormatType
		WHERE	Template_Guid = @TemplateGuid
				AND File_Guid = @FileGuid;
	END
	ELSE
	BEGIN
		INSERT INTO Template_File(Template_Guid, File_Guid, [Binary], FormatTypeId)
		VALUES (@TemplateGuid, @FileGuid, @Bytes, @FormatType);
	END
GO
CREATE PROCEDURE [dbo].[spProject_UpdateDefinition] (
	@Xtf xml,
	@TemplateGuid uniqueidentifier
)
AS
	DECLARE @FeatureFlags int;

	BEGIN TRAN
		-- Feature detection --
		SET @FeatureFlags = 0

		-- Workflow
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/Workflow)') as ProjectXML(P))
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 1;
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

		-- Address
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 1)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 16;
		END

		-- Sign off
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 5)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 32;
		END

		-- Rich text
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 19)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 64;
		END
				
		UPDATE	Template 
		SET		Project_Definition = @XTF,
				FeatureFlags = @FeatureFlags
		WHERE	Template_Guid = @TemplateGuid;
	COMMIT
GO
CREATE procedure [dbo].[spProject_UpdateProject]
	@BusinessUnitGuid uniqueidentifier,
	@Name nvarchar(100),
	@ProjectGuid uniqueidentifier,
	@ProjectTypeID int,
	@SupplierGuid uniqueidentifier,
	@ContentBookmark nvarchar(100),
	@NextVersion nvarchar(10) = '0',
	@UserGuid uniqueidentifier = NULL
as
	BEGIN TRAN

		IF NOT EXISTS(SELECT Template_Guid FROM Template WHERE Template_Guid = @ProjectGuid)
		BEGIN
			INSERT INTO Template(Business_Unit_Guid, Name, Template_Guid, 
				Template_Type_Id, Supplier_Guid, Content_Bookmark, Template_Version, IsMajorVersion)
			VALUES (@BusinessUnitGuid, @Name, @ProjectGuid, 
				@ProjectTypeId, @SupplierGuid, @ContentBookmark, '0.0', 0);
		END
		ELSE
		BEGIN
		
			IF @UserGuid IS NOT NULL
			BEGIN
				EXEC spProject_AddNewProjectVersion @ProjectGuid, @NextVersion;
			END
		
			UPDATE	Template
			SET		[name] = @Name, 
					Template_type_id = @ProjectTypeID, 
					Supplier_GUID = @SupplierGuid,
					Content_Bookmark = @ContentBookmark
			WHERE	Template_Guid = @ProjectGuid;
		END

		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE Template
			SET Modified_Date = getUTCdate(),
				Modified_By = @UserGuid,
				Template_Version = @NextVersion,
				Comment = NULL,
				IsMajorVersion = 0
			WHERE Template_Guid = @ProjectGuid;
		END
	
	COMMIT
GO
CREATE PROCEDURE [dbo].[spProject_UpdateStyle] (
	@ProjectGuid uniqueidentifier,
	@Title nvarchar(100),
	@FontName nvarchar(100),
	@Size decimal,
	@FontColour int,
	@Bold bit,
	@Italic bit,
	@Underline bit)
AS
	INSERT INTO Template_Styles (ProjectGuid, Title, FontName, Size, FontColour, Bold, Italic, Underline)
	VALUES (@ProjectGuid, @Title, @FontName, @Size, @FontColour, @Bold, @Italic, @Underline);
GO
CREATE PROCEDURE [dbo].[spProjectGroup_FolderListAll]
	@UserGuid uniqueidentifier,
	@FolderSearch nvarchar(50),
	@ProjectSearch nvarchar(100)
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid;
	
	SELECT	DISTINCT a.*, d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, b.Template_ID, b.[Name] as Template_Name, 
			b.Template_Type_ID, d.Template_Group_Guid
	FROM	Folder a
			INNER JOIN Template_Group d on a.folder_Guid = d.Folder_Guid
			INNER JOIN Template b on d.Template_Guid = b.Template_Guid
	WHERE	a.Business_Unit_GUID = @BusinessUnitGUID
			AND a.Folder_Guid IN (
				SELECT	Folder_Group.FolderGuid
				FROM	Folder_Group
						INNER JOIN User_Group ON Folder_Group.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Subscription ON User_Group.Group_Guid = User_Group_Subscription.GroupGuid
						INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
				WHERE	Intelledox_User.User_Guid = @UserGuid
				)
			AND a.Folder_Name LIKE @FolderSearch + '%'
			AND CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END LIKE @ProjectSearch + '%'
			AND (d.EnforcePublishPeriod = 0 
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getdate())))
	ORDER BY a.Folder_Name, a.Folder_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END;
GO
CREATE procedure [dbo].[spProjectGroup_Recent]
	@UserGuid uniqueidentifier,
	@ProjectSearch nvarchar(100)
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid;
	
	SELECT	DISTINCT d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, b.Template_ID, b.[Name] as Template_Name, 
			b.Template_Type_ID, d.Template_Group_Guid, l.DateTime_Start, l.Log_Guid
	FROM	Folder a
			INNER JOIN Template_Group d on a.folder_Guid = d.Folder_Guid
			INNER JOIN Template b on d.Template_Guid = b.Template_Guid
			INNER JOIN Template_Recent l on d.Template_Group_Guid = l.Template_Group_Guid
	WHERE	a.Business_Unit_GUID = @BusinessUnitGUID
			AND a.Folder_Guid IN (
				SELECT	Folder_Group.FolderGuid
				FROM	Folder_Group
						INNER JOIN User_Group ON Folder_Group.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Subscription ON User_Group.Group_Guid = User_Group_Subscription.GroupGuid
						INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
				WHERE	Intelledox_User.User_Guid = @UserGuid
				)
			AND CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END LIKE @ProjectSearch + '%'
			AND l.[User_Guid] = @UserGuid
			AND (d.EnforcePublishPeriod = 0 
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getdate())))
	ORDER BY l.DateTime_Start DESC;
GO
CREATE procedure [dbo].[spProjectGrp_FolderList]
	@FolderGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier
AS
	IF @FolderGuid IS NULL
	BEGIN
		SELECT	*
		FROM	Folder
		WHERE	Business_Unit_Guid = @BusinessUnitGuid
		ORDER BY Folder_Name;
	END
	ELSE
	BEGIN
		SELECT	*
		FROM	Folder
		WHERE	Folder_Guid = @FolderGuid;
	END
GO
CREATE PROCEDURE [dbo].[spProjectGrp_IdToGuid]
	@id int
AS
	SELECT	Template_Group_Guid
	FROM	Template_Group
	WHERE	Template_Group_Id = @id;

GO
CREATE PROCEDURE [dbo].[spProjectGrp_ProjectCategoryList]
	@ProjectGuid uniqueidentifier
AS
	SELECT	Category.*
	FROM	Template a 
			INNER JOIN Template_Category b on a.Template_ID = b.Template_ID
			INNER JOIN Category ON b.Category_Id = Category.Category_Id
	WHERE	a.Template_Guid = @ProjectGuid;
GO
CREATE procedure [dbo].[spProjectGrp_ProjectGroupList]
      @ProjectGroupGuid uniqueidentifier
AS
    SELECT	a.Template_Group_ID, t.[Name] as Template_Group_Name, a.template_group_guid, 
			a.helptext as TemplateGroup_HelpText, a.Template_Guid, a.Layout_Guid,
			a.Template_Version, a.Layout_Version, a.AllowPreview, a.PostGenerateText,
			a.UpdateDocumentFields, a.EnforceValidation, a.WizardFinishText, 
			a.EnforcePublishPeriod, a.PublishStartDate, a.PublishFinishDate,
			a.HideNavigationPane
    FROM	Template_Group a
			INNER JOIN Template t on a.Template_Guid = t.Template_Guid
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;
GO
CREATE procedure [dbo].[spProjectGrp_ProjectGroupListByFolder]
	@FolderGuid uniqueidentifier,
	@IncludeRestricted bit
AS
	SELECT	d.Template_Group_ID, b.Name as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, d.Template_Group_Guid,
			b.Template_Guid, d.Layout_Guid
	FROM	Folder a
			INNER JOIN Template_Group d on a.folder_Guid = d.Folder_Guid
			INNER JOIN Template b on d.Template_Guid = b.Template_Guid
	WHERE	a.Folder_Guid = @FolderGuid
			AND ((d.EnforcePublishPeriod = 0 OR @IncludeRestricted = 1)
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getdate())))
	ORDER BY b.[Name], d.Template_Group_ID;
GO
CREATE procedure [dbo].[spProjectGrp_RemoveFolder]
	@FolderGuid uniqueidentifier
AS
	DECLARE @FolderID INT
	
	SET NOCOUNT ON
	
	SELECT	@FolderID = Folder_Id
	FROM	Folder
	WHERE	Folder_Guid = @FolderGuid;
	
	DELETE Template_Group 
	WHERE Folder_Guid = @FolderGuid;
	
	DELETE Folder WHERE Folder_ID = @FolderID;
GO
CREATE procedure [dbo].[spProjectGrp_RemoveProjectGroup]
	@ProjectGroupGuid uniqueidentifier
AS
	DELETE Template_Group WHERE Template_Group_Guid = @ProjectGroupGuid;
GO
CREATE procedure [dbo].[spProjectGrp_UpdateFolder]
	@FolderGuid uniqueidentifier,
	@Name nvarchar(100),
	@BusinessUnitGUID uniqueidentifier
AS
	IF EXISTS(SELECT * FROM Folder WHERE Folder_Guid = @FolderGuid)
	BEGIN
		UPDATE	Folder
		SET		folder_name = @Name
		WHERE	Folder_Guid = @FolderGuid;
	END
	ELSE
	BEGIN
		INSERT INTO Folder(Folder_Name, Business_Unit_GUID, Folder_Guid)
		VALUES (@Name, @BusinessUnitGUID, @FolderGuid)
	END
GO
CREATE PROCEDURE [dbo].[spProjectGrp_UpdateProjectGroup]
	@ProjectGroupGuid uniqueidentifier,
	@Name nvarchar(100),
	@HelpText nvarchar(4000),
	@AllowPreview bit,
	@WizardFinishText nvarchar(max),
	@PostGenerateText nvarchar(4000),
	@UpdateDocumentFields bit,
	@EnforceValidation bit,
	@HideNavigationPane bit,
	@EnforcePublishPeriod bit,
	@PublishStartDate datetime,
	@PublishFinishDate datetime,
	@ProjectGuid uniqueidentifier,
	@LayoutGuid uniqueidentifier,
	@ProjectVersion nvarchar(10),
	@LayoutVersion nvarchar(10),
	@FolderGuid uniqueidentifier
AS
	IF NOT EXISTS(SELECT * FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid)
	BEGIN
		INSERT INTO Template_Group ([name], template_group_guid, helptext, AllowPreview, PostGenerateText, 
				UpdateDocumentFields, EnforceValidation, WizardFinishText, EnforcePublishPeriod,
				PublishStartDate, PublishFinishDate, HideNavigationPane, Template_Guid, Layout_Guid,
				Template_Version, Layout_Version, Folder_Guid)
		VALUES (@Name, @ProjectGroupGuid, @HelpText, @AllowPreview, @PostGenerateText, 
				@UpdateDocumentFields, @EnforceValidation, @WizardFinishText, @EnforcePublishPeriod,
				@PublishStartDate, @PublishFinishDate, @HideNavigationPane, @ProjectGuid, @LayoutGuid,
				@ProjectVersion, @LayoutVersion, @FolderGuid);
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
				WizardFinishText = @WizardFinishText,
				EnforcePublishPeriod = @EnforcePublishPeriod,
				PublishStartDate = @PublishStartDate,
				PublishFinishDate = @PublishFinishDate,
				HideNavigationPane = @HideNavigationPane,
				Template_Guid = @ProjectGuid,
				Layout_Guid = @LayoutGuid,
				Template_Version = @ProjectVersion,
				Layout_Version = @LayoutVersion,
				Folder_Guid = @FolderGuid
		WHERE	Template_Group_Guid = @ProjectGroupGuid;
	END
GO
CREATE procedure [dbo].[spReport_LogicResponses]
	@TemplateId Int,
	@StartDate datetime,
	@FinishDate datetime,
	@DisplayText bit = 0
AS
	SET ARITHABORT ON 
	CREATE TABLE #Answers
	(
		Id int identity(1,1),
		AnswerGuid uniqueidentifier,
		QuestionGuid uniqueidentifier,
		AnswerName nvarchar(1000),
		Label nvarchar(100),
		QuestionName nvarchar(1000),
		PageName nvarchar(1000),
		QuestionTypeId int
	);

	CREATE TABLE #Responses
	(
		LogGuid uniqueidentifier,
		AnswerGuid uniqueidentifier,
		Value nvarchar(1000)
	);
	
	-- Finish date inclusive
	SET @FinishDate = DateAdd(d, 1, @FinishDate);

	INSERT INTO #Answers(QuestionGuid, AnswerGuid, AnswerName, Label, QuestionName, QuestionTypeId, PageName)
	SELECT	Q.value('@Guid', 'uniqueidentifier'),
			A.value('@Guid', 'uniqueidentifier'), 
			A.value('@Name', 'nvarchar(1000)'),
			A.value('@AnswerFileLabel', 'nvarchar(100)'),
			Q.value('@Text', 'nvarchar(1000)'),
			Q.value('@TypeId', 'int'),
			P.value('@Name', 'nvarchar(1000)')
	FROM	Template
			CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
			CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
			CROSS APPLY Q.nodes('(Answer)') as AnswerXml(A)
	WHERE	Template.Template_Id = @TemplateId;

	INSERT INTO #Responses(LogGuid, AnswerGuid, Value)
	SELECT	Template_Log.Log_Guid,
			#Answers.AnswerGuid, 
			C.value('@v', 'nvarchar(1000)')
	FROM	Template_Log 
			CROSS APPLY Answer_File.nodes('(/AnswerFile/ps/p/qs/q/as/a)') as ID(C)
			, #Answers
	WHERE	C.value('@aid', 'uniqueidentifier') = #Answers.AnswerGuid
			AND Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
			AND (#Answers.QuestionTypeId = 3	-- Group logic
				OR #Answers.QuestionTypeId = 6	-- Simple logic
				OR (#Answers.QuestionTypeId = 7 AND @DisplayText = 1))	-- User prompt
			AND Template_Log.Template_Group_Id IN
			(
				SELECT	tg.Template_Group_Id
				FROM	Template_Group tg
						INNER JOIN Template t ON tg.Template_Guid = t.Template_Guid
				WHERE	t.Template_Id = @TemplateId
			)
	UNION ALL
	SELECT	Template_Log.Log_Guid,
			#Answers.AnswerGuid, 
			C.value('@name', 'nvarchar(1000)')
	FROM	Template_Log 
			CROSS APPLY Answer_File.nodes('(/AnswerFile/AnswerLabels/Label)') as Label(C)
			, #Answers
	WHERE	C.value('@name', 'nvarchar(100)') = #Answers.Label
			AND Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
			AND (#Answers.QuestionTypeId = 3	-- Group logic
				OR #Answers.QuestionTypeId = 6	-- Simple logic
				OR (#Answers.QuestionTypeId = 7 AND @DisplayText = 1))	-- User prompt
			AND Template_Log.Template_Group_Id IN
			(
				SELECT	tg.Template_Group_Id
				FROM	Template_Group tg
						INNER JOIN Template t ON tg.Template_Guid = t.Template_Guid
				WHERE	t.Template_Id = @TemplateId
			);

	SELECT	#Answers.PageName,
			#Answers.QuestionTypeId,
			#Answers.QuestionName,
			#Answers.AnswerName,
			COUNT(CASE #Answers.QuestionTypeId 
				WHEN 3	-- Group Logic
				THEN CASE #Responses.Value WHEN '1' THEN '1' ELSE NULL END
				WHEN 6	-- Simple
				THEN CASE #Responses.Value WHEN '1' THEN '1' ELSE NULL END
				ELSE #Responses.Value
				END) as AnswerCount,
			(SELECT COUNT(DISTINCT #Responses.LogGuid) 
				FROM #Answers
				INNER JOIN #Answers ByQuestion ON #Answers.QuestionGuid = ByQuestion.QuestionGuid
				INNER JOIN #Responses ON ByQuestion.AnswerGuid = #Responses.AnswerGuid) as TotalQuestionResponses,
			(SELECT COUNT(DISTINCT #Responses.LogGuid) FROM #Responses) as TotalResponses,
			CASE WHEN #Answers.QuestionTypeId = 7 THEN #Responses.Value ELSE '' END as TextResponse
	FROM	#Answers
			LEFT JOIN #Responses ON #Answers.AnswerGuid = #Responses.AnswerGuid
	WHERE (#Answers.QuestionTypeId = 3	-- Group logic
			OR #Answers.QuestionTypeId = 6	-- Simple logic
			OR (#Answers.QuestionTypeId = 7 AND @DisplayText = 1))	-- User prompt
	GROUP BY #Answers.Id,
			#Answers.PageName,
			#Answers.QuestionTypeId,
			#Answers.QuestionName,
			#Answers.AnswerName,
			CASE WHEN #Answers.QuestionTypeId = 7 THEN #Responses.Value ELSE '' END
	ORDER BY #Answers.Id;

	DROP TABLE #Answers;
	DROP TABLE #Responses;
GO
CREATE procedure [dbo].[spReport_ResultsCSV]
	@TemplateId Int,
	@StartDate datetime,
	@FinishDate datetime
AS
	SET ARITHABORT ON 
	CREATE TABLE #Answers
	(
		Id int identity(1,1),
		AnswerGuid uniqueidentifier,
		AnswerName nvarchar(1000),
		Label nvarchar(100),
		QuestionName nvarchar(1000),
		PageName nvarchar(1000),
		QuestionTypeId int,
		QuestionId int
	);

	CREATE TABLE #Responses
	(
		LogGuid uniqueidentifier,
		AnswerGuid uniqueidentifier,
		Value nvarchar(1000),
		StartDate datetime,
		FinishDate datetime,
		UserId int
	);
	
	-- Finish date inclusive
	SET @FinishDate = DateAdd(d, 1, @FinishDate);

	INSERT INTO #Answers(AnswerGuid, AnswerName, Label, QuestionName, QuestionTypeId, PageName, QuestionID)
	SELECT	A.value('@Guid', 'uniqueidentifier'), 
			A.value('@Name', 'nvarchar(1000)'),
			A.value('@AnswerFileLabel', 'nvarchar(100)'),
			Q.value('@Text', 'nvarchar(1000)'),
			Q.value('@TypeId', 'int'),
			P.value('@Name', 'nvarchar(1000)'),
			Q.value('@ID', 'int')
	FROM	Template
			CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
			CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
			CROSS APPLY Q.nodes('(Answer)') as AnswerXml(A)
	WHERE	Template.Template_Id = @TemplateId;

	INSERT INTO #Responses(LogGuid, AnswerGuid, Value, StartDate, FinishDate, UserId)
	SELECT	Template_Log.Log_Guid,
			#Answers.AnswerGuid, 
			C.value('@v', 'nvarchar(1000)'),
			Template_Log.DateTime_Start,
			Template_Log.DateTime_Finish,
			Template_Log.User_Id
	FROM	Template_Log 
			CROSS APPLY Answer_File.nodes('(/AnswerFile/ps/p/qs/q/as/a)') as ID(C)
			, #Answers
	WHERE	C.value('@aid', 'uniqueidentifier') = #Answers.AnswerGuid
			AND Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
			AND (#Answers.QuestionTypeId = 3	-- Group logic
				OR #Answers.QuestionTypeId = 6	-- Simple logic
				OR #Answers.QuestionTypeId = 7)	-- User prompt
			AND Template_Log.Template_Group_Id IN
			(
				SELECT	tg.Template_Group_Id
				FROM	Template_Group tg
						INNER JOIN Template t ON tg.Template_Guid = t.Template_Guid
				WHERE	t.Template_Id = @TemplateId
			)
	UNION ALL
	SELECT	Template_Log.Log_Guid,
			#Answers.AnswerGuid, 
			C.value('@name', 'nvarchar(1000)'),
			Template_Log.DateTime_Start,
			Template_Log.DateTime_Finish,
			Template_Log.User_Id
	FROM	Template_Log 
			CROSS APPLY Answer_File.nodes('(/AnswerFile/AnswerLabels/Label)') as Label(C)
			, #Answers
	WHERE	C.value('@name', 'nvarchar(100)') = #Answers.Label
			AND Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
			AND (#Answers.QuestionTypeId = 3	-- Group logic
				OR #Answers.QuestionTypeId = 6	-- Simple logic
				OR #Answers.QuestionTypeId = 7)	-- User prompt
			AND Template_Log.Template_Group_Id IN
			(
				SELECT	tg.Template_Group_Id
				FROM	Template_Group tg
						INNER JOIN Template t ON tg.Template_Guid = t.Template_Guid
				WHERE	t.Template_Id = @TemplateId
			);
			
	SELECT DISTINCT	#Responses.LogGuid AS 'Log Id',
					Intelledox_User.Username,
					#Responses.StartDate AS 'Start Date/Time',
					#Responses.FinishDate AS 'Finish Date/Time',
					#Answers.PageName AS 'Page',
					#Answers.QuestionName AS 'Question',
					#Answers.QuestionID AS 'Question ID',
					
					CASE #Answers.QuestionTypeId 
						WHEN 3	
						THEN 'Group Logic'
						WHEN 6	
						THEN 'Simple Logic'
						WHEN 7	
						THEN 'User Prompt'
						ELSE 'Unknown'
					END as 'Question Type',
					
					CASE #Answers.QuestionTypeId 
						WHEN 3	-- Group
						THEN #Answers.AnswerName
						WHEN 6	-- Simple
						THEN CASE #Responses.Value
							WHEN '1'
							THEN 'Yes'
							ELSE 'No'
							END
						ELSE #Responses.Value
					END as 'Answer'
			
	FROM	#Answers
			INNER JOIN #Responses ON #Answers.AnswerGuid = #Responses.AnswerGuid
			INNER JOIN Intelledox_User ON Intelledox_User.User_ID = #Responses.UserID
	WHERE (#Answers.QuestionTypeId = 3 AND #Responses.Value = '1')
		OR (#Answers.QuestionTypeId = 6)
		OR (#Answers.QuestionTypeId = 7)
	ORDER BY #Responses.LogGuid,
			Intelledox_User.Username,
			#Responses.StartDate,
			#Responses.FinishDate;

	DROP TABLE #Answers;
	DROP TABLE #Responses;
GO
CREATE procedure [dbo].[spReport_UsageDataMostRunTemplates] (
	@StartDate datetime,
	@FinishDate datetime,
	@BusinessUnitGuid uniqueidentifier
)
AS
	SELECT TOP 10 Template.Template_Guid,
		Template.Name AS TemplateName,
		COUNT(*) AS NumRuns
	FROM Template_Log 
		INNER JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
		INNER JOIN Template ON Template.Template_Guid = Template_Group.Template_Guid
		INNER JOIN Intelledox_User ON Intelledox_User.User_ID = Template_Log.User_ID
    WHERE Template_Log.DateTime_Finish IS NOT NULL
		AND Template_Log.DateTime_Finish >= @StartDate
        AND Template_Log.DateTime_Finish <= @FinishDate + 1
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
    GROUP BY Template.Template_Guid,
		Template.Name
	ORDER BY NumRuns DESC;
GO
CREATE procedure [dbo].[spReport_UsageDataTimeTaken] (
	@StartDate datetime,
	@FinishDate datetime,
	@BusinessUnitGuid uniqueidentifier
)
AS
	SELECT TOP 10 Template.Name AS TemplateName,
		AVG(DateDiff(second, Template_Log.DateTime_Start, Template_Log.DateTime_Finish)) AS AvgTimeTaken
	FROM Template_Log 
		INNER JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
		INNER JOIN Template ON Template.Template_Guid = Template_Group.Template_Guid
		INNER JOIN Intelledox_User ON Intelledox_User.User_ID = Template_Log.User_ID
    WHERE Template_Log.DateTime_Finish IS NOT NULL
		AND Template_Log.DateTime_Finish >= @StartDate
        AND Template_Log.DateTime_Finish <= @FinishDate + 1
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
    GROUP BY Template.Template_Guid,
		Template.Name
	ORDER BY AVG(DateDiff(second, Template_Log.DateTime_Start, Template_Log.DateTime_Finish)) DESC;
GO
CREATE PROCEDURE [dbo].[spReport_UsageDataTopUsers] (
    @StartDate datetime,
    @FinishDate datetime,
    @BusinessUnitGuid uniqueidentifier
)
AS
    
    SELECT TOP 10 Intelledox_User.Username,
        COUNT(*) AS NumRuns,
        Address_Book.Full_Name
    FROM Template_Log 
        INNER JOIN Intelledox_User ON Intelledox_User.User_ID = Template_Log.User_ID
        LEFT JOIN Address_Book ON Address_Book.Address_id = Intelledox_User.Address_Id
    WHERE Template_Log.DateTime_Finish IS NOT NULL
        AND Template_Log.DateTime_Finish >= @StartDate
        AND Template_Log.DateTime_Finish <= @FinishDate + 1
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
    GROUP BY Template_Log.User_ID,
        Intelledox_User.Username,
        Address_Book.Full_Name
    ORDER BY NumRuns DESC;
GO
CREATE PROCEDURE [dbo].[spRouting_ActionOutputList]
	@ActionTypeId uniqueidentifier
AS
	SELECT	*
	FROM	Action_Output
	WHERE	ActionTypeId = @ActionTypeId
	ORDER BY Name;
GO
CREATE PROCEDURE [dbo].[spRouting_RegisterActionOutput]
	@ActionTypeId uniqueidentifier,
	@ActionOutputId uniqueidentifier,
	@Name nvarchar(255)
AS
	IF NOT EXISTS(SELECT * 
		FROM Action_Output 
		WHERE ActionTypeId = @ActionTypeId 
			AND ActionOutputId = @ActionOutputId)
	BEGIN
		INSERT INTO Action_Output(ActionTypeId, ActionOutputId, Name)
		VALUES	(@ActionTypeId, @ActionOutputId, @Name);
	END
GO
CREATE PROCEDURE [dbo].[spRouting_RegisterType]
	@Id uniqueidentifier,
	@Description nvarchar(255),
	@ProviderType int,
	@RunForAllProjects bit,
	@SupportsRun bit,
	@SupportsUI bit

AS
	IF NOT EXISTS(SELECT * FROM Routing_Type WHERE RoutingTypeId = @id)
	BEGIN
		INSERT INTO Routing_Type(RoutingTypeId, RoutingTypeDescription, ProviderType, RunForAllProjects, SupportsRun, SupportsUI)
		VALUES	(@id, @Description, @ProviderType, @RunForAllProjects, @SupportsRun, @SupportsUI);
	END
GO
CREATE PROCEDURE [dbo].[spRouting_RegisterTypeAttribute]
	@RoutingTypeId uniqueidentifier,
	@Id uniqueidentifier,
	@Description nvarchar(255),
	@ElementLimit int,
	@Required bit
AS
	IF NOT EXISTS(SELECT * FROM Routing_ElementType WHERE RoutingElementTypeId = @Id AND RoutingTypeId = @RoutingTypeId)
	BEGIN
		INSERT INTO Routing_ElementType(RoutingElementTypeId, RoutingTypeId, ElementTypeDescription, ElementLimit, [Required])
		VALUES	(@Id, @RoutingTypeId, @Description, @ElementLimit, @Required);
	END
GO
CREATE procedure [dbo].[spSecurity_PermissionList]
	@PermissionGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	IF (@PermissionGuid IS NULL)
	BEGIN
		SELECT	*
		FROM	Permission
		ORDER BY NAME
	END
	ELSE
	BEGIN
		SELECT	*
		FROM	Permission
		WHERE	PermissionGuid = @PermissionGuid
	END

	set @errorcode = @@error
GO
CREATE procedure [dbo].[spSecurity_RemoveRolePermission]
	@PermissionGuid uniqueidentifier,
	@RoleGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	DELETE FROM Role_Permission
	WHERE	RoleGuid = @RoleGuid
			AND PermissionGuid = @PermissionGuid
	
	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spSecurity_RolePermissionList]
	@RoleGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	SELECT	*
	FROM	Role_Permission
	WHERE	RoleGuid = @RoleGuid

	set @errorcode = @@error
GO
CREATE procedure [dbo].[spSecurity_UpdateRolePermission]
	@PermissionGuid uniqueidentifier,
	@RoleGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	INSERT INTO Role_Permission (RoleGuid,PermissionGuid)
	VALUES (@RoleGuid, @PermissionGuid)
	
	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spSession_RemoveUserSession]
	@SessionGuid uniqueidentifier
AS
	DELETE FROM	User_Session
	WHERE Session_Guid = @SessionGuid
GO
CREATE procedure [dbo].[spSession_UpdateUserSession]
	@SessionGuid uniqueidentifier,
	@UserGuid uniqueidentifier,
	@ModifiedDate datetime,
	@AnswerFileID int,
	@LogGuid uniqueidentifier
as
	IF EXISTS(SELECT * FROM User_Session WHERE Session_Guid = @SessionGuid)
		UPDATE	User_Session
		SET		AnswerFile_ID = @AnswerFileID,
				Log_Guid = @LogGuid
		WHERE	Session_Guid = @SessionGuid;
	ELSE
		INSERT INTO User_Session (Session_Guid, User_Guid, Modified_Date, AnswerFile_ID, Log_Guid)
		VALUES (@SessionGuid, @UserGuid, @ModifiedDate, @AnswerFileID, @LogGuid);
GO
CREATE procedure [dbo].[spSession_UserSessionList]
	@SessionGuid uniqueidentifier,
	@ErrorCode int output
as
	SELECT	User_Session.*, Intelledox_User.Business_Unit_Guid, Intelledox_User.User_ID
	FROM	User_Session
			INNER JOIN Intelledox_User ON User_Session.User_Guid = Intelledox_User.User_Guid
	WHERE	Session_Guid = @SessionGuid
	
	set @ErrorCode = @@error
GO
create procedure [dbo].[spSignoff_RemoveSignoff]
	@SignoffID int = 0,
	@UserID int = 0,
	@ErrorCode int output
as
	IF @SignoffID = 0 OR @SignoffID IS NULL 
		-- by user id
		DELETE user_signoff WHERE [user_id] = @UserID
	ELSE
		-- by signoff id
		DELETE user_signoff WHERE signoff_id = @SignoffID

	set @ErrorCode = @@error
GO
create procedure [dbo].[spSignoff_SignoffList]
	@SignoffID int = 0,
	@UserID int = 0,
	@ErrorCode int output
as
	IF @SignoffID = 0 OR @SignoffID IS NULL 
		IF @UserID = 0 OR @UserID IS NULL 
			SELECT * FROM user_signoff	
		ELSE
			SELECT * FROM user_signoff WHERE [user_id] = @UserID
	ELSE
		SELECT * FROM user_signoff WHERE signoff_id = @SignoffID

	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spSignoff_UpdateSignoff]
	@SignoffID int output,
	@UserID int,
	@Name nvarchar(50),
	@OtherDetail nvarchar(4000),
	@ErrorCode int output
as
	IF @SignoffID = 0 OR @SignoffID IS NULL 
	begin
		INSERT INTO user_signoff(User_id, Name, Other_Detail)
		VALUES (@UserID, @Name, @OtherDetail)

		select @SignoffID = @@identity
	end
	ELSE
		UPDATE user_signoff
		SET 	[user_id] = @UserID,
			[name] = @Name,
			other_detail = @OtherDetail
		WHERE signoff_id = @SignoffID

	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spTemplate_RemoveTemplate]
	@TemplateGuid uniqueidentifier,
	@OnlyChildInfo bit
as
	DECLARE @TemplateId Int

	SELECT	@TemplateId = Template_Id
	FROM	Template
	WHERE	Template_Guid = @TemplateGuid;

	IF @OnlyChildInfo = 0
	BEGIN
		DELETE	template_Group
		WHERE	template_guid = @TemplateGuid
			OR	layout_guid = @TemplateGuid;

		DELETE	Template_Category
		WHERE	Template_ID = @TemplateID;

		DELETE	User_Group_Template
		WHERE	TemplateGuid = @TemplateGuid;
	END
	
	DELETE	Template_File
	WHERE	Template_Guid = @TemplateGuid;
	
	DELETE	Template
	WHERE	Template_Guid = @TemplateGuid;
	
	DELETE	Template_File_Version
	WHERE	Template_Guid = @TemplateGuid;
	
	DELETE	Template_Version
	WHERE	Template_Guid = @TemplateGuid;
GO
CREATE procedure [dbo].[spTemplate_RoutingElementTypeList]
	@RoutingTypeId uniqueidentifier
AS
	SELECT	*
	FROM	Routing_ElementType
	WHERE	RoutingTypeId = @RoutingTypeId
	ORDER BY ElementTypeDescription;
GO
CREATE procedure [dbo].[spTemplate_RoutingTypeList]
	@ProviderType INT,
	@ErrorCode int = 0 output	
AS
	IF @ProviderType > 0 
		BEGIN 
			SELECT *
			FROM Routing_Type
			WHERE ProviderType=@ProviderType
		END 
	ELSE
		BEGIN 
			SELECT *
			FROM Routing_Type
		END 
	
	SET @errorcode = @@error
GO
CREATE procedure [dbo].[spTemplate_TemplateFormatList]
	@ItemId int = 0,
	@ItemGuid varchar(40) = '',
	@ErrorCode int = 0 output
AS
	SELECT FormatTypeId as ItemId, [Name] as ItemName, Description
	FROM Format_Type
	where (@ItemId = 0 or FormatTypeId = @ItemId)

	set @errorcode = @@error
GO
CREATE procedure [dbo].[spTemplate_TemplateList]
	@TemplateGuid uniqueidentifier = null,
	@ErrorCode int output
AS
	SET NOCOUNT ON
	
	IF @TemplateGuid IS NULL
		SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, b.Category_ID, 
				b.[Name] as Category_Name, a.Supplier_Guid, a.Business_Unit_Guid,
				a.Content_Bookmark, a.HelpText, a.Modified_Date, Intelledox_User.Username, 
				a.[name] as Project_Name, a.Modified_By, lockedByUser.Username AS LockedBy, a.Comment, 
				a.Template_Version, a.FeatureFlags
		FROM	Template a 
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		ORDER BY a.[Name];
	ELSE
		SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, b.Category_ID, 
				b.[Name] as Category_Name, a.Supplier_Guid, a.Business_Unit_Guid,
				a.Content_Bookmark, a.HelpText, a.Modified_Date, Intelledox_User.Username,
				a.[name] as Project_Name, a.Modified_By, lockedByUser.Username AS LockedBy, a.Comment, 
				a.Template_Version, a.FeatureFlags
		FROM	Template a
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		WHERE	a.Template_Guid = @TemplateGuid
		ORDER BY a.[Name];

	set @ErrorCode = @@error;
GO
CREATE PROCEDURE [dbo].[spTemplate_TemplateSubscribeGroup]
    @TemplateGuid uniqueidentifier,
    @UserGroupGuid uniqueidentifier
AS
    DECLARE @Subscribed int
    
    SELECT	@Subscribed = COUNT(*)
    FROM	User_group_template
    WHERE	TemplateGuid = @TemplateGuid
        AND GroupGuid = @UserGroupGuid
    
    IF @Subscribed = 0
    BEGIN
        INSERT INTO user_Group_template (GroupGuid, TemplateGuid)
        VALUES (@UserGroupGuid, @TemplateGuid);
    END
GO
CREATE PROCEDURE [dbo].[spTemplate_TemplateUnsubscribeGroup]
    @TemplateGuid uniqueidentifier,
    @UserGroupGuid uniqueidentifier,
    @UnsubscribeAll bit
AS	
    IF @UnsubscribeAll = 1
    BEGIN
        DELETE	User_group_template
        WHERE	TemplateGuid = @TemplateGuid;
    END
    ELSE
    BEGIN
        DELETE	User_Group_template
        WHERE	TemplateGuid = @TemplateGuid
                AND GroupGuid = @UserGroupGuid;
    END
GO
CREATE PROCEDURE [dbo].[spTemplate_TemplateUserGroups]
    @TemplateID int,
    @ErrorCode int output
AS
    select	b.* 
    from	user_group_template a
            inner join user_group b on a.GroupGuid = b.Group_Guid
            inner join Template t on a.TemplateGuid = t.Template_Guid
    where	t.Template_Id = @TemplateID
    order by b.[name];
GO
CREATE procedure [dbo].[spTemplateGrp_CategoryList]
	@CategoryID int = 0,
	@ErrorCode int output
as
	SELECT	*
	FROM	Category
	WHERE	@CategoryID = 0
			OR Category_ID = @CategoryID
	ORDER BY Name
	
	set @ErrorCode = @@error	
GO
CREATE procedure [dbo].[spTemplateGrp_FolderList]
	@FolderID int,
	@TemplateGroupID int,
	@ErrorCode int output
as
	IF @TemplateGroupID IS NULL OR @TemplateGroupID = 0
	BEGIN
		SELECT	*
		FROM	Folder
		WHERE	Folder_ID = @FolderID
	END
	ELSE
	BEGIN
		SELECT	TOP 1 Folder.*
		FROM	Folder
				INNER JOIN Template_Group ON Folder.Folder_Guid = Template_Group.Folder_Guid
		WHERE	Template_group.Template_Group_ID = @TemplateGroupID
	END

	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spTemplateGrp_FolderTemplateList]
	@FolderID int = 0,
	@ErrorCode int output
as
	SELECT	a.*, d.*, b.Template_ID, b.[Name], b.Template_Type_ID
	FROM	Folder a
		inner join Template_Group d on a.folder_Guid = d.Folder_Guid
		inner join Template b on b.Template_Guid = d.Template_Guid
	WHERE	(@FolderID = 0 OR a.Folder_ID = @FolderID)
	ORDER BY a.Folder_ID, d.Template_Group_ID;
	
	set @ErrorCode = @@error
GO
CREATE PROCEDURE [dbo].[spTemplateGrp_GroupOutputList]
	@GroupGuid uniqueidentifier
as
	SELECT	*
	FROM	Group_Output
	WHERE	GroupGuid = @GroupGuid
GO
CREATE PROCEDURE [dbo].[spTemplateGrp_InsertTemplateLog]
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
create procedure [dbo].[spTemplateGrp_QuestionTypeList]
	@ErrorCode int output
as
	SELECT * FROM question_type
	
	set @ErrorCode = @@error
GO
create procedure [dbo].[spTemplateGrp_RemoveCategory]
	@CategoryID int,
	@ErrorCode int output
as
	DELETE template_category WHERE category_id = @CategoryID
	DELETE category WHERE category_id = @CategoryID
	
	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spTemplateGrp_RemoveFolder]
	@FolderID int,
	@ErrorCode int output
as
	DELETE Template_Group 
	WHERE Folder_Guid = (
		SELECT	Folder_Guid
		FROM	Folder
		WHERE	Folder_ID = @FolderID);
	
	DELETE Folder WHERE Folder_ID = @FolderID;
	
	set @ErrorCode = @@error;
GO
CREATE PROCEDURE [dbo].[spTemplateGrp_RemoveGroupOutput]
	@GroupGuid uniqueidentifier,
	@FormatTypeId int
AS
	IF @FormatTypeId IS NULL
		DELETE	FROM Group_Output
		WHERE	GroupGuid = @GroupGuid
	ELSE
		DELETE	FROM Group_Output
		WHERE	GroupGuid = @GroupGuid
			AND FormatTypeId = @FormatTypeId
GO
CREATE procedure [dbo].[spTemplateGrp_RemoveTemplateGroup]
	@TemplateGroupID int,
	@ErrorCode int output
as
	-- Remove the group records
	DELETE Template_Group WHERE Template_Group_ID = @TemplateGroupID;
	
	set @ErrorCode = @@error;
GO
CREATE PROCEDURE [dbo].[spTemplateGrp_SubscribeCategory]
	@TemplateGuid uniqueidentifier,
	@CategoryID int
as
	DECLARE @TemplateId int
	
	SELECT	@TemplateId = Template_Id
	FROM	Template
	WHERE	Template_Guid = @TemplateGuid;
	
	DELETE	Template_category 
	WHERE	template_id = @TemplateID 
			and category_id = @CategoryID;

	INSERT INTO Template_category(Template_Id, Category_id)
	VALUES (@TemplateID, @CategoryID);
GO
CREATE PROCEDURE [dbo].[spTemplateGrp_UnsubscribeCategory]
	@TemplateGuid uniqueidentifier,
	@CategoryID int
as
	DECLARE @TemplateId int
	
	SELECT	@TemplateId = Template_Id
	FROM	Template
	WHERE	Template_Guid = @TemplateGuid;

	DELETE	template_category
	WHERE	template_id = @TemplateID
			AND category_id = @CategoryID;
GO
create procedure [dbo].[spTemplateGrp_UpdateCategory]
	@CategoryID int,
	@Name nvarchar(100),
	@NewID int output,
	@ErrorCode int output
as
	IF @CategoryID = 0
	begin
		INSERT INTO Category ([Name]) VALUES (@Name)
		select @NewID = @@identity
	end
	ELSE
	begin
		UPDATE Category
		SET [Name] = @Name
		WHERE Category_ID = @CategoryID
	end
	
	set @ErrorCode = @@error	
GO
CREATE procedure [dbo].[spTemplateGrp_UpdateFolder]
	@FolderID int,
	@Name nvarchar(100),
	@BusinessUnitGUID uniqueidentifier,
	@FolderGuid uniqueidentifier,
	@NewID int output,
	@ErrorCode int output
as
	IF @FolderID  = 0
	begin
		INSERT INTO folder(Folder_Name, Business_Unit_GUID, Folder_Guid)
		VALUES (@Name, @BusinessUnitGUID, @FolderGuid)

		select @NewID = @@identity
	end
	ELSE
	begin
		UPDATE folder
		SET folder_name = @Name
		WHERE folder_id = @FolderID
	end

	set @ErrorCode = @@error
GO
CREATE PROCEDURE [dbo].[spTemplateGrp_UpdateGroupOutput]
	@GroupGuid uniqueidentifier,
	@FormatTypeId int,
	@LockOutput bit,
	@EmbedFullFonts bit
AS
	IF NOT EXISTS(SELECT * FROM Group_Output WHERE GroupGuid = @GroupGuid AND FormatTypeId = @FormatTypeId)
	BEGIN
		INSERT INTO Group_Output (GroupGuid, FormatTypeId, LockOutput, EmbedFullFonts)
		VALUES (@GroupGuid, @FormatTypeId, @LockOutput, @EmbedFullFonts)
	END	
	ELSE
	BEGIN		
		UPDATE	Group_Output
		SET		LockOutput = @LockOutput,
				EmbedFullFonts = @EmbedFullFonts
		WHERE	GroupGuid = @GroupGuid
			AND FormatTypeId = @FormatTypeId
	END
GO
CREATE procedure [dbo].[spTenant_BusinessUnitList]
	@BusinessUnitGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	IF (@BusinessUnitGuid IS NULL)
	BEGIN
		SELECT	*
		FROM	Business_Unit;
	END
	ELSE
	BEGIN
		SELECT	*
		FROM	Business_Unit
		WHERE	Business_Unit_Guid = @BusinessUnitGuid;
	END

	set @errorcode = @@error;
GO
CREATE PROCEDURE [dbo].[spTenant_ProvisionTenant] (
    @BusinessUnitGuid uniqueidentifier,
    @TenantName nvarchar(200),
    @FirstName nvarchar(200),
    @LastName nvarchar(200),
    @UserName nvarchar(50),
    @UserPasswordHash varchar(100),
    @SubscriptionType int,
    @ExpiryDate datetime,
    @TenantFee money,
    @DefaultLanguage nvarchar(10),
    @UserFee money
)
AS
    DECLARE @UserGuid uniqueidentifier
    DECLARE @TemplateBusinessUnit uniqueidentifier
    DECLARE @TemplateUser uniqueidentifier

    SET @UserGuid = NewID()

    SELECT	@TemplateBusinessUnit = Business_Unit_Guid
    FROM	Business_Unit
    WHERE	Name = 'SaaSTemplate'

    SELECT	@TemplateUser = User_Guid
    FROM	Intelledox_User
    WHERE	UserName = 'SaaSTemplate'

    --New business unit (Company in SaaS)
    INSERT INTO Business_Unit(Business_Unit_Guid, Name, SubscriptionType, ExpiryDate, TenantFee, DefaultLanguage, UserFee)
    VALUES (@BusinessUnitGuid, @TenantName, @SubscriptionType, @ExpiryDate, @TenantFee, @DefaultLanguage, @UserFee)

    --Roles
    INSERT INTO Administrator_Level(AdminLevel_Description, RoleGuid, Business_Unit_Guid)
    SELECT	AdminLevel_Description, newid(), @BusinessUnitGuid
    FROM	Administrator_Level
    WHERE	Business_Unit_Guid = @TemplateBusinessUnit

    --Role Permissions
    INSERT INTO Role_Permission(PermissionGuid, RoleGuid)
    SELECT	Role_Permission.PermissionGuid, NewRole.RoleGuid
    FROM	Role_Permission
            INNER JOIN Administrator_Level ON Administrator_Level.RoleGuid = Role_Permission.RoleGuid
            INNER JOIN Administrator_Level NewRole ON Administrator_Level.AdminLevel_Description = NewRole.AdminLevel_Description
    WHERE	Administrator_Level.Business_Unit_Guid = @TemplateBusinessUnit
            AND NewRole.Business_Unit_Guid = @BusinessUnitGuid

    --Groups
    INSERT INTO User_Group(Name, WinNT_Group, Business_Unit_Guid, Group_Guid, AutoAssignment, SystemGroup)
    SELECT	Name, WinNT_Group, @BusinessUnitGuid, NewID(), AutoAssignment, SystemGroup
    FROM	User_Group
    WHERE	Business_Unit_Guid = @TemplateBusinessUnit

    --User Address
    INSERT INTO address_book (full_name, first_name, last_name, email_address)
    VALUES (@FirstName + ' ' + @LastName, @FirstName, @LastName, @UserName)
    
    --User
    INSERT INTO Intelledox_User(Username, Pwdhash, WinNT_User, Business_Unit_Guid, User_Guid, Address_ID)
    VALUES (@UserName, @UserPasswordHash, 0, @BusinessUnitGuid, @UserGuid, @@IDENTITY)

    --User Permissions
    INSERT INTO User_Role(UserGuid, RoleGuid, GroupGuid)
    SELECT	@UserGuid, NewRole.RoleGuid, NULL
    FROM	User_Role
            INNER JOIN Administrator_Level ON Administrator_Level.RoleGuid = User_Role.RoleGuid
            INNER JOIN Administrator_Level NewRole ON Administrator_Level.AdminLevel_Description = NewRole.AdminLevel_Description
    WHERE	Administrator_Level.Business_Unit_Guid = @TemplateBusinessUnit
            AND NewRole.Business_Unit_Guid = @BusinessUnitGuid
            AND User_Role.UserGuid = @TemplateUser

    --User Groups
    INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
    SELECT	NewUser.User_Guid, NewGroup.Group_Guid, User_Group_Subscription.IsDefaultGroup
    FROM	User_Group_Subscription
            INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
            INNER JOIN User_Group ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
            INNER JOIN User_Group NewGroup ON User_Group.Name = NewGroup.Name
            , Intelledox_User NewUser
    WHERE	Intelledox_User.User_Guid = @TemplateUser
            AND NewUser.User_Guid = @UserGuid
            AND NewGroup.Business_Unit_Guid = @BusinessUnitGuid
GO
CREATE PROCEDURE [dbo].[spTenant_Renewals] 
AS
	SELECT	Business_Unit_Guid, Name, SubscriptionType, ExpiryDate, TenantFee
	FROM	Business_Unit
	WHERE	ExpiryDate  <= DateAdd(d, 4, GetDate())
			AND SubscriptionType = 1
GO
CREATE procedure [dbo].[spTenant_UpdateBusinessUnit]
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
	@SamlLastLoginFail nvarchar(max)
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
			SamlLastLoginFail = @SamlLastLoginFail
	WHERE	Business_Unit_Guid = @BusinessUnitGuid;
GO
CREATE procedure [dbo].[spUser_RemoveUserRole]
	@UserGuid uniqueidentifier,
	@RoleGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	DELETE FROM User_Role
	WHERE	userGuid = @userGuid
			AND RoleGuid = @RoleGuid
			AND (GroupGuid = @GroupGuid OR (GroupGuid IS NULL AND @GroupGuid IS NULL))
	
	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spUser_UpdateUserRole]
	@UserGuid uniqueidentifier,
	@RoleGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	INSERT INTO User_Role (UserGuid, RoleGuid, GroupGuid)
	VALUES (@UserGuid, @RoleGuid, @GroupGuid)
	
	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spUser_UserRoleList]
	@UserGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	SELECT	*
	FROM	User_Role
	WHERE	UserGuid = @UserGuid
			AND (GroupGuid = @GroupGuid or (GroupGuid IS NULL AND @GroupGuid IS NULL))

	set @errorcode = @@error
GO
CREATE PROCEDURE [dbo].[spUser_UserRoleText]
	@UserGuid uniqueidentifier,
	@GroupGuid uniqueidentifier
AS
	SELECT	AdminLevel_Description
	FROM	Administrator_Level
			INNER JOIN vwUserPermissions ON Administrator_Level.RoleGuid = vwUserPermissions.RoleGuid
	WHERE	vwUserPermissions.UserGuid = @UserGuid
			AND (vwUserPermissions.GroupGuid = @GroupGuid OR (vwUserPermissions.GroupGuid IS NULL AND @GroupGuid IS NULL))
GO
CREATE procedure [dbo].[spUsers_AdminLevelAddGroup]
	@RoleGuid uniqueidentifier,
	@GroupGuid uniqueidentifier
AS
	INSERT INTO User_Group_Role(GroupGuid, RoleGuid)
	VALUES (@GroupGuid, @RoleGuid)
GO
CREATE procedure [dbo].[spUsers_AdminLevelList]
	@RoleGuid uniqueidentifier,
	@BusinessUnitGUID uniqueidentifier,
	@UserGUID uniqueidentifier,
	@ErrorCode int = 0 output
AS
	IF (@UserGUID IS NULL)
	BEGIN
		IF (@RoleGuid IS NULL)
		BEGIN
			SELECT	Administrator_Level.AdminLevel_ID, Administrator_Level.AdminLevel_Description, 
					Administrator_Level.RoleGuid, Administrator_Level.Business_Unit_Guid,
					--Design projects
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' THEN 1 ELSE 0 END) AS CanDesignProjects,
					--Publish projects
					MAX(CASE WHEN Role_Permission.PermissionGuid = '6B96BAF3-8A76-4F42-B1E7-DF87142444E0' THEN 1 ELSE 0 END) AS CanPublishProjects,
					--Manage content
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'FA2C7769-6D15-442E-9F7F-E8CE82590D8D' THEN 1 ELSE 0 END) AS CanManageContent,
					--Manage users
					MAX(CASE WHEN Role_Permission.PermissionGuid = '7D98327C-B4CB-48DC-9FF7-E613C26FA918' THEN 1 ELSE 0 END) AS CanManageUsers,
					--Manage groups
					MAX(CASE WHEN Role_Permission.PermissionGuid = '33FC4FFE-9108-4D56-9A08-DD128255D87C' THEN 1 ELSE 0 END) AS CanManageGroups,
					--Manage security
					MAX(CASE WHEN Role_Permission.PermissionGuid = '09B7187E-E432-4B03-BDC9-C7FC2C82B9F1' THEN 1 ELSE 0 END) AS CanManageSecurity,
					--Manage data sources
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'B0761CDD-BE11-45EE-8133-BF1D6AA65D6D' THEN 1 ELSE 0 END) AS CanManageDataSources,
					0 as IsInherited,
					--Maintain Licensing
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'BB4F1768-DBC7-46C7-9A52-09159DB15A02' THEN 1 ELSE 0 END) AS CanMaintainLicensing,
					--Change Settings
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'D0416D36-5C3C-4CB7-8686-74432261A87A' THEN 1 ELSE 0 END) AS CanChangeSettings,
					--Management Console
					MAX(CASE WHEN Role_Permission.PermissionGuid = '22A89A6C-C131-4DF1-9A4F-50CFC5E69B58' THEN 1 ELSE 0 END) AS CanManageConsole,
					--Content Approver
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'F9A676FF-93F8-4D15-9F24-B95DD8C01762' THEN 1 ELSE 0 END) AS CanApproveContent,
					--Workflow Tasks
					MAX(CASE WHEN Role_Permission.PermissionGuid = '73843C3F-21D0-4861-8886-7071E174DA04' THEN 1 ELSE 0 END) AS CanManageWorkflowTasks
			FROM	Administrator_Level
					LEFT JOIN Role_Permission ON Administrator_Level.RoleGuid = Role_Permission.RoleGuid
			WHERE	Administrator_Level.Business_Unit_GUID = @BusinessUnitGUID
			GROUP BY Administrator_Level.AdminLevel_ID, Administrator_Level.AdminLevel_Description, 
					Administrator_Level.RoleGuid, Administrator_Level.Business_Unit_Guid
			ORDER BY Administrator_Level.AdminLevel_Description;
		END
		ELSE
		BEGIN
			SELECT	Administrator_Level.AdminLevel_ID, Administrator_Level.AdminLevel_Description, 
					Administrator_Level.RoleGuid, Administrator_Level.Business_Unit_Guid,
					--Design projects
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'CF0680C8-E5CA-4ACE-AC1A-AD6523973CC7' THEN 1 ELSE 0 END) AS CanDesignProjects,
					--Publish projects
					MAX(CASE WHEN Role_Permission.PermissionGuid = '6B96BAF3-8A76-4F42-B1E7-DF87142444E0' THEN 1 ELSE 0 END) AS CanPublishProjects,
					--Manage content
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'FA2C7769-6D15-442E-9F7F-E8CE82590D8D' THEN 1 ELSE 0 END) AS CanManageContent,
					--Manage users
					MAX(CASE WHEN Role_Permission.PermissionGuid = '7D98327C-B4CB-48DC-9FF7-E613C26FA918' THEN 1 ELSE 0 END) AS CanManageUsers,
					--Manage groups
					MAX(CASE WHEN Role_Permission.PermissionGuid = '33FC4FFE-9108-4D56-9A08-DD128255D87C' THEN 1 ELSE 0 END) AS CanManageGroups,
					--Manage security
					MAX(CASE WHEN Role_Permission.PermissionGuid = '09B7187E-E432-4B03-BDC9-C7FC2C82B9F1' THEN 1 ELSE 0 END) AS CanManageSecurity,
					--Manage data sources
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'B0761CDD-BE11-45EE-8133-BF1D6AA65D6D' THEN 1 ELSE 0 END) AS CanManageDataSources,
					0 as IsInherited,
					--Maintain Licensing
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'BB4F1768-DBC7-46C7-9A52-09159DB15A02' THEN 1 ELSE 0 END) AS CanMaintainLicensing,
					--Change Settings
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'D0416D36-5C3C-4CB7-8686-74432261A87A' THEN 1 ELSE 0 END) AS CanChangeSettings,
					--Management Console
					MAX(CASE WHEN Role_Permission.PermissionGuid = '22A89A6C-C131-4DF1-9A4F-50CFC5E69B58' THEN 1 ELSE 0 END) AS CanManageConsole,
					--Content Approver
					MAX(CASE WHEN Role_Permission.PermissionGuid = 'F9A676FF-93F8-4D15-9F24-B95DD8C01762' THEN 1 ELSE 0 END) AS CanApproveContent,
					--Workflow Tasks
					MAX(CASE WHEN Role_Permission.PermissionGuid = '73843C3F-21D0-4861-8886-7071E174DA04' THEN 1 ELSE 0 END) AS CanManageWorkflowTasks
			FROM	Administrator_Level
					LEFT JOIN Role_Permission ON Administrator_Level.RoleGuid = Role_Permission.RoleGuid
			WHERE	Administrator_Level.RoleGuid = @RoleGuid
			GROUP BY Administrator_Level.AdminLevel_ID, Administrator_Level.AdminLevel_Description, 
					Administrator_Level.RoleGuid, Administrator_Level.Business_Unit_Guid
			ORDER BY Administrator_Level.AdminLevel_Description;
		END
	END
	ELSE
	BEGIN
		SELECT	Administrator_Level.AdminLevel_ID, Administrator_Level.AdminLevel_Description, 
				Administrator_Level.RoleGuid, Administrator_Level.Business_Unit_Guid,
				vwUserPermissions.CanDesignProjects, vwUserPermissions.CanPublishProjects,
				vwUserPermissions.CanManageContent, vwUserPermissions.CanManageUsers,
				vwUserPermissions.CanManageGroups, vwUserPermissions.CanManageSecurity,
				vwUserPermissions.CanManageDataSources, vwUserPermissions.IsInherited,
				vwUserPermissions.CanMaintainLicensing, vwUserPermissions.CanChangeSettings,
				vwUserPermissions.CanManageConsole, vwUserPermissions.CanApproveContent,
				vwUserPermissions.CanManageWorkflowTasks
		FROM	Administrator_Level
				LEFT JOIN vwUserPermissions ON Administrator_Level.RoleGuid = vwUserPermissions.RoleGuid
		WHERE	Administrator_Level.Business_Unit_GUID = @BusinessUnitGUID
				AND vwUserPermissions.UserGUID = @UserGUID
				AND vwUserPermissions.GroupGuid IS NULL
		ORDER BY Administrator_Level.AdminLevel_Description;
	END

	set @errorcode = @@error;
GO
CREATE procedure [dbo].[spUsers_AdminLevelRemoveGroup]
	@RoleGuid uniqueidentifier,
	@GroupGuid uniqueidentifier
AS
	DELETE	User_Group_Role 
	WHERE	GroupGuid = @GroupGuid and RoleGuid = @RoleGuid
GO
CREATE procedure [dbo].[spUsers_ConfirmUniqueUsername]
	@UserID int,
	@Username nvarchar(50) = ''
as
	SELECT	COUNT(*)
	FROM	Intelledox_User
	WHERE	[Username] = @Username
			AND [User_ID] <> @UserID
GO
CREATE procedure [dbo].[spUsers_DefaultUserGroup]
    @UserGuid uniqueidentifier = null
AS
    SELECT	b.User_Group_Id, b.Group_Guid
    FROM	Intelledox_User IxUser
            INNER JOIN	User_Group_Subscription c on IxUser.User_Guid = c.UserGuid
            INNER JOIN	User_Group b on c.GroupGuid = b.Group_Guid
    WHERE	c.IsDefaultGroup = 1
            AND (IxUser.User_Guid = @UserGuid);
GO
CREATE procedure [dbo].[spUsers_GroupList]
	@UserGroupGuid uniqueidentifier,
	@BusinessUnitGUID uniqueidentifier,
	@WindowsGroups bit
as
	SELECT	*
	FROM	User_Group
	WHERE	(@UserGroupGuid IS NULL OR Group_Guid = @UserGroupGuid)
			AND (@BusinessUnitGUID IS NULL OR Business_Unit_GUID = @BusinessUnitGUID) 
			AND (@WindowsGroups = 0 OR WinNT_Group = @WindowsGroups) 
	ORDER BY Name
GO
CREATE PROCEDURE [dbo].[spUsers_IdToGuid]
	@id int
AS
	SELECT	User_Guid
	FROM	Intelledox_User
	WHERE	User_Id = @id;
GO
CREATE procedure [dbo].[spUsers_RemoveAdminLevel]
	@RoleGuid uniqueidentifier,
	@ErrorCode int = 0 output
AS
	delete Administrator_Level
	where RoleGuid = @RoleGuid

	delete User_Role
	where RoleGuid = @RoleGuid

	delete User_Group_role
	where RoleGuid = @RoleGuid
	
	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spUsers_RemoveUser]
    @UserGuid uniqueidentifier
AS
    DECLARE @UserId int;
    DECLARE @AddressId int;
    
    SELECT	@UserId = [User_Id], @AddressId = Address_ID
    FROM	Intelledox_User
    WHERE	User_Guid = @UserGuid;
    
    DELETE	Address_Book WHERE Address_ID = @AddressId;
    DELETE	User_Address_Book WHERE [User_Id] = @UserId;
    DELETE	User_Group_Subscription WHERE UserGuid = @UserGuid;
    DELETE	User_Signoff WHERE [User_Id] = @UserId;
    DELETE	Intelledox_User WHERE User_Guid = @UserGuid;
GO
CREATE procedure [dbo].[spUsers_RemoveUserGroup] 
	@GroupGuid uniqueidentifier
as
	delete user_group
	where group_guid = @GroupGuid
GO
CREATE procedure [dbo].[spUsers_RolesByGroup]
	@GroupGuid uniqueidentifier
AS
	SELECT	Administrator_Level.AdminLevel_ID, Administrator_Level.AdminLevel_Description, 
			Administrator_Level.RoleGuid, Administrator_Level.Business_Unit_Guid
	FROM	Administrator_Level
			INNER JOIN User_Group_Role ON Administrator_Level.RoleGuid = User_Group_Role.RoleGuid
	WHERE	User_Group_Role.GroupGuid = @GroupGuid
GO
CREATE procedure [dbo].[spUsers_SubscribeUserGroup]
    @UserGroupID int,
    @UserID int,
    @Default bit,
    @ErrorCode int = 0 output
as
    declare @SubscriptionCount int
    DECLARE @UserGuid uniqueidentifier
    DECLARE @GroupGuid uniqueidentifier
    
    SET NOCOUNT ON
    
    SELECT	@UserGuid = User_Guid
    FROM	Intelledox_User
    WHERE	[User_ID] = @UserID;
    
    SELECT	@GroupGuid = Group_Guid
    FROM	User_Group
    WHERE	User_Group_ID = @UserGroupID;
    
    select	@SubscriptionCount = COUNT(*)
    from	User_Group_Subscription
    where	GroupGuid = @GroupGuid
            AND UserGuid = @UserGuid;

    --Enforce single default group
    if @Default <> 0
    begin
        update	user_group_subscription
        SET		IsDefaultGroup = 0
        where	UserGuid = @UserGuid
    end
    else
    begin
        if (select count(*) from user_group_subscription where IsDefaultGroup = 1 and UserGuid = @UserGuid) = 0
            set @Default = 1;
    end

    if @SubscriptionCount = 0
    begin
        INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
        VALUES (@UserGuid, @GroupGuid, @Default);
    end

    set @ErrorCode = @@error;
GO
CREATE procedure [dbo].[spUsers_UnsubscribeUserGroup]
    @UserGroupID int,
    @UserID int,
    @ErrorCode int = 0 output
AS
    DECLARE @Default bit,
            @NewDefaultID int
    DECLARE @UserGuid uniqueidentifier
    DECLARE @GroupGuid uniqueidentifier
            
    SELECT	@UserGuid = User_Guid
    FROM	Intelledox_User
    WHERE	[User_ID] = @UserID;
    
    SELECT	@GroupGuid = Group_Guid
    FROM	User_Group
    WHERE	User_Group_ID = @UserGroupID;

    SELECT	@Default = IsDefaultGroup
    FROM	User_Group_Subscription
    WHERE	GroupGuid = @GroupGuid
            AND UserGuid = @UserGuid;
            
    -- Remove any roles we have in this group
    DELETE FROM	User_Role
    WHERE	UserGuid = @UserGuid
            AND GroupGuid = @GroupGuid;

    -- Remove group from user
    DELETE FROM User_Group_Subscription
    WHERE	GroupGuid = @GroupGuid
            AND UserGuid = @UserGuid;

    IF @Default <> 0
    begin
        update	user_group_subscription
        SET		IsDefaultGroup = 1
        from	user_group_subscription
                inner join (
                    select top 1 GroupGuid from user_group_subscription where UserGuid = @UserGuid
                ) ugs on user_group_subscription.GroupGuid = ugs.GroupGuid and user_group_subscription.UserGuid = @UserGuid;
    end

    set @ErrorCode = @@error;
GO
CREATE procedure [dbo].[spUsers_updateAdminLevel]
	@RoleGuid uniqueidentifier,
	@Description nvarchar(50),
	@BusinessUnitGUID uniqueidentifier,
	@ErrorCode int = 0 output
AS
	if NOT EXISTS(SELECT * FROM Administrator_Level WHERE RoleGuid = @RoleGuid)
	begin
		INSERT INTO Administrator_Level (adminlevel_description, RoleGuid, Business_Unit_GUID)
		VALUES (@Description, @RoleGuid, @BusinessUnitGUID)
	end
	else
	begin
		update Administrator_Level
		SET AdminLevel_Description = @Description
		where RoleGuid = @RoleGuid
	end
	
	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spUsers_updateUser]
	@UserID int,
	@Username nvarchar(50),
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
	@ErrorCode int = 0 output
as
	if @UserID = 0 OR @UserID IS NULL
	begin
		INSERT INTO Intelledox_User(Username, PwdHash, WinNT_User, Business_Unit_GUID, User_Guid, SelectedTheme, 
				ChangePassword, PwdSalt, PwdFormat, [Disabled], Address_ID, Timezone, Culture, Language)
		VALUES (@Username, @Password, @WinNT_User, @BusinessUnitGUID, @User_Guid, @SelectedTheme, 
				@ChangePassword, @PasswordSalt, @PasswordFormat, @Disabled, @Address_Id, @Timezone, @Culture, @Language);
		
		select @NewID = @@identity;

		INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
		SELECT	@User_Guid, User_Group.Group_Guid, 0
		FROM	User_Group
		WHERE	User_Group.AutoAssignment = 1;
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
			Address_ID = @Address_Id
		WHERE [User_ID] = @UserID;
	end

	set @ErrorCode = @@error;
GO
CREATE procedure [dbo].[spUsers_updateUserGroup]
    @GroupGuid uniqueidentifier,
    @Name nvarchar(50),
    @IsWindowsGroup bit,
    @BusinessUnitGUID uniqueidentifier,
    @AddressId int
as
    if NOT EXISTS (SELECT * FROM User_Group WHERE Group_Guid = @GroupGuid)
    begin
        INSERT INTO User_Group ([Name], [WinNT_Group], Business_Unit_GUID, Group_Guid, AutoAssignment, SystemGroup, Address_ID)
        VALUES (@Name, @IsWindowsGroup, @BusinessUnitGUID, @GroupGuid, 0, 0, @AddressId);
    end
    else
    begin
        update	User_Group
        SET		[Name] = @Name, 
                [WinNT_Group] = @IsWindowsGroup,
                Address_ID = @AddressId
        where	Group_Guid = @GroupGuid;
    end
GO
CREATE procedure [dbo].[spUsers_UserByUsername]
	@UserName nvarchar(50)
AS
	SELECT	Intelledox_User.*, Business_Unit.DefaultLanguage
	FROM	Intelledox_User
			INNER JOIN Business_Unit ON Intelledox_User.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
	WHERE	Intelledox_User.Username = @UserName;
GO
CREATE procedure [dbo].[spUsers_UserData]
	@BusinessUnitGUID nvarchar(50),
	@Username nvarchar(50) = '',
	@UserGroupID int = 0,
	@ShowActive int = 0,
	@ErrorCode int = 0 output
as
	SET NOCOUNT ON;

	DECLARE @ColNames nvarchar(MAX);
	
	-- Find the Custom_Fields
	-- Will look like "[CustomField1],[CustomField2],[Custom_Field."
	SET @ColNames = '[' + (
		SELECT Title + '],[' 
		FROM Custom_Field 
		WHERE Validation_Type <> 3
		FOR XML PATH('')) ;
	-- Cut off the final ",["
	SET @ColNames = SUBSTRING(@ColNames, 1, LEN(@ColNames)-2);
	
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
			' + IsNull(',' + @ColNames, '') + ' 
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
				AND Intelledox_User.Business_Unit_GUID = CONVERT(uniqueidentifier, ''' + @BusinessUnitGUID + ''')
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
			' + IsNull('PIVOT (MAX(Custom_Value) FOR CustomFieldTitle IN (' + @ColNames + ')) AS PivotedData', '') + 
			' ORDER BY Username';
		
	EXECUTE sp_executesql @SQL;
 
	SET @ErrorCode = @@error;
GO
CREATE procedure [dbo].[spUsers_UserGroupByUser]
    @UserID int,
    @BusinessUnitGUID uniqueidentifier,
    @Username nvarchar(50) = '',
    @UserGroupID int = 0,
    @UserGuid uniqueidentifier = null,
    @ShowActive int = 0,
    @ErrorCode int = 0 output
as
    if @UserGroupID = 0	--all user groups
    begin
        if @UserGuid is null
        begin
            if @UserID is null or @UserID = 0
            begin
                select	a.*, Business_Unit.DefaultLanguage
                from	Intelledox_User a
                    left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
                where	(@Username = '' OR @Username is null OR a.[Username] like @Username + '%')
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
                AND	(@Username = '' OR @Username is null OR a.[Username] like @Username + '%')
                AND	a.User_Guid not in (
                        select a.userGuid
                        from user_group_subscription a 
                        inner join user_Group b on a.GroupGuid = b.Group_Guid
                    )
                AND (@UserID <> 0 OR a.Business_Unit_GUID = @BusinessUnitGUID)
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
                AND	(@Username = '' OR @Username is null OR a.[Username] like @Username + '%')
                AND	c.GroupGuid = (SELECT Group_Guid FROM User_Group WHERE User_Group_id = @UserGroupID)
                AND (@UserID <> 0 OR a.Business_Unit_GUID = @BusinessUnitGUID)
                AND (@ShowActive = 0 
                    OR (@ShowActive = 1 AND a.[Disabled] = 0)
                    OR (@ShowActive = 2 AND a.[Disabled] = 1))
            ORDER BY a.[Username]
        end
    end

    set @ErrorCode = @@error;
GO
CREATE procedure [dbo].[spUsers_UserGroupList]
	@UserGroupID int,
	@BusinessUnitGUID uniqueidentifier,
	@ErrorCode int = 0 output
as
	SELECT	*
	FROM	User_Group
	WHERE	(@UserGroupID = 0
				OR @UserGroupID IS NULL
				OR User_Group_ID = @UserGroupID)
			AND (@UserGroupID <> 0 OR Business_Unit_GUID = @BusinessUnitGUID) 
	ORDER BY Name

	set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spUsers_UserGroupUsers]
    @UserGroupID int,
    @ErrorCode int = 0 output
as
    if @UserGroupID = 0
    begin
        --all users without active user groups

        select	a.*,
            b.Full_Name,
            0 as IsDefaultGroup
        from	Intelledox_User a
            left join Address_Book b on a.Address_ID = b.Address_ID
        where	a.User_Guid not in (
                select a.UserGuid
                from user_group_subscription a 
                    inner join user_Group b on a.GroupGuid = b.Group_Guid
            )
    end
    else
    begin
        select	a.*,
            b.Full_Name,
            c.IsDefaultGroup
        from	Intelledox_User a
            left join Address_Book b on a.Address_ID = b.Address_ID
            inner join User_Group_Subscription c on a.User_Guid = c.UserGuid
            inner join user_Group d on c.GroupGuid = d.Group_Guid
        where	d.User_Group_ID = @UserGroupID
    end

    set @ErrorCode = @@error
GO
CREATE procedure [dbo].[spUsers_UserLogin]
    @Username nvarchar(50),
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
CREATE PROCEDURE [dbo].[spVersionNumber]
	@ErrorCode int output
AS
	SELECT * from dbVersion

GO
CREATE procedure [dbo].[spProject_ProjectListFullText]
	@UserGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ProjectTypeId int,
	@SearchString nvarchar(100),
	@FullText NVarChar(1000)
as
	declare @IsGlobal bit
	declare @BusinessUnitGUID uniqueidentifier

	SELECT	@BusinessUnitGUID = Business_Unit_GUID
	FROM	Intelledox_User
	WHERE	User_Guid = @UserGuid;

	IF EXISTS(SELECT	vwUserPermissions.*
		FROM	vwUserPermissions
		WHERE	vwUserPermissions.CanDesignProjects = 1
				AND vwUserPermissions.GroupGuid IS NULL
				AND vwUserPermissions.UserGuid = @UserGuid)
	BEGIN
		SET @IsGlobal = 1;
	END

	if @GroupGuid IS NULL
	begin
		--all usergroups
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, a.template_version, a.import_date, 
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Content_Bookmark, a.Modified_By, lockedByUser.Username AS LockedBy,
				a.FeatureFlags
		FROM	Template a
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		WHERE	(@IsGlobal = 1 or a.template_Guid in (
				SELECT	User_Group_Template.TemplateGuid
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid 
				WHERE	vwUserPermissions.CanDesignProjects = 1
			AND Intelledox_User.User_Guid = @UserGuid
				))
			AND (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
			AND (a.Template_Guid IN (
					SELECT	Template_Guid
					FROM	Template_File tf
					WHERE	Contains(*, @FullText)
				))
		ORDER BY a.[name];
	end
	else
	begin
		--specific user group
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, a.template_version, a.import_date, 
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Content_Bookmark, a.Modified_By, lockedByUser.Username AS LockedBy,
				a.FeatureFlags
		FROM	Template a
				INNER JOIN User_Group_Template d on a.Template_Guid = d.TemplateGuid
				INNER JOIN User_Group ON d.GroupGuid = User_Group.Group_Guid  AND User_Group.Group_Guid = @GroupGuid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		WHERE	(@IsGlobal = 1 or a.template_Guid in (
				SELECT	User_Group_Template.TemplateGuid
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid 
				WHERE	vwUserPermissions.CanDesignProjects = 1
			))
			and (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
			AND (a.Template_Guid IN (
					SELECT	Template_Guid
					FROM	Template_File tf
					WHERE	Contains(*, @FullText)
				))
		ORDER BY a.[name];
	end
GO
CREATE procedure [dbo].[spContent_ContentItemListFullText]
	@ItemGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier,
	@ExactMatch bit,
	@ContentTypeId int,
	@Name NVarChar(255),
	@Description NVarChar(1000),
	@Category int,
	@FullText NVarChar(1000),
	@Approved int = 2,
	@ErrorCode int output,
	@FolderGuid uniqueidentifier,
	@UserId uniqueidentifier,
	@NoFolder bit
as

	UPDATE Content_Item
	SET Approved = 1
	WHERE ExpiryDate < GETDATE()
		AND Approved = 0;

	IF @ItemGuid is null 
		IF @ExactMatch = 1
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
								INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit,
					Content_Folder.FolderName
					
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity = @Name
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
			ORDER BY ci.NameIdentity;
		ELSE
			--Full text search
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Intelledox_User.UserName,
					CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
					CASE WHEN (@UserId IS NULL 
						OR ci.FolderGuid IS NULL 
						OR (NOT EXISTS (
							SELECT * 
							FROM Content_Folder_Group 
							WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
						OR EXISTS (
							SELECT * 
							FROM Content_Folder_Group
								INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
								INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
								INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
							WHERE Intelledox_User.User_Guid = @UserId
								AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
					THEN 1 ELSE 0 END
					AS CanEdit,
					Content_Folder.FolderName
					
			FROM	content_item ci
					LEFT JOIN (
						SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
						FROM	ContentData_Binary
						UNION
						SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
						FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
					LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
					LEFT JOIN (
						SELECT	ContentData_Guid
						FROM	vwContentItemVersionDetails
						WHERE	Approved = 0
						) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
					LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
			WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
					AND ci.NameIdentity LIKE '%' + @Name + '%'
					AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND ci.Description LIKE '%' + @Description + '%'
					AND (@Category = 0 or ci.Category = @Category)
					AND (@Approved = -1 
						OR (@Approved = 0 AND UnapprovedRevisions.ContentData_Guid IS NOT NULL)
						OR ci.Approved = @Approved)
					AND (ci.ContentData_Guid IN (
							SELECT	ContentData_Guid
							FROM	ContentData_Binary cdb
							WHERE	Contains(*, @FullText)
							)
						OR
						ci.ContentData_Guid IN (
							SELECT	ContentData_Guid
							FROM	ContentData_Text cdt
							WHERE	Contains(*, @FullText)
							)
						)
					AND ((@NoFolder = 0 AND (@FolderGuid IS NULL OR ci.FolderGuid = @FolderGuid))
						OR (@NoFolder = 1 AND ci.FolderGuid IS NULL))
			ORDER BY ci.NameIdentity;
	ELSE
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Intelledox_User.UserName,
				CASE WHEN UnapprovedRevisions.ContentData_Guid IS NULL THEN 0 ELSE 1 END as HasUnapprovedRevision,
				CASE WHEN (@UserId IS NULL 
					OR ci.FolderGuid IS NULL 
					OR (NOT EXISTS (
						SELECT * 
						FROM Content_Folder_Group 
						WHERE ci.FolderGuid = Content_Folder_Group.FolderGuid))
					OR EXISTS (
						SELECT * 
						FROM Content_Folder_Group
							INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
							INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
							INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
						WHERE Intelledox_User.User_Guid = @UserId
							AND ci.FolderGuid = Content_Folder_Group.FolderGuid))
				THEN 1 ELSE 0 END
				AS CanEdit,
				Content_Folder.FolderName
					
		FROM	content_item ci
				LEFT JOIN (
					SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
					FROM	ContentData_Binary
					UNION
					SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
					FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
				LEFT JOIN (
					SELECT	ContentData_Guid
					FROM	vwContentItemVersionDetails
					WHERE	Approved = 0
					) UnapprovedRevisions ON ci.ContentData_Guid = UnapprovedRevisions.ContentData_Guid
				LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
					
		WHERE	ci.contentitem_guid = @ItemGuid;
	
	set @ErrorCode = @@error;
GO
CREATE procedure [dbo].[spContent_ContentItemListBySearchFullText]
	@BusinessUnitGuid uniqueidentifier,
	@SearchString NVarChar(1000),
	@FullTextSearchString NVarChar(1000),
	@ContentTypeId Int,
	@FolderGuid uniqueidentifier
AS
	SELECT	ci.*, 
			Content.FileType, 
			Content.Modified_Date, 
			Intelledox_User.UserName,
			0 as HasUnapprovedRevision,
			0 AS CanEdit,
			Content_Folder.FolderName
	FROM	content_item ci
			LEFT JOIN (
				SELECT	ContentData_Guid, Modified_Date, Modified_By, FileType
				FROM	ContentData_Binary
				UNION
				SELECT	ContentData_Guid, Modified_Date, Modified_By, NULL
				FROM	ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By
			LEFT JOIN Category ON ci.Category = Category.Category_ID
			LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
			LEFT JOIN FREETEXTTABLE(ContentData_Binary, *, @FullTextSearchString) as Ftt
				ON ci.ContentData_Guid = Ftt.[Key]
	WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
			AND ci.Approved = 2
			AND ci.ContentType_Id = @ContentTypeId
			AND (ci.NameIdentity LIKE '%' + @SearchString + '%'
				OR ci.Description LIKE '%' + @SearchString + '%'
				OR Category.Name LIKE '%' + @SearchString + '%'
				OR (ci.ContentData_Guid IN (
						SELECT	ContentData_Guid
						FROM	ContentData_Binary cdb
						WHERE	Contains(*, @FullTextSearchString)
						)
					OR
					ci.ContentData_Guid IN (
						SELECT	ContentData_Guid
						FROM	ContentData_Text cdt
						WHERE	Contains(*, @FullTextSearchString)
						)
					)
				)
				--Search all folders/none folder/specific folder
			AND (
				@FolderGuid = '00000000-0000-0000-0000-000000000000' --all
				OR @FolderGuid = '99999999-9999-9999-9999-999999999999'  AND ci.FolderGuid IS NULL --none
				OR ci.FolderGuid = @FolderGuid --a specific folder
				)
	ORDER BY Ftt.Rank DESC, ci.NameIdentity;
GO
SET IDENTITY_INSERT [dbo].[Address_Book] ON 
INSERT [dbo].[Address_Book] ([Address_ID], [Addresstype_ID], [Address_Reference], [Prefix], [First_Name], [Last_Name], [Full_Name], [Salutation_Name], [Title], [Organisation_Name], [Phone_Number], [Fax_Number], [Email_Address], [Street_Address_1], [Street_Address_2], [Street_Address_Suburb], [Street_Address_State], [Street_Address_Postcode], [Street_Address_Country], [Postal_Address_1], [Postal_Address_2], [Postal_Address_Suburb], [Postal_Address_State], [Postal_Address_Postcode], [Postal_Address_Country]) VALUES (1, 0, NULL, NULL, NULL, NULL, N'admin', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
INSERT [dbo].[Address_Book] ([Address_ID], [Addresstype_ID], [Address_Reference], [Prefix], [First_Name], [Last_Name], [Full_Name], [Salutation_Name], [Title], [Organisation_Name], [Phone_Number], [Fax_Number], [Email_Address], [Street_Address_1], [Street_Address_2], [Street_Address_Suburb], [Street_Address_State], [Street_Address_Postcode], [Street_Address_Country], [Postal_Address_1], [Postal_Address_2], [Postal_Address_Suburb], [Postal_Address_State], [Postal_Address_Postcode], [Postal_Address_Country]) VALUES (2, 0, N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
SET IDENTITY_INSERT [dbo].[Address_Book] OFF
GO
SET IDENTITY_INSERT [dbo].[Administrator_Level] ON 
INSERT [dbo].[Administrator_Level] ([AdminLevel_ID], [AdminLevel_Description], [RoleGuid], [Business_Unit_Guid]) VALUES (1, N'End User', N'2778ccfb-ddfb-47a4-92a6-6eb516daf6a7', N'0cc2007e-3344-4059-b368-9bad2b9bd42b')
INSERT [dbo].[Administrator_Level] ([AdminLevel_ID], [AdminLevel_Description], [RoleGuid], [Business_Unit_Guid]) VALUES (3, N'Global Administrator', N'94d5653a-a8fe-4bde-8fef-61577a88ece0', N'0cc2007e-3344-4059-b368-9bad2b9bd42b')
INSERT [dbo].[Administrator_Level] ([AdminLevel_ID], [AdminLevel_Description], [RoleGuid], [Business_Unit_Guid]) VALUES (5, N'Workflow Administrator', N'60b0f9dd-2bb8-4080-a051-7185a9206f4f', N'0cc2007e-3344-4059-b368-9bad2b9bd42b')
SET IDENTITY_INSERT [dbo].[Administrator_Level] OFF
GO
INSERT [dbo].[Business_Unit] ([Business_Unit_GUID], [Name], [SubscriptionType], [ExpiryDate], [TenantFee], [DefaultLanguage], [UserFee], [SamlEnabled], [SamlCertificate], [SamlCertificateType], [SamlCreateUsers], [SamlIssuer], [SamlLoginUrl], [SamlLogoutUrl], [SamlLastLoginFail], [SamlManageEntityId], [SamlProduceEntityId], [DefaultTimezone], [DefaultCulture]) VALUES (N'0cc2007e-3344-4059-b368-9bad2b9bd42b', N'Default', 1, NULL, 150.0000, N'en', 0.0000, 0, N'', 0, 0, N'', N'', N'', N'', N'', N'', N'AUS Eastern Standard Time', N'en-AU')
GO
SET IDENTITY_INSERT [dbo].[Content_Type] ON 
INSERT [dbo].[Content_Type] ([ContentType_Id], [ContentType_Name]) VALUES (1, N'Image')
INSERT [dbo].[Content_Type] ([ContentType_Id], [ContentType_Name]) VALUES (2, N'Text (Unformatted)')
INSERT [dbo].[Content_Type] ([ContentType_Id], [ContentType_Name]) VALUES (3, N'Document Fragment')
SET IDENTITY_INSERT [dbo].[Content_Type] OFF
GO
INSERT [dbo].[dbversion] ([dbversion]) VALUES (N'8.2.0.14')
GO
SET IDENTITY_INSERT [dbo].[Format_Type] ON 
INSERT [dbo].[Format_Type] ([FormatTypeId], [Name], [FileExtension], [Description]) VALUES (1, N'Microsoft Word 97-2003 Document', N'doc', NULL)
INSERT [dbo].[Format_Type] ([FormatTypeId], [Name], [FileExtension], [Description]) VALUES (2, N'Microsoft Word 2003 XML Document', N'xml', NULL)
SET IDENTITY_INSERT [dbo].[Format_Type] OFF
GO
SET IDENTITY_INSERT [dbo].[Global_Options] ON 
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (1, N'ADMIN_AUTH_MODE', N'Admin Centre Authentication Mode (0=Standard, 1=Windows)', N'0')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (2, N'USER_AUTH_MODE', N'User Addin Authentication Mode (0=Standard, 1=Windows)', N'0')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (3, N'WORD_XML', N'Store WordML with templates (0=No, 1=Yes)', N'1')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (5, N'LOG_TEMPLATE', N'Log that a template run been run (0=No, 1=Yes)', N'1')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (6, N'LOG_WIZARD_PAGE', N'Log that a wizard page has been viewed (0=No, 1=Yes)', N'1')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (7, N'LICENSE_HOLDER', N'License Holder Name', N'')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (8, N'MAX_VERSIONS', N'Maximum number of versions that are stored of a project', N'100')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (10, N'TEMP_DOC_FOLDER', N'Temporary Document Folder', N'')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (11, N'CLEANUP_HOURS', N'Hours to keep temporary documents', N'24')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (12, N'REQUIRE_CONTENT_APPROVAL', N'Require content approval', N'False')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (13, N'PDF_FORMAT', N'Default PDF format', N'0')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (14, N'DOCX_FORMAT', N'Default Docx format', N'0')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (15, N'PRODUCER_URL', N'URL to the Producer application', N'')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (16, N'DIRECTOR_URL', N'URL to the Director application', N'')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (17, N'HAS_LEGACY_PROVIDERS', N'Defines whether or not this instance of Intelledox has pre-v8 Delivery/Submission Providers', N'1')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (18, N'DOWNLOADABLE_DOC_NUM', N'Number of Documents to keep available for download per user', N'0')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (19, N'PDF_EMBED_FONTS', N'Default for PDF Full Font Embedding', N'False')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (20, N'FROM_EMAIL_ADDRESS', N'Email address used as "From" address when Infiniti sends automatic emails', N'DoNotReply@intelledox.com')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (21, N'MINIMUM_PASSWORD_LENGTH', N'Minimum length of a user password', N'8')
INSERT [dbo].[Global_Options] ([OptionID], [OptionCode], [OptionDescription], [OptionValue]) VALUES (22, N'DISALLOW_COMMON_PASSWORDS', N'Disallow common passwords', N'True')
SET IDENTITY_INSERT [dbo].[Global_Options] OFF
GO
SET IDENTITY_INSERT [dbo].[Intelledox_User] ON 
INSERT [dbo].[Intelledox_User] ([User_ID], [Username], [pwdhash], [AdminLevel_ID], [WinNT_User], [Business_Unit_GUID], [User_Guid], [SelectedTheme], [ChangePassword], [PwdFormat], [PwdSalt], [Disabled], [Address_ID], [Timezone], [Culture], [Language]) VALUES (1, N'admin', N'/d44lkp9gzLHFurohsXG3NdtmmoNnstR8Nf/AbW5G94=', 3, 0, N'0cc2007e-3344-4059-b368-9bad2b9bd42b', NewId(), NULL, 1, 3, N'82bmtVl6/Ot6xHU5DUIlS7FmZjyiUfU/dbVouyphJpk78Uj8xnX3TrzawE8DjdaN205AQyxU4Ny6g59bWFiLDpI=', 0, 1, NULL, NULL, NULL)
INSERT [dbo].[Intelledox_User] ([User_ID], [Username], [pwdhash], [AdminLevel_ID], [WinNT_User], [Business_Unit_GUID], [User_Guid], [SelectedTheme], [ChangePassword], [PwdFormat], [PwdSalt], [Disabled], [Address_ID], [Timezone], [Culture], [Language]) VALUES (-1, N'Guest', N'', NULL, 0, N'0cc2007e-3344-4059-b368-9bad2b9bd42b', N'99999999-9999-9999-9999-999999999999', N'', 0, 2, N'', 1, 2, NULL, NULL, NULL)
SET IDENTITY_INSERT [dbo].[Intelledox_User] OFF
GO
INSERT [dbo].[Permission] ([PermissionGuid], [Name], [Description]) VALUES (N'bb4f1768-dbc7-46c7-9a52-09159db15a02', N'Licensing', N'Control license keys')
INSERT [dbo].[Permission] ([PermissionGuid], [Name], [Description]) VALUES (N'22a89a6c-c131-4df1-9a4f-50cfc5e69b58', N'Management console', N'Manage queues and monitor current activity')
INSERT [dbo].[Permission] ([PermissionGuid], [Name], [Description]) VALUES (N'73843c3f-21d0-4861-8886-7071e174da04', N'Manage workflow tasks', N'Manage workflow tasks')
INSERT [dbo].[Permission] ([PermissionGuid], [Name], [Description]) VALUES (N'd0416d36-5c3c-4cb7-8686-74432261a87a', N'Change settings', N'Change Intelledox Settings')
INSERT [dbo].[Permission] ([PermissionGuid], [Name], [Description]) VALUES (N'cf0680c8-e5ca-4ace-ac1a-ad6523973cc7', N'Design projects', N'Create and edit projects and questions')
INSERT [dbo].[Permission] ([PermissionGuid], [Name], [Description]) VALUES (N'f9a676ff-93f8-4d15-9f24-b95dd8c01762', N'Content approver', N'Can approve new content and projects')
INSERT [dbo].[Permission] ([PermissionGuid], [Name], [Description]) VALUES (N'b0761cdd-be11-45ee-8133-bf1d6aa65d6d', N'Manage data sources', N'Create, edit and delete data sources')
INSERT [dbo].[Permission] ([PermissionGuid], [Name], [Description]) VALUES (N'09b7187e-e432-4b03-bdc9-c7fc2c82b9f1', N'Manage security', N'Set system level permissions and roles')
INSERT [dbo].[Permission] ([PermissionGuid], [Name], [Description]) VALUES (N'33fc4ffe-9108-4d56-9a08-dd128255d87c', N'Manage groups', N'Create, edit and delete groups and assign users')
INSERT [dbo].[Permission] ([PermissionGuid], [Name], [Description]) VALUES (N'6b96baf3-8a76-4f42-b1e7-df87142444e0', N'Publish projects', N'Publish projects into folders for people to use')
INSERT [dbo].[Permission] ([PermissionGuid], [Name], [Description]) VALUES (N'7d98327c-b4cb-48dc-9ff7-e613c26fa918', N'Manage users', N'Create, edit and delete users')
INSERT [dbo].[Permission] ([PermissionGuid], [Name], [Description]) VALUES (N'fa2c7769-6d15-442e-9f7f-e8ce82590d8d', N'Manage content library', N'Create, edit and delete images and text')
GO
SET IDENTITY_INSERT [dbo].[Question_Type] ON 
INSERT [dbo].[Question_Type] ([Question_Type_ID], [Description], [Web_Type]) VALUES (1, N'Address Prompt', N'1')
INSERT [dbo].[Question_Type] ([Question_Type_ID], [Description], [Web_Type]) VALUES (2, N'Data Field', N'1')
INSERT [dbo].[Question_Type] ([Question_Type_ID], [Description], [Web_Type]) VALUES (3, N'Group Logic', N'1')
INSERT [dbo].[Question_Type] ([Question_Type_ID], [Description], [Web_Type]) VALUES (4, N'Image', N'0')
INSERT [dbo].[Question_Type] ([Question_Type_ID], [Description], [Web_Type]) VALUES (5, N'Sign-off', N'1')
INSERT [dbo].[Question_Type] ([Question_Type_ID], [Description], [Web_Type]) VALUES (6, N'Simple Logic', N'1')
INSERT [dbo].[Question_Type] ([Question_Type_ID], [Description], [Web_Type]) VALUES (7, N'User Prompt', N'1')
INSERT [dbo].[Question_Type] ([Question_Type_ID], [Description], [Web_Type]) VALUES (8, N'Variable', N'1')
INSERT [dbo].[Question_Type] ([Question_Type_ID], [Description], [Web_Type]) VALUES (9, N'Data Table', N'1')
INSERT [dbo].[Question_Type] ([Question_Type_ID], [Description], [Web_Type]) VALUES (10, N'External Document', N'0')
INSERT [dbo].[Question_Type] ([Question_Type_ID], [Description], [Web_Type]) VALUES (11, N'Content Library', N'1')
SET IDENTITY_INSERT [dbo].[Question_Type] OFF
GO
INSERT [dbo].[Role_Permission] ([PermissionGuid], [RoleGuid]) VALUES (N'bb4f1768-dbc7-46c7-9a52-09159db15a02', N'94d5653a-a8fe-4bde-8fef-61577a88ece0')
INSERT [dbo].[Role_Permission] ([PermissionGuid], [RoleGuid]) VALUES (N'22a89a6c-c131-4df1-9a4f-50cfc5e69b58', N'94d5653a-a8fe-4bde-8fef-61577a88ece0')
INSERT [dbo].[Role_Permission] ([PermissionGuid], [RoleGuid]) VALUES (N'73843c3f-21d0-4861-8886-7071e174da04', N'94d5653a-a8fe-4bde-8fef-61577a88ece0')
INSERT [dbo].[Role_Permission] ([PermissionGuid], [RoleGuid]) VALUES (N'73843c3f-21d0-4861-8886-7071e174da04', N'60b0f9dd-2bb8-4080-a051-7185a9206f4f')
INSERT [dbo].[Role_Permission] ([PermissionGuid], [RoleGuid]) VALUES (N'd0416d36-5c3c-4cb7-8686-74432261a87a', N'94d5653a-a8fe-4bde-8fef-61577a88ece0')
INSERT [dbo].[Role_Permission] ([PermissionGuid], [RoleGuid]) VALUES (N'cf0680c8-e5ca-4ace-ac1a-ad6523973cc7', N'94d5653a-a8fe-4bde-8fef-61577a88ece0')
INSERT [dbo].[Role_Permission] ([PermissionGuid], [RoleGuid]) VALUES (N'f9a676ff-93f8-4d15-9f24-b95dd8c01762', N'94d5653a-a8fe-4bde-8fef-61577a88ece0')
INSERT [dbo].[Role_Permission] ([PermissionGuid], [RoleGuid]) VALUES (N'b0761cdd-be11-45ee-8133-bf1d6aa65d6d', N'94d5653a-a8fe-4bde-8fef-61577a88ece0')
INSERT [dbo].[Role_Permission] ([PermissionGuid], [RoleGuid]) VALUES (N'09b7187e-e432-4b03-bdc9-c7fc2c82b9f1', N'94d5653a-a8fe-4bde-8fef-61577a88ece0')
INSERT [dbo].[Role_Permission] ([PermissionGuid], [RoleGuid]) VALUES (N'33fc4ffe-9108-4d56-9a08-dd128255d87c', N'94d5653a-a8fe-4bde-8fef-61577a88ece0')
INSERT [dbo].[Role_Permission] ([PermissionGuid], [RoleGuid]) VALUES (N'6b96baf3-8a76-4f42-b1e7-df87142444e0', N'94d5653a-a8fe-4bde-8fef-61577a88ece0')
INSERT [dbo].[Role_Permission] ([PermissionGuid], [RoleGuid]) VALUES (N'7d98327c-b4cb-48dc-9ff7-e613c26fa918', N'94d5653a-a8fe-4bde-8fef-61577a88ece0')
INSERT [dbo].[Role_Permission] ([PermissionGuid], [RoleGuid]) VALUES (N'fa2c7769-6d15-442e-9f7f-e8ce82590d8d', N'94d5653a-a8fe-4bde-8fef-61577a88ece0')
GO
SET IDENTITY_INSERT [dbo].[User_Group] ON 
INSERT [dbo].[User_Group] ([User_Group_ID], [Name], [WinNT_Group], [Business_Unit_GUID], [Group_Guid], [AutoAssignment], [SystemGroup], [Address_ID]) VALUES (17, N'Infiniti Users', 0, N'0cc2007e-3344-4059-b368-9bad2b9bd42b', N'4396fd90-f339-4443-b9ba-f8264fe6ae6f', 1, 1, NULL)
SET IDENTITY_INSERT [dbo].[User_Group] OFF
GO
INSERT INTO [dbo].[User_Group_Subscription] ([UserGuid], [GroupGuid], [IsDefaultGroup])
SELECT User_Guid, N'4396fd90-f339-4443-b9ba-f8264fe6ae6f', 1
FROM  [dbo].[Intelledox_User]
WHERE UserName = N'admin';
GO
INSERT [dbo].[User_Group_Subscription] ([UserGuid], [GroupGuid], [IsDefaultGroup]) VALUES (N'99999999-9999-9999-9999-999999999999', N'4396fd90-f339-4443-b9ba-f8264fe6ae6f', 1)
GO
INSERT INTO [dbo].[User_Role] ([UserGuid], [RoleGuid], [GroupGuid])
SELECT User_Guid, N'94d5653a-a8fe-4bde-8fef-61577a88ece0', NULL
FROM  [dbo].[Intelledox_User]
WHERE UserName = N'admin';
GO
