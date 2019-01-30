/*
** Database Update package 6.1.2
*/

--set version
truncate table dbversion
go
insert into dbversion values ('6.1.2')
go

--1877
CREATE TABLE dbo.Data_Object_Display
	(
	Data_Object_Guid uniqueidentifier NOT NULL,
	Field_Name varchar(500) NOT NULL,
	Display_Name nvarchar(500) NOT NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.Data_Object_Display ADD CONSTRAINT
	PK_Data_Object_Display PRIMARY KEY CLUSTERED 
	(
	Data_Object_Guid,
	Field_Name
	) 
GO
CREATE PROCEDURE [dbo].[spDataSource_DisplayFieldList]
	@DataObjectGuid uniqueidentifier = null,
	@Name nvarchar(500) = null
AS
	IF @Name IS NULL
		SELECT	field_name, display_name, data_object_guid
		FROM	data_object_display
		WHERE	data_object_guid = @DataObjectGuid
		ORDER BY field_name;
	ELSE
		SELECT	field_name, display_name, data_object_guid
		FROM	data_object_display
		WHERE	data_object_guid = @DataObjectGuid
				AND Field_Name = @Name
		ORDER BY field_name;
GO
CREATE PROCEDURE [dbo].[spDataSource_RemoveDisplayField]
	@FieldName nvarchar(500),
	@DataObjectGuid uniqueidentifier
AS
	DELETE	data_object_display
	WHERE	Data_Object_Guid = @DataObjectGuid
			and field_name = @FieldName;
GO
CREATE procedure [dbo].[spDataSource_UpdateDisplayField]
	@FieldName nvarchar(500),
	@DisplayName nvarchar(500),
	@DataObjectGuid uniqueidentifier
AS
	IF NOT EXISTS(SELECT * FROM data_object_display WHERE Field_Name = @FieldName AND Data_Object_Guid = @DataObjectGuid)
	begin
		INSERT INTO data_object_display (Field_Name, Display_Name, Data_Object_Guid)
		VALUES (@FieldName, @DisplayName, @DataObjectGuid);
	end
	ELSE
	begin
		UPDATE	data_object_display
		SET		display_name = @DisplayName
		WHERE	Data_Object_Guid = @DataObjectGuid
			and field_name = @FieldName;
	end
GO
ALTER PROCEDURE [dbo].[spDataSource_RemoveDataObject]
	@DataObjectGuid uniqueidentifier
AS
	DELETE	data_object_key
	WHERE	data_object_guid = @DataObjectGuid;
	
	DELETE	data_object_display
	WHERE	data_object_guid = @DataObjectGuid;

	DELETE	data_object 
	WHERE	data_object_guid = @DataObjectGuid;
GO

