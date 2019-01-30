/*
** Database Update package 7.1.4
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.1.4')
go

--1968
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

	INSERT INTO #Answers(AnswerGuid, AnswerName, Label, QuestionName, QuestionTypeId, PageName)
	SELECT	A.value('@Guid', 'uniqueidentifier'), 
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
			COUNT(*) as TotalQuestionResponses,
			(SELECT COUNT(DISTINCT #Responses.LogGuid) FROM #Responses) as TotalResponses,
			CASE WHEN #Answers.QuestionTypeId = 7 THEN #Responses.Value ELSE '' END as TextResponse
	FROM	#Answers
			LEFT JOIN #Responses ON #Answers.AnswerGuid = #Responses.AnswerGuid
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


--1969
ALTER PROCEDURE [dbo].[spReport_ResultsCSV]
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
			CROSS APPLY ProjectXML.P.nodes('(Question)') as QuestionXML(Q)
			CROSS APPLY QuestionXML.Q.nodes('(Answer)') as AnswerXml(A)
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
				SELECT	Template_Group_Id
				FROM	Template_Group_Item
				WHERE	Template_Id = @TemplateId
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


