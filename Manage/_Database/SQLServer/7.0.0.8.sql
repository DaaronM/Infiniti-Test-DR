/*
** Database Update package 7.0.0.8
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.0.0.8')
go

--1956
ALTER procedure [dbo].[spContent_RemoveContentItem]
	@ContentItemGuid uniqueidentifier
AS
	DECLARE @ContentDataGuid uniqueidentifier;
	
	SET		@ContentDataGuid = (SELECT ContentData_Guid FROM Content_Item WHERE ContentItem_Guid = @ContentItemGuid);

	DELETE	Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItemGuid;
	
	DELETE	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;
	
	DELETE	ContentData_Binary
	WHERE	ContentData_Guid = @ContentDataGuid;
	
	DELETE	ContentData_Binary_Version
	WHERE	ContentData_Guid = @ContentDataGuid;

	DELETE	ContentData_Text
	WHERE	ContentData_Guid = @ContentDataGuid;
	
	DELETE	ContentData_Text_Version
	WHERE	ContentData_Guid = @ContentDataGuid;
GO


--1957
ALTER procedure [dbo].[spAudit_AnswerFileList]
	@AnswerFile_ID int = 0,
	@User_Guid uniqueidentifier = null,
	@InProgress char(1) = '0',
	@TemplateGroupGuid uniqueidentifier = null,
	@ErrorCode int output
AS
	DECLARE @User_Id Int
	
	set nocount on
	
	IF (@User_Guid IS NOT NULL)
	BEGIN
		SELECT	@User_Id = User_Id
		FROM	Intelledox_User
		WHERE	User_Guid = @User_Guid;
	END

	if @AnswerFile_ID = 0 or @AnswerFile_ID is null
    begin
		if @TemplateGroupGuid is null
			select	ans.AnswerFile_Id, ans.User_Id, ans.Template_Group_Id, ans.Description, 
					ans.RunDate, ans.InProgress, 
					T.Name as TemplateGroup_Name, Template_Group.Template_Group_Guid,
					Intelledox_User.User_Guid
			from	answer_file ans
					INNER JOIN Template_Group on ans.Template_Group_ID = Template_Group.Template_Group_ID
					INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
					INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
					INNER JOIN Intelledox_User ON ans.User_Id = Intelledox_User.User_ID
			where Ans.[user_ID] = @user_id
				AND Ans.[InProgress] = @InProgress
				AND Ans.template_group_id in(

				-- Get a union of template group.
				SELECT DISTINCT tg.Template_Group_ID
				FROM Folder f
					left join (
						SELECT tg.Template_Group_ID, ft.Folder_ID
						FROM folder_template ft
						LEFT JOIN template_group tg ON ft.FolderItem_ID = tg.Template_Group_ID AND ft.ItemType_ID = 1
					) tg on f.Folder_ID = tg.Folder_ID
					left join template_group_item tgi on tg.template_group_id = tgi.template_group_id
					left join template t on tgi.template_id = t.template_id
					inner join folder_group fg on F.Folder_Guid = fg.FolderGuid
				where 	(fg.GroupGuid in
							(select b.Group_Guid
							from intelledox_user a
							left join User_Group_Subscription c on a.[User_ID] = c.[User_ID]
							left join user_group b on c.user_group_id = b.user_group_id
							where c.[user_id] = @user_id)
						)
			)
			order by [RunDate] desc;
		else
			select	ans.AnswerFile_Id, ans.User_Id, ans.Template_Group_Id, ans.Description, 
					ans.RunDate, ans.InProgress, 
					Template_Group.Name as TemplateGroup_Name, Template_Group.Template_Group_Guid,
					Intelledox_User.User_Guid
			from	answer_file ans
					INNER JOIN Template_Group on ans.Template_Group_ID = Template_Group.Template_Group_ID
					INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
					INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
					INNER JOIN Intelledox_User ON ans.User_Id = Intelledox_User.User_ID
			where Ans.[user_ID] = @user_id
				AND Template_Group.Template_group_Guid = @TemplateGroupGuid
			order by [RunDate] desc;
    end
    else
    begin
        SELECT	Answer_File.*, Template_Group.Template_Group_Guid, Intelledox_User.User_Guid
		FROM	Answer_File
				INNER JOIN Template_Group ON Answer_File.Template_Group_Id = Template_Group.Template_Group_Id
				INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
				INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
				INNER JOIN Intelledox_User ON Answer_File.User_Id = Intelledox_User.User_ID
        WHERE	Answer_File.AnswerFile_Id = @AnswerFile_Id
        ORDER BY Answer_File.[RunDate] desc;
    end
GO
exec sp_updatestats;
GO

