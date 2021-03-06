truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.2');
go

ALTER PROCEDURE [dbo].[spProject_DependentContentItems] (  
 @ProjectGuid uniqueidentifier,  
 @Version nvarchar(10)  
)  
AS  
  SELECT DISTINCT Content_Item.ContentItem_Guid,  
   ContentData.ContentData_Version,  
   Content_Item.NameIdentity,  
   ContentData.FileType,
   Content_Item.ContentType_Id  
  FROM Xtf_ContentLibrary_Dependency  
   INNER JOIN Content_Item ON Xtf_ContentLibrary_Dependency.Content_Object_Guid = Content_Item.ContentItem_Guid  
   INNER JOIN (SELECT ContentData_Binary.ContentData_Guid, ContentData_Binary.ContentData_Version,  ContentData_Binary.FileType
    FROM ContentData_Binary  
	UNION ALL 
    SELECT ContentData_Text.ContentData_Guid, ContentData_Text.ContentData_Version, ''
    FROM ContentData_Text) ContentData  
	ON (Content_Item.ContentData_Guid = ContentData.ContentData_Guid)
   INNER JOIN  (SELECT Template.Template_Guid  
      FROM Template  
      WHERE Template.Template_Guid = @ProjectGuid  
      AND Template.Template_Version = @Version  
     UNION  
      SELECT Template_Version.Template_Guid  
      FROM Template_Version  
      WHERE Template_Version.Template_Guid = @ProjectGuid  
      AND Template_Version.Template_Version = @Version
	   ) TemplateVersion  
    ON TemplateVersion.Template_Guid = Xtf_ContentLibrary_Dependency.Template_Guid  
  WHERE Xtf_ContentLibrary_Dependency.Display_Type = '8'
GO

ALTER TABLE dbo.Business_Unit ADD
	LicenseFile nvarchar(MAX) NULL,
	TenancyKeyDateUtc datetime NULL;
GO

UPDATE Business_Unit
SET TenancyKeyDateUtc = GETUTCDATE();
GO

CREATE PROCEDURE spLicense_UpdateLicenseFile
	@BusinessUnitGuid uniqueidentifier, 
	@LicenseFile nvarchar(MAX)
AS
BEGIN
	UPDATE Business_Unit
	SET LicenseFile = @LicenseFile
	WHERE Business_Unit_GUID = @BusinessUnitGuid;
END
GO

CREATE PROCEDURE spLicense_GetLicenseFile
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN

	SELECT LicenseFile
	FROM Business_Unit
	WHERE Business_Unit_GUID = @BusinessUnitGuid;
END
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
	@TenantKey varbinary(50),
	@Eula nvarchar(max),
	@EnforceEula bit,
	@TenancyKeyDateUtc datetime = NULL
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
			TenantKey = @TenantKey,
			Eula = @Eula,
			EnforceEula = @EnforceEula,
			TenancyKeyDateUtc = @TenancyKeyDateUtc
	WHERE	Business_Unit_Guid = @BusinessUnitGuid;

GO

INSERT INTO Global_Options (BusinessUnitGuid,OptionCode,OptionDescription,OptionValue)
SELECT bu.Business_Unit_GUID,'ESCAPE_EXCEL_FORMULA','Default for handling data that could be interpreted as an excel formula', 'True'
FROM Business_Unit bu
GO

ALTER TABLE ContentData_Binary
	ADD VersionComment [nvarchar](max) NULL
GO

ALTER TABLE ContentData_Binary_Version
	ADD VersionComment [nvarchar](max) NULL
GO

ALTER TABLE ContentData_Text
	ADD VersionComment [nvarchar](max) NULL
GO

ALTER TABLE ContentData_Text_Version
	ADD VersionComment [nvarchar](max) NULL
GO

ALTER PROCEDURE [dbo].[spLibrary_UpdateBinary] (
	@UniqueId as uniqueidentifier,
	@ContentData as image,
	@Extension as varchar(5),
	@UserGuid as uniqueidentifier,
	@VersionComment as nvarchar(max)
)
AS
	DECLARE @ContentData_Guid uniqueidentifier;
	DECLARE @ContentItem_Guid uniqueidentifier;
	DECLARE @BusinessUnitGuid uniqueidentifier;
	DECLARE @Approvals nvarchar(10);
	DECLARE @MaxVersion int;
	DECLARE @CIApproved int;

	SET NOCOUNT ON;

	SELECT	@ContentData_Guid = ContentData_Guid, 
			@ContentItem_Guid = ContentItem_Guid,
			@BusinessUnitGuid = Business_Unit_Guid,
			@CIApproved = Approved
	FROM	Content_Item
	WHERE	ContentItem_Guid = @UniqueId;
	
	SELECT	@Approvals = OptionValue
	FROM	Global_Options
	WHERE	OptionCode = 'REQUIRE_CONTENT_APPROVAL'
			AND BusinessUnitGuid = @BusinessUnitGuid;


	IF (@Approvals = 'true')
	BEGIN
		IF @ContentData_Guid IS NULL OR NOT EXISTS(SELECT ContentData_Guid 
												FROM ContentData_Binary 
												WHERE	ContentData_Guid = @ContentData_Guid)
		BEGIN
			SET	@ContentData_Guid = newid();
			
			INSERT INTO ContentData_Binary(ContentData_Guid, ContentData, FileType, ContentData_Version, Modified_Date, Modified_By, VersionComment)
			VALUES (@ContentData_Guid, @ContentData, @Extension, 1, getUTCdate(), @UserGuid, @VersionComment);

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
				EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 1, @UniqueId;
				
				UPDATE	ContentData_Binary
				SET		ContentData = @ContentData,
						FileType = @Extension,
						Modified_Date = getUTCdate(),
						Modified_By = @UserGuid,
						ContentData_Version = ContentData_Version + 1,
						VersionComment = @VersionComment
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
				INSERT INTO ContentData_Binary_Version(ContentData_Guid, ContentData, FileType, ContentData_Version, Modified_Date, Modified_By, Approved, VersionComment)
				VALUES (@ContentData_Guid, @ContentData, @Extension, IsNull(@MaxVersion, 0) + 1, getUTCdate(), @UserGuid, 0, @VersionComment);
			END
				
			IF (SELECT COUNT(*)
				FROM	Template
					INNER JOIN Template_Group ON Template_Group.Layout_Guid = Template.Template_Guid OR Template_Group.Template_Guid = Template.Template_Guid
					INNER JOIN Xtf_ContentLibrary_Dependency on Xtf_ContentLibrary_Dependency.Template_Guid = Template.Template_Guid
				WHERE	Template_Group.MatchProjectVersion = 1
						AND Xtf_ContentLibrary_Dependency.Content_Object_Guid = @ContentData_Guid) = 0
			BEGIN
				EXEC spLibrary_ClearExcessVersions @ContentData_Guid, 0;
			END
			
		END
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT ContentData_Guid FROM ContentData_Binary WHERE ContentData_Guid = @ContentData_Guid)
		BEGIN
			EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 1, @UniqueId;
			
			UPDATE	ContentData_Binary
			SET		ContentData = @ContentData,
					FileType = @Extension,
					VersionComment = @VersionComment
			WHERE	ContentData_Guid = @ContentData_Guid;
		END
		ELSE
		BEGIN
			IF @ContentItem_Guid IS NOT NULL
			BEGIN
				SET	@ContentData_Guid = newid();

				INSERT INTO ContentData_Binary(ContentData_Guid, ContentData, FileType, ContentData_Version, VersionComment)
				VALUES (@ContentData_Guid, @ContentData, @Extension, 0, @VersionComment);

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
					ContentData_Version = ContentData_Version + 1,
					VersionComment = @VersionComment
			WHERE	ContentData_Guid = @ContentData_Guid;
		END
	END

	DELETE	FROM Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItem_Guid;
	
	UPDATE	Content_Item
	SET		IsIndexed = 0
	WHERE	ContentItem_Guid = @ContentItem_Guid;

GO

ALTER PROCEDURE [dbo].[spLibrary_UpdateText] (
	@UniqueId as uniqueidentifier,
	@ContentData as nvarchar(max),
	@UserGuid as uniqueidentifier,
	@VersionComment as nvarchar(max)
)
AS
	DECLARE @ContentData_Guid uniqueidentifier;
	DECLARE @BusinessUnitGuid uniqueidentifier;
	DECLARE @Approvals nvarchar(10);
	DECLARE @MaxVersion int;

	SELECT	@ContentData_Guid = ContentData_Guid,
			@BusinessUnitGuid = Business_Unit_Guid
	FROM	Content_Item
	WHERE	ContentItem_Guid = @UniqueId
	
	SELECT	@Approvals = OptionValue
	FROM	Global_Options
	WHERE	OptionCode = 'REQUIRE_CONTENT_APPROVAL'
			AND BusinessUnitGuid = @BusinessUnitGuid;


	IF (@Approvals = 'true')
	BEGIN
		IF @ContentData_Guid IS NULL OR NOT EXISTS(SELECT ContentData_Guid 
												FROM ContentData_Text 
												WHERE	ContentData_Guid = @ContentData_Guid)
		BEGIN
			SET	@ContentData_Guid = newid();
			
			INSERT INTO ContentData_Text(ContentData_Guid, ContentData, ContentData_Version, Modified_Date, Modified_By, VersionComment)
			VALUES (@ContentData_Guid, @ContentData, 1, getUTCdate(), @UserGuid, @VersionComment)

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
			INSERT INTO ContentData_Text_Version(ContentData_Guid, ContentData, ContentData_Version, Modified_Date, Modified_By, Approved, VersionComment)
			VALUES (@ContentData_Guid, @ContentData, IsNull(@MaxVersion, 0) + 1, getUTCdate(), @UserGuid, 0, @VersionComment);
			
			IF (SELECT COUNT(*)
				FROM	Template
					INNER JOIN Template_Group ON Template_Group.Layout_Guid = Template.Template_Guid OR Template_Group.Template_Guid = Template.Template_Guid
					INNER JOIN Xtf_ContentLibrary_Dependency on Xtf_ContentLibrary_Dependency.Template_Guid = Template.Template_Guid
				WHERE	Template_Group.MatchProjectVersion = 1
						AND Xtf_ContentLibrary_Dependency.Content_Object_Guid = @UniqueId) = 0
			BEGIN
				EXEC spLibrary_ClearExcessVersions @ContentData_Guid, 0;
			END
		END
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT ContentData_Guid FROM ContentData_Text WHERE ContentData_Guid = @ContentData_Guid)
		BEGIN
			EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, 0, @UniqueId;
			
			UPDATE	ContentData_Text
			SET		ContentData = @ContentData,
					VersionComment = @VersionComment
			WHERE	ContentData_Guid = @ContentData_Guid
		END
		ELSE
		BEGIN
			SET	@ContentData_Guid = newid()

			INSERT INTO ContentData_Text(ContentData_Guid, ContentData, ContentData_Version, VersionComment)
			VALUES (@ContentData_Guid, @ContentData, 0, @VersionComment)

			UPDATE	Content_Item
			SET		ContentData_Guid = @ContentData_Guid
			WHERE	ContentItem_Guid = @UniqueId
		END
		
		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE	ContentData_Text
			SET		Modified_Date = getUTCdate(),
					Modified_By = @UserGuid,
					ContentData_Version = ContentData_Version + 1,
					VersionComment = @VersionComment
			WHERE	ContentData_Guid = @ContentData_Guid;
		END
	END

GO

ALTER PROCEDURE [dbo].[spLibrary_AddNewLibraryVersion]
	@ContentData_Guid uniqueidentifier,
	@IsBinary bit,
	@ContentItem_Guid varchar(40)
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
			Approved,
			VersionComment)
		SELECT ContentData_Binary.ContentData_Version,
			ContentData_Binary.ContentData_Guid,
			ContentData_Binary.ContentData,
			ContentData_Binary.FileType,
			ContentData_Binary.Modified_Date,
			ContentData_Binary.Modified_By,
			CASE Content_Item.Approved WHEN 0 THEN 1 ELSE Content_Item.Approved END AS Approved,
			ContentData_Binary.VersionComment
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
			Approved,
			VersionComment)
		SELECT ContentData_Text.ContentData_Version,
			ContentData_Text.ContentData_Guid,
			ContentData_Text.ContentData,
			ContentData_Text.Modified_Date,
			ContentData_Text.Modified_By,
			CASE Content_Item.Approved WHEN 0 THEN 1 ELSE Content_Item.Approved END AS Approved,
			ContentData_Text.VersionComment
		FROM ContentData_Text
			INNER JOIN Content_Item ON ContentData_Text.ContentData_Guid = Content_Item.ContentData_Guid
		WHERE ContentData_Text.ContentData_Guid = @ContentData_Guid;
	END
	
	IF (SELECT COUNT(*)
		FROM	Template
			INNER JOIN Template_Group ON Template_Group.Layout_Guid = Template.Template_Guid OR Template_Group.Template_Guid = Template.Template_Guid
			INNER JOIN Xtf_ContentLibrary_Dependency on Xtf_ContentLibrary_Dependency.Template_Guid = Template.Template_Guid
		WHERE	Template_Group.MatchProjectVersion = 1
			AND Xtf_ContentLibrary_Dependency.Content_Object_Guid = @ContentItem_Guid) = 0
	BEGIN
		EXEC spLibrary_ClearExcessVersions @ContentData_Guid, @IsBinary;
	END
			
	COMMIT

GO

ALTER VIEW [dbo].[vwContentItemVersionDetails]
AS
	SELECT	ContentData_Version, ContentData_Guid, Modified_Date, Modified_By, Approved, VersionComment
	FROM	ContentData_Binary_Version
	UNION
	SELECT	ContentData_Version, ContentData_Guid, Modified_Date, Modified_By, Approved, VersionComment
	FROM	ContentData_Text_Version


GO

ALTER procedure [dbo].[spLibrary_GetContentVersions]
	@ContentItemGuid uniqueidentifier
as
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @Approved Int
	DECLARE @ExpiryDate datetime
	
	UPDATE Content_Item
	SET Approved = 1
	WHERE ExpiryDate < GETDATE()
		And ContentItem_Guid = @ContentItemGuid;

	SELECT	@ContentData_Guid = ContentData_Guid, @Approved = Approved, @ExpiryDate = ExpiryDate
	FROM	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;

	SELECT	ContentData_Version, Modified_Date, Versions.Modified_By, Intelledox_User.Username,
			Approved, ExpiryDate, Versions.VersionComment
	FROM	(SELECT	ContentData_Guid, 
				Modified_Date, 
				Modified_By, 
				ContentData_Version, 
				@Approved as Approved, 
				@ExpiryDate AS ExpiryDate,
				VersionComment
			FROM	ContentData_Binary
			UNION
			SELECT	ContentData_Guid, 
				Modified_Date, 
				Modified_By, 
				ContentData_Version, 
				Approved, 
				NULL AS ExpiryDate,
				VersionComment
			FROM	ContentData_Binary_Version
			UNION
			SELECT	ContentData_Guid, 
				Modified_Date, 
				Modified_By, 
				ContentData_Version, 
				@Approved as Approved, 
				@ExpiryDate AS ExpiryDate,
				VersionComment
			FROM	ContentData_Text
			UNION
			SELECT	ContentData_Guid, 
				Modified_Date, 
				Modified_By, 
				ContentData_Version, 
				Approved, 
				NULL AS ExpiryDate,
				VersionComment
			FROM	ContentData_Text_Version) Versions
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Versions.Modified_By
	WHERE	ContentData_Guid = @ContentData_Guid
	ORDER BY ContentData_Version DESC;
GO

ALTER procedure [dbo].[spLibrary_ApproveVersion]
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
				Approved,
				VersionComment)
			SELECT ContentData_Binary.ContentData_Version,
				ContentData_Binary.ContentData_Guid,
				ContentData_Binary.ContentData,
				ContentData_Binary.FileType,
				ContentData_Binary.Modified_Date,
				ContentData_Binary.Modified_By,
				Content_Item.Approved,
				ContentData_Binary.VersionComment
			FROM	ContentData_Binary
					INNER JOIN Content_Item ON ContentData_Binary.ContentData_Guid = Content_Item.ContentData_Guid
			WHERE	ContentData_Binary.ContentData_Guid = @ContentData_Guid;
			
			--Copy approved version into current
			UPDATE	ContentData_Binary
			SET		ContentData = ContentData_Binary_Version.ContentData, 
					FileType = ContentData_Binary_Version.FileType,
					ContentData_Version = @VersionNumber,
					Modified_Date = ContentData_Binary_Version.Modified_Date,
					Modified_By = ContentData_Binary_Version.Modified_By,
					VersionComment = ContentData_Binary_Version.VersionComment
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
				Approved,
				VersionComment)
			SELECT ContentData_Text.ContentData_Version,
				ContentData_Text.ContentData_Guid,
				ContentData_Text.ContentData,
				ContentData_Text.Modified_Date,
				ContentData_Text.Modified_By,
				Content_Item.Approved,
				ContentData_Text.VersionComment
			FROM	ContentData_Text
					INNER JOIN Content_Item ON ContentData_Text.ContentData_Guid = Content_Item.ContentData_Guid
			WHERE ContentData_Text.ContentData_Guid = @ContentData_Guid;
			
			--Copy approved version into current
			UPDATE	ContentData_Text
			SET		ContentData = ContentData_Text_Version.ContentData, 
					ContentData_Version = @VersionNumber, 
					Modified_Date = ContentData_Text_Version.Modified_Date,
					Modified_By = ContentData_Text_Version.Modified_By,
					VersionComment = ContentData_Text_Version.VersionComment
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
	
	IF (SELECT COUNT(*)
		FROM	Template
			INNER JOIN Template_Group ON Template_Group.Layout_Guid = Template.Template_Guid OR Template_Group.Template_Guid = Template.Template_Guid
			INNER JOIN Xtf_ContentLibrary_Dependency on Xtf_ContentLibrary_Dependency.Template_Guid = Template.Template_Guid
		WHERE	Template_Group.MatchProjectVersion = 1
			AND Xtf_ContentLibrary_Dependency.Content_Object_Guid = @ContentItemGuid) = 0
	BEGIN
		EXEC spLibrary_ClearExcessVersions @ContentData_Guid, @IsBinary;
	END
	
	COMMIT
GO

ALTER procedure [dbo].[spLibrary_RestoreVersion]
	@ContentItemGuid uniqueidentifier,
	@VersionNumber int,
	@UserGuid uniqueidentifier,
	@RestoreVersionComment nvarchar(max)
AS
	SET NOCOUNT ON
	
	DECLARE @ContentData_Guid uniqueidentifier
	DECLARE @IsBinary bit
	
	SELECT	@ContentData_Guid = ContentData_Guid, 
			@IsBinary = CASE WHEN ContentType_Id = 2 THEN 0 ELSE 1 END
	FROM	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;
		
	BEGIN TRAN	
	
	EXEC spLibrary_AddNewLibraryVersion @ContentData_Guid, @IsBinary, @ContentItemGuid;
	
	IF (@IsBinary = 1)
	BEGIN
		UPDATE	ContentData_Binary
		SET		ContentData = ContentData_Binary_Version.ContentData, 
				FileType = ContentData_Binary_Version.FileType,
				ContentData_Version = ContentData_Binary.ContentData_Version + 1, 
				Modified_Date = GetUTCdate(),
				Modified_By = @UserGuid,
				VersionComment = @RestoreVersionComment
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
				Modified_By = @UserGuid,
				VersionComment = @RestoreVersionComment
		FROM	ContentData_Text, 
				ContentData_Text_Version
		WHERE	ContentData_Text.ContentData_Guid = @ContentData_Guid
				AND ContentData_Text_Version.ContentData_Guid = @ContentData_Guid 
				AND	ContentData_Text_Version.ContentData_Version = @VersionNumber;
	END
		
	IF (SELECT COUNT(*)
		FROM	Template
			INNER JOIN Template_Group ON Template_Group.Layout_Guid = Template.Template_Guid OR Template_Group.Template_Guid = Template.Template_Guid
			INNER JOIN Xtf_ContentLibrary_Dependency on Xtf_ContentLibrary_Dependency.Template_Guid = Template.Template_Guid
		WHERE	Template_Group.MatchProjectVersion = 1
			AND Xtf_ContentLibrary_Dependency.Content_Object_Guid = @ContentItemGuid) = 0
	BEGIN
		EXEC spLibrary_ClearExcessVersions @ContentData_Guid, @IsBinary;
	END
	
	UPDATE	Content_Item
	SET		IsIndexed = 0
	WHERE	ContentItem_Guid = @ContentItemGuid;
	
	DELETE	Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItemGuid;
		
	COMMIT

GO

DELETE FROM Global_Options
WHERE OptionCode = 'GUEST_LOGGUID'
GO

ALTER TABLE Content_Folder
	ADD ParentFolderGuid uniqueidentifier NULL
GO
ALTER procedure [dbo].[spContent_UpdateContentFolder]
	@FolderGuid uniqueidentifier,
	@Name nvarchar(100),
	@BusinessUnitGUID uniqueidentifier,
	@ParentFolderGuid uniqueidentifier
AS
	IF EXISTS(SELECT * FROM Content_Folder WHERE FolderGuid = @FolderGuid)
	BEGIN
		UPDATE	Content_Folder
		SET		FolderName = @Name
		WHERE	FolderGuid = @FolderGuid;
	END
	ELSE
	BEGIN
		INSERT INTO Content_Folder(FolderName, BusinessUnitGuid, FolderGuid, ParentFolderGuid)
		VALUES (@Name, @BusinessUnitGUID, @FolderGuid, @ParentFolderGuid)
	END
GO
ALTER procedure [dbo].[spContent_RemoveContentFolder]
	@FolderGuid uniqueidentifier
AS

	WITH ContentFolderCte (FolderGuid)
	AS
	( 
		SELECT @FolderGuid
		UNION ALL
		SELECT Content_Folder.FolderGuid
		FROM Content_Folder
			INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid
	)
	DELETE Content_Folder_Group
	FROM ContentFolderCte
	WHERE ContentFolderCte.FolderGuid = Content_Folder_Group.FolderGuid;
	

	WITH ContentFolderCte (FolderGuid)
	AS
	( 
		SELECT @FolderGuid
		UNION ALL
		SELECT Content_Folder.FolderGuid
		FROM Content_Folder
			INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid
	)
	DELETE Content_Item
	FROM ContentFolderCte
	WHERE ContentFolderCte.FolderGuid = Content_Item.FolderGuid;


	WITH ContentFolderCte (FolderGuid)
	AS
	( 
		SELECT @FolderGuid
		UNION ALL
		SELECT Content_Folder.FolderGuid
		FROM Content_Folder
			INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid
	)
	DELETE Content_Folder
	FROM ContentFolderCte
	WHERE ContentFolderCte.FolderGuid = Content_Folder.FolderGuid;
GO
ALTER procedure [dbo].[spContent_ContentItemListBySearch]
	@BusinessUnitGuid uniqueidentifier,
	@SearchString NVarChar(1000),
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
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Content.Modified_By,
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
				LEFT JOIN Content_Folder ON ci.FolderGuid = Content_Folder.FolderGuid
		WHERE	ci.Business_Unit_GUID = @BusinessUnitGuid
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
		SELECT	ci.*, 
				Content.FileType, 
				Content.Modified_Date, 
				Content.Modified_By,
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
ALTER procedure [dbo].[spContent_ContentItemListBySearchFullText]
	@BusinessUnitGuid uniqueidentifier,
	@SearchString NVarChar(1000),
	@FullTextSearchString NVarChar(1000),
	@ContentTypeId Int,
	@FolderGuid uniqueidentifier
AS
	WITH ContentFolderCte (FolderGuid)
	AS
	( 
		SELECT @FolderGuid
		UNION ALL
		SELECT Content_Folder.FolderGuid
		FROM Content_Folder
			INNER JOIN ContentFolderCte ON Content_Folder.ParentFolderGuid = ContentFolderCte.FolderGuid
	)
	SELECT	ci.*, 
			Content.FileType, 
			Content.Modified_Date, 
			Content.Modified_By,
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
			AND (ci.NameIdentity COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchString + '%') COLLATE Latin1_General_CI_AI
				OR ci.Description COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchString + '%') COLLATE Latin1_General_CI_AI
				OR Category.Name COLLATE Latin1_General_CI_AI LIKE ('%' + @SearchString + '%') COLLATE Latin1_General_CI_AI
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
				OR ci.FolderGuid in (SELECT FolderGuid FROM ContentFolderCte) --a specific folder
				)
	ORDER BY Ftt.Rank DESC, ci.NameIdentity;
GO
ALTER procedure [dbo].[spContent_ContentItemList]
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
		WHERE ExpiryDate < GETDATE()
			AND Approved = 0;
		
		IF @ExactMatch = 1
			WITH ContentFolderGroupCte (FolderGuid)
			AS
			( 
				SELECT Content_Folder_Group.FolderGuid
				FROM Content_Folder_Group
					INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
					INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
					INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
				WHERE Intelledox_User.User_Guid = @UserId
				UNION ALL
				SELECT Content_Folder.FolderGuid
				FROM Content_Folder
					INNER JOIN ContentFolderGroupCte ON Content_Folder.ParentFolderGuid = ContentFolderGroupCte.FolderGuid
			)
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Content.Modified_By,
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
							FROM ContentFolderGroupCte
							WHERE ci.FolderGuid = ContentFolderGroupCte.FolderGuid))
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
			WITH ContentFolderGroupCte (FolderGuid)
			AS
			( 
				SELECT Content_Folder_Group.FolderGuid
				FROM Content_Folder_Group
					INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
					INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
					INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
				WHERE Intelledox_User.User_Guid = @UserId
				UNION ALL
				SELECT Content_Folder.FolderGuid
				FROM Content_Folder
					INNER JOIN ContentFolderGroupCte ON Content_Folder.ParentFolderGuid = ContentFolderGroupCte.FolderGuid
			)
			SELECT DISTINCT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Content.Modified_By,
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
							FROM ContentFolderGroupCte
							WHERE ci.FolderGuid = ContentFolderGroupCte.FolderGuid))
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
					AND ci.NameIdentity COLLATE Latin1_General_CI_AI LIKE ('%' + @Name + '%') COLLATE Latin1_General_CI_AI
					AND (ci.ContentType_Id = @ContentTypeId OR @ContentTypeId = -1)
					AND ci.Description COLLATE Latin1_General_CI_AI LIKE ('%' + @Description + '%') COLLATE Latin1_General_CI_AI
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
		WHERE	ExpiryDate < GETDATE()
				AND Approved = 0
				AND contentitem_guid = @ItemGuid;
		
		IF (@MinimalGet = 1)
		BEGIN
			SELECT	ci.*, 
					'' as FileType, 
					NULL as Modified_Date, 
					NULL as Modified_By,
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
			WITH ContentFolderGroupCte (FolderGuid)
			AS
			( 
				SELECT Content_Folder_Group.FolderGuid
				FROM Content_Folder_Group
					INNER JOIN User_Group ON Content_Folder_Group.GroupGuid = User_Group.Group_Guid
					INNER JOIN User_Group_Subscription ON User_Group_Subscription.GroupGuid = User_Group.Group_Guid
					INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
				WHERE Intelledox_User.User_Guid = @UserId
				UNION ALL
				SELECT Content_Folder.FolderGuid
				FROM Content_Folder
					INNER JOIN ContentFolderGroupCte ON Content_Folder.ParentFolderGuid = ContentFolderGroupCte.FolderGuid
			)
			SELECT	ci.*, 
					Content.FileType, 
					Content.Modified_Date, 
					Content.Modified_By,
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
							FROM ContentFolderGroupCte
							WHERE ci.FolderGuid = ContentFolderGroupCte.FolderGuid))
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

ALTER TABLE ActionListState ADD StartPageGuid UniqueIdentifier 
GO
