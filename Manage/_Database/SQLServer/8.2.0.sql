/*
** Database Update package 8.2.0
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.0');
go

--2060
ALTER TABLE Template_group
	ADD	Template_Guid uniqueidentifier null,
		Template_Version int null,
		Layout_Guid uniqueidentifier null,
		Layout_Version int null
GO
UPDATE	Template_group
SET		Template_group.Template_Guid = Template_group_Item.Template_Guid,
		Template_group.Template_Version = Template_group_Item.Template_Version,
		Template_group.Layout_Guid = Template_group_Item.Layout_Guid,
		Template_group.Layout_Version = Template_group_Item.Layout_Version
FROM	Template_group
		INNER JOIN Template_group_Item ON Template_group.Template_Group_Guid = Template_group_Item.Template_Group_Guid;
GO
DELETE FROM Template_group
WHERE	Template_Guid IS NULL;
GO
exec sp_rename 'dbo.Template_group_Item', 'zzTemplate_group_Item';
GO
ALTER TABLE Template_Group
	ADD Folder_Guid  uniqueidentifier null
GO
UPDATE	Template_Group
SET		Folder_Guid = Folder.Folder_Guid
FROM	Folder
		INNER JOIN Folder_Template ON Folder.Folder_ID = Folder_Template.Folder_ID
		INNER JOIN Template_Group ON Folder_Template.FolderItem_Id = Template_Group.Template_Group_ID
GO
DELETE FROM Template_group
WHERE	Folder_Guid IS NULL;
GO
exec sp_rename 'dbo.Folder_Template', 'zzFolder_Template';
GO
ALTER VIEW [dbo].[vwTemplateVersion]
AS
		SELECT	Template_Version.Template_Version, 
			Template_Version.Template_Guid,
			Template_Version.Modified_Date,
			Template.Template_Type_ID,
			Intelledox_User.Username,
			1 AS InUse,
			0 AS Latest
		FROM	Template_Version
			INNER JOIN Template ON Template_Version.Template_Guid = Template.Template_Guid
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template_Version.Modified_By
			LEFT JOIN Template_Group ON (Template_Group.Template_Guid = Template_Version.Template_Guid
					AND Template_Group.Template_Version = Template_Version.Template_Version)
				OR (Template_Group.Layout_Guid = Template_Version.Template_Guid
					AND Template_Group.Layout_Version = Template_Version.Template_Version)
	UNION ALL
		SELECT	Template.Template_Version, 
			Template.Template_Guid,
			Template.Modified_Date,
			Template.Template_Type_ID,
			Intelledox_User.Username,
			1 AS InUse,
			1 AS Latest
		FROM	Template
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By
			LEFT JOIN Template_Group ON (Template_Group.Template_Guid = Template.Template_Guid
					AND Template_Group.Template_Version = Template.Template_Version)
				OR (Template_Group.Layout_Guid = Template.Template_Guid
					AND Template_Group.Layout_Version = Template.Template_Version)
GO
ALTER VIEW [dbo].[vwStatsAllData]
AS
SELECT     TLog.Log_Guid, T.Name AS TemplateGroup, IUser.Username AS Creator, TLog.DateTime_Start, TLog.DateTime_Finish, 
                      CASE WHEN day(tlog.datetime_start) < 10 THEN substring(CAST(CONVERT(varchar(50), TLog.DateTime_Start, 103) AS varchar(50)), 2, 9) 
                      ELSE CAST(CONVERT(varchar(50), TLog.DateTime_Start, 103) AS varchar(50)) END AS Date_Start, DATEDIFF(s, TLog.DateTime_Start, 
                      TLog.DateTime_Finish) AS TimeTaken
FROM        Template_Log AS TLog 
			INNER JOIN Intelledox_User AS IUser ON TLog.User_ID = IUser.User_ID 
			INNER JOIN Template_Group AS TG ON TG.Template_Group_ID = TLog.Template_Group_ID
			INNER JOIN Template AS T ON TG.Template_Guid = T.Template_Guid
GO
ALTER VIEW [dbo].[vwStatsSummaryData]
AS
SELECT     TOP 100 PERCENT IUser.Username AS Creator, T.Name AS TemplateGroup, AVG(DATEDIFF(s, TLog.DateTime_Start, TLog.DateTime_Finish)) 
                      AS AverageTimeTakenLast30Days
FROM        Template_Log AS TLog 
			INNER JOIN Intelledox_User AS IUser ON TLog.User_ID = IUser.User_ID 
			INNER JOIN Template_Group AS TG ON TG.Template_Group_ID = TLog.Template_Group_ID
			INNER JOIN Template AS T ON TG.Template_Guid = T.Template_Guid
WHERE     (TLog.Completed = 1) AND (TLog.DateTime_Start BETWEEN DATEADD(d, - 30, GETDATE()) AND GETDATE())
GROUP BY IUser.Username, T.Name
ORDER BY IUser.Username, T.Name
GO
ALTER procedure [dbo].[spAudit_AnswerFileList]
	@AnswerFile_ID int = 0,
	@User_Guid uniqueidentifier = null,
	@InProgress bit = 0,
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
					INNER JOIN Template AS T ON Template_Group.Template_Guid = T.Template_Guid
					INNER JOIN Intelledox_User ON ans.User_Id = Intelledox_User.User_ID
			where Ans.[user_ID] = @user_id
				AND Ans.[InProgress] = @InProgress
				AND Ans.template_group_id in(

				-- Get a union of template group.
				SELECT DISTINCT tg.Template_Group_ID
				FROM Folder f
					left join (
						SELECT tg.Template_Group_ID, tg.Folder_Guid, tg.Template_Group_Guid, tg.Template_Guid
						FROM template_group tg 
						WHERE (tg.EnforcePublishPeriod = 0 
								OR ((tg.PublishStartDate IS NULL OR tg.PublishStartDate < getdate())
									AND (tg.PublishFinishDate IS NULL OR tg.PublishFinishDate > getdate())))
					) tg on f.Folder_Guid = tg.Folder_Guid
					left join template t on tg.Template_Guid = t.Template_Guid
					inner join folder_group fg on F.Folder_Guid = fg.FolderGuid
				where 	(fg.GroupGuid in
							(select b.Group_Guid
							from intelledox_user a
							left join User_Group_Subscription c on a.User_Guid = c.UserGuid
							left join user_group b on c.groupguid = b.group_guid
							where c.UserGuid = @user_guid)
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
					INNER JOIN Template AS T ON Template_Group.Template_Guid = T.Template_Guid
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
				INNER JOIN Template AS T ON Template_Group.Template_Guid = T.Template_Guid
				INNER JOIN Intelledox_User ON Answer_File.User_Id = Intelledox_User.User_ID
        WHERE	Answer_File.AnswerFile_Id = @AnswerFile_Id
        ORDER BY Answer_File.[RunDate] desc;
    end
GO
ALTER PROCEDURE [dbo].[spDocument_DocumentList] (
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier
)
AS
	SELECT	Document.DocumentId, 
			Document.Extension,  
			Document.DisplayName,  
			Document.ProjectDocumentGuid,  
			Document.DateCreated,  
			Document.JobId,
			Template.Name As ProjectName
	FROM	Document
			INNER JOIN ProcessJob ON Document.JobId = ProcessJob.JobId
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
	WHERE	(Document.JobId = @JobId OR @JobId IS NULL)
			AND Document.UserGuid = @UserGuid --Security check;
GO
ALTER procedure [dbo].[spFolder_PublishedProjectList]
	@UserGuid uniqueidentifier,
	@ErrorCode int output
as
	declare @BusinessUnitGuid uniqueidentifier
	select @BusinessUnitGuid = business_unit_guid from Intelledox_User where User_Guid = @UserGuid

	SELECT	a.Folder_ID, a.Folder_Guid, a.Folder_Name, d.Template_Group_Id, b.[Name] as Project_Name,
			d.Template_Group_Guid
	FROM	Folder a
		left join Template_Group d on a.Folder_Guid = d.Folder_Guid
			AND (d.EnforcePublishPeriod = 0 
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getdate())))
		left join Template b on d.Template_Guid = b.Template_Guid
	WHERE	((d.Template_Group_Guid in (
					select	c.Template_Group_Guid
					from	template_group c
							inner join template b on c.Template_Guid = b.template_Guid or c.Layout_Guid = b.template_Guid
					group by c.Template_Group_Guid
				)
			))
		and a.Business_Unit_GUID = @BusinessUnitGuid
		and a.Folder_Guid in (
			SELECT	FolderGuid
			FROM	Folder_Group
			WHERE	GroupGuid in (
				select	distinct b.Group_Guid
				from	Intelledox_User a
						left join User_Group_Subscription c on a.User_Guid = c.UserGuid
						left join User_Group b on c.GroupGuid = b.Group_Guid
				where	b.Group_Guid is not null
				and		a.User_Guid = @UserGuid
			)
		)
	ORDER BY a.Folder_Name, a.Folder_ID, d.template_group_id
	
	set @ErrorCode = @@error
GO
ALTER procedure [dbo].[spGetBilling]
AS
	DECLARE @CurrentDate DateTime
	DECLARE @LicenseHolder NVarchar(1000)
	
	SET NOCOUNT ON
	
	SET @CurrentDate = CAST(CONVERT(Varchar(10), GETUTCDATE(), 102) AS DateTime)
	
	SELECT	@LicenseHolder = OptionValue 
	FROM	Global_Options
	WHERE	OptionCode = 'LICENSE_HOLDER'

	SELECT	@LicenseHolder as LicenseHolder, CONVERT(Varchar(10), Template_Log.DateTime_Finish, 102) as ActivityDate, 
			IsNull(Template.Name, '') as ProjectName, COUNT(*) AS DocumentCount
	FROM	Template_Log
			LEFT JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
			LEFT JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
	WHERE	Template_Log.Completed = 1
			AND Template_Log.DateTime_Finish BETWEEN DATEADD(d, -30, @CurrentDate) AND @CurrentDate
	GROUP BY CONVERT(Varchar(10), Template_Log.DateTime_Finish, 102), IsNull(Template.Name, '')
GO
ALTER PROCEDURE [dbo].[spJob_QueueList]
	@StartDate DateTime,
	@FinishDate DateTime,
	@CurrentStatus Int
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus,
			Template.Name as ProjectName, Intelledox_User.Username, 
			ProcessJob.LogGuid,
			CASE WHEN template_Log.Messages IS NOT NULL THEN 1 ELSE 0 END AS HasMessages
	FROM	ProcessJob
			INNER JOIN Intelledox_User ON ProcessJob.UserGuid = Intelledox_User.User_Guid
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
			LEFT JOIN Template_Log ON ProcessJob.LogGuid = Template_Log.Log_Guid
	WHERE	ProcessJob.DateStarted BETWEEN @StartDate AND @FinishDate
			AND ((@CurrentStatus = 0) OR 
				(@CurrentStatus = -1 AND ProcessJob.CurrentStatus <> 7) OR 
				(@CurrentStatus <> -1 AND ProcessJob.CurrentStatus = @CurrentStatus))
	ORDER BY ProcessJob.DateStarted DESC;
GO
ALTER PROCEDURE [dbo].[spJob_QueueListByDefinition]
	@JobDefinitionId uniqueidentifier
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus,
			Template.Name as ProjectName, Intelledox_User.Username, 
			ProcessJob.LogGuid,
			CASE WHEN template_Log.Messages IS NOT NULL THEN 1 ELSE 0 END AS HasMessages
	FROM	ProcessJob
			INNER JOIN Intelledox_User ON ProcessJob.UserGuid = Intelledox_User.User_Guid
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
			LEFT JOIN Template_Log ON ProcessJob.LogGuid = Template_Log.Log_Guid
	WHERE	ProcessJob.JobDefinitionGuid = @JobDefinitionId
	ORDER BY ProcessJob.DateStarted DESC;
GO
ALTER PROCEDURE [dbo].[spProject_DefinitionsByGroup] (
	@TemplateGroupGuid uniqueidentifier
)
AS
		SELECT	Template.Template_Guid, 
			Template.Project_Definition, 
			Template.Template_Type_ID
		FROM	Template_Group
				INNER JOIN Template ON (Template_Group.Template_Guid = Template.Template_Guid 
						AND (Template_Group.Template_Version IS NULL
							OR Template_Group.Template_Version = Template.Template_Version))
					OR (Template_Group.Layout_Guid = Template.Template_Guid
						AND (Template_Group.Layout_Version IS NULL
							OR Template_Group.Layout_Version = Template.Template_Version))
		WHERE	Template_Group.Template_Group_Guid = @TemplateGroupGuid
	UNION ALL
		SELECT	Template_Version.Template_Guid, 
			Template_Version.Project_Definition, 
			Template.Template_Type_ID
		FROM	Template_Group
				INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
				INNER JOIN Template_Version ON (Template_Group.Template_Guid = Template_Version.Template_Guid 
						AND Template_Group.Template_Version = Template_Version.Template_Version)
					OR (Template_Group.Layout_Guid = Template_Version.Template_Guid
						AND Template_Group.Layout_Version = Template_Version.Template_Version)
		WHERE	Template_Group.Template_Group_Guid = @TemplateGroupGuid
	ORDER BY Template_Type_ID;
GO
ALTER procedure [dbo].[spProject_GetFoldersByProject]
	@ProjectGuid uniqueidentifier
AS
	SELECT	Folder.Folder_Name, Folder.Folder_Guid, Template_Group.Template_Group_Guid,
			Template.Template_Type_ID
	FROM	Folder
			INNER JOIN Template_Group on Folder.Folder_Guid = Template_Group.Folder_Guid
			INNER JOIN Template on Template_Group.Template_Guid = Template.Template_Guid
	WHERE	Template.Template_Guid = @ProjectGuid
	ORDER BY Folder.Folder_Name;
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
			b.Template_Type_ID, d.Template_Group_Guid
	FROM	Folder a
			INNER JOIN Template_Group d on a.folder_Guid = d.Folder_Guid
			INNER JOIN Template b on d.Template_Guid = b.Template_Guid
	WHERE	a.Business_Unit_GUID = @BusinessUnitGUID
			AND a.Folder_Guid IN (
				SELECT	Folder_Group.FolderGuid
				FROM	Folder_Group
						INNER JOIN User_Group ON Folder_Group.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Subscription ON User_Group.Group_Guid = User_Group_Subscription.GroupGuid
						INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
				WHERE	Intelledox_User.User_Guid = @UserGuid
				)
			AND a.Folder_Name LIKE @FolderSearch + '%'
			AND CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END LIKE @ProjectSearch + '%'
			AND (d.EnforcePublishPeriod = 0 
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getdate())))
	ORDER BY a.Folder_Name, a.Folder_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END;
GO
ALTER procedure [dbo].[spProjectGroup_Recent]
	@UserGuid uniqueidentifier,
	@ProjectSearch nvarchar(100)
AS
	DECLARE @BusinessUnitGuid uniqueidentifier
	
	SELECT	@BusinessUnitGuid = Business_Unit_Guid
	FROM	Intelledox_User
	WHERE	Intelledox_User.User_Guid = @UserGuid;
	
	SELECT	DISTINCT d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, b.Template_ID, b.[Name] as Template_Name, 
			b.Template_Type_ID, d.Template_Group_Guid, l.DateTime_Start, l.Log_Guid
	FROM	Folder a
			INNER JOIN Template_Group d on a.folder_Guid = d.Folder_Guid
			INNER JOIN Template b on d.Template_Guid = b.Template_Guid
			INNER JOIN Template_Recent l on d.Template_Group_Guid = l.Template_Group_Guid
	WHERE	a.Business_Unit_GUID = @BusinessUnitGUID
			AND a.Folder_Guid IN (
				SELECT	Folder_Group.FolderGuid
				FROM	Folder_Group
						INNER JOIN User_Group ON Folder_Group.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Subscription ON User_Group.Group_Guid = User_Group_Subscription.GroupGuid
						INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
				WHERE	Intelledox_User.User_Guid = @UserGuid
				)
			AND CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END LIKE @ProjectSearch + '%'
			AND l.[User_Guid] = @UserGuid
			AND (d.EnforcePublishPeriod = 0 
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getdate())))
	ORDER BY l.DateTime_Start DESC;
GO
ALTER procedure [dbo].[spProjectGrp_ProjectGroupList]
      @ProjectGroupGuid uniqueidentifier
AS
    SELECT	a.Template_Group_ID, t.[Name] as Template_Group_Name, a.template_group_guid, 
			a.helptext as TemplateGroup_HelpText, a.Template_Guid, a.Layout_Guid,
			a.Template_Version, a.Layout_Version, a.AllowPreview, a.PostGenerateText,
			a.UpdateDocumentFields, a.EnforceValidation, a.WizardFinishText, 
			a.EnforcePublishPeriod, a.PublishStartDate, a.PublishFinishDate,
			a.HideNavigationPane
    FROM	Template_Group a
			INNER JOIN Template t on a.Template_Guid = t.Template_Guid
    WHERE	a.Template_Group_Guid = @ProjectGroupGuid;
GO
ALTER procedure [dbo].[spProjectGrp_ProjectGroupListByFolder]
	@FolderGuid uniqueidentifier,
	@IncludeRestricted bit
AS
	SELECT	d.Template_Group_ID, CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, d.Template_Group_Guid,
			b.Template_Guid, d.Layout_Guid
	FROM	Folder a
			INNER JOIN Template_Group d on a.folder_Guid = d.Folder_Guid
			INNER JOIN Template b on d.Template_Guid = b.Template_Guid
	WHERE	a.Folder_Guid = @FolderGuid
			AND ((d.EnforcePublishPeriod = 0 OR @IncludeRestricted = 1)
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getdate())))
	ORDER BY d.[Name], b.[Name], d.Template_Group_ID;
GO
ALTER procedure [dbo].[spProjectGrp_RemoveFolder]
	@FolderGuid uniqueidentifier
AS
	DECLARE @FolderID INT
	
	SET NOCOUNT ON
	
	SELECT	@FolderID = Folder_Id
	FROM	Folder
	WHERE	Folder_Guid = @FolderGuid;
	
	DELETE Template_Group 
	WHERE Folder_Guid = @FolderGuid;
	
	DELETE Folder WHERE Folder_ID = @FolderID;
GO
ALTER procedure [dbo].[spProjectGrp_RemoveProjectGroup]
	@ProjectGroupGuid uniqueidentifier
AS
	DELETE Template_Group WHERE Template_Group_Guid = @ProjectGroupGuid;
GO
DROP procedure [dbo].[spProjectGrp_SubscribeProjectGroup]
GO
DROP PROCEDURE [dbo].[spProjectGrp_UnsubscribeProjectGroup]
GO
ALTER procedure [dbo].[spReport_LogicResponses]
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
				SELECT	tg.Template_Group_Id
				FROM	Template_Group tg
						INNER JOIN Template t ON tg.Template_Guid = t.Template_Guid
				WHERE	t.Template_Id = @TemplateId
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
				SELECT	tg.Template_Group_Id
				FROM	Template_Group tg
						INNER JOIN Template t ON tg.Template_Guid = t.Template_Guid
				WHERE	t.Template_Id = @TemplateId
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
ALTER procedure [dbo].[spReport_ResultsCSV]
	@TemplateId Int,
	@StartDate datetime,
	@FinishDate datetime
AS
	SET ARITHABORT ON 
	CREATE TABLE #Answers
	(
		Id int identity(1,1),
		AnswerGuid uniqueidentifier,
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
		AnswerGuid uniqueidentifier,
		Value nvarchar(1000),
		StartDate datetime,
		FinishDate datetime,
		UserId int
	);
	
	-- Finish date inclusive
	SET @FinishDate = DateAdd(d, 1, @FinishDate);

	INSERT INTO #Answers(AnswerGuid, AnswerName, Label, QuestionName, QuestionTypeId, PageName, QuestionID)
	SELECT	A.value('@Guid', 'uniqueidentifier'), 
			A.value('@Name', 'nvarchar(1000)'),
			A.value('@AnswerFileLabel', 'nvarchar(100)'),
			Q.value('@Text', 'nvarchar(1000)'),
			Q.value('@TypeId', 'int'),
			P.value('@Name', 'nvarchar(1000)'),
			Q.value('@ID', 'int')
	FROM	Template
			CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
			CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
			CROSS APPLY Q.nodes('(Answer)') as AnswerXml(A)
	WHERE	Template.Template_Id = @TemplateId;

	INSERT INTO #Responses(LogGuid, AnswerGuid, Value, StartDate, FinishDate, UserId)
	SELECT	Template_Log.Log_Guid,
			#Answers.AnswerGuid, 
			C.value('@v', 'nvarchar(1000)'),
			Template_Log.DateTime_Start,
			Template_Log.DateTime_Finish,
			Template_Log.User_Id
	FROM	Template_Log 
			CROSS APPLY Answer_File.nodes('(/AnswerFile/ps/p/qs/q/as/a)') as ID(C)
			, #Answers
	WHERE	C.value('@aid', 'uniqueidentifier') = #Answers.AnswerGuid
			AND Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
			AND (#Answers.QuestionTypeId = 3	-- Group logic
				OR #Answers.QuestionTypeId = 6	-- Simple logic
				OR #Answers.QuestionTypeId = 7)	-- User prompt
			AND Template_Log.Template_Group_Id IN
			(
				SELECT	tg.Template_Group_Id
				FROM	Template_Group tg
						INNER JOIN Template t ON tg.Template_Guid = t.Template_Guid
				WHERE	t.Template_Id = @TemplateId
			)
	UNION ALL
	SELECT	Template_Log.Log_Guid,
			#Answers.AnswerGuid, 
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
				SELECT	tg.Template_Group_Id
				FROM	Template_Group tg
						INNER JOIN Template t ON tg.Template_Guid = t.Template_Guid
				WHERE	t.Template_Id = @TemplateId
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
							WHEN '1'
							THEN 'Yes'
							ELSE 'No'
							END
						ELSE #Responses.Value
					END as 'Answer'
			
	FROM	#Answers
			INNER JOIN #Responses ON #Answers.AnswerGuid = #Responses.AnswerGuid
			INNER JOIN Intelledox_User ON Intelledox_User.User_ID = #Responses.UserID
	WHERE (#Answers.QuestionTypeId = 3 AND #Responses.Value = '1')
		OR (#Answers.QuestionTypeId = 6)
		OR (#Answers.QuestionTypeId = 7)
	ORDER BY #Responses.LogGuid,
			Intelledox_User.Username,
			#Responses.StartDate,
			#Responses.FinishDate;

	DROP TABLE #Answers;
	DROP TABLE #Responses;
GO
ALTER procedure [dbo].[spReport_UsageDataMostRunTemplates] (
	@StartDate datetime,
	@FinishDate datetime,
	@BusinessUnitGuid uniqueidentifier
)
AS
	SELECT TOP 10 Template.Template_Guid,
		Template.Name AS TemplateName,
		COUNT(*) AS NumRuns
	FROM Template_Log 
		INNER JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
		INNER JOIN Template ON Template.Template_Guid = Template_Group.Template_Guid
		INNER JOIN Intelledox_User ON Intelledox_User.User_ID = Template_Log.User_ID
    WHERE Template_Log.DateTime_Finish IS NOT NULL
		AND Template_Log.DateTime_Finish >= @StartDate
        AND Template_Log.DateTime_Finish <= @FinishDate + 1
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
    GROUP BY Template.Template_Guid,
		Template.Name
	ORDER BY NumRuns DESC;
GO
ALTER procedure [dbo].[spReport_UsageDataTimeTaken] (
	@StartDate datetime,
	@FinishDate datetime,
	@BusinessUnitGuid uniqueidentifier
)
AS
	SELECT TOP 10 Template.Name AS TemplateName,
		AVG(DateDiff(second, Template_Log.DateTime_Start, Template_Log.DateTime_Finish)) AS AvgTimeTaken
	FROM Template_Log 
		INNER JOIN Template_Group ON Template_Log.Template_Group_ID = Template_Group.Template_Group_ID
		INNER JOIN Template ON Template.Template_Guid = Template_Group.Template_Guid
		INNER JOIN Intelledox_User ON Intelledox_User.User_ID = Template_Log.User_ID
    WHERE Template_Log.DateTime_Finish IS NOT NULL
		AND Template_Log.DateTime_Finish >= @StartDate
        AND Template_Log.DateTime_Finish <= @FinishDate + 1
        AND Intelledox_User.Business_Unit_Guid = @BusinessUnitGuid
    GROUP BY Template.Template_Guid,
		Template.Name
	ORDER BY AVG(DateDiff(second, Template_Log.DateTime_Start, Template_Log.DateTime_Finish)) DESC;
GO
ALTER procedure [dbo].[spTemplate_RemoveTemplate]
	@TemplateGuid uniqueidentifier,
	@OnlyChildInfo bit
as
	DECLARE @TemplateId Int

	SELECT	@TemplateId = Template_Id
	FROM	Template
	WHERE	Template_Guid = @TemplateGuid;

	IF @OnlyChildInfo = 0
	BEGIN
		DELETE	template_Group
		WHERE	template_guid = @TemplateGuid
			OR	layout_guid = @TemplateGuid;

		DELETE	Template_Category
		WHERE	Template_ID = @TemplateID;

		DELETE	User_Group_Template
		WHERE	TemplateGuid = @TemplateGuid;
	END
	
	DELETE	Template_File
	WHERE	Template_Guid = @TemplateGuid;
	
	DELETE	Template
	WHERE	Template_Guid = @TemplateGuid;
	
	DELETE	Template_File_Version
	WHERE	Template_Guid = @TemplateGuid;
	
	DELETE	Template_Version
	WHERE	Template_Guid = @TemplateGuid;
GO
ALTER procedure [dbo].[spTemplateGrp_FolderTemplateList]
	@FolderID int = 0,
	@ErrorCode int output
as
	SELECT	a.*, d.*, b.Template_ID, b.[Name], b.Template_Type_ID
	FROM	Folder a
		inner join Template_Group d on a.folder_Guid = d.Folder_Guid
		inner join Template b on b.Template_Guid = d.Template_Guid
	WHERE	(@FolderID = 0 OR a.Folder_ID = @FolderID)
	ORDER BY a.Folder_ID, d.Template_Group_ID;
	
	set @ErrorCode = @@error
GO
ALTER procedure [dbo].[spTemplateGrp_RemoveFolder]
	@FolderID int,
	@ErrorCode int output
as
	DELETE Template_Group 
	WHERE Folder_Guid = (
		SELECT	Folder_Guid
		FROM	Folder
		WHERE	Folder_ID = @FolderID);
	
	DELETE Folder WHERE Folder_ID = @FolderID;
	
	set @ErrorCode = @@error;
GO
ALTER procedure [dbo].[spTemplateGrp_RemoveTemplateGroup]
	@TemplateGroupID int,
	@ErrorCode int output
as
	-- Remove the group records
	DELETE Template_Group WHERE Template_Group_ID = @TemplateGroupID;
	
	set @ErrorCode = @@error;
GO
ALTER PROCEDURE [dbo].[spProjectGrp_UpdateProjectGroup]
	@ProjectGroupGuid uniqueidentifier,
	@Name nvarchar(100),
	@HelpText nvarchar(4000),
	@AllowPreview bit,
	@WizardFinishText nvarchar(max),
	@PostGenerateText nvarchar(4000),
	@UpdateDocumentFields bit,
	@EnforceValidation bit,
	@HideNavigationPane bit,
	@EnforcePublishPeriod bit,
	@PublishStartDate datetime,
	@PublishFinishDate datetime,
	@ProjectGuid uniqueidentifier,
	@LayoutGuid uniqueidentifier,
	@ProjectVersion int,
	@LayoutVersion int,
	@FolderGuid uniqueidentifier
AS
	IF NOT EXISTS(SELECT * FROM Template_Group WHERE template_group_guid = @ProjectGroupGuid)
	BEGIN
		INSERT INTO Template_Group ([name], template_group_guid, helptext, AllowPreview, PostGenerateText, 
				UpdateDocumentFields, EnforceValidation, WizardFinishText, EnforcePublishPeriod,
				PublishStartDate, PublishFinishDate, HideNavigationPane, Template_Guid, Layout_Guid,
				Template_Version, Layout_Version, Folder_Guid)
		VALUES (@Name, @ProjectGroupGuid, @HelpText, @AllowPreview, @PostGenerateText, 
				@UpdateDocumentFields, @EnforceValidation, @WizardFinishText, @EnforcePublishPeriod,
				@PublishStartDate, @PublishFinishDate, @HideNavigationPane, @ProjectGuid, @LayoutGuid,
				@ProjectVersion, @LayoutVersion, @FolderGuid);
	END
	ELSE
	BEGIN
		UPDATE	Template_Group
		SET		[Name] = @Name,
				HelpText = @HelpText,
				AllowPreview = @AllowPreview,
				PostGenerateText = @PostGenerateText,
				UpdateDocumentFields = @UpdateDocumentFields,
				EnforceValidation = @EnforceValidation,
				WizardFinishText = @WizardFinishText,
				EnforcePublishPeriod = @EnforcePublishPeriod,
				PublishStartDate = @PublishStartDate,
				PublishFinishDate = @PublishFinishDate,
				HideNavigationPane = @HideNavigationPane,
				Template_Guid = @ProjectGuid,
				Layout_Guid = @LayoutGuid,
				Template_Version = @ProjectVersion,
				Layout_Version = @LayoutVersion,
				Folder_Guid = @FolderGuid
		WHERE	Template_Group_Guid = @ProjectGroupGuid;
	END
GO
ALTER procedure [dbo].[spTemplateGrp_FolderList]
	@FolderID int,
	@TemplateGroupID int,
	@ErrorCode int output
as
	IF @TemplateGroupID IS NULL OR @TemplateGroupID = 0
	BEGIN
		SELECT	*
		FROM	Folder
		WHERE	Folder_ID = @FolderID
	END
	ELSE
	BEGIN
		SELECT	TOP 1 Folder.*
		FROM	Folder
				INNER JOIN Template_Group ON Folder.Folder_Guid = Template_Group.Folder_Guid
		WHERE	Template_group.Template_Group_ID = @TemplateGroupID
	END

	set @ErrorCode = @@error
GO
DROP PROCEDURE spTemplateGrp_SubscribeFolder
GO
DROP PROCEDURE spTemplateGrp_UnsubscribeFolder
GO
DROP PROCEDURE spProjectGrp_Publish
GO
DROP PROCEDURE spProjectGrp_Unpublish
GO
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
				a.Content_Bookmark, a.Modified_By
		FROM	Template a
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		WHERE	(@IsGlobal = 1 or a.Template_Guid in (
				SELECT	User_Group_Template.TemplateGuid
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid
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
				a.Content_Bookmark, a.Modified_By
		FROM	Template a
				INNER JOIN User_Group_Template d on a.Template_Guid = d.TemplateGuid
				INNER JOIN User_Group ON d.GroupGuid = User_Group.Group_Guid AND User_Group.Group_Guid = @GroupGuid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		WHERE	(@IsGlobal = 1 or a.template_Guid in (
				SELECT	User_Group_Template.TemplateGuid
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid
				WHERE	((@Purpose = 'Design' AND vwUserPermissions.CanDesignProjects = 1)
					OR (@Purpose = 'Publish' AND vwUserPermissions.CanPublishProjects = 1))
			))
			and (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
		ORDER BY a.[name];
	end
GO
ALTER procedure [dbo].[spProject_ProjectListFullText]
	@UserGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ProjectTypeId int,
	@SearchString nvarchar(100),
	@FullText NVarChar(1000)
as
	declare @IsGlobal bit
	declare @BusinessUnitGUID uniqueidentifier

	SELECT	@BusinessUnitGUID = Business_Unit_GUID
	FROM	Intelledox_User
	WHERE	User_Guid = @UserGuid;

	IF EXISTS(SELECT	vwUserPermissions.*
		FROM	vwUserPermissions
		WHERE	vwUserPermissions.CanDesignProjects = 1
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
				a.Content_Bookmark, a.Modified_By
		FROM	Template a
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		WHERE	(@IsGlobal = 1 or a.template_Guid in (
				SELECT	User_Group_Template.TemplateGuid
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid 
				WHERE	vwUserPermissions.CanDesignProjects = 1
			AND Intelledox_User.User_Guid = @UserGuid
				))
			AND (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
			AND (a.Template_Guid IN (
					SELECT	Template_Guid
					FROM	Template_File tf
					WHERE	Contains(*, @FullText)
				))
		ORDER BY a.[name];
	end
	else
	begin
		--specific user group
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, a.template_version, a.import_date, 
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Content_Bookmark, a.Modified_By
		FROM	Template a
				INNER JOIN User_Group_Template d on a.Template_Guid = d.TemplateGuid
				INNER JOIN User_Group ON d.GroupGuid = User_Group.Group_Guid  AND User_Group.Group_Guid = @GroupGuid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		WHERE	(@IsGlobal = 1 or a.template_Guid in (
				SELECT	User_Group_Template.TemplateGuid
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid 
				WHERE	vwUserPermissions.CanDesignProjects = 1
			))
			and (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
			AND (a.Template_Guid IN (
					SELECT	Template_Guid
					FROM	Template_File tf
					WHERE	Contains(*, @FullText)
				))
		ORDER BY a.[name];
	end
GO
ALTER procedure [dbo].[spTemplate_TemplateList]
	@TemplateID int = 0,
	@TemplateGuid uniqueidentifier = null,
	@ErrorCode int output
as
	SET NOCOUNT ON
	
	If @TemplateGuid IS NOT NULL
	BEGIN
		SELECT	@TemplateId = Template_Id
		FROM	Template
		WHERE	Template_Guid = @TemplateGuid;
	END

	IF @TemplateID = 0 
		SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, b.Category_ID, 
				b.[Name] as Category_Name, a.Supplier_Guid, a.Business_Unit_Guid,
				a.Content_Bookmark, a.HelpText, a.Modified_Date, Intelledox_User.Username, 
				a.[name] as Project_Name, a.Modified_By
		FROM	Template a
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		ORDER BY a.[Name];
	ELSE
		SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, b.Category_ID, 
				b.[Name] as Category_Name, a.Supplier_Guid, a.Business_Unit_Guid,
				a.Content_Bookmark, a.HelpText, a.Modified_Date, Intelledox_User.Username,
				a.[name] as Project_Name, a.Modified_By
		FROM	Template a
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
		WHERE	a.template_id = @TemplateID
		ORDER BY a.[Name];

	set @ErrorCode = @@error;
GO

--2061
CREATE VIEW dbo.vwTemplateVersionLatest
AS
	SELECT Template_Version, Template_Guid, Modified_Date, Modified_By, Project_Definition
	FROM	Template
GO
UPDATE	Template_Group
SET		Template_Version = null
WHERE	Template_Version = 0;
GO
UPDATE	Template_Group
SET		Layout_Version = null
WHERE	Layout_Version = 0;
GO


--2062
ALTER TABLE dbo.Answer_File
	DROP CONSTRAINT DF_Answer_File_InProgress
GO
CREATE TABLE dbo.Tmp_Answer_File
	(
	AnswerFile_Guid uniqueidentifier NOT NULL,
	User_Guid uniqueidentifier NOT NULL,
	Template_Group_Guid uniqueidentifier NOT NULL,
	AnswerFile_ID int NOT NULL IDENTITY (1, 1),
	Description nvarchar(255) NULL,
	RunDate datetime NULL,
	AnswerString xml NULL,
	InProgress bit NOT NULL
	)
GO
CREATE CLUSTERED INDEX IX_Answer_File_UserGuid ON dbo.Tmp_Answer_File
	(
	User_Guid,
	Template_Group_Guid
	) 
GO
ALTER TABLE dbo.Tmp_Answer_File ADD CONSTRAINT
	PK_Answer_File2 PRIMARY KEY NONCLUSTERED 
	(
	AnswerFile_Guid
	) 
GO
CREATE NONCLUSTERED INDEX IX_Answer_File_AnswerFileId ON dbo.Tmp_Answer_File
	(
	AnswerFile_ID
	) 
GO
ALTER TABLE dbo.Tmp_Answer_File ADD CONSTRAINT
	DF_Answer_File_InProgress DEFAULT ((0)) FOR InProgress
GO
SET IDENTITY_INSERT dbo.Tmp_Answer_File ON
GO
IF EXISTS(SELECT * FROM dbo.Answer_File)
	INSERT INTO dbo.Tmp_Answer_File (AnswerFile_ID, Description, RunDate, AnswerString, InProgress, 
			AnswerFile_Guid, Template_Group_Guid, User_Guid)
	SELECT	AnswerFile_ID, Description, RunDate, AnswerString, InProgress,
			newid(), Template_Group.Template_Group_Guid, Intelledox_User.User_Guid
	FROM	Answer_File
			INNER JOIN Intelledox_User ON Answer_File.User_ID = Intelledox_User.User_ID
			INNER JOIN Template_Group ON Answer_File.Template_Group_Id = Template_Group.Template_Group_ID
GO
SET IDENTITY_INSERT dbo.Tmp_Answer_File OFF
GO
DROP TABLE dbo.Answer_File
GO
EXECUTE sp_rename N'dbo.Tmp_Answer_File', N'Answer_File', 'OBJECT' 
GO
ALTER procedure [dbo].[spAudit_UpdateAnswerFile]
	@AnswerFile_ID int,
	@AnswerFile_Guid uniqueidentifier,
	@User_Guid uniqueidentifier,
	@Template_Group_Guid uniqueidentifier,
	@Description nvarchar(255),
	@RunDate datetime,
	@AnswerString xml,
	@InProgress bit = 0,
	@NewID int output,
	@ErrorCode int output
AS
	set nocount on
	
	if ((@AnswerFile_ID = 0 OR @AnswerFile_ID IS NULL) AND @AnswerFile_Guid IS NOT NULL)
	begin
		 SELECT	@AnswerFile_ID = AnswerFile_ID 
		 FROM	Answer_File 
		 WHERE	AnswerFile_Guid = @AnswerFile_Guid
	end

	if (@AnswerFile_ID > 0)
	begin
		update Answer_File
		set [Description] = @Description,
			RunDate = @RunDate,
			AnswerString = @AnswerString
		where AnswerFile_ID = @AnswerFile_ID;
	end
	else
	begin
		insert into Answer_File (AnswerFile_Guid, [User_Guid], [Template_Group_Guid], [Description], [RunDate], [AnswerString], [InProgress])
		values (@AnswerFile_Guid, @User_Guid, @Template_Group_Guid, @Description, @RunDate, @AnswerString, @InProgress);

		select @NewID = @@Identity;
	end

	set @ErrorCode = @@Error;
GO
ALTER procedure [dbo].[spAudit_AnswerFileList]
	@AnswerFile_ID int = 0,
	@AnswerFile_Guid uniqueidentifier = null,
	@User_Guid uniqueidentifier = null,
	@InProgress bit = 0,
	@TemplateGroupGuid uniqueidentifier = null,
	@ErrorCode int output
AS
	set nocount on
	
	IF (@AnswerFile_Guid IS NOT NULL)
	BEGIN
		SELECT	@AnswerFile_ID = AnswerFile_ID
		FROM	Answer_File
		WHERE	AnswerFile_Guid = @AnswerFile_Guid;
	END

	if @AnswerFile_ID = 0 or @AnswerFile_ID is null
    begin
		if @TemplateGroupGuid is null
			select	ans.AnswerFile_Id, ans.User_Guid, ans.Template_Group_Guid, ans.Description, 
					ans.RunDate, ans.InProgress, ans.AnswerFile_Guid,
					Template.Name as TemplateGroup_Name, Template_Group.Template_Group_Guid
			from	answer_file ans
					inner join Template_Group on ans.Template_Group_Guid = Template_Group.Template_Group_Guid
					inner join Template on Template_Group.Template_Guid = Template.Template_Guid
			where	Ans.[User_Guid] = @user_Guid
					AND Ans.[InProgress] = @InProgress
					AND Ans.template_group_Guid in (

				-- Get a union of template group.
				SELECT DISTINCT tg.Template_Group_Guid
				FROM Folder f
					left join (
						SELECT tg.Template_Group_ID, tg.Folder_Guid, tg.Template_Group_Guid, tg.Template_Guid
						FROM template_group tg 
						WHERE (tg.EnforcePublishPeriod = 0 
								OR ((tg.PublishStartDate IS NULL OR tg.PublishStartDate < getdate())
									AND (tg.PublishFinishDate IS NULL OR tg.PublishFinishDate > getdate())))
					) tg on f.Folder_Guid = tg.Folder_Guid
					left join template t on tg.Template_Guid = t.Template_Guid
					inner join folder_group fg on F.Folder_Guid = fg.FolderGuid
				where 	(fg.GroupGuid in
							(select b.Group_Guid
							from intelledox_user a
							left join User_Group_Subscription c on a.User_Guid = c.UserGuid
							left join user_group b on c.groupguid = b.group_guid
							where c.UserGuid = @user_guid)
						)
			)
			order by [RunDate] desc;
		else
			select	ans.AnswerFile_Id, ans.User_Guid, ans.Template_Group_Guid, ans.Description, 
					ans.RunDate, ans.InProgress, ans.AnswerFile_Guid
			from	answer_file ans
			where	Ans.[user_Guid] = @user_Guid
					AND Ans.Template_group_Guid = @TemplateGroupGuid
			order by [RunDate] desc;
    end
    else
    begin
        SELECT	Answer_File.*
		FROM	Answer_File
        WHERE	Answer_File.AnswerFile_Id = @AnswerFile_Id
        ORDER BY Answer_File.[RunDate] desc;
    end
GO

--2063
ALTER procedure [dbo].[spAudit_RemoveAnswerFile]
	@AnswerFile_ID int
AS
	set nocount on

	delete Answer_File
	where AnswerFile_Id = @AnswerFile_Id;
GO


--2064
ALTER procedure [dbo].[spAudit_RemoveAnswerFile]
	@AnswerFile_Guid uniqueidentifier
AS
	set nocount on

	delete Answer_File
	where AnswerFile_Guid = @AnswerFile_Guid;
GO
ALTER procedure [dbo].[spAudit_AnswerFileList]
	@AnswerFile_ID int = 0,
	@AnswerFile_Guid uniqueidentifier = null,
	@User_Guid uniqueidentifier = null,
	@InProgress bit = 0,
	@TemplateGroupGuid uniqueidentifier = null,
	@ErrorCode int output
AS
	set nocount on
	
	IF (@AnswerFile_Guid IS NOT NULL)
	BEGIN
		SELECT	@AnswerFile_ID = AnswerFile_ID
		FROM	Answer_File
		WHERE	AnswerFile_Guid = @AnswerFile_Guid;
	END

	if @AnswerFile_ID = 0 or @AnswerFile_ID is null
    begin
		if @TemplateGroupGuid is null
			select	ans.AnswerFile_Id, ans.User_Guid, ans.Template_Group_Guid, ans.Description, 
					ans.RunDate, ans.InProgress, ans.AnswerFile_Guid,
					Template.Name as TemplateGroup_Name, Template_Group.Template_Group_Guid
			from	answer_file ans
					inner join Template_Group on ans.Template_Group_Guid = Template_Group.Template_Group_Guid
					inner join Template on Template_Group.Template_Guid = Template.Template_Guid
			where	Ans.[User_Guid] = @user_Guid
					AND Ans.[InProgress] = @InProgress
					AND Ans.template_group_Guid in (

				-- Get a union of template group.
				SELECT DISTINCT tg.Template_Group_Guid
				FROM Folder f
					left join (
						SELECT tg.Template_Group_ID, tg.Folder_Guid, tg.Template_Group_Guid, tg.Template_Guid
						FROM template_group tg 
						WHERE (tg.EnforcePublishPeriod = 0 
								OR ((tg.PublishStartDate IS NULL OR tg.PublishStartDate < getdate())
									AND (tg.PublishFinishDate IS NULL OR tg.PublishFinishDate > getdate())))
					) tg on f.Folder_Guid = tg.Folder_Guid
					left join template t on tg.Template_Guid = t.Template_Guid
					inner join folder_group fg on F.Folder_Guid = fg.FolderGuid
				where 	(fg.GroupGuid in
							(select b.Group_Guid
							from intelledox_user a
							left join User_Group_Subscription c on a.User_Guid = c.UserGuid
							left join user_group b on c.groupguid = b.group_guid
							where c.UserGuid = @user_guid)
						)
			)
			order by [RunDate] desc;
		else
			select	ans.AnswerFile_Id, ans.User_Guid, ans.Template_Group_Guid, ans.Description, 
					ans.RunDate, ans.InProgress, ans.AnswerFile_Guid,
					Template_Group.Name as TemplateGroup_Name
			from	answer_file ans					
					INNER JOIN Template_Group on ans.Template_Group_Guid = Template_Group.Template_Group_Guid
					INNER JOIN Template AS T ON Template_Group.Template_Guid = T.Template_Guid
			where	Ans.[user_Guid] = @user_Guid
					AND Ans.Template_group_Guid = @TemplateGroupGuid
			order by [RunDate] desc;
    end
    else
    begin
        SELECT	Answer_File.*
		FROM	Answer_File
        WHERE	Answer_File.AnswerFile_Id = @AnswerFile_Id
        ORDER BY Answer_File.[RunDate] desc;
    end
GO

--2068
ALTER procedure [dbo].[spProjectGrp_ProjectGroupListByFolder]
	@FolderGuid uniqueidentifier,
	@IncludeRestricted bit
AS
	SELECT	d.Template_Group_ID, b.Name as Template_Group_Name, 
			d.HelpText as TemplateGroup_HelpText, d.Template_Group_Guid,
			b.Template_Guid, d.Layout_Guid
	FROM	Folder a
			INNER JOIN Template_Group d on a.folder_Guid = d.Folder_Guid
			INNER JOIN Template b on d.Template_Guid = b.Template_Guid
	WHERE	a.Folder_Guid = @FolderGuid
			AND ((d.EnforcePublishPeriod = 0 OR @IncludeRestricted = 1)
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getdate())))
	ORDER BY b.[Name], d.Template_Group_ID;
GO


--2069
ALTER TABLE [dbo].[Template_Version]
ADD Comment nvarchar(max) NULL
GO

--2070
ALTER TABLE [dbo].[Template]
ADD Comment nvarchar(max) NULL
GO

ALTER TABLE [dbo].[Template]
ADD LockedByUserGuid uniqueidentifier NULL
GO

--2071
ALTER VIEW [dbo].[vwTemplateVersion]
AS
		SELECT	Template_Version.Template_Version, 
			Template_Version.Template_Guid,
			Template_Version.Modified_Date,
			Template_Version.Comment,
			Template.Template_Type_ID,
			Template.LockedByUserGuid,
			Intelledox_User.Username,
			CASE WHEN Template_Group.Template_Group_ID IS NULL
				THEN 0
				ELSE 1
			END AS InUse,
			0 AS Latest
		FROM	Template_Version
			INNER JOIN Template ON Template_Version.Template_Guid = Template.Template_Guid
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template_Version.Modified_By
			LEFT JOIN Template_Group ON (Template_Group.Template_Guid = Template_Version.Template_Guid
					AND Template_Group.Template_Version = Template_Version.Template_Version)
				OR (Template_Group.Layout_Guid = Template_Version.Template_Guid
					AND Template_Group.Layout_Version = Template_Version.Template_Version)
	UNION ALL
		SELECT	Template.Template_Version, 
			Template.Template_Guid,
			Template.Modified_Date,
			Template.Comment,
			Template.Template_Type_ID,
			Template.LockedByUserGuid,
			Intelledox_User.Username,
			CASE WHEN Template_Group.Template_Group_ID IS NULL
				THEN 0
				ELSE 1
			END AS InUse,
			1 AS Latest
		FROM	Template
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By
			LEFT JOIN Template_Group ON (Template_Group.Template_Guid = Template.Template_Guid
					AND (Template_Group.Template_Version = Template.Template_Version OR ISNULL(Template_Group.Template_Version, 0) = 0))
				OR (Template_Group.Layout_Guid = Template.Template_Guid
					AND (Template_Group.Layout_Version = Template.Template_Version OR ISNULL(Template_Group.Layout_Version, 0) = 0))

GO

--2072
ALTER procedure [dbo].[spProject_GetProjectVersions]
	@ProjectGuid uniqueidentifier
as
		SELECT	vwTemplateVersion.Template_Version, 
			vwTemplateVersion.Modified_Date,
			vwTemplateVersion.Username,
			vwTemplateVersion.Comment,
			vwTemplateVersion.LockedByUserGuid,
			vwTemplateVersion.InUse
		FROM	vwTemplateVersion
		WHERE	vwTemplateVersion.Template_Guid = @ProjectGuid
	ORDER BY Template_Version DESC;

GO

--2073
ALTER PROCEDURE [dbo].[spProject_UpdateDefinition] (
	@Xtf xml,
	@TemplateGuid uniqueidentifier,
	@UserGuid uniqueidentifier = NULL
)
AS
	BEGIN TRAN
		IF @UserGuid IS NOT NULL
		BEGIN
			EXEC spProject_AddNewProjectVersion @TemplateGuid;
		END
		
		UPDATE	Template 
		SET		Project_Definition = @XTF 
		WHERE	Template_Guid = @TemplateGuid;
		
		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE Template
			SET Template_Version = Template_Version + 1,
				Comment = NULL,
				Modified_By = @UserGuid,
				Modified_Date = getUTCdate()
			WHERE Template_Guid = @TemplateGuid;
		END
	COMMIT
	
GO

--2074
ALTER procedure [dbo].[spProject_UpdateProject]
	@BusinessUnitGuid uniqueidentifier,
	@Name nvarchar(100),
	@ProjectGuid uniqueidentifier,
	@ProjectTypeID int,
	@SupplierGuid uniqueidentifier,
	@ContentBookmark nvarchar(100),
	@UserGuid uniqueidentifier = NULL
as
	BEGIN TRAN

		IF NOT EXISTS(SELECT Template_Guid FROM Template WHERE Template_Guid = @ProjectGuid)
		BEGIN
			INSERT INTO Template(Business_Unit_Guid, Name, Template_Guid, 
				Template_Type_Id, Supplier_Guid, Content_Bookmark, Template_Version)
			VALUES (@BusinessUnitGuid, @Name, @ProjectGuid, 
				@ProjectTypeId, @SupplierGuid, @ContentBookmark, 0);
		END
		ELSE
		BEGIN
		
			IF @UserGuid IS NOT NULL
			BEGIN
				EXEC spProject_AddNewProjectVersion @ProjectGuid;
			END
		
			UPDATE	Template
			SET		[name] = @Name, 
					Template_type_id = @ProjectTypeID, 
					Supplier_GUID = @SupplierGuid,
					Content_Bookmark = @ContentBookmark
			WHERE	Template_Guid = @ProjectGuid;
		END

		IF @UserGuid IS NOT NULL
		BEGIN
			UPDATE Template
			SET Modified_Date = getUTCdate(),
				Modified_By = @UserGuid,
				Template_Version = Template_Version + 1,
				Comment = NULL
			WHERE Template_Guid = @ProjectGuid;
		END
	
	COMMIT

GO

--2075
ALTER procedure [dbo].[spProject_AddNewProjectVersion]
	@ProjectGuid uniqueidentifier

AS
	BEGIN TRAN

		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Project_Definition,
			Comment)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,
			Template.Modified_By,
			Template.Project_Definition,
			Template.Comment
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File_Version (Template_Guid, File_Guid, Template_Version, [Binary],
				FormatTypeId)
		SELECT	Template.Template_Guid, Template_File.File_Guid, Template.Template_Version, 
				Template_File.[Binary], Template_File.FormatTypeId
		FROM	Template
				INNER JOIN Template_File ON Template.Template_Guid = Template_File.Template_Guid
		WHERE	Template.Template_Guid = @ProjectGuid;
		
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
				
		DELETE FROM Template_File_Version
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	Template_Version
					WHERE	Template_Guid = @ProjectGuid);
	COMMIT
	
GO

--2076
CREATE PROCEDURE [dbo].[spProject_TryLockProject]
	@ProjectGuid uniqueidentifier,
	@UserGuid uniqueidentifier
	
AS

	BEGIN TRAN

		IF EXISTS(SELECT 1 FROM Template WHERE Template_Guid = @ProjectGuid AND LockedByUserGuid IS NULL)
		BEGIN
			UPDATE	Template
			SET		LockedByUserGuid = @UserGuid
			WHERE	Template_Guid = @ProjectGuid;
			
			SELECT ''				
		END
		ELSE
		BEGIN
			SELECT	Username 
			FROM	Intelledox_User 
					INNER JOIN Template ON Intelledox_User.User_Guid = Template.LockedByUserGuid
			WHERE	Template_Guid = @ProjectGuid						
		END

	COMMIT
	
GO

--2077
CREATE PROCEDURE [dbo].[spProject_UnlockProject]
	@ProjectGuid uniqueidentifier,
	@VersionComment text = '',
	@UserGuid uniqueidentifier,
	@ForceUnlock bit
AS

	BEGIN TRAN
	
		--allows unlock either by any user if its a force unlock OR by the same user who has currently locked the project if general unlock
		IF @ForceUnlock = 1 OR (@ForceUnlock = 0 AND EXISTS(SELECT LockedByUserGuid FROM Template WHERE Template_Guid = @ProjectGuid AND LockedByUserGuid = @UserGuid))
		BEGIN
			IF EXISTS(SELECT Comment FROM Template WHERE Template_Guid = @ProjectGuid AND LEN(Comment) > 0)
			BEGIN
				UPDATE	Template
				SET		LockedByUserGuid = NULL
				WHERE	Template_Guid = @ProjectGuid;
			END
			ELSE
			BEGIN
				UPDATE	Template
				SET		LockedByUserGuid = NULL,
						Comment = @VersionComment
				WHERE	Template_Guid = @ProjectGuid;
			END
		END

	COMMIT
	
GO

--2078
ALTER procedure [dbo].[spTemplate_TemplateList]
	@TemplateID int = 0,
	@TemplateGuid uniqueidentifier = null,
	@ErrorCode int output
AS
	SET NOCOUNT ON
	
	If @TemplateGuid IS NOT NULL
	BEGIN
		SELECT	@TemplateId = Template_Id
		FROM	Template
		WHERE	Template_Guid = @TemplateGuid;
	END

	IF @TemplateID = 0 
		SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, b.Category_ID, 
				b.[Name] as Category_Name, a.Supplier_Guid, a.Business_Unit_Guid,
				a.Content_Bookmark, a.HelpText, a.Modified_Date, Intelledox_User.Username, 
				a.[name] as Project_Name, a.Modified_By, lockedByUser.Username AS LockedBy, a.Comment
		FROM	Template a 
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		ORDER BY a.[Name];
	ELSE
		SELECT	a.template_id, a.[name] as template_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, b.Category_ID, 
				b.[Name] as Category_Name, a.Supplier_Guid, a.Business_Unit_Guid,
				a.Content_Bookmark, a.HelpText, a.Modified_Date, Intelledox_User.Username,
				a.[name] as Project_Name, a.Modified_By, lockedByUser.Username AS LockedBy, a.Comment
		FROM	Template a
				left join Template_Category c on a.Template_ID = c.Template_ID
				left join Category b on c.Category_ID = b.Category_ID
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		WHERE	a.template_id = @TemplateID
		ORDER BY a.[Name];

	set @ErrorCode = @@error;
	
GO

--2079
ALTER procedure [dbo].[spProject_RestoreVersion]
	@ProjectGuid uniqueidentifier,
	@VersionNumber int,
	@UserGuid uniqueidentifier,
	@RestoreVersionComment nvarchar(50)
as
	SET NOCOUNT ON
		
	BEGIN TRAN	
	
		INSERT INTO Template_Version 
			(Template_Version, 
			Template_Guid, 
			Modified_Date, 
			Modified_By,
			Project_Definition,
			Comment)
		SELECT Template.Template_Version,
			Template.Template_Guid,
			Template.Modified_Date,
			Template.Modified_By,
			Template.Project_Definition,
			Template.Comment
		FROM Template
		WHERE Template.Template_Guid = @ProjectGuid;
			
		UPDATE Template
		SET	Project_Definition = (SELECT Project_Definition
				FROM Template_Version 
				WHERE Template_Guid = @ProjectGuid 
					AND Template_Version = @VersionNumber), 
			Template_Version = Template_Version + 1, 
			Comment = @RestoreVersionComment,
			Modified_Date = GetUTCdate(),
			Modified_By = @UserGuid
		WHERE	Template_Guid = @ProjectGuid;
		
		DELETE FROM Template_File
		WHERE	Template_Guid = @ProjectGuid;
		
		INSERT INTO Template_File(Template_Guid, File_Guid, [Binary], FormatTypeId)
		SELECT	@ProjectGuid, Template_File_Version.File_Guid, Template_File_Version.[Binary],
				Template_File_Version.FormatTypeId
		FROM	Template_File_Version 
		WHERE	Template_Guid = @ProjectGuid 
				AND Template_Version = @VersionNumber; 
				
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

--2080
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
				a.Content_Bookmark, a.Modified_By, lockedByUser.Username AS LockedBy
		FROM	Template a
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
			LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		WHERE	(@IsGlobal = 1 or a.Template_Guid in (
				SELECT	User_Group_Template.TemplateGuid
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid
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
				a.Content_Bookmark, a.Modified_By, lockedByUser.Username AS LockedBy
		FROM	Template a
				INNER JOIN User_Group_Template d on a.Template_Guid = d.TemplateGuid
				INNER JOIN User_Group ON d.GroupGuid = User_Group.Group_Guid AND User_Group.Group_Guid = @GroupGuid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		WHERE	(@IsGlobal = 1 or a.template_Guid in (
				SELECT	User_Group_Template.TemplateGuid
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid
				WHERE	((@Purpose = 'Design' AND vwUserPermissions.CanDesignProjects = 1)
					OR (@Purpose = 'Publish' AND vwUserPermissions.CanPublishProjects = 1))
			))
			and (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
		ORDER BY a.[name];
	end
	
GO

--2081
ALTER procedure [dbo].[spProject_ProjectListFullText]
	@UserGuid uniqueidentifier,
	@GroupGuid uniqueidentifier,
	@ProjectTypeId int,
	@SearchString nvarchar(100),
	@FullText NVarChar(1000)
as
	declare @IsGlobal bit
	declare @BusinessUnitGUID uniqueidentifier

	SELECT	@BusinessUnitGUID = Business_Unit_GUID
	FROM	Intelledox_User
	WHERE	User_Guid = @UserGuid;

	IF EXISTS(SELECT	vwUserPermissions.*
		FROM	vwUserPermissions
		WHERE	vwUserPermissions.CanDesignProjects = 1
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
				a.Content_Bookmark, a.Modified_By, lockedByUser.Username AS LockedBy
		FROM	Template a
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		WHERE	(@IsGlobal = 1 or a.template_Guid in (
				SELECT	User_Group_Template.TemplateGuid
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid 
				WHERE	vwUserPermissions.CanDesignProjects = 1
			AND Intelledox_User.User_Guid = @UserGuid
				))
			AND (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
			AND (a.Template_Guid IN (
					SELECT	Template_Guid
					FROM	Template_File tf
					WHERE	Contains(*, @FullText)
				))
		ORDER BY a.[name];
	end
	else
	begin
		--specific user group
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, a.fax_template_id, 
				a.template_guid, a.template_version, a.import_date, 
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Content_Bookmark, a.Modified_By, lockedByUser.Username AS LockedBy
		FROM	Template a
				INNER JOIN User_Group_Template d on a.Template_Guid = d.TemplateGuid
				INNER JOIN User_Group ON d.GroupGuid = User_Group.Group_Guid  AND User_Group.Group_Guid = @GroupGuid
				LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
				LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		WHERE	(@IsGlobal = 1 or a.template_Guid in (
				SELECT	User_Group_Template.TemplateGuid
				FROM	vwUserPermissions
						INNER JOIN Intelledox_User ON vwUserPermissions.UserGuid = Intelledox_User.User_Guid
						INNER JOIN User_Group_Subscription ON Intelledox_User.User_Guid = User_Group_Subscription.UserGuid
						INNER JOIN User_Group ON vwUserPermissions.GroupGuid = User_Group.Group_Guid
						INNER JOIN User_Group_Template ON User_Group_Subscription.GroupGuid = User_Group_Template.GroupGuid 
				WHERE	vwUserPermissions.CanDesignProjects = 1
			))
			and (a.Business_Unit_GUID = @BusinessUnitGUID) 
			AND a.Name LIKE @SearchString + '%'
			AND (a.Template_Type_Id = @ProjectTypeId OR @ProjectTypeId = 0)
			AND (a.Template_Guid IN (
					SELECT	Template_Guid
					FROM	Template_File tf
					WHERE	Contains(*, @FullText)
				))
		ORDER BY a.[name];
	end
	
GO

