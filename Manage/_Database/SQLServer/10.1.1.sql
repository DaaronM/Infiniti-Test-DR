truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.1.1');
GO

ALTER TABLE Data_Object
ALTER COLUMN Object_Name VARCHAR(MAX);
GO

ALTER PROCEDURE [dbo].[spDataSource_UpdateDataObject]
	@DataObjectGuid uniqueidentifier,
	@DataServiceGuid uniqueidentifier,
	@Name nvarchar(MAX),
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
