/*
** Database Update package 7.1.17.3
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.1.17.3')
go

--1984
ALTER PROCEDURE [dbo].[spDataSource_DataKeyList]
	@DataObjectGuid uniqueidentifier = null,
	@Name nvarchar(500) = null
AS
	IF @Name IS NULL
		SELECT	dk.data_object_key_guid, dk.field_name, dk.required, dk.display_name, dk.data_object_guid,
				dk.Data_Object_Key_Id
		FROM	data_object_key dk
		WHERE	dk.data_object_guid = @DataObjectGuid
		ORDER BY dk.field_name
	ELSE
		SELECT	dk.data_object_key_guid, dk.field_name, dk.required, dk.display_name, dk.data_object_guid,
				dk.Data_Object_Key_Id
		FROM	data_object_key dk
		WHERE	dk.data_object_guid = @DataObjectGuid
				AND dk.Field_Name = @Name
		ORDER BY dk.field_name
GO
DROP PROCEDURE [dbo].[spUsers_IdToGuid]
GO
CREATE PROCEDURE [dbo].[spUsers_IdToGuid]
	@id int
AS
	SELECT	User_Guid
	FROM	Intelledox_User
	WHERE	User_Id = @id;
GO
