truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.0.0.7');
go
ALTER PROCEDURE [dbo].[spProject_TryLockProject]
	@ProjectGuid uniqueidentifier,
	@UserGuid uniqueidentifier
AS
	BEGIN TRAN
	
		--check for a deleted project
		IF NOT EXISTS(SELECT 1 FROM Template WHERE Template_Guid = @ProjectGuid) 
			SELECT '' as Username;
		ELSE
		BEGIN
			IF EXISTS(SELECT 1 FROM Template WHERE (Template.LockedByUserGuid IS NULL OR Template.LockedByUserGuid = @UserGuid) AND Template_Guid = @ProjectGuid)
			BEGIN
				UPDATE	Template
				SET		LockedByUserGuid = @UserGuid
				WHERE	Template_Guid = @ProjectGuid;
				
				SELECT '' as Username;		
			END
			ELSE
			BEGIN
				SELECT	Username 
				FROM	Intelledox_User 
						INNER JOIN Template ON Intelledox_User.User_Guid = Template.LockedByUserGuid
				WHERE	Template_Guid = @ProjectGuid						
			END
		END

	COMMIT
GO
ALTER PROCEDURE [dbo].[spProject_UpdateDefinition] (
	@Xtf xml,
	@TemplateGuid uniqueidentifier,
	@EncryptedXtf varbinary(MAX)
)
AS
	SET ARITHABORT ON

	DECLARE @ExistingFeatureFlags int;
	DECLARE @FeatureFlags int;
	DECLARE @DataObjectGuid uniqueidentifier;
	DECLARE @XtfVersion nvarchar(10)

	BEGIN TRAN
		-- Feature detection --
		SET @FeatureFlags = 0
		SELECT @XtfVersion = Template.Template_Version, @ExistingFeatureFlags = ISNULL(Template.FeatureFlags, 0) FROM Template WHERE Template.Template_Guid = @TemplateGuid;

		-- Workflow
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/Workflow/State/Transition)') as ProjectXML(P))
		BEGIN
			--Looking for a specified transition from the start state
			IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/Workflow/State)') as StateXML(S)
					  CROSS APPLY S.nodes('(Transition)') as TransitionXML(T)
					  WHERE S.value('@ID', 'uniqueidentifier') = cast('11111111-1111-1111-1111-111111111111' as uniqueidentifier)
					  AND (T.value('@SendToType', 'int') = 0 or T.value('@SendToType', 'int') IS NULL))
			BEGIN
				SET @FeatureFlags = @FeatureFlags | 256;
			END
			ELSE
			BEGIN
				SET @FeatureFlags = @FeatureFlags | 1;
			END
		END

		-- Data source
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 2		-- Data field
						OR Q.value('@TypeId', 'int') = 9	-- Data table
						OR Q.value('@TypeId', 'int') = 12	-- Data list
						OR Q.value('@TypeId', 'int') = 14)	-- Data source
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 2;

			INSERT INTO Xtf_Datasource_Dependency(Template_Guid, Template_Version, Data_Object_Guid)
			SELECT DISTINCT @TemplateGuid,
					@XtfVersion,
					Q.value('@DataObjectGuid', 'uniqueidentifier')
			FROM 
				@Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question)') as QuestionXML(Q)
			WHERE Q.value('@DataObjectGuid', 'uniqueidentifier') is not null
				AND Q.value('@DataServiceGuid', 'uniqueidentifier') <> '6a4af944-0563-4c95-aba1-ddf2da4337b1'
				AND (SELECT  COUNT(*)
				FROM    Xtf_Datasource_Dependency 
				WHERE   Template_Guid = @TemplateGuid
				AND     Template_Version = @XtfVersion 
				AND		Data_Object_Guid = Q.value('@DataObjectGuid', 'uniqueidentifier')) = 0
			
		END

		-- Content library
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 11
						AND Q.value('@DisplayType', 'int') = 8) -- Existing content item
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 4;
		END
		
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 11
						AND Q.value('@DisplayType', 'int') = 4) -- Search
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 8;
		END

		IF EXISTS(SELECT 1 FROM Xtf_ContentLibrary_Dependency
			WHERE	Xtf_ContentLibrary_Dependency.Template_Guid = @TemplateGuid AND
					Xtf_ContentLibrary_Dependency.Template_Version = @XtfVersion)
		BEGIN
			DELETE FROM Xtf_ContentLibrary_Dependency
			WHERE	Xtf_ContentLibrary_Dependency.Template_Guid = @TemplateGuid AND
					Xtf_ContentLibrary_Dependency.Template_Version = @XtfVersion;
		END

		INSERT INTO Xtf_ContentLibrary_Dependency(Template_Guid, Template_Version, Content_Object_Guid)
		SELECT DISTINCT @TemplateGuid, @XtfVersion, Content_Object_Guid
		FROM (
			SELECT C.value('@Id', 'uniqueidentifier') as Content_Object_Guid
			FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question/Answer/ContentItem)') as ContentItemXML(C)
			UNION
			SELECT Q.value('@ContentItemGuid', 'uniqueidentifier')
			FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question)') as QuestionXML(Q)
			WHERE Q.value('@ContentItemGuid', 'uniqueidentifier') is not null) Content

		-- Address
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 1)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 16;
		END

		-- Rich text
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 19)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 64;
		END
			
		-- Custom Question
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 22)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 128;
		END

		-- Fragments
		IF EXISTS(SELECT 1 FROM Xtf_Fragment_Dependency
					WHERE	Xtf_Fragment_Dependency.Template_Guid = @TemplateGuid AND
							Xtf_Fragment_Dependency.Template_Version = @XtfVersion)
		BEGIN
			DELETE FROM Xtf_Fragment_Dependency
			WHERE	Xtf_Fragment_Dependency.Template_Guid = @TemplateGuid AND
					Xtf_Fragment_Dependency.Template_Version = @XtfVersion;
		END
		
		INSERT INTO Xtf_Fragment_Dependency(Template_Guid, Template_Version, Fragment_Guid)
		SELECT DISTINCT @TemplateGuid, @XtfVersion, Fragment_Guid
		FROM (
			SELECT fp.value('@ProjectGuid', 'uniqueidentifier') as Fragment_Guid
			FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as PageFragmentXML(fp)
			WHERE fp.value('@ProjectGuid', 'uniqueidentifier') IS NOT NULL
			UNION
			SELECT fn.value('@ProjectGuid', 'uniqueidentifier')
			FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Layout//Fragment)') as NodeFragmentXML(fn)
			WHERE fn.value('@ProjectGuid', 'uniqueidentifier') IS NOT NULL) Fragments

		IF EXISTS(SELECT 1 FROM Xtf_Fragment_Dependency WHERE Template_Guid = @TemplateGuid AND Template_Version = @XtfVersion)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 512;
		END

		IF @EncryptedXtf IS NULL
		BEGIN
			UPDATE	Template 
			SET		Project_Definition = @XTF,
					FeatureFlags = @FeatureFlags,
					EncryptedProjectDefinition = NULL
			WHERE	Template_Guid = @TemplateGuid;
		END
		ELSE
		BEGIN
			UPDATE	Template 
			SET		EncryptedProjectDefinition = @EncryptedXtf,
					FeatureFlags = @FeatureFlags,
					Project_Definition = NULL
			WHERE	Template_Guid = @TemplateGuid;
		END

		-- Updating project group feature flags is expensive, only do it if our flags have changed
		-- or we contain project fragments (could have been added or removed)
		IF @ExistingFeatureFlags <> @FeatureFlags OR (@FeatureFlags & 512) = 512
		BEGIN
			EXEC spProjectGroup_UpdateFeatureFlags @ProjectGuid=@TemplateGuid;
		END
	COMMIT
GO
ALTER PROCEDURE [dbo].[spProjectGroup_UpdateFeatureFlags]
	@ProjectGroupGuid uniqueidentifier = null,
	@ProjectGuid uniqueidentifier = null
AS
	DECLARE @ProjectGroupsAffected TABLE 
	(
		Template_Group_Guid uniqueidentifier,
		Content_Guid uniqueidentifier,
		Layout_Guid uniqueidentifier
	)

	IF (@ProjectGuid is NULL)
	BEGIN
		-- Update a single group
		INSERT INTO @ProjectGroupsAffected(Template_Group_Guid, Content_Guid, Layout_Guid)
		SELECT @ProjectGroupGuid, Template_Guid, Layout_Guid
		FROM	Template_Group
		WHERE	Template_Group_Guid = @ProjectGroupGuid;
	END
	ELSE
	BEGIN
		-- Update groups using a project
		WITH ParentFragments (Template_Guid)
		AS
		(
			-- Anchor member definition
			SELECT	p.Template_Guid
			FROM	Xtf_Fragment_Dependency fd
					INNER JOIN Template p ON fd.Template_Guid = p.Template_Guid AND fd.Template_Version = p.Template_Version
			WHERE	fd.Fragment_Guid = @ProjectGuid
			UNION ALL
			-- Recursive member definition
			SELECT fd2.Template_Guid
			FROM Xtf_Fragment_Dependency fd2
				INNER JOIN Template p2 ON fd2.Template_Guid = p2.Template_Guid AND fd2.Template_Version = p2.Template_Version
				INNER JOIN ParentFragments AS fp ON fd2.Fragment_Guid = fp.Template_Guid
		)
		INSERT INTO @ProjectGroupsAffected(Template_Group_Guid, Content_Guid, Layout_Guid)
		SELECT DISTINCT Template_Group.Template_Group_Guid, Template_Group.Template_Guid as Content_Guid, Template_Group.Layout_Guid
		FROM ParentFragments
			INNER JOIN Template_Group ON ParentFragments.Template_Guid = Template_Group.Template_Guid
				OR ParentFragments.Template_Guid = Template_Group.Layout_Guid

		--Select parent content project guid
		INSERT INTO @ProjectGroupsAffected(Template_Group_Guid, Content_Guid, Layout_Guid)
		SELECT Template_Group_Guid, Template_Guid, Layout_Guid
		FROM	Template_Group
		WHERE	(Template_Guid = @ProjectGuid OR Layout_Guid = @ProjectGuid) AND
				Template_Group_Guid NOT IN (SELECT Template_Group_Guid FROM @ProjectGroupsAffected);

	END

	DECLARE @FeatureFlag int;
	DECLARE @Content_Guid uniqueidentifier
	DECLARE @Layout_Guid uniqueidentifier
	DECLARE @Project_Version nvarchar(10)
	DECLARE PgCursor CURSOR
		FOR	SELECT	Template_Group_Guid, Content_Guid, Layout_Guid
			FROM	@ProjectGroupsAffected;

	OPEN PgCursor;
	FETCH NEXT FROM PgCursor INTO @ProjectGroupGuid, @Content_Guid, @Layout_Guid;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Content
		SET @FeatureFlag = (SELECT	Template.FeatureFlags
					FROM	Template_Group
							INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid 
									AND (Template_Group.Template_Version IS NULL
										OR Template_Group.Template_Version = Template.Template_Version)
					WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid
					UNION ALL
					SELECT	Template_Version.FeatureFlags
					FROM	Template_Group
							INNER JOIN Template_Version ON (Template_Group.Template_Guid = Template_Version.Template_Guid 
									AND Template_Group.Template_Version = Template_Version.Template_Version)
					WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid)

		SET @Project_Version = (SELECT	Template.Template_Version
					FROM	Template_Group
							INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid 
									AND (Template_Group.Template_Version IS NULL
										OR Template_Group.Template_Version = Template.Template_Version)
					WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid
					UNION ALL
					SELECT	Template_Version.Template_Version
					FROM	Template_Group
							INNER JOIN Template_Version ON (Template_Group.Template_Guid = Template_Version.Template_Guid 
									AND Template_Group.Template_Version = Template_Version.Template_Version)
					WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid)

		-- Content Project Fragments
		DECLARE FragCursor CURSOR
			FOR	WITH ChildFragments (Template_Guid)
				AS
				(
					-- Anchor member definition
					SELECT	t.Fragment_Guid
					FROM	Xtf_Fragment_Dependency t
					WHERE	t.Template_Guid = @Content_Guid AND
							t.Template_Version = @Project_Version
					UNION ALL
					-- Recursive member definition
					SELECT t.Fragment_Guid
					FROM Xtf_Fragment_Dependency t
						INNER JOIN ChildFragments AS p ON t.Template_Guid = p.Template_Guid
						INNER JOIN Template ON t.Template_Version = Template.Template_Version AND t.Template_Guid = Template.Template_Guid
				)
				SELECT Template_Guid
				FROM ChildFragments;

		OPEN FragCursor;
		FETCH NEXT FROM FragCursor INTO @ProjectGuid;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @FeatureFlag = @FeatureFlag | ISNULL((SELECT FeatureFlags
				FROM Template
				WHERE Template_Guid = @ProjectGuid), 0);

			FETCH NEXT FROM FragCursor INTO @ProjectGuid;
		END
		
		CLOSE FragCursor;
		DEALLOCATE FragCursor;

		-- Layout
		IF @Layout_Guid IS NOT NULL
		BEGIN
			SET @FeatureFlag = @FeatureFlag | ISNULL((SELECT Template.FeatureFlags
					FROM	Template_Group
							INNER JOIN Template ON Template_Group.Layout_Guid = Template.Template_Guid
									AND (Template_Group.Layout_Version IS NULL
										OR Template_Group.Layout_Version = Template.Template_Version)
					WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid
					UNION ALL
					SELECT	Template_Version.FeatureFlags
					FROM	Template_Group
							INNER JOIN Template_Version ON Template_Group.Layout_Guid = Template_Version.Template_Guid
									AND Template_Group.Layout_Version = Template_Version.Template_Version
					WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid), 0)

			SET @Project_Version =(SELECT Template.Template_Version
					FROM	Template_Group
							INNER JOIN Template ON Template_Group.Layout_Guid = Template.Template_Guid
									AND (Template_Group.Layout_Version IS NULL
										OR Template_Group.Layout_Version = Template.Template_Version)
					WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid
					UNION ALL
					SELECT	Template_Version.Template_Version
					FROM	Template_Group
							INNER JOIN Template_Version ON Template_Group.Layout_Guid = Template_Version.Template_Guid
									AND Template_Group.Layout_Version = Template_Version.Template_Version
					WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid)

			-- Layout Project fragments
			DECLARE LayoutFragCursor CURSOR
				FOR	WITH ChildFragments (Template_Guid)
					AS
					(
						-- Anchor member definition
						SELECT	t.Fragment_Guid
						FROM	Xtf_Fragment_Dependency t
						WHERE	t.Template_Guid = @Layout_Guid AND
							    t.Template_Version = @Project_Version
						UNION ALL
						-- Recursive member definition
						SELECT t.Fragment_Guid
						FROM Xtf_Fragment_Dependency t
							INNER JOIN ChildFragments AS p ON t.Template_Guid = p.Template_Guid
							INNER JOIN Template ON t.Template_Version = Template.Template_Version AND t.Template_Guid = Template.Template_Guid
					)
					SELECT Template_Guid
					FROM ChildFragments;

			OPEN LayoutFragCursor;
			FETCH NEXT FROM LayoutFragCursor INTO @ProjectGuid;
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @FeatureFlag = @FeatureFlag | ISNULL((SELECT FeatureFlags
					FROM Template
					WHERE Template_Guid = @ProjectGuid), 0);

				FETCH NEXT FROM LayoutFragCursor INTO @ProjectGuid;
			END
		
			CLOSE LayoutFragCursor;
			DEALLOCATE LayoutFragCursor;
		END

		UPDATE	Template_Group
		SET		Template_Group.FeatureFlags = @FeatureFlag
		WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid;
		
		FETCH NEXT FROM PgCursor INTO @ProjectGroupGuid, @Content_Guid, @Layout_Guid;
	END

	CLOSE PgCursor;
	DEALLOCATE PgCursor;

GO
ALTER VIEW [dbo].[vwProjectDetails]
AS
SELECT  t.Template_ID, t.Name, t.Template_Type_ID, t.Template_Guid, t.Template_Version, t.HelpText, 
        t.Business_Unit_GUID, t.Modified_Date, t.Modified_By, t.Comment, t.LockedByUserGuid, t.FeatureFlags, 
        t.IsMajorVersion, tg.Template_Group_ID, tg.Template_Group_Guid, tg.HelpText AS GroupHelpText, tg.AllowPreview, tg.PostGenerateText, 
        tg.UpdateDocumentFields, tg.EnforceValidation, tg.WizardFinishText, tg.EnforcePublishPeriod, tg.PublishStartDate, tg.PublishFinishDate, 
        tg.HideNavigationPane, tg.Layout_Guid, tg.Layout_Version, tg.Folder_Guid
FROM    dbo.Template AS t INNER JOIN
        dbo.Template_Group AS tg ON tg.Template_Guid = t.Template_Guid

GO
ALTER PROCEDURE [dbo].[spProject_DeleteOldProjectVersion]
	@ProjectGuid uniqueidentifier,
	@NextVersion nvarchar(10),
	@BusinessUnitGuid uniqueidentifier
AS
BEGIN

	IF (SELECT COUNT(*) 
		FROM Template_Group 
		WHERE (Template_Group.Layout_Guid = @ProjectGuid OR Template_Group.Template_Guid = @ProjectGuid)
			AND Template_Group.MatchProjectVersion = 1) = 0
	BEGIN
	
		--delete the earliest minor version which does not belong to the next version number
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
						AND (FLOOR(vwTemplateVersion.Template_Version) < FLOOR(@NextVersion))) > 0)
		BEGIN

			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version 
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
						AND (FLOOR(vwTemplateVersion.Template_Version) < FLOOR(@NextVersion))
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END
			
		--otherwise	
		--delete earliest major version, leaving at least one major version untouched			
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 1) > 1)
		BEGIN

			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 1
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END

		--otherwise
		--delete the earliest left minor version
		WHILE ((SELECT COUNT(*) FROM Template_Version WHERE Template_Guid = @ProjectGuid) > 
			(SELECT OptionValue FROM Global_Options WHERE OptionCode = 'MAX_VERSIONS' AND BusinessUnitGuid = @BusinessUnitGuid) - 1)
				AND ((SELECT COUNT(*)
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0) > 0)
		BEGIN
			DELETE FROM Template_Version
			WHERE Template_Version = 
					(SELECT TOP 1 Template_Version
					FROM vwTemplateVersion 
					WHERE Template_Guid = @ProjectGuid
						AND vwTemplateVersion.InUse = 0
						AND vwTemplateVersion.Latest = 0
						AND vwTemplateVersion.IsMajorVersion = 0
					ORDER BY Modified_Date ASC)
				AND Template_Guid = @ProjectGuid;
		END

		DELETE FROM Xtf_Datasource_Dependency
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	Template_Version
					WHERE	Template_Guid = @ProjectGuid);

		DELETE FROM Xtf_ContentLibrary_Dependency
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	Template_Version
					WHERE	Template_Guid = @ProjectGuid);

		DELETE FROM Xtf_Fragment_Dependency
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	Template_Version
					WHERE	Template_Guid = @ProjectGuid);
				
		DELETE FROM Template_File_Version
		WHERE	Template_Guid = @ProjectGuid
				AND Template_Version NOT IN (
					SELECT	Template_Version
					FROM	Template_Version
					WHERE	Template_Guid = @ProjectGuid);
	END
END
GO
DELETE Xtf_Fragment_Dependency
FROM Xtf_Fragment_Dependency
	LEFT JOIN vwTemplateVersion ON Xtf_Fragment_Dependency.Template_Guid = vwTemplateVersion.Template_Guid AND Xtf_Fragment_Dependency.Template_Version = vwTemplateVersion.Template_Version
WHERE	vwTemplateVersion.Template_Guid IS NULL;
GO
ALTER procedure [dbo].[spTemplate_RemoveTemplate]
	@TemplateGuid uniqueidentifier,
	@OnlyChildInfo bit
as
	IF @OnlyChildInfo = 0
	BEGIN
		DELETE	template_Group
		WHERE	template_guid = @TemplateGuid
			OR	layout_guid = @TemplateGuid;

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

	DELETE  Xtf_Datasource_Dependency
	WHERE	Template_Guid = @TemplateGuid;

	DELETE  Xtf_ContentLibrary_Dependency
	WHERE	Template_Guid = @TemplateGuid;

	DELETE FROM Xtf_Fragment_Dependency
	WHERE	Template_Guid = @TemplateGuid;
GO

DROP procedure [dbo].[spDataSource_ProjectAnswers]
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
		QuestionId int,
		AnswerId int
	);

	CREATE TABLE #Responses
	(
		LogGuid uniqueidentifier,
		AnswerGuid uniqueidentifier,
		Value nvarchar(1000),
		StartDate datetime,
		FinishDate datetime,
		UserId int,
		RepeatGuids nvarchar(1000),
		RepeatIndexes nvarchar(1000)
	);
	
	-- Finish date inclusive
	SET @FinishDate = DateAdd(d, 1, @FinishDate);

	INSERT INTO #Answers(AnswerGuid, AnswerName, Label, QuestionName, QuestionTypeId, PageName, QuestionID, AnswerID)
	SELECT	CASE WHEN Q.value('@TypeId', 'int') = 14 -- Fudge for Datasource questions, which won't necessarily have a saved answer node
				THEN Q.value('@Guid', 'uniqueidentifier')
				ELSE A.value('@Guid', 'uniqueidentifier')
				END, 
			A.value('@Name', 'nvarchar(1000)'),
			A.value('@AnswerFileLabel', 'nvarchar(100)'),
			Q.value('@Text', 'nvarchar(1000)'),
			Q.value('@TypeId', 'int'),
			P.value('@Name', 'nvarchar(1000)'),
			Q.value('@ID', 'int'),
			A.value('@ID', 'int')
	FROM	Template
			CROSS APPLY Project_Definition.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
			CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
			CROSS APPLY Q.nodes('(Answer)') as AnswerXml(A)
	WHERE	Template.Template_Id = @TemplateId
		AND ((Q.value('@TypeId', 'int') = 3)
			OR Q.value('@TypeId', 'int') = 6
			OR Q.value('@TypeId', 'int') = 7
			OR (Q.value('@TypeId', 'int') = 14 AND Q.value('@SelectionType', 'int') IS NULL)
			OR Q.value('@TypeId', 'int') = 19		
			OR Q.value('@TypeId', 'int') = 24);
	
	INSERT INTO #Responses(LogGuid, AnswerGuid, Value, StartDate, FinishDate, UserId, RepeatGuids, RepeatIndexes)
	-- Normal Answers
	SELECT	Template_Log.Log_Guid,
			#Answers.AnswerGuid, 
			C.value('@v', 'nvarchar(1000)'),
			Template_Log.DateTime_Start,
			Template_Log.DateTime_Finish,
			Template_Log.User_Id,
			'',
			''
	FROM	Template_Log 
			CROSS APPLY Answer_File.nodes('(/AnswerFile/ps/p/qs/q/as/a)') as ID(C)
			, #Answers
	WHERE	C.value('@aid', 'uniqueidentifier') = #Answers.AnswerGuid
			AND Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
			AND (#Answers.QuestionTypeId = 3		-- Group logic
				OR #Answers.QuestionTypeId = 6		-- Simple logic
				OR #Answers.QuestionTypeId = 7		-- User prompt	
				OR #Answers.QuestionTypeId = 19		-- Rich Text	
				OR #Answers.QuestionTypeId = 24)	-- Numeric	
			AND Template_Log.Template_Group_Id IN
			(
				SELECT	tg.Template_Group_Id
				FROM	Template_Group tg
						INNER JOIN Template t ON tg.Template_Guid = t.Template_Guid
				WHERE	t.Template_Id = @TemplateId
			)
	UNION ALL
	-- Datasource SelectedValues
	SELECT	Template_Log.Log_Guid,
			#Answers.AnswerGuid, 
			C.value('@SelectedValue', 'nvarchar(1000)'),
			Template_Log.DateTime_Start,
			Template_Log.DateTime_Finish,
			Template_Log.User_Id,
			'',
			''
	FROM	Template_Log 
			CROSS APPLY Answer_File.nodes('(/AnswerFile/ps/p/qs/q)') as ID(C)
			, #Answers
	WHERE	C.value('@qid', 'uniqueidentifier') = #Answers.AnswerGuid -- #Answers.AnswerGuid will actually be the question guid for a data source
			AND Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
			AND #Answers.QuestionTypeId = 14		-- Datasource	
			AND Template_Log.Template_Group_Id IN
			(
				SELECT	tg.Template_Group_Id
				FROM	Template_Group tg
						INNER JOIN Template t ON tg.Template_Guid = t.Template_Guid
				WHERE	t.Template_Id = @TemplateId
			)
	UNION ALL
	-- Label Answers
	SELECT	Template_Log.Log_Guid,
			#Answers.AnswerGuid, 
			ISNULL(C.value('.', 'nvarchar(1000)'), ''),
			Template_Log.DateTime_Start,
			Template_Log.DateTime_Finish,
			Template_Log.User_Id,
			'',
			''
	FROM	Template_Log 
			CROSS APPLY Answer_File.nodes('(/AnswerFile/AnswerLabels/Label[count(Values)=0])') as Label(C)
			, #Answers
	WHERE	C.value('@name', 'nvarchar(100)') = #Answers.Label
			AND Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
			AND (#Answers.QuestionTypeId = 3		-- Group logic
				OR #Answers.QuestionTypeId = 6		-- Simple logic
				OR #Answers.QuestionTypeId = 7		-- User prompt
				OR #Answers.QuestionTypeId = 19		-- Rich Text	
				OR #Answers.QuestionTypeId = 24)	-- Numeric	
			AND Template_Log.Template_Group_Id IN
			(
				SELECT	tg.Template_Group_Id
				FROM	Template_Group tg
						INNER JOIN Template t ON tg.Template_Guid = t.Template_Guid
				WHERE	t.Template_Id = @TemplateId
			)
	UNION ALL
	-- Repeated Answers
	SELECT Log_Guid,
		A.value('@Guid', 'nvarchar(50)') AS AnswerGuid,
		A.value('@Value', 'nvarchar(1000)') AS Value,
		DateTime_Start,
		DateTime_Finish,
		User_Id,
		A.value('@RepeatGuids', 'nvarchar(1000)') AS RepeatGuids,
		A.value('@RepeatIndexes', 'nvarchar(1000)') AS RepeatIndexes
	FROM (SELECT Axml.query(
					'
					for $A in (descendant::a)
					return element a 
					{
						attribute Guid {$A/@aid},
						attribute Value {$A/@v},
						attribute RepeatGuids
						{
							(//repeat[descendant::a[. is $A]]/@guid)
						},
						attribute RepeatIndexes
						{
							(//qs[descendant::a[. is $A]]/@i)
						}
					}
					') AS AnswerInfo,
				Template_Log.Log_Guid,
				Template_Log.DateTime_Start,
				Template_Log.DateTime_Finish,
				Template_Log.User_Id
		FROM	Template_Log 
				CROSS APPLY Answer_File.nodes('(/AnswerFile/ps)') as AnswerXml(Axml)
		WHERE	Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
				AND Template_Log.Template_Group_Id IN
				(
					SELECT	tg.Template_Group_Id
					FROM	Template_Group tg
							INNER JOIN Template t ON tg.Template_Guid = t.Template_Guid
					WHERE	t.Template_Id = @TemplateId
				)
			) AnswersXmlTable
		CROSS APPLY AnswersXmlTable.AnswerInfo.nodes('//a') AS AnswersXML(A),
		#Answers
	WHERE A.value('@Guid', 'nvarchar(50)') = #Answers.AnswerGuid
		AND (#Answers.QuestionTypeId = 3		-- Group logic
			OR #Answers.QuestionTypeId = 6		-- Simple logic
			OR #Answers.QuestionTypeId = 7		-- User prompt
			OR #Answers.QuestionTypeId = 19		-- Rich Text	
			OR #Answers.QuestionTypeId = 24)	-- Numeric	
	UNION ALL
	-- Repeated Datasource SelectedValues
	SELECT Log_Guid,
		A.value('@Guid', 'nvarchar(50)') AS AnswerGuid,
		A.value('@Value', 'nvarchar(1000)') AS Value,
		DateTime_Start,
		DateTime_Finish,
		User_Id,
		A.value('@RepeatGuids', 'nvarchar(1000)') AS RepeatGuids,
		A.value('@RepeatIndexes', 'nvarchar(1000)') AS RepeatIndexes
	FROM (SELECT Axml.query(
					'
					for $Q in (descendant::q)
					return element q 
					{
						attribute Guid {$Q/@qid},
						attribute Value {$Q/@SelectedValue},
						attribute RepeatGuids
						{
							(//repeat[descendant::q[. is $Q]]/@guid)
						},
						attribute RepeatIndexes
						{
							(//qs[descendant::q[. is $Q]]/@i)
						}
					}
					') AS AnswerInfo,
				Template_Log.Log_Guid,
				Template_Log.DateTime_Start,
				Template_Log.DateTime_Finish,
				Template_Log.User_Id
		FROM	Template_Log 
				CROSS APPLY Answer_File.nodes('(/AnswerFile/ps)') as AnswerXml(Axml)
		WHERE	Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
				AND Template_Log.Template_Group_Id IN
				(
					SELECT	tg.Template_Group_Id
					FROM	Template_Group tg
							INNER JOIN Template t ON tg.Template_Guid = t.Template_Guid
					WHERE	t.Template_Id = @TemplateId
				)
			) AnswersXmlTable
		CROSS APPLY AnswersXmlTable.AnswerInfo.nodes('//q') AS AnswersXML(A),
		#Answers
	WHERE A.value('@Guid', 'nvarchar(50)') = #Answers.AnswerGuid
		AND #Answers.QuestionTypeId = 14		-- Datasource
	UNION ALL
	---- Repeated Label Answers
	SELECT	Log_Guid,
			#Answers.AnswerGuid, 
			Value,
			DateTime_Start,
			DateTime_Finish,
			User_Id,
			RepeatGuids,
			RepeatIndexes
	FROM
		(SELECT V.value('@Label', 'nvarchar(1000)') AS Label,
			V.value('@Value', 'nvarchar(1000)') AS Value,
			V.value('@RepeatGuids', 'nvarchar(1000)') AS RepeatGuids,
			V.value('@RepeatIndexes', 'nvarchar(1000)') + ' ' + V.value('@LastRepeatIndex', 'nvarchar(50)') AS RepeatIndexes,
			Log_Guid,
			DateTime_Start,
			DateTime_Finish,
			User_Id
		FROM (SELECT Ls.query(
					'
					for $A in (descendant::Value)
					return element Value 
					{
						attribute Label 
						{
							(//Label[descendant::Value[. is $A]]/@name)
						},
						attribute Value {$A/text()},
						attribute RepeatGuids
						{
							(//Values[descendant::Value[. is $A]]/@guid)
						},
						attribute RepeatIndexes
						{
							(//Values[descendant::Value[. is $A]]/@i)
						},
						attribute LastRepeatIndex {$A/@i}
					}
					') AS AnswerInfo,
					Template_Log.Log_Guid,
					Template_Log.DateTime_Start,
					Template_Log.DateTime_Finish,
					Template_Log.User_Id
				FROM	Template_Log 
						CROSS APPLY Answer_File.nodes('(/AnswerFile/AnswerLabels)') as LabelXML(Ls)
				WHERE	Template_Log.DateTime_Finish BETWEEN @StartDate and @FinishDate
						AND Template_Log.Template_Group_Id IN
						(
							SELECT	tg.Template_Group_Id
							FROM	Template_Group tg
									INNER JOIN Template t ON tg.Template_Guid = t.Template_Guid
							WHERE	t.Template_Id = @TemplateId
						)
				) LabelsXmlTable
			CROSS APPLY LabelsXmlTable.AnswerInfo.nodes('//Value') AS ValueXML(V)
			) AS Labels,
			#Answers
		WHERE Labels.Label = #Answers.Label
			AND (#Answers.QuestionTypeId = 3		-- Group logic
				OR #Answers.QuestionTypeId = 6		-- Simple logic
				OR #Answers.QuestionTypeId = 7		-- User prompt
				OR #Answers.QuestionTypeId = 19		-- Rich Text	
				OR #Answers.QuestionTypeId = 24)	-- Numeric	
			
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
						WHEN 14
						THEN 'Datasource'
						WHEN 19
						THEN 'Rich Text'
						WHEN 24
						THEN 'Numeric'
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
					END as 'Answer',
					#Answers.AnswerName AS 'Answer Name',
					#Answers.AnswerID AS 'Answer ID',
					#Responses.RepeatGuids,
					#Responses.RepeatIndexes
			
	FROM	#Answers
			INNER JOIN #Responses ON #Answers.AnswerGuid = #Responses.AnswerGuid
			INNER JOIN Intelledox_User ON Intelledox_User.User_ID = #Responses.UserID
	WHERE (#Answers.QuestionTypeId = 3 AND #Responses.Value = '1')
		OR #Answers.QuestionTypeId = 6
		OR #Answers.QuestionTypeId = 7
		OR #Answers.QuestionTypeId = 14		
		OR #Answers.QuestionTypeId = 19		
		OR #Answers.QuestionTypeId = 24
	ORDER BY #Responses.LogGuid,
			Intelledox_User.Username,
			#Responses.StartDate,
			#Responses.FinishDate;
	
	DROP TABLE #Answers;
	DROP TABLE #Responses;
GO

ALTER TABLE dbo.Data_Object_Key ADD
	HierarchyParentName nvarchar(100) NULL
GO

ALTER PROCEDURE [dbo].[spDataSource_DataKeyList]
	@DataObjectGuid uniqueidentifier = null,
	@Name nvarchar(500) = null
AS
	IF @Name IS NULL
		SELECT	dk.data_object_key_guid, dk.field_name, dk.required, dk.display_name, dk.data_object_guid,
				dk.Data_Object_Key_Id, dk.Required_In_Filter, dk.HierarchyParentName
		FROM	data_object_key dk
		WHERE	dk.data_object_guid = @DataObjectGuid
		ORDER BY dk.field_name;
	ELSE
		SELECT	dk.data_object_key_guid, dk.field_name, dk.required, dk.display_name, dk.data_object_guid,
				dk.Data_Object_Key_Id, dk.Required_In_Filter, dk.HierarchyParentName
		FROM	data_object_key dk
		WHERE	dk.data_object_guid = @DataObjectGuid
				AND dk.Field_Name = @Name
		ORDER BY dk.field_name;
GO

ALTER PROCEDURE [dbo].[spDataSource_UpdateDataKey]
	@FieldName nvarchar(500),
	@Required bit,
	@DisplayName nvarchar(500),
	@DataObjectGuid nvarchar(40),
	@RequiredInFilter bit,
	@HierarchyParentName nvarchar(100)
AS
	IF NOT EXISTS(SELECT * FROM data_object_key WHERE Field_Name = @FieldName AND Data_Object_Guid = @DataObjectGuid)
	begin
		INSERT INTO data_object_key (Data_Object_Key_Guid, Field_Name, [Required], Display_Name, Data_Object_Guid, Required_In_Filter, HierarchyParentName)
		VALUES (newid(), @FieldName, @Required, @DisplayName, @DataObjectGuid, @RequiredInFilter, @HierarchyParentName);
	end
	ELSE
	begin
		UPDATE	data_object_key
		SET		[required] = @Required,
				display_name = @DisplayName,
				Required_In_Filter = @RequiredInFilter,
				HierarchyParentName = @HierarchyParentName
		WHERE	Data_Object_Guid = @DataObjectGuid
			and field_name = @FieldName;
	end
GO
