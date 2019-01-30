/*
** Database Update package 6.0.13
*/

--set version
truncate table dbversion
GO
insert into dbversion values ('6.0.13')
GO

--1873
TRUNCATE TABLE Content_Item_Placeholder;
GO
UPDATE Content_Item
SET IsIndexed = 0
WHERE IsIndexed = 1;
GO

--1874
ALTER TABLE dbo.Template_Group ADD
	PostGenerateText nvarchar(4000) NULL
GO

ALTER PROCEDURE [dbo].[spProjectGrp_UpdateProjectGroup]
	@ProjectGroupGuid uniqueidentifier,
	@Name nvarchar(100),
	@HelpText nvarchar(4000),
	@AllowPreview bit,
	@PostGenerateText nvarchar(4000)
AS
	IF NOT EXISTS(SELECT * FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid)
	BEGIN
		INSERT INTO Template_Group ([name], template_group_guid, helptext, AllowPreview, PostGenerateText)
		VALUES (@Name, @ProjectGroupGuid, @HelpText, @AllowPreview, @PostGenerateText);
	END
	ELSE
	BEGIN
		UPDATE	Template_Group
		SET		[Name] = @Name,
				HelpText = @HelpText,
				AllowPreview = @AllowPreview,
				PostGenerateText = @PostGenerateText
		WHERE	Template_Group_Guid = @ProjectGroupGuid;
	END
GO

ALTER PROCEDURE [dbo].[spProjectGrp_ProjectGroupList]
      @ProjectGroupGuid uniqueidentifier
AS
    SELECT	a.Template_Group_ID, a.[Name] as Template_Group_Name, a.template_group_guid, 
			a.helptext as TemplateGroup_HelpText, b.template_guid, b.Layout_Guid,
			b.Template_Version, b.Layout_Version, a.AllowPreview, a.PostGenerateText
    FROM	Template_Group a
			LEFT JOIN Template_Group_Item b on a.template_group_id = b.template_group_id
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;
GO

