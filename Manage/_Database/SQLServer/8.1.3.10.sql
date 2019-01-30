/*
** Database Update package 8.1.3.10
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.1.3.10');
go

--2114
ALTER procedure [dbo].[spProject_RestoreVersion]
	@ProjectGuid uniqueidentifier,
	@VersionNumber int,
	@UserGuid uniqueidentifier
as
	SET NOCOUNT ON
		
	BEGIN TRAN	
	
		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Project_Definition)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,
			Template.Modified_By,
			Template.Project_Definition
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;

		INSERT INTO Template_File_Version 
			(Template_Guid, 
			File_Guid,
			Template_Version, 
			[Binary],
			FormatTypeId)
		SELECT Template_File.Template_Guid,
			Template_File.File_Guid,
			Template.Template_Version,
			Template_File.[Binary],
			Template_File.FormatTypeId
		FROM Template_File
			INNER JOIN Template ON Template_File.Template_Guid = Template.Template_Guid
		WHERE Template.Template_Guid = @ProjectGuid;
			
		UPDATE Template
		SET	Project_Definition = (SELECT Project_Definition
				FROM Template_Version 
				WHERE Template_Guid = @ProjectGuid 
					AND Template_Version = @VersionNumber), 
			Template_Version = Template_Version + 1, 
			Modified_Date = GetUTCdate(),
			Modified_By = @UserGuid
		WHERE	Template_Guid = @ProjectGuid;
		
		DELETE FROM Template_File
		WHERE	Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File(Template_Guid, File_Guid, [Binary], FormatTypeId)
		SELECT	@ProjectGuid, Template_File_Version.File_Guid, Template_File_Version.[Binary],
				Template_File_Version.FormatTypeId
		FROM	Template_File_Version 
		WHERE	Template_Guid = @ProjectGuid 
				AND Template_Version = @VersionNumber; 
				
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS') - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0) > 0)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT MIN(Template_Version) 
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0)
				AND Template_Guid = @ProjectGuid;
		END
	COMMIT
GO


