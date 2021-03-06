truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.4.13');
go
ALTER PROCEDURE [dbo].[spProject_DeleteOldProjectVersion]
	@ProjectGuid uniqueidentifier,
	@NextVersion nvarchar(10),
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN

	IF (SELECT COUNT(*) 
		FROM Template_Group 
		WHERE (Template_Group.Layout_Guid = @ProjectGuid OR Template_Group.Template_Guid = @ProjectGuid)
			AND Template_Group.MatchProjectVersion = 1) = 0
	BEGIN
	
		--delete the earliest minor version which does not belong to the next version number
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
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
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
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
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
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

		DELETE FROM Xtf_Datasource_Dependency
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	vwTemplateVersion
					WHERE	Template_Guid = @ProjectGuid);

		DELETE FROM Xtf_ContentLibrary_Dependency
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	vwTemplateVersion
					WHERE	Template_Guid = @ProjectGuid);

		DELETE FROM Xtf_Fragment_Dependency
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	vwTemplateVersion
					WHERE	Template_Guid = @ProjectGuid);
				
		DELETE FROM Template_File_Version
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	vwTemplateVersion
					WHERE	Template_Guid = @ProjectGuid);
	END
END
GO
