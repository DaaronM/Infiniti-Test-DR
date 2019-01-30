truncate table dbversion;
GO
insert into dbversion(dbversion) values ('10.0.55');
GO

ALTER PROCEDURE [dbo].[spProject_GetProjectsByContentItem]
	@ContentGuid varchar(40),
	@BusinessUnitGuid uniqueidentifier
AS
	SET ARITHABORT ON 

	SELECT DISTINCT	Template.template_id, 
			Template.[name] as project_name, 
			Template.template_type_id, 
			Template.template_guid, 
			Template.template_version, 
			Template.import_date,
			Template.Business_Unit_GUID, 
			Template.Supplier_Guid,
			Template.Modified_Date,
			Intelledox_User.Username,
			Template.Modified_By,
			Template.FeatureFlags,
			Template.FolderGuid,
			Template.Template_Version,
			Template.IsMajorVersion
	FROM	Template
		LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By
		INNER JOIN Xtf_ContentLibrary_Dependency on Xtf_ContentLibrary_Dependency.Template_Guid = Template.Template_Guid  AND
													Xtf_ContentLibrary_Dependency.Template_Version = Template.Template_Version
	WHERE	Template.Business_Unit_GUID = @BusinessUnitGuid
		AND Xtf_ContentLibrary_Dependency.Content_Object_Guid = @ContentGuid 
	ORDER BY Template.[name];

GO
