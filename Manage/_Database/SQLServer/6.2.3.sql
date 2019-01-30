/*
** Database Update package 6.2.3
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.2.3')
go

--1909
ALTER procedure [dbo].[spTemplate_RemoveTemplate]
	@TemplateGuid uniqueidentifier,
	@OnlyChildInfo bit
as
/*
MODIFICATION HISTORY

3.2.1	chrisg	remove questions that are not in use by any other templates.
---INTELLEDOX----
1.1.4	chrisg	remove any references to it from content templates
1.3.4	chrisg	alter answer removal so it is still removed even if no bookmarks are assigned to the answer
*/
	DECLARE @TemplateId Int

	SELECT	@TemplateId = Template_Id
	FROM	Template
	WHERE	Template_Guid = @TemplateGuid;

	DELETE	template_macro
	WHERE	template_id = @TemplateID;

	IF @OnlyChildInfo = 0
	BEGIN
		DELETE	template_Group_item
		WHERE	template_id = @TemplateID
			OR	layout_id = @TemplateID;

		DELETE	template_Group
		WHERE	Template_Group_id NOT IN (
			SELECT	Template_Group_id
			FROM	Template_Group_Item
		);

		DELETE	Package_Template
		WHERE	Template_Group_id NOT IN (
			SELECT	Template_Group_id
			FROM	template_Group
		);

		DELETE	Template_Category
		WHERE	Template_ID = @TemplateID;

		DELETE	User_Group_Template
		WHERE	Template_ID = @TemplateID;

		UPDATE	template 
		SET		layout_id = 0 
		WHERE	layout_id = @TemplateID;
	END
	
	DELETE template
	WHERE template_id = @TemplateID;
GO


