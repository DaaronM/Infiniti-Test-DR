/*
** Database Update package 8.2.1.14
*/

--set version
truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.2.1.14');
go

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
