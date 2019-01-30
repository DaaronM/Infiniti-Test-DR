/*
** Database Update package 8.2.1.18
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.1.18');
go

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


ALTER procedure [dbo].[spProject_GetProjectsByContentDefinition]
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
		AND Project_Definition.exist('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question/Answer/ContentDefinition[@Id = sql:variable("@ContentGuid")])[1]') = 1
	ORDER BY Template.[name];
GO
