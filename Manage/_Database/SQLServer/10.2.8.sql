TRUNCATE TABLE dbversion;
GO
INSERT INTO dbversion(dbversion) VALUES ('10.2.8');
GO

INSERT INTO Global_Options (BusinessUnitGuid,OptionCode,OptionDescription,OptionValue)
SELECT bu.Business_Unit_GUID,'STORE_LOCATION','Whether to request and store location data when analytics module is attached', '0'
FROM Business_Unit bu WHERE bu.Business_Unit_GUID NOT IN (
	SELECT BusinessUnitGuid from Global_Options where OptionCode = 'STORE_LOCATION'
)
GO
ALTER PROCEDURE [dbo].[spProject_DefinitionsByGroup] (
	@TemplateGroupGuid uniqueidentifier,
	@PublishedBy datetime
)
AS
	DECLARE @MatchProjectVersion bit;
	DECLARE @LayoutGuid uniqueidentifier;
	DECLARE @LayoutVersion nvarchar(10);
	DECLARE @TemplateGuid uniqueidentifier;
	DECLARE @TemplateVersion nvarchar(10);

	SELECT	@MatchProjectVersion = Template_Group.MatchProjectVersion,
			@LayoutGuid = Template_Group.Layout_Guid,
			@LayoutVersion = Template_Group.Layout_Version,
			@TemplateGuid = Template_Group.Template_Guid,
			@TemplateVersion = Template_Group.Template_Version
	FROM	Template_Group
	WHERE	Template_Group.Template_Group_Guid = @TemplateGroupGuid

	IF (@MatchProjectVersion = 0 OR @PublishedBy >= '9999-12-31')
	BEGIN
		-- New launches
		SELECT	Template.Template_Guid, 
				Template.Template_Type_ID,
				Template.Template_Version, 
				CASE WHEN Template.EncryptedProjectDefinition IS NULL THEN 0 ELSE 1 END AS Encrypted,
				Template.EncryptedProjectDefinition,
				Template.Project_Definition
		FROM	Template
		WHERE	(Template.Template_Guid = @TemplateGuid AND (@TemplateVersion IS NULL OR Template.Template_Version = @TemplateVersion))
					OR (Template.Template_Guid = @LayoutGuid AND (@LayoutVersion IS NULL OR Template.Template_Version = @LayoutVersion))
		UNION ALL
		SELECT	Template_Version.Template_Guid, 
				Template.Template_Type_ID,
				Template_Version.Template_Version, 
				CASE WHEN Template_Version.EncryptedProjectDefinition IS NULL THEN 0 ELSE 1 END AS Encrypted,
				Template_Version.EncryptedProjectDefinition,
				Template_Version.Project_Definition
		FROM	Template
				INNER JOIN Template_Version ON Template.Template_Guid = Template_Version.Template_Guid
					AND ((Template_Version.Template_Guid = @TemplateGuid AND Template_Version.Template_Version = @TemplateVersion)
					   OR (Template_Version.Template_Guid = @LayoutGuid AND Template_Version.Template_Version = @LayoutVersion))
		ORDER BY Template_Type_ID;
	END
	ELSE
	BEGIN
		-- Resume launches of match project version
		SELECT	Template.Template_Guid, 
				Template.Template_Type_ID,
				Template.Template_Version, 
				CASE WHEN Template.EncryptedProjectDefinition IS NULL THEN 0 ELSE 1 END AS Encrypted,
				Template.EncryptedProjectDefinition,
				Template.Project_Definition
		FROM	Template
		WHERE	(Template.Template_Guid = @TemplateGuid OR Template.Template_Guid = @LayoutGuid)
				AND Template.Modified_Date <= @PublishedBy
		UNION ALL
		SELECT	Template_Version.Template_Guid, 
				Template.Template_Type_ID,
				Template_Version.Template_Version, 
				CASE WHEN Template_Version.EncryptedProjectDefinition IS NULL THEN 0 ELSE 1 END AS Encrypted,
				Template_Version.EncryptedProjectDefinition,
				Template_Version.Project_Definition
		FROM	Template
				INNER JOIN Template_Version ON Template.Template_Guid = Template_Version.Template_Guid
		WHERE	(Template_Version.Template_Guid = @TemplateGuid OR Template_Version.Template_Guid = @LayoutGuid)
				AND Template.Modified_Date > @PublishedBy
				AND Template_Version.Modified_Date = (SELECT TOP 1 VersionDate.Modified_Date
								FROM Template_Version VersionDate
								WHERE VersionDate.Template_Guid = Template_Version.Template_Guid
									AND VersionDate.Modified_Date <= @PublishedBy
								ORDER BY VersionDate.Modified_Date DESC)
		ORDER BY Template_Type_ID;
	END
GO
