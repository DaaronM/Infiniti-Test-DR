truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.1.2');
GO

ALTER procedure [dbo].[spContent_ContentItemListBySearch]  
 @BusinessUnitGuid uniqueidentifier,  
 @SearchString NVarChar(1000) = null,  
 @ContentTypeId Int,  
 @FolderGuid uniqueidentifier  
AS  
 IF @SearchString IS NULL OR @SearchString = ''  
  WITH ContentFolderCte (FolderGuid)  
  AS  
  (   
   SELECT @FolderGuid  
   UNION ALL  
   SELECT Content_Folder.FolderGuid  
   FROM Content_Folder  
    INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid  
  )  
  SELECT ci.*,   
    Content.FileType,   
    Content.Modified_Date,   
    Content.Modified_By,  
    Intelledox_User.UserName,  
    0 as HasUnapprovedRevision,  
    Content_Folder.FolderName  
  FROM content_item ci  
    LEFT JOIN (  
     SELECT ContentData_Guid, Modified_Date, Modified_By, FileType  
     FROM ContentData_Binary  
     UNION  
     SELECT ContentData_Guid, Modified_Date, Modified_By, NULL  
     FROM ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid  
    LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By  
    LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid  
  WHERE ci.Business_Unit_GUID = @BusinessUnitGuid  
    AND ci.Approved = 2  
    AND ci.ContentType_Id = @ContentTypeId  
     --Search all folders/none folder/specific folder  
    AND (  
     @FolderGuid = '00000000-0000-0000-0000-000000000000' --all  
     OR (@FolderGuid = '99999999-9999-9999-9999-999999999999'  AND ci.FolderGuid IS NULL) --none  
     OR ci.FolderGuid in (SELECT FolderGuid FROM ContentFolderCte) --a specific folder  
     )  
  ORDER BY ci.NameIdentity;  
ELSE  
  WITH ContentFolderCte (FolderGuid)  
  AS  
  (   
   SELECT @FolderGuid  
   UNION ALL  
   SELECT Content_Folder.FolderGuid  
   FROM Content_Folder  
    INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid  
  )  
  SELECT ci.*,   
    Content.FileType,   
    Content.Modified_Date,   
    Content.Modified_By,  
    Intelledox_User.UserName,  
    0 as HasUnapprovedRevision,  
    Content_Folder.FolderName  
  FROM content_item ci  
    LEFT JOIN (  
     SELECT ContentData_Guid, Modified_Date, Modified_By, FileType  
     FROM ContentData_Binary  
     UNION  
     SELECT ContentData_Guid, Modified_Date, Modified_By, NULL  
     FROM ContentData_Text) Content ON ci.ContentData_Guid = Content.ContentData_Guid  
    LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Content.Modified_By  
    LEFT JOIN Category ON ci.Category = Category.Category_ID  
    LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid  
  WHERE ci.Business_Unit_GUID = @BusinessUnitGuid  
    AND ci.Approved = 2  
    AND ci.ContentType_Id = @ContentTypeId  
    AND (ci.NameIdentity COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchString + '%') COLLATE Latin1_General_CI_AI  
     OR ci.Description COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchString + '%') COLLATE Latin1_General_CI_AI  
     OR Category.Name COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchString + '%') COLLATE Latin1_General_CI_AI  
     )  
     --Search all folders/none folder/specific folder  
    AND (  
     @FolderGuid = '00000000-0000-0000-0000-000000000000' --all  
     OR (@FolderGuid = '99999999-9999-9999-9999-999999999999'  AND ci.FolderGuid IS NULL) --none  
     OR ci.FolderGuid in (SELECT FolderGuid FROM ContentFolderCte) --a specific folder  
     )  
  ORDER BY ci.NameIdentity;  

GO

ALTER TABLE Data_Service
	ADD [Schema] NVARCHAR(MAX) NULL
GO

ALTER TABLE Data_Service
	ADD [DefaultData] NVARCHAR(MAX) NULL
GO

ALTER TABLE Data_Service ADD
	EncryptedDefaultData varbinary(MAX) NULL
GO

ALTER TABLE Data_Service ADD
	ExportDefaultData BIT NOT NULL DEFAULT 0
GO

ALTER TABLE Data_Service
	ADD UpdatedUTC DateTime NOT NULL DEFAULT GETUTCDATE() 
GO

ALTER PROCEDURE [dbo].[spDataSource_UpdateDataService]
	@DataServiceGuid uniqueidentifier,
	@Name nvarchar(100),
	@ConnectionString nvarchar(MAX),
	@CredentialMethod int,
	@AllowConnectionExport bit,
	@BusinessUnitGuid uniqueidentifier,
	@ProviderName nvarchar(100),
	@Username nvarchar(100),
	@PasswordHash varchar(1000),
	@UpdatedUTC datetime,
	@ExportDefaultData bit
AS
	IF NOT EXISTS(SELECT * FROM Data_Service WHERE data_service_guid = @DataServiceGuid)
		INSERT INTO Data_Service ([name], connection_string, data_service_guid, 
				Credential_Method, Allow_Connection_Export, Business_Unit_Guid, Provider_Name, 
				Username, PasswordHash, UpdatedUTC, ExportDefaultData)
		VALUES (@Name, @ConnectionString, @DataServiceGuid, 
				@CredentialMethod, @AllowConnectionExport, @BusinessUnitGuid, @ProviderName, 
				@Username, @PasswordHash, @UpdatedUTC, @ExportDefaultData);
	ELSE
		UPDATE Data_Service
		SET [name] = @Name,
			connection_string = @ConnectionString,
			Credential_Method = @CredentialMethod,
			Allow_Connection_Export = @AllowConnectionExport,
			Business_Unit_Guid = @BusinessUnitGuid,
			Provider_Name = @ProviderName,
			Username = @Username,
			PasswordHash = @PasswordHash,
			UpdatedUTC = @UpdatedUTC,
			ExportDefaultData = @ExportDefaultData
		WHERE Data_Service_Guid = @DataServiceGuid;
GO

ALTER PROCEDURE [dbo].[spDataSource_DataSourceList]
	@DataServiceGuid uniqueidentifier = null,
	@BusinessUnitGuid uniqueidentifier = null
AS
	IF @DataServiceGuid IS NULL
		SELECT	d.[Name], d.Connection_String, d.Data_Service_Guid,
				d.Allow_WriteBack, d.Credential_Method, d.Allow_Connection_Export,
				d.Business_Unit_Guid, d.Provider_Name, d.Allow_Insert
		FROM	Data_Service d
		WHERE	d.Business_Unit_Guid = @BusinessUnitGuid
		ORDER BY d.[Name]
	ELSE
		SELECT	d.[Name], d.Connection_String, d.Data_Service_Guid,
				d.Allow_WriteBack, d.Credential_Method, d.Allow_Connection_Export,
				d.Business_Unit_Guid, d.Provider_Name, d.Allow_Insert, d.Username, d.PasswordHash,
				CASE WHEN [Schema] IS NULL THEN 0 ELSE 1 END AS HasSchema,
				CASE WHEN DefaultData IS NULL THEN (CASE WHEN EncryptedDefaultData IS NULL THEN 0 ELSE 1 END) ELSE 1 END AS HasDefaultData,
				d.UpdatedUTC, ExportDefaultData
		FROM	Data_Service d
		WHERE	d.data_service_guid = @DataServiceGuid
		ORDER BY d.[Name]
GO

CREATE PROCEDURE [dbo].[spDataSource_GetSchema]
	@DataServiceGuid uniqueidentifier
AS
	SELECT	[SCHEMA]
	FROM	Data_Service
	WHERE	Data_Service_Guid = @DataServiceGuid
GO

CREATE PROCEDURE [dbo].[spDataSource_UpdateSchema]
	@DataServiceGuid uniqueidentifier,
	@Schema nvarchar(max)
AS
	UPDATE Data_Service
	SET [Schema] = @Schema
	WHERE Data_Service_Guid = @DataServiceGuid
GO

CREATE PROCEDURE [dbo].[spDataSource_GetDefaultData]
	@DataServiceGuid uniqueidentifier
AS
	SELECT	DefaultData, EncryptedDefaultData
	FROM	Data_Service
	WHERE	Data_Service_Guid = @DataServiceGuid
GO

CREATE PROCEDURE [dbo].[spDataSource_UpdateDefaultData]
	@DataServiceGuid uniqueidentifier,
	@DefaultData nvarchar(max),
	@EncryptedDefaultData varbinary(MAX)
AS
	UPDATE Data_Service
	SET [DefaultData] = @DefaultData,
	    [EncryptedDefaultData] = @EncryptedDefaultData
	WHERE Data_Service_Guid = @DataServiceGuid
GO

ALTER PROCEDURE [dbo].[spDocument_InsertDocument]
	@DocumentId uniqueidentifier,
	@Extension nvarchar(10),
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier,
	@DisplayName nvarchar(255),
	@DateCreated datetime,
	@DocumentBinary varbinary(max),
	@DocumentLength int,
	@ProjectDocumentGuid uniqueidentifier,
	@ActionOnly bit,
	@RepeatIndices nvarchar(255),
	@Attachment bit,
	@Downloadable bit
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
		ActionOnly,
		RepeatIndices,
		Attachment)
	VALUES (@DocumentId, 
		@Extension, 
		@JobId, 
		@UserGuid, 
		@DisplayName, 
		@DateCreated, 
		@DocumentBinary, 
		@DocumentLength,
		@ProjectDocumentGuid,
		CASE WHEN @ActionOnly = 1 THEN 0 ELSE @Downloadable END,
		@ActionOnly,
		@RepeatIndices,
		@Attachment);

GO

ALTER PROCEDURE [dbo].[spDocument_DocumentList] (
@JobId uniqueidentifier,
	@UserGuid uniqueidentifier,
	@IncludeAllGeneratedDocs bit
)
AS
	IF (@JobId IS NULL)
	BEGIN
		SELECT	TOP 500
				Document.DocumentId, 
				Document.Extension,  
				Document.DisplayName,  
				Document.ProjectDocumentGuid,  
				Document.DateCreated,  
				Document.JobId,
				Document.Downloadable,
				Document.ActionOnly,
				Document.RepeatIndices,
				Template.Name As ProjectName,
				Document.Downloadable
		FROM	Document WITH (NOLOCK)
				INNER JOIN ProcessJob ON Document.JobId = ProcessJob.JobId
				INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
				INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
		WHERE	(@IncludeAllGeneratedDocs = 1 OR Document.Downloadable = 1)
				AND Document.UserGuid = @UserGuid
				AND Document.DocumentLength <> -1;
	END
	ELSE
	BEGIN
		SELECT	Document.DocumentId, 
				Document.Extension,  
				Document.DisplayName,  
				Document.ProjectDocumentGuid,  
				Document.DateCreated,  
				Document.JobId,
				Document.Downloadable,
				Document.ActionOnly,
				Document.RepeatIndices,
				Template.Name As ProjectName,
				Document.Downloadable
		FROM	Document
				INNER JOIN ProcessJob ON Document.JobId = ProcessJob.JobId
				INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
				INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
		WHERE	Document.JobId = @JobId
				AND (@IncludeAllGeneratedDocs = 1 OR Document.Downloadable = 1)
				AND Document.UserGuid = @UserGuid --Security check
				AND Document.DocumentLength <> -1
		ORDER BY Document.DisplayName;
	END

GO




