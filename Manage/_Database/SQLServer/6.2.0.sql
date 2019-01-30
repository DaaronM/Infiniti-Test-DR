/*
** Database Update package 6.2.0
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.2.0')
go

--1898
ALTER TABLE dbo.Template_Group ADD
	UpdateDocumentFields bit NULL
GO
ALTER TABLE dbo.Template_Group ADD CONSTRAINT
	DF_Template_Group_UpdateDocumentFields DEFAULT 0 FOR UpdateDocumentFields
GO
UPDATE	Template_Group
SET		UpdateDocumentFields = 0
WHERE	UpdateDocumentFields IS NULL;
GO
ALTER PROCEDURE [dbo].[spProjectGrp_ProjectGroupList]
      @ProjectGroupGuid uniqueidentifier
AS
    SELECT	a.Template_Group_ID, a.[Name] as Template_Group_Name, a.template_group_guid, 
			a.helptext as TemplateGroup_HelpText, b.template_guid, b.Layout_Guid,
			b.Template_Version, b.Layout_Version, a.AllowPreview, a.PostGenerateText,
			a.UpdateDocumentFields
    FROM	Template_Group a
			LEFT JOIN Template_Group_Item b on a.template_group_id = b.template_group_id
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;
GO
ALTER PROCEDURE [dbo].[spProjectGrp_UpdateProjectGroup]
	@ProjectGroupGuid uniqueidentifier,
	@Name nvarchar(100),
	@HelpText nvarchar(4000),
	@AllowPreview bit,
	@PostGenerateText nvarchar(4000),
	@UpdateDocumentFields bit
AS
	IF NOT EXISTS(SELECT * FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid)
	BEGIN
		INSERT INTO Template_Group ([name], template_group_guid, helptext, AllowPreview, PostGenerateText, UpdateDocumentFields)
		VALUES (@Name, @ProjectGroupGuid, @HelpText, @AllowPreview, @PostGenerateText, @UpdateDocumentFields);
	END
	ELSE
	BEGIN
		UPDATE	Template_Group
		SET		[Name] = @Name,
				HelpText = @HelpText,
				AllowPreview = @AllowPreview,
				PostGenerateText = @PostGenerateText,
				UpdateDocumentFields = @UpdateDocumentFields
		WHERE	Template_Group_Guid = @ProjectGroupGuid;
	END
GO

--1900
EXECUTE sp_rename N'dbo.Routing_Type', N'zzRouting_Type', 'OBJECT';
GO
CREATE TABLE dbo.Routing_Type
	(
	RoutingTypeId uniqueidentifier NOT NULL,
	RoutingTypeDescription nvarchar(255) NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.Routing_Type ADD CONSTRAINT
	PK_Routing_Type_Guid PRIMARY KEY CLUSTERED 
	(
	RoutingTypeId
	) ON [PRIMARY]
GO
INSERT INTO Routing_Type(RoutingTypeId, RoutingTypeDescription)
VALUES ('230DD56C-0018-4D49-945E-5B6E5B08EAF6', 'Email');
GO
EXECUTE sp_rename N'dbo.Routing_ElementType', N'zzRouting_ElementType', 'OBJECT';
GO
CREATE TABLE [dbo].[Routing_ElementType](
	[RoutingElementTypeId] uniqueidentifier NOT NULL,
	[RoutingTypeId] uniqueidentifier NULL,
	[ElementTypeDescription] [nvarchar](255) NULL,
	[ElementLimit] [int] NULL,
	[Required] bit NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Routing_ElementType] ADD  CONSTRAINT [DF_Routing_ElementType_Required2]  DEFAULT (0) FOR [Required]
GO
ALTER TABLE dbo.Routing_ElementType ADD CONSTRAINT
	PK_Routing_ElementType_Guid PRIMARY KEY CLUSTERED 
	(
	RoutingElementTypeId
	) ON [PRIMARY]
GO
INSERT INTO Routing_ElementType(RoutingTypeId, RoutingElementTypeId, ElementTypeDescription, ElementLimit, [Required])
VALUES ('230DD56C-0018-4D49-945E-5B6E5B08EAF6', '1CFC7329-3410-4FFF-B979-7E8703403CE3', 'Address To', 0, 1)

INSERT INTO Routing_ElementType(RoutingTypeId, RoutingElementTypeId, ElementTypeDescription, ElementLimit, [Required])
VALUES ('230DD56C-0018-4D49-945E-5B6E5B08EAF6', '34BA9167-353E-4B91-8796-0167E15252D4', 'Address From', 1, 1)

INSERT INTO Routing_ElementType(RoutingTypeId, RoutingElementTypeId, ElementTypeDescription, ElementLimit, [Required])
VALUES ('230DD56C-0018-4D49-945E-5B6E5B08EAF6', '92380C66-D038-44D7-A6DA-A52A2CD202A0', 'Email Body', 1, 0)

INSERT INTO Routing_ElementType(RoutingTypeId, RoutingElementTypeId, ElementTypeDescription, ElementLimit, [Required])
VALUES ('230DD56C-0018-4D49-945E-5B6E5B08EAF6', '580C5529-5A20-4E2C-B80E-53563E62E1E5', 'Subject Line', 1, 0)

INSERT INTO Routing_ElementType(RoutingTypeId, RoutingElementTypeId, ElementTypeDescription, ElementLimit, [Required])
VALUES ('230DD56C-0018-4D49-945E-5B6E5B08EAF6', '345109CB-2216-4FEE-88B3-ABB78BBC3A73', 'Address BCC', 0, 0)
GO
CREATE PROCEDURE dbo.spRouting_RegisterType
	@Id uniqueidentifier,
	@Description nvarchar(255)
AS
	IF NOT EXISTS(SELECT * FROM Routing_Type WHERE RoutingTypeId = @id)
	BEGIN
		INSERT INTO Routing_Type(RoutingTypeId, RoutingTypeDescription)
		VALUES	(@id, @Description);
	END
GO
CREATE PROCEDURE dbo.spRouting_RegisterTypeAttribute
	@RoutingTypeId uniqueidentifier,
	@Id uniqueidentifier,
	@Description nvarchar(255),
	@ElementLimit int,
	@Required bit
AS
	IF NOT EXISTS(SELECT * FROM Routing_ElementType WHERE RoutingElementTypeId = @Id AND RoutingTypeId = @RoutingTypeId)
	BEGIN
		INSERT INTO Routing_ElementType(RoutingElementTypeId, RoutingTypeId, ElementTypeDescription, ElementLimit, [Required])
		VALUES	(@RoutingTypeId, @id, @Description, @ElementLimit, @Required);
	END
GO
ALTER procedure [dbo].[spTemplate_RoutingElementTypeList]
	@RoutingTypeId uniqueidentifier
AS
	SELECT	*
	FROM	Routing_ElementType
	WHERE	RoutingTypeId = @RoutingTypeId;
GO

--1902
ALTER PROCEDURE [dbo].[spReport_ResultsCSV]
	@TemplateId Int,
	@StartDate datetime,
	@FinishDate datetime
AS
	SET ARITHABORT ON 
	CREATE TABLE #Answers
	(
		Id int identity(1,1),
		AnswerId int,
		AnswerName nvarchar(1000),
		Label nvarchar(100),
		QuestionName nvarchar(1000),
		PageName nvarchar(1000),
		QuestionTypeId int,
		QuestionId int
	);

	CREATE TABLE #Responses
	(
		LogGuid uniqueidentifier,
		AnswerId int,
		Value nvarchar(1000),
		StartDate datetime,
		FinishDate datetime,
		UserId int
	);
	
	-- Finish date inclusive
	SET @FinishDate = DateAdd(d, 1, @FinishDate);

	INSERT INTO #Answers(AnswerId, AnswerName, Label, QuestionName, QuestionTypeId, PageName, QuestionID)
	SELECT	A.value('@ID', 'int'), 
			A.value('@Name', 'nvarchar(1000)'),
			A.value('@AnswerFileLabel', 'nvarchar(100)'),
			Q.value('@Text', 'nvarchar(1000)'),
			Q.value('@TypeId', 'int'),
			P.value('@Name', 'nvarchar(1000)'),
			Q.value('@ID', 'int')
	FROM	Template
			CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
			CROSS APPLY ProjectXML.P.nodes('(Question)') as QuestionXML(Q)
			CROSS APPLY QuestionXML.Q.nodes('(Answer)') as AnswerXml(A)
	WHERE	Template.Template_Id = @TemplateId;

	INSERT INTO #Responses(LogGuid, AnswerId, Value, StartDate, FinishDate, UserId)
	SELECT	Template_Log.Log_Guid,
			#Answers.AnswerId, 
			C.value('@AnswerValue', 'nvarchar(1000)'),
			Template_Log.DateTime_Start,
			Template_Log.DateTime_Finish,
			Template_Log.User_Id
	FROM	Template_Log 
			CROSS APPLY Answer_File.nodes('(/AnswerFile/Groups/Group/Questions/Question/Answers/Answer)') as ID(C)
			, #Answers
	WHERE	C.value('@AnswerId', 'int') = #Answers.AnswerId
			AND Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
			AND (#Answers.QuestionTypeId = 3	-- Group logic
				OR #Answers.QuestionTypeId = 6	-- Simple logic
				OR #Answers.QuestionTypeId = 7)	-- User prompt
			AND Template_Log.Template_Group_Id IN
			(
				SELECT	Template_Group_Id
				FROM	Template_Group_Item
				WHERE	Template_Id = @TemplateId
			)
	UNION ALL
	SELECT	Template_Log.Log_Guid,
			#Answers.AnswerId, 
			C.value('@name', 'nvarchar(1000)'),
			Template_Log.DateTime_Start,
			Template_Log.DateTime_Finish,
			Template_Log.User_Id
	FROM	Template_Log 
			CROSS APPLY Answer_File.nodes('(/AnswerFile/AnswerLabels/Label)') as Label(C)
			, #Answers
	WHERE	C.value('@name', 'nvarchar(100)') = #Answers.Label
			AND Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
			AND (#Answers.QuestionTypeId = 3	-- Group logic
				OR #Answers.QuestionTypeId = 6	-- Simple logic
				OR #Answers.QuestionTypeId = 7)	-- User prompt
			AND Template_Log.Template_Group_Id IN
			(
				SELECT	Template_Group_Id
				FROM	Template_Group_Item
				WHERE	Template_Id = @TemplateId
			);
			
	SELECT DISTINCT	#Responses.LogGuid AS 'Log Id',
					Intelledox_User.Username,
					#Responses.StartDate AS 'Start Date/Time',
					#Responses.FinishDate AS 'Finish Date/Time',
					#Answers.PageName AS 'Page',
					#Answers.QuestionName AS 'Question',
					#Answers.QuestionID AS 'Question ID',
					
					CASE #Answers.QuestionTypeId 
						WHEN 3	
						THEN 'Group Logic'
						WHEN 6	
						THEN 'Simple Logic'
						WHEN 7	
						THEN 'User Prompt'
						ELSE 'Unknown'
					END as 'Question Type',
					
					CASE #Answers.QuestionTypeId 
						WHEN 3	-- Group
						THEN #Answers.AnswerName
						WHEN 6	-- Simple
						THEN CASE #Responses.Value
							WHEN 'True'
							THEN 'Yes'
							ELSE 'No'
							END
						ELSE #Responses.Value
					END as 'Answer'
			
	FROM	#Answers
			INNER JOIN #Responses ON #Answers.AnswerId = #Responses.AnswerId
			INNER JOIN Intelledox_User ON Intelledox_User.User_ID = #Responses.UserID
	WHERE (#Answers.QuestionTypeId = 3 AND #Responses.Value = 'True')
		OR (#Answers.QuestionTypeId = 6)
		OR (#Answers.QuestionTypeId = 7)
	ORDER BY #Responses.LogGuid,
			Intelledox_User.Username,
			#Responses.StartDate,
			#Responses.FinishDate;

	DROP TABLE #Answers;
	DROP TABLE #Responses;
GO


--1903
ALTER PROCEDURE [dbo].[spReport_LogicResponses]
	@TemplateId Int,
	@StartDate datetime,
	@FinishDate datetime,
	@DisplayText bit = 0
AS
	SET ARITHABORT ON 
	CREATE TABLE #Answers
	(
		Id int identity(1,1),
		AnswerId int,
		AnswerName nvarchar(1000),
		Label nvarchar(100),
		QuestionName nvarchar(1000),
		PageName nvarchar(1000),
		QuestionTypeId int
	);

	CREATE TABLE #Responses
	(
		LogGuid uniqueidentifier,
		AnswerId int,
		Value nvarchar(1000)
	);
	
	-- Finish date inclusive
	SET @FinishDate = DateAdd(d, 1, @FinishDate);

	INSERT INTO #Answers(AnswerId, AnswerName, Label, QuestionName, QuestionTypeId, PageName)
	SELECT	A.value('@ID', 'int'), 
			A.value('@Name', 'nvarchar(1000)'),
			A.value('@AnswerFileLabel', 'nvarchar(100)'),
			Q.value('@Text', 'nvarchar(1000)'),
			Q.value('@TypeId', 'int'),
			P.value('@Name', 'nvarchar(1000)')
	FROM	Template
			CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
			CROSS APPLY ProjectXML.P.nodes('(Question)') as QuestionXML(Q)
			CROSS APPLY QuestionXML.Q.nodes('(Answer)') as AnswerXml(A)
	WHERE	Template.Template_Id = @TemplateId;

	INSERT INTO #Responses(LogGuid, AnswerId, Value)
	SELECT	Template_Log.Log_Guid,
			#Answers.AnswerId, 
			C.value('@AnswerValue', 'nvarchar(1000)')
	FROM	Template_Log 
			CROSS APPLY Answer_File.nodes('(/AnswerFile/Groups/Group/Questions/Question/Answers/Answer)') as ID(C)
			, #Answers
	WHERE	C.value('@AnswerId', 'int') = #Answers.AnswerId
			AND Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
			AND (#Answers.QuestionTypeId = 3	-- Group logic
				OR #Answers.QuestionTypeId = 6	-- Simple logic
				OR (#Answers.QuestionTypeId = 7 AND @DisplayText = 1))	-- User prompt
			AND Template_Log.Template_Group_Id IN
			(
				SELECT	Template_Group_Id
				FROM	Template_Group_Item
				WHERE	Template_Id = @TemplateId
			)
	UNION ALL
	SELECT 	Template_Log.Log_Guid,
			#Answers.AnswerId, 
			C.value('@name', 'nvarchar(1000)')
	FROM	Template_Log 
			CROSS APPLY Answer_File.nodes('(/AnswerFile/AnswerLabels/Label)') as Label©
			, #Answers
	WHERE	C.value('@name', 'nvarchar(100)') = #Answers.Label
			AND Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
			AND (#Answers.QuestionTypeId = 3	-- Group logic
				OR #Answers.QuestionTypeId = 6	-- Simple logic
				OR (#Answers.QuestionTypeId = 7 AND @DisplayText = 1))	-- User prompt
			AND Template_Log.Template_Group_Id IN
			(
				SELECT	Template_Group_Id
				FROM	Template_Group_Item
				WHERE	Template_Id = @TemplateId
			);

	SELECT	#Answers.PageName,
			#Answers.QuestionTypeId,
			#Answers.QuestionName,
			#Answers.AnswerName,
			COUNT(CASE #Answers.QuestionTypeId 
				WHEN 3	-- Group
				THEN CASE #Responses.Value WHEN 'True' THEN '1' ELSE NULL END
				WHEN 6	-- Simple
				THEN CASE #Responses.Value WHEN 'True' THEN '1' ELSE NULL END
				ELSE #Responses.Value
				END) as AnswerCount,
			COUNT(*) as TotalQuestionResponses,
			(SELECT COUNT(DISTINCT #Responses.LogGuid) FROM #Responses) as TotalResponses,
			CASE WHEN #Answers.QuestionTypeId = 7 THEN #Responses.Value ELSE '' END as TextResponse
	FROM	#Answers
			INNER JOIN #Responses ON #Answers.AnswerId = #Responses.AnswerId
	GROUP BY #Answers.Id,
			#Answers.PageName,
			#Answers.QuestionTypeId,
			#Answers.QuestionName,
			#Answers.AnswerName,
			CASE WHEN #Answers.QuestionTypeId = 7 THEN #Responses.Value ELSE '' END
	ORDER BY #Answers.Id;

	DROP TABLE #Answers;
	DROP TABLE #Responses;
GO


--1904
ALTER procedure [dbo].[spAudit_AnswerFileList]
	@AnswerFile_ID int = 0,
	@User_ID int = 0,
	@WebOnly char(1) = 0,
	@InProgress char(1) = '0',
	@TemplateGroupGuid uniqueidentifier = null,
	@ErrorCode int output
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
        ORDER BY Answer_File.[RunDate] desc;
    end
GO
ALTER PROCEDURE [dbo].[spProjectGroup_FolderListAll]
	@UserGuid uniqueidentifier,
	@FolderSearch nvarchar(50),
	@ProjectSearch nvarchar(100)
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid;
	
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
	ORDER BY a.Folder_Name, a.Folder_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END;
GO
ALTER PROCEDURE [dbo].[spProjectGroup_Recent]
	@UserGuid uniqueidentifier,
	@ProjectSearch nvarchar(100)
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid;
	
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
	ORDER BY l.DateTime_Start DESC;
GO
DELETE FROM	Global_Options
WHERE	OptionCode = 'ANONYMOUS_ACCESS';
GO

--1905
ALTER TABLE dbo.Template_Group ADD
	EnforceValidation bit NULL
GO

ALTER TABLE dbo.Template_Group ADD CONSTRAINT
	DF_Template_Group_EnforceValidation DEFAULT 0 FOR EnforceValidation
GO

UPDATE	Template_Group
SET		EnforceValidation = 0
WHERE	EnforceValidation IS NULL;
GO

ALTER PROCEDURE [dbo].[spProjectGrp_UpdateProjectGroup]
	@ProjectGroupGuid uniqueidentifier,
	@Name nvarchar(100),
	@HelpText nvarchar(4000),
	@AllowPreview bit,
	@PostGenerateText nvarchar(4000),
	@UpdateDocumentFields bit,
	@EnforceValidation bit
AS
	IF NOT EXISTS(SELECT * FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid)
	BEGIN
		INSERT INTO Template_Group ([name], template_group_guid, helptext, AllowPreview, PostGenerateText, UpdateDocumentFields, EnforceValidation)
		VALUES (@Name, @ProjectGroupGuid, @HelpText, @AllowPreview, @PostGenerateText, @UpdateDocumentFields, @EnforceValidation);
	END
	ELSE
	BEGIN
		UPDATE	Template_Group
		SET		[Name] = @Name,
				HelpText = @HelpText,
				AllowPreview = @AllowPreview,
				PostGenerateText = @PostGenerateText,
				UpdateDocumentFields = @UpdateDocumentFields,
				EnforceValidation = @EnforceValidation
		WHERE	Template_Group_Guid = @ProjectGroupGuid;
	END
GO


ALTER PROCEDURE [dbo].[spProjectGrp_ProjectGroupList]
      @ProjectGroupGuid uniqueidentifier
AS
    SELECT	a.Template_Group_ID, a.[Name] as Template_Group_Name, a.template_group_guid, 
			a.helptext as TemplateGroup_HelpText, b.template_guid, b.Layout_Guid,
			b.Template_Version, b.Layout_Version, a.AllowPreview, a.PostGenerateText,
			a.UpdateDocumentFields, a.EnforceValidation
    FROM	Template_Group a
			LEFT JOIN Template_Group_Item b on a.template_group_id = b.template_group_id
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;
GO


