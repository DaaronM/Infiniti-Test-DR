truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.2.2');
go

-- This alter is included in 8.6.3.0, so this file is not in the DBUpdates.xml of that version
ALTER procedure [dbo].[spProject_GetProjectsByContentItem]
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
			Intelledox_User.Username,
			Template.Modified_By,
			Template.FeatureFlags
	FROM	Template
		LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By
	WHERE	Template.Business_Unit_GUID = @BusinessUnitGuid
		AND Project_Definition.exist('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question/Answer/ContentItem[@Id = sql:variable("@ContentGuid")])[1]') = 1
	ORDER BY Template.[name];
GO
