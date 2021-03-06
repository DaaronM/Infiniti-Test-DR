truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.1.8');
go

ALTER procedure [dbo].[spProject_RestoreVersion]
	@ProjectGuid uniqueidentifier,
	@VersionNumber nvarchar(10),
	@UserGuid uniqueidentifier,
	@RestoreVersionComment nvarchar(50),
	@NextVersion nvarchar(10)
as
	SET NOCOUNT ON

	BEGIN TRAN	
		DECLARE @BusinessUnitGuid uniqueidentifier;

		SELECT TOP 1 @BusinessUnitGuid = Business_Unit_Guid 
		FROM Template
		WHERE Template_Guid = @ProjectGuid;
	
		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Project_Definition,
			Comment,
			IsMajorVersion,
			FeatureFlags,
			EncryptedProjectDefinition)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,	
			Template.Modified_By,
			Template.Project_Definition,
			Template.Comment,
			Template.IsMajorVersion,
			Template.FeatureFlags,
			Template.EncryptedProjectDefinition
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
			
		INSERT INTO Template_File_Version (Template_Guid, File_Guid, Template_Version, [Binary],
				FormatTypeId)
		SELECT	Template.Template_Guid, Template_File.File_Guid, Template.Template_Version, 
				Template_File.[Binary], Template_File.FormatTypeId
		FROM	Template
				INNER JOIN Template_File ON Template.Template_Guid = Template_File.Template_Guid
		WHERE	Template.Template_Guid = @ProjectGuid;
		
		UPDATE	Template
		SET		Project_Definition = Template_Version.Project_Definition, 
				Template_Version = @NextVersion, 
				Comment = @RestoreVersionComment,
				Modified_Date = GetUTCdate(),
				Modified_By = @UserGuid,
				IsMajorVersion = 1,
				FeatureFlags = Template_Version.FeatureFlags,
				EncryptedProjectDefinition = Template_Version.EncryptedProjectDefinition
		FROM	Template
				INNER JOIN Template_Version ON Template.Template_Guid = Template_Version.Template_Guid
		WHERE	Template_Version.Template_Guid = @ProjectGuid
				AND Template_Version.Template_Version = @VersionNumber
		
		DELETE FROM Template_File
		WHERE	Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File(Template_Guid, File_Guid, [Binary], FormatTypeId)
		SELECT	@ProjectGuid, Template_File_Version.File_Guid, Template_File_Version.[Binary],
				Template_File_Version.FormatTypeId
		FROM	Template_File_Version 
		WHERE	Template_Guid = @ProjectGuid 
				AND Template_Version = @VersionNumber; 
				
		EXEC spProject_DeleteOldProjectVersion @ProjectGuid=@ProjectGuid, 
			@NextVersion=@NextVersion,
			@BusinessUnitGuid=@BusinessUnitGuid;

		EXEC spProjectGroup_UpdateFeatureFlags @ProjectGuid=@ProjectGuid;
		
		--copy over dependencies from the source version
		INSERT INTO Xtf_ContentLibrary_Dependency(Template_Guid, Template_Version, Content_Object_Guid, Display_Type)
		SELECT	Template_Guid, @NextVersion, Content_Object_Guid, Display_Type
		FROM	Xtf_ContentLibrary_Dependency
		WHERE	Template_Guid = @ProjectGuid 
				AND Template_Version = @VersionNumber;
				
		INSERT INTO Xtf_Datasource_Dependency(Template_Guid, Template_Version, Data_Object_Guid)
		SELECT	Template_Guid, @NextVersion, Data_Object_Guid
		FROM	Xtf_Datasource_Dependency
		WHERE	Template_Guid = @ProjectGuid 
				AND Template_Version = @VersionNumber;
				
		INSERT INTO Xtf_Fragment_Dependency(Template_Guid, Template_Version, Fragment_Guid)
		SELECT	Template_Guid, @NextVersion, Fragment_Guid
		FROM	Xtf_Fragment_Dependency
		WHERE	Template_Guid = @ProjectGuid 
				AND Template_Version = @VersionNumber;
	COMMIT

GO
ALTER PROCEDURE [dbo].[spLibrary_GetBinary] (
	@UniqueId as uniqueidentifier,
	@VersionNumber as varchar(50),
	@PublishedBy as datetime
)
AS
	If @VersionNumber = '0'
	BEGIN
		IF @PublishedBy IS NULL
		BEGIN
			SELECT	cd.ContentData as [Binary]
			FROM	ContentData_Binary cd
					INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
			WHERE	ContentItem_Guid = @UniqueId
			OPTION (RECOMPILE);  -- Getting bad index selection because of the next query
		END
		ELSE
		BEGIN
			SELECT	cd.ContentData as [Binary]
			FROM	ContentData_Binary cd
					INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
			WHERE	ContentItem_Guid = @UniqueId
				AND cd.Modified_Date <= @PublishedBy
			UNION
			SELECT	cd.ContentData as [Binary]
			FROM	ContentData_Binary_Version cd
					INNER JOIN Content_Item ON cd.ContentData_Guid = Content_Item.ContentData_Guid
					INNER JOIN ContentData_Binary ON ContentData_Binary.ContentData_Guid = Content_Item.ContentData_Guid
			WHERE	ContentItem_Guid = @UniqueId
					AND ContentData_Binary.Modified_Date > @PublishedBy
					AND cd.Modified_Date = 
						(SELECT MAX(LatestValidVersionBinary.Modified_Date)
						FROM ContentData_Binary_Version LatestValidVersionBinary
							INNER JOIN Content_Item LatestValidVersion ON LatestValidVersion.ContentData_Guid = LatestValidVersionBinary.ContentData_Guid
						WHERE LatestValidVersion.ContentItem_Guid = @UniqueId
							AND LatestValidVersionBinary.Modified_Date <= @PublishedBy)
			OPTION (RECOMPILE);
		END
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
				AND cd.ContentData_Version = @VersionNumber
		OPTION (RECOMPILE);
	END

GO

--check whether user table has duplicate usernames
DECLARE @recordCount int
SELECT @recordCount = COUNT(Username)
	FROM dbo.Intelledox_User
	GROUP BY Username
	HAVING COUNT(Username) > 1

IF (@recordCount) > 0
	BEGIN
		INSERT INTO EventLog (DateTime, Message, LevelID)
		VALUES (GETUTCDATE(), 'Detected multiple users with same username in the table Intelledox_User - Intelledox unique username index not updated', 1);
	END
ELSE
	BEGIN
		DROP INDEX dbo.Intelledox_User.IX_Intelledox_User_Username;
		
		CREATE UNIQUE INDEX IX_Intelledox_User_Username ON dbo.Intelledox_User 
		(
			Username ASC
		)
	END
	
GO
