truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.1');
go


--Response Metadata
CREATE TABLE  dbo.ResponseMetaData_Field
	(
	FieldGuid uniqueidentifier NOT NULL,
	BusinessUnitGuid uniqueidentifier NOT NULL,
	[Name] nvarchar(100) NOT NULL
	  CONSTRAINT [PK_ResponseMetadataField] PRIMARY KEY CLUSTERED (FieldGuid)
	)
GO

CREATE PROCEDURE [dbo].[spResponseMetadata_GetField]
   @FieldGuid UNIQUEIDENTIFIER
AS
   SELECT *
   FROM ResponseMetaData_Field
   WHERE FieldGuid =  @FieldGuid
GO

CREATE PROCEDURE [dbo].[spResponseMetadata_GetFields]
   @BusinessUnitGuid UNIQUEIDENTIFIER
AS
   SELECT *
   FROM ResponseMetaData_Field
   WHERE BusinessUnitGuid = @BusinessUnitGuid
GO

CREATE PROCEDURE [dbo].[spResponseMetadata_RemoveField]
	@FieldGuid uniqueidentifier,
	@BusinessUnitGuid uniqueidentifier
AS
	DELETE ResponseMetaData_Field
	WHERE FieldGuid = @FieldGuid AND BusinessUnitGuid = @BusinessUnitGuid
GO

CREATE PROCEDURE[dbo].[spResponseMetadata_UpdateField]
	@BusinessUnitGuid uniqueidentifier,
	@FieldGuid uniqueidentifier = null,
	@Name nvarchar(100)
AS
	BEGIN
	  IF EXISTS (SELECT * FROM ResponseMetaData_Field WHERE FieldGuid = @FieldGuid AND BusinessUnitGuid = @BusinessUnitGuid)
	    BEGIN
		  UPDATE ResponseMetaData_Field
		  SET [Name] = @Name
		  WHERE FieldGuid = @FieldGuid AND BusinessUnitGuid = @BusinessUnitGuid
	    END
	  ELSE
	    BEGIN
		  INSERT INTO ResponseMetaData_Field (FieldGuid, BusinessUnitGuid, [Name])
		  VALUES (@FieldGuid, @BusinessUnitGuid, @Name)
		END
	END
GO

CREATE TABLE dbo.ResponseMetaData_Value
	(
	FieldGuid uniqueidentifier NOT NULL,
	RunId uniqueidentifier NOT NULL,
	[Value] nvarchar(255)
	  CONSTRAINT [PK_ResponseMetadata_Value] PRIMARY KEY CLUSTERED (RunId, FieldGuid ASC)
	)
GO

CREATE PROCEDURE[dbo].[spResponseMetadata_UpdateValue]
	@FieldGuid uniqueidentifier,
	@RunId uniqueidentifier,
	@Value nvarchar(255)
AS
	IF EXISTS (SELECT * FROM ResponseMetaData_Value WHERE RunId = @RunId AND FieldGuid = @FieldGuid)
	  BEGIN
		UPDATE ResponseMetaData_Value
		SET [Value] = @Value
		WHERE RunId = @RunId AND FieldGuid = @FieldGuid
	  END
  	ELSE
	  BEGIN
		INSERT INTO ResponseMetaData_Value (RunId, FieldGuid, [Value])
		VALUES (@RunId, @FieldGuid, @Value)
	  END  
GO

CREATE TABLE dbo.ResponseMetaData_FinishValue
	(
	FieldGuid uniqueidentifier NOT NULL,
	RunId uniqueidentifier NOT NULL,
	[Value] nvarchar(255)
	  CONSTRAINT [PK_ResponseMetadata_FinishValue] PRIMARY KEY CLUSTERED (RunId, FieldGuid ASC)
	)
GO

CREATE PROCEDURE[dbo].[spResponseMetadata_Finish]
	@RunId uniqueidentifier
AS
  INSERT INTO ResponseMetaData_FinishValue (FieldGuid, RunID, [Value])
  SELECT FieldGuid, RunID, [Value]
  FROM ResponseMetaData_Value
  WHERE RunId = @RunId
  
  DELETE 
  FROM ResponseMetaData_Value
  WHERE RunId = @RunId
GO
CREATE TABLE [dbo].[Data_Object_Schema](
	[Data_Object_Guid] [uniqueidentifier] NOT NULL,
	[Field_Name] [nvarchar](500) NOT NULL,
)
GO
CREATE CLUSTERED INDEX [IX_Data_Object_Schema] ON [dbo].[Data_Object_Schema]
(
	[Data_Object_Guid] ASC
)
GO
CREATE PROCEDURE [dbo].[spDataSource_SchemaFieldList]
	@DataObjectGuid uniqueidentifier
AS
	SELECT	field_name, data_object_guid
	FROM	data_object_schema
	WHERE	data_object_guid = @DataObjectGuid;
GO
CREATE PROCEDURE [dbo].[spDataSource_RemoveSchemaField]
	@FieldName nvarchar(500),
	@DataObjectGuid uniqueidentifier
AS
	DELETE	data_object_schema
	WHERE	Data_Object_Guid = @DataObjectGuid
			and field_name = @FieldName;
GO
CREATE PROCEDURE [dbo].[spDataSource_UpdateSchemaField]
	@FieldName nvarchar(500),
	@DataObjectGuid uniqueidentifier
AS
	IF NOT EXISTS(SELECT * FROM data_object_schema WHERE Field_Name = @FieldName AND Data_Object_Guid = @DataObjectGuid)
	begin
		INSERT INTO data_object_schema (Field_Name, Data_Object_Guid)
		VALUES (@FieldName, @DataObjectGuid);
	end
GO
ALTER PROCEDURE [dbo].[spDataSource_RemoveDataObject]
	@DataObjectGuid uniqueidentifier
AS
	DELETE	data_object_key
	WHERE	data_object_guid = @DataObjectGuid;
	
	DELETE	data_object_display
	WHERE	data_object_guid = @DataObjectGuid;

	DELETE  data_object_schema
	WHERE   data_object_guid = @DataObjectGuid;

	DELETE	data_object 
	WHERE	data_object_guid = @DataObjectGuid;
GO

ALTER VIEW dbo.vwUserAI
AS
	SELECT u.Business_Unit_GUID as BusinessUnitGuid,
			u.User_Guid as UserGuid,
			u.IsGuest,
			u.[Disabled],
			u.Username COLLATE Latin1_General_CI_AI as Username,
			ud.First_Name COLLATE Latin1_General_CI_AI as FirstName,
			ud.Last_Name COLLATE Latin1_General_CI_AI as LastName
	FROM Intelledox_User u
		LEFT JOIN Address_Book ud ON u.Address_ID = ud.Address_ID;
GO

ALTER PROCEDURE [dbo].[spUser_InsertIntoAccessCode]
	@UserGuid uniqueidentifier,
	@AccessCode nvarchar(50)
AS
BEGIN
	IF (SELECT COUNT(UserGuid) FROM AnonymousUser WHERE UserGuid = @UserGuid) > 0
	BEGIN
		UPDATE AnonymousUser
		SET AccessCode = @AccessCode
		WHERE UserGuid = @UserGuid
	END
	ELSE
	BEGIN
		INSERT INTO AnonymousUser (UserGuid, AccessCode)
		VALUES (@UserGuid, @AccessCode) 
	END
END
GO

IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[dbo].[User_Device]') 
         AND name = 'DeviceEnvironment'
)
BEGIN
	ALTER TABLE User_Device
	ADD DeviceEnvironment int NOT NULL DEFAULT(0)
END
GO

ALTER PROCEDURE [dbo].[spUser_RegisterDeviceToken] (
	@UserGuid uniqueidentifier,
	@DeviceToken [nvarchar](200),
	@DeviceType [int],
	@DeviceEnvironment [int]
)
AS
	IF EXISTS(SELECT * FROM User_Device WHERE DeviceToken = @DeviceToken)
	BEGIN
		UPDATE User_Device
		SET UserGuid = @UserGuid
		WHERE DeviceToken = @DeviceToken
	END
	ELSE 
	BEGIN
		IF NOT EXISTS(SELECT * FROM User_Device WHERE UserGuid = @UserGuid AND DeviceToken = @DeviceToken)
		BEGIN
			INSERT INTO User_Device (UserGuid, DeviceToken, DeviceType, DeviceEnvironment)
			VALUES (@UserGuid, @DeviceToken, @DeviceType, @DeviceEnvironment)
		END
	END

GO


IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[dbo].[Data_Object]') 
         AND name = 'Cache_Warning'
)
BEGIN

	ALTER TABLE Data_Object
	ADD Cache_Warning int NOT NULL DEFAULT(0),
		Cache_Warning_Message nvarchar(256) NULL,
		Cache_Expiry int NOT NULL DEFAULT(0),
		UseAnswerFileData BIT NOT NULL DEFAULT(0)


	UPDATE Data_Object 
	SET Cache_Warning = Cache_Duration

END

GO

ALTER PROCEDURE [dbo].[spDataSource_DataObjectList]
	@DataObjectGuid uniqueidentifier = null,
	@DataServiceGuid uniqueidentifier = null
AS
	IF @DataObjectGuid IS NULL
		SELECT	o.[Object_Name], o.data_object_guid, o.data_service_guid, o.Merge_Source, 
				o.Object_Type, o.Display_Name, o.Allow_Cache, o.Cache_Duration, o.Cache_Warning, 
				o.Cache_Warning_Message, o.Cache_Expiry, o.UseAnswerFileData
		FROM	data_object o
		WHERE	o.data_service_guid = @DataServiceGuid
		ORDER BY o.Display_Name;
	ELSE
		SELECT	o.[Object_Name], o.data_object_guid, o.data_service_guid, o.Merge_Source, 
				o.Object_Type, o.Display_Name, o.Allow_Cache, o.Cache_Duration, o.Cache_Warning, 
				o.Cache_Warning_Message, o.Cache_Expiry, o.UseAnswerFileData
		FROM	data_object o
		WHERE	o.data_object_guid = @DataObjectGuid
		ORDER BY o.Display_Name;

GO

ALTER PROCEDURE [dbo].[spDataSource_UpdateDataObject]
	@DataObjectGuid uniqueidentifier,
	@DataServiceGuid uniqueidentifier,
	@Name nvarchar(500),
	@DisplayName nvarchar(500),
	@MergeSource bit,
	@ObjectType uniqueidentifier,
	@AllowCache bit,
	@CacheDuration int,
	@CacheWarning int,
	@CacheWarningMessage nvarchar(256),
	@CacheExpiry int,
	@UseAnswerFileData bit
AS
	IF NOT EXISTS(SELECT * FROM data_object WHERE Data_Object_Guid = @DataObjectGuid)
	BEGIN
		INSERT INTO data_object (Data_Service_Guid, [Object_Name], Merge_Source, 
				Data_Object_Guid, Object_Type, Display_Name, Allow_Cache, Cache_Duration,
				Cache_Warning, Cache_Warning_Message, Cache_Expiry, UseAnswerFileData)
		VALUES (@DataServiceGuid, @Name, @MergeSource, @DataObjectGuid,
				 @ObjectType, @DisplayName, @AllowCache, @CacheDuration,
				 @CacheWarning, @CacheWarningMessage, @CacheExpiry, @UseAnswerFileData);
	END	
	ELSE
	BEGIN		
		UPDATE	data_object
		SET		[object_name] = @Name, 
				merge_source = @MergeSource,
				Object_Type = @ObjectType,
				Display_Name = @DisplayName,
				Allow_Cache = @AllowCache,
				Cache_Duration = @CacheDuration,
				Cache_Warning = @CacheWarning,
				Cache_Warning_Message = @CacheWarningMessage,
				Cache_Expiry = @CacheExpiry,
				UseAnswerFileData = @UseAnswerFileData
		WHERE	data_object_guid = @DataObjectGuid;
	END
GO

ALTER PROCEDURE [dbo].[spGetCached_DataSourceDependencies] (
	@ProjectGuid as uniqueidentifier
)
AS
	SELECT DISTINCT Data_Object.Data_Object_Guid,
		Data_Object.Data_Object_ID,
		Data_Object.Data_Service_Guid,
		Data_Object.Data_Service_ID,
		Data_Object.Display_Name,
		Data_Object.Merge_Source,
		Data_Object.[Object_Name],
		Data_Object.Object_Type,
		Data_Object.Allow_Cache,
		Data_Object.Cache_Duration,
		Data_Object.Cache_Warning,
		Data_Object.Cache_Warning_Message,
		Data_Object.Cache_Expiry,
		Data_Object.UseAnswerFileData
	FROM [Data_Object]
	inner join Xtf_Datasource_Dependency ON Xtf_Datasource_Dependency.Data_Object_Guid = [Data_Object].Data_Object_Guid
	AND Xtf_Datasource_Dependency.Template_Guid = @ProjectGuid
	WHERE Data_Object.Allow_Cache = 1 OR Data_Object.UseAnswerFileData = 1
GO

ALTER PROCEDURE [dbo].[spUsers_UserGroupByUserCount]
	@BusinessUnitGUID uniqueidentifier,
	@Username nvarchar(50) = '',
	@UserGroupID int = 0,
	@ShowActive int = 0,
	@Firstname nvarchar(50) = '',
	@Lastname nvarchar(50) = ''
AS
BEGIN
	if @UserGroupID = 0	--all user groups
	begin
		if @Username = '' AND @Firstname = '' AND @Lastname = '' AND @ShowActive = 0
		begin
			select	COUNT(*)
			from	Intelledox_User a
			where	a.Business_Unit_GUID = @BusinessUnitGUID AND a.IsAnonymousUser = 0
		end
		else
		begin
			select	COUNT(*)
			from	Intelledox_User a
				left join Address_Book d on a.Address_ID = d.Address_ID
			where	(@Username = '' OR a.[Username] COLLATE Latin1_General_CI_AI like (@Username + '%') COLLATE Latin1_General_CI_AI)
				AND (@Firstname = '' OR d.[First_Name] COLLATE Latin1_General_CI_AI like ('%' + @Firstname + '%') COLLATE Latin1_General_CI_AI)
				AND (@Lastname = '' or d.[Last_Name] COLLATE Latin1_General_CI_AI like ('%' + @Lastname + '%') COLLATE Latin1_General_CI_AI)
				AND (a.Business_Unit_GUID = @BusinessUnitGUID)
				AND ((@ShowActive = 0 AND a.IsAnonymousUser = 0)
					OR (@ShowActive = 1 AND a.[Disabled] = 0 AND a.IsAnonymousUser = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1 AND a.IsAnonymousUser = 0)
					OR (@ShowActive = 3 AND a.IsAnonymousUser = 1))
		end
	end
	else
	begin
		if @UserGroupID = -1	--users with no user groups
		begin
			select	COUNT(*)
			from	Intelledox_User a
				left join Address_Book d on a.Address_Id = d.Address_id
			where	(@Username = '' OR a.[Username] COLLATE Latin1_General_CI_AI like (@Username + '%') COLLATE Latin1_General_CI_AI)
				AND (@Firstname = '' OR d.[First_Name] COLLATE Latin1_General_CI_AI like ('%' + @Firstname + '%') COLLATE Latin1_General_CI_AI)
				AND (@Lastname = '' or d.[Last_Name] COLLATE Latin1_General_CI_AI like ('%' + @Lastname + '%') COLLATE Latin1_General_CI_AI)
				AND	a.User_Guid not in (
						select a.userGuid
						from user_group_subscription a 
						inner join user_Group b on a.GroupGuid = b.Group_Guid
					)
				AND (a.Business_Unit_GUID = @BusinessUnitGUID)
				AND ((@ShowActive = 0 AND a.IsAnonymousUser = 0)
					OR (@ShowActive = 1 AND a.[Disabled] = 0 AND a.IsAnonymousUser = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1 AND a.IsAnonymousUser = 0)
					OR (@ShowActive = 3 AND a.IsAnonymousUser = 1))
		end
		else			--users in specified user group
		begin
			select	COUNT(*)
			from	Intelledox_User a
				inner join User_Group_Subscription c on a.User_Guid = c.UserGuid
				left join Address_Book d on a.Address_Id = d.Address_id
			where	(@Username = '' OR a.[Username] COLLATE Latin1_General_CI_AI like (@Username + '%') COLLATE Latin1_General_CI_AI)
				AND (@Firstname = '' OR d.[First_Name] COLLATE Latin1_General_CI_AI like ('%' + @Firstname + '%') COLLATE Latin1_General_CI_AI)
				AND (@Lastname = '' or d.[Last_Name] COLLATE Latin1_General_CI_AI like ('%' + @Lastname + '%') COLLATE Latin1_General_CI_AI)
				AND	c.GroupGuid = (SELECT Group_Guid FROM User_Group WHERE User_Group_id = @UserGroupID)
				AND (a.Business_Unit_GUID = @BusinessUnitGUID)
				AND ((@ShowActive = 0 AND a.IsAnonymousUser = 0)
					OR (@ShowActive = 1 AND a.[Disabled] = 0 AND a.IsAnonymousUser = 0)
					OR (@ShowActive = 2 AND a.[Disabled] = 1 AND a.IsAnonymousUser = 0)
					OR (@ShowActive = 3 AND a.IsAnonymousUser = 1))
		end
	end
END

GO
ALTER PROCEDURE [dbo].[spUsers_UsersPaging]
	@BusinessUnitGUID uniqueidentifier,
	@Username nvarchar(50) = '',
	@UserGroupID int = 0,
	@ShowActive int = 0,
	@Firstname nvarchar(50) = '',
	@Lastname nvarchar(50) = '',
	@StartRow int,
	@MaximumRows int
AS
BEGIN
	if @UserGroupID = 0	--all user groups
	begin
		if @Username = '' AND @Firstname = '' AND @Lastname = '' AND @ShowActive = 0 
		begin
			select *
			from (
				select	a.*, d.[First_Name], d.[Last_Name], d.[Email_Address], d.[Full_Name], ROW_NUMBER() OVER (ORDER BY a.[Username]) AS RowRank
				from	Intelledox_User a
					left join Address_Book d on a.Address_ID = d.Address_ID
				where	a.Business_Unit_GUID = @BusinessUnitGUID AND a.IsAnonymousUser = 0
				) as RankedUsers
			WHERE RowRank > @StartRow AND RowRank <= (@StartRow + @MaximumRows)
		end
		else
		begin
			select *
			from (
				select	a.*, d.[First_Name], d.[Last_Name], d.[Email_Address], d.[Full_Name], ROW_NUMBER() OVER (ORDER BY a.[Username]) AS RowRank
				from	Intelledox_User a
					left join Address_Book d on a.Address_ID = d.Address_ID
				where	(@Username = '' OR a.[Username] COLLATE Latin1_General_CI_AI like (@Username + '%') COLLATE Latin1_General_CI_AI)
					AND (@Firstname = '' OR d.[First_Name] COLLATE Latin1_General_CI_AI like ('%' + @Firstname + '%') COLLATE Latin1_General_CI_AI)
					AND (@Lastname = '' or d.[Last_Name] COLLATE Latin1_General_CI_AI like ('%' + @Lastname + '%') COLLATE Latin1_General_CI_AI)
					AND (a.Business_Unit_GUID = @BusinessUnitGUID)
					AND ((@ShowActive = 0 AND a.IsAnonymousUser = 0)
						OR (@ShowActive = 1 AND a.[Disabled] = 0 AND a.IsAnonymousUser = 0)
						OR (@ShowActive = 2 AND a.[Disabled] = 1 AND a.IsAnonymousUser = 0)
						OR (@ShowActive = 3 AND a.IsAnonymousUser = 1))
				) as RankedUsers
			WHERE RowRank > @StartRow AND RowRank <= (@StartRow + @MaximumRows)
		end
	end
	else
	begin
		if @UserGroupID = -1	--users with no user groups
		begin
			select *
			from (
				select	a.*,  d.[First_Name], d.[Last_Name], d.[Email_Address], d.[Full_Name], ROW_NUMBER() OVER (ORDER BY a.[Username]) AS RowRank
				from	Intelledox_User a
					left join Address_Book d on a.Address_Id = d.Address_id
				where	(@Username = '' OR a.[Username] COLLATE Latin1_General_CI_AI like (@Username + '%') COLLATE Latin1_General_CI_AI)
					AND (@Firstname = '' OR d.[First_Name] COLLATE Latin1_General_CI_AI like ('%' + @Firstname + '%') COLLATE Latin1_General_CI_AI)
					AND (@Lastname = '' or d.[Last_Name] COLLATE Latin1_General_CI_AI like ('%' + @Lastname + '%') COLLATE Latin1_General_CI_AI)
					AND	a.User_Guid not in (
							select a.userGuid
							from user_group_subscription a 
							inner join user_Group b on a.GroupGuid = b.Group_Guid
						)
					AND (a.Business_Unit_GUID = @BusinessUnitGUID)
					AND ((@ShowActive = 0 AND a.IsAnonymousUser = 0)
						OR (@ShowActive = 1 AND a.[Disabled] = 0 AND a.IsAnonymousUser = 0)
						OR (@ShowActive = 2 AND a.[Disabled] = 1 AND a.IsAnonymousUser = 0)
						OR (@ShowActive = 3 AND a.IsAnonymousUser = 1))
				) as RankedUsers
			WHERE RowRank > @StartRow AND RowRank <= (@StartRow + @MaximumRows)
		end
		else			--users in specified user group
		begin
			select *
			from (
				select	a.*,  d.[First_Name], d.[Last_Name], d.[Email_Address], d.[Full_Name], ROW_NUMBER() OVER (ORDER BY a.[Username]) AS RowRank
				from	Intelledox_User a
					inner join User_Group_Subscription c on a.User_Guid = c.UserGuid
					left join Address_Book d on a.Address_Id = d.Address_id
				where	(@Username = '' OR a.[Username] COLLATE Latin1_General_CI_AI like (@Username + '%') COLLATE Latin1_General_CI_AI)
					AND (@Firstname = '' OR d.[First_Name] COLLATE Latin1_General_CI_AI like ('%' + @Firstname + '%') COLLATE Latin1_General_CI_AI)
					AND (@Lastname = '' or d.[Last_Name] COLLATE Latin1_General_CI_AI like ('%' + @Lastname + '%') COLLATE Latin1_General_CI_AI)
					AND	c.GroupGuid = (SELECT Group_Guid FROM User_Group WHERE User_Group_id = @UserGroupID)
					AND (a.Business_Unit_GUID = @BusinessUnitGUID)
					AND ((@ShowActive = 0 AND a.IsAnonymousUser = 0)
						OR (@ShowActive = 1 AND a.[Disabled] = 0 AND a.IsAnonymousUser = 0)
						OR (@ShowActive = 2 AND a.[Disabled] = 1 AND a.IsAnonymousUser = 0)
						OR (@ShowActive = 3 AND a.IsAnonymousUser = 1))
				) as RankedUsers
			WHERE RowRank > @StartRow AND RowRank <= (@StartRow + @MaximumRows)
		end
	end
END
GO
