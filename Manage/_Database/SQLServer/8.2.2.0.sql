/*
** Database Update package 8.2.2.0
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.2.0');
go

--2116
CREATE NONCLUSTERED INDEX IX_Document_UserGuidJobId ON dbo.[Document]
	(
	UserGuid,
	JobId
	)
GO
CREATE NONCLUSTERED INDEX IX_Document_DateCreated ON dbo.[Document]
	(
	DateCreated
	)
GO
ALTER PROCEDURE [dbo].[spDocument_DocumentList] (
	@JobId uniqueidentifier,
	@UserGuid uniqueidentifier,
	@IncludeActionOnlyDocs bit
)
AS
	IF (@JobId IS NULL)
	BEGIN
		SELECT	TOP 500
				Document.DocumentId, 
				Document.Extension,  
				Document.DisplayName,  
				Document.ProjectDocumentGuid,  
				Document.DateCreated,  
				Document.JobId,
				Document.ActionOnly,
				Template.Name As ProjectName
		FROM	Document WITH (NOLOCK)
				INNER JOIN ProcessJob ON Document.JobId = ProcessJob.JobId
				INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
				INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
		WHERE	(@IncludeActionOnlyDocs = 1 OR Document.ActionOnly = 0)
				AND Document.UserGuid = @UserGuid;
	END
	ELSE
	BEGIN
		SELECT	Document.DocumentId, 
				Document.Extension,  
				Document.DisplayName,  
				Document.ProjectDocumentGuid,  
				Document.DateCreated,  
				Document.JobId,
				Document.ActionOnly,
				Template.Name As ProjectName
		FROM	Document
				INNER JOIN ProcessJob ON Document.JobId = ProcessJob.JobId
				INNER JOIN Template_Group ON ProcessJob.ProjectGroupGuid = Template_Group.Template_Group_Guid
				INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid
		WHERE	Document.JobId = @JobId
				AND (@IncludeActionOnlyDocs = 1 OR Document.ActionOnly = 0)
				AND Document.UserGuid = @UserGuid; --Security check
	END
GO

--2117
ALTER PROCEDURE [dbo].[spUsers_UserGroupByUser]
	-- Add the parameters for the stored procedure here
	@UserID int,
	@BusinessUnitGUID uniqueidentifier,
	@Username nvarchar(50) = '',
	@UserGroupID int = 0,
	@UserGuid uniqueidentifier = null,
	@ShowActive int = 0,
	@ErrorCode int = 0 output,
	@Firstname nvarchar(50) = '',
	@Lastname nvarchar(50) = ''
AS
BEGIN
	if @UserGroupID = 0	--all user groups
	begin
		if @UserGuid is null
		begin
			if @UserID is null or @UserID = 0
			begin
				select	a.*, Business_Unit.DefaultLanguage
				from	Intelledox_User a
					left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
					left join Address_Book d on a.Address_ID = d.Address_ID
				where	(@Username = '' OR @Username is null OR a.[Username] like + @Username + '%')
					AND (@Firstname = '' OR @Firstname is null OR d.[First_Name] like + @Firstname + '%')
					AND (@Lastname = '' or @Lastname is null or d.[Last_Name] like + @Lastname + '%')
					AND (a.Business_Unit_GUID = @BusinessUnitGUID)
					AND (@ShowActive = 0 
						OR (@ShowActive = 1 AND a.[Disabled] = 0)
						OR (@ShowActive = 2 AND a.[Disabled] = 1))
				ORDER BY a.[Username]
			end
			else
			begin
				select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
				from	Intelledox_User a
					left join User_Group_Subscription c on a.User_Guid = c.UserGuid
					left join User_Group b on c.GroupGuid = b.Group_Guid
					left join Address_Book d on a.Address_Id = d.Address_id
					left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
				where	(a.[User_ID] = @UserID)
					AND (@ShowActive = 0 
						OR (@ShowActive = 1 AND a.[Disabled] = 0)
						OR (@ShowActive = 2 AND a.[Disabled] = 1))
				ORDER BY a.[Username]
			end
		end
		else
		begin
			select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
			from	Intelledox_User a
				left join User_Group_Subscription c on a.User_Guid = c.UserGuid
				left join User_Group b on c.GroupGuid = b.Group_Guid
				left join Address_Book d on a.Address_Id = d.Address_id
				left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			where	(User_Guid = @UserGuid)
				AND (@ShowActive = 0 
					OR (@ShowActive = 1 AND a.[Disabled] = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1))
			ORDER BY a.[Username]
		end
	end
	else
	begin
		if @UserGroupID = -1	--users with no user groups
		begin
			select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
			from	Intelledox_User a
				left join User_Group_Subscription c on a.User_Guid = c.UserGuid
				left join User_Group b on c.GroupGuid = b.Group_Guid
				left join Address_Book d on a.Address_Id = d.Address_id
				left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			where	(@UserID = 0 OR @UserID IS NULL OR a.[User_ID] = @UserID)
				AND	(@Username = '' OR @Username is null OR a.[Username] like + @Username + '%')
				AND (@Firstname = '' OR @Firstname is null OR d.[First_Name] like + @Firstname + '%')
				AND (@Lastname = '' or @Lastname is null or d.[Last_Name] like + @Lastname + '%')
				AND	a.User_Guid not in (
						select a.userGuid
						from user_group_subscription a 
						inner join user_Group b on a.GroupGuid = b.Group_Guid
					)
				AND (@UserID <> 0 OR a.Business_Unit_GUID = @BusinessUnitGUID)
				AND (@ShowActive = 0 
					OR (@ShowActive = 1 AND a.[Disabled] = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1))
			ORDER BY a.[Username]
		end
		else			--users in specified user group
		begin
			select	a.*, b.*, c.IsDefaultGroup, d.Full_Name, Business_Unit.DefaultLanguage
			from	Intelledox_User a
				left join User_Group_Subscription c on a.User_Guid = c.UserGuid
				left join User_Group b on c.GroupGuid = b.Group_Guid
				left join Address_Book d on a.Address_Id = d.Address_id
				left join Business_Unit on a.Business_Unit_Guid = Business_Unit.Business_Unit_Guid
			where	(@UserID = 0 OR @UserID IS NULL OR a.[User_ID] = @UserID)
				AND	(@Username = '' OR @Username is null OR a.[Username] like + @Username + '%')
				AND (@Firstname = '' OR @Firstname is null OR d.[First_Name] like + @Firstname + '%')
				AND (@Lastname = '' or @Lastname is null or d.[Last_Name] like + @Lastname + '%')
				AND	c.GroupGuid = (SELECT Group_Guid FROM User_Group WHERE User_Group_id = @UserGroupID)
				AND (@UserID <> 0 OR a.Business_Unit_GUID = @BusinessUnitGUID)
				AND (@ShowActive = 0 
					OR (@ShowActive = 1 AND a.[Disabled] = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1))
			ORDER BY a.[Username]
		end
	end

	set @ErrorCode = @@error;

END

GO

--2118
ALTER TABLE dbo.Data_Object_Key ADD
	Required_In_Filter bit NOT NULL CONSTRAINT DF_Data_Object_Key_Required_In_Filter DEFAULT 0
GO


--2119
ALTER PROCEDURE [dbo].[spDataSource_UpdateDataKey]
	@FieldName nvarchar(500),
	@Required bit,
	@DisplayName nvarchar(500),
	@DataObjectGuid nvarchar(40),
	@RequiredInFilter bit
AS
	IF NOT EXISTS(SELECT * FROM data_object_key WHERE Field_Name = @FieldName AND Data_Object_Guid = @DataObjectGuid)
	begin
		INSERT INTO data_object_key (Data_Object_Key_Guid, Field_Name, [Required], Display_Name, Data_Object_Guid, Required_In_Filter)
		VALUES (newid(), @FieldName, @Required, @DisplayName, @DataObjectGuid, @RequiredInFilter);
	end
	ELSE
	begin
		UPDATE	data_object_key
		SET		[required] = @Required,
				display_name = @DisplayName,
				Required_In_Filter = @RequiredInFilter
		WHERE	Data_Object_Guid = @DataObjectGuid
			and field_name = @FieldName;
	end
GO


--2120
ALTER PROCEDURE [dbo].[spDataSource_DataKeyList]
	@DataObjectGuid uniqueidentifier = null,
	@Name nvarchar(500) = null
AS
	IF @Name IS NULL
		SELECT	dk.data_object_key_guid, dk.field_name, dk.required, dk.display_name, dk.data_object_guid,
				dk.Data_Object_Key_Id, dk.Required_In_Filter
		FROM	data_object_key dk
		WHERE	dk.data_object_guid = @DataObjectGuid
		ORDER BY dk.field_name;
	ELSE
		SELECT	dk.data_object_key_guid, dk.field_name, dk.required, dk.display_name, dk.data_object_guid,
				dk.Data_Object_Key_Id, dk.Required_In_Filter
		FROM	data_object_key dk
		WHERE	dk.data_object_guid = @DataObjectGuid
				AND dk.Field_Name = @Name
		ORDER BY dk.field_name;
GO


--2121
DROP PROCEDURE [dbo].[spData_UpdateDataServiceCredential]
GO
DROP PROCEDURE [dbo].[spData_UpdateDataService]
GO
DROP PROCEDURE [dbo].[spData_UpdateDataObject]
GO
DROP PROCEDURE [dbo].[spData_UpdateDataKey]
GO
DROP PROCEDURE [dbo].[spData_RemoveDataServiceCredential]
GO
DROP PROCEDURE [dbo].[spData_RemoveDataService]
GO
DROP PROCEDURE [dbo].[spData_RemoveDataObject]
GO
DROP PROCEDURE [dbo].[spData_RemoveDataKey]
GO
DROP PROCEDURE [dbo].[spData_DataServiceList]
GO
DROP PROCEDURE [dbo].[spData_DataServiceCredentialList]
GO
DROP PROCEDURE [dbo].[spData_DataObjectListByGuid]
GO
DROP PROCEDURE [dbo].[spData_DataKeyList]
GO
exec sp_rename 'dbo.Data_Service_Credential', 'zzData_Service_Credential';
GO
UPDATE	Data_Service
SET		Credential_Method = 0
WHERE	Credential_Method = 1;
GO
ALTER TABLE Data_Service
	DROP COLUMN Requires_Credentials
GO

--2122
INSERT INTO Group_Output(GroupGuid, FormatTypeId, LockOutput, EmbedFullFonts)
SELECT	GroupGuid, 3, LockOutput, EmbedFullFonts
FROM	Group_Output
WHERE	FormatTypeID = 2
		AND GroupGuid NOT IN (
			SELECT	GroupGuid
			FROM	Group_Output
			WHERE	FormatTypeId = 1 OR FormatTypeId = 3
		);

DELETE FROM	Group_Output
WHERE	FormatTypeID = 2;
GO


--2124
CREATE VIEW [dbo].[vwProjectDetails]
AS
SELECT  t.Template_ID, t.Name, t.Template_Type_ID, t.Fax_Template_ID, t.content_bookmark, t.Template_Guid, t.Template_Version, t.Import_Date, t.HelpText, 
        t.Business_Unit_GUID, t.Supplier_Guid, t.Project_Definition, t.Modified_Date, t.Modified_By, t.Comment, t.LockedByUserGuid, t.FeatureFlags, 
        t.IsMajorVersion, tg.Template_Group_ID, tg.Name AS GroupName, tg.Template_Group_Guid, tg.HelpText AS GroupHelpText, tg.AllowPreview, tg.PostGenerateText, 
        tg.UpdateDocumentFields, tg.EnforceValidation, tg.WizardFinishText, tg.EnforcePublishPeriod, tg.PublishStartDate, tg.PublishFinishDate, 
        tg.HideNavigationPane, tg.Template_Guid AS Expr3, tg.Template_Version AS Expr4, tg.Layout_Guid, tg.Layout_Version, tg.Folder_Guid
FROM    dbo.Template AS t INNER JOIN
        dbo.Template_Group AS tg ON tg.Template_Guid = t.Template_Guid
GO

