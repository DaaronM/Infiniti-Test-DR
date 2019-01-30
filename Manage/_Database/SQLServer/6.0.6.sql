/*
** Database Update package 6.0.6
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.0.6')
go

--1870
ALTER TABLE dbo.Template_Group ADD
	AllowPreview bit NULL
GO
ALTER TABLE dbo.Template_Group ADD CONSTRAINT
	DF_Template_Group_AllowPreview DEFAULT 0 FOR AllowPreview
GO
UPDATE	Template_Group
SET		AllowPreview = 0
WHERE	AllowPreview IS NULL;
GO
ALTER PROCEDURE [dbo].[spProjectGrp_UpdateProjectGroup]
	@ProjectGroupGuid uniqueidentifier,
	@Name nvarchar(100),
	@HelpText nvarchar(4000),
	@AllowPreview bit
AS
	IF NOT EXISTS(SELECT * FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid)
	BEGIN
		INSERT INTO Template_Group ([name], template_group_guid, helptext, AllowPreview)
		VALUES (@Name, @ProjectGroupGuid, @HelpText, @AllowPreview);
	END
	ELSE
	BEGIN
		UPDATE	Template_Group
		SET		[Name] = @Name,
				HelpText = @HelpText,
				AllowPreview = @AllowPreview
		WHERE	Template_Group_Guid = @ProjectGroupGuid;
	END
GO
ALTER PROCEDURE [dbo].[spProjectGrp_ProjectGroupList]
      @ProjectGroupGuid uniqueidentifier
AS
    SELECT	a.Template_Group_ID, a.[Name] as Template_Group_Name, a.template_group_guid, 
			a.helptext as TemplateGroup_HelpText, b.template_guid, b.Layout_Guid,
			b.Template_Version, b.Layout_Version, a.AllowPreview
    FROM	Template_Group a
			LEFT JOIN Template_Group_Item b on a.template_group_id = b.template_group_id
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;
GO

