/*
** Database Update package 6.1.11
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.1.11')
go

--1899
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
		IF @PackageRunId = 0 -- Only insert projects which aren't part of a package
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
	END
GO


--1901
CREATE PROCEDURE [dbo].[spReport_ResultsCSV]
	@TemplateId Int,
	@StartDate datetime,
	@FinishDate datetime
AS
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


