/*
** Database Update package 7.2.9
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('7.2.9');
go

--2004
ALTER PROCEDURE [dbo].[spJob_UpdateJobDefinition](
	@JobDefinitionId uniqueidentifier,
	@Name nvarchar(200),
	@IsEnabled bit,
	@OwnerGuid uniqueidentifier,
	@DateModified datetime,
	@JobDefinition xml,
	@WatchFolder nvarchar(300),
	@DataSourceGuid uniqueidentifier,
	@DeleteAfterDays int,
	@NextRunDate datetime
)
AS
	UPDATE	JobDefinition
	SET		Name = @Name, 
			IsEnabled = @IsEnabled, 
			OwnerGuid = @OwnerGuid, 
			DateModified = @DateModified, 
			JobDefinition = @JobDefinition,
			WatchFolder = @WatchFolder,
			DataSourceGuid = @DataSourceGuid,
			DeleteAfterDays = @DeleteAfterDays,
			NextRunDate = @NextRunDate
	WHERE	JobDefinitionId = @JobDefinitionId;
GO


--2005
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
		AnswerGuid uniqueidentifier,
		QuestionGuid uniqueidentifier,
		AnswerName nvarchar(1000),
		Label nvarchar(100),
		QuestionName nvarchar(1000),
		PageName nvarchar(1000),
		QuestionTypeId int
	);

	CREATE TABLE #Responses
	(
		LogGuid uniqueidentifier,
		AnswerGuid uniqueidentifier,
		Value nvarchar(1000)
	);
	
	-- Finish date inclusive
	SET @FinishDate = DateAdd(d, 1, @FinishDate);

	INSERT INTO #Answers(QuestionGuid, AnswerGuid, AnswerName, Label, QuestionName, QuestionTypeId, PageName)
	SELECT	Q.value('@Guid', 'uniqueidentifier'),
			A.value('@Guid', 'uniqueidentifier'), 
			A.value('@Name', 'nvarchar(1000)'),
			A.value('@AnswerFileLabel', 'nvarchar(100)'),
			Q.value('@Text', 'nvarchar(1000)'),
			Q.value('@TypeId', 'int'),
			P.value('@Name', 'nvarchar(1000)')
	FROM	Template
			CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
			CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
			CROSS APPLY Q.nodes('(Answer)') as AnswerXml(A)
	WHERE	Template.Template_Id = @TemplateId;

	INSERT INTO #Responses(LogGuid, AnswerGuid, Value)
	SELECT	Template_Log.Log_Guid,
			#Answers.AnswerGuid, 
			C.value('@v', 'nvarchar(1000)')
	FROM	Template_Log 
			CROSS APPLY Answer_File.nodes('(/AnswerFile/ps/p/qs/q/as/a)') as ID(C)
			, #Answers
	WHERE	C.value('@aid', 'uniqueidentifier') = #Answers.AnswerGuid
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
	SELECT	Template_Log.Log_Guid,
			#Answers.AnswerGuid, 
			C.value('@name', 'nvarchar(1000)')
	FROM	Template_Log 
			CROSS APPLY Answer_File.nodes('(/AnswerFile/AnswerLabels/Label)') as Label(C)
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
				WHEN 3	-- Group Logic
				THEN CASE #Responses.Value WHEN '1' THEN '1' ELSE NULL END
				WHEN 6	-- Simple
				THEN CASE #Responses.Value WHEN '1' THEN '1' ELSE NULL END
				ELSE #Responses.Value
				END) as AnswerCount,
			(SELECT COUNT(DISTINCT #Responses.LogGuid) 
				FROM #Answers
				INNER JOIN #Answers ByQuestion ON #Answers.QuestionGuid = ByQuestion.QuestionGuid
				INNER JOIN #Responses ON ByQuestion.AnswerGuid = #Responses.AnswerGuid) as TotalQuestionResponses,
			(SELECT COUNT(DISTINCT #Responses.LogGuid) FROM #Responses) as TotalResponses,
			CASE WHEN #Answers.QuestionTypeId = 7 THEN #Responses.Value ELSE '' END as TextResponse
	FROM	#Answers
			LEFT JOIN #Responses ON #Answers.AnswerGuid = #Responses.AnswerGuid
	WHERE (#Answers.QuestionTypeId = 3	-- Group logic
			OR #Answers.QuestionTypeId = 6	-- Simple logic
			OR (#Answers.QuestionTypeId = 7 AND @DisplayText = 1))	-- User prompt
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


--2006
ALTER procedure [dbo].[spProject_ProjectList]
	@UserGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ProjectTypeId int,
	@SearchString nvarchar(100),
	@Purpose nvarchar(10)
as
	declare @IsGlobal bit
	declare @BusinessUnitGUID uniqueidentifier

	SELECT	@BusinessUnitGUID = Business_Unit_GUID
	FROM	Intelledox_User
	WHERE	User_Guid = @UserGuid;

	IF EXISTS(SELECT	vwUserPermissions.*
		FROM	vwUserPermissions
		WHERE	((@Purpose = 'Design' AND vwUserPermissions.CanDesignProjects = 1)
					OR (@Purpose = 'Publish' AND vwUserPermissions.CanPublishProjects = 1))
				AND vwUserPermissions.GroupGuid IS NULL
				AND vwUserPermissions.UserGuid = @UserGuid)
	BEGIN
		SET @IsGlobal = 1;
	END

	if @GroupGuid IS NULL
	begin
		--all usergroups
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, a.template_version, a.import_date, 
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Content_Bookmark
		FROM	Template a
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		WHERE	(@IsGlobal = 1 or a.template_id in (
				SELECT	User_Group_Template.Template_ID
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.[User_ID] = User_Group_Subscription.[User_ID] 
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.User_Group_Id = User_Group_Template.User_Group_Id 
				WHERE	((@Purpose = 'Design' AND vwUserPermissions.CanDesignProjects = 1)
					OR (@Purpose = 'Publish' AND vwUserPermissions.CanPublishProjects = 1))
			AND Intelledox_User.User_Guid = @UserGuid
				))
			AND (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
		ORDER BY a.[name];
	end
	else
	begin
		--specific user group
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, a.template_version, a.import_date, 
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Content_Bookmark
		FROM	Template a
				INNER JOIN User_Group_Template d on a.Template_ID = d.Template_ID
				INNER JOIN User_Group ON d.User_Group_ID = User_Group.User_Group_ID  AND User_Group.Group_Guid = @GroupGuid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		WHERE	(@IsGlobal = 1 or a.template_id in (
				SELECT	User_Group_Template.Template_ID
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.[User_ID] = User_Group_Subscription.[User_ID] 
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.User_Group_Id = User_Group_Template.User_Group_Id 
				WHERE	((@Purpose = 'Design' AND vwUserPermissions.CanDesignProjects = 1)
					OR (@Purpose = 'Publish' AND vwUserPermissions.CanPublishProjects = 1))
			))
			and (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
		ORDER BY a.[name];
	end
GO


