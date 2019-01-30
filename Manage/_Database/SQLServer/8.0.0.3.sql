/*
** Database Update package 8.0.0.3
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.0.0.3');
go

--2027
ALTER TABLE	Template_Recent
	ADD Log_Guid uniqueidentifier null
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
						INNER JOIN User_Group_Subscription ON User_Group.Group_Guid = User_Group_Subscription.GroupGuid
						INNER JOIN Intelledox_User ON User_Group_Subscription.UserGuid = Intelledox_User.User_Guid
				WHERE	Intelledox_User.User_Guid = @UserGuid
				)
			AND CASE WHEN d.[Name] = '' THEN b.Name ELSE d.[Name] END LIKE @ProjectSearch + '%'
			AND l.[User_Guid] = @UserGuid
			AND (d.EnforcePublishPeriod = 0 
				OR ((d.PublishStartDate IS NULL OR d.PublishStartDate < getutcdate())
					AND (d.PublishFinishDate IS NULL OR d.PublishFinishDate > getutcdate())))
	ORDER BY l.DateTime_Start DESC;
GO
ALTER procedure [dbo].[spLog_InsertTemplateLog]
	@LogGuid uniqueidentifier,
	@UserGuid uniqueidentifier,	
	@TemplateGroupGuid uniqueidentifier,
	@StartTime datetime,
	@AnswerFileUsed bit,
	@AnswerFile xml,
	@UpdateRecent bit = 0
AS
	DECLARE @UserId INT;
	DECLARE @TemplateGroupId INT;
	
	SET NOCOUNT ON;
	
	SET @UserId = (SELECT User_Id FROM Intelledox_User WITH (NOLOCK) WHERE User_Guid = @UserGuid);
	SET	@TemplateGroupId = (SELECT Template_Group_Id FROM Template_Group WITH (NOLOCK) WHERE Template_Group_Guid = @TemplateGroupGuid);
	
	IF @LogGuid IS NULL
		SET @LogGuid = newid();

	--Add to log
	INSERT INTO Template_Log WITH (ROWLOCK) (Log_Guid, [User_ID], Template_Group_ID, DateTime_Start, Completed, Answer_File_Used, InProgress, Answer_File)
	VALUES (@LogGuid, @UserID, @TemplateGroupID, @StartTime, 0, @AnswerFileUsed, 1, @AnswerFile);

	--Add to recent
	If @UpdateRecent = 1
	BEGIN
		IF EXISTS (SELECT * FROM Template_Recent WHERE User_Guid = @UserGuid AND Template_Group_Guid = @TemplateGroupGuid)
		BEGIN
			--Update time ran
			UPDATE	Template_Recent
			SET		DateTime_Start = @StartTime,
					Log_Guid = @LogGuid
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
			
			INSERT INTO Template_Recent(User_Guid, DateTime_Start, Template_Group_Guid, Log_Guid)
			VALUES (@UserGuid, @StartTime, @TemplateGroupGuid, @LogGuid);
		END
	END
GO


--2028
CREATE TABLE [dbo].[Routing_Output](
	[RoutingTypeID] [uniqueidentifier] NOT NULL,
	[RoutingOutputID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_Routing_Output] PRIMARY KEY CLUSTERED 
(
	[RoutingOutputID] ASC
)
)
GO

CREATE PROCEDURE [dbo].[spRouting_RegisterRouterOutput]
	@RoutingTypeId uniqueidentifier,
	@RouterOutputId uniqueidentifier,
	@Name nvarchar(255)
AS
	IF NOT EXISTS(SELECT * 
		FROM Routing_Output 
		WHERE RoutingTypeId = @RoutingTypeId 
			AND RoutingOutputId = @RouterOutputId)
	BEGIN
		INSERT INTO Routing_Output(RoutingTypeId, RoutingOutputId, Name)
		VALUES	(@RoutingTypeId, @RouterOutputId, @Name);
	END
GO

CREATE PROCEDURE [dbo].[spRouting_RouterOutputList]
	@RoutingTypeId uniqueidentifier
AS
	SELECT	*
	FROM	Routing_Output
	WHERE	RoutingTypeId = @RoutingTypeId
	ORDER BY Name;

GO

--2029
CREATE TABLE [dbo].[ProviderSettings_ElementType](
	[ProviderSettingsElementTypeId] [uniqueidentifier] NOT NULL,
	[ProviderSettingsTypeId] [uniqueidentifier] NOT NULL,
	[DescriptionDefault] [nvarchar](255) NULL,
	[Encrypt] [bit] NULL,
	[SortOrder] [numeric](18, 0) NULL,
	[ElementValue] [nvarchar](max) NULL,
 CONSTRAINT [PK_ProviderSettings_ElementType] PRIMARY KEY CLUSTERED 
(
	[ProviderSettingsElementTypeId] ASC
)
)

GO

CREATE TABLE [dbo].[ProviderSettings_Type](
	[ProviderSettingsTypeId] [uniqueidentifier] NOT NULL,
	[ProviderSettingsDescription] [nvarchar](255) NULL,
 CONSTRAINT [PK_ProviderSettings_Type] PRIMARY KEY CLUSTERED 
(
	[ProviderSettingsTypeId] ASC
)
)

GO

CREATE PROCEDURE [dbo].[spProviderSettings_ElementTypeList] 
	-- Add the parameters for the stored procedure here
	@ProviderSettingsTypeId uniqueidentifier
AS
BEGIN
	SELECT * 
	FROM ProviderSettings_ElementType
	WHERE ProviderSettingsTypeId = @ProviderSettingsTypeId
	ORDER BY SortOrder, DescriptionDefault
END

GO

CREATE PROCEDURE [dbo].[spProviderSettings_RegisterElementType]
	@ProviderSettingsElementTypeId uniqueidentifier,
	@ProviderSettingsTypeId uniqueidentifier,
	@Description nvarchar(255),
	@Encrypt bit,
	@SortOrder int,
	@ElementValue nvarchar(max)
AS
	IF NOT EXISTS(SELECT * FROM ProviderSettings_ElementType WHERE ProviderSettingsElementTypeId = @ProviderSettingsElementTypeId AND ProviderSettingsTypeId = @ProviderSettingsTypeId)
	BEGIN
		INSERT INTO ProviderSettings_ElementType(ProviderSettingsElementTypeId,ProviderSettingsTypeId,DescriptionDefault,Encrypt,SortOrder,ElementValue)
		VALUES (@ProviderSettingsElementTypeId,@ProviderSettingsTypeId,@Description,@Encrypt,@SortOrder,@ElementValue);
	END

GO

CREATE PROCEDURE [dbo].[spProviderSettings_RegisterSettingsType]
	@Id uniqueidentifier,
	@Description nvarchar(255)
AS
	IF NOT EXISTS(SELECT * FROM  ProviderSettings_Type WHERE ProviderSettingsTypeId = @id)
	BEGIN
		INSERT INTO ProviderSettings_Type(ProviderSettingsTypeId, ProviderSettingsDescription)
		VALUES	(@id, @Description);
	END


GO

CREATE PROCEDURE [dbo].[spProviderSettings_TypeList]
	
AS
BEGIN
	SELECT * 
	FROM ProviderSettings_Type
	ORDER BY ProviderSettingsDescription
END


GO

CREATE PROCEDURE [dbo].[spProviderSettings_UpdateElementTypeValue]
	-- Add the parameters for the stored procedure here
	@ProviderSettingsElementTypeId uniqueidentifier,
	@ElementValue nvarchar(max)
AS
BEGIN
	UPDATE ProviderSettings_ElementType
	SET ElementValue = @ElementValue
	WHERE ProviderSettingsElementTypeId = @ProviderSettingsElementTypeId
END

GO

--2030
ALTER TABLE dbo.Template_Styles ADD
	TemplateStyleGuid uniqueidentifier NOT NULL CONSTRAINT DF_Template_Styles_TemplateStyleGuid DEFAULT newid()
GO
ALTER TABLE dbo.Template_Styles ADD CONSTRAINT
	PK_Template_Styles PRIMARY KEY NONCLUSTERED 
	(
	TemplateStyleGuid
	)
GO

--2031

  INSERT INTO Global_Options (OptionCode, OptionDescription, OptionValue)
  VALUES ('HAS_LEGACY_PROVIDERS', 'Defines whether or not this instance of Intelledox has pre-v8 Delivery/Submission Providers', 0)
  GO

UPDATE Global_Options
SET OptionValue =
	CASE (SELECT Count(*)
		FROM Routing_Type
		WHERE ProviderType = 1
			OR ProviderType = 2)
	WHEN 0 THEN 0
	ELSE 1
	END
WHERE OptionCode = 'HAS_LEGACY_PROVIDERS'
GO

