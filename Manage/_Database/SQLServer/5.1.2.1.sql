/*
** Database Update package 5.1.2.1
*/

--set version
truncate table dbversion
go
insert into dbversion values ('5.1.2.1')
go

--1843
CREATE PROCEDURE dbo.spGetBilling
AS
	DECLARE @CurrentDate DateTime
	DECLARE @LicenseHolder NVarchar(1000)
	
	SET NOCOUNT ON
	
	SET @CurrentDate = CAST(CONVERT(Varchar(10), GETDATE(), 102) AS DateTime)
	
	SELECT @LicenseHolder = OptionValue 
	FROM Global_Options
	WHERE OptionCode = 'LICENSE_HOLDER'

	SELECT	@LicenseHolder as LicenseHolder, CONVERT(Varchar(10), DateTime_Finish, 102) as ActivityDate, 
			COUNT(*) AS DocumentCount
	FROM	Template_Log
	WHERE	Completed = 1
			AND DateTime_Finish BETWEEN DATEADD(d, -30, @CurrentDate) AND @CurrentDate
	GROUP BY CONVERT(Varchar(10), DateTime_Finish, 102)
GO


--1844
--Address_Book_Custom_Field indexes
ALTER TABLE dbo.Address_Book_Custom_Field
	DROP CONSTRAINT PK_Address_Book_Custom_Field_ID
GO
ALTER TABLE dbo.Address_Book_Custom_Field ADD CONSTRAINT
	PK_Address_Book_Custom_Field_ID PRIMARY KEY NONCLUSTERED 
	(
	Address_Book_Custom_Field_ID
	) ON [PRIMARY]

GO
CREATE CLUSTERED INDEX IX_Address_Book_Custom_Field ON dbo.Address_Book_Custom_Field
	(
	Address_ID,
	Custom_Field_ID
	) ON [PRIMARY]
GO


--Answer_File indexes
ALTER TABLE dbo.Answer_File ADD CONSTRAINT
	PK_Answer_File PRIMARY KEY NONCLUSTERED 
	(
	AnswerFile_ID
	) ON [PRIMARY]

GO
CREATE CLUSTERED INDEX IX_Answer_File_UserId ON dbo.Answer_File
	(
	User_ID
	) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX IX_Answer_File_TemplateGroupId ON dbo.Answer_File
	(
	Template_Group_ID
	) ON [PRIMARY]
GO


--Content_Definition indexes
ALTER TABLE dbo.Content_Definition
	DROP CONSTRAINT PK_Content_Definition
GO
ALTER TABLE dbo.Content_Definition ADD CONSTRAINT
	PK_Content_Definition PRIMARY KEY CLUSTERED 
	(
	ContentDefinition_Guid
	) ON [PRIMARY]

GO


--Content_Definition_Item indexes
ALTER TABLE dbo.Content_Definition_Item
	DROP CONSTRAINT PK_ContentDefinition_Item
GO
ALTER TABLE dbo.Content_Definition_Item ADD CONSTRAINT
	PK_ContentDefinition_Item PRIMARY KEY NONCLUSTERED 
	(
	ContentDefinitionItem_Id
	) ON [PRIMARY]

GO
CREATE CLUSTERED INDEX IX_Content_Definition_Item ON dbo.Content_Definition_Item
	(
	ContentDefinition_Guid,
	ContentItem_Guid
	) ON [PRIMARY]
GO


--Content_Item indexes
DROP INDEX IX_Content_Item_Guid ON dbo.Content_Item
GO
ALTER TABLE dbo.Content_Item
	DROP CONSTRAINT PK_Content_Item
GO
ALTER TABLE dbo.Content_Item ADD CONSTRAINT
	PK_Content_Item PRIMARY KEY CLUSTERED 
	(
	ContentItem_Guid
	) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX IX_Content_Item_BusinessUnit ON dbo.Content_Item
	(
	Business_Unit_GUID
	) ON [PRIMARY]
GO


--ContentData_Binary indexes
ALTER TABLE dbo.ContentData_Binary
	DROP CONSTRAINT PK_Content_Binary
GO
ALTER TABLE dbo.ContentData_Binary ADD CONSTRAINT
	PK_Content_Binary PRIMARY KEY CLUSTERED 
	(
	ContentData_Guid
	) ON [PRIMARY]
GO


--ContentData_Text indexes
ALTER TABLE dbo.ContentData_Text
	DROP CONSTRAINT PK_ContentData_Text
GO
ALTER TABLE dbo.ContentData_Text ADD CONSTRAINT
	PK_ContentData_Text PRIMARY KEY CLUSTERED 
	(
	ContentData_Guid
	) ON [PRIMARY]
GO


--Data_Object indexes
ALTER TABLE dbo.Data_Object
	DROP CONSTRAINT PK_Data_Object
GO
DROP INDEX IX_Data_Object_Guid ON dbo.Data_Object
GO
ALTER TABLE dbo.Data_Object
	ALTER COLUMN Data_Object_Guid uniqueidentifier not null
GO
ALTER TABLE dbo.Data_Object ADD CONSTRAINT
	PK_Data_Object PRIMARY KEY NONCLUSTERED 
	(
	Data_Object_Guid
	) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX IX_Data_Object_DataServiceGuid ON dbo.Data_Object
	(
	Data_Service_Guid
	)
GO


--Data_Object_Key indexes
DROP INDEX IX_Data_Object_Key_ObjectGuid ON dbo.Data_Object_Key
GO
ALTER TABLE dbo.Data_Object_Key
	DROP CONSTRAINT Data_Object_Key_pk
GO
ALTER TABLE dbo.Data_Object_Key
	ALTER COLUMN Data_Object_Key_Guid uniqueidentifier not null
GO
ALTER TABLE dbo.Data_Object_Key ADD CONSTRAINT
	PK_Data_Object_Key PRIMARY KEY NONCLUSTERED 
	(
	Data_Object_Key_Guid
	) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX IX_Data_Object_Key_DataObjectGuid ON dbo.Data_Object_Key
	(
	Data_Object_Guid
	) ON [PRIMARY]
GO


--Data_Service indexes
DROP INDEX IX_Data_Service_Guid ON dbo.Data_Service
GO
ALTER TABLE dbo.Data_Service
	DROP CONSTRAINT Data_Service_pk
GO
ALTER TABLE dbo.Data_Service
	ALTER COLUMN Data_Service_Guid uniqueidentifier not null
GO
ALTER TABLE dbo.Data_Service ADD CONSTRAINT
	PK_Data_Service PRIMARY KEY CLUSTERED 
	(
	Data_Service_Guid
	) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX IX_Data_Service_BusinessUnitGuid ON dbo.Data_Service
	(
	Business_Unit_Guid
	) ON [PRIMARY]
GO
exec sp_rename 'dbo.Data_Service_Key', 'zzData_Service_Key'
GO


