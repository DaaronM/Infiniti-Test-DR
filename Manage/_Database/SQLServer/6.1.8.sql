/*
** Database Update package 6.1.8
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.1.8')
go

--1897
ALTER TABLE Data_Object
	ALTER COLUMN [Object_Name] nvarchar(500) null
GO
ALTER TABLE Data_Object_Key
	ALTER COLUMN Field_Name nvarchar(500) null
GO
ALTER TABLE Data_Object_Key
	ALTER COLUMN Display_Name nvarchar(500) null
GO
ALTER procedure [dbo].[spDataSource_UpdateDataKey]
	@FieldName nvarchar(500),
	@Required bit,
	@DisplayName nvarchar(500),
	@DataObjectGuid nvarchar(40)
AS
	IF NOT EXISTS(SELECT * FROM data_object_key WHERE Field_Name = @FieldName AND Data_Object_Guid = @DataObjectGuid)
	begin
		INSERT INTO data_object_key (Data_Object_Key_Guid, Field_Name, [Required], Display_Name, Data_Object_Guid)
		VALUES (newid(), @FieldName, @Required, @DisplayName, @DataObjectGuid);
	end
	ELSE
	begin
		UPDATE	data_object_key
		SET		[required] = @Required,
				display_name = @DisplayName
		WHERE	Data_Object_Guid = @DataObjectGuid
			and field_name = @FieldName;
	end
GO
ALTER PROCEDURE [dbo].[spDataSource_UpdateDataObject]
	@DataObjectGuid uniqueidentifier,
	@DataServiceGuid uniqueidentifier,
	@Name nvarchar(500),
	@MergeSource bit,
	@ObjectType uniqueidentifier
AS
	IF NOT EXISTS(SELECT * FROM data_object WHERE Data_Object_Guid = @DataObjectGuid)
	BEGIN
		INSERT INTO data_object (Data_Service_Guid, [Object_Name], Merge_Source, Data_Object_Guid, Object_Type)
		VALUES (@DataServiceGuid, @Name, @MergeSource, @DataObjectGuid, @ObjectType);
	END	
	ELSE
	BEGIN		
		UPDATE	data_object
		SET		[object_name] = @Name, 
				merge_source = @MergeSource,
				Object_Type = @ObjectType
		WHERE	data_object_guid = @DataObjectGuid;
	END

GO

