truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.6.2');
go

CREATE TABLE [dbo].[AssetRunID](
	[ID] [uniqueidentifier] NOT NULL,
	[AssetID] [uniqueidentifier] NOT NULL,
	[RunID] [uniqueidentifier] NULL,
	CONSTRAINT [AssetRunId_pk] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)
)

GO

ALTER TABLE [dbo].[Answer_File]
ADD RunID uniqueidentifier NULL
GO

ALTER procedure [dbo].[spAudit_UpdateAnswerFile]
	@AnswerFile_ID int,
	@AnswerFile_Guid uniqueidentifier,
	@User_Guid uniqueidentifier,
	@Template_Group_Guid uniqueidentifier,
	@Description nvarchar(255),
	@RunDate datetime,
	@UnencryptedAnswerString xml,
	@EncryptedAnswerString varbinary(MAX),
	@FirstLaunchTimeUtc datetime,
	@RunID uniqueidentifier,
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
			AnswerString = @UnencryptedAnswerString,
			EncryptedAnswerString = @EncryptedAnswerString
		where AnswerFile_ID = @AnswerFile_ID;
	end
	else
	begin
		insert into Answer_File (AnswerFile_Guid, [User_Guid], [Template_Group_Guid], [Description], [RunDate], [AnswerString], [InProgress], [EncryptedAnswerString], FirstLaunchTimeUtc, RunID)
		values (@AnswerFile_Guid, @User_Guid, @Template_Group_Guid, @Description, @RunDate, @UnencryptedAnswerString, @InProgress, @EncryptedAnswerString, @FirstLaunchTimeUtc, @RunID);

		select @NewID = @@Identity;
	end

	set @ErrorCode = @@Error;
GO

ALTER PROCEDURE [dbo].[spAudit_AnswerFileList]
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
					ans.RunDate, ans.InProgress, ans.AnswerFile_Guid, ans.RunID,
					Template.Name as Template_Name, Template_Group.Template_Group_Guid,
					ans.FirstLaunchTimeUtc, Template_Group.MatchProjectVersion
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
					ans.RunDate, ans.InProgress, ans.AnswerFile_Guid, ans.RunID,
					T.Name as Template_Name,
					ans.FirstLaunchTimeUtc, Template_Group.MatchProjectVersion
			from	answer_file ans					
					INNER JOIN Template_Group on ans.Template_Group_Guid = Template_Group.Template_Group_Guid
					INNER JOIN Template AS T ON Template_Group.Template_Guid = T.Template_Guid
			where	Ans.[user_Guid] = @user_Guid
					AND Ans.Template_group_Guid = @TemplateGroupGuid
			order by [RunDate] desc;
    end
    else
    begin
        SELECT	Answer_File.*, Template_Group.MatchProjectVersion
		FROM	Answer_File
			INNER JOIN Template_Group ON Answer_File.Template_Group_Guid = Template_Group.Template_Group_Guid
        WHERE	Answer_File.AnswerFile_Id = @AnswerFile_Id
        ORDER BY Answer_File.[RunDate] desc;
    end
GO

ALTER PROCEDURE [dbo].[spAssetStorage_Store]
	@BusinessUnitGuid uniqueidentifier,
	@Id uniqueidentifier,
	@DateCreatedUtc datetime,
	@RunID uniqueidentifier,
	@Data varbinary(max)
AS
	INSERT AssetStorage(BusinessUnitGuid, Id, Data, DateCreatedUtc)
	VALUES (@BusinessUnitGuid, @Id, @Data, @DateCreatedUtc);

	INSERT AssetRunID(ID, AssetID, RunID)
	VALUES (NEWID(), @Id, @RunID)

GO

ALTER TABLE [dbo].[Template_Log]
ADD RunID uniqueidentifier NULL
GO

ALTER procedure [dbo].[spLog_InsertTemplateLog]
	@LogGuid uniqueidentifier,
	@UserGuid uniqueidentifier,	
	@TemplateGroupGuid uniqueidentifier,
	@StartTime datetime,
	@AnswerFile xml,
	@RunID uniqueidentifier,
	@UpdateRecent bit = 0,
	@ActionListStateId uniqueidentifier = '00000000-0000-0000-0000-000000000000'
AS
	DECLARE @UserId INT;
	DECLARE @TemplateGroupId INT;
	
	SET NOCOUNT ON;
	
	SET @UserId = (SELECT User_Id FROM Intelledox_User WITH (NOLOCK) WHERE User_Guid = @UserGuid);
	SET	@TemplateGroupId = (SELECT Template_Group_Id FROM Template_Group WITH (NOLOCK) WHERE Template_Group_Guid = @TemplateGroupGuid);
	
	IF @LogGuid IS NULL
		SET @LogGuid = newid();

	--Add to log
	INSERT INTO Template_Log WITH (ROWLOCK) (Log_Guid, [User_ID], Template_Group_ID, DateTime_Start, CompletionState, Answer_File, ActionListStateId, RunID)
	VALUES (@LogGuid, @UserID, @TemplateGroupID, @StartTime, 0, @AnswerFile, @ActionListStateId, @RunID);

	--Add to recent
	If @UpdateRecent = 1
	BEGIN
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
			
			INSERT INTO Template_Recent(User_Guid, DateTime_Start, Template_Group_Guid, Log_Guid)
			VALUES (@UserGuid, @StartTime, @TemplateGroupGuid, @LogGuid);
		END
	END
GO

ALTER TABLE [dbo].[ActionListState]
ADD RunID uniqueidentifier NULL
GO

CREATE PROCEDURE [dbo].[spAssets_ForRunID]
	@BusinessUnitGuid uniqueidentifier,
	@RunID uniqueidentifier
AS
	SELECT *
	FROM AssetRunID
	WHERE RunID = @RunID

GO

CREATE PROCEDURE [dbo].[spAssetStorage_NewRunID]
	@OldRunID uniqueidentifier,
	@NewRunID uniqueidentifier
AS
	INSERT INTO AssetRunID(ID, AssetID, RunID)
	SELECT NEWID(), AssetID, @NewRunID
	FROM AssetRunID 
	WHERE RunID = @OldRunID
GO
CREATE TABLE [dbo].[ConnectorSettings_ElementTypeTmp](
	[ConnectorSettingsElementTypeId] [uniqueidentifier] NOT NULL,
	[ConnectorSettingsTypeId] [uniqueidentifier] NOT NULL,
	[DescriptionDefault] [nvarchar](255) NULL,
	[Encrypt] [bit] NULL,
	[SortOrder] [numeric](18, 0) NULL,
	[ElementValue] [nvarchar](max) NULL,
 CONSTRAINT [PK_ConnectorSettings_ElementTypeId] PRIMARY KEY NONCLUSTERED 
(
	[ConnectorSettingsElementTypeId] ASC
)
)
GO
CREATE CLUSTERED INDEX IX_ConnectorSettings_ElementType ON dbo.ConnectorSettings_ElementTypeTmp
	(
	ConnectorSettingsTypeId
	)
GO
INSERT INTO ConnectorSettings_ElementTypeTmp(ConnectorSettingsElementTypeId, ConnectorSettingsTypeId,
	DescriptionDefault, Encrypt, SortOrder,	ElementValue)
SELECT ConnectorSettingsElementTypeId, ConnectorSettingsTypeId,
	DescriptionDefault, Encrypt, SortOrder,	ElementValue
FROM ConnectorSettings_ElementType
GO
DROP TABLE dbo.ConnectorSettings_ElementType
GO
EXEC sp_rename 'dbo.ConnectorSettings_ElementTypeTmp', 'ConnectorSettings_ElementType'
GO

ALTER PROCEDURE [dbo].[spTenant_ProvisionTenant] (
	   @NewBusinessUnit uniqueidentifier,
	   @AdminUserGuid uniqueidentifier,
       @TenantName nvarchar(200),
       @FirstName nvarchar(50),
       @LastName nvarchar(50),
       @UserName nvarchar(256),
       @UserPasswordHash varchar(1000),
       @UserPwdSalt nvarchar(128),
       @UserPwdFormat int,
       @Email nvarchar(256),
       @TenantKey varbinary(MAX),
       @TenantType int,
       @LicenseHolderName nvarchar(4000)
)
AS
       DECLARE @GuestUserGuid uniqueidentifier
       DECLARE @TenantGroupGuid uniqueidentifier
	   DECLARE @BusinessUnitIdentifier int

       SET @GuestUserGuid = NewID()
	   SET @BusinessUnitIdentifier = floor(rand(CONVERT([varbinary],newid(),(0)))*(89999))+(10000)

	   WHILE @BusinessUnitIdentifier IN (SELECT IdentifyBusinessUnit FROM Business_Unit)
	   BEGIN
		SET @BusinessUnitIdentifier = floor(rand(CONVERT([varbinary],newid(),(0)))*(89999))+(10000)
	   END
	   
       --New business unit (Company in SaaS)
       INSERT INTO Business_Unit(Business_Unit_Guid, Name, TenantKey, TenantType, IdentifyBusinessUnit)
       VALUES (@NewBusinessUnit, @TenantName, CONVERT(varbinary(MAX), @TenantKey), @TenantType, @BusinessUnitIdentifier)

		
       --Insert roles
       --End User
       --Workflow Administrator
       INSERT INTO Administrator_Level(AdminLevel_Description, RoleGuid, Business_Unit_Guid)
       VALUES ('End User', NewId(), @NewBusinessUnit)

       INSERT INTO Administrator_Level(AdminLevel_Description, RoleGuid, Business_Unit_Guid)
       VALUES ('Workflow Administrator', NewId(), @NewBusinessUnit)

       SET @TenantGroupGuid = NewId()
	   --Group address for User Group
       INSERT INTO Address_Book (Organisation_Name)
       VALUES (@TenantName + ' Users')

       --New group
       INSERT INTO User_Group(Name, WinNT_Group, Business_Unit_Guid, Group_Guid, AutoAssignment, SystemGroup, Address_ID)
       VALUES (@TenantName + ' Users', 0, @NewBusinessUnit, @TenantGroupGuid, 1, 1, @@IDENTITY)

	   --Mobile App Users Group
	   INSERT INTO Address_Book(Full_Name, Organisation_Name)
	   VALUES ('Mobile App Users', 'Mobile App Users');

	   INSERT INTO User_Group(Name, WinNT_Group, Business_Unit_Guid, Group_Guid, AutoAssignment, SystemGroup, Address_ID)
	   VALUES ('Mobile App Users', 0, @NewBusinessUnit, NewId(), 0, 1, @@IDENTITY);

		--call procedure for creating admin user, global administrator role, role mapping and group assignment
	   EXEC spTenant_CreateAdminUser @NewBusinessUnit, @AdminUserGuid, @FirstName, @LastName, @UserName, 
										@UserPasswordHash, @UserPwdSalt, @UserPwdFormat, @Email 

       --User address for guest user
       INSERT INTO address_book (full_name, first_name, last_name, email_address)
       VALUES (@LicenseHolderName + '_Guest', '', '', '')
       --Guest
       INSERT INTO Intelledox_User(Username, Pwdhash, PwdSalt, PwdFormat, WinNT_User, Business_Unit_Guid, User_Guid, Address_ID, IsGuest)
       VALUES (@LicenseHolderName + '_Guest', '', '', @UserPwdFormat, 0, @NewBusinessUnit, @GuestUserGuid, @@IDENTITY, 1)

       INSERT INTO User_Group_Subscription(UserGuid, GroupGuid, IsDefaultGroup)
       VALUES(@GuestUserGuid, @TenantGroupGuid, 1)

       INSERT INTO Global_Options(BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
       SELECT @NewBusinessUnit, OptionCode, OptionDescription, OptionValue
       FROM   Global_Options
       WHERE  BusinessUnitGuid = (SELECT OptionValue
									FROM Global_Options
									WHERE UPPER(OptionCode) = 'DEFAULT_TENANT');
											
	   UPDATE Global_Options
       SET OptionValue=''
       WHERE BusinessUnitGuid = @NewBusinessUnit AND UPPER(OptionCode) IN ('APPLE_PUSH_CERT', 'APPLE_PUSH_CERT_PASSWORD', 'ANDROID_PUSH_API_KEY');

       UPDATE Global_Options
       SET OptionValue='DoNotReply@intelledox.com'
       WHERE BusinessUnitGuid = @NewBusinessUnit AND OptionCode='FROM_EMAIL_ADDRESS';

	   	   --sync the license holder name to tenant name
       UPDATE Global_Options
       SET OptionValue=@LicenseHolderName
       WHERE BusinessUnitGuid = @NewBusinessUnit AND OptionCode='LICENSE_HOLDER';

GO
