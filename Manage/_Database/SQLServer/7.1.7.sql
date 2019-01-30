/*
** Database Update package 7.1.7
*/

--set version
truncate table dbversion
go
insert into dbversion values ('7.1.7')
go

--1972
CREATE PROCEDURE [dbo].[spUsers_IdToGuid]
	@id int
AS
	SELECT	User_Guid
	FROM	Intelledox_Users
	WHERE	User_Id = @id;
GO


--1973
ALTER TABLE Administrator_Level 
	ALTER COLUMN AdminLevel_Description nvarchar(50) null
GO
ALTER TABLE Content_Item_Placeholder
	ALTER COLUMN PlaceholderName nvarchar(50)
GO
BEGIN TRANSACTION
CREATE TABLE dbo.Tmp_Data_Object_Display
	(
	Data_Object_Guid uniqueidentifier NOT NULL,
	Field_Name nvarchar(500) NOT NULL,
	Display_Name nvarchar(500) NOT NULL
	)

IF EXISTS(SELECT * FROM dbo.Data_Object_Display)
	 EXEC('INSERT INTO dbo.Tmp_Data_Object_Display (Data_Object_Guid, Field_Name, Display_Name)
		SELECT Data_Object_Guid, CONVERT(nvarchar(500), Field_Name), Display_Name FROM dbo.Data_Object_Display WITH (HOLDLOCK TABLOCKX)')

DROP TABLE dbo.Data_Object_Display

EXECUTE sp_rename N'dbo.Tmp_Data_Object_Display', N'Data_Object_Display', 'OBJECT' 

CREATE CLUSTERED INDEX IX_Data_Object_Display ON dbo.Data_Object_Display
	(
	Data_Object_Guid
	) 
	
COMMIT
GO
ALTER PROCEDURE [dbo].[spContent_UpdatePlaceholder]
	@ContentItemGuid uniqueidentifier,
	@Placeholder nvarchar(50)
AS
	INSERT INTO Content_Item_Placeholder(ContentItemGuid, PlaceholderName)
	VALUES (@ContentItemGuid, @Placeholder);
GO

--1974
DELETE FROM User_Session
WHERE Modified_Date < DateAdd(d, -10, GetDate());
GO


