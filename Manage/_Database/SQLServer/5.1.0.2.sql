/*
** Database Update package 5.1.0.2
*/

--set version
truncate table dbversion
go
insert into dbversion values ('5.1.0.2')
go

--1822
ALTER PROCEDURE [dbo].[spDataSource_DataKeyList]
	@DataObjectGuid uniqueidentifier = null,
	@Name nvarchar(100) = null
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
ALTER procedure [dbo].[spDataSource_UpdateDataKey]
	@FieldName nvarchar(100),
	@Required bit,
	@DisplayName nvarchar(100),
	@DataObjectGuid nvarchar(40)
AS
	IF NOT EXISTS(SELECT * FROM data_object_key WHERE Field_Name = @FieldName AND Data_Object_Guid = @DataObjectGuid)
	begin
		INSERT INTO data_object_key (Data_Object_Key_Guid, Field_Name, Required, Display_Name, Data_Object_Guid)
		VALUES (newid(), @FieldName, @Required, @DisplayName, @DataObjectGuid)
	end
	ELSE
	begin
		UPDATE data_object_key
		SET required = @Required,
			display_name = @DisplayName
		WHERE Data_Object_Guid = @DataObjectGuid
			and field_name = @FieldName
	end
GO
ALTER PROCEDURE [dbo].[spDataSource_RemoveDataKey]
	@FieldName nvarchar(100),
	@DataObjectGuid nvarchar(40)
AS
	DELETE	data_object_key 
	WHERE	Data_Object_Guid = @DataObjectGuid
			and field_name = @FieldName
GO

--1823
ALTER procedure [dbo].[spTemplateGrp_PackageTemplateList]
	@BusinessUnitGuid uniqueidentifier,
	@PackageId int,
	@ErrorCode int output
as
	SELECT pt.*, 
		(SELECT TOP 1 Template.Name
		FROM Template
			INNER JOIN Template_Group_Item ON Template.Template_ID = Template_Group_Item.Template_ID
		WHERE Template.Template_Type_Id = 1
			AND Template_Group_Item.Template_Group_ID = tg.Template_Group_ID) as Template_Group_Name
		--tg.Name as Template_Group_Name, 
		,tg.HelpText as Template_Help_Text, tg.Template_Group_Guid
	FROM Package_Template pt
		left join Template_Group tg on pt.Template_Group_Id = tg.Template_Group_Id
	WHERE pt.Package_Id = @PackageId
	ORDER BY pt.order_id
GO

--1824
ALTER procedure [dbo].[spProject_UpdateProject]
	@BusinessUnitGuid uniqueidentifier,
	@FormatTypeId int,
	@Name nvarchar(100),
	@ProjectGuid uniqueidentifier,
	@ProjectTypeID int,
	@SupplierGuid uniqueidentifier,
	@ContentBookmark nvarchar(100)
as

	IF NOT EXISTS(SELECT Template_Guid FROM Template WHERE Template_Guid = @ProjectGuid)
	BEGIN
		INSERT INTO Template(Business_Unit_Guid, FormatTypeId, Name, Template_Guid, Template_Type_Id, Supplier_Guid, Content_Bookmark)
		VALUES (@BusinessUnitGuid, @FormatTypeId, @Name, @ProjectGuid, @ProjectTypeId, @SupplierGuid, @ContentBookmark)
	END
	ELSE
	BEGIN
		UPDATE	Template
		SET		[name] = @Name, 
				Template_type_id = @ProjectTypeID, 
				FormatTypeId = @FormatTypeID, 
				Supplier_GUID = @SupplierGuid,
				Content_Bookmark = @ContentBookmark
		WHERE	Template_Guid = @ProjectGuid
	END
GO


