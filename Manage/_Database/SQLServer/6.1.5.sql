/*
** Database Update package 6.1.5
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.1.5')
go

--1885
ALTER procedure [dbo].[spProject_AddNewProjectVersion]
	@ProjectGuid uniqueidentifier
as
	BEGIN TRAN

		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Binary,
			Project_Definition)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,
			Template.Modified_By,
			Template.Binary,
			Template.Project_Definition
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
		
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


--1886
UPDATE	Template
SET		FormatTypeId = 1
WHERE	FormatTypeId = 2;
GO


--1887
CREATE TABLE dbo.Template_Recent
	(
	User_Guid uniqueidentifier NOT NULL,
	DateTime_Start datetime NOT NULL,
	Template_Group_Guid uniqueidentifier NOT NULL
	)  ON [PRIMARY]
GO
CREATE CLUSTERED INDEX IX_Template_Recent ON dbo.Template_Recent
	(
	User_Guid,
	DateTime_Start DESC,
	Template_Group_Guid
	) 
GO
CREATE TABLE ##Temp
(
	User_Id int,
	DateTime_Start datetime,
	Template_Group_Id int
)
SET NOCOUNT ON;

INSERT INTO ##Temp(User_Id, DateTime_Start, Template_Group_Id)
SELECT TL3.User_Id, MAX(TL3.DateTime_Start) as DateTime_Start, TL3.Template_Group_Id
FROM	Template_Log TL3
GROUP BY	TL3.User_Id, TL3.Template_Group_Id;

INSERT INTO Template_Recent(User_Guid, DateTime_Start, Template_Group_Guid)
SELECT	Intelledox_User.User_Guid, ##Temp.DateTime_Start, Template_Group.Template_Group_Guid
FROM	##Temp
		INNER JOIN Intelledox_User ON ##Temp.User_Id = Intelledox_User.User_Id
		INNER JOIN Template_Group ON ##Temp.Template_Group_Id = Template_Group.Template_Group_Id
WHERE	(SELECT COUNT(*)
		FROM	##Temp TL2
		WHERE	TL2.User_Id = ##Temp.User_Id
				AND TL2.DateTime_Start > ##Temp.DateTime_Start
		) < 5
ORDER BY ##Temp.DateTime_Start DESC;


DROP TABLE ##Temp;
GO
ALTER PROCEDURE [dbo].[spProjectGroup_Recent]
	@UserGuid uniqueidentifier,
	@ProjectSearch nvarchar(100)
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid
	
	SELECT	DISTINCT d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, b.Template_ID, b.[Name] as Template_Name, 
			b.Template_Type_ID, b.FormatTypeId, d.Template_Group_Guid, l.DateTime_Start
	FROM	Folder a
			INNER JOIN Folder_Template c on a.Folder_ID = c.Folder_ID
			INNER JOIN Template_Group d on c.folderitem_ID = d.Template_Group_ID and itemtype_id = 1
			INNER JOIN Template_Group_Item e on d.Template_Group_Guid = e.Template_Group_Guid
			INNER JOIN Template b on e.Template_Guid = b.Template_Guid
			INNER JOIN Template_Recent l on d.Template_Group_Guid = l.Template_Group_Guid
	WHERE	a.Business_Unit_GUID = @BusinessUnitGUID
			AND a.Folder_Guid IN (
				SELECT	Folder_Group.FolderGuid
				FROM	Folder_Group
						INNER JOIN User_Group ON Folder_Group.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Subscription ON User_Group.User_Group_Id = User_Group_Subscription.User_Group_Id
						INNER JOIN Intelledox_User ON User_Group_Subscription.User_Id = Intelledox_User.User_Id
				WHERE	Intelledox_User.User_Guid = @UserGuid
				)
			AND CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END LIKE @ProjectSearch + '%'
			AND l.[User_Guid] = @UserGuid
	ORDER BY l.DateTime_Start DESC
GO
ALTER PROCEDURE [dbo].[spLog_InsertTemplateLog]
	@LogGuid uniqueidentifier,
	@UserGuid uniqueidentifier,	
	@TemplateGroupGuid uniqueidentifier,
	@StartTime datetime,
	@AnswerFileUsed bit,
	@PackageRunId int,
	@AnswerFile xml
AS
	DECLARE @UserId INT;
	DECLARE @TemplateGroupId INT;
	
	SET NOCOUNT ON;
	
	SET @UserId = (SELECT User_Id FROM Intelledox_User WHERE User_Guid = @UserGuid);
	SET	@TemplateGroupId = (SELECT Template_Group_Id FROM Template_Group WHERE Template_Group_Guid = @TemplateGroupGuid);
	
	IF @LogGuid IS NULL
		SET @LogGuid = newid();

	--Add to log
	INSERT INTO Template_Log(Log_Guid, [User_ID], Template_Group_ID, DateTime_Start, Completed, Answer_File_Used, Package_Run_Id, InProgress, Answer_File)
	VALUES (@LogGuid, @UserID, @TemplateGroupID, @StartTime, 0, @AnswerFileUsed, @PackageRunId, 1, @AnswerFile);

	--Add to recent
	IF EXISTS (SELECT * FROM Template_Recent WHERE User_Guid = @UserGuid AND Template_Group_Guid = @TemplateGroupGuid)
	BEGIN
		--Update time ran
		UPDATE	Template_Recent
		SET		DateTime_Start = @StartTime
		WHERE	User_Guid = @UserGuid 
				AND Template_Group_Guid = @TemplateGroupGuid;
	END
	ELSE
	BEGIN
		IF ((SELECT COUNT(*) FROM Template_Recent WHERE User_Guid = @UserGuid) = 5)
		BEGIN
			--Remove oldest recent record
			DELETE Template_Recent
			WHERE DateTime_Start = (SELECT MIN(DateTime_Start)
				FROM	Template_Recent
				WHERE	User_Guid = @UserGuid)
				AND User_Guid = @UserGuid;
		END
		
		INSERT INTO Template_Recent(User_Guid, DateTime_Start, Template_Group_Guid)
		VALUES (@UserGuid, @StartTime, @TemplateGroupGuid);
	END
GO

--1888
CREATE NONCLUSTERED INDEX IX_Template_Log_UserId ON dbo.Template_Log
	(
	User_ID,
	DateTime_Start,
	InProgress
	)
GO

--1889

ALTER PROCEDURE [dbo].[spProjectGroup_FolderListAll]
	@UserGuid uniqueidentifier,
	@FolderSearch nvarchar(50),
	@ProjectSearch nvarchar(100),
	@IncludeForms bit
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid
	
	SELECT	DISTINCT a.*, d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, b.Template_ID, b.[Name] as Template_Name, 
			b.Template_Type_ID, b.FormatTypeId, d.Template_Group_Guid
	FROM	Folder a
			INNER JOIN Folder_Template c on a.Folder_ID = c.Folder_ID
			INNER JOIN Template_Group d on c.folderitem_ID = d.Template_Group_ID and itemtype_id = 1
			INNER JOIN Template_Group_Item e on d.Template_Group_ID = e.Template_Group_ID
			INNER JOIN Template b on e.Template_ID = b.Template_ID
	WHERE	a.Business_Unit_GUID = @BusinessUnitGUID
			AND a.Folder_Guid IN (
				SELECT	Folder_Group.FolderGuid
				FROM	Folder_Group
						INNER JOIN User_Group ON Folder_Group.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Subscription ON User_Group.User_Group_Id = User_Group_Subscription.User_Group_Id
						INNER JOIN Intelledox_User ON User_Group_Subscription.User_Id = Intelledox_User.User_Id
				WHERE	Intelledox_User.User_Guid = @UserGuid
				)
			AND a.Folder_Name LIKE @FolderSearch + '%'
			AND CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END LIKE @ProjectSearch + '%'
			AND (@IncludeForms = 1 OR b.Template_Type_ID <> 3)
	ORDER BY a.Folder_Name, a.Folder_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END
GO


--1890
ALTER procedure [dbo].[spAudit_AnswerFileList]
	@AnswerFile_ID int = 0,
	@User_ID int = 0,
	@WebOnly char(1) = 0,
	@InProgress char(1) = '0',
	@TemplateGroupId int = 0,
	@ErrorCode int output,
	@IncludeForms bit
AS
	set nocount on

	if @AnswerFile_ID = 0 or @AnswerFile_ID is null
    begin
        if @User_ID = 0 or @User_ID is null
            SELECT	Answer_File.*, Template_Group.Template_Group_Guid
			FROM	Answer_File
					INNER JOIN Template_Group ON Answer_File.Template_Group_Id = Template_Group.Template_Group_Id
					INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
					INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
			WHERE	Answer_File.InProgress = @InProgress
				AND (@IncludeForms = 1 OR T.Template_Type_ID <> 3)
            order by Answer_File.[RunDate] desc;
        else
		begin
			if @TemplateGroupId = 0 or @TemplateGroupId is null
				select ans.*, T.Name as TemplateGroup_Name, Template_Group.Template_Group_Guid
				from answer_file ans
					INNER JOIN Template_Group on ans.Template_Group_ID = Template_Group.Template_Group_ID
					INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
					INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
				where Ans.[user_ID] = @user_id
					AND Ans.[InProgress] = @InProgress
					AND (@IncludeForms = 1 OR T.Template_Type_ID <> 3)
					AND Ans.template_group_id in(

					-- Get a union of template group and template package.
					SELECT DISTINCT tg.Template_Group_ID
					FROM Folder f
						left join (
							SELECT tg.Template_Group_ID, ft.Folder_ID
							FROM folder_template ft
							LEFT JOIN template_group tg ON ft.FolderItem_ID = tg.Template_Group_ID AND ft.ItemType_ID = 1
							UNION
							SELECT pt.Template_Group_ID, ft.Folder_ID
							FROM folder_template ft
							LEFT JOIN package_template pt ON ft.FolderItem_ID = pt.Package_ID AND ft.ItemType_ID = 2
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
				select ans.*, Template_Group.Name as TemplateGroup_Name, Template_Group.Template_Group_Guid
				from answer_file ans
					INNER JOIN Template_Group on ans.Template_Group_ID = Template_Group.Template_Group_ID
					INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
					INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
				where Ans.[user_ID] = @user_id
					AND Ans.template_group_id = @TemplateGroupId
					AND (@IncludeForms = 1 OR T.Template_Type_ID <> 3)
				order by [RunDate] desc;
		end
    end
    else
    begin
        SELECT	Answer_File.*, Template_Group.Template_Group_Guid
		FROM	Answer_File
				INNER JOIN Template_Group ON Answer_File.Template_Group_Id = Template_Group.Template_Group_Id
				INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
				INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
        WHERE	Answer_File.AnswerFile_Id = @AnswerFile_Id
			AND (@IncludeForms = 1 OR T.Template_Type_ID <> 3)
        ORDER BY Answer_File.[RunDate] desc;
    end
GO


--1891
ALTER PROCEDURE [dbo].[spProjectGroup_Recent]
	@UserGuid uniqueidentifier,
	@ProjectSearch nvarchar(100),
	@IncludeForms bit
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid
	
	SELECT	DISTINCT d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, b.Template_ID, b.[Name] as Template_Name, 
			b.Template_Type_ID, b.FormatTypeId, d.Template_Group_Guid, l.DateTime_Start
	FROM	Folder a
			INNER JOIN Folder_Template c on a.Folder_ID = c.Folder_ID
			INNER JOIN Template_Group d on c.folderitem_ID = d.Template_Group_ID and itemtype_id = 1
			INNER JOIN Template_Group_Item e on d.Template_Group_Guid = e.Template_Group_Guid
			INNER JOIN Template b on e.Template_Guid = b.Template_Guid
			INNER JOIN Template_Recent l on d.Template_Group_Guid = l.Template_Group_Guid
	WHERE	a.Business_Unit_GUID = @BusinessUnitGUID
			AND a.Folder_Guid IN (
				SELECT	Folder_Group.FolderGuid
				FROM	Folder_Group
						INNER JOIN User_Group ON Folder_Group.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Subscription ON User_Group.User_Group_Id = User_Group_Subscription.User_Group_Id
						INNER JOIN Intelledox_User ON User_Group_Subscription.User_Id = Intelledox_User.User_Id
				WHERE	Intelledox_User.User_Guid = @UserGuid
				)
			AND CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END LIKE @ProjectSearch + '%'
			AND l.[User_Guid] = @UserGuid
			AND (@IncludeForms = 1 OR b.Template_Type_ID <> 3)
	ORDER BY l.DateTime_Start DESC
GO


--1892
ALTER procedure [dbo].[spAudit_AnswerFileList]
	@AnswerFile_ID int = 0,
	@User_ID int = 0,
	@WebOnly char(1) = 0,
	@InProgress char(1) = '0',
	@TemplateGroupGuid uniqueidentifier = null,
	@ErrorCode int output,
	@IncludeForms bit
AS
	set nocount on

	if @AnswerFile_ID = 0 or @AnswerFile_ID is null
    begin
        if @User_ID = 0 or @User_ID is null
            SELECT	Answer_File.*, Template_Group.Template_Group_Guid
			FROM	Answer_File
					INNER JOIN Template_Group ON Answer_File.Template_Group_Id = Template_Group.Template_Group_Id
					INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
					INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
			WHERE	Answer_File.InProgress = @InProgress
				AND (@IncludeForms = 1 OR T.Template_Type_ID <> 3)
            order by Answer_File.[RunDate] desc;
        else
		begin
			if @TemplateGroupGuid is null
				select ans.*, T.Name as TemplateGroup_Name, Template_Group.Template_Group_Guid
				from answer_file ans
					INNER JOIN Template_Group on ans.Template_Group_ID = Template_Group.Template_Group_ID
					INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
					INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
				where Ans.[user_ID] = @user_id
					AND Ans.[InProgress] = @InProgress
					AND (@IncludeForms = 1 OR T.Template_Type_ID <> 3)
					AND Ans.template_group_id in(

					-- Get a union of template group and template package.
					SELECT DISTINCT tg.Template_Group_ID
					FROM Folder f
						left join (
							SELECT tg.Template_Group_ID, ft.Folder_ID
							FROM folder_template ft
							LEFT JOIN template_group tg ON ft.FolderItem_ID = tg.Template_Group_ID AND ft.ItemType_ID = 1
							UNION
							SELECT pt.Template_Group_ID, ft.Folder_ID
							FROM folder_template ft
							LEFT JOIN package_template pt ON ft.FolderItem_ID = pt.Package_ID AND ft.ItemType_ID = 2
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
				select ans.*, Template_Group.Name as TemplateGroup_Name, Template_Group.Template_Group_Guid
				from answer_file ans
					INNER JOIN Template_Group on ans.Template_Group_ID = Template_Group.Template_Group_ID
					INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
					INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
				where Ans.[user_ID] = @user_id
					AND Template_Group.Template_group_Guid = @TemplateGroupGuid
					AND (@IncludeForms = 1 OR T.Template_Type_ID <> 3)
				order by [RunDate] desc;
		end
    end
    else
    begin
        SELECT	Answer_File.*, Template_Group.Template_Group_Guid
		FROM	Answer_File
				INNER JOIN Template_Group ON Answer_File.Template_Group_Id = Template_Group.Template_Group_Id
				INNER JOIN Template_Group_Item AS TGI ON Template_Group.Template_Group_ID = TGI.Template_Group_ID
				INNER JOIN Template AS T ON TGI.Template_ID = T.Template_ID
        WHERE	Answer_File.AnswerFile_Id = @AnswerFile_Id
			AND (@IncludeForms = 1 OR T.Template_Type_ID <> 3)
        ORDER BY Answer_File.[RunDate] desc;
    end
GO
ALTER PROCEDURE [dbo].[spAudit_UpdateAnswerFile]
	@AnswerFile_ID int,
	@User_ID int,
	@Template_Group_Guid uniqueidentifier,
	@Description nvarchar(255),
	@RunDate datetime,
	@AnswerString xml,
	@InProgress char(1) = '0',
	@NewID int output,
	@ErrorCode int output
AS
	set nocount on
	
	DECLARE @Template_Group_Id Int
	
	SELECT	@Template_Group_Id = Template_Group_Id
	FROM	Template_Group
	WHERE	Template_Group_Guid = @Template_Group_Guid;

	if @AnswerFile_ID = 0 or @AnswerFile_ID is null
	begin
		insert into Answer_File ([User_ID], [Template_Group_ID], [Description], [RunDate], [AnswerString], [InProgress])
		values (@User_ID, @Template_Group_ID, @Description, @RunDate, @AnswerString, @InProgress);

		select @NewID = @@Identity;
	end
	else
	begin
		update Answer_File
		set [Description] = @Description,
			RunDate = @RunDate,
			AnswerString = @AnswerString
		where AnswerFile_ID = @AnswerFile_ID;
	end

	set @ErrorCode = @@Error;
GO

--1893
ALTER TABLE dbo.Intelledox_User
	DROP CONSTRAINT PK_Intelledox_User
GO
ALTER TABLE dbo.Intelledox_User ADD CONSTRAINT
	PK_Intelledox_User PRIMARY KEY NONCLUSTERED 
	(
	User_ID
	)

GO
CREATE CLUSTERED INDEX IX_Intelledox_User_UserGuid ON dbo.Intelledox_User
	(
	User_Guid
	) 
GO

--1894
DELETE FROM ProcessJob
WHERE	JobId NOT IN
	(
	SELECT	JobId
	FROM	Document
	);
GO


