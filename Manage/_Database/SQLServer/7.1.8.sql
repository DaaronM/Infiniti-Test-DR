/*
** Database Update package 7.1.8
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.1.8')
go

--1975
ALTER PROCEDURE [dbo].[spDataSource_DataObjectList]
	@DataObjectGuid uniqueidentifier = null,
	@DataServiceGuid uniqueidentifier = null
AS
	IF @DataObjectGuid IS NULL
		SELECT	o.[Object_Name], o.data_object_guid, o.data_service_guid, o.Merge_Source, 
				o.Object_Type, o.Display_Name
		FROM	data_object o
		WHERE	o.data_service_guid = @DataServiceGuid
		ORDER BY o.Display_Name;
	ELSE
		SELECT	o.[Object_Name], o.data_object_guid, o.data_service_guid, o.Merge_Source, 
				o.Object_Type, o.Display_Name
		FROM	data_object o
		WHERE	o.data_object_guid = @DataObjectGuid
		ORDER BY o.Display_Name;
GO


