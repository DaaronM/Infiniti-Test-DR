truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.0.3');
go
SET NOCOUNT ON;

DECLARE @BusinessUnitGuid uniqueidentifier;
DECLARE BuCursor CURSOR
	FOR	SELECT	Business_Unit_Guid
		FROM	Business_Unit;

OPEN BuCursor;
FETCH NEXT FROM BuCursor INTO @BusinessUnitGuid;

WHILE @@FETCH_STATUS = 0
BEGIN
	INSERT INTO Address_Book(full_name)
	VALUES ('Mobile App Users');

	INSERT INTO User_Group(Name, WinNT_Group, Business_Unit_Guid, Group_Guid, AutoAssignment, SystemGroup, Address_ID)
	VALUES ('Mobile App Users', 0, @BusinessUnitGuid, newid(), 0, 1, @@IDENTITY);

	FETCH NEXT FROM BuCursor INTO @BusinessUnitGuid;
END

CLOSE BuCursor;
DEALLOCATE BuCursor;
GO
SET NOCOUNT ON;

DECLARE @GroupGuid uniqueidentifier;
DECLARE	@Name nvarchar(50);
DECLARE GroupCursor CURSOR
	FOR	SELECT	Group_Guid, Name
		FROM	user_group
		WHERE	Address_ID IS NULL;

OPEN GroupCursor;
FETCH NEXT FROM GroupCursor INTO @GroupGuid, @Name;

WHILE @@FETCH_STATUS = 0
BEGIN
	INSERT INTO Address_Book(full_name)
	VALUES (@Name);

	UPDATE User_Group
	SET	Address_ID = @@IDENTITY
	WHERE	Group_Guid = @GroupGuid;

	FETCH NEXT FROM GroupCursor INTO @GroupGuid, @Name;
END

CLOSE GroupCursor;
DEALLOCATE GroupCursor;
GO
ALTER PROCEDURE [dbo].[spJob_QueueList]
	@BusinessUnitGuid uniqueidentifier,
	@StartDate DateTime,
	@FinishDate DateTime,
	@CurrentStatus Int
AS
	SELECT	ProcessJob.JobId, ProcessJob.DateStarted, ProcessJob.CurrentStatus,
			Template.Name as ProjectName, Intelledox_User.Username, 
			ProcessJob.LogGuid,
			CASE WHEN template_Log.Messages IS NOT NULL THEN 1 ELSE 0 END AS HasMessages
	FROM	ProcessJob
			LEFT JOIN Intelledox_User ON ProcessJob.UserGuid = Intelledox_User.User_Guid
			INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
			INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
			LEFT JOIN Template_Log ON ProcessJob.LogGuid = Template_Log.Log_Guid
	WHERE	ProcessJob.DateStarted BETWEEN @StartDate AND @FinishDate
			AND ((@CurrentStatus = 0) OR 
				(@CurrentStatus = -1 AND ProcessJob.CurrentStatus <> 7) OR 
				(@CurrentStatus <> -1 AND ProcessJob.CurrentStatus = @CurrentStatus))
			AND Template.Business_Unit_Guid = @BusinessUnitGuid
	ORDER BY ProcessJob.DateStarted DESC;
GO
ALTER TABLE Group_Output
	ADD CreateOutline bit not null default (0)
GO
ALTER PROCEDURE [dbo].[spTemplateGrp_UpdateGroupOutput]
	@GroupGuid uniqueidentifier,
	@FormatTypeId int,
	@LockOutput bit,
	@EmbedFullFonts bit,
	@CreateOutline bit
AS
	IF NOT EXISTS(SELECT * FROM Group_Output WHERE GroupGuid = @GroupGuid AND FormatTypeId = @FormatTypeId)
	BEGIN
		INSERT INTO Group_Output (GroupGuid, FormatTypeId, LockOutput, EmbedFullFonts, CreateOutline)
		VALUES (@GroupGuid, @FormatTypeId, @LockOutput, @EmbedFullFonts, @CreateOutline)
	END	
	ELSE
	BEGIN		
		UPDATE	Group_Output
		SET		LockOutput = @LockOutput,
				EmbedFullFonts = @EmbedFullFonts,
				CreateOutline = @CreateOutline
		WHERE	GroupGuid = @GroupGuid
			AND FormatTypeId = @FormatTypeId
	END
GO
